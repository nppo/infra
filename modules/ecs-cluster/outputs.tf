output "policy_arn" {
  value = aws_iam_policy.surfpol-ecs.arn
  description = "The ARN of the IAM policy which allows managing this cluster"
}

output "application_task_role_arn" {
  value = aws_iam_role.application_task_role.arn
  description = "The ARN of the IAM role that is used by normal tasks"
}

output "application_task_role_name" {
  value = aws_iam_role.application_task_role.name
  description = "The name of the IAM role that is used by normal tasks"
}

output "superuser_task_role_name" {
  value = aws_iam_role.superuser_task_role.name
  description = "The name of the IAM role that is used by superuser tasks"
}

output "django_secrets_arn" {
  value = aws_secretsmanager_secret.django.arn
  description = "The ARN of the secret containing Django secrets"
}
