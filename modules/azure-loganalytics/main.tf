/**
 * Creates Azure Log Analytics workspace and integrates it with Azure Databricks through init scripts
 *
 * ![arch](./images/arch.png)
 * This solution accelerator downloads latest spark streaming listeners and log analytics Log4j appender repository,
 * builds it with Maven, uploads the JARs to dbfs:/FileStore/jars/monitoring. Then it creates initi scripts, that
 * collect metrics from JVMs using those JARs, as well as LogAnalytics OMS agent to collect VM-level metrics, like
 * memory utilization and CPU load.
 *
 * ![preview](./images/preview.png)
 * To speed up some of the analysis, this module pre-creates couple of saved search queries for Log Analytics search
 * interface.
 *
 * Blogs:
 * - https://cloudarchitected.com/2019/04/monitoring-azure-databricks/
 * - https://github.com/AdamPaternostro/Azure-Databricks-Log4J-To-AppInsights
 *
 * Last tested on 2020-12-15
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

variable "log4j" {
  description = "Ship Driver/Executor Log4j logs to LogAnalytics workspace"
  default     = true
}

variable "spark_metrics" {
  description = "Ship Spark Dropwizzard metrics"
  default     = true
}

variable "spark_metrics_period" {
  description = "Dropwizzard metric collection interval. Requires `spark_metrics = true`"
  default     = 60
}

variable "vm_metrics" {
  description = "Ship Azure VM metrics, like CPU load and available memory"
  default     = true
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

resource "azurerm_log_analytics_workspace" "this" {
  name                = replace(data.azurerm_resource_group.this.name, "rg", "loganalytics")
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  sku                 = "PerGB2018"

  tags = merge(data.azurerm_resource_group.this.tags, {
    Service = "log-analytics"
  })
}

// TODO: add a bit more saved searches - https://github.com/mspnp/spark-monitoring/blob/master/perftools/deployment/loganalytics/logAnalyticsDeploy.json#L46
resource "azurerm_log_analytics_saved_search" "query" {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  category     = "Databricks"
  for_each     = fileset(path.module, "queries/*.kusto")
  name         = basename(each.value)
  display_name = replace(replace(basename(each.value), ".kusto", ""), "_", " ")
  query        = file("${path.module}/${each.value}")
}

resource "azurerm_monitor_diagnostic_setting" "log_analytics" {
  name                       = "Forward audit logs to ${azurerm_log_analytics_workspace.this.name}"
  target_resource_id         = var.databricks_resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

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

# Depending on the version of Spark/DBR you are using, the below needs to be adjusted to compensate
# Ex. "...spark-listeners_2.4.5_2.11..." vs "...spark-listeners_3.0.0_2.12..."
data "external" "build_jars" {
  program = ["${path.module}/build-jars.sh", "scala-2.12_spark-3.0.1"]
}

resource "databricks_dbfs_file" "listeners" {
  for_each = data.external.build_jars.result
  source   = each.value
  path     = "/FileStore/jars/monitoring/${each.key}"
}

locals {
  init_scripts = compact([
    // application logs and Spark Event Logs
    var.log4j ? "loganalytics-log4j.sh" : "",
    // streaming / task metrics
    var.spark_metrics ? "loganalytics-dropwizzard.sh" : "",
    // OMS is an agent that is run within each VM that
    // monitors utilization metrics such as % RAM and network IO etc.
    var.vm_metrics ? "oms-agent.sh" : "",
  ])
  init_template = {
    LOG_ANALYTICS_WORKSPACE_ID  = azurerm_log_analytics_workspace.this.workspace_id,
    LOG_ANALYTICS_WORKSPACE_KEY = azurerm_log_analytics_workspace.this.primary_shared_key,
    AZ_RSRC_GRP_NAME            = data.azurerm_resource_group.this.name,
    AZ_RSRC_NAME                = local.databricks_workspace_name
    SPARK_METRICS_PERIOD        = var.spark_metrics_period
  }
}

resource "databricks_dbfs_file" "init_scripts" {
  for_each = toset(local.init_scripts)
  content_base64 = base64encode(templatefile(
  "${path.module}/init-scripts/${each.value}", local.init_template))
  path = "/databricks/init-scripts/${each.value}"
}

resource "databricks_global_init_script" "init2" {
  for_each = toset(local.init_scripts)
  content_base64 = base64encode(templatefile(
  "${path.module}/init-scripts/${each.value}", local.init_template))
  name = each.value
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

resource "databricks_cluster" "sample" {
  cluster_name            = "Log Forwarding Sample"
  spark_version           = "7.4.x-scala2.12"
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  num_workers             = 1

  dynamic "init_scripts" {
    for_each = databricks_dbfs_file.init_scripts
    content {
      dbfs {
        destination = init_scripts.value.path
      }
    }
  }
}