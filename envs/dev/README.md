# Dev stack (consumer)

What it creates
- VPC with public/private subnets (vpc-core)
- SSM interface endpoints (vpc-ssm-endpoints)
- PrivateLink consumer: Interface VPC Endpoint + SG + private Route 53 record (privatelink-consumer)
- Optional Client VPN (client-vpn)

How modules are imported
- main.tf calls modules with explicit inputs. No hidden defaults.
- Prod service name is read via terraform_remote_state from the prod backend.

Key variables and passing
- CIDRs and AZs: set inline in main.tf in module "vpc".
- PrivateLink service name: comes from data.terraform_remote_state.prod.outputs.hello_world_service_name.
- DNS: set private_zone_name and record_name on the consumer module (defaults: internal.company, hello).
- Client VPN: pass ACM ARNs with -var "vpn_server_cert_arn=..." and -var "vpn_root_ca_arn=...".
- client_cidr_block and vpn_dns_servers are variables in variables.tf.

Minimal usage
```zsh
# Uses the dev AWS profile configured in provider
AWS_PROFILE=dev tofu init
AWS_PROFILE=dev tofu apply -auto-approve \
  -var "vpn_server_cert_arn=$SERVER_ARN" \
  -var "vpn_root_ca_arn=$CA_ARN"
```

Outputs
- private_dns_hello: friendly DNS name
- vpce_dns: raw endpoint DNS
- vpn_endpoint / vpn_dns: when VPN is enabled

Change safely
- Edit CIDRs/AZs in module "vpc".
- Tune allow_cidrs in privatelink-consumer (often [vpc_cidr, client_cidr_block]).
- You can skip VPN by not passing the ARNs.