output "app_log_group_name" {
  description = "CloudWatch log group for app workloads."
  value       = aws_cloudwatch_log_group.app.name
}
