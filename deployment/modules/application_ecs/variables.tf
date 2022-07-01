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

# Grafana

variable "grafana_port" {
  type        = number
  description = "Grafana instance public port"
}

variable "grafana_container_image" {
  type        = string
  description = "Deployed container name"
}

# ECS variables

variable "region" {
  type        = string
  description = "AWS region to deploy the ECS cluster and resources"
}

variable "name" {
  type        = string
  description = "Given prefix name of the deployed resources"
}

variable "environment" {
  type        = string
  description = "Given environment name to group the resources names"
}

variable "container_image" {
  type        = string
  description = "Deployed container name"
}

variable "container_port" {
  type        = number
  description = "Port where the telemetry service is listening within the container"
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

variable "lb_certificate_arn" {
  type        = string
  description = "The TLS certificate ARN to use for the TLS termination in ELB"
}

# Route 53

variable "dns_zone" {
  type        = string
  description = "The Route 53 DNS zone to add DNS records to"
}

variable "dns_cname" {
  type        = string
  description = "The name of the CNAME record to add"
}
