output "all_users" {
  value = aws_iam_user.myiam
}

output "all_users_arn" {
  value = values(aws_iam_user.myiam)[*].arn
}
