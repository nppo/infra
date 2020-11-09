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

variable "elasticsearch_arn" {
  description = "ARN for the destination elasticsearch cluster"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "A list of subnet ids the kinesis datastream will be made available in"
  type        = list(string)
  default     = []
}

variable "firehose_security_group" {
  description = "ID of the elasticsearch access security group"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Name of the log backup bucket"
  type        = string
  default     = ""
}
