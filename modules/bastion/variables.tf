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

variable "ipv4_eduvpn_ips" {
  description = "A list of ipv4 eduvpn ips"
  type        = list(string)
  default     = []
}

variable "ipv6_eduvpn_ips" {
  description = "A list of ipv6 eduvpn ips"
  type        = list(string)
  default     = []
}

variable "public_keys" {
  description = "Mapping of name to public key"
  type        = map(string)
  default     = {}
}

variable "database_security_group" {
  description = "ID of the database security group"
  type        = string
  default     = ""
}

variable "harvester_security_group" {
  description = "ID of the harvester security group"
  type        = string
  default     = ""
}

variable "default_security_group_id" {
  description = "The ID of the default security group"
  type = string
  default = ""
}
