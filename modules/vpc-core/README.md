Part of [cross-vpc-private-link](../../README.md).

# vpc-core

Creates a VPC, private subnets and a local-only route table, with DNS support enabled.

## Run

Used by the [dev](../../envs/dev/README.md) and [prod](../../envs/prod/README.md) stacks.

## Test

```bash
tofu -chdir=modules/vpc-core init -backend=false
tofu -chdir=modules/vpc-core validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `name` | required | Resource prefix |
| `vpc_cidr` | required | VPC address range |
| `private_subnet_cidrs` | required | Ordered subnet CIDRs |
| `azs` | required | AZ for each subnet, in matching order |

## Interfaces

Outputs: `vpc_id`, `private_subnet_ids`. The module has no internet gateway or NAT gateway.
