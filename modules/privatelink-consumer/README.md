Part of [cross-vpc-private-link](../../README.md).

# privatelink-consumer

Creates an interface VPC endpoint and, by default, a private Route 53 alias for the provider service.

## Run

The [dev stack](../../envs/dev/README.md) applies this module.

## Test

```bash
tofu -chdir=modules/privatelink-consumer init -backend=false
tofu -chdir=modules/privatelink-consumer validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `name` | required | Resource prefix |
| `vpc_id` | required | Consumer VPC |
| `subnet_ids` | required | Endpoint ENI subnets |
| `service_name` | required | Published endpoint service |
| `port` | `8080` | Endpoint ingress TCP port |
| `allow_cidrs` | `[]` | Endpoint security group CIDRs |
| `create_private_dns` | `true` | Create private zone and alias |
| `private_zone_name` | `internal.company` | Private hosted zone |
| `record_name` | `hello` | A record label |

## Interfaces

Outputs: `endpoint_id`, `endpoint_dns`, `private_dns_name`, `endpoint_security_group_id`.

The alias targets the endpoint DNS name. AWS-managed private DNS is disabled.
