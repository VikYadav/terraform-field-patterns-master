provider "random" {
  version = "~> 2.2"
}

// get any env var to tf
data "external" "env" {
  program = ["python", "-c", "import sys,os,json;json.dump(dict(os.environ), sys.stdout)"]
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  // dltp - databricks labs terraform provider
  prefix = "dltp${random_string.naming.result}"
  cidr = "10.3.0.0/16"

  region = data.external.env.result.AWS_DEFAULT_REGION
  account_id = data.external.env.result.DATABRICKS_ACCOUNT_ID

  tags = {
    Environment = "Testing"
    Owner       = data.external.env.result.OWNER
    Epoch       = random_string.naming.result
  }
}

provider "aws" {
  region = local.region
  version = "2.70.0"
}

// initialize provider in "MWS" mode to provision new workspace
provider "databricks" {
  alias = "mws"
  host  = "https://accounts.cloud.databricks.com"
}

// create cross-account role
module "crossaccount" {
  source      = "../../modules/aws-databricks-crossaccount"
  prefix      = local.prefix
  tags        = local.tags
  external_id = local.account_id
}

// register cross-account ARN
resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  account_id       = local.account_id
  credentials_name = "${local.prefix}-creds"
  role_arn         = module.crossaccount.role_arn
}

// create root bucket
module "root_bucket" {
  source        = "../../modules/aws-databricks-bucket"
  name          = "${local.prefix}-databricks-root"
  region        = local.region
  force_destroy = true
  versioning    = false
  tags          = local.tags
}

// register root bucket
resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.mws
  account_id                 = local.account_id
  storage_configuration_name = "${local.prefix}-storage"
  bucket_name                = module.root_bucket.bucket
}

// create VPC
module "vpc" {
  source          = "../../modules/aws-mws/vpc"
  region          = local.region
  resource_prefix = local.prefix
  tags            = local.tags
  cidr            = cidrsubnet(local.cidr, 2, 0)
}

// register VPC
resource "databricks_mws_networks" "this" {
  provider     = databricks.mws
  account_id   = local.account_id
  network_name = "${local.prefix}-network"
  vpc_id       = module.vpc.aws_vpc_id
  subnet_ids = [module.vpc.public_subnet, module.vpc.private_subnet]
  security_group_ids = [module.vpc.aws_sg]
}

// create workspace in given VPC with DBFS on root bucket
resource "databricks_mws_workspaces" "this" {
  provider        = databricks.mws
  account_id      = local.account_id
  workspace_name  = local.prefix
  deployment_name = local.prefix
  aws_region      = local.region

  credentials_id            = databricks_mws_credentials.this.credentials_id
  storage_configuration_id  = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                = databricks_mws_networks.this.network_id
  verify_workspace_runnning = true
}

// initialize provider in normal mode
provider "databricks" {
  // in normal scenario you won't have to give providers aliases
  alias = "created_workspace" 
  
  host = databricks_mws_workspaces.this.workspace_url
}

// create PAT token to provision entities within workspace
resource "databricks_token" "pat" {
  provider = databricks.created_workspace
  comment  = "Terraform Provisioning"
  // 1 day token
  lifetime_seconds = 86400
}

// create bucket for mounting
resource "aws_s3_bucket" "this" {
  bucket = "${local.prefix}-test"
  acl    = "private"
  versioning {
    enabled = false
  }
  force_destroy = true
  tags = merge(local.tags, {
    Name = "${local.prefix}-test"
  })
}

// block all public access to created bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket              = aws_s3_bucket.this.id
  ignore_public_acls  = true
}

// export bucket name to test mounting
output "test_bucket" {
  value = aws_s3_bucket.this.bucket
}

// export host for integration tests to run on
output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

// export token for integraiton tests to run on
output "databricks_token" {
  value     = databricks_token.pat.token_value
  sensitive = true
}