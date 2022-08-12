terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.3.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.30.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "workspace" {
  source = "../../modules/azure-vnet-injection"
  cidr   = "10.31.0.0/16"
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

# Configure the Databricks and Azure providers.
# Note that most configuration is implicitly inherited from env vars set in run.sh

provider "databricks" {
  azure_workspace_resource_id = module.workspace.databricks_azure_workspace_resource_id
}

module "logs" {
  source                 = "../../modules/azure-loganalytics"
  databricks_resource_id = module.workspace.databricks_azure_workspace_resource_id

  retention            = 1
  spark_metrics        = true
  log4j                = true
  vm_metrics           = true
  spark_metrics_period = 60

  providers = {
    databricks = databricks
  }
}

module "audit" {
  source                 = "../../modules/azure-audit"
  databricks_resource_id = module.workspace.databricks_azure_workspace_resource_id
  categories             = ["accounts", "clusters", "dbfs"]

  providers = {
    databricks = databricks
  }
}

module "eventhub" {
  source                 = "../../modules/azure-audit-eventhubs"
  databricks_resource_id = module.workspace.databricks_azure_workspace_resource_id

  providers = {
    databricks = databricks
  }
}