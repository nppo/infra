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
