/**
 * Creates Azure Container Registry, sample Docker image and Databricks cluster with it
 * VNet module should be started with `private_subnet_endpoints = ["Microsoft.ContainerRegistry"]`
 */
variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/.+/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[0]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[1]
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

data "azurerm_subnet" "this" {
  virtual_network_name = replace(data.azurerm_resource_group.this.name, "rg", "vnet")
  name = replace(data.azurerm_resource_group.this.name, "rg", "private")
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_container_registry" "this" {
  name = replace(data.azurerm_resource_group.this.name, "-rg", "acr")
  resource_group_name = data.azurerm_resource_group.this.name
  location = data.azurerm_resource_group.this.location
  tags = data.azurerm_resource_group.this.tags
  admin_enabled = true
  sku = "Premium"

  network_rule_set {
    virtual_network {
      action = "Allow"
      subnet_id = data.azurerm_subnet.this.id
    }
  }
}

