terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "trento-telemetry-terraform-backend"
    key = "trento-telemetry"
  }
}

# use environment variables or shared credentials file
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
provider "aws" {
  region     = var.region
}
