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

resource "aws_secretsmanager_secret" "hanze_credentials_harvester" {
  name = "harvester/hanze-credentials"
  description = "Hanze Azure API credentials"
}

resource "aws_secretsmanager_secret" "deepl_key" {
  name = "harvester/deepl"
  description = "API key for deepl"
}

resource "aws_secretsmanager_secret_version" "deepl_key" {
  secret_id     = aws_secretsmanager_secret.deepl_key.id
  secret_string = jsonencode({ api_key = "" })
}

resource "aws_secretsmanager_secret" "eduterm_credentials" {
  name = "eduterm"
  description = "API key for the Eduterm service"
}

resource "random_password" "random_harvester_key" {
  length = 40
  special = false
}

resource "aws_secretsmanager_secret" "harvester_key" {
  name = "harvester/api-key"
  description = "Internal API key to access the harvester"
}

resource "aws_secretsmanager_secret_version" "harvester_key_version" {
  secret_id     = aws_secretsmanager_secret.harvester_key.id
  secret_string = jsonencode({
    api_key = random_password.random_harvester_password.result
  })
}

resource "random_uuid" "random_harvester_webhook_secret" { }

resource "aws_secretsmanager_secret" "harvester_credentials" {
  name = "harvester/credentials"
  description = "Internal credentials to access the harvester"
}

resource "aws_secretsmanager_secret_version" "harvester_credentials_version" {
  secret_id     = aws_secretsmanager_secret.harvester_credentials.id
  secret_string = jsonencode({
    api_key = random_password.random_harvester_password.result
    webhook_secret = random_uuid.random_harvester_webhook_secret.result
  })
}

resource "aws_secretsmanager_secret" "pure_hva_key" {
  name = "harvester/pure-hva"
  description = "API key for HvA"
}

resource "aws_secretsmanager_secret_version" "pure_hva_key" {
  secret_id     = aws_secretsmanager_secret.pure_hva_key.id
  secret_string = jsonencode({ api_key = "" })
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
    eduterm_credentials_arn = aws_secretsmanager_secret.eduterm_credentials.arn
    deepl_key_arn = aws_secretsmanager_secret.deepl_key.arn
    opensearch_credentials_arn = var.opensearch_credentials_arn,
    harvester_api_key_arn = aws_secretsmanager_secret.harvester_key.arn
    harvester_credentials_arn = aws_secretsmanager_secret_version.harvester_credentials_version.arn
    hanze_credentials_harvester = aws_secretsmanager_secret.hanze_credentials_harvester.arn
    pure_hva_key = aws_secretsmanager_secret.pure_hva_key.arn
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
