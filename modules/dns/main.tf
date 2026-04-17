resource "aws_route53_record" "app" {
  count = var.create_record ? 1 : 0

  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 300
  records = [var.record_value]
}
