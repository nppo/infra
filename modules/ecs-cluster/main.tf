locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
}

data "aws_iam_policy_document" "this" {
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

resource "aws_iam_role" "this" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "secretsmanager" {
  role = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "s3" {
  role = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
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
  template = file("${path.module}/policy.json.tpl")
  vars = {
    task_execution_role_arn = aws_iam_role.this.arn
    cluster_arn = aws_ecs_cluster.surfpol.arn
  }
}

resource "aws_iam_policy" "surfpol-ecs" {
  name        = "${var.project}-ecs-manage"
  description = "Policy for managing the ${var.project} ECS cluster"
  policy = data.template_file.surfpol.rendered
}
