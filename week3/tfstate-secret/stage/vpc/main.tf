terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket  = "jjikin-tfstate-s3"
    key     = "stage/vpc/terraform.tfstate"
    region  = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_vpc" "jjikin-vpc" {
  cidr_block       = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "jjikin-vpc"
  }
}

resource "aws_subnet" "pri-a-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "10.10.3.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "pri-a-sn"
  }
}

resource "aws_subnet" "pri-c-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "10.10.4.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "pri-c-sn"
  }
}

resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.jjikin-vpc.id

  tags = {
    Name = "pri-rt"
  }
}

resource "aws_route_table_association" "pri-rt-a-asso" {
  subnet_id      = aws_subnet.pri-a-sn.id
  route_table_id = aws_route_table.pri-rt.id
}

resource "aws_route_table_association" "pri-rt-c-asso" {
  subnet_id      = aws_subnet.pri-c-sn.id
  route_table_id = aws_route_table.pri-rt.id
}

resource "aws_security_group" "rds-sg" {
  vpc_id      = aws_vpc.jjikin-vpc.id
  name        = "rds-sg"
  description = "rds-sg"
}

resource "aws_security_group_rule" "rds-sg-inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds-sg.id
}

resource "aws_security_group_rule" "rds-sg-outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds-sg.id
}
