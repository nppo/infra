##################################################
# Security groups that manage network access
##################################################

resource "aws_security_group" "access_harvester" {
  name        = "harvester-access"
  description = "Harvester access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "protect_harvester" {
  name = "harvester-protect"
  description = "Harvester protection"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port = 8080
    protocol = "tcp"
    security_groups = [
      aws_security_group.access_harvester.id]
  }

  ingress {
    from_port = 0
    to_port = 5555
    protocol = "tcp"
    security_groups = [
      aws_security_group.access_harvester.id]
  }
}

resource "aws_security_group" "access_redis" {
  name        = "redis-access"
  description = "Redis access"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "protect_redis" {
  name = "redis-protect"
  description = "Redis protection"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.access_redis.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.access_redis.id]
  }
}

##################################################
# Passwords
##################################################

resource "random_password" "random_harvester_password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials_harvester" {
  name = "harvester/postgres-application"
  description = "Harvester credentials for the RDS Postgres instance"
}

resource "aws_secretsmanager_secret_version" "postgres_password_harvester" {
  secret_id     = aws_secretsmanager_secret.rds_credentials_harvester.id
  secret_string = jsonencode({
    password = random_password.random_harvester_password.result
    application_password = random_password.random_harvester_password.result
  })
}

resource "aws_secretsmanager_secret" "django" {
  name = "harvester/django"
  description = "The Django SECRET_KEY setting and superuser admin password"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({ secret_key = "", admin_password = "" })
}

resource "random_password" "random_flower_password" {
  length = 32
  special = false
}

resource "aws_secretsmanager_secret" "flower_credentials_harvester" {
  name = "harvester/flower-basic-auth-credentials"
  description = "Flower basic auth credentials"
}

resource "aws_secretsmanager_secret_version" "flower_password_harvester" {
  secret_id     = aws_secretsmanager_secret.flower_credentials_harvester.id
  secret_string = "supersurf:${random_password.random_flower_password.result}"
}

resource "aws_secretsmanager_secret" "sharekit_credentials_harvester" {
  name = "harvester/sharekit-credentials"
  description = "Sharekit JSON API credentials"
}

##################################################
# AWS policies that manage access rights
##################################################

# Secrets access

data "template_file" "harvester_task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = aws_secretsmanager_secret_version.django.arn
    postgres_credentials_application_arn = aws_secretsmanager_secret_version.postgres_password_harvester.arn
    flower_credentials_arn = aws_secretsmanager_secret_version.flower_password_harvester.arn
    sharekit_credentials_arn = aws_secretsmanager_secret.sharekit_credentials_harvester.arn
  }
}

resource "aws_iam_policy" "harvester_task_secrets_policy" {
  name        = "ecsHarvesterTasksSecretsPolicy"
  description = "Policy for using secrets by harvester tasks"
  policy = data.template_file.harvester_task_secrets_policy.rendered
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.harvester_task_secrets_policy.arn
}

# Harvested content access

data "template_file" "harvester_content_policy" {
  template = file("${path.module}/harvester-content-policy.json.tpl")
  vars = {
    harvester_content_bucket_arn = aws_s3_bucket.harvester_content_bucket.arn
  }
}

resource "aws_iam_policy" "harvester_content_policy" {
  name        = "ecsHarvesterTasksContentPolicy"
  description = "Policy for using harvester content from S3"
  policy = data.template_file.harvester_content_policy.rendered
}

resource "aws_iam_role_policy_attachment" "harvester_content" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.harvester_content_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment_task" {
  role = var.harvester_task_role_name
  policy_arn = var.exec_policy_arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment_super" {
  role = var.superuser_task_role_name
  policy_arn = var.exec_policy_arn
}
