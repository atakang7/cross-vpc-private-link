variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "ssm_endpoint_sg" {
  description = "Security group to attach to SSM endpoint"
  type        = string
}
