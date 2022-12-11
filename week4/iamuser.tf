provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

locals {
  name = "iamuser"
  team = {
    group = "dev"
  }
}

resource "aws_iam_user" "iamuser1" {
  name = "${local.name}1"
  tags = local.team
}

resource "aws_iam_user" "iamuser2" {
  name = "${local.name}2"
  tags = local.team
}
