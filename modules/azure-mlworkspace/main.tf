/**
 * AzureML workspace connected to Azure Databricks workspace
 *
 * Module creates:
 * * Application Insights
 * * Blob Storage
 * * Key Vault
 * * ML Workspace
 */
variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/.+/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[0]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[1]
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

resource "azurerm_application_insights" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "insights")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  application_type    = "other"
  tags                = data.azurerm_resource_group.this.tags
}

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "akv")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_storage_account" "this" {
  name                    = replace(data.azurerm_resource_group.this.name, "-rg", "azml")
  resource_group_name     = data.azurerm_resource_group.this.name
  location                = data.azurerm_resource_group.this.location
  tags                    = data.azurerm_resource_group.this.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_container" "blobexample" {
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
  name                  = "dev"
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}

resource "azurerm_machine_learning_workspace" "this" {
  name                    = replace(data.azurerm_resource_group.this.name, "rg", "azml")
  resource_group_name     = data.azurerm_resource_group.this.name
  location                = data.azurerm_resource_group.this.location
  tags                    = data.azurerm_resource_group.this.tags
  application_insights_id = azurerm_application_insights.this.id
  key_vault_id            = azurerm_key_vault.this.id
  storage_account_id      = azurerm_storage_account.this.id
  identity {
    type = "SystemAssigned"
  }
}