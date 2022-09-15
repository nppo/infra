variable "project" {
  description = "Project to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "env" {
  description = "Which environment this db belongs to"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC to create this db in"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "A list of subnet ids this db will be made available in"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = ""
}

variable "monitoring_kms_key" {
  description = "KMS key for monitoring"
  type        = string
  default     = ""
}

variable "aws_services_protect_security_group_id" {
  description = "The id of the VPC security group that protects AWS services"
  type        = string
  default     = ""
}
