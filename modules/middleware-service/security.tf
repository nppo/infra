##################################################
# Security groups that manage network access
##################################################

resource "aws_security_group" "access_middleware" {
  name        = "middleware-access"
  description = "Middleware access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "protect_middleware" {
  name = "middleware-protect"
  description = "Middleware protection"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.access_middleware.id]
  }
}

##################################################
# Passwords and other random secrets
##################################################

resource "random_password" "random_postgres_password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials_middleware" {
  name = "middleware/postgres-application"
  description = "Middleware credentials for the RDS Postgres instance"
}

resource "aws_secretsmanager_secret_version" "postgres_password_middleware" {
  secret_id     = aws_secretsmanager_secret.rds_credentials_middleware.id
  secret_string = jsonencode({
    password = random_password.random_postgres_password.result
    application_password = random_password.random_postgres_password.result
  })
}

resource "aws_secretsmanager_secret" "django" {
  name = "middleware/django"
  description = "The Django SECRET_KEY setting and superuser admin password"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({ secret_key = "", admin_password = "" })
}

##################################################
# AWS policies that manage access rights
##################################################

# Secrets access

data "template_file" "task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = aws_secretsmanager_secret_version.django.arn
    postgres_credentials_application_arn = aws_secretsmanager_secret_version.postgres_password_middleware.arn
    hva_pure_api_key_arn = var.hva_pure_api_key_arn
  }
}

resource "aws_iam_policy" "task_secrets_policy" {
  name        = "ecsMiddlewareTasksSecretsPolicy"
  description = "Policy for using secrets by tasks on ECS cluster"
  policy = data.template_file.task_secrets_policy.rendered
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = var.application_task_role_name
  policy_arn = aws_iam_policy.task_secrets_policy.arn
}

# ECS Exec

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment_task" {
  role = var.application_task_role_name
  policy_arn = var.exec_policy_arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment_super" {
  role = var.superuser_task_role_name
  policy_arn = var.exec_policy_arn
}
