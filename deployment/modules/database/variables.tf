variable "name" {
  type        = string
  description = "Given prefix name of the deployed resources"
}

variable "environment" {
  type        = string
  description = "Given environment name to group the resources names"
}

variable "vpc_id" {
  type        = string
  description = "Used VPC id"
}

variable "database_subnets" {
  type        = list
  description = "List of database subnets in the used VPC"
}
