output "dns_name" {
  value = aws_lb.main.dns_name
}

output "ecs_arn" {
  value = aws_ecs_cluster.main.arn
}
