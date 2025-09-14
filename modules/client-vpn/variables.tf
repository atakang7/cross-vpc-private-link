variable "name" {
  type        = string
  description = "Name prefix"
}

variable "vpc_id" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "client_cidr_block" {
  type        = string
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR to authorize access from Client VPN (e.g., 10.10.0.0/16)"
}

variable "server_certificate_arn" {
  type        = string
  description = "ACM ARN of the server certificate"
}

variable "root_ca_arn" {
  type        = string
  description = "ACM ARN of the client root CA"
}

variable "manage_vpc_route" {
  type        = bool
  description = "Whether to manage/create the VPC-wide route (var.vpc_cidr) from the Client VPN. Disable if AWS or another process creates it automatically to avoid duplicate route errors."
  default     = true
}

variable "target_vpc_subnet_id" {
  description = "The ID of the subnet to associate with the client VPN endpoint for route creation."
  type        = string
}

