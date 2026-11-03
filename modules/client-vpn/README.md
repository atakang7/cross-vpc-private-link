Part of [cross-vpc-private-link](../../README.md).

# client-vpn

Creates a certificate-authenticated AWS Client VPN endpoint, subnet associations, private DNS egress rules, and 30-day CloudWatch connection logs.

## Run

The [dev stack](../../envs/dev/README.md) applies this module.

## Test

```bash
cp envs/dev/.terraform.lock.hcl modules/client-vpn/.terraform.lock.hcl
tofu -chdir=modules/client-vpn init -backend=false -lockfile=readonly
tofu -chdir=modules/client-vpn test -no-color
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `name` | required | Resource prefix |
| `vpc_id` | required | Consumer VPC |
| `subnet_ids` | required | VPN network associations |
| `target_vpc_subnet_id` | required | Optional managed route target |
| `client_cidr_block` | required | VPN client CIDR |
| `dns_servers` | `[]` | DNS servers advertised to clients |
| `vpc_cidr` | required | VPN authorization and DNS egress CIDR |
| `server_certificate_arn` | required | ACM server certificate |
| `root_ca_arn` | required | ACM client CA |
| `manage_vpc_route` | `true` | Manage route when associations do not provide it |
| `app_port` | `8080` | Allowed application TCP port |
| `allowed_app_sg_ids` | `[]` | Application security groups permitted as egress targets |

## Interfaces

Outputs: `endpoint_id`, `dns_name`. VPN authorization covers `vpc_cidr`; the security group limits DNS and application traffic.
