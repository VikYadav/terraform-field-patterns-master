Creates Azure Databricks Autoloader for ADLSv2
Relies on the assumption that container is mounted and administrators want to pre-provision queues.

This module replicates [setUpNotificationServices]( https://docs.microsoft.com/en-us/azure/databricks/spark/latest/structured-streaming/auto-loader#cloud-resource-management).

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [azurerm_eventgrid_event_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_event_subscription) | resource |
| [azurerm_storage_queue.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |
| [time_static.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_container_name"></a> [container_name](#input_container_name) | Name of storage container | `any` | n/a |
| <a name="input_folder"></a> [folder](#input_folder) | Path on the container to create queue from | `any` | n/a |
| <a name="input_mount_name"></a> [mount_name](#input_mount_name) | Name of the mount | `any` | n/a |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | Name of resource group | `any` | n/a |
| <a name="input_storage_account_name"></a> [storage_account_name](#input_storage_account_name) | Name of storage account | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_path"></a> [path](#output_path) | Path that is expected to be consumed from |
| <a name="output_queue_name"></a> [queue_name](#output_queue_name) | n/a |
