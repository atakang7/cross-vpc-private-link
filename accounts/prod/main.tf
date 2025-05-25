provider "aws" {
  region  = "eu-central-1"
  profile = "prod"
}

module "prod_trust_role" {
  source = "../../modules/iam-cross-account"

  role_name             = "ProdAcceptFromDev"
  trusted_principal_arn = "arn:aws:iam::928558116184:role/DevBastionEC2Role"  # Ensure this ARN exists in dev account
  allowed_actions = [
    "eks:DescribeCluster",
    "eks:ListNodegroups",
    "eks:ListClusters"
  ]
}

resource "aws_security_group" "eks_ssm_endpoint" {
  name        = "eks-ssm-endpoint"
  description = "SG for SSM VPC endpoint"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "prod-vpc"
  region                = "eu-central-1"
  vpc_cidr              = "10.20.0.0/16"
  public_subnet_cidrs   = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs  = ["10.20.3.0/24", "10.20.4.0/24"]
  azs                   = ["eu-central-1a", "eu-central-1b"]
  ssm_endpoint_sg       = aws_security_group.eks_ssm_endpoint.id
}