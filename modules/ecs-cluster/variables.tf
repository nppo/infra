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

variable "application_project" {
  description = "Application project that services should start with"
  type = string
  default = ""
}

variable "application_mode" {
  description = "Application mode that services should start with"
  type = string
  default = ""
}

variable "docker_registry" {
  description = "Domain of the Docker registry that should be used"
  type = string
  default = ""
}

variable "harvester_target_group" {
  description = "The harvester target group"
  type        = string
  default     = ""
}

variable "service_target_group" {
  description = "The service target group"
  type        = string
  default     = ""
}

variable "flower_credentials_arn" {
  description = "The flower credentials ARN"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC services will be placed in"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "A list of public subnet ids"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "A list of private subnet ids"
  type        = list(string)
  default     = []
}

variable "default_security_group" {
  description = "The default security group for the VPN"
  type        = string
  default     = ""
}

variable "postgres_access_security_group" {
  description = "The security group that gives access to Postgres database"
  type        = string
  default     = ""
}

variable "opensearch_access_security_group" {
  description = "The security group that gives access to Opensearch"
  type        = string
  default     = ""
}

variable "redis_access_security_group" {
  description = "The security group that gives access to Redis"
  type        = string
  default     = ""
}

variable "harvester_access_security_group" {
  description = "The security group that gives access to the harvester"
  type        = string
  default     = ""
}

variable "harvester_protect_security_group" {
  description = "The security group that protects the harvester"
  type        = string
  default     = ""
}

variable "search_protect_security_group" {
  description = "The security group that protects the search service"
  type        = string
  default     = ""
}

variable "ecs_event_role" {
  description = "The ECS event role required for Cloud Watch event targets"
  type        = string
  default     = ""
}
