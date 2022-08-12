variable "tags" {}
variable "prefix" {}
variable "aws_region" {}
variable "aws_zone" {}
variable "databricks_external_id" {}
variable "databricks_cloud_username" {}
variable "databricks_cloud_password" {}

/**
 * Code layout based on patterns described in:
 * 
 * @link https://www.terraform-best-practices.com/examples/terraform/large-size-infrastructure-with-terraform
 */
module "multiworkspace_demo" {
  source                    = "../../modules/aws-mws"
  databricks_external_id    = var.databricks_external_id
  databricks_cloud_username = var.databricks_cloud_username
  databricks_cloud_password = var.databricks_cloud_password
  aws_region                = var.aws_region
  aws_zone                  = var.aws_zone
  prefix                    = "sergemws2"
  name                      = "techsummit09"
  cidr                      = "10.3.0.0/16"
  tags                      = var.tags
}

output "workspace_url" {
  value = module.multiworkspace_demo.workspace_url
}

output "reader_workspace_url" {
  value = module.multiworkspace_demo.reader_workspace_url
}

