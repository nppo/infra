data "template_file" "harvester_task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = var.django_secrets_arn
    postgres_credentials_application_arn = var.postgres_credentials_application_arn
  }
}

resource "aws_iam_policy" "harvester_task_secrets_policy" {
  name        = "ecsHarvesterTasksSecretsPolicy"
  description = "Policy for using secrets by harvester tasks"
  policy = data.template_file.harvester_task_secrets_policy.rendered
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.harvester_task_secrets_policy.arn
}

resource "aws_elasticache_subnet_group" "harvester_redis_subnet_group" {
  name       = "harvester-redis-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "harvester_redis" {
  cluster_id           = "harvester"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.harvester_redis_subnet_group.name
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/harvester"
  retention_in_days = 14
}
