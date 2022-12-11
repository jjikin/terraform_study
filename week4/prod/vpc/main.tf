provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
} 

terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket  = "jjikin-tfstate-s3"
    key     = "stage/vpc/terraform.tfstate"
    region  = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

resource "aws_vpc" "jjikin-stg-vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "jjikin-stg-vpc" }
}

resource "aws_subnet" "stg-pub-a-sn" {
  vpc_id     = aws_vpc.jjikin-stg-vpc.id
  cidr_block = "192.168.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "stg-pub-a-sn"
  }
}

resource "aws_subnet" "stg-pub-c-sn" {
  vpc_id     = aws_vpc.jjikin-stg-vpc.id
  cidr_block = "192.168.20.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "stg-pub-c-sn"
  }
}

resource "aws_internet_gateway" "stg-igw" {
  vpc_id = aws_vpc.jjikin-stg-vpc.id

  tags = {
    Name = "stg-igw"
  }
}

resource "aws_route_table" "stg-pub-rt" {
  vpc_id = aws_vpc.jjikin-stg-vpc.id

  tags = {
    Name = "stg-pub-rt"
  }
}

resource "aws_route_table_association" "stg-pub-rt-a-asso" {
  subnet_id      = aws_subnet.stg-pub-a-sn.id
  route_table_id = aws_route_table.stg-pub-rt.id
}

resource "aws_route_table_association" "stg-pub-rt-c-asso" {
  subnet_id      = aws_subnet.stg-pub-c-sn.id
  route_table_id = aws_route_table.stg-pub-rt.id
}

resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.stg-pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.stg-igw.id
}


resource "aws_subnet" "stg-pri-a-sn" {
  vpc_id     = aws_vpc.jjikin-stg-vpc.id
  cidr_block = "192.168.30.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "stg-pri-a-sn"
  }
}

resource "aws_subnet" "stg-pri-c-sn" {
  vpc_id     = aws_vpc.jjikin-stg-vpc.id
  cidr_block = "192.168.40.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "stg-pri-c-sn"
  }
}

resource "aws_route_table" "stg-pri-rt" {
  vpc_id = aws_vpc.jjikin-stg-vpc.id
  tags = {
    Name = "stg-pri-rt"
  }
}

resource "aws_route_table_association" "stg-pri-rt-a-asso" {
  subnet_id      = aws_subnet.stg-pri-a-sn.id
  route_table_id = aws_route_table.stg-pri-rt.id
}

resource "aws_route_table_association" "stg-pri-rt-c-asso" {
  subnet_id      = aws_subnet.stg-pri-c-sn.id
  route_table_id = aws_route_table.stg-pri-rt.id
}

resource "aws_security_group" "stg-rds-sg" {
  vpc_id      = aws_vpc.jjikin-stg-vpc.id
  name        = "stg-rds-sg"
  description = "stg-rds-sg"
}

resource "aws_security_group_rule" "stg-rds-sg-inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.stg-rds-sg.id
}

resource "aws_security_group_rule" "stg-rds-sg-outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.stg-rds-sg.id
}
