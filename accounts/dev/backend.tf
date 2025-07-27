terraform {
  backend "s3" {
    bucket         = "tf-state-dev-471112589061"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-dev"
    profile        = "dev"
    encrypt        = true
  }
}
