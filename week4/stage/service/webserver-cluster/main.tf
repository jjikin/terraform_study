provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket = "jjikin-tfstate-s3"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "tfstate-db-table"
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}