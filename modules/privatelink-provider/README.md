# privatelink-provider

Exposes an internal TCP service via a Network Load Balancer and a VPC Endpoint Service.
Optionally creates a demo EC2 app on the given port.

Inputs
- name (string)
- vpc_id (string)
- private_subnet_ids (list(string))
- port (number) default 8080
- allowed_principals (list(string)) AWS principals allowed to create endpoints
- create_demo_instance (bool) default true

Outputs
- service_name
- demo_private_ip (null if not created)

Example
```hcl
module "provider" {
  source             = "../../modules/privatelink-provider"
  name               = "prod-hello"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  port               = 8080
  allowed_principals = ["arn:aws:iam::123456789012:root"]
}
```