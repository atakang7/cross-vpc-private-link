# CA Certificate for VPN
resource "aws_acm_certificate" "vpn_ca" {
  private_key      = file("scripts/certs/ca.key")
  certificate_body = file("scripts/certs/ca.crt")
  
  tags = {
    Name = "vpn-ca-cert"
  }
}

# VPN Server Certificate
resource "aws_acm_certificate" "vpn_server" {
  private_key      = file(var.server_key_file_path)
  certificate_body = file(var.server_certificate_file_path)
  certificate_chain = file("scripts/certs/ca.crt")
  
  tags = {
    Name = "vpn-server-cert"
  }
}

# CloudWatch Logs for VPN
resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/aws/client-vpn/dev-vpn"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "vpn_logs" {
  name           = "connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}

# Client VPN Endpoint with Certificate Authentication
resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Dev Client VPN Endpoint"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = "172.16.0.0/22"
  split_tunnel           = true
  dns_servers            = ["10.10.0.2"]  # VPC DNS resolver
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_ca.arn
  }
  
  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_logs.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_logs.name
  }
  
  tags = {
    Name = "dev-client-vpn"
  }
}

# Associate with private subnets
resource "aws_ec2_client_vpn_network_association" "vpn_association" {
  count                  = length(module.vpc.private_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnet_ids[count.index]
}

# Authorize VPN access to dev VPC only (AWS auto-creates this route)
resource "aws_ec2_client_vpn_authorization_rule" "vpn_dev_vpc_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = "10.10.0.0/16"
  authorize_all_groups   = true
}

# Output VPN endpoint for configuration
output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.vpn.id
}

output "client_vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.vpn.dns_name
}