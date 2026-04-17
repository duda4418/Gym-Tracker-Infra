variable "project" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "db_subnet_group_name" {
  description = "DB subnet group name for RDS instance."
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID allowing DB access from EC2."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "master_username" {
  description = "Master username for PostgreSQL."
  type        = string
}

variable "master_password" {
  description = "Master password for PostgreSQL."
  type        = string
  sensitive   = true
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily backup window in UTC."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy for non-production experimentation."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection for the database instance."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
