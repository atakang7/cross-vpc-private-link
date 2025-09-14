variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for NLB"
  type        = list(string)
}

variable "port" {
  description = "Application port exposed via NLB/PrivateLink"
  type        = number
  default     = 8080
}

variable "allowed_principals" {
  description = "List of AWS principal ARNs allowed to create endpoints"
  type        = list(string)
  default     = []
}

variable "create_demo_instance" {
  description = "Whether to create a demo EC2 instance and systemd hello-world"
  type        = bool
  default     = true
}
