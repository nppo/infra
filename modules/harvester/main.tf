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
  security_group_ids   = [aws_security_group.protect_redis.id]
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/harvester"
  retention_in_days = 14
}

resource "aws_s3_bucket" "harvester_content_bucket" {
  bucket = var.harvester_content_bucket_name
}

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
  alarm_name                = "service-cpu"
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
  alarm_name                = "service-memory"
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
