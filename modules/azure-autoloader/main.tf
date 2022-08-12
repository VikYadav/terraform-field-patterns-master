/**
 * Creates Autoloader configuration for Azure with relevant notebooks, dummy data generator and secrets
 * https://docs.microsoft.com/en-us/azure/databricks/spark/latest/structured-streaming/auto-loader
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

resource "databricks_secret_scope" "autoloader" {
  name = "autoloader"
}

data "azurerm_client_config" "this" {}

variable "service_principal_secret" {
  description = "Client Secret of Service Principal"
}

resource "databricks_secret" "spn_secret" {
  key = "spn-secret"
  string_value = var.service_principal_secret
  scope = databricks_secret_scope.autoloader.id
}

resource "databricks_secret" "connection_string" {
  key = "connection_string"
  string_value = azurerm_storage_account.this.primary_connection_string
  scope = databricks_secret_scope.autoloader.id
}

data "databricks_current_user" "me" {}

resource "azurerm_storage_account" "this" {
  name = replace(data.azurerm_resource_group.this.name, "-rg", "autoloader")
  resource_group_name = data.azurerm_resource_group.this.name
  location = data.azurerm_resource_group.this.location
  tags = data.azurerm_resource_group.this.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_container" "this" {
  name                  = "autoloader"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "time_static" "this" {}

data "azurerm_storage_account_sas" "queue" {
  connection_string = azurerm_storage_account.this.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = true
    table = false
    file  = false
  }

  start  = formatdate("YYYY-MM-DD", time_static.this.id)
  expiry  = "2021-12-31" // demo purposes only

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
  }
}

resource "databricks_secret" "sas" {
  key = "queue-sas"
  string_value = data.azurerm_storage_account_sas.queue.sas
  scope = databricks_secret_scope.autoloader.id
}

resource "databricks_azure_adls_gen2_mount" "this" {
  container_name         = azurerm_storage_container.this.name
  storage_account_name   = azurerm_storage_account.this.name
  mount_name             = azurerm_storage_container.this.name
  tenant_id              = data.azurerm_client_config.this.tenant_id
  client_id              = data.azurerm_client_config.this.client_id
  client_secret_scope    = databricks_secret_scope.autoloader.name
  client_secret_key      = databricks_secret.spn_secret.key
  cluster_id             = databricks_cluster.this.id
  initialize_file_system = true
}

variable "folder" {
  default = "checkins_ten"
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest" {
  latest = true
}

resource "databricks_cluster" "this" {
  cluster_name            = "Autoloader experiments"
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 60

  autoscale {
    min_workers = 1
    max_workers = 10
  }

  library {
    pypi {
      package = "Faker==6.1.1"
    }
  }

  spark_conf = {
    "experiment.resource_group" = data.azurerm_resource_group.this.name,
    "experiment.subscription_id" = data.azurerm_client_config.this.subscription_id,
    "experiment.tenant_id" = data.azurerm_client_config.this.tenant_id,
    "experiment.client_id" = data.azurerm_client_config.this.client_id,
    "experiment.primary_dfs_endpoint" = azurerm_storage_account.this.primary_dfs_endpoint
  }
}