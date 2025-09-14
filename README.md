# Cross VPC PrivateLink (minimal prototype)

Connect two AWS accounts privately with AWS PrivateLink. Prod provides a service. Dev consumes it. Optional Client VPN for testing.

![System Architecture](img/system_architecture.png)

## Layout

```
envs/
  dev/   # consumer stack
  prod/  # provider stack
modules/
  vpc-core/             # VPC, subnets, routes
  vpc-ssm-endpoints/    # SSM endpoints + SG
  privatelink-provider/ # NLB + endpoint service (+ demo app)
  privatelink-consumer/ # Interface endpoint + SG + private DNS
  client-vpn/           # Client VPN (cert auth)
scripts/
  first-run.sh and modular helpers
  70_destroy_all.sh      # destroy dev then prod safely
```

## Minimal flow

Prereqs
- AWS CLI profiles: dev and prod
- OpenTofu (tofu), OpenSSL, optional: openvpn

1) One-liner (orchestrated)
```zsh
export DEV_PROFILE=dev
export PROD_PROFILE=prod
bash first-run.sh
```

2) Manual (short version)
- Deploy provider (prod):
```zsh
AWS_PROFILE=prod tofu -chdir envs/prod init
AWS_PROFILE=prod tofu -chdir envs/prod apply -auto-approve
```
- (Optional) Generate and import VPN certs (dev):
```zsh
bash scripts/10_generate_certs.sh
SERVER_ARN=$(aws acm import-certificate --profile dev \
  --certificate fileb://scripts/certs/server.crt \
  --private-key fileb://scripts/certs/server.key \
  --certificate-chain fileb://scripts/certs/ca.crt \
  --query CertificateArn --output text)
CA_ARN=$(aws acm import-certificate --profile dev \
  --certificate fileb://scripts/certs/ca.crt \
  --private-key fileb://scripts/certs/ca.key \
  --query CertificateArn --output text)
```
- Deploy consumer (dev):
```zsh
AWS_PROFILE=dev tofu -chdir envs/dev init
AWS_PROFILE=dev tofu -chdir envs/dev apply -auto-approve \
  -var "vpn_server_cert_arn=${SERVER_ARN:-}" \
  -var "vpn_root_ca_arn=${CA_ARN:-}"
```
- Export VPN config (if VPN created) and connect:
```zsh
aws ec2 export-client-vpn-client-configuration --profile dev \
  --client-vpn-endpoint-id "$(tofu -chdir envs/dev output -raw vpn_endpoint)" > dev.ovpn
sudo openvpn --config dev.ovpn \
  --cert scripts/certs/client.crt \
  --key scripts/certs/client.key \
  --ca scripts/certs/ca.crt
```
- Test PrivateLink over VPN:
```zsh
bash scripts/60_test_privateline.sh  # curls http://hello.internal.company:8080
```

Cleanup
- Destroy both environments when done:
```zsh
DEV_PROFILE=dev PROD_PROFILE=prod bash scripts/70_destroy_all.sh --yes
```

## How the modules work (in 60 seconds)
- Each env stack composes small modules: vpc-core -> vpc-ssm-endpoints -> provider/consumer -> optional client-vpn.
- Inputs are explicit; see each module README for variables and outputs.
- Prod exports the PrivateLink service name. Dev reads it via terraform_remote_state.
- Security groups live with the module that needs them to avoid dependency cycles.

Learn more per env
- Dev: envs/dev/README.md (consumer wiring, variables, VPN)
- Prod: envs/prod/README.md (provider wiring, allowed_principals)

## Use this repo
- Clone, set AWS profiles, run the minimal flow above.
- Each module has a tiny README with inputs/outputs and an example.
- CI checks formatting/validation; security scan runs on PRs.

