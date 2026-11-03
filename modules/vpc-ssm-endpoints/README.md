# vpc-ssm-endpoints

Adds SSM interface endpoints (ssm, ssmmessages, ec2messages) to a VPC.
Creates its own security group to avoid module/VPC cycles.

Inputs
- name (string)
- vpc_id (string)
- private_subnet_ids (list(string))
- region (string)
- allowed_cidrs (list(string)) optional

Outputs
- security_group_id

Example
```hcl
module "ssm_endpoints" {
  source             = "../../modules/vpc-ssm-endpoints"
  name               = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  region             = "eu-central-1"
  allowed_cidrs      = ["10.10.0.0/16"]
}
```