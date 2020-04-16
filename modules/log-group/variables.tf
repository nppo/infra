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