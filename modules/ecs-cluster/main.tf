locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "task_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}


###########################################
# CREATING CLUSTER SECRETS
###########################################

resource "aws_secretsmanager_secret" "django" {
  name = "search-portal/django"
  description = "Mainly the Django SECRET_KEY setting, but possibly in the future other miscellaneous secrets"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({ secret_key = "" })
}

resource "aws_secretsmanager_secret" "surfconext" {
  name = "search-portal/surfconext"
  description = "The OIDC secret key"
}

resource "aws_secretsmanager_secret_version" "surfconext" {
  secret_id     = aws_secretsmanager_secret.surfconext.id
  secret_string = jsonencode({ secret_key = "" })
}

resource "aws_secretsmanager_secret" "elastic_search" {
  name = "search-portal/elastic"
  description = "Password for connecting to Elastic Search service"
}

resource "aws_secretsmanager_secret_version" "elastic_search" {
  secret_id     = aws_secretsmanager_secret.elastic_search.id
  secret_string = jsonencode({ password = "" })
}


###########################################
# CREATING SUPERUSER TASK ROLE
###########################################

resource "aws_iam_role" "superuser_task_role" {
  name = "ecsSuperuserTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "superuser_secretsmanager" {
  role = aws_iam_role.superuser_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "superuser_s3" {
  role = aws_iam_role.superuser_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "superuser_task_execution" {
  role       = aws_iam_role.superuser_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


###########################################
# CREATING TASK ROLE
###########################################

resource "aws_iam_role" "application_task_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

data "template_file" "task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = aws_secretsmanager_secret.django.arn
    surfconext_credentials_arn = aws_secretsmanager_secret.surfconext.arn
    elastic_search_credentials_arn = aws_secretsmanager_secret.elastic_search.arn
    postgres_credentials_application_arn = var.postgres_credentials_application_arn
  }
}

resource "aws_iam_policy" "task_secrets_policy" {
  name        = "ecsTasksSecretsPolicy"
  description = "Policy for using secrets by tasks on ECS cluster"
  policy = data.template_file.task_secrets_policy.rendered
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = aws_iam_role.application_task_role.name
  policy_arn = aws_iam_policy.task_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "application_s3" {
  role = aws_iam_role.application_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "application_task_execution" {
  role       = aws_iam_role.application_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


###########################################
# CREATING CLUSTER
###########################################

resource "aws_ecs_cluster" "surfpol" {
  name = var.project
  capacity_providers = ["FARGATE"]

  setting {
    name = "containerInsights"
    value = "enabled"
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight = 1
  }

  tags = local.common_tags
}

data "template_file" "surfpol" {
  template = file("${path.module}/cluster-policy.json.tpl")
  vars = {
    task_execution_role_arn = aws_iam_role.application_task_role.arn
    superuser_task_execution_role_arn = aws_iam_role.superuser_task_role.arn
    cluster_arn = aws_ecs_cluster.surfpol.arn
  }
}

resource "aws_iam_policy" "surfpol-ecs" {
  name        = "${var.project}-ecs-manage"
  description = "Policy for managing the ${var.project} ECS cluster"
  policy = data.template_file.surfpol.rendered
}
