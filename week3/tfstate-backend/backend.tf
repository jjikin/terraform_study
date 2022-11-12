provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

resource "aws_s3_bucket" "s3-backend" {
  bucket = "jjikin-t101study-tfstate"
}

# 버전 관리 활성화
resource "aws_s3_bucket_versioning" "s3-backend_versioning" {
  bucket = aws_s3_bucket.s3-backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "dynamodbtable-backend" {
  name         = "dynamodbtable-backend"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.s3-backend.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.dynamodbtable-backend.name
  description = "The name of the DynamoDB table"
}
