resource "aws_iam_role" "cross_account_access" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        AWS = var.trusted_principal_arn
      }
    }]
  })
}

resource "aws_iam_role_policy" "permissions" {
  name = "${var.role_name}-permissions"
  role = aws_iam_role.cross_account_access.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = var.allowed_actions,
      Resource = "*"
    }]
  })
}