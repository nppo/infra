output "elasticsearch_arn" {
  value = aws_elasticsearch_domain.this.arn
  description = "The ARN of the elastic search cluster"
}

output "elasticsearch_read_access_arn" {
  value = aws_iam_policy.elasticsearch_read_access.arn
  description = "The ARN of the elastic search read only role"
}
