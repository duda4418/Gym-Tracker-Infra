variable "aws_region" {
	description = "AWS region for bootstrap resources."
	type        = string
}

variable "state_bucket_name" {
	description = "Globally unique S3 bucket name used for Terraform remote state."
	type        = string
}

variable "create_dynamodb_lock_table" {
	description = "Whether to create a DynamoDB lock table for Terraform state locking."
	type        = bool
	default     = true
}

variable "lock_table_name" {
	description = "DynamoDB table name used for Terraform state locking."
	type        = string
	default     = "gym-tracker-terraform-locks"
}

variable "create_github_oidc_provider" {
	description = "Whether to create the GitHub OIDC provider in this account."
	type        = bool
	default     = true
}

variable "existing_github_oidc_provider_arn" {
	description = "Existing GitHub OIDC provider ARN if not creating one."
	type        = string
	default     = null
}

variable "github_oidc_url" {
	description = "GitHub OIDC URL."
	type        = string
	default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_client_ids" {
	description = "OIDC client IDs (audiences)."
	type        = list(string)
	default     = ["sts.amazonaws.com"]
}

variable "github_oidc_thumbprints" {
	description = "OIDC thumbprints for the GitHub provider."
	type        = list(string)
	default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "create_infra_github_role" {
	description = "Whether to create an initial GitHub role skeleton for infra automation."
	type        = bool
	default     = false
}

variable "infra_role_name" {
	description = "IAM role name for Terraform infra GitHub workflow."
	type        = string
	default     = "gym-tracker-infra-gha-role"
}

variable "infra_role_subject" {
	description = "GitHub OIDC subject pattern, e.g. repo:org/repo:ref:refs/heads/main."
	type        = string
	default     = "repo:your-org/your-repo:ref:refs/heads/main"
}

variable "infra_role_policy_arns" {
	description = "Managed policy ARNs attached to the infra role."
	type        = list(string)
	default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "tags" {
	description = "Tags applied to bootstrap resources."
	type        = map(string)
	default     = {}
}
