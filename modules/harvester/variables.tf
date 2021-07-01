variable "harvester_task_role_name" {
  description = "The name of the IAM role that is used by harvester tasks"
  type        = string
  default     = ""
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

variable "monitoring_kms_key" {
  description = "KMS key for monitoring"
  type        = string
  default     = ""
}

variable "exec_policy_arn" {
  description = "ARN of the policy that allows entering containers"
  type        = string
  default     = ""
}
