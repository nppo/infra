output "application_task_role_arn" {
  value = aws_iam_role.application_task_role.arn
  description = "The ARN of the application role"
}

output "superuser_task_role_arn" {
  value = aws_iam_role.superuser_task_role.arn
  description = "The ARN of the superuser role"
}
