provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_s3_bucket" "jjikin-tfstate-s3" {
  bucket = "jjikin-tfstate-s3"
}

resource "aws_s3_bucket_versioning" "jjikin-tfstate-s3_versioning" {
  bucket = aws_s3_bucket.jjikin-tfstate-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tfstate-db-table" {
  name         = "tfstate-db-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
