# Cross-account service access with AWS PrivateLink

The goal is simple: reach **one internal service** in a different AWS account without routing between the two VPCs.

![Provider/consumer network topology](../img/architecture.svg)

## Design

The provider publishes an internal NLB through a VPC endpoint service and allows the consumer account principal. The consumer creates an interface endpoint and a private Route 53 alias (`hello.internal.company`). The developer reaches the consumer network via certificate-authenticated AWS Client VPN.

The roles are distinct:

- **DNS:** VPC resolver `10.10.0.2` resolves the private name to endpoint ENI addresses.
- **Data:** Client VPN → endpoint ENI → PrivateLink → endpoint service → internal NLB → EC2 TCP/8080.
- **Permission:** An allowed principal permits endpoint creation. Endpoint security groups, VPN authorization, and application authentication govern access separately.

There is no VPC peering or routed connectivity to the provider VPC.

## Reproduce

See the [repository README](../README.md#deploy) for the two-account setup, state backends and cost warning.

```bash
bash first-run.sh
```

After connecting with the exported `dev.ovpn`, verify:

```bash
bash scripts/60_test_privateline.sh
```

The demo returns a short JSON response from the backend EC2 instance.

## Things that break

- **VPN connected, hostname unresolved:** check the client's DNS resolver selection. Split tunnel does not configure conditional DNS on every OS.
- **Endpoint exists, no response:** check provider allowed principals / endpoint acceptance, NLB target health and endpoint/target SG rules.
- **EC2 backend unhealthy:** inspect cloud-init and `hello.service`. The instance has no NAT or internet access; boot must not download packages.

The deployed example has **one backend** and **plaintext HTTP**. It demonstrates network isolation, not production availability or zero-trust application identity.

See [operational checks](operations.md) and [teardown](../README.md#teardown).
