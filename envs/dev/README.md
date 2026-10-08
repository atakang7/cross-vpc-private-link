# Consumer stack — dev account

Creates a private VPC, SSM endpoints, a PrivateLink interface endpoint with Route 53 private DNS, and a certificate-authenticated AWS Client VPN.

**Prerequisite:** The provider endpoint service has already been deployed and its service name is available. There is no cross-account Terraform state read.

```bash
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
# Edit bucket, key, region and DynamoDB lock table for the dev account.
AWS_PROFILE=dev tofu -chdir=envs/dev init -backend-config=backend.hcl

AWS_PROFILE=dev tofu -chdir=envs/dev apply \
  -var "privatelink_service_name=$SERVICE_NAME" \
  -var "vpn_server_cert_arn=$SERVER_ARN" \
  -var "vpn_root_ca_arn=$CA_ARN"
```

`SERVICE_NAME` is the provider's `hello_world_service_name` output. `SERVER_ARN` and `CA_ARN` are imported ACM certificates in the consumer account's `eu-central-1` region. The script `scripts/40_deploy_dev.sh` accepts these in the same order, after backend configuration.

Private DNS resolves `hello.internal.company` inside the VPC. For a remote VPN client, OS DNS configuration must direct that private suffix to `10.10.0.2`. VPN authorization covers the dev VPC; it is intentionally broader than production access should be.

Outputs: `private_dns_hello`, `vpce_dns`, `vpn_endpoint`, `vpn_dns`.
