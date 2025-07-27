provider "aws" {
  region  = "eu-central-1"
  profile = "prod"
}

# Security group must be defined before VPC module to avoid circular dependency
resource "aws_security_group" "ssm_endpoint" {
  name        = "ssm-endpoint-sg"
  description = "SG for SSM VPC endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]  # Prod VPC CIDR
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm-endpoint-sg"
  }
}

# Create VPC directly here instead of using module to avoid circular dependency
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "prod-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = ["10.20.1.0/24", "10.20.2.0/24"][count.index]
  availability_zone       = ["eu-central-1a", "eu-central-1b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-vpc-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.20.3.0/24", "10.20.4.0/24"][count.index]
  availability_zone = ["eu-central-1a", "eu-central-1b"][count.index]

  tags = {
    Name = "prod-vpc-private-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "prod-vpc-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "prod-vpc-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "prod-vpc-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# SSM VPC Endpoints for Session Manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-central-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm_endpoint.id]

  tags = {
    Name = "prod-vpc-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-central-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm_endpoint.id]

  tags = {
    Name = "prod-vpc-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.eu-central-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm_endpoint.id]

  tags = {
    Name = "prod-vpc-ec2messages-endpoint"
  }
}

module "prod_trust_role" {
  source = "../../modules/iam-cross-account"

  role_name             = "ProdAcceptFromDev"
  trusted_principal_arn = "arn:aws:iam::471112589061:role/SSMInstanceRole"
  allowed_actions = [
    "ec2:DescribeInstances",
    "ec2:DescribeVpcs",
    "ec2:DescribeSubnets"
  ]
}