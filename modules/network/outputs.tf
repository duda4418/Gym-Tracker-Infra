output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "Public subnet ID for EC2."
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for data tier resources."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "db_subnet_group_name" {
  description = "Database subnet group name for RDS."
  value       = aws_db_subnet_group.this.name
}
