output "state_bucket_name" {
	description = "S3 bucket name for Terraform remote state."
	value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
	description = "S3 bucket ARN for Terraform remote state."
	value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
	description = "DynamoDB lock table name if created."
	value       = try(aws_dynamodb_table.terraform_locks[0].name, null)
}

output "github_oidc_provider_arn" {
	description = "GitHub OIDC provider ARN if created or supplied."
	value       = local.github_oidc_provider_arn
}

output "infra_role_arn" {
	description = "Initial infrastructure role ARN if created."
	value       = try(aws_iam_role.infra[0].arn, null)
}
