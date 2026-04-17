output "record_fqdn" {
  description = "Created DNS record FQDN when enabled."
  value       = try(aws_route53_record.app[0].fqdn, null)
}
