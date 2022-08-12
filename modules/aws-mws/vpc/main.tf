variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

variable "resource_prefix" {
  description = "Prefix for resources created for"
}

variable "region" {}

variable "cidr" {}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, 0)
  availability_zone = "${var.region}b"
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-public-sn"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, 1)
  availability_zone = "${var.region}a"
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-private-sn"
  })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-igw"
  })
}

resource "aws_route" "r" {
  route_table_id         = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [aws_internet_gateway.gw, aws_vpc.main]
}

resource "aws_security_group" "test_sg" {
  name        = "all all"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-allow-all-sg"
  })
}

output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet" {
  value = aws_subnet.public.id
}

output "private_subnet" {
  value = aws_subnet.private.id
}

output "aws_sg" {
  value = aws_security_group.test_sg.id
}