terraform {
  backend "s3" {
    bucket         = "tf-state-prod-471112589061"
    key            = "prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-prod"
    profile        = "prod"
    encrypt        = true
  }
}
