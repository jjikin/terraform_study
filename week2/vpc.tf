provider "aws" {
  region  = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_vpc" "ljyoon-vpc" {
  cidr_block       = "10.10.0.0/16"
	enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ljyoon-vpc"
  }
}

# 서브넷 생성
resource "aws_subnet" "ljyoon-pub-a-sn" {
  vpc_id     = aws_vpc.ljyoon-vpc.id
  cidr_block = "10.10.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ljyoon-pub-a-sn"
  }
}

resource "aws_subnet" "ljyoon-pub-c-sn" {
  vpc_id     = aws_vpc.ljyoon-vpc.id
  cidr_block = "10.10.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "ljyoon-pub-c-sn"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "ljyoon-igw" {
  vpc_id = aws_vpc.ljyoon-vpc.id

  tags = {
    Name = "ljyoon-igw"
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "ljyoon-pub-rt" {
  vpc_id = aws_vpc.ljyoon-vpc.id

  tags = {
    Name = "ljyoon-pub-rt"
  }
}

# 라우팅 테이블에 서브넷 연결
resource "aws_route_table_association" "ljyoon-pub-a-rt-association" {
  subnet_id      = aws_subnet.ljyoon-pub-a-sn.id
  route_table_id = aws_route_table.ljyoon-pub-rt.id
}

resource "aws_route_table_association" "ljyoon-pub-c-rt-association" {
  subnet_id      = aws_subnet.ljyoon-pub-c-sn.id
  route_table_id = aws_route_table.ljyoon-pub-rt.id
}

# 기본 라우팅 규칙 생성
resource "aws_route" "ljyoon-pub-rt-rule" {
  route_table_id         = aws_route_table.ljyoon-pub-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ljyoon-igw.id
}
