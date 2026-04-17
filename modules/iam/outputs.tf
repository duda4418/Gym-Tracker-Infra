output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN used by roles."
  value       = local.github_oidc_provider_arn
}

output "infra_role_arn" {
  description = "Infrastructure workflow role ARN."
  value       = aws_iam_role.infra.arn
}

output "frontend_role_arn" {
  description = "Frontend deployment workflow role ARN."
  value       = aws_iam_role.frontend.arn
}

output "backend_role_arn" {
  description = "Backend deployment workflow role ARN."
  value       = aws_iam_role.backend.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name."
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_role_arn" {
  description = "EC2 IAM role ARN."
  value       = aws_iam_role.ec2.arn
}
