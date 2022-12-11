resource "aws_iam_role" "middleware_task_role" {
  name = "ecsMiddlewareTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "middleware_task_execution" {
  role       = aws_iam_role.middleware_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "middleware_container_definitions" {
  template = file("${path.module}/container-definitions/middleware.json.tpl")
  vars = {
    env = var.env
    application_project = var.application_project
    application_mode = var.application_mode
    docker_registry = var.docker_registry
  }
}

resource "aws_ecs_task_definition" "middleware" {
  family = "middleware"
  container_definitions = data.template_file.middleware_container_definitions.rendered
  network_mode = "awsvpc"
  task_role_arn = aws_iam_role.middleware_task_role.arn  # gives middleware access to AWS services
  execution_role_arn = aws_iam_role.middleware_task_role.arn  # gives Fargate access to AWS services
  memory = 8192
  cpu = 2048
}

resource "aws_ecs_service" "middleware" {
  name = "middleware"
  cluster = aws_ecs_cluster.nppo.arn
  task_definition = aws_ecs_task_definition.middleware.arn
  depends_on = [aws_iam_role_policy_attachment.middleware_task_execution]
  enable_ecs_managed_tags = true

  desired_count = 2
  enable_execute_command = true
  force_new_deployment = true
  wait_for_steady_state = true

  capacity_provider_strategy {
    base = 0
    capacity_provider = "FARGATE"
    weight = 1
  }

  load_balancer {
    target_group_arn = var.middleware_target_group
    container_name = "middleware-nginx"
    container_port = 80
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [
      var.default_security_group,
      var.middleware_protect_security_group,
      var.aws_services_access_security_group_id
    ]
  }
}
