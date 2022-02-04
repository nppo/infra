resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/middleware"
  retention_in_days = 14
}
