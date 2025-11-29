##################################################
# EFS Security Group for Prometheus data storage #
##################################################

resource "aws_security_group" "efs" {
  name        = "${local.prefix}-efs"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-efs"
  }
}

#####################################################
# EFS File System for Prometheus data storage #
#####################################################

resource "aws_efs_file_system" "prometheus_data" {
  creation_token = "${local.prefix}-prometheus-data"

  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100

  tags = {
    Name = "${local.prefix}-prometheus-data"
  }
}

################################################
# EFS Access Point for Prometheus data storage #
################################################

resource "aws_efs_access_point" "prometheus_data" {
  file_system_id = aws_efs_file_system.prometheus_data.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/data"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }
}

#################################################
# EFS Mount Targets for Prometheus data storage #
#################################################

resource "aws_efs_mount_target" "prometheus_data_a" {
  file_system_id  = aws_efs_file_system.prometheus_data.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "prometheus_data_b" {
  file_system_id  = aws_efs_file_system.prometheus_data.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}

#################################################
# EFS File System for Prometheus config storage #
#################################################

resource "aws_efs_file_system" "prometheus_config" {
  creation_token = "${local.prefix}-prometheus-config"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "${local.prefix}-prometheus-config"
  }
}

##################################################
# EFS Access Point for Prometheus config storage #
##################################################

resource "aws_efs_access_point" "prometheus_config" {
  file_system_id = aws_efs_file_system.prometheus_config.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/config"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }
}

###################################################
# EFS Mount Targets for Prometheus config storage #
###################################################

resource "aws_efs_mount_target" "prometheus_config_a" {
  file_system_id  = aws_efs_file_system.prometheus_config.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "prometheus_config_b" {
  file_system_id  = aws_efs_file_system.prometheus_config.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}
