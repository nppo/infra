output "policy_arn" {
  value = aws_iam_policy.surfpol-ecs.arn
  description = "The ARN of the IAM policy which allows managing this cluster"
}
