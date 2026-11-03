variable "privatelink_service_name" {
  description = "Published PrivateLink service name from the provider output."
  type        = string
}

variable "vpn_server_cert_arn" {
  description = "Imported ACM server certificate ARN for AWS Client VPN."
  type        = string
}

variable "vpn_root_ca_arn" {
  description = "Imported ACM client CA certificate ARN for AWS Client VPN."
  type        = string
}

variable "client_cidr_block" {
  type    = string
  default = "172.16.0.0/22"
}

variable "vpn_dns_servers" {
  type    = list(string)
  default = ["10.10.0.2"]
}
