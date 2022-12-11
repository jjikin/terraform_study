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

resource "aws_vpc" "jjikin-vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "jjikin-stg-vpc" }
}

resource "aws_subnet" "pub-a-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "192.168.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "stg-pub-a-sn"
  }
}

resource "aws_subnet" "pub-c-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "192.168.20.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "stg-pub-c-sn"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.jjikin-vpc.id

  tags = {
    Name = "stg-igw"
  }
}

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.jjikin-vpc.id

  tags = {
    Name = "stg-pub-rt"
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
  gateway_id             = aws_internet_gateway.igw.id
}


resource "aws_subnet" "pri-a-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "192.168.30.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "stg-pri-a-sn"
  }
}

resource "aws_subnet" "pri-c-sn" {
  vpc_id     = aws_vpc.jjikin-vpc.id
  cidr_block = "192.168.40.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "stg-pri-c-sn"
  }
}

resource "aws_route_table" "pri-rt" {
  vpc_id = aws_vpc.jjikin-vpc.id
  tags = {
    Name = "stg-pri-rt"
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
