# Architecture

The provider account has an internal NLB and an AWS VPC endpoint service. The consumer account creates an interface endpoint for that service. This grants access to one TCP service without routed connectivity between VPCs.

The two OpenTofu stacks have separate state backends. The provider exports a service name that is passed to the consumer. The consumer account has no reason to read the provider state.

The consumer private Route 53 zone resolves `hello.internal.company` to its endpoint ENIs. DNS resolution happens before TCP traffic crosses PrivateLink. VPN clients need a resolver route for the private suffix on their own OS.

Both VPCs use private-only subnets. SSM interface endpoints support management access without internet gateways or NAT. The provider EC2 instance starts its demo HTTP server with Python from the base AMI.

The NLB spans two availability zones with cross-zone forwarding, but the demo has one backend target. VPN authorization covers the consumer VPC CIDR, with the VPN security group limited to DNS and the endpoint's TCP port. The endpoint service automatically accepts connections from allowlisted principals. A real application needs TLS, application authentication, redundant targets, and tighter approval and access policies.

The exact address ranges and ports are in the [network reference](../reference/network.md).
