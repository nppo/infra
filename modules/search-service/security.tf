##################################################
# Security groups that manage network access
##################################################

resource "aws_security_group" "access_service" {
  name        = "service-access"
  description = "Service access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "protect_service" {
  name = "service-protect"
  description = "Service protection"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.access_service.id]
  }
}

##################################################
# Passwords and other random secrets
##################################################

resource "random_password" "random_service_password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials_service" {
  name = "search-portal/postgres-application"
  description = "Service credentials for the RDS Postgres instance"
}

resource "aws_secretsmanager_secret_version" "postgres_password_service" {
  secret_id     = aws_secretsmanager_secret.rds_credentials_service.id
  secret_string = jsonencode({
    password = random_password.random_service_password.result
    application_password = random_password.random_service_password.result
  })
}

resource "aws_secretsmanager_secret" "django" {
  name = "search-portal/django"
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
    postgres_credentials_application_arn = aws_secretsmanager_secret_version.postgres_password_service.arn
    harvester_api_key_arn = var.harvester_api_key_arn
  }
}

resource "aws_iam_policy" "task_secrets_policy" {
  name        = "ecsTasksSecretsPolicy"
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

# Scheduled tasks

data "aws_iam_policy_document" "events" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_events_role" {
  name = "ecsEventsRole"
  assume_role_policy = data.aws_iam_policy_document.events.json
}

resource "aws_iam_policy" "scheduled_event_ecs" {
  name        = "AmazonEC2ContainerServiceEventsRole"
  description = "Permission to run ECS tasks"
  policy = templatefile(
  "${path.module}/ecs-events-policy.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "scheduled_event_ecs_tasks" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = aws_iam_policy.scheduled_event_ecs.arn
}

resource "aws_iam_policy" "event_task_role" {
  name        = "AmazonECSEventsTaskExecutionRole"
  description = "Permission to run ECS tasks as application role"
  policy = templatefile(
  "${path.module}/ecs-events-task-execution.json.tpl",
  { task_role_arn: var.application_task_role_arn }
  )
}

resource "aws_iam_role_policy_attachment" "scheduled_event_ecs_task_role" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = aws_iam_policy.event_task_role.arn
}
