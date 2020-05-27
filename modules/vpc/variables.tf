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

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
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
