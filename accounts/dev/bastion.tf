resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssm-only"
  description = "Allow SSM only"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = "ami-0c2b8ca1dad447f8a"
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = module.bastion_iam_role.instance_profile_name

  tags = {
    Name = "SecureBastion"
  }
}
