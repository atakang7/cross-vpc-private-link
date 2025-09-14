resource "aws_security_group" "endpoint" {
  name        = "${var.name}-vpce-sg"
  description = "SG for PrivateLink interface endpoint"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allow_cidrs
    content {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = var.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = false
  tags                = { Name = "${var.name}-vpce" }
}

resource "aws_route53_zone" "private" {
  count = var.create_private_dns ? 1 : 0
  name  = var.private_zone_name
  vpc { vpc_id = var.vpc_id }
  tags = { Name = "${var.name}-private-zone" }
}

resource "aws_route53_record" "record" {
  count   = var.create_private_dns ? 1 : 0
  zone_id = aws_route53_zone.private[0].zone_id
  name    = "${var.record_name}.${var.private_zone_name}"
  type    = "A"
  alias {
    name                   = aws_vpc_endpoint.this.dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.this.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

output "endpoint_id" {
  value = aws_vpc_endpoint.this.id
}

output "endpoint_dns" {
  value = aws_vpc_endpoint.this.dns_entry[0].dns_name
}

output "private_dns_name" {
  value = var.create_private_dns ? "${var.record_name}.${var.private_zone_name}" : null
}
