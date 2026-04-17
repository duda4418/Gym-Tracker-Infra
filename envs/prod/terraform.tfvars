aws_region = "eu-central-1"

project_name = "gym-tracker"
environment  = "prod"

vpc_cidr           = "10.20.0.0/16"
public_subnet_cidr = "10.20.1.0/24"
public_subnet_az   = "eu-central-1a"

private_subnets = [
	{
		cidr = "10.20.11.0/24"
		az   = "eu-central-1a"
	},
	{
		cidr = "10.20.12.0/24"
		az   = "eu-central-1b"
	}
]

allow_ssh       = false
ssh_cidr_blocks = []

ec2_instance_type    = "t3.small"
ec2_root_volume_size = 40
ec2_key_name         = null

rds_db_name         = "gymtracker"
rds_master_username = "gymadmin"
rds_master_password = "CHANGE_ME"

infra_role_name    = "gym-tracker-infra-gha-role"
infra_role_subject = "repo:your-org/gym-tracker-infra:ref:refs/heads/main"

frontend_role_name    = "gym-tracker-frontend-gha-role"
frontend_role_subject = "repo:your-org/gym-tracker-frontend:ref:refs/heads/main"
frontend_role_policy_arns = [
	"arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
	"arn:aws:iam::aws:policy/AmazonSSMFullAccess"
]

backend_role_name    = "gym-tracker-backend-gha-role"
backend_role_subject = "repo:your-org/gym-tracker-backend:ref:refs/heads/main"
backend_role_policy_arns = [
	"arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
	"arn:aws:iam::aws:policy/AmazonSSMFullAccess"
]

ec2_role_name             = "gym-tracker-ec2-role"
ec2_instance_profile_name = "gym-tracker-ec2-instance-profile"

create_github_oidc_provider     = false
existing_github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"

create_dns_record  = false
route53_zone_id    = null
route53_record_name = null

tags = {
	Owner       = "you"
	Application = "gym-tracker"
}
