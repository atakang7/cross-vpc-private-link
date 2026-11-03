# Network values

| Setting | Value |
| --- | --- |
| Region | `eu-central-1` |
| Subnet availability zones | `eu-central-1a`, `eu-central-1b` |
| Consumer VPC | `10.10.0.0/16` |
| Consumer private subnets | `10.10.0.0/17`, `10.10.128.0/17` |
| Provider VPC | `10.20.0.0/16` |
| Provider private subnets | `10.20.0.0/17`, `10.20.128.0/17` |
| VPN client CIDR | `172.16.0.0/22` |
| Consumer VPC resolver | `10.10.0.2` |
| Private hosted zone | `internal.company` |
| Service record | `hello.internal.company` |
| Application transport | TCP/8080 |
| Demo backend protocol | HTTP |

The provider output `hello_world_service_name` is the consumer input `privatelink_service_name`.
