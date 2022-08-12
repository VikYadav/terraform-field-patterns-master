variable "prefix" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "crossaccount_role_name" {}
variable "databricks_workspace_host" {}
variable "databricks_workspace_token" {}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

provider "databricks" {
  host  = var.databricks_workspace_host
  token = var.databricks_workspace_token
}

module "marketing" {
  source                     = "../../aws-databricks-department"
  aws_zone                   = var.aws_zone
  crossaccount_role_name     = var.crossaccount_role_name
  databricks_workspace_host  = var.databricks_workspace_host
  databricks_workspace_token = var.databricks_workspace_token
  department                 = "Marketing"
  name                       = "marketing"
  prefix                     = var.prefix
  tags                       = var.tags
  force_destroy              = true
  versioning                 = false
  region                     = var.aws_region
}

module "ds" {
  source                     = "../../aws-databricks-department"
  aws_zone                   = var.aws_zone
  crossaccount_role_name     = var.crossaccount_role_name
  databricks_workspace_host  = var.databricks_workspace_host
  databricks_workspace_token = var.databricks_workspace_token
  department                 = "Data Science"
  name                       = "ds"
  prefix                     = var.prefix
  tags                       = var.tags
  force_destroy              = true
  versioning                 = false
  region                     = var.aws_region
}

output "exported_datasets" {
  value = {
    marketing = {
      reader_policy_arn = module.marketing.reader_policy_arn
      bucket = module.marketing.bucket
    }
    ds = {
      reader_policy_arn = module.ds.reader_policy_arn
      bucket = module.ds.bucket
    }
  }
}