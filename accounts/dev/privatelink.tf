# Fetch information about the Prod VPC Endpoint Service
data "aws_vpc_endpoint_service" "grafana" {
  service_name = var.grafana_endpoint_service_name
}

# Create VPC Endpoint for Grafana
resource "aws_vpc_endpoint" "grafana" {
  vpc_id             = module.vpc.vpc_id
  service_name       = data.aws_vpc_endpoint_service.grafana.service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.grafana_endpoint.id]
  private_dns_enabled = false
  
  tags = {
    Name = "grafana-vpc-endpoint"
  }
}

# Security group for the VPC Endpoint
resource "aws_security_group" "grafana_endpoint" {
  name        = "grafana-endpoint-sg"
  description = "Allow access to Grafana VPC Endpoint"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 5003
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16", "172.16.0.0/22"]  # Dev VPC CIDR and VPN CIDR
    description = "Allow access to Grafana from VPC and VPN"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "grafana-endpoint-sg"
  }
}

# Create a private hosted zone
resource "aws_route53_zone" "private" {
  name = "internal.company"
  
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  
  tags = {
    Name = "internal-private-zone"
  }
}

# Create DNS record for Grafana
resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "grafana.internal.company"
  type    = "A"
  
  alias {
    name                   = aws_vpc_endpoint.grafana.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.grafana.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}