data "aws_ssm_parameter" "amzn2_latest"  {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"  
}

resource "aws_instance" "webserver" {
  ami 			 = data.aws_ssm_parameter.amzn2_latest.value
  instance_type 	 = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y && yum install httpd -y && sleep 10
              sudo sed -i "s/Listen 80/Listen ${var.webserver_port}/g" /etc/httpd/conf/httpd.conf
	      echo "Hello, My name is Jiyoon. Port number is ${var.webserver_port}" > /var/www/html/index.html
              systemctl restart httpd
              EOF
  
  user_data_replace_on_change = true

  tags = {
    Name = "webserver1"
  }
}

resource "aws_security_group" "webserver" {
  name = var.security_group_name

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.webserver_port
    to_port     = var.webserver_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
