resource "aws_secretsmanager_secret" "django_harvester" {
  name = "search-portal/django-harvester"
  description = "Mainly the Django SECRET_KEY setting for harvester, but possibly in the future other miscellaneous secrets"
}

resource "aws_secretsmanager_secret_version" "django_harvester" {
  secret_id     = aws_secretsmanager_secret.django_harvester.id
  secret_string = jsonencode({ secret_key = "" })
}

data "template_file" "task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = aws_secretsmanager_secret.django_harvester.arn
    postgres_credentials_application_arn = var.postgres_credentials_application_arn
  }
}

resource "aws_iam_policy" "task_secrets_policy" {
  name        = "ecsTasksSecretsPolicy"
  description = "Policy for using secrets by harvester tasks"
  policy = data.template_file.task_secrets_policy.rendered
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = var.harvester_task_role_name
  policy_arn = aws_iam_policy.task_secrets_policy.arn
}

resource "aws_elasticache_cluster" "harvester_redis" {
  cluster_id           = "harvester"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.6"
  port                 = 6379
}
