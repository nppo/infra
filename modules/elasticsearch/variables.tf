variable "domain_name" {
  description = "Name for this ElasticSearch domain. Will be appended to project and env."
  type        = string
  default     = ""
}

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

variable "elasticsearch_version" {
  description = "The version of ElasticSearch to deploy"
  type        = string
  default     = "7.4"
}

variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.medium.elasticsearch"
}

variable "instance_count" {
  description = "The number of instances"
  type        = number
  default     = 1
}

variable "instance_volume_size" {
  description = "The volume size per instance in GB"
  type        = number
  default     = 10
}

variable "vpc_id" {
  description = "ID of the VPC the domain will be created in"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "VPC Subnet ID for the domain endpoints to be created in."
  type        = string
  default     = ""
}

variable "log_group_arn" {
  description = "The ARN of the log group to write logs to"
  type        = string
  default     = ""
}

