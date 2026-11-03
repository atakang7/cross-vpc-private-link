# Verify the private service

1. After [deployment](deploy.md), connect the exported Client VPN profile:

```bash
sudo openvpn --config dev.ovpn \
  --cert scripts/certs/client.crt \
  --key scripts/certs/client.key \
  --ca scripts/certs/ca.crt
```

2. In another terminal, test DNS resolution and the service response:

```bash
bash scripts/60_test_privateline.sh
```

The expected JSON has `"message": "Hello from provider"` and a `ts` timestamp.

If the hostname does not resolve, the VPN client's OS may need a DNS rule for `internal.company` through the consumer VPC resolver. See [connection failures](troubleshoot.md).
