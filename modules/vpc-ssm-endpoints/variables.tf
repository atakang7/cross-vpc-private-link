variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs to place interface endpoints"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "CIDR ranges allowed to connect to SSM endpoints"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS region"
  type        = string
}
