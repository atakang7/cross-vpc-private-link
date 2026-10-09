# Provider stack — prod account

Creates private VPC subnets, SSM endpoints, internal NLB, one demo EC2 target, and a VPC endpoint service. No public subnet, internet gateway, or NAT is provisioned.

```bash
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
# Edit bucket, key, region and DynamoDB lock table for the prod account.
AWS_PROFILE=prod tofu -chdir=envs/prod init -backend-config=backend.hcl

AWS_PROFILE=prod tofu -chdir=envs/prod apply \
  -var "dev_account_root_arn=arn:aws:iam::123456789012:root"

AWS_PROFILE=prod tofu -chdir=envs/prod output -raw hello_world_service_name
```

Replace the example account ID with the **actual consumer AWS account ID**. The allowlist grants that account permission to create service endpoints. Automatic acceptance is enabled **only for this lab**.

You can run `DEV_PROFILE=dev PROD_PROFILE=prod bash scripts/30_deploy_prod.sh` after backend setup; it obtains the consumer account ID from AWS STS rather than guessing it.

The provider output `hello_world_service_name` is passed explicitly to the consumer stack. Do not give the consumer account read access to the production state just to obtain it.

The demo uses one EC2 target and plaintext HTTP; see [production limitations](../../README.md#limits).
