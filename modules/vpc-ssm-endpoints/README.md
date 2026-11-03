Part of [cross-vpc-private-link](../../README.md).

# vpc-ssm-endpoints

Creates private interface endpoints for SSM, SSM Messages, and EC2 Messages with a dedicated security group.

## Run

Used by the [dev](../../envs/dev/README.md) and [prod](../../envs/prod/README.md) stacks.

## Test

```bash
tofu -chdir=modules/vpc-ssm-endpoints init -backend=false
tofu -chdir=modules/vpc-ssm-endpoints validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `name` | required | Resource prefix |
| `vpc_id` | required | VPC that owns the endpoints |
| `private_subnet_ids` | required | Endpoint ENI subnets |
| `region` | required | AWS region for service names |
| `allowed_cidrs` | `[]` | HTTPS ingress and VPC egress CIDRs |

## Interfaces

Output: `security_group_id`. Three endpoints use TCP/443 and AWS private DNS.
