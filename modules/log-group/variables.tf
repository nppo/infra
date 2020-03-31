variable "name" {
  description = "The name of this log group. Will be appended to project and env."
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

variable "retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 14
}