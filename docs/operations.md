# Operations

## Deploy order

1. Provision an S3 state bucket and a DynamoDB lock table (`LockID`) in each AWS account.
2. Create VPN demo certificates, import server and CA to ACM in the dev account.
3. Apply `envs/prod` with the consumer account principal.
4. Pass `hello_world_service_name` to `envs/dev` as `privatelink_service_name`, along with ACM certificate ARNs.
5. Connect the exported VPN profile. Verify DNS, then TCP/8080.
6. Destroy **dev before prod**. Delete ACM imports and state infrastructure separately.

Use `bash first-run.sh` for steps 2–5. Applies remain interactive.

## Debug by boundary

| Symptom | First check |
| --- | --- |
| Client VPN cannot connect | Client CA/server certificates, endpoint association, CloudWatch connection log |
| VPN connects; `hello.internal.company` does not resolve | Client DNS configuration, VPC resolver `10.10.0.2`, private hosted zone |
| Name resolves, TCP times out | Interface endpoint SG, endpoint state, Client VPN authorization |
| Endpoint available, backend unhealthy | NLB target group, EC2 `hello.service`, `/var/log/cloud-init-output.log`, backend SG |
| Dev cannot access prod state | By design; dev needs the published service **name**, not prod Terraform state |
| `tofu init` fails | Correct account/profile, S3 backend permissions, DynamoDB lock table and region |

## Constraints

- No NAT/IGW. Private EC2 bootstrap uses Python already present on Amazon Linux 2023.
- NLB spans two AZs with cross-zone forwarding; there is only **one** EC2 demo target.
- Provider acceptance is automatic for allowed principals. VPN authorization spans the dev VPC.
- Demo uses plaintext HTTP, locally generated keys, and no application authentication.
- Two remote state stores are separately managed; no cross-account state read is required.

Production deployment would need redundant app targets, TLS and app identity, narrower VPN authorization and IAM, explicit endpoint approvals, certificate rotation, monitoring and a tested recovery procedure.
