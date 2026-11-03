Part of [cross-vpc-private-link](../../README.md).

# privatelink-provider

Creates an internal TCP NLB, a VPC endpoint service, and an optional Amazon Linux 2023 EC2 demo target.

```text
+--------------+  TCP  +--------------+
| internal NLB | ----> | demo EC2     |
+--------------+       +--------------+
```

## Run

The [prod stack](../../envs/prod/README.md) applies this module.

## Test

```bash
tofu -chdir=modules/privatelink-provider init -backend=false
tofu -chdir=modules/privatelink-provider validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `name` | required | Resource prefix |
| `vpc_id` | required | Provider VPC |
| `vpc_cidr` | required | Demo backend ingress source |
| `private_subnet_ids` | required | NLB subnets |
| `port` | `8080` | Listener, target, and demo HTTP port |
| `allowed_principals` | `[]` | AWS principals allowed to connect |
| `create_demo_instance` | `true` | Create one backend instance |

## Interfaces

Outputs: `service_name`, `demo_private_ip` (null without a demo instance).

`bootstrap.sh.tftpl` writes `/opt/hello_world.py` and `hello.service`. GET requests return JSON with `message` and `ts`.
