module "vpc" {
  source               = "../../modules/vpc-core"
  name                 = "prod"
  vpc_cidr             = "10.20.0.0/16"
  private_subnet_cidrs = ["10.20.0.0/17", "10.20.128.0/17"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
}

module "ssm_endpoints" {
  source             = "../../modules/vpc-ssm-endpoints"
  name               = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  region             = "eu-central-1"
  allowed_cidrs      = ["10.20.0.0/16"]
}

variable "dev_account_root_arn" {
  type    = string
  default = "arn:aws:iam::471112589061:root"
}

module "privatelink_provider" {
  source             = "../../modules/privatelink-provider"
  name               = "prod-hello"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  port               = 8080
  allowed_principals = [var.dev_account_root_arn]
}

output "hello_world_service_name" { value = module.privatelink_provider.service_name }
output "hello_world_demo_ip"      { value = module.privatelink_provider.demo_private_ip }
