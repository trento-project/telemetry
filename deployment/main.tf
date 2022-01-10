module "network" {
  source = "./modules/network"

  name        = var.name
  environment = var.environment
}

module "database" {
  source = "./modules/database"

  name              = var.name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  database_subnets  = module.network.database_subnets
}

module "telemetry_application" {
  source      = "./modules/application_ecs"

  name               = var.name
  region             = var.region
  environment        = var.environment
  container_image    = var.container_image
  lb_certificate_arn = var.lb_certificate_arn

  influxdb_url    = var.influxdb_url
  influxdb_token  = var.influxdb_token
  influxdb_org    = var.influxdb_org
  influxdb_bucket = var.influxdb_bucket

  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets

  database_address  = module.database.database_address
  database_port     = tostring(module.database.database_port)
  database_user     = module.database.database_user
  database_password = module.database.database_password
  database_name     = module.database.database_name
}
