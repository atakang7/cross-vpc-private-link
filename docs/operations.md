# Operations

Checks for deploying and testing the two-account PrivateLink lab.

- Prepare a versioned S3 state bucket and DynamoDB `LockID` table in each account.
- `bash first-run.sh` imports demo certificates and applies `envs/prod` before `envs/dev` with confirmation.
- VPN connection fails: check certificates, subnet associations, and CloudWatch connection logs.
- DNS fails: check VPN resolver selection, `10.10.0.2`, and the private Route 53 zone.
- TCP times out: check endpoint security groups, service state, and NLB target health.
- EC2 target unhealthy: inspect `hello.service` and `/var/log/cloud-init-output.log`.

## Verify

Run from the repository root with VPN connected:

```bash
bash scripts/60_test_privateline.sh
```

Local checks without AWS credentials:

```bash
tofu fmt -check -recursive
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

## Cleanup

```bash
bash scripts/70_destroy_all.sh
```

Cleanup destroys dev before prod but leaves imported ACM certificates and both state backends.
