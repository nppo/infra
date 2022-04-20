variable "harvester_task_role_name" {
  description = "The name of the IAM role that is used by harvester tasks"
  type        = string
  default     = ""
}

variable "middleware_task_role_name" {
  description = "The name of the IAM role that is used by middleware tasks"
  type        = string
  default     = ""
}

variable "superuser_task_role_name" {
  description = "The name of the superuser IAM role"
  type        = string
  default     = ""
}
