variable "project" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 is deployed."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to EC2."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name attached to EC2."
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name for emergency SSH."
  type        = string
  default     = null
}

variable "create_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP to the EC2 instance."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB."
  type        = number
  default     = 30
}

variable "certbot_email" {
  description = "Email address used for Let's Encrypt certificate registration and renewal notices."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

# Observability stack (optional — disabled by default)
variable "enable_observability" {
  description = "When true, installs and keeps the observability stack (Grafana, Prometheus, Loki, Tempo, Pyroscope, OTEL Collector, Alertmanager, Promtail) updated on this EC2 via bootstrap plus SSM."
  type        = bool
  default     = false
}

variable "obs_config_repo_url" {
  description = "HTTPS git URL of the repo containing observability config files. Required when enable_observability = true."
  type        = string
  default     = null
}

variable "obs_config_repo_branch" {
  description = "Branch to clone from obs_config_repo_url."
  type        = string
  default     = "master"
}

variable "obs_grafana_admin_password_ssm_param" {
  description = "SSM SecureString parameter name for the Grafana admin password. Required when enable_observability = true."
  type        = string
  default     = null
}

variable "obs_alertmanager_email_password_ssm_param" {
  description = "SSM SecureString parameter name for the Alertmanager SMTP password. Required when enable_observability = true."
  type        = string
  default     = null
}

variable "obs_alertmanager_smarthost" {
  description = "Alertmanager SMTP smarthost (host:port)."
  type        = string
  default     = "smtp.gmail.com:587"
}

variable "obs_alertmanager_email_from" {
  description = "Alertmanager sender email address."
  type        = string
  default     = null
}

variable "obs_alertmanager_email_to" {
  description = "Alertmanager alert recipient email address."
  type        = string
  default     = null
}

variable "obs_alertmanager_auth_username" {
  description = "Alertmanager SMTP auth username."
  type        = string
  default     = null
}
