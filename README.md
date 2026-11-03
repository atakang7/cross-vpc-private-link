# cross-vpc-private-link

OpenTofu lab for engineers testing private TCP access between AWS accounts through Client VPN and PrivateLink.

```text
+--------+  VPN  +------------+   TCP   +---------------+  PrivateLink  +--------------+  TCP  +---------+
| client | ----> | Client VPN | ------> | interface VPCE| ------------> | internal NLB | ----> | demo EC2|
+--------+       +------------+         +---------------+               +--------------+       +---------+
```

## Quick start

Requires two AWS accounts, AWS CLI profiles `dev` and `prod`, OpenTofu 1.10.0, OpenSSL and Linux. Provision a private S3 state bucket and DynamoDB lock table in each account, then edit the copied backend files. See [deploy](docs/how-to/deploy.md) for the prerequisites.

```bash
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
bash first-run.sh
sudo openvpn --config dev.ovpn --cert scripts/certs/client.crt --key scripts/certs/client.key --ca scripts/certs/ca.crt
bash scripts/60_test_privateline.sh
```

Run the VPN connection and HTTP test in separate terminals.

## Layout

| Path | What it is |
| --- | --- |
| [`envs/prod/`](envs/prod/README.md) | Provider account stack |
| [`envs/dev/`](envs/dev/README.md) | Consumer account stack |
| [`modules/vpc-core/`](modules/vpc-core/README.md) | Private VPC and subnets |
| [`modules/vpc-ssm-endpoints/`](modules/vpc-ssm-endpoints/README.md) | SSM interface endpoints |
| [`modules/privatelink-provider/`](modules/privatelink-provider/README.md) | NLB and endpoint service |
| [`modules/privatelink-consumer/`](modules/privatelink-consumer/README.md) | Interface endpoint and DNS |
| [`modules/client-vpn/`](modules/client-vpn/README.md) | Certificate-based Client VPN |
| [`scripts/`](scripts/README.md) | Deployment and check scripts |

## Docs

[Docs index](docs/README.md): [deploy](docs/how-to/deploy.md), [verify](docs/how-to/verify.md), [troubleshoot](docs/how-to/troubleshoot.md), [teardown](docs/how-to/teardown.md), [network values](docs/reference/network.md), [architecture](docs/explanation/architecture.md).

## Limits

- One EC2 backend target without redundancy.
- HTTP on TCP/8080 without application authentication.
- Demo VPN certificates and broad VPC CIDR authorization.
- Automatic endpoint acceptance for allowlisted AWS principals.
- AWS resources incur charges until removed.
