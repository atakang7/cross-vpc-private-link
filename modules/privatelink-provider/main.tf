resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App SG for demo instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow NLB health checks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "al2" {
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

resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "demo" {
  count                       = var.create_demo_instance ? 1 : 0
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.micro"
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    cat > /home/ec2-user/hello_world.py << 'PY'
import http.server, socketserver, json
from datetime import datetime
class H(http.server.SimpleHTTPRequestHandler):
  def do_GET(self):
    self.send_response(200)
    self.send_header('Content-type','application/json')
    self.end_headers()
    self.wfile.write(json.dumps({"message":"Hello from provider","ts":datetime.now().isoformat()}).encode())
PORT=%PORT%
with socketserver.TCPServer(("", PORT), H) as httpd: httpd.serve_forever()
PY
    sed -i "s/%PORT%/${var.port}/" /home/ec2-user/hello_world.py
    cat > /etc/systemd/system/hello.service << 'SVC'
[Unit]
Description=Hello Service
After=network.target
[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/hello_world.py
Restart=always
[Install]
WantedBy=multi-user.target
SVC
    systemctl daemon-reload
    systemctl enable hello
    systemctl start hello
  EOF

  tags = { Name = "${var.name}-demo" }
}

resource "aws_lb" "nlb" {
  name               = "${var.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids
  tags               = { Name = "${var.name}-nlb" }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.name}-tg"
  port        = var.port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = var.create_demo_instance ? 1 : 0
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.demo[0].id
  port             = var.port
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
  tags = { Name = "${var.name}-vpce-svc" }
}

resource "aws_vpc_endpoint_service_allowed_principal" "allow" {
  for_each                = toset(var.allowed_principals)
  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = each.value
}

output "service_name" {
  value = aws_vpc_endpoint_service.this.service_name
}

output "demo_private_ip" {
  value = try(aws_instance.demo[0].private_ip, null)
}
