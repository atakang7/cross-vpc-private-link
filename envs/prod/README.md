Part of [cross-vpc-private-link](../../README.md).

# prod

Applies the provider VPC, private SSM endpoints, internal NLB, demo EC2 instance, and PrivateLink endpoint service.

## Run

Create the remote state bucket and lock table, then edit `backend.hcl` after copying the example.

```bash
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
DEV_PROFILE=dev PROD_PROFILE=prod bash scripts/30_deploy_prod.sh
```

## Test

```bash
tofu -chdir=envs/prod init -backend=false -lockfile=readonly
tofu -chdir=envs/prod validate
```

## Config

| Variable | Default | Purpose |
| --- | --- | --- |
| `dev_account_root_arn` | required | Consumer account allowed to create endpoints |

The AWS provider uses `eu-central-1`. `backend.hcl` supplies the S3 bucket, state path, region and DynamoDB lock table.

## Interfaces

Outputs: `hello_world_service_name` for the dev stack; `hello_world_demo_ip` for the single demo target.

The provider uses TCP/8080 and automatically accepts endpoint requests from allowed principals.
