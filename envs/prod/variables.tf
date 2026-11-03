variable "dev_account_root_arn" {
  description = "Explicitly allow the consumer AWS account to create an interface endpoint. This grants the account permission to request connections."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:root$", var.dev_account_root_arn))
    error_message = "Provide the consumer account root ARN, e.g. arn:aws:iam::123456789012:root."
  }
}
