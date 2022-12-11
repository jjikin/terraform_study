provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
} 

terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stg/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

# vpc tfstate 파일 참조
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "${var.env}/stage/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# db tfstate 파일 참조
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "${var.env}/db/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  http_port    = 8080
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_security_group" "web-sg" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc-id
  name        = "${var.env}-web-sg"
  description = "${var.env}-web-sg"
}

resource "aws_security_group_rule" "web-sg-inbound" {
  type              = "ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
  security_group_id = aws_security_group.web-sg.id
}

resource "aws_security_group_rule" "web-sg-outbound" {
  type              = "egress"
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
  security_group_id = aws_security_group.web-sg.id
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = 8080
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

data "aws_ami" "amazonlinux2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_launch_template" "web-template" {
  name            = "${var.env}-web-template"
  image_id        = data.aws_ami.amazonlinux2.id
  instance_type   = "${var.instance_type}"
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.web-sg.id]
  }  

  # Render the User Data script as a template
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = 8080
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }))
}            

resource "aws_autoscaling_group" "web-asg" {
  name                 = "${var.env}-web-asg"
  vpc_zone_identifier  = [data.terraform_remote_state.vpc.outputs.pub-a-sn, data.terraform_remote_state.vpc.outputs.pub-c-sn]
  desired_capacity = 2
  min_size = var.min_size
  max_size = var.max_size
 
  # ALB 연결
  target_group_arns = [aws_lb_target_group.web-alb-tg.arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.web-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-web-asg"
    propagate_at_launch = true
  }
}

# 기본사항 정의
resource "aws_lb" "web-alb" {
  name               = "${var.env}-web-alb"
  load_balancer_type = "application"
  subnets            = [data.terraform_remote_state.vpc.outputs.pub-a-sn, data.terraform_remote_state.vpc.outputs.pub-c-sn]
  security_groups = [aws_security_group.web-sg.id]

  tags = {
    Name = "${var.env}-web-alb"
  }
}

# 리스너 정의
resource "aws_lb_listener" "web-http" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = 8080
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found - T101 Study"
      status_code  = 404
    }
  }
}

# 타겟그룹 정의
resource "aws_lb_target_group" "web-alb-tg" {
  name = "web-alb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc-id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 5
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 리스너 규칙 정의
resource "aws_lb_listener_rule" "web-alb-rule" {
  listener_arn = aws_lb_listener.web-http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-alb-tg.arn
  }
}
