module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  name                  = var.project_name
  cidr                  = var.cidr_block_private
  secondary_cidr_blocks = [var.cidr_block_public, var.vpce_subnet_cidr]
  azs                   = data.aws_availability_zones.available.names
  tags                  = var.tags

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  create_igw           = true

  public_subnets = [
    cidrsubnet(var.cidr_block_public, var.project_subnets_range_public, 0)
  ]
  private_subnets = [
    cidrsubnet(var.cidr_block_private, var.project_subnets_range_private, 1),
    cidrsubnet(var.cidr_block_private, var.project_subnets_range_private, 2)
  ]

  default_security_group_egress = [{
    cidr_blocks = "0.0.0.0/0"
  }]

  default_security_group_ingress = [{
    description = "Allow all internal TCP and UDP"
    self        = true
  }]
}

module "vpc_endpoints" {
  source             = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version            = "3.2.0"
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]
  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      tags = {
        Name = "${var.project_name}-s3-vpc-endpoint"
      }
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "${var.project_name}-sts-vpc-endpoint"
      }
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = {
        Name = "${var.project_name}-kinesis-vpc-endpoint"
      }
    },
  }
  tags       = var.tags
  depends_on = [module.vpc]
}
