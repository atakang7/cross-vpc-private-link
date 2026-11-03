# Cross-account AWS PrivateLink

OpenTofu lab for reaching an HTTP service in a second AWS account through AWS Client VPN and PrivateLink, without VPC peering.

```text
+------------+  HTTP  +--------------------+  TCP  +------------------+
| Client VPN | -----> | Interface endpoint | ----> | Endpoint service |
+------------+        +--------------------+       +------------------+
                                                        |
                                                       TCP
                                                        v
                                              +--------------+  TCP  +-------------------+
                                              | Internal NLB | ----> | EC2 hello.service |
                                              +--------------+       +-------------------+
```

```text
+--------------+  applies  +-----------+  service name  +----------+  exports  +----------+
| first-run.sh | --------> | envs/prod | -------------> | envs/dev | --------> | dev.ovpn |
+--------------+           +-----------+                +----------+           +----------+
```

## Run

Requires Linux, AWS CLI, OpenTofu 1.10.0, OpenSSL, OpenVPN, and two AWS accounts with separate S3 state buckets and DynamoDB lock tables (`LockID` string key).

```bash
cp .env.example .env
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
# Configure profiles, region, S3 buckets, and lock tables in these files.
set -a
. ./.env
set +a
aws sts get-caller-identity --profile "$DEV_PROFILE"
aws sts get-caller-identity --profile "$PROD_PROFILE"
bash first-run.sh
```

Connect in one terminal; test from another:

```bash
sudo openvpn --config dev.ovpn \
  --cert scripts/certs/client.crt \
  --key scripts/certs/client.key \
  --ca scripts/certs/ca.crt
```

```bash
bash scripts/60_test_privateline.sh
```

Expected response includes `"message": "Hello from provider"`; [operations](docs/operations.md) covers failure checks.

Remove the stacks with `bash scripts/70_destroy_all.sh`.

## Config

| Var | Default | What |
| --- | --- | --- |
| `DEV_PROFILE` | `dev` | Consumer AWS CLI profile |
| `PROD_PROFILE` | `prod` | Provider AWS CLI profile |
| `AWS_REGION` | `eu-central-1` | Region for both stacks and VPN/ACM commands |
| `envs/dev/backend.hcl` | unset | Consumer S3 state and lock table |
| `envs/prod/backend.hcl` | unset | Provider S3 state and lock table |
| `client_cidr_block` | `172.16.0.0/22` | VPN client CIDR (`envs/dev`) |

## Limits

- One EC2 target; no backend failover.
- HTTP on port 8080 has no TLS or application authentication.
- Demo VPN certificates are self-signed; VPC-level VPN authorization is broad.
- Endpoint acceptance is automatic for allowed principals.
- AWS resources incur charges; teardown leaves ACM imports and state backends.
