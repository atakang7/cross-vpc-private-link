# Secure internal service communication with PrivateLink

## Introduction

Exposing internal services through internet is not suggested due to security reasons. Most of the enterprises construct their network on highly secured connections. These, usually, well maintained by cloud providers like AWS, Azure, GCP and all has their own similar solutions to the matter. In today's writing, I will be focusing on one of these solutions. AWS PrivateLink.

## What is AWS PrivateLink

AWS PrivateLink helps customers to have connectivity between different VPC resources even in different regions. The data transfer is unidirectional and never leaves AWS-owned fiber network. Connectivity can be configured in different zones and regions. By enabling Cross-Zone Load Balancing you can allow the Network Load Balancer (NLB) to distribute traffic evenly across all registered targets in all enabled AZs, regardless of the AZ where the client is located.

The concept is constructed around producer-consumer model where the producer sets up NLB, Target Group and VPC Service Provider. Consumer VPC setups VPC endpoint with Elastic Network Interface (ENI).

## Prerequisites

To get started, you need to have two different AWS accounts to experiment together. Configure AWS credentials to start.

Clone the repository:
```bash
git clone https://github.com/atakang7/cross-vpc-private-link.git
```

Run the script:
```bash
❯ bash first-run.sh
```

## Script Execution Flow

After running the script, it will do the following:

### 1. Scripts/00_check_prereqs.sh

Checks script prerequisites: tofu (ex-terraform), aws, openssl.

- **Tofu** is OSS fork of Terraform - almost everything is the same as before
- **AWS** is the AWS CLI for managing resources
- **OpenSSL** needed to generate VPN certificates

### 2. Scripts/10_generate_certs.sh

Creates VPN certificates:

- **CA certificate** (ca.crt) - Root certificate authority for signing
- **Server certificate** (server.crt) - Authenticates the VPN endpoint
- **Client certificate** (client.crt) - Authenticates VPN clients

### 3. Scripts/20_import_acm.sh

Imports generated certificates to AWS Certificate Manager in dev account:


- **Server cert + CA chain** - Required for VPN endpoint SSL termination
- **Root CA cert** - Used for client certificate validation
- **Returns ARNs** - Certificate ARNs passed to Terraform for VPN configuration

### 4. Scripts/30_deploy_prod.sh

Deploys provider infrastructure in production account:

- **VPC + private subnets** - Isolated network environment
- **Network Load Balancer** - Routes traffic to backend services
- **VPC Endpoint Service** - Exposes NLB via PrivateLink
- **Demo application** - Simple HTTP service for testing

### 5. Scripts/40_deploy_dev.sh

Deploys consumer infrastructure in development account:

- **Consumer VPC** - Separate network for development
- **Interface VPC Endpoint** - Connects to prod PrivateLink service



- **Route53 private zone** - Custom DNS (hello.internal.company)
- **Client VPN endpoint** - Certificate-based remote access

### 6. Scripts/50_export_vpn_config.sh

Exports OpenVPN configuration file:

- **Downloads .ovpn file** - From AWS Client VPN endpoint
- **Includes endpoint details** - Server address, protocol, port
- **Ready for client** - Use with OpenVPN client + certificates

### 7. Scripts/60_test_privateline.sh

Tests PrivateLink connectivity:

- **Curls private service** - http://hello.internal.company:8080
- **Validates DNS resolution** - Route53 private zone working
- **Confirms end-to-end** - VPN → private DNS → PrivateLink → backend

### 8. Scripts/70_destroy_all.sh

Clean teardown of all resources:

- **Dev environment first** - Removes consumer dependencies
- **Prod environment second** - Safely removes provider resources
- **Prevents dependency errors** - Proper destruction order matters

## Testing the Connection

After first_run.sh script completes, connect to VPN with your certificate.

```bash
❯ sudo openvpn --config ./dev.ovpn --cert scripts/certs/client.crt --key scripts/certs/client.key --ca scripts/certs/ca.crt
```

Successful connection:
```
...
2025-09-15 01:15:40 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
2025-09-15 01:15:40 net_route_v4_best_gw query: dst 0.0.0.0
2025-09-15 01:15:40 net_route_v4_best_gw result: via 192.168.1.1 dev wlp0s20f3
2025-09-15 01:15:40 ROUTE_GATEWAY 192.168.1.1/255.255.255.0 IFACE=wlp0s20f3 HWADDR=90:cc:df:08:3a:81
2025-09-15 01:15:40 TUN/TAP device tun0 opened
2025-09-15 01:15:40 net_iface_mtu_set: mtu 1500 for tun0
2025-09-15 01:15:40 net_iface_up: set tun0 up
2025-09-15 01:15:40 net_addr_v4_add: 172.16.0.2/27 dev tun0
2025-09-15 01:15:40 net_route_v4_add: 10.10.0.0/16 via 172.16.0.1 dev [NULL] table 0 metric -1
2025-09-15 01:15:40 Initialization Sequence Completed
```

Try to connect to hello.internal.company:8080.

```bash
❯ curl hello.internal.company:8080
curl: (6) Could not resolve host: hello.internal.company
```

Add DNS server to /etc/resolv.conf.
```
nameserver 10.10.0.2
```

Try again.
```bash
❯ curl hello.internal.company:8080
{"message": "Hello from provider", "ts": "2025-09-14T22:19:10.640669"}
```

## Learning Points

- Be careful not to overlap CIDRs for your VPN and between VPCs.
- If DNS resolution should only be resolved by the company, set split_tunnel to false.

```hcl
resource "aws_ec2_client_vpn_endpoint" "this" {
  ...
  split_tunnel = true
  ...
}
```

Peace ;)
