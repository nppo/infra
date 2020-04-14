output "policy_arn" {
  value = aws_iam_policy.this.arn
  description = "The ARN of the IAM policy which allows managing this cluster"
}