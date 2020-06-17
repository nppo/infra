locals {
  common_tags = {
    Project = var.project
    Environment = var.env
    ProvisionedBy = "Terraform"
  }
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
    task_execution_role_arn = var.application_task_role_arn
    superuser_task_execution_role_arn = var.superuser_task_role_arn
    cluster_arn = aws_ecs_cluster.surfpol.arn
  }
}

resource "aws_iam_policy" "surfpol-ecs" {
  name        = "${var.project}-ecs-manage"
  description = "Policy for managing the ${var.project} ECS cluster"
  policy = data.template_file.surfpol.rendered
}
