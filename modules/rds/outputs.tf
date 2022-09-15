output "postgres_credentials_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}
