output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "hello_world_dns" {
  value = "hello.internal.company:8080"
  description = "DNS name for accessing Hello World service"
}

output "hello_world_vpce_dns" {
  value = aws_vpc_endpoint.hello_world.dns_entry[0].dns_name
  description = "VPC Endpoint DNS name"
}

output "hello_world_internal_dns" {
  value = trim(aws_route53_record.hello_world.fqdn, ".")
  description = "Internal DNS for Hello World service"
}

output "private_instance_id" {
  value = aws_instance.dev_test_instance.id
  description = "Instance ID for SSM access"
}