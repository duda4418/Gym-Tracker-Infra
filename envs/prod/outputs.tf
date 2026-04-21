output "vpc_id" {
	description = "VPC ID."
	value       = module.network.vpc_id
}

output "ec2_instance_id" {
	description = "EC2 instance ID."
	value       = module.ec2.instance_id
}

output "ec2_public_ip" {
	description = "EC2 public IP address."
	value       = module.ec2.public_ip
}

output "ec2_elastic_ip" {
	description = "Elastic IP address attached to EC2 when enabled."
	value       = module.ec2.elastic_ip
}

output "rds_endpoint" {
	description = "RDS endpoint."
	value       = module.rds.endpoint
}

output "ecr_repository_urls" {
	description = "Repository URLs for frontend and backend images."
	value       = module.ecr.repository_urls
}


output "infra_role_arn" {
	description = "IAM role ARN for infra GitHub workflow."
	value       = module.iam.infra_role_arn
}

output "frontend_role_arn" {
	description = "IAM role ARN for frontend deployment workflow."
	value       = module.iam.frontend_role_arn
}

output "backend_role_arn" {
	description = "IAM role ARN for backend deployment workflow."
	value       = module.iam.backend_role_arn
}

output "ec2_instance_profile_name" {
	description = "EC2 instance profile name."
	value       = module.iam.ec2_instance_profile_name
}

output "dns_record_fqdn" {
	description = "Route53 record FQDN if enabled."
	value       = module.dns.record_fqdn
}
