# Remove the deployed stacks

1. Use the AWS profiles and backend files from [deployment](deploy.md).
2. From the repository root, run:

```bash
bash scripts/70_destroy_all.sh
```

3. Type `destroy` at the prompt. The script removes dev resources before the provider service in prod.

Imported ACM certificates, the two S3 state buckets, and the DynamoDB lock tables remain. Remove those separately after checking that no other workloads use them.

The script also accepts `--yes` for an unattended teardown.
