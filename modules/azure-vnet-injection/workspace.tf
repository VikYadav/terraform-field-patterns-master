variable "no_public_ip" {
  default = false
}

resource "azurerm_databricks_workspace" "this" {
  sku                         = "premium"
  name                        = "${local.prefix}-workspace"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location

  custom_parameters {
    no_public_ip        = var.no_public_ip
    virtual_network_id  = azurerm_virtual_network.this.id
    public_subnet_name  = azurerm_subnet.public.name
    private_subnet_name = azurerm_subnet.private.name
  }

  tags = local.tags

  # We need this, otherwise destroy doesn't cleanup things correctly
  depends_on = [
    azurerm_subnet_network_security_group_association.public,
    azurerm_subnet_network_security_group_association.private
  ]
}

output "databricks_azure_workspace_resource_id" {
  // The ID of the Databricks Workspace in the Azure management plane.
  value = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  // The workspace URL which is of the format 'adb-{workspaceId}.{random}.azuredatabricks.net'
  // this is not named as DATABRICKS_HOST, because it affect authentication
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}
