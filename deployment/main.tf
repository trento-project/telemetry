module "telemetry_application" {
  source      = "./modules/application_ecs"

  name            = var.name
  region          = var.region
  aws_access_key  = var.aws_access_key
  aws_secret_key  = var.aws_secret_key
  environment     = var.environment
  container_image = var.container_image
  container_tag   = var.container_tag

  influxdb_url    = var.influxdb_url
  influxdb_token  = var.influxdb_token
  influxdb_org    = var.influxdb_org
  influxdb_bucket = var.influxdb_bucket
}
