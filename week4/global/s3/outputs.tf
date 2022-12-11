output "s3_bucket_arn" {
  value       = aws_s3_bucket.jjikin-tfstate-s3.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.tfstate-db-table.name
  description = "The name of the DynamoDB table"
}
