provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_instance" "example" {
  ami           = "ami-0c76973fbe0ee100c"
  instance_type = "t2.micro"
  tags = {
    Name = "t101-week3"
  }
}

terraform {
  backend "s3" {
    profile = "ljyoon"
    bucket = "jjikin-t101study-tfstate-week3"
    key    = "workspaces-default/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-locks-week3"
  }
}
