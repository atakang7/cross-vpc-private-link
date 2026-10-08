# client-vpn

Creates an AWS Client VPN endpoint with mutual certificate authentication, CloudWatch connection logging (30-day retention), authorization for `vpc_cidr`, and subnet associations. Split tunneling is enabled.

Inputs: `name`, `vpc_id`, `subnet_ids`, `client_cidr_block`, `dns_servers`, `vpc_cidr`, `server_certificate_arn`, `root_ca_arn`, `target_vpc_subnet_id`, `manage_vpc_route`.

Outputs: `endpoint_id`, `dns_name`.

The root module sets `manage_vpc_route=false` because associations produce the local VPC route. A connected VPN client still needs correct OS DNS resolver configuration. The all-groups VPC authorization is suitable for a lab, **not** least-privilege production access.
