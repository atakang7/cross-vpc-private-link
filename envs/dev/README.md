Part of [cross-vpc-private-link](../../README.md).

# dev

Applies the consumer VPC, private SSM endpoints, interface endpoint, private Route 53 zone, and AWS Client VPN.

## Run

Apply the [provider stack](../prod/README.md) first. Set `SERVICE_NAME` to its `hello_world_service_name` output and the two ARN variables to ACM imports in the dev account.

```bash
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
bash scripts/40_deploy_dev.sh "$SERVER_ARN" "$CA_ARN" "$SERVICE_NAME"
```

## Test

```bash
tofu -chdir=envs/dev init -backend=false -lockfile=readonly
tofu -chdir=envs/dev validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `privatelink_service_name` | required | Provider service name |
| `vpn_server_cert_arn` | required | ACM server certificate |
| `vpn_root_ca_arn` | required | ACM client CA |
| `client_cidr_block` | `172.16.0.0/22` | Client address range |
| `vpn_dns_servers` | `["10.10.0.2"]` | DNS pushed to VPN clients |

The AWS provider uses `eu-central-1`. `backend.hcl` supplies the separate dev state store.

## Interfaces

Outputs: `private_dns_hello`, `vpce_dns`, `vpn_endpoint`, `vpn_dns`.

The alias `hello.internal.company` points at the interface endpoint. Clients connect to TCP/8080 over VPN.
