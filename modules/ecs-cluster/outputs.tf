output "policy_arn" {
  value = aws_iam_policy.nppo-ecs.arn
  description = "The ARN of the IAM policy which allows managing this cluster"
}

output "exec_policy_arn" {
  value = aws_iam_policy.exec-ecs.arn
  description = "The ARN of the IAM policy which allows entering containers in a cluster"
}

output "application_task_role_arn" {
  value = aws_iam_role.application_task_role.arn
  description = "The ARN of the IAM role that is used by normal tasks"
}

output "application_task_role_name" {
  value = aws_iam_role.application_task_role.name
  description = "The name of the IAM role that is used by normal tasks"
}

output "harvester_task_role_name" {
  value = aws_iam_role.harvester_task_role.name
  description = "The name of the IAM role that is used by harvester tasks"
}

output "middleware_task_role_name" {
  value = aws_iam_role.middleware_task_role.name
  description = "The name of the IAM role that is used by middleware tasks"
}

output "superuser_task_role_name" {
  value = aws_iam_role.superuser_task_role.name
  description = "The name of the IAM role that is used by superuser tasks"
}
