E2 design pattern, that creates restricted S3 bucket with EC2 instance profile to access data, registers it within Databricks, attaches it to cluster policy and allows usage to this group.

Per-department "Shared Autoscaling" cluster is created and basic notebooks are added as well.

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module_bucket) | ./restricted-bucket | n/a |

#### Resources

| Name | Type |
|------|------|
| [databricks_cluster.team_shared_autoscaling](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/cluster) | resource |
| [databricks_cluster_policy.fair_use](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/cluster_policy) | resource |
| [databricks_group.this](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/group) | resource |
| [databricks_group_instance_profile.this](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/group_instance_profile) | resource |
| [databricks_notebook.init_database_notebook](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/notebook) | resource |
| [databricks_permissions.can_use_instance_profile](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/permissions) | resource |
| [databricks_permissions.can_use_team_cluster](https://registry.terraform.io/providers/hashicorp/databricks/latest/docs/resources/permissions) | resource |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_aws_zone"></a> [aws_zone](#input_aws_zone) | n/a | `any` | n/a |
| <a name="input_crossaccount_role_name"></a> [crossaccount_role_name](#input_crossaccount_role_name) | n/a | `any` | n/a |
| <a name="input_databricks_workspace_host"></a> [databricks_workspace_host](#input_databricks_workspace_host) | n/a | `any` | n/a |
| <a name="input_databricks_workspace_token"></a> [databricks_workspace_token](#input_databricks_workspace_token) | n/a | `any` | n/a |
| <a name="input_department"></a> [department](#input_department) | n/a | `any` | n/a |
| <a name="input_force_destroy"></a> [force_destroy](#input_force_destroy) | n/a | `any` | n/a |
| <a name="input_name"></a> [name](#input_name) | n/a | `any` | n/a |
| <a name="input_prefix"></a> [prefix](#input_prefix) | n/a | `any` | n/a |
| <a name="input_region"></a> [region](#input_region) | n/a | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |
| <a name="input_versioning"></a> [versioning](#input_versioning) | n/a | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output_bucket) | n/a |
| <a name="output_reader_policy_arn"></a> [reader_policy_arn](#output_reader_policy_arn) | n/a |
