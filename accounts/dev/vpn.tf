resource "aws_directory_service_directory" "vpn_directory" {
  name     = "corp.internal.company"
  password = "SecurePassword123!"
  size     = "Small"
  
  vpc_settings {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = slice(module.vpc.private_subnet_ids, 0, 2)
  }
  
  tags = {
    Name = "vpn-directory"
  }
}

resource "aws_acm_certificate" "vpn_server" {
  private_key      = file(var.server_key_file_path)
  certificate_body = file(var.server_certificate_file_path)
  
  tags = {
    Name = "vpn-server-cert"
  }
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Dev Client VPN Endpoint"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = "172.16.0.0/22"
  split_tunnel           = true
  
  authentication_options {
    type                = "directory-service-authentication"
    active_directory_id = aws_directory_service_directory.vpn_directory.id
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

resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/aws/client-vpn/dev-vpn"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "vpn_logs" {
  name           = "connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}

# Associate with private subnets
resource "aws_ec2_client_vpn_network_association" "vpn_association" {
  count                  = length(module.vpc.private_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnet_ids[count.index]
}

# Authorize VPN access to dev VPC
resource "aws_ec2_client_vpn_authorization_rule" "vpn_dev_vpc_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = "10.10.0.0/16"  # Dev VPC CIDR
  authorize_all_groups   = true
}

# Authorize VPN access to prod VPC
resource "aws_ec2_client_vpn_authorization_rule" "vpn_prod_vpc_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = "10.20.0.0/16"  # Prod VPC CIDR
  authorize_all_groups   = true
}

# Route table for dev VPC
resource "aws_ec2_client_vpn_route" "dev_vpc_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = "10.10.0.0/16"  # Dev VPC CIDR
  target_vpc_subnet_id   = module.vpc.private_subnet_ids[0]
}

# Route table for prod VPC
resource "aws_ec2_client_vpn_route" "prod_vpc_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = "10.20.0.0/16"  # Prod VPC CIDR
  target_vpc_subnet_id   = module.vpc.private_subnet_ids[0]
}

# Internet access route
resource "aws_ec2_client_vpn_route" "internet_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = module.vpc.private_subnet_ids[0]
}

# VPN security group
resource "aws_security_group" "vpn_access" {
  name        = "vpn-access"
  description = "Security group for VPN connected clients"
  vpc_id      = module.vpc.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.client_cidr_block]
  }

  tags = {
    Name = "vpn-access-sg"
  }
}

# Update bastion security group to allow access from VPN
resource "aws_security_group_rule" "bastion_vpn_access" {
  security_group_id        = aws_security_group.bastion_sg.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["172.16.0.0/22"]  # VPN CIDR
  description              = "Allow SSH from VPN clients"
}

# Output VPN endpoint for configuration
output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.vpn.id
}

output "client_vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.vpn.dns_name
}