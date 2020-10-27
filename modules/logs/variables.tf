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

variable "elasticsearch_security_group" {
  description = "ID of the elasticsearch security group"
  type        = string
  default     = ""
}
