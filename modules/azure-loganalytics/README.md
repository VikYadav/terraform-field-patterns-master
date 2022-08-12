Creates Azure Log Analytics workspace and integrates it with Azure Databricks through init scripts

![arch](./images/arch.png)
This solution accelerator downloads latest spark streaming listeners and log analytics Log4j appender repository,
builds it with Maven, uploads the JARs to dbfs:/FileStore/jars/monitoring. Then it creates initi scripts, that
collect metrics from JVMs using those JARs, as well as LogAnalytics OMS agent to collect VM-level metrics, like
memory utilization and CPU load.

![preview](./images/preview.png)
To speed up some of the analysis, this module pre-creates couple of saved search queries for Log Analytics search
interface.

Blogs:
- https://cloudarchitected.com/2019/04/monitoring-azure-databricks/
- https://github.com/AdamPaternostro/Azure-Databricks-Log4J-To-AppInsights

Last tested on 2020-12-15

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [azurerm_log_analytics_saved_search.query](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_saved_search) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_diagnostic_setting.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [databricks_cluster.sample](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/cluster) | resource |
| [databricks_dbfs_file.init_scripts](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/dbfs_file) | resource |
| [databricks_dbfs_file.listeners](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/dbfs_file) | resource |
| [databricks_global_init_script.init2](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/global_init_script) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [databricks_node_type.smallest](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/node_type) | data source |
| [external_external.build_jars](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_categories"></a> [categories](#input_categories) | Databricks diagnostic log categories (all by default) | `list` | <pre>[<br>  "dbfs",<br>  "clusters",<br>  "accounts",<br>  "jobs",<br>  "notebook",<br>  "ssh",<br>  "workspace",<br>  "secrets",<br>  "sqlPermissions",<br>  "instancePools"<br>]</pre> |
| <a name="input_databricks_resource_id"></a> [databricks_resource_id](#input_databricks_resource_id) | The Azure resource ID for the databricks workspace deployment. | `any` | n/a |
| <a name="input_log4j"></a> [log4j](#input_log4j) | Ship Driver/Executor Log4j logs to LogAnalytics workspace | `bool` | `true` |
| <a name="input_retention"></a> [retention](#input_retention) | Days to keep diagnostics | `number` | `3` |
| <a name="input_spark_metrics"></a> [spark_metrics](#input_spark_metrics) | Ship Spark Dropwizzard metrics | `bool` | `true` |
| <a name="input_spark_metrics_period"></a> [spark_metrics_period](#input_spark_metrics_period) | Dropwizzard metric collection interval. Requires `spark_metrics = true` | `number` | `60` |
| <a name="input_vm_metrics"></a> [vm_metrics](#input_vm_metrics) | Ship Azure VM metrics, like CPU load and available memory | `bool` | `true` |

#### Outputs

No outputs.
