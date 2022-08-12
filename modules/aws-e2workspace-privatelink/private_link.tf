resource "aws_subnet" "dataplane_vpce" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = var.vpce_subnet_cidr

  tags = merge(var.tags, {
    Name = "${local.prefix}-${module.vpc.vpc_id}-pl-vpce"
  })
  depends_on = [module.vpc]
}

resource "aws_route_table" "this" {
  vpc_id = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${local.prefix}-${module.vpc.vpc_id}-pl-local-route-tbl"
  })
  depends_on = [module.vpc]
}

resource "aws_route_table_association" "dataplane_vpce_rtb" {
  subnet_id      = aws_subnet.dataplane_vpce.id
  route_table_id = aws_route_table.this.id
}

######## Security group for data plane VPC endpoint backend/relay connections ########

locals {
  vpc_cidr_blocks = [
    cidrsubnet(var.cidr_block_private, var.project_subnets_range_private, 1),
    cidrsubnet(var.cidr_block_private, var.project_subnets_range_private, 2)
  ]
}

resource "aws_security_group" "dataplane_vpce" {
  name        = "Data Plane VPC endpoint security group"
  description = "Security group shared with relay and workspace endpoints"
  vpc_id      = module.vpc.vpc_id
  depends_on  = [module.vpc]
  ingress {
    description = "Inbound rules"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([var.vpce_subnet_cidr], local.vpc_cidr_blocks)
  }

  ingress {
    description = "Inbound rules"
    from_port   = 6666
    to_port     = 6666
    protocol    = "tcp"
    cidr_blocks = concat([var.vpce_subnet_cidr], local.vpc_cidr_blocks)
  }

  egress {
    description = "Outbound rules"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([var.vpce_subnet_cidr], local.vpc_cidr_blocks)
  }

  egress {
    description = "Outbound rules"
    from_port   = 6666
    to_port     = 6666
    protocol    = "tcp"
    cidr_blocks = concat([var.vpce_subnet_cidr], local.vpc_cidr_blocks)
  }

  tags = merge(var.tags, {
    Name = "${local.prefix}-${module.vpc.vpc_id}-pl-vpce-sg-rules"
  })
}