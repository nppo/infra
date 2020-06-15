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

variable "postgres_credentials_application_arn" {
  description = "The ARN for the application postgres credentials"
  type        = string
  default     = ""
}
