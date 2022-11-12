terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket  = "jjikin-t101study-tfstate"
    key     = "dev/terraform.tfstate"
    region  = "ap-northeast-2"
    dynamodb_table = "dynamodbtable-backend"
    #encrypt = true
  }
}
