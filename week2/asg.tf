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
  user_data = filebase64("user_data.sh")
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.webserver-sg.id]
  }  
}            

resource "aws_autoscaling_group" "webserver-asg" {
  name                 = "webserver-asg"
  vpc_zone_identifier  = [aws_subnet.ljyoon-pub-a-sn.id, aws_subnet.ljyoon-pub-c-sn.id]
  desired_capacity = 2
  min_size = 2
  max_size = 10
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
