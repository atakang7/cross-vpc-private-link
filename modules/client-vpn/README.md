# client-vpn

Creates a certificate-authenticated AWS Client VPN endpoint with CloudWatch logs and subnet associations.

Inputs
- name (string)
- vpc_id (string)
- subnet_ids (list(string))
- client_cidr_block (string)
- dns_servers (list(string)) optional
- vpc_cidr (string) used for authorization rule and optional route creation
- server_certificate_arn (string)
- root_ca_arn (string)
- manage_vpc_route (bool) default true, set false if route to vpc_cidr is auto-created to avoid duplicate errors

Outputs
- endpoint_id
- dns_name

Example
```hcl
module "client_vpn" {
  source                = "../../modules/client-vpn"
  name                  = "dev"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  client_cidr_block     = var.client_cidr_block
  dns_servers           = ["10.10.0.2"]
  vpc_cidr              = "10.10.0.0/16"
  manage_vpc_route      = true # set false if route already exists
  server_certificate_arn = var.vpn_server_cert_arn
  root_ca_arn            = var.vpn_root_ca_arn
}
```