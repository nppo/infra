resource "aws_iam_role" "harvester_task_role" {
  name = "ecsHarvesterTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "harvester_task_execution" {
  role       = aws_iam_role.harvester_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "harvester_container_definitions" {
  template = file("${path.module}/container-definitions/harvester.json.tpl")
  vars = {
    env = var.env
    application_project = var.application_project
    application_mode = var.application_mode
    docker_registry = var.docker_registry
    flower_secret = substr( # cuts the version string to allow secret rotation upon deploy
      var.flower_credentials_arn,
      0,
      length(var.flower_credentials_arn) - 7
    )
  }
}

resource "aws_ecs_task_definition" "harvester" {
  family = "harvester"
  container_definitions = data.template_file.harvester_container_definitions.rendered
  network_mode = "awsvpc"
  task_role_arn = aws_iam_role.harvester_task_role.arn  # gives harvester access to AWS services
  execution_role_arn = aws_iam_role.harvester_task_role.arn  # gives Fargate access to AWS services
  memory = 8192
  cpu = 2048
}

data "template_file" "celery_container_definitions" {
  template = file("${path.module}/container-definitions/celery.json.tpl")
  vars = {
    env = var.env
    application_project = var.application_project
    application_mode = var.application_mode
    docker_registry = var.docker_registry
  }
}

resource "aws_ecs_task_definition" "celery" {
  family = "celery"
  container_definitions = data.template_file.celery_container_definitions.rendered
  network_mode = "awsvpc"
  task_role_arn = aws_iam_role.harvester_task_role.arn  # gives harvester access to AWS services
  execution_role_arn = aws_iam_role.harvester_task_role.arn  # gives Fargate access to AWS services
  memory = 8192
  cpu = 2048
}

data "template_file" "command_container_definitions" {
  template = file("${path.module}/container-definitions/harvester-command.json.tpl")
  vars = {
    env = var.env
    application_project = var.application_project
    application_mode = var.application_mode
    docker_registry = var.docker_registry
  }
}

resource "aws_ecs_task_definition" "command" {
  family = "harvester-command"
  container_definitions = data.template_file.command_container_definitions.rendered
  network_mode = "awsvpc"
  task_role_arn = aws_iam_role.harvester_task_role.arn  # gives harvester access to AWS services
  execution_role_arn = aws_iam_role.harvester_task_role.arn  # gives Fargate access to AWS services
  memory = 8192
  cpu = 2048
}

resource "aws_service_discovery_private_dns_namespace" "nppo" {
  name        = "nppo"
  description = null
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "harvester" {
  name = "harvester"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.nppo.id

    dns_records {
      ttl  = 300
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "harvester" {
  name = "harvester"
  cluster = aws_ecs_cluster.nppo.arn
  task_definition = aws_ecs_task_definition.harvester.arn
  depends_on = [aws_iam_role_policy_attachment.harvester_task_execution]
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
    target_group_arn = var.harvester_target_group
    container_name = "harvester-nginx"
    container_port = 80
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [
      var.default_security_group,
      var.harvester_protect_security_group,
      var.postgres_access_security_group,
      var.opensearch_access_security_group,
      var.redis_access_security_group
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.harvester.arn
  }
}

resource "aws_ecs_service" "celery" {
  name = "celery"
  cluster = aws_ecs_cluster.nppo.arn
  task_definition = aws_ecs_task_definition.celery.arn
  depends_on = [aws_iam_role_policy_attachment.harvester_task_execution]
  enable_ecs_managed_tags = true

  desired_count = 1
  enable_execute_command = true
  force_new_deployment = true
  wait_for_steady_state = true

  capacity_provider_strategy {
    base = 0
    capacity_provider = "FARGATE"
    weight = 1
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [
      var.default_security_group,
      var.harvester_protect_security_group,
      var.postgres_access_security_group,
      var.opensearch_access_security_group,
      var.redis_access_security_group
    ]
  }
}
