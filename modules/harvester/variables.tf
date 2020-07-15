variable "postgres_credentials_application_arn" {
  description = "The ARN for the application postgres credentials"
  type        = string
  default     = ""
}

variable "harvester_task_role_name" {
  description = "The name of the IAM role that is used by harvester tasks"
  type        = string
  default     = ""
}

variable "django_secrets_arn" {
  description = "The ARN of the secret containing Django secrets"
  type = string
  default = ""
}
