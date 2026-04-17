variable "project" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet used by EC2."
  type        = string
}

variable "public_subnet_az" {
  description = "Availability zone for the public subnet."
  type        = string
}

variable "private_subnets" {
  description = "Private subnet definitions used by RDS."
  type = list(object({
    cidr = string
    az   = string
  }))

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least two private subnets are required for RDS subnet groups."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
