resource "aws_secretsmanager_secret" "django" {
  name = "search-portal/django"
  description = "Mainly the Django SECRET_KEY setting, but possibly in the future other miscellaneous secrets"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = aws_secretsmanager_secret.django.id
  secret_string = jsonencode({ secret_key = "" })
}

resource "aws_secretsmanager_secret" "surfconext" {
  name = "search-portal/surfconext"
  description = "The OIDC secret key"
}

resource "aws_secretsmanager_secret_version" "surfconext" {
  secret_id     = aws_secretsmanager_secret.surfconext.id
  secret_string = jsonencode({ secret_key = "" })
}

resource "aws_secretsmanager_secret" "elastic_search" {
  name = "search-portal/elastic"
  description = "Password for connecting to Elastic Search service"
}

resource "aws_secretsmanager_secret_version" "elastic_search" {
  secret_id     = aws_secretsmanager_secret.elastic_search.id
  secret_string = jsonencode({ password = "" })
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

resource "aws_iam_role" "application_task_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_role_policy.json
}

data "template_file" "task_secrets_policy" {
  template = file("${path.module}/task-secrets-policy.json.tpl")
  vars = {
    django_credentials_arn = aws_secretsmanager_secret.django.arn
    surfconext_credentials_arn = aws_secretsmanager_secret.surfconext.arn
    elastic_search_credentials_arn = aws_secretsmanager_secret.elastic_search.arn
    postgres_credentials_application_arn = var.postgres_credentials_application_arn
  }
}

resource "aws_iam_policy" "task_secrets_policy" {
  name        = "ecsTasksSecretsPolicy"
  description = "Policy for using secrets by tasks on ECS cluster"
  policy = data.template_file.task_secrets_policy.rendered
}

resource "aws_iam_policy" "elasticsearch_read_access" {
  name        = "SurfpolElasticSearchReadAccess"
  description = "Policy for read-access to surfpol elasticsearch cluster"
  policy = templatefile(
    "${path.module}/elasticsearch_read_access.json.tpl",
    { elasticsearch_arn: var.elasticsearch_arn }
  )
}

resource "aws_iam_policy" "elasticsearch_full_access" {
  name        = "SurfpolElasticSearchFullAccess"
  description = "Policy for full access to surfpol elasticsearch cluster"
  policy = templatefile(
    "${path.module}/elasticsearch_full_access.json.tpl",
    { elasticsearch_arn: var.elasticsearch_arn }
  )
}

resource "aws_iam_policy" "s3_read_write" {
  name        = "SurfpolS3ReadWrite"
  description = "Policy for read/write access to image upload bucket"
  policy = templatefile(
    "${path.module}/s3_read_write.json.tpl",
    { bucket_arn: var.image_upload_bucket_arn }
  )
}

resource "aws_iam_role_policy_attachment" "application_secretsmanager" {
  role = aws_iam_role.application_task_role.name
  policy_arn = aws_iam_policy.task_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "application_task_execution" {
  role       = aws_iam_role.application_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "application_elastic" {
  role = aws_iam_role.application_task_role.name
  policy_arn = aws_iam_policy.elasticsearch_read_access.arn
}

resource "aws_iam_role_policy_attachment" "application_s3" {
  role = aws_iam_role.application_task_role.name
  policy_arn = aws_iam_policy.s3_read_write.arn
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

resource "aws_iam_role_policy_attachment" "superuser_elastic" {
  role = aws_iam_role.superuser_task_role.name
  policy_arn = aws_iam_policy.elasticsearch_full_access.arn
}

resource "aws_cloudwatch_event_rule" "clearlogins" {
  name        = "clearlogins"
  description = "Runs the clearlogins command every day"

  # Every day at 2:00 am UTC
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_iam_role" "ecs_events_role" {
  name = "ecsEventsRole"
  assume_role_policy = data.aws_iam_policy_document.events.json
}

data "aws_iam_policy_document" "events" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "scheduled_event_ecs" {
  name        = "AmazonEC2ContainerServiceEventsRole"
  description = "Permission to run ECS tasks"
  policy = templatefile(
    "${path.module}/ecs-events-policy.json.tpl", {}
  )
}

resource "aws_iam_policy" "event_task_role" {
  name        = "AmazonECSEventsTaskExecutionRole"
  description = "Permission to run ECS tasks as application role"
  policy = templatefile(
    "${path.module}/ecs-events-task-execution.json.tpl",
    { task_role_arn: aws_iam_role.application_task_role.arn }
  )
}

resource "aws_iam_role_policy_attachment" "scheduled_event_ecs_tasks" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = aws_iam_policy.scheduled_event_ecs.arn
}

resource "aws_iam_role_policy_attachment" "scheduled_event_ecs_task_role" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = aws_iam_policy.event_task_role.arn
}
