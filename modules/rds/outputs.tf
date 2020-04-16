output "security_group_access_id" {
  value = aws_security_group.access.id
  description = "The id of the security group that gives access to this database"
}

output "password" {
  value = random_password.password.result
  description = "Password of the main user of the database"
}