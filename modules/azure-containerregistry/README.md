Creates Azure Container Registry, sample Docker image and Databricks cluster with it
VNet module should be started with `private_subnet_endpoints = ["Microsoft.ContainerRegistry"]`

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [databricks_cluster.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/cluster) | resource |
| [docker_registry_image.this](https://registry.terraform.io/providers/kreuzwerker/docker/2.11.0/docs/resources/registry_image) | resource |
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/databricks_workspace) | data source |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [databricks_current_user.me](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/current_user) | data source |
| [databricks_node_type.smallest](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/node_type) | data source |
| [databricks_spark_version.latest](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/spark_version) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_databricks_resource_id"></a> [databricks_resource_id](#input_databricks_resource_id) | The Azure resource ID for the databricks workspace deployment. | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_url"></a> [cluster_url](#output_cluster_url) | URL to view cluster configuration in the browser |
