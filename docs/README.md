# Network notes

Private DNS resolves the consumer interface endpoint; PrivateLink carries TCP traffic to the provider's internal NLB.

- `aws_route53_record.record` aliases `hello.internal.company` to the endpoint DNS name.
- Consumer VPN clients must resolve `internal.company` through `10.10.0.2`.
- `aws_vpc_endpoint_service_allowed_principal.allow` permits endpoint creation, not HTTP access.
- The consumer receives `hello_world_service_name`; it never reads provider state.

## Verify

With Client VPN connected, from the repository root:

```bash
bash scripts/60_test_privateline.sh
```

Expect JSON containing `"message": "Hello from provider"`.
