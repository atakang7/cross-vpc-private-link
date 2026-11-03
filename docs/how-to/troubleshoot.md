# Diagnose a failed connection

Check each boundary in order after the [VPN connection test](verify.md).

| Symptom | Check |
| --- | --- |
| Client VPN cannot connect | ACM server and client CA certificates, network association, CloudWatch connection logs |
| VPN connects but hostname fails | Client DNS selection, resolver `10.10.0.2`, Route 53 private zone association |
| Hostname resolves but TCP/8080 times out | Interface endpoint status and security group, VPN authorization |
| Endpoint exists but service does not respond | Provider endpoint service permission, NLB target health, backend security group |
| Backend target is unhealthy | `hello.service`, `/var/log/cloud-init-output.log`, EC2 SSM access |
| OpenTofu init fails | Profile, S3 bucket access, DynamoDB lock table and region |

For a DNS failure, check the client OS resolver configuration. Avoid changing system-wide `/etc/resolv.conf` to point every query at the VPC resolver.
