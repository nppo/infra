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
# AWS policies that manage access rights
##################################################

# Secrets access

data "template_file" "harvester_task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = var.django_secrets_arn
    postgres_credentials_application_arn = var.postgres_credentials_application_arn
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

data "template_file" "harvester_development_data_policy" {
  template = file("${path.module}/development-data-policy.json.tpl")
  vars = { }
}

# Development data access

resource "aws_iam_policy" "harvester_development_data_policy" {
  name        = "ecsHarvesterTasksDataPolicy"
  description = "Policy for using data from S3"
  policy = data.template_file.harvester_development_data_policy.rendered
}

resource "aws_iam_role_policy_attachment" "harvester_data" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.harvester_development_data_policy.arn
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
