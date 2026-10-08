# privatelink-provider

Provisions an **internal** NLB, TCP listener/target group, an endpoint service restricted to `allowed_principals`, and optionally a **single demo** Amazon Linux 2023 EC2 target. The backend is bootstrapped with preinstalled Python 3 and systemd, with no package downloads or public address.

Inputs: `name`, `vpc_id`, `vpc_cidr`, `private_subnet_ids`, `port` (default 8080), `allowed_principals`, `create_demo_instance` (default true).

Outputs: `service_name` and `demo_private_ip` (null if disabled).

The backend SG only admits traffic from the provider VPC CIDR; it is **not** open to the internet. Endpoint acceptance is automatic for allowed principals **only in this lab**. Production requires explicit approval, app-layer TLS/authentication, and redundant targets.
