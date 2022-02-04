resource "aws_sns_topic" "middleware_metrics" {
  name = "middleware-metrics"
  display_name = "Middleware Metrics"
  kms_master_key_id = var.monitoring_kms_key
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.middleware_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.middleware_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "middleware_cpu" {
  alarm_name                = "middleware-cpu"
  dimensions                = {
    "ClusterName" = "nppo"
    "ServiceName" = "middleware"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CpuUtilized"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container cpu utilization"

  alarm_actions = [aws_sns_topic.middleware_metrics.arn]
  ok_actions = [aws_sns_topic.middleware_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "middleware_memory" {
  alarm_name                = "middleware-memory"
  dimensions                = {
    "ClusterName" = "nppo"
    "ServiceName" = "middleware"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container memory utilization"

  alarm_actions = [aws_sns_topic.middleware_metrics.arn]
  ok_actions = [aws_sns_topic.middleware_metrics.arn]
}
