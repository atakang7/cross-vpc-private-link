# vpc-core

Minimal private-only VPC: VPC DNS enabled, one private subnet per configured AZ, and a private route table with only local VPC routing. No public subnets, internet gateway, or NAT gateway.

Inputs: `name`, `vpc_cidr`, `private_subnet_cidrs`, `azs` (subnet and AZ arrays must have corresponding positions).

Outputs: `vpc_id`, `private_subnet_ids`.

This module deliberately leaves all outbound internet access unavailable. Service traffic uses VPC interface endpoints and PrivateLink.
