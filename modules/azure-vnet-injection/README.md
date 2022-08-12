Azure Databricks workspace in custom VNet

Module creates:
* Resource group with random prefix
* Tags, including `Owner`, which is taken from `az account show --query user`
* VNet with public and private subnet
* Databricks workspace

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [random_string.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [external_external.me](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_cidr"></a> [cidr](#input_cidr) | n/a | `any` | n/a |
| <a name="input_no_public_ip"></a> [no_public_ip](#input_no_public_ip) | n/a | `bool` | `false` |
| <a name="input_private_subnet_endpoints"></a> [private_subnet_endpoints](#input_private_subnet_endpoints) | n/a | `list` | `[]` |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_arm_client_id"></a> [arm_client_id](#output_arm_client_id) | n/a |
| <a name="output_arm_subscription_id"></a> [arm_subscription_id](#output_arm_subscription_id) | n/a |
| <a name="output_arm_tenant_id"></a> [arm_tenant_id](#output_arm_tenant_id) | n/a |
| <a name="output_azure_region"></a> [azure_region](#output_azure_region) | n/a |
| <a name="output_databricks_azure_workspace_resource_id"></a> [databricks_azure_workspace_resource_id](#output_databricks_azure_workspace_resource_id) | n/a |
| <a name="output_test_resource_group"></a> [test_resource_group](#output_test_resource_group) | n/a |
| <a name="output_workspace_url"></a> [workspace_url](#output_workspace_url) | n/a |
