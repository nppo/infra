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
  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "deny_http_policy" {
  bucket = aws_s3_bucket.surfpol-image-uploads.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "${aws_s3_bucket.surfpol-image-uploads.arn}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_event_rule" "clearlogins" {
  name        = "clearlogins"
  description = "Runs the clearlogins command every day"

  # Every day at 2:00 am UTC
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "sync_category_filters" {
  name        = "sync_category_filters"
  description = "Runs the sync_category_filters command every day"

  # Every day at 6:00 am UTC
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "sync_materials" {
  name        = "sync_materials"
  description = "Runs the sync_materials command every day"

  # Every day at 6:00 am UTC
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_rule" "monitor_uptime" {
  count = var.monitor_uptime ? 1 : 0

  name        = "monitor_uptime"
  description = "Sends monthly report to SURFrapportage"

  # Every first day of month @ 4 o'clock
  schedule_expression = "cron(0 4 1 * ? *)"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/search-portal"
  retention_in_days = 14
}

# health check

resource "aws_route53_health_check" "uptime_health_check" {
  count = var.monitor_uptime ? 1 : 0
  failure_threshold = "3"
  fqdn              = "edusources.nl"
  port              = 443
  request_interval  = "30"
  type              = "HTTPS"
  tags = {
    Name = "edusources-check"
  }
}
