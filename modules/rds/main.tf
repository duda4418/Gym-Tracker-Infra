resource "aws_db_instance" "this" {
  identifier             = "${var.project}-${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  db_name                = var.db_name
  username               = var.master_username
  password               = var.master_password
  port                   = 5432
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-postgres"
  })
}
