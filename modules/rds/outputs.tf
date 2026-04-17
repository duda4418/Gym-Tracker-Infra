output "db_instance_id" {
  description = "RDS instance ID."
  value       = aws_db_instance.this.id
}

output "endpoint" {
  description = "RDS endpoint hostname and port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}
