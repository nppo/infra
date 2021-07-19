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

variable "superuser_task_role_name" {
  description = "The name of thes superuser IAM role"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC to create the service in"
  type        = string
  default     = ""
}

variable "monitoring_kms_key" {
  description = "KMS key for monitoring"
  type        = string
  default     = ""
}

variable "harvester_bucket_arn" {
  description = "arn of harvester content bucket"
  type        = string
  default     = ""
}

variable "monitor_uptime" {
  description = "Boolean to define whether uptime is sent to SURFrapportage"
  type        = bool
  default     = false
}

variable "exec_policy_arn" {
  description = "ARN of the policy that allows entering containers"
  type        = string
  default     = ""
}
