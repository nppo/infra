resource "aws_sns_topic" "harvester_metrics" {
  name = "harvester-metrics"
  display_name = "Harvester Metrics"
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.harvester_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.harvester_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "harvester_cpu" {
  alarm_name                = "harvester-cpu"
  dimensions                = {
    "ClusterName" = "surfpol"
    "ServiceName" = "harvester"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CpuUtilized"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container cpu utilization"

  alarm_actions = [aws_sns_topic.harvester_metrics.arn]
  ok_actions = [aws_sns_topic.harvester_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "harvester_memory" {
  alarm_name                = "harvester-memory"
  dimensions                = {
    "ClusterName" = "surfpol"
    "ServiceName" = "harvester"
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "ECS/ContainerInsights"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors container memory utilization"

  alarm_actions = [aws_sns_topic.harvester_metrics.arn]
  ok_actions = [aws_sns_topic.harvester_metrics.arn]
}
