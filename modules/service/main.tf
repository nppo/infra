resource "aws_secretsmanager_secret" "surfconext" {
  name = "search-portal/surfconext"
  description = "The OIDC secret key"
}

resource "aws_secretsmanager_secret_version" "surfconext" {
  secret_id     = aws_secretsmanager_secret.surfconext.id
  secret_string = jsonencode({ secret_key = "" })
}

# These Elastic Search secrets refer to resources outside of AWS
# They are only used by the search-portal service
resource "aws_secretsmanager_secret" "elastic_search" {
  name = "search-portal/elastic"
  description = "Password for connecting to Elastic Search service"
}

resource "aws_secretsmanager_secret_version" "elastic_search" {
  secret_id     = aws_secretsmanager_secret.elastic_search.id
  secret_string = jsonencode({ password = "" })
}

resource "aws_s3_bucket" "surfpol-image-uploads" {
  bucket = "search-portal-media-uploads-${var.env}"
  acl = "public-read"
}

resource "aws_cloudwatch_event_rule" "clearlogins" {
  name        = "clearlogins"
  description = "Runs the clearlogins command every day"

  # Every day at 2:00 am UTC
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/search-portal"
  retention_in_days = 14
}

resource "aws_sns_topic" "service_metrics" {
  name = "service-metrics"
  display_name = "Service Metrics"
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.service_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.service_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "service_cpu" {
  alarm_name                = "service-cpu"
  dimensions                = {
    "ClusterName" = "surfpol"
    "ServiceName" = "search-portal"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CpuUtilized"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container cpu utilization"

  alarm_actions = [aws_sns_topic.service_metrics.arn]
  ok_actions = [aws_sns_topic.service_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_memory" {
  alarm_name                = "service-memory"
  dimensions                = {
    "ClusterName" = "surfpol"
    "ServiceName" = "search-portal"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container memory utilization"

  alarm_actions = [aws_sns_topic.service_metrics.arn]
  ok_actions = [aws_sns_topic.service_metrics.arn]
}
