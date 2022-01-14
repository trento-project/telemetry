variable "name" {
  type        = string
  description = "Given prefix name of the deployed resources"
}

variable "environment" {
  type        = string
  description = "Given environment name to group the resources names"
}

variable "sns_subscription_email_address_list" {
  type        = list(string)
  description = "List of email addresses to notify service state changes"
}

variable "ecs_arn" {
  type        = string
  description = "Created ECS cluster arn"
}
