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

resource "aws_iam_role" "application_task_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "application_task_execution" {
  role       = aws_iam_role.application_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "harvester_task_role" {
  name = "ecsHarvesterTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "harvester_task_execution" {
  role       = aws_iam_role.harvester_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

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

resource "aws_secretsmanager_secret" "django" {
  name = "search-portal/django"
  description = "Mainly the Django SECRET_KEY setting, but possibly in the future other miscellaneous secrets"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({ secret_key = "" })
}
