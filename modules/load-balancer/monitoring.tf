resource "aws_sns_topic" "load_balancer_metrics" {
  name = "load-balancer-metrics"
  display_name = "Load Balancer Metrics"
}

data "template_file" "sns_cloudwatch_policy" {
  template = file("${path.module}/../cloudwatch/sns-cloudwatch-policy.json.tpl")
  vars = {
    sns_topic_arn = aws_sns_topic.load_balancer_metrics.arn
  }
}

resource "aws_sns_topic_policy" "sns_cloudwatch_policy" {
  arn = aws_sns_topic.load_balancer_metrics.arn

  policy = data.template_file.sns_cloudwatch_policy.rendered
}

resource "aws_cloudwatch_metric_alarm" "load_balancer_50x" {
  alarm_name                = "load-balancer-50x"
  dimensions                = {
    "LoadBalancer" = aws_lb.surfpol.arn
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "HTTPCode_ELB_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors the amount of 50x coming from the load balancer"

  alarm_actions = [aws_sns_topic.load_balancer_metrics.arn]
  ok_actions = [aws_sns_topic.load_balancer_metrics.arn]
}

resource "aws_cloudwatch_metric_alarm" "targets_50x" {
  alarm_name                = "targets-50x"
  dimensions                = {
    "LoadBalancer" = aws_lb.surfpol.arn
  }
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "HTTPCode_Target_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors the amount of 50x coming from the targets"

  alarm_actions = [aws_sns_topic.load_balancer_metrics.arn]
  ok_actions = [aws_sns_topic.load_balancer_metrics.arn]
}
