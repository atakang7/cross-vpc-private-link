resource "aws_security_group" "grafana_sg" {
  name        = "grafana-sg"
  description = "Allow access to Grafana + Node Exporter"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]  # Internal Prod VPC
    description = "Allow Grafana access"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]  # Grafana scraping itself
    description = "Allow Node Exporter access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana-sg"
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

# SSM role for Grafana instance
resource "aws_iam_role" "grafana_ssm_role" {
  name = "GrafanaSSMRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_ssm_managed_instance_core" {
  role       = aws_iam_role.grafana_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "grafana_ssm_profile" {
  name = "GrafanaSSMInstanceProfile"
  role = aws_iam_role.grafana_ssm_role.name
}

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.grafana_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.grafana_ssm_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # Install Grafana
    cat > /etc/yum.repos.d/grafana.repo << 'GRAFANA_REPO'
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
GRAFANA_REPO

    yum install -y grafana
    
    # Configure Grafana to run on port 3000
    systemctl enable grafana-server
    systemctl start grafana-server

    # Install Node Exporter
    useradd -rs /bin/false node_exporter
    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
    cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
    chown node_exporter:node_exporter /usr/local/bin/node_exporter

    cat > /etc/systemd/system/node_exporter.service << 'NODE_EXPORTER_SERVICE'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
NODE_EXPORTER_SERVICE

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
  EOF

  tags = {
    Name = "GrafanaInstance"
  }
}

resource "aws_lb" "grafana_nlb" {
  name               = "grafana-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.private_subnet_ids

  tags = {
    Name = "GrafanaNLB"
  }
}

resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "grafana_attach" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = aws_instance.grafana.id
  port             = 3000
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.grafana_nlb.arn
  port              = 3000
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_vpc_endpoint_service" "grafana" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.grafana_nlb.arn]

  tags = {
    Name = "grafana-endpoint-service"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "dev_account" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.grafana.id
  principal_arn           = "arn:aws:iam::928558116184:root"
}

output "grafana_endpoint_service_name" {
  value = aws_vpc_endpoint_service.grafana.service_name
}

output "grafana_ec2_private_ip" {
  value = aws_instance.grafana.private_ip
}