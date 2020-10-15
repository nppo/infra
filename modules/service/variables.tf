variable "env" {
  description = "Which environment this service belongs to"
  type        = string
  default     = ""
}

variable "application_task_role_arn" {
  description = "The ARN of the IAM role that is used by normal tasks"
  type        = string
  default     = ""
}

variable "application_task_role_name" {
  description = "The name of the IAM role that is used by normal tasks"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC to create the service in"
  type        = string
  default     = ""
}
