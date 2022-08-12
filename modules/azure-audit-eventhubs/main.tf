/**
 * Azure EventHubs for structured streaming
 *
 * ![preview](./arch.png)
 *
 * This module creates:
 * * Diagnostic setting to forward into Event Hub (EH)
 * * EH Namespace with single Event Hub
 * * Databricks Secret Scope
 * * Databricks Cluster with corresponding JAR installed
 * * Secret with EH Namespace connection string composed out of `...`
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

resource "azurerm_monitor_diagnostic_setting" "eventhub" {
  name               = "Send to ${azurerm_eventhub.this.name} event hub"
  target_resource_id = var.databricks_resource_id
  eventhub_name      = azurerm_eventhub.this.name
  //eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.manage.id
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.root.id

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

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

// @link https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_namespace
resource "azurerm_eventhub_namespace" "this" {
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  name                = replace(data.azurerm_resource_group.this.name, "rg", "ehn")
  sku                 = "Standard" // or Basic - would rather calculate it dynamically here
  tags                = data.azurerm_resource_group.this.tags
}

// @link https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub
resource "azurerm_eventhub" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "hub")
  resource_group_name = data.azurerm_resource_group.this.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  message_retention   = 1
  partition_count     = 2
}

resource "azurerm_eventhub_namespace_authorization_rule" "manage" {
  name                = "send-audit"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = data.azurerm_resource_group.this.name
  manage              = true
  listen              = true
  send                = true
}

data "azurerm_eventhub_namespace_authorization_rule" "root" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "databricks_secret_scope" "this" {
  name = "eventhub"
}

resource "azurerm_eventhub_authorization_rule" "listen" {
  name                = "listen-in-databricks"
  eventhub_name       = azurerm_eventhub.this.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = data.azurerm_resource_group.this.name
  listen              = true
}

resource "databricks_secret" "this" {
  key   = "connection-string"
  scope = databricks_secret_scope.this.name
  // Endpoint=sb://.../;SharedAccessKeyName=listen-in-databricks;SharedAccessKey=...;EntityPath=...
  string_value = azurerm_eventhub_authorization_rule.listen.primary_connection_string
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

resource "databricks_cluster" "this" {
  cluster_name            = "Azure EventHub Streaming"
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  spark_version           = "7.4.x-scala2.12"
  num_workers             = 2

  library {
    maven {
      coordinates = "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18"
    }
  }
}

resource "databricks_notebook" "process_in_scala" {
  source = "${path.module}/ProcessInScala.scala"
  path   = "/AuditLogs/ProcessEventsInScala"
}