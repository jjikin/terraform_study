terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
}

# vpc tfstate 파일 참조
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# db tfstate 파일 참조
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/db/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

resource "aws_subnet" "pub-a-sn" {
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc-id
  cidr_block = "10.10.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "pub-a-sn"
  }
}

resource "aws_subnet" "pub-c-sn" {
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc-id
  cidr_block = "10.10.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "pub-c-sn"
  }
}

resource "aws_internet_gateway" "jjikin-igw" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc-id

  tags = {
    Name = "jjikin-igw"
  }
}

resource "aws_route_table" "pub-rt" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc-id

  tags = {
    Name = "pub-rt"
  }
}

resource "aws_route_table_association" "pub-rt-a-asso" {
  subnet_id      = aws_subnet.pub-a-sn.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route_table_association" "pub-rt-c-asso" {
  subnet_id      = aws_subnet.pub-c-sn.id
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.jjikin-igw.id
}

resource "aws_security_group" "web-sg" {
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc-id
  name        = "web-sg"
  description = "web-sg"
}

resource "aws_security_group_rule" "web-sg-inbound" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web-sg.id
}

resource "aws_security_group_rule" "web-sg-outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web-sg.id
}

data "template_file" "user_data" {
  template = file("user-data.sh")

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

resource "aws_launch_template" "webserver-template" {
  name            = "webserver-template"
  image_id        = data.aws_ami.amazonlinux2.id
  instance_type   = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.web-sg.id]
  }  

  # Render the User Data script as a template
  user_data = base64encode(templatefile("user-data.sh", {
    server_port = 8080
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }))
}            

resource "aws_autoscaling_group" "webserver-asg" {
  name                 = "webserver-asg"
  vpc_zone_identifier  = [aws_subnet.pub-a-sn.id, aws_subnet.pub-c-sn.id]
  desired_capacity = 2
  min_size = 2
  max_size = 10
 
  # ALB 연결
  target_group_arns = [aws_lb_target_group.web-alb-tg.arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.webserver-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "webserver-asg"
    propagate_at_launch = true
  }
}

# 기본사항 정의
resource "aws_lb" "web-alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub-a-sn.id, aws_subnet.pub-c-sn.id]
  security_groups = [aws_security_group.web-sg.id]

  tags = {
    Name = "web-alb"
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

output "web-alb_dns" {
  value       = aws_lb.web-alb.dns_name
  description = "The DNS Address of the ALB"
}
