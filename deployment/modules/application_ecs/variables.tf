# Influxdb variables

variable "influxdb_url" {
  type        = string
  description = "Influxdb service url"
}

variable "influxdb_token" {
  type        = string
  description = "Influxdb API token"
}

variable "influxdb_org" {
  type        = string
  description = "The organization id of the deployed Influxdb"
}

variable "influxdb_bucket" {
  type        = string
  description = "Created Influxdb bucket name. This bucket will have write/read authorizations through an API token"
}

# Database variables

variable "database_address" {
  type        = string
  description = "PostgreSQL database address"
}

variable "database_port" {
  type        = string
  description = "PostgreSQL database port"
}

variable "database_user" {
  type        = string
  description = "PostgreSQL database user name"
}

variable "database_password" {
  type        = string
  description = "PostgreSQL database password"
}

variable "database_name" {
  type        = string
  description = "PostgreSQL database name"
}

# ECS variables

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

variable "vpc_id" {
  type        = string
  description = "Used VPC id"
}

variable "public_subnets" {
  type        = list
  description = "List of public subnets in the used VPC"
}

variable "private_subnets" {
  type        = list
  description = "List of private subnets in the used VPC"
}
