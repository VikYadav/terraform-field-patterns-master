E2 pattern with two VPCs and two workspaces with fully-featured security measures

This reference architecture can be described as the following diagram:
![architecture](./architecture.png)

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crossaccount"></a> [crossaccount](#module_crossaccount) | ../aws-databricks-crossaccount | n/a |
| <a name="module_data_consumers"></a> [data_consumers](#module_data_consumers) | ./consumers | n/a |
| <a name="module_data_creators"></a> [data_creators](#module_data_creators) | ./creators | n/a |
| <a name="module_reader_workspace"></a> [reader_workspace](#module_reader_workspace) | ./workspace | n/a |
| <a name="module_root_bucket"></a> [root_bucket](#module_root_bucket) | ../aws-databricks-bucket | n/a |
| <a name="module_vpc"></a> [vpc](#module_vpc) | ./vpc | n/a |
| <a name="module_vpc_reader"></a> [vpc_reader](#module_vpc_reader) | ./vpc | n/a |
| <a name="module_workspace"></a> [workspace](#module_workspace) | ./workspace | n/a |

#### Resources

No resources.

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | n/a | `any` | n/a |
| <a name="input_aws_zone"></a> [aws_zone](#input_aws_zone) | n/a | `any` | n/a |
| <a name="input_cidr"></a> [cidr](#input_cidr) | n/a | `string` | `"10.1.0.0/16"` |
| <a name="input_databricks_cloud_password"></a> [databricks_cloud_password](#input_databricks_cloud_password) | n/a | `any` | n/a |
| <a name="input_databricks_cloud_username"></a> [databricks_cloud_username](#input_databricks_cloud_username) | n/a | `any` | n/a |
| <a name="input_databricks_external_id"></a> [databricks_external_id](#input_databricks_external_id) | External ID you find on https://accounts.cloud.databricks.com/#aws | `string` | n/a |
| <a name="input_name"></a> [name](#input_name) | n/a | `any` | n/a |
| <a name="input_prefix"></a> [prefix](#input_prefix) | n/a | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_reader_workspace_url"></a> [reader_workspace_url](#output_reader_workspace_url) | n/a |
| <a name="output_workspace_url"></a> [workspace_url](#output_workspace_url) | n/a |
