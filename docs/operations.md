# Operations and design notes

## Trust boundaries

```text
Developer certificate -> Client VPN -> Dev VPC DNS / Interface Endpoint
                                           |
                      explicit provider service name / allowed principal
                                           |
                                   PrivateLink service -> internal NLB
                                                            |
                                                  demo target SG -> EC2
```

The provider exposes an **endpoint service**, not a routed VPC network. The consumer obtains private ENIs for that service. The service is whitelisted to a consumer AWS account; the demo sets `acceptance_required=false`, so any suitably authorized identity in that allowed account can request an endpoint. For real deployments, prefer narrower principals and explicit endpoint acceptance.

Both accounts keep their own S3 state. The producer's service name is the only value transferred to the consumer; no consumer IAM permission to read the provider state bucket is required.

## Deployment dependencies

1. Configure a versioned state bucket and DynamoDB lock table in **each** account.
2. Generate VPN CA/server/client certificates and import the server and CA into ACM in the **dev** account, region `eu-central-1`.
3. Apply `envs/prod` with `dev_account_root_arn`; capture `hello_world_service_name`.
4. Apply `envs/dev` with `privatelink_service_name`, `vpn_server_cert_arn`, and `vpn_root_ca_arn`.
5. Wait for the demo target to become healthy, export the Client VPN profile, connect, and verify DNS and HTTP.
6. Destroy **dev before prod**. ACM imports and backend resources require separate cleanup.

The helper `first-run.sh` performs steps 2–5, with interactive infrastructure approvals. It is intended for a controlled lab account only.

## Verification and failures

| Symptom | Check first |
| --- | --- |
| Provider target unhealthy | EC2 user-data status (`/var/log/cloud-init-output.log`), systemd `hello` service, NLB target health, target SG |
| Consumer endpoint pending or rejected | Provider service name, allowed principal, acceptance configuration and endpoint status |
| VPN can't connect | Server/CA certificate ARNs, validity and client certificate, VPN association/auth rules and CloudWatch connection logs |
| VPN connects but name won't resolve | `internal.company` private hosted zone attached to dev VPC; VPN DNS server `10.10.0.2`; OS conditional DNS |
| DNS resolves but curl fails | Endpoint security group, VPN authorization, endpoint state, NLB target health and port `8080` |
| `tofu init` fails | AWS profile, access to correct state bucket, pre-created `LockID` lock table, region and backend.hcl |
| Consumer can't read prod state | It should not need to; pass the provider's **service name output** instead |

The network is intentionally closed: package downloads from the demo EC2 instance will not work without a separately designed egress path. The bootstrap does not rely on downloads.

## Production hardening not implemented here

This is a learning reference, not a deployable product. A production design should use multi-AZ healthy app targets, TLS on the application path, authentication/authorization at the service boundary, narrower per-role IAM, explicit provider endpoint approval, certificate lifecycle/rotation, alarms and log retention strategy, controlled build artifacts and AMI pinning, and automated test environments. A Terraform validation pass alone is not runtime verification.
