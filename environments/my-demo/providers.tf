terraform {
  required_providers {
    azurerm = "~> 2.33"
    databricks = {
      source = "databricks/databricks"
      version = "1.2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "databricks" {
    host = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}