variable "role_name" {
  type        = string
  description = "Name of the IAM role to create"
}

variable "trusted_principal_arn" {
  type        = string
  description = "ARN of the IAM role in dev account allowed to assume this role"
}

variable "allowed_actions" {
  type        = list(string)
  description = "List of allowed AWS actions for this role"
}
