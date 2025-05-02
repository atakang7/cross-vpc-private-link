output "role_arn" {
  value = aws_iam_role.bastion_role.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.bastion_instance_profile.name
}
