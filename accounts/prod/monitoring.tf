resource "aws_security_group" "hello_world_sg" {
  name        = "hello-world-sg"
  description = "Allow access to Hello World service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]  # Internal Prod VPC
    description = "Allow Hello World access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hello-world-sg"
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

# SSM role for Hello World instance
resource "aws_iam_role" "hello_world_ssm_role" {
  name = "HelloWorldSSMRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "hello_world_ssm_managed_instance_core" {
  role       = aws_iam_role.hello_world_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "hello_world_ssm_profile" {
  name = "HelloWorldSSMInstanceProfile"
  role = aws_iam_role.hello_world_ssm_role.name
}

resource "aws_instance" "hello_world" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.hello_world_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.hello_world_ssm_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    
    # Create a simple HTTP server
    cat > /home/ec2-user/hello_world.py << 'PYTHON_SCRIPT'
import http.server
import socketserver
import json
from datetime import datetime

class HelloWorldHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "message": "Hello World from Production!",
            "timestamp": datetime.now().isoformat(),
            "server": "prod-hello-world",
            "status": "healthy"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())

PORT = 8080
with socketserver.TCPServer(("", PORT), HelloWorldHandler) as httpd:
    print(f"Hello World server running on port {PORT}")
    httpd.serve_forever()
PYTHON_SCRIPT

    # Create systemd service
    cat > /etc/systemd/system/hello-world.service << 'SERVICE_FILE'
[Unit]
Description=Hello World Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/hello_world.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE_FILE

    # Start the service
    systemctl daemon-reload
    systemctl enable hello-world
    systemctl start hello-world
  EOF

  tags = {
    Name = "HelloWorldInstance"
  }
}

resource "aws_lb" "hello_world_nlb" {
  name               = "hello-world-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = "HelloWorldNLB"
  }
}

resource "aws_lb_target_group" "hello_world_tg" {
  name        = "hello-world-tg"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "hello_world_attach" {
  target_group_arn = aws_lb_target_group.hello_world_tg.arn
  target_id        = aws_instance.hello_world.id
  port             = 8080
}

resource "aws_lb_listener" "hello_world_listener" {
  load_balancer_arn = aws_lb.hello_world_nlb.arn
  port              = 8080
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hello_world_tg.arn
  }
}

resource "aws_vpc_endpoint_service" "hello_world" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.hello_world_nlb.arn]

  tags = {
    Name = "hello-world-endpoint-service"
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "dev_account" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.hello_world.id
  principal_arn           = "arn:aws:iam::471112589061:root"  # Your actual dev account
}
output "hello_world_endpoint_service_name" {
  value = aws_vpc_endpoint_service.hello_world.service_name
}

output "hello_world_ec2_private_ip" {
  value = aws_instance.hello_world.private_ip
}