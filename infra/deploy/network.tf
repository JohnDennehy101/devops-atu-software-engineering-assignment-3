##################
# VPC Definition #
##################

resource "aws_vpc" "primary" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

###############################
# Internet Gateway Definition #
###############################

resource "aws_internet_gateway" "primary" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "${local.prefix}-primary"
  }
}

#############################
# Public Subnets Definition #
#############################

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "${local.prefix}-public-a"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.primary.id
}


resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_region.current.name}b"

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "${local.prefix}-public-b"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route" "public_internet_access_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.primary.id
}

##############################
# Private Subnets Definition #
##############################

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${data.aws_region.current.name}a"
  tags = {
    Name = "${local.prefix}-private-a"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "${local.prefix}-private-a"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${data.aws_region.current.name}b"
  tags = {
    Name = "${local.prefix}-private-b"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.primary.id

  tags = {
    Name = "${local.prefix}-private-b"
  }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

############################
# VPC Endpoints Definition #
############################

resource "aws_security_group" "vpc_endpoint_access" {
  description = "Endpoints access"
  name        = "${local.prefix}-endpoints-access"
  vpc_id      = aws_vpc.primary.id

  ingress {
    cidr_blocks = [aws_vpc.primary.cidr_block]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [
    aws_security_group.vpc_endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ecr-end-point"
  }
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [
    aws_security_group.vpc_endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-dkr-end-point"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids = [
    aws_security_group.vpc_endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-cloudwatch-end-point"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.primary.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-s3-end-point"
  }
}
