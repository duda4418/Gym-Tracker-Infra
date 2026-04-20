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

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
