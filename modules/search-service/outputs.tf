output "search_access_security_group_id" {
  value = aws_security_group.access_service.id
  description = "The id of the security group that may access the search service"
}
