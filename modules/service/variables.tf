variable "postgres_credentials_application_arn" {
  description = "The ARN for the application postgres credentials"
  type        = string
  default     = ""
}

variable "elasticsearch_arn" {
  description = "The ARN of the elasticsearch cluster"
  type        = string
  default     = ""
}
