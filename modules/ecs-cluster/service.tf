resource "aws_iam_role" "application_task_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "application_task_execution" {
  role       = aws_iam_role.application_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "service_container_definitions" {
  template = file("${path.module}/container-definitions/service.json.tpl")
  vars = {
    env = var.env
    application_project = var.application_project
    application_mode = var.application_mode
    docker_registry = var.docker_registry
  }
}

resource "aws_ecs_task_definition" "service" {
  family = "search-portal"
  container_definitions = data.template_file.service_container_definitions.rendered
  network_mode = "awsvpc"
  task_role_arn = aws_iam_role.application_task_role.arn  # gives harvester access to AWS services
  execution_role_arn = aws_iam_role.application_task_role.arn  # gives Fargate access to AWS services
  memory = 2048
  cpu = 1024
}

resource "aws_ecs_service" "service" {
  name = "search-portal"
  cluster = aws_ecs_cluster.nppo.arn
  task_definition = aws_ecs_task_definition.service.arn
  depends_on = [aws_iam_role_policy_attachment.application_task_execution]
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
    target_group_arn = var.service_target_group
    container_name = "search-portal-nginx"
    container_port = 80
  }

  network_configuration {
    assign_public_ip = true
    subnets = var.private_subnet_ids
    security_groups = [
      var.default_security_group,
      var.search_protect_security_group,
      var.postgres_access_security_group,
      var.opensearch_access_security_group,
      var.harvester_access_security_group
    ]
  }
}

resource "aws_cloudwatch_event_rule" "clearlogins_event_rule" {
  name = "clearlogins"
  description = "Runs the clearlogins command every day"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "clearlogins_scheduled_task" {
  rule = aws_cloudwatch_event_rule.clearlogins_event_rule.name
  target_id = "1"
  arn = aws_ecs_cluster.nppo.arn
  role_arn = "arn:aws:iam::825135206789:role/ecsEventsRole"

  input = jsonencode({
    containerOverrides = [
      {
        command = ["python", "manage.py", "clearlogins"]
        name = "search-portal-container"
      }
    ]
  })

  ecs_target {
    launch_type = "FARGATE"
    platform_version = "LATEST"
    task_count = 1
    task_definition_arn = aws_ecs_task_definition.service.arn
    network_configuration {
      subnets = [var.private_subnet_ids[0]]
      security_groups = [
        var.default_security_group,
        var.postgres_access_security_group
      ]
    }
  }
}
