variable "name" {
  type        = string
  description = "Name prefix"
}

variable "vpc_id" {
  type        = string
  description = "Consumer VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for Interface Endpoint"
}

variable "service_name" {
  type        = string
  description = "Provider VPC endpoint service name"
}

variable "port" {
  type        = number
  default     = 8080
}

variable "allow_cidrs" {
  type        = list(string)
  default     = []
}

variable "create_private_dns" {
  type        = bool
  default     = true
}

variable "private_zone_name" {
  type        = string
  default     = "internal.company"
}

variable "record_name" {
  type        = string
  default     = "hello"
}
