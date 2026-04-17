variable "create_record" {
  description = "Whether to create a Route53 A record for the app endpoint."
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
  default     = null
}

variable "record_name" {
  description = "Record name to create (FQDN or relative name based on zone usage)."
  type        = string
  default     = null
}

variable "record_value" {
  description = "A-record value, typically EC2 public IP."
  type        = string
  default     = null
}
