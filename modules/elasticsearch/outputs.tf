output "elasticsearch_arn" {
  value = aws_elasticsearch_domain.this.arn
  description = "The ARN of the elastic search cluster"
}

output "elasticsearch_security_group" {
  value = aws_security_group.this.id
  description = "The id of the elasticsearch security group"
}

output "opensearch_credentials_arn" {
  value = aws_secretsmanager_secret_version.opensearch_password_version.arn
  description = "The password of the opensearch main user"
}
