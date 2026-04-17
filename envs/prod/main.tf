terraform {
	required_version = ">= 1.6.0"

	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}

provider "aws" {
	region = var.aws_region
}

data "aws_ami" "amazon_linux_2023" {
	most_recent = true
	owners      = ["amazon"]

	filter {
		name   = "name"
		values = ["al2023-ami-*-x86_64"]
	}

	filter {
		name   = "virtualization-type"
		values = ["hvm"]
	}
}

locals {
	tags = merge(
		{
			Project     = var.project_name
			Environment = var.environment
			ManagedBy   = "terraform"
		},
		var.tags
	)
}

module "network" {
	source = "../../modules/network"

	project            = var.project_name
	environment        = var.environment
	vpc_cidr           = var.vpc_cidr
	public_subnet_cidr = var.public_subnet_cidr
	public_subnet_az   = var.public_subnet_az
	private_subnets    = var.private_subnets
	tags               = local.tags
}

module "security" {
	source = "../../modules/security"

	project         = var.project_name
	environment     = var.environment
	vpc_id          = module.network.vpc_id
	allow_ssh       = var.allow_ssh
	ssh_cidr_blocks = var.ssh_cidr_blocks
	tags            = local.tags
}

module "ecr" {
	source = "../../modules/ecr"

	repository_names     = var.ecr_repository_names
	image_tag_mutability = var.ecr_image_tag_mutability
	tags                 = local.tags
}

module "iam" {
	source = "../../modules/iam"

	create_github_oidc_provider    = var.create_github_oidc_provider
	existing_github_oidc_provider_arn = var.existing_github_oidc_provider_arn
	github_oidc_url                = var.github_oidc_url
	github_oidc_client_ids         = var.github_oidc_client_ids
	github_oidc_thumbprints        = var.github_oidc_thumbprints

	infra_role_name         = var.infra_role_name
	infra_role_subject      = var.infra_role_subject
	infra_role_policy_arns  = var.infra_role_policy_arns

	frontend_role_name        = var.frontend_role_name
	frontend_role_subject     = var.frontend_role_subject
	frontend_role_policy_arns = var.frontend_role_policy_arns

	backend_role_name        = var.backend_role_name
	backend_role_subject     = var.backend_role_subject
	backend_role_policy_arns = var.backend_role_policy_arns

	ec2_role_name             = var.ec2_role_name
	ec2_instance_profile_name = var.ec2_instance_profile_name
	ec2_managed_policy_arns   = var.ec2_managed_policy_arns

	tags = local.tags
}

module "ec2" {
	source = "../../modules/ec2"

	project                   = var.project_name
	environment               = var.environment
	ami_id                    = var.ec2_ami_id != null ? var.ec2_ami_id : data.aws_ami.amazon_linux_2023.id
	instance_type             = var.ec2_instance_type
	subnet_id                 = module.network.public_subnet_id
	security_group_ids        = [module.security.ec2_security_group_id]
	iam_instance_profile_name = module.iam.ec2_instance_profile_name
	key_name                  = var.ec2_key_name
	root_volume_size          = var.ec2_root_volume_size
	tags                      = local.tags
}

module "rds" {
	source = "../../modules/rds"

	project              = var.project_name
	environment          = var.environment
	db_subnet_group_name = module.network.db_subnet_group_name
	rds_security_group_id = module.security.rds_security_group_id

	engine_version           = var.rds_engine_version
	instance_class           = var.rds_instance_class
	allocated_storage        = var.rds_allocated_storage
	max_allocated_storage    = var.rds_max_allocated_storage
	db_name                  = var.rds_db_name
	master_username          = var.rds_master_username
	master_password          = var.rds_master_password
	backup_retention_period  = var.rds_backup_retention_period
	backup_window            = var.rds_backup_window
	maintenance_window       = var.rds_maintenance_window
	skip_final_snapshot      = var.rds_skip_final_snapshot
	deletion_protection      = var.rds_deletion_protection

	tags = local.tags
}

module "monitoring" {
	source = "../../modules/monitoring"

	project            = var.project_name
	environment        = var.environment
	log_retention_days = var.log_retention_days
	tags               = local.tags
}

module "dns" {
	source = "../../modules/dns"

	create_record = var.create_dns_record
	zone_id       = var.route53_zone_id
	record_name   = var.route53_record_name
	record_value  = module.ec2.public_ip
}
