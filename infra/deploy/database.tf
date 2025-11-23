#######################################
# Initialise DB Subnet Security Group #
#######################################

resource "aws_db_subnet_group" "primary" {
  name = "${local.prefix}-primary"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

#################################
# Initialise AWS Security Group #
#################################

resource "aws_security_group" "rds" {
  description = "Enable access to RDS instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id      = aws_vpc.primary.id

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [aws_security_group.ecs_service.id]
  }

  tags = {
    Name = "${local.prefix}-db-security-group"
  }

}

###########################
# Initialise RDS Instance #
###########################

resource "aws_db_instance" "primary" {
  identifier                 = "${local.prefix}-db"
  db_name                    = "notes"
  allocated_storage          = 20
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "15"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.database_username
  password                   = var.database_password
  # TODO: Update to False when final version 
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.primary.name
  # TODO: Update to True when final version 
  multi_az = false
  # TODO: Update when final version 
  backup_retention_period = 0
  vpc_security_group_ids  = [aws_security_group.rds.id]
  tags = {
    Name = "${local.prefix}-primary"
  }
}
