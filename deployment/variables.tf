# Influxdb variables

variable "influxdb_url" {
  type        = string
  description = "Influxdb database url (it doesn't containt the organization id). Example: https://influxdb.com"
}

variable "influxdb_token" {
  type        = string
  description = "Influxdb connection token. It must have bucket and api creation authorizations"
}

variable "influxdb_org" {
  type        = string
  description = "The organization id of the deployed Influxdb"
}

variable "influxdb_bucket" {
  type        = string
  description = "Created Influxdb bucket name. This bucket will have write/read authorizations through an API token"
  default     = "trento-telemetry"
}

# ECS variables

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "region" {
  type        = string
  description = "AWS region to deploy the ECS cluster and resources"
  default     = "eu-west-2"
}

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

variable "container_image" {
  type        = string
  description = "Deployed container name"
  default     = "ghcr.io/trento-project/telemetry"
}

variable "container_tag" {
  type        = string
  description = "Deployed container tag"
  default     = "latest"
}

variable "container_port" {
  type        = number
  description = "Port where the telemetry service is listening within the container"
  default     = 10000
}

variable "load_balancer_port" {
  type        = number
  description = "Port where the load balancer is listening"
  default     = 80
}
