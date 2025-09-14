# Prod stack (provider)

What it creates
- VPC with public/private subnets (vpc-core)
- SSM interface endpoints (vpc-ssm-endpoints)
- PrivateLink provider: NLB + target group + listener + endpoint service (privatelink-provider)
- Optional demo EC2 app on the target port (default 8080)

How modules are imported
- main.tf composes vpc-core, vpc-ssm-endpoints, and privatelink-provider.
- allowed_principals controls which AWS principals can create endpoints.

Key variables and passing
- CIDRs and AZs: set inline in module "vpc".
- port: pass to provider module if not 8080.
- allowed_principals: pass a list of AWS principals (e.g., dev account root) to permit consumption.

Minimal usage
```zsh
AWS_PROFILE=prod tofu init
AWS_PROFILE=prod tofu apply -auto-approve
```

Outputs
- hello_world_service_name: passively read by dev via remote state.
- hello_world_demo_ip: private IP of demo app (when created).

Change safely
- Restrict allowed_principals to exact roles or accounts.
- Set acceptance_required=true inside the provider module if you want manual approvals.