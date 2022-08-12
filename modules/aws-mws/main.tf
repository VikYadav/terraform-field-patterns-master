/**
 * E2 pattern with two VPCs and two workspaces with fully-featured security measures
 * 
 * This reference architecture can be described as the following diagram:
 * ![architecture](./architecture.png)
 */

variable "prefix" {}
variable "name" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "databricks_cloud_username" {}
variable "databricks_cloud_password" {}
variable "cidr" { default = "10.1.0.0/16" }

variable "databricks_external_id" {
  type        = string
  description = "External ID you find on https://accounts.cloud.databricks.com/#aws"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

provider "aws" {
  region = var.aws_region
}

module "crossaccount" {
  source      = "../aws-databricks-crossaccount"
  prefix      = var.prefix
  tags        = var.tags
  external_id = var.databricks_external_id
}

module "root_bucket" {
  source        = "../aws-databricks-bucket"
  name          = "${var.prefix}-databricks-root"
  region        = var.aws_region
  force_destroy = true
  versioning    = false
  tags          = var.tags
}

module "vpc" {
  source          = "./vpc"
  region          = var.aws_region
  resource_prefix = var.prefix
  tags            = var.tags
  cidr            = cidrsubnet(var.cidr, 2, 0)
}

module "workspace" {
  source                    = "./workspace"
  name                      = "${var.name}-primary"
  prefix                    = var.prefix
  aws_region                = var.aws_region
  databricks_external_id    = var.databricks_external_id
  databricks_cloud_username = var.databricks_cloud_username
  databricks_cloud_password = var.databricks_cloud_password
  role_arn                  = module.crossaccount.role_arn
  root_bucket               = module.root_bucket.bucket
  private_subnet            = module.vpc.private_subnet
  public_subnet             = module.vpc.public_subnet
  security_group            = module.vpc.aws_sg
  vpc_id                    = module.vpc.aws_vpc_id
}

module "vpc_reader" {
  source          = "./vpc"
  region          = var.aws_region
  resource_prefix = var.prefix
  tags            = var.tags
  cidr            = cidrsubnet(var.cidr, 2, 1)
}

module "reader_workspace" {
  source                    = "./workspace"
  name                      = "${var.name}-reader"
  prefix                    = var.prefix
  aws_region                = var.aws_region
  databricks_external_id    = var.databricks_external_id
  databricks_cloud_username = var.databricks_cloud_username
  databricks_cloud_password = var.databricks_cloud_password
  role_arn                  = module.crossaccount.role_arn
  root_bucket               = module.root_bucket.bucket
  private_subnet            = module.vpc_reader.private_subnet
  public_subnet             = module.vpc_reader.public_subnet
  security_group            = module.vpc_reader.aws_sg
  vpc_id                    = module.vpc_reader.aws_vpc_id
}

module "data_creators" {
  source                     = "./creators"
  crossaccount_role_name     = module.crossaccount.role_name
  databricks_workspace_host  = module.workspace.workspace_url
  databricks_workspace_token = module.workspace.pat_token
  aws_region                 = var.aws_region
  aws_zone                   = var.aws_zone
  prefix                     = var.prefix
  tags                       = var.tags
}

module "data_consumers" {
  source = "./consumers"
  consumed_datasets          = module.data_creators.exported_datasets
  crossaccount_role_name     = module.crossaccount.role_name
  databricks_workspace_host  = module.reader_workspace.workspace_url
  databricks_workspace_token = module.reader_workspace.pat_token
  aws_region                 = var.aws_region
  aws_zone                   = var.aws_zone
  prefix                     = var.prefix
  tags                       = var.tags
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

output "reader_workspace_url" {
  value = module.reader_workspace.workspace_url
}