output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Effective public IP address (Elastic IP if enabled, otherwise instance public IP)."
  value       = coalesce(try(aws_eip.this[0].public_ip, null), aws_instance.this.public_ip)
}

output "elastic_ip" {
  description = "Elastic IP address associated to the EC2 instance if enabled."
  value       = try(aws_eip.this[0].public_ip, null)
}

output "private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = aws_instance.this.private_ip
}
