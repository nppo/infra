variable "project" {
  description = "Project to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "env" {
  description = "Which environment this vpc belongs to"
  type        = string
  default     = ""
}

variable "application_task_role_arn" {
  description = "The ARN of the application role"
  type        = string
  default     = ""
}

variable "superuser_task_role_arn" {
  description = "The ARN of the superuser role"
  type        = string
  default     = ""
}
