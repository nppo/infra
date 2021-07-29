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

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/search-portal"
  retention_in_days = 14
}
