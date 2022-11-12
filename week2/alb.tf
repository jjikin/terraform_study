# 기본사항 정의
resource "aws_lb" "web-alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.ljyoon-pub-a-sn.id, aws_subnet.ljyoon-pub-c-sn.id]
  security_groups = [aws_security_group.webserver-sg.id]

  tags = {
    Name = "web-alb"
  }
}

# 리스너 정의
resource "aws_lb_listener" "web-http" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = 80
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
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ljyoon-vpc.id

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
