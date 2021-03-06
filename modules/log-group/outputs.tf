output "name" {
  value = aws_cloudwatch_log_group.this.name
  description = "The name of the log group"
}

output "arn" {
  value = aws_cloudwatch_log_group.this.arn
  description = "The ARN of the log group"
}

output "policy_arn" {
  value = aws_iam_policy.this.arn
  description = "The ARN of the IAM policy which allows managing this log-group"
}