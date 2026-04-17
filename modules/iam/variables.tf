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
  description = "GitHub OIDC provider URL."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_client_ids" {
  description = "Client IDs (audiences) for GitHub OIDC."
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for GitHub OIDC provider certificates."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "infra_role_name" {
  description = "IAM role name used by Terraform infra workflow."
  type        = string
}

variable "infra_role_subject" {
  description = "OIDC subject pattern for infra role, e.g. repo:org/repo:ref:refs/heads/main."
  type        = string
}

variable "infra_role_policy_arns" {
  description = "Managed policy ARNs attached to infra role."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "frontend_role_name" {
  description = "IAM role name used by frontend deployment workflow."
  type        = string
}

variable "frontend_role_subject" {
  description = "OIDC subject pattern for frontend workflow."
  type        = string
}

variable "frontend_role_policy_arns" {
  description = "Managed policy ARNs attached to frontend deployment role."
  type        = list(string)
}

variable "backend_role_name" {
  description = "IAM role name used by backend deployment workflow."
  type        = string
}

variable "backend_role_subject" {
  description = "OIDC subject pattern for backend workflow."
  type        = string
}

variable "backend_role_policy_arns" {
  description = "Managed policy ARNs attached to backend deployment role."
  type        = list(string)
}

variable "ec2_role_name" {
  description = "IAM role attached to Gym Tracker EC2 instance profile."
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Instance profile name for EC2."
  type        = string
}

variable "ec2_managed_policy_arns" {
  description = "Managed policies attached to EC2 role."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
