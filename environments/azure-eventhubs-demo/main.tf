terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.2.9"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.30.0"
    }
  }
}

locals {
  epoch = "dltp4wz1ue"
  // joining for readability only
  worskpace_resource_id = join("/", [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}",
    "resourceGroups/${local.epoch}-rg",
    "providers/Microsoft.Databricks/workspaces/${local.epoch}-workspace"
  ])
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

provider "databricks" {
  azure_workspace_resource_id = local.worskpace_resource_id
}

module "eventhub" {
  source                 = "../../modules/azure-audit-eventhubs"
  databricks_resource_id = local.worskpace_resource_id
}