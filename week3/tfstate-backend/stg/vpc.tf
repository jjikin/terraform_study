provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_vpc" "stg_myvpc" {
  cidr_block       = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "stg_t101-study"
  }
}

resource "aws_subnet" "stg_mysubnet1" {
  vpc_id     = aws_vpc.stg_myvpc.id
  cidr_block = "10.20.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "stg_t101-subnet1"
  }
}

resource "aws_subnet" "stg_mysubnet2" {
  vpc_id     = aws_vpc.stg_myvpc.id
  cidr_block = "10.20.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "stg_t101-subnet2"
  }
}


resource "aws_internet_gateway" "stg_myigw" {
  vpc_id = aws_vpc.stg_myvpc.id

  tags = {
    Name = "stg_t101-igw"
  }
}

resource "aws_route_table" "stg_myrt" {
  vpc_id = aws_vpc.stg_myvpc.id

  tags = {
    Name = "stg_t101-rt"
  }
}

resource "aws_route_table_association" "stg_myrtassociation1" {
  subnet_id      = aws_subnet.stg_mysubnet1.id
  route_table_id = aws_route_table.stg_myrt.id
}

resource "aws_route_table_association" "stg_myrtassociation2" {
  subnet_id      = aws_subnet.stg_mysubnet2.id
  route_table_id = aws_route_table.stg_myrt.id
}

resource "aws_route" "stg_mydefaultroute" {
  route_table_id         = aws_route_table.stg_myrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.stg_myigw.id
}

