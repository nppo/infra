variable "postgres_credentials_application_arn" {
  description = "The ARN for the application postgres credentials"
  type        = string
  default     = ""
}

variable "image_upload_bucket_arn" {
  description = "The ARN of the image upload bucket"
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

variable "django_secrets_arn" {
  description = "The ARN of the secret containing Django secrets"
  type = string
  default = ""
}
