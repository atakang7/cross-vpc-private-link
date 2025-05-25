resource "aws_iam_role" "dev_to_prod" {
  name = "CrossAccountProdAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "arn:aws:iam::928558116184:root"
      },
      Action = "sts:AssumeRole"
    }]
  })
}
