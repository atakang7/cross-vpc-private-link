# Uses OpenTofu's mocked AWS provider. Tests actual resource plans without
# creating billable infrastructure or requiring AWS credentials.
mock_provider "aws" {}

variables {
  name                   = "test"
  vpc_id                 = "vpc-0123456789abcdef0"
  subnet_ids             = ["subnet-0123456789abcdef0"]
  target_vpc_subnet_id   = "subnet-0123456789abcdef0"
  vpc_cidr               = "10.10.0.0/16"
  client_cidr_block      = "172.16.0.0/22"
  dns_servers            = ["10.10.0.2"]
  server_certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/00000000-0000-0000-0000-000000000001"
  root_ca_arn            = "arn:aws:acm:eu-central-1:123456789012:certificate/00000000-0000-0000-0000-000000000002"
  app_port               = 8080
  allowed_app_sg_ids     = ["sg-0123456789abcdef0"]
  manage_vpc_route       = false
}

run "private_application_only" {
  command = plan

  assert {
    condition     = aws_ec2_client_vpn_endpoint.this.vpc_id == var.vpc_id
    error_message = "Client VPN must explicitly attach to the consumer VPC."
  }

  assert {
    condition     = length(aws_ec2_client_vpn_endpoint.this.security_group_ids) == 1
    error_message = "Client VPN must own exactly one explicit association security group."
  }

  assert {
    condition = length([
      for rule in aws_security_group.client_vpn.egress : rule
      if rule.from_port == 8080 && rule.protocol == "tcp" &&
      contains(rule.security_groups, "sg-0123456789abcdef0")
    ]) == 1
    error_message = "Published application endpoint requires a restricted TCP/8080 egress rule."
  }

  assert {
    condition = alltrue([
      for rule in aws_security_group.client_vpn.egress :
      !contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "Client VPN association must not have unrestricted IPv4 egress."
  }
}
