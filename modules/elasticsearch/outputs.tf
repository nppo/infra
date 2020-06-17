output "elasticsearch_arn" {
  value = aws_elasticsearch_domain.this.arn
  description = "The ARN of the elastic search cluster"
}
