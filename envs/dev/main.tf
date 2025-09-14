data "terraform_remote_state" "prod" {
  backend = "s3"
  config = {
    bucket  = "tf-state-prod-916960893956"
    key     = "prod/terraform.tfstate"
    region  = "eu-central-1"
    profile = "prod"
  }
}

module "vpc" {
  source               = "../../modules/vpc-core"
  name                 = "dev"
  vpc_cidr             = "10.10.0.0/16"
  private_subnet_cidrs = ["10.10.0.0/17", "10.10.128.0/17"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
}

module "ssm_endpoints" {
  source             = "../../modules/vpc-ssm-endpoints"
  name               = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  region             = "eu-central-1"
  allowed_cidrs      = ["10.10.0.0/16"]
}

module "privatelink_consumer" {
  source            = "../../modules/privatelink-consumer"
  name              = "dev-hello"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  service_name      = data.terraform_remote_state.prod.outputs.hello_world_service_name
  allow_cidrs       = ["10.10.0.0/16", var.client_cidr_block]
  private_zone_name = "internal.company"
  record_name       = "hello"
}

# Client VPN assumes certs already in ACM; provide ARNs via tfvars or environment-specific vars later
variable "vpn_server_cert_arn" {}
variable "vpn_root_ca_arn" {}

module "client_vpn" {
  source                 = "../../modules/client-vpn"
  name                   = "dev"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  target_vpc_subnet_id   = module.vpc.private_subnet_ids[0]
  client_cidr_block      = var.client_cidr_block
  dns_servers            = var.vpn_dns_servers
  vpc_cidr               = "10.10.0.0/16"
  server_certificate_arn = var.vpn_server_cert_arn
  root_ca_arn            = var.vpn_root_ca_arn
  manage_vpc_route       = false
}

output "private_dns_hello" { value = module.privatelink_consumer.private_dns_name }
output "vpce_dns"         { value = module.privatelink_consumer.endpoint_dns }
output "vpn_endpoint"     { value = module.client_vpn.endpoint_id }
output "vpn_dns"          { value = module.client_vpn.dns_name }
