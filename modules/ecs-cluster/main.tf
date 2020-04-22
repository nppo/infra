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

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.env}"
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

data "template_file" "this" {
  template = file("${path.module}/policy.json.tpl")
  vars = {
    task_execution_role_arn = aws_iam_role.this.arn
    cluster_arn = aws_ecs_cluster.this.arn
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.env}-ecs-manage"
  description = "Policy for managing the ${var.project}-${var.env} ECS cluster"
  policy = data.template_file.this.rendered
}
