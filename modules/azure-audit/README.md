Azure Monitor setting to send audit logs over to storage account

* In case you pick to create storage account, you'll get couple of containers created within it:
* `insights-logs-accounts`
* `insights-logs-clusters`
* `insights-logs-dbfs`
* `insights-logs-notebook`
* `insights-logs-ssh`
* `insights-logs-workspace`
* `insights-logs-secrets`
* `insights-logs-sqlPermissions`
* `insights-logs-instancePools`

Each of those files will get per-minute JSON logs into
`/resourceId=$databricksWorkspaceId/y=$year/m=$month/d=$day/h=$hour/m=$minute`

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [azurerm_monitor_diagnostic_setting.storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_categories"></a> [categories](#input_categories) | Databricks diagnostic log categories (all by default) | `list` | <pre>[<br>  "dbfs",<br>  "clusters",<br>  "accounts",<br>  "jobs",<br>  "notebook",<br>  "ssh",<br>  "workspace",<br>  "secrets",<br>  "sqlPermissions",<br>  "instancePools"<br>]</pre> |
| <a name="input_databricks_resource_id"></a> [databricks_resource_id](#input_databricks_resource_id) | The Azure resource ID for the databricks workspace deployment. | `any` | n/a |
| <a name="input_retention"></a> [retention](#input_retention) | Days to keep diagnostics | `number` | `3` |

#### Outputs

No outputs.
