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
  username               = var.db_username
  password               = var.db_password
}
