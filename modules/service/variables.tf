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

variable "elasticsearch_read_access_arn" {
  description = "The ARN of the elastic search read only role"
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

variable "superuser_task_role_name" {
  description = "The name of the IAM role that is used by superuser tasks"
  type        = string
  default     = ""
}
