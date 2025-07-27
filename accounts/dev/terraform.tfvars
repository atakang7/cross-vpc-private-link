# Development Environment Variables

# Get this value from prod environment output after deployment
# Run: terraform output hello_world_endpoint_service_name
hello_world_endpoint_service_name = "com.amazonaws.vpce.eu-central-1.vpce-svc-0fd05d1219d2ef4c7"

# VPN certificate paths (already generated in scripts/certs/)
server_certificate_file_path = "scripts/certs/server.crt"
server_key_file_path = "scripts/certs/server.key"

# VPN client CIDR block
client_cidr_block = "172.16.0.0/22"