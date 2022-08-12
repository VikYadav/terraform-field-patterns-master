/**
 * E2 pattern with AWS Private Link
 * 
 * This reference architecture can be described as the following diagram:
 * ![architecture](./aws-e2-private-link-backend.png)
 */
 terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
    }
  }
}

provider "aws" {
  region = var.region
}

// initialize provider in "MWS" mode to provision new workspace
provider "databricks" {
  alias    = "mws"
  host     = "https://accounts.cloud.databricks.com"
  username = var.databricks_account_username
  password = var.databricks_account_password
}

