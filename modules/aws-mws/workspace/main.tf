variable "databricks_external_id" {
  type        = string
  description = "External ID you find on https://accounts.cloud.databricks.com/#aws"
}

variable "databricks_cloud_url" {
  default = "https://accounts.cloud.databricks.com/"
}

variable "databricks_cloud_username" {}
variable "databricks_cloud_password" {}
variable "prefix" {}
variable "aws_region" {}
variable "role_arn" {}
variable "root_bucket" {}
variable "vpc_id" {}
variable "public_subnet" {}
variable "private_subnet" {}
variable "security_group" {}
variable "name" {
  description = "Alphanumeric name of the workspace resource (https://NAME.cloud.databricks.com)"
}

provider "databricks" {
  alias = "accounts"
  host  = var.databricks_cloud_url
  basic_auth {
    username = var.databricks_cloud_username
    password = var.databricks_cloud_password
  }
}

resource "databricks_mws_credentials" "crossaccount" {
  provider         = databricks.accounts
  credentials_name = "${var.prefix}-credentials"
  account_id       = var.databricks_external_id
  role_arn         = var.role_arn
}

resource "databricks_mws_storage_configurations" "root_bucket" {
  provider                   = databricks.accounts
  account_id                 = var.databricks_external_id
  bucket_name                = var.root_bucket
  storage_configuration_name = "${var.prefix}-storage"
}

resource "databricks_mws_networks" "byo_vpc" {
  provider     = databricks.accounts
  account_id   = var.databricks_external_id
  network_name = "${var.prefix}-network"
  vpc_id       = var.vpc_id
  subnet_ids = [
    var.public_subnet,
    var.private_subnet
  ]
  security_group_ids = [
    var.security_group
  ]
}

resource "databricks_mws_workspaces" "my_mws_workspace" {
  provider                  = databricks.accounts
  account_id                = var.databricks_external_id
  workspace_name            = "${var.prefix}-${var.name}"
  deployment_name           = "${var.prefix}-${var.name}"
  aws_region                = var.aws_region
  credentials_id            = databricks_mws_credentials.crossaccount.credentials_id
  storage_configuration_id  = databricks_mws_storage_configurations.root_bucket.storage_configuration_id
  network_id                = databricks_mws_networks.byo_vpc.network_id
  verify_workspace_runnning = true
}

provider "databricks" {
  alias = "created_workspace"
  host  = databricks_mws_workspaces.my_mws_workspace.workspace_url
  basic_auth {
    username = var.databricks_cloud_username
    password = var.databricks_cloud_password
  }
}

resource "databricks_token" "pat" {
  provider = databricks.created_workspace
  comment  = "Terraform Provisioning"
  // 1 year of lifetime (due to refresh issues)
  lifetime_seconds = 31536000
}

output "workspace_url" {
  //value = ""
  value = databricks_mws_workspaces.my_mws_workspace.workspace_url
}

output "pat_token" {
  value = databricks_token.pat.token_value
}