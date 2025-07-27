# Upload client certificate to ACM for VPN client authentication
resource "aws_acm_certificate" "vpn_client" {
  private_key      = file("scripts/certs/client.key")
  certificate_body = file("scripts/certs/client.crt")
  certificate_chain = file("scripts/certs/ca.crt")
  
  tags = {
    Name = "vpn-client-cert"
  }
}

# Output the client certificate ARN for VPN configuration
output "vpn_client_certificate_arn" {
  value = aws_acm_certificate.vpn_client.arn
  description = "Client certificate ARN for VPN authentication"
}

# Output VPN connection details
output "vpn_connection_details" {
  value = {
    endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
    dns_name    = aws_ec2_client_vpn_endpoint.vpn.dns_name
    client_cidr = var.client_cidr_block
    auth_type   = "certificate"
  }
  description = "VPN connection details for client configuration"
}