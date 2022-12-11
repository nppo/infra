output "harvester_target_group" {
  value = aws_lb_target_group.harvester-target.arn
  description = "The ARN of the harvester target group"
}

output "search_target_group" {
  value = aws_lb_target_group.search-target.arn
  description = "The ARN of the search target group"
}

output "middleware_target_group" {
  value = aws_lb_target_group.middleware-target.arn
  description = "The ARN of the middleware target group"
}
