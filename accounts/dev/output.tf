output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "grafana_dns" {
  value = "grafana.internal.company:5003"
  description = "DNS name for accessing Grafana"
}

output "grafana_vpce_dns" {
  value = aws_vpc_endpoint.grafana.dns_entry[0].dns_name
  description = "VPC Endpoint DNS name"
}

output "grafana_internal_dns" {
  value = trim(aws_route53_record.grafana.fqdn, ".")
  description = "Internal DNS for Grafana"
}
