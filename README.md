# Cross-VPC PrivateLink

Private service connectivity between AWS accounts using PrivateLink. Production account provides services, development account consumes them via interface endpoints with custom DNS.

![System Architecture](img/system_architecture.png)

## Architecture

- **Provider (Prod)**: NLB + VPC Endpoint Service
- **Consumer (Dev)**: Interface VPC Endpoint + Route53 Private Zone
- **Access**: Client VPN with certificate authentication
- **DNS**: Custom private zone (`internal.company`) for clean service discovery

## Scripts

| Script | Purpose |
|--------|---------|
| `00_check_prereqs.sh` | Validate AWS CLI profiles and dependencies |
| `10_generate_certs.sh` | Generate CA and client/server certificates for VPN |
| `20_import_acm.sh` | Import certificates to AWS Certificate Manager |
| `30_deploy_prod.sh` | Deploy provider infrastructure (NLB + endpoint service) |
| `40_deploy_dev.sh` | Deploy consumer infrastructure (VPC endpoint + VPN) |
| `50_export_vpn_config.sh` | Export OpenVPN configuration file |
| `60_test_privateline.sh` | Test connectivity via PrivateLink endpoint |
| `70_destroy_all.sh` | Clean teardown of all resources |

## Quick Start

Set AWS profiles and run orchestrated deployment:
```bash
export DEV_PROFILE=dev PROD_PROFILE=prod
bash first-run.sh
```

Test connectivity:
```bash
sudo openvpn --config dev.ovpn --cert scripts/certs/client.crt --key scripts/certs/client.key --ca scripts/certs/ca.crt &
curl hello.internal.company:8080
```

## Manual Deployment

1. **Prerequisites**
   ```bash
   bash scripts/00_check_prereqs.sh
   ```

2. **Deploy Provider**
   ```bash
   bash scripts/30_deploy_prod.sh
   ```

3. **Generate Certificates**
   ```bash
   bash scripts/10_generate_certs.sh
   bash scripts/20_import_acm.sh
   ```

4. **Deploy Consumer**
   ```bash
   bash scripts/40_deploy_dev.sh
   ```

5. **Connect VPN**
   ```bash
   bash scripts/50_export_vpn_config.sh
   ```

6. **Test Service**
   ```bash
   bash scripts/60_test_privateline.sh
   ```

## Module Structure

```
modules/
├── vpc-core/             # VPC, private subnets, route tables
├── vpc-ssm-endpoints/    # SSM endpoints for private management
├── privatelink-provider/ # NLB + endpoint service + demo app
├── privatelink-consumer/ # Interface endpoint + private DNS zone
└── client-vpn/           # Certificate-based Client VPN
```

## Network Design

- **Prod VPC**: `10.0.0.0/16`
- **Dev VPC**: `10.10.0.0/16` 
- **VPN Clients**: `172.16.0.0/22`
- **DNS**: AWS resolver at `10.10.0.2` for private zones
- **Routing**: Split tunnel VPN (internet traffic stays local)

## Security

- Private subnets only (no internet gateways)
- PrivateLink traffic stays within AWS backbone
- Certificate-based VPN authentication
- Security groups restrict access by CIDR

## Cleanup

```bash
bash scripts/70_destroy_all.sh --yes
```

