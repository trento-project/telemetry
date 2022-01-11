output "dns_name" {
  value = module.telemetry_application.dns_name
}

output "url" {
  value = "https://${var.dns_cname}.${var.dns_zone}"
}

output "database_address" {
  value = module.database.database_address
}

output "database_password" {
  value = module.database.database_password
}
