/**
 * Azure Monitor setting to send audit logs over to storage account
 *
 * * In case you pick to create storage account, you'll get couple of containers created within it:
 * * `insights-logs-accounts`
 * * `insights-logs-clusters`
 * * `insights-logs-dbfs`
 * * `insights-logs-notebook`
 * * `insights-logs-ssh`
 * * `insights-logs-workspace`
 * * `insights-logs-secrets`
 * * `insights-logs-sqlPermissions`
 * * `insights-logs-instancePools`
 *
 * Each of those files will get per-minute JSON logs into
 * `/resourceId=$databricksWorkspaceId/y=$year/m=$month/d=$day/h=$hour/m=$minute`
 */
terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
    }
  }
}

variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/.+/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[0]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[1]
}

variable "categories" {
  default = ["dbfs", "clusters", "accounts", "jobs", "notebook",
  "ssh", "workspace", "secrets", "sqlPermissions", "instancePools"]
  description = "Databricks diagnostic log categories (all by default)"
}

variable "retention" {
  default     = 3
  description = "Days to keep diagnostics"
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name               = "Forward audit logs to ${azurerm_storage_account.this.name} storage account"
  target_resource_id = var.databricks_resource_id
  storage_account_id = azurerm_storage_account.this.id

  dynamic "log" {
    for_each = var.categories
    content {
      category = log.value
      retention_policy {
        enabled = true
        days    = var.retention
      }
    }
  }
}

resource "azurerm_storage_account" "this" {
  name                     = replace(data.azurerm_resource_group.this.name, "-rg", "diagnostics")
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  # As of writing this, diagnostic logs cannot be sent to a hns-enabled adls container.
  is_hns_enabled = "false"
}