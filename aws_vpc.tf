
####################################################
# VPC
####################################################
resource "aws_vpc" "this" {
  cidr_block  = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags        = {Name = "vpc"}
}


####################################################
# VPC endpoint for ECR
####################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private_1a.id
}

resource "aws_security_group" "vpc_endpoint" {
  name   = "vpc_endpoint_sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id
  ]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

####################################################
# internet gateway
####################################################
resource "aws_internet_gateway" "igw" {
  vpc_id  = aws_vpc.this.id
  tags    = {Name = "internat_gateway"}
}

####################################################
# public subnet
####################################################
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_1c"
  }
}


####################################################
# private subnet
####################################################
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "private_1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "private_1c"
  }
}


####################################################
# Elastic IP for NAT
####################################################
resource "aws_eip" "nat_1a" {
  vpc   = true
  tags  = {
    Name = "nat_1a"
  }
}


####################################################
# NAT gateway
####################################################
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id
  tags = {
    Name = "natgw_1a"
  }
}


####################################################
# public subnet route table
####################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}


####################################################
# private subnet route table
####################################################
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_1a.id
  }
  tags = {
    Name = "private_1a"
  }
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}