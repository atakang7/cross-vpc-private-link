resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssm-only"
  description = "Allow SSM and access from VPN"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/22"]  # VPN CIDR
    description = "Allow SSH from VPN clients"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "bastion-sg"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = module.bastion_iam_role.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq kubectl
    amazon-linux-extras install -y docker
    systemctl enable docker
    systemctl start docker
    
    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    
    # Configure AWS CLI for cross-account access
    mkdir -p /home/ec2-user/.aws
    cat > /home/ec2-user/.aws/config << 'AWSCONFIG'
    [profile dev]
    region = eu-central-1
    
    [profile prod]
    region = eu-central-1
    role_arn = arn:aws:iam::471112589061:role/ProdAcceptFromDev
    source_profile = dev
    AWSCONFIG
    
    chown -R ec2-user:ec2-user /home/ec2-user/.aws
    
  EOF

  tags = {
    Name = "SecureBastion"
  }
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}