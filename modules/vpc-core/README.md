# vpc-core

Creates a simple VPC with public and private subnets.

- DNS support on.
- Public route to IGW. Private route table stub.

Inputs
- name (string)
- vpc_cidr (string)
- public_subnet_cidrs (list(string))
- private_subnet_cidrs (list(string))
- azs (list(string))

Outputs
- vpc_id
- public_subnet_ids
- private_subnet_ids

Example
```hcl
module "vpc" {
  source               = "../../modules/vpc-core"
  name                 = "dev"
  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.3.0/24", "10.10.4.0/24"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
}
```