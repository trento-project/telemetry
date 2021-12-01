data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name                 = var.name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  create_database_subnet_group = false

  public_subnet_tags = {
    Name        = "${var.name}-public-subnets-${var.environment}"
    Environment = var.environment
  }

  private_subnet_tags = {
    Name        = "${var.name}-private-subnets-${var.environment}"
    Environment = var.environment
  }

  database_subnet_group_tags = {
    Name        = "${var.name}-database-subnets-${var.environment}"
    Environment = var.environment
  }

  tags = {
    Name        = "${var.name}-vpc-${var.environment}"
    Environment = var.environment
  }
}
