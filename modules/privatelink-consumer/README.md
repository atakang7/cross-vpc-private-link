# privatelink-consumer

Creates an Interface VPC Endpoint to a provider service and optional private DNS record.

Inputs
- name (string)
- vpc_id (string)
- subnet_ids (list(string))
- service_name (string)
- port (number) default 8080
- allow_cidrs (list(string)) optional
- create_private_dns (bool) default true
- private_zone_name (string) default internal.company
- record_name (string) default hello

Outputs
- endpoint_id
- endpoint_dns
- private_dns_name (null if disabled)

Example
```hcl
module "consumer" {
  source            = "../../modules/privatelink-consumer"
  name              = "dev-hello"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  service_name      = data.terraform_remote_state.prod.outputs.hello_world_service_name
  allow_cidrs       = ["10.10.0.0/16", var.client_cidr_block]
  private_zone_name = "internal.company"
  record_name       = "hello"
}
```