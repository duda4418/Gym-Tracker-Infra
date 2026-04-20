variable "project" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "allow_ssh" {
  description = "Whether to allow SSH to EC2 for emergency access."
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into EC2 if enabled."
  type        = list(string)
  default     = []
}

variable "allow_backend_port_8000" {
  description = "Temporarily allow direct public access to backend port 8000."
  type        = bool
  default     = false
}

variable "backend_port_8000_cidr_blocks" {
  description = "CIDR blocks allowed to access backend port 8000 when enabled."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
