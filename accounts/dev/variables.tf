variable "grafana_endpoint_service_name" {
  description = "The service name of the Grafana endpoint service in prod account"
  type        = string
  # This will be provided from the prod account output
  # Example: com.amazonaws.vpce.eu-central-1.vpce-svc-1234567890abcdef0
}

variable "server_certificate_file_path" {
  description = "Path to the server certificate file for VPN"
  type        = string
  default     = "certs/server.crt"
}

variable "server_key_file_path" {
  description = "Path to the server key file for VPN"
  type        = string
  default     = "certs/server.key"
}

variable "client_cidr_block" {
  description = "Client CIDR block for VPN"
  type        = string
  default     = "172.16.0.0/22"
}

variable "key_pair_name" {
  description = "SSH key name for EC2 login"
  type        = string
}
