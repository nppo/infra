resource "aws_sns_topic" "elastic_metrics" {
  name = "elastic-metrics"
  display_name = "Elastic Search Metrics"
  kms_master_key_id = var.monitoring_kms_key
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.elastic_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.elastic_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "elastic_cpu" {
  alarm_name                = "elastic-cpu"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ES"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors Elastic Search cluster cpu utilization"

  alarm_actions = [aws_sns_topic.elastic_metrics.arn]
  ok_actions = [aws_sns_topic.elastic_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "elastic_memory" {
  alarm_name                = "elastic-memory"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ES"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "40"
  alarm_description         = "This metric monitors Elastic Search cluster memory utilization"

  alarm_actions = [aws_sns_topic.elastic_metrics.arn]
  ok_actions = [aws_sns_topic.elastic_metrics.arn]
}
