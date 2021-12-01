variable "name" {
  type        = string
  description = "Given prefix name of the deployed resources"
  default     = "trento"
}

variable "environment" {
  type        = string
  description = "Given environment name to group the resources names"
  default     = "default"
}
