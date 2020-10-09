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

variable "subnet_ids" {
  description = "A list of subnet ids the redis queue will be made available in"
  type        = list(string)
  default     = []
}

variable "harvester_content_bucket_name" {
  description = "Bucket name where harvester content gets stored"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC to create the harvester in"
  type        = string
  default     = ""
}
