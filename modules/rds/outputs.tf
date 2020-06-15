output "security_group_access_id" {
  value = aws_security_group.access.id
  description = "The id of the security group that gives access to this database"
}

output "postgres_credentials_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "postgres_credentials_application_arn" {
  value = aws_secretsmanager_secret.rds_credentials_application.arn
}
