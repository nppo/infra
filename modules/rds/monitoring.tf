resource "aws_sns_topic" "rds_metrics" {
  name = "rds-metrics"
  display_name = "RDS Metrics"
  kms_master_key_id = var.monitoring_kms_key
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.rds_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.rds_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name                = "rds-cpu"
  dimensions                = {
    "DBInstanceIdentifier" = aws_db_instance.surfpol.identifier
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "60"
  alarm_description         = "This metric monitors postgres cpu utilization"

  alarm_actions = [aws_sns_topic.rds_metrics.arn]
  ok_actions = [aws_sns_topic.rds_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name                = "rds-memory"
  dimensions                = {
    "DBInstanceIdentifier" = aws_db_instance.surfpol.identifier
  }
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "FreeableMemory"
  namespace                 = "AWS/RDS"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "40"
  alarm_description         = "This metric monitors postgres free memory"

  alarm_actions = [aws_sns_topic.rds_metrics.arn]
  ok_actions = [aws_sns_topic.rds_metrics.arn]
}
