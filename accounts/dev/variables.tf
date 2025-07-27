variable "hello_world_endpoint_service_name" {
  description = "The service name of the Hello World endpoint service in prod account"
  type        = string
  # This will be provided from the prod account output
  # Example: com.amazonaws.vpce.eu-central-1.vpce-svc-1234567890abcdef0
}

variable "server_certificate_file_path" {
  description = "Path to the server certificate file for VPN"
  type        = string
  default     = "scripts/certs/server.crt"
}

variable "server_key_file_path" {
  description = "Path to the server key file for VPN"
  type        = string
  default     = "scripts/certs/server.key"
}

variable "client_cidr_block" {
  description = "Client CIDR block for VPN"
  type        = string
  default     = "172.16.0.0/22"
}