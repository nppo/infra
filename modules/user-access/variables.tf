variable "users" {
  description = "Mapping of users to create to group memberships"
  type        = map(list(string))
  default     = {}
}