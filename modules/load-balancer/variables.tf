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
  description = "A list of subnet ids this loadbalancer will be made available in"
  type        = list(string)
  default     = []
}

variable "eduvpn_ips" {
  description = "A list of eduvpn ips"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = ""
}

variable "default_security_group_id" {
  description = "The ID of the default security group"
  type = string
  default = ""
}
