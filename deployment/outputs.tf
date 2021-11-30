output "dns_name" {
  value = module.telemetry_application.dns_name
}

output "database_address" {
  value = module.database.database_address
}

output "database_password" {
  value = module.database.database_password
}
