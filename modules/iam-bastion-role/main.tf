resource "aws_iam_role" "bastion_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.bastion_role.name
}
