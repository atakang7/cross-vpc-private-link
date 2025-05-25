# Cross-Account Grafana Monitoring Infrastructure

This repository contains Terraform configuration for deploying a secure cross-account monitoring infrastructure with Grafana, Prometheus, and VPN access.

## Architecture

- **Dev Account**: Contains VPN endpoint, bastion host, and VPC endpoints for cross-account access
- **Prod Account**: Contains EKS cluster with Grafana and Prometheus in private subnets
- **Secure Access**: Access to Grafana is only allowed through the VPN connection to the dev account
- **PrivateLink**: Cross-account communication happens through AWS PrivateLink

## Prerequisites

- AWS CLI configured with profiles for both dev and prod accounts
- Terraform 1.0.0 or later
- OpenSSL for generating VPN certificates

## Deployment Steps

1. **Generate VPN Certificates**:
   ```bash
   cd accounts/dev/scripts
   ./generate-vpn-certs.sh
   ```

2. **Deploy Prod Account**:
   ```bash
   cd accounts/prod
   terraform init
   terraform apply
   ```
   
3. **Note the Grafana Endpoint Service Name**:
   - Take note of the `grafana_endpoint_service_name` output value

4. **Deploy Dev Account**:
   ```bash
   cd accounts/dev
   
   # Set the Grafana endpoint service name
   export TF_VAR_grafana_endpoint_service_name="com.amazonaws.vpce.eu-central-1.vpce-svc-xxxxx"
   
   terraform init
   terraform apply
   ```

5. **Download VPN Configuration**:
   - In the AWS Console, go to VPC > Client VPN Endpoints
   - Select the VPN endpoint
   - Download the client configuration file

6. **Connect to VPN**:
   - Install AWS Client VPN app
   - Import the configuration file
   - Connect to the VPN

7. **Access Grafana**:
   - Open a browser and navigate to `grafana.internal.company:5003`
   - Log in with the admin credentials from the prod account outputs
   
## Modification and Updates

To update or modify the infrastructure:

1. **Monitor Stack (in prod account)**:
   ```bash
   # Add a new Grafana dashboard
   kubectl -n monitoring create configmap my-dashboard --from-file=my-dashboard.json
   
   # Scale Prometheus storage
   kubectl -n monitoring edit pvc prometheus-server
   ```

2. **VPN Configuration (in dev account)**:
   ```bash
   # Add a new authorization rule
   aws ec2 authorize-client-vpn-ingress \
     --client-vpn-endpoint-id cvpn-endpoint-xxxx \
     --target-network-cidr 10.30.0.0/16 \
     --authorize-all-groups
   ```

3. **Access Management**:
   - Add/remove users from the directory service in AWS Console
   - Update route tables for new network ranges

## Troubleshooting

- **VPN Connection Issues**: 
  - Check client configuration file
  - Verify security group rules
  - Validate authorization rules
  
- **Grafana Access Issues**:
  - Verify DNS resolution (`nslookup grafana.internal.company`)
  - Check VPC Endpoint security groups
  - Validate NLB health checks

- **Cross-Account Access**:
  - Verify IAM role permissions
  - Check allowed principals on VPC Endpoint Service

## Network Flow

Here's how traffic flows through the entire system:

1. User connects to AWS Client VPN in dev account
2. User requests `grafana.internal.company:5003`
3. Private Route53 zone resolves the name to the VPC Endpoint IP
4. Traffic flows through the VPC Endpoint to the PrivateLink connection
5. PrivateLink forwards traffic to the Network Load Balancer in prod
6. NLB forwards traffic to the Grafana service in the EKS cluster
7. Grafana responds through the same path back to the user

## Security Features

- All services are deployed in private subnets
- Access requires successful VPN authentication
- PrivateLink ensures traffic never traverses the public internet
- Network policies restrict pod access
- Bastion host available for administrative access
- Cross-account IAM roles with least privilege permissions

## Directory Structure

```bash
.
├── accounts
│   ├── dev
│   │   ├── backend.tf
│   │   ├── bastion.tf
│   │   ├── iam_principal.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── privatelink.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   └── vpn.tf
│   └── prod
│       ├── backend.tf
│       ├── main.tf
│       ├── monitoring.tf
│       ├── outputs.tf
│       └── providers.tf
├── modules
│   ├── eks
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam-bastion-role
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam-cross-account
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf