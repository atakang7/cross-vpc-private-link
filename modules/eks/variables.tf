variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "k8s_version" {
  default = "1.29"
}
