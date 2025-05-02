provider "aws" {
  region  = "eu-central-1"
  profile = "dev"
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "dev-vpc"
  region                = "eu-central-1"
  vpc_cidr              = "10.10.0.0/16"
  public_subnet_cidrs   = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs  = ["10.10.3.0/24", "10.10.4.0/24"]
  azs                   = ["eu-central-1a", "eu-central-1b"]
  ssm_endpoint_sg       = aws_security_group.bastion_sg.id
}

module "bastion_iam_role" {
  source    = "../../modules/iam-bastion-role"
  role_name = "DevBastionEC2Role"
}

module "eks" {
  source      = "../../modules/eks"
  name        = "dev-eks"
  subnet_ids  = module.vpc.private_subnet_ids
}