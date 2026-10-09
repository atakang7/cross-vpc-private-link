# Do not inherit the VPC default security group for Client VPN associations.
# Permit only private DNS and the explicitly selected application endpoint.
resource "aws_security_group" "client_vpn" {
  name        = "${var.name}-client-vpn"
  description = "Client VPN egress to private DNS and the published application"
  vpc_id      = var.vpc_id

  egress {
    description = "VPC resolver (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "VPC resolver (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  dynamic "egress" {
    for_each = toset(var.allowed_application_security_group_ids)
    content {
      description     = "Published application TCP endpoint"
      from_port       = var.application_port
      to_port         = var.application_port
      protocol        = "tcp"
      security_groups = [egress.value]
    }
  }

  tags = { Name = "${var.name}-client-vpn" }
}

resource "aws_cloudwatch_log_group" "vpn" {
  name              = "/aws/client-vpn/${var.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "${var.name} Client VPN Endpoint"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  dns_servers            = var.dns_servers
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.client_vpn.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.root_ca_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }
}

resource "aws_ec2_client_vpn_network_association" "assoc" {
  count                  = length(var.subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "allow_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
  description            = "Allow access to the VPC"
}

resource "aws_ec2_client_vpn_route" "route_vpc" {
  count                  = var.manage_vpc_route ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = var.vpc_cidr
  target_vpc_subnet_id   = var.target_vpc_subnet_id
  depends_on             = [aws_ec2_client_vpn_network_association.assoc]
}

output "endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.this.id
}

output "dns_name" {
  value = aws_ec2_client_vpn_endpoint.this.dns_name
}
