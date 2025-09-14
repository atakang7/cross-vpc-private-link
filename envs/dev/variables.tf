variable "client_cidr_block" {
	type    = string
	default = "172.16.0.0/22"
}

variable "vpn_dns_servers"  {
	type    = list(string)
	default = ["10.10.0.2"]
}
