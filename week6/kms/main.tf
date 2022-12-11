provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

# Look up the details of the current user
data "aws_caller_identity" "self" {}

# 현재 사용자가 KMS 권한을 가질 수 있도록 정책 설정
data "aws_iam_policy_document" "cmk_admin_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.self.arn]
    }
  }
}

resource "aws_kms_key" "cmk" {
  policy = data.aws_iam_policy_document.cmk_admin_policy.json
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/jjikin2"
  target_key_id = aws_kms_key.cmk.id
}

# 테라폼 코드에서 암호화된 파일 사용
data "aws_kms_secrets" "creds" {
  secret {
    name    = "db"
    payload = file("${path.module}/db-creds.yml.encrypted2")
  }
}

locals {
  db_creds = yamldecode(data.aws_kms_secrets.creds.plaintext["db"])
}

resource "aws_db_subnet_group" "stg-db-sn-group" {
  name       = "stg-db-sn-group"
  subnet_ids = [aws_subnet.pri-a-sn.id, aws_subnet.pri-c-sn.id]

  tags = {
    Name = "stg-db-sn-group"
  }
}

resource "aws_security_group" "stg-rds-sg" {
  vpc_id      = aws_vpc.jjikin-vpc.id
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

resource "aws_db_instance" "staging-rds" {
  identifier             = "staging-rds"
  engine                 = "mysql"
  allocated_storage      = 10
  instance_class         = "db.t2.micro"
  db_subnet_group_name   = aws_db_subnet_group.stg-db-sn-group.name
  vpc_security_group_ids = [aws_security_group.stg-rds-sg.id]
  skip_final_snapshot    = true
  db_name                = var.db_name
  username               = local.db_creds.username
  password               = local.db_creds.password
}

# 초기 생성 리소스
resource "aws_vpc" "jjikin-vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "jjikin-stg-vpc" }
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

variable "db_name" {
  description = "The name to use for the database"
  type        = string
  default     = "stagingrds"
}

output "address" {
  value       = aws_db_instance.staging-rds.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = aws_db_instance.staging-rds.port
  description = "The port the database is listening on"
}