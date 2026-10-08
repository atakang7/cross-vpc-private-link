resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Demo backend traffic from provider VPC NLB nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Only traffic from the provider VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
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
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = false
  user_data                   = templatefile("${path.module}/bootstrap.sh.tftpl", { port = var.port })

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = { Name = "${var.name}-demo" }
}

resource "aws_lb" "nlb" {
  name                             = "${var.name}-nlb"
  internal                         = true
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets                          = var.private_subnet_ids
  tags                             = { Name = "${var.name}-nlb" }
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
  acceptance_required        = false # demo-only: tighten approval policy for production
  network_load_balancer_arns = [aws_lb.nlb.arn]
  tags                       = { Name = "${var.name}-vpce-svc" }
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
