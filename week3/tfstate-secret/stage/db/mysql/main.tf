terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/db/mysql/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/vpc/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 랜덤 암호 생성
resource "random_password" "password" {
  length           = 10
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
 
# 보안 암호 이름
resource "aws_secretsmanager_secret" "secret_db" {
   name = "secret_db"
}
 
# 보안 암호 버전 설정
resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = aws_secretsmanager_secret.secret_db.id
  secret_string = <<EOF
   {
    "username": "cloudneta",
    "password": "${random_password.password.result}"
   }
EOF
}
 
# 생성한 보안 암호의 arn 가져오기
data "aws_secretsmanager_secret" "secret_db" {
  arn = aws_secretsmanager_secret.secret_db.arn
}
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secret_db.arn
}
 
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}

resource "aws_db_subnet_group" "db-sn-group" {
  name       = "db-sn-group"
  subnet_ids = [data.terraform_remote_state.vpc.outputs.pri-a-sn, data.terraform_remote_state.vpc.outputs.pri-c-sn]

  tags = {
    Name = "db-sn-group"
  }
}

resource "aws_db_instance" "staging-rds" {
  identifier             = "staging-rds"
  engine                 = "mysql"
  allocated_storage      = 10
  instance_class         = "db.t2.micro"
  db_subnet_group_name   = aws_db_subnet_group.db-sn-group.name
  vpc_security_group_ids = [data.terraform_remote_state.vpc.outputs.rds-sg]
  skip_final_snapshot    = true

  db_name                = var.db_name
  username               = local.db_creds.username
  password               = local.db_creds.password
}
