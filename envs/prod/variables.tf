variable "aws_region" {
	description = "AWS region for production infrastructure."
	type        = string
}

variable "project_name" {
	description = "Project name used in resource naming and tagging."
	type        = string
	default     = "gym-tracker"
}

variable "environment" {
	description = "Environment name."
	type        = string
	default     = "prod"
}

variable "tags" {
	description = "Additional tags applied to all resources."
	type        = map(string)
	default     = {}
}

variable "vpc_cidr" {
	description = "CIDR block for the VPC."
	type        = string
}

variable "public_subnet_cidr" {
	description = "CIDR block for the public subnet hosting EC2."
	type        = string
}

variable "public_subnet_az" {
	description = "Availability zone for the public subnet."
	type        = string
}

variable "private_subnets" {
	description = "Private subnet definitions for RDS."
	type = list(object({
		cidr = string
		az   = string
	}))
}

variable "allow_ssh" {
	description = "Whether to allow SSH ingress on EC2 SG."
	type        = bool
	default     = false
}

variable "ssh_cidr_blocks" {
	description = "CIDR blocks allowed for SSH if enabled."
	type        = list(string)
	default     = []
}

variable "ec2_ami_id" {
	description = "Optional custom AMI ID for EC2. If null, latest Amazon Linux 2023 is used."
	type        = string
	default     = null
}

variable "ec2_instance_type" {
	description = "EC2 instance type."
	type        = string
	default     = "t3.small"
}

variable "ec2_key_name" {
	description = "Optional EC2 key pair name for emergency SSH access."
	type        = string
	default     = null
}

variable "ec2_root_volume_size" {
	description = "Root EBS volume size for EC2 instance in GB."
	type        = number
	default     = 40
}

variable "rds_engine_version" {
	description = "PostgreSQL engine version for RDS."
	type        = string
	default     = "16.3"
}

variable "rds_instance_class" {
	description = "RDS instance class."
	type        = string
	default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
	description = "Allocated RDS storage in GB."
	type        = number
	default     = 20
}

variable "rds_max_allocated_storage" {
	description = "Maximum autoscaled RDS storage in GB."
	type        = number
	default     = 100
}

variable "rds_db_name" {
	description = "Initial PostgreSQL database name."
	type        = string
}

variable "rds_master_username" {
	description = "Master username for PostgreSQL."
	type        = string
}

variable "rds_master_password" {
	description = "Master password for PostgreSQL."
	type        = string
	sensitive   = true
}

variable "rds_backup_retention_period" {
	description = "RDS backup retention in days."
	type        = number
	default     = 7
}

variable "rds_backup_window" {
	description = "RDS backup window in UTC."
	type        = string
	default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
	description = "RDS maintenance window in UTC."
	type        = string
	default     = "sun:04:00-sun:05:00"
}

variable "rds_skip_final_snapshot" {
	description = "Whether to skip final snapshot when destroying RDS."
	type        = bool
	default     = false
}

variable "rds_deletion_protection" {
	description = "Enable deletion protection for RDS."
	type        = bool
	default     = true
}

variable "ecr_repository_names" {
	description = "ECR repositories to create."
	type        = list(string)
	default = [
		"gym-tracker-frontend",
		"gym-tracker-backend"
	]
}

variable "ecr_image_tag_mutability" {
	description = "ECR tag mutability setting."
	type        = string
	default     = "MUTABLE"
}

variable "create_github_oidc_provider" {
	description = "Whether to create GitHub OIDC provider in this stack."
	type        = bool
	default     = false
}

variable "existing_github_oidc_provider_arn" {
	description = "Existing GitHub OIDC provider ARN when not creating one."
	type        = string
	default     = null
}

variable "github_oidc_url" {
	description = "GitHub OIDC provider URL."
	type        = string
	default     = "https://token.actions.githubusercontent.com"
}

variable "github_oidc_client_ids" {
	description = "GitHub OIDC audiences."
	type        = list(string)
	default     = ["sts.amazonaws.com"]
}

variable "github_oidc_thumbprints" {
	description = "GitHub OIDC provider thumbprints."
	type        = list(string)
	default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "infra_role_name" {
	description = "IAM role for infra workflow."
	type        = string
}

variable "infra_role_subject" {
	description = "OIDC subject pattern for infra workflow role."
	type        = string
}

variable "infra_role_policy_arns" {
	description = "Managed policy ARNs attached to infra role."
	type        = list(string)
	default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "frontend_role_name" {
	description = "IAM role for frontend deploy workflow."
	type        = string
}

variable "frontend_role_subject" {
	description = "OIDC subject pattern for frontend workflow role."
	type        = string
}

variable "frontend_role_policy_arns" {
	description = "Managed policy ARNs attached to frontend role."
	type        = list(string)
}

variable "backend_role_name" {
	description = "IAM role for backend deploy workflow."
	type        = string
}

variable "backend_role_subject" {
	description = "OIDC subject pattern for backend workflow role."
	type        = string
}

variable "backend_role_policy_arns" {
	description = "Managed policy ARNs attached to backend role."
	type        = list(string)
}

variable "ec2_role_name" {
	description = "IAM role attached to the EC2 instance profile."
	type        = string
}

variable "ec2_instance_profile_name" {
	description = "EC2 instance profile name."
	type        = string
}

variable "ec2_managed_policy_arns" {
	description = "Managed policy ARNs attached to EC2 role (SSM + ECR pull minimum)."
	type        = list(string)
	default = [
		"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
		"arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
	]
}

variable "log_retention_days" {
	description = "App CloudWatch log retention in days."
	type        = number
	default     = 30
}

variable "create_dns_record" {
	description = "Whether to create a Route53 A record for EC2 public IP."
	type        = bool
	default     = false
}

variable "route53_zone_id" {
	description = "Hosted zone ID for Route53 record."
	type        = string
	default     = null
}

variable "route53_record_name" {
	description = "Record name in Route53."
	type        = string
	default     = null
}
