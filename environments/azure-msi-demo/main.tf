terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.3.6"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.30.0"
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

module "this" {
  source = "../../modules/azure-msi-sandbox"
  databricks_resource_id = local.worskpace_resource_id
}

output "user_assigned_identity" {
  value = module.this.ssh_command_for_user_assigned
}

output "system_assigned_identity" {
  value = module.this.ssh_command_for_system_assigned
}