Creates Autoloader configuration for Azure with relevant notebooks, dummy data generator and secrets
https://docs.microsoft.com/en-us/azure/databricks/spark/latest/structured-streaming/auto-loader

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_attempt"></a> [attempt](#module_attempt) | ../azure-autoloader-queue | n/a |
| <a name="module_non_partitioned"></a> [non_partitioned](#module_non_partitioned) | ../azure-autoloader-queue | n/a |

#### Resources

| Name | Type |
|------|------|
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [databricks_azure_adls_gen2_mount.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/azure_adls_gen2_mount) | resource |
| [databricks_cluster.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/cluster) | resource |
| [databricks_job.trigger_once](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/job) | resource |
| [databricks_notebook.cloudfiles_init](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/notebook) | resource |
| [databricks_notebook.consume_non_partitioned](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/notebook) | resource |
| [databricks_notebook.consume_sample](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/notebook) | resource |
| [databricks_notebook.dummy-data](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/notebook) | resource |
| [databricks_notebook.trigger_once](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/notebook) | resource |
| [databricks_secret.connection_string](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/secret) | resource |
| [databricks_secret.sas](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/secret) | resource |
| [databricks_secret.spn_secret](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/secret) | resource |
| [databricks_secret_scope.autoloader](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/secret_scope) | resource |
| [local_file.make_dummy_data](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.make_dummy_data_non_partitioned](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [time_static.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/databricks_workspace) | data source |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account_sas.queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account_sas) | data source |
| [databricks_current_user.me](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/current_user) | data source |
| [databricks_node_type.smallest](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/node_type) | data source |
| [databricks_spark_version.latest](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/spark_version) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_databricks_resource_id"></a> [databricks_resource_id](#input_databricks_resource_id) | The Azure resource ID for the databricks workspace deployment. | `any` | n/a |
| <a name="input_folder"></a> [folder](#input_folder) | n/a | `string` | `"checkins_ten"` |
| <a name="input_service_principal_secret"></a> [service_principal_secret](#input_service_principal_secret) | Client Secret of Service Principal | `any` | n/a |

#### Outputs

No outputs.
