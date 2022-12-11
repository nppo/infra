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

resource "aws_ecs_cluster" "nppo" {
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

data "template_file" "nppo" {
  template = file("${path.module}/cluster-policy.json.tpl")
  vars = {
    task_execution_role_arn = aws_iam_role.application_task_role.arn
    superuser_task_execution_role_arn = aws_iam_role.superuser_task_role.arn
    cluster_arn = aws_ecs_cluster.nppo.arn
  }
}

resource "aws_iam_policy" "nppo-ecs" {
  name        = "${var.project}-ecs-manage"
  description = "Policy for managing the ${var.project} ECS cluster"
  policy = data.template_file.nppo.rendered
}

resource "aws_iam_policy" "exec-ecs" {
  name        = "EcsExec-cluster"
  description = "Policy to enable ECS exec"
  policy = templatefile(
  "${path.module}/ecs_exec.json.tpl", {}
  )
}
