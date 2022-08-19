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
