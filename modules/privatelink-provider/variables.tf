variable "name" {
  description = "Name prefix for resources."
  type        = string
}

variable "vpc_id" {
  description = "Provider VPC ID."
  type        = string
}

variable "vpc_cidr" {
  description = "Provider VPC CIDR. Only NLB nodes inside this VPC may reach the demo target."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the NLB."
  type        = list(string)
}

variable "port" {
  description = "Application port exposed via NLB/PrivateLink."
  type        = number
  default     = 8080
}

variable "allowed_principals" {
  description = "Explicit AWS principal ARNs allowed to create consumer endpoints."
  type        = list(string)
  default     = []
}

variable "create_demo_instance" {
  description = "Create one demo EC2 backend. Not a highly available production service."
  type        = bool
  default     = true
}
