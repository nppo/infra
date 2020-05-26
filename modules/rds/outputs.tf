output "security_group_access_id" {
  value = aws_security_group.access.id
  description = "The id of the security group that gives access to this database"
}

output "postgres_password" {
  value = jsondecode(data.aws_secretsmanager_secret_version.postgres_credentials.secret_string)["password"]
}
