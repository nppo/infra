resource "aws_sns_topic" "service_metrics" {
  name = "service-metrics"
  display_name = "Service Metrics"
  kms_master_key_id = var.monitoring_kms_key
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
