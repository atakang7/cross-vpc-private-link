# Deploy the two-account lab

1. Install OpenTofu 1.10.0, AWS CLI, OpenSSL, curl and `getent` on Linux. Configure distinct AWS CLI profiles for the dev and prod accounts.
2. In each account, create a versioned, private S3 state bucket and a DynamoDB table with a string partition attribute named `LockID`. Allow the matching profile to use its backend.
3. Copy the backend examples and replace the bucket and lock table placeholders:

```bash
cp envs/prod/backend.hcl.example envs/prod/backend.hcl
cp envs/dev/backend.hcl.example envs/dev/backend.hcl
```

4. Check the identities:

```bash
aws sts get-caller-identity --profile prod
aws sts get-caller-identity --profile dev
```

5. Run the deployment from the repository root:

```bash
bash first-run.sh
```

The script generates demo certificates, imports the server and CA certificates to ACM in dev, applies prod then dev, and exports `dev.ovpn`. Review and approve each OpenTofu apply.

Profiles other than `dev` and `prod` can be selected with `DEV_PROFILE` and `PROD_PROFILE`. Infrastructure incurs AWS charges.

To connect and test the service, follow [verify the connection](verify.md).
