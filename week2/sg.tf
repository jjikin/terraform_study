resource "aws_security_group" "webserver-sg" {
  vpc_id      = aws_vpc.ljyoon-vpc.id
  name        = "webserver-sg"
  description = "T101 Study webserver-sg"
}

resource "aws_security_group_rule" "webserver-sg-inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webserver-sg.id
}

resource "aws_security_group_rule" "webserver-sg-outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.webserver-sg.id
}
