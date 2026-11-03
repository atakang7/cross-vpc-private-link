Part of [cross-vpc-private-link](../README.md).

# scripts

Shell entry points for certificate setup, ACM import, stack deployment, VPN export, verification, and teardown.

## Run

From the repository root, after [state setup](../docs/how-to/deploy.md):

```bash
bash first-run.sh
```

## Test

```bash
bash -n first-run.sh
for script in scripts/*.sh; do bash -n "$script"; done
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `DEV_PROFILE` | `dev` | Consumer AWS CLI profile |
| `PROD_PROFILE` | `prod` | Provider AWS CLI profile |
| `AWS_REGION` | `eu-central-1` | ACM import and destroy placeholder region |
| `SERVER_ARN`, `CA_ARN` | unset | ACM inputs for dev apply or destroy |
| `SERVICE_NAME` | unset | Provider endpoint service input |

## Interfaces

| Script | Input / side effect |
| --- | --- |
| `00_check_prereqs.sh` | Checks `tofu`, `aws`, `openssl`, `curl`, `getent` |
| `10_generate_certs.sh` | Calls `generate-vpn-certs.sh` |
| `generate-vpn-certs.sh` | Writes `scripts/certs/` (CA, server and client PEM files) |
| `20_import_acm.sh` | Profile argument; prints `SERVER_ARN` and `CA_ARN` |
| `30_deploy_prod.sh` | Applies `envs/prod`; prints service name |
| `40_deploy_dev.sh` | Arguments: server ARN, CA ARN, service name |
| `50_export_vpn_config.sh` | Profile, output path, region; writes `dev.ovpn` by default |
| `60_test_privateline.sh` | Host and port; resolves DNS and sends HTTP GET |
| `70_destroy_all.sh` | Optional `--yes`; destroys dev then prod |

`first-run.sh` runs the setup sequence and leaves OpenTofu applies interactive.
