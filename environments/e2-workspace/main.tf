terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.3.0"
    }
  }
}

/*
export TF_VAR_databricks_account_id=$DATABRICKS_ACCOUNT_ID
export TF_VAR_databricks_account_password=$DATABRICKS_PASSWORD
export TF_VAR_databricks_account_username=$DATABRICKS_USERNAME
*/

variable "databricks_account_id" {}
variable "databricks_account_password" {}
variable "databricks_account_username" {}

module "this" {
  source                      = "../../modules/aws-e2workspace"
  databricks_account_id       = var.databricks_account_id
  databricks_account_password = var.databricks_account_password
  databricks_account_username = var.databricks_account_username

  region = "eu-central-1"

  tags = {
    Owner = "serge.smertin@databricks.com"
  }
}

output "databricks_host" {
  value = module.this.databricks_host
}