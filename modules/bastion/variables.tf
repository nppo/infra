variable "project" {
  description = "Project to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "env" {
  description = "Which environment this bastion belongs to"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet id to place the bastion into"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC id to place the bastion into"
  type        = string
  default     = ""
}
