Databricks E2 workspace with BYOVPC

![preview](./arch.png)

Creates AWS IAM cross-account role, AWS S3 root bucket, VPC with Internet gateway, NAT, routing, one public subnet,
two private subnets in two different regions. Then it ties all together and creates an E2 workspace.

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module_vpc) | terraform-aws-modules/vpc/aws | 2.70.0 |

#### Resources

| Name | Type |
|------|------|
| [aws_iam_role.cross_account_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.root_storage_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.root_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.root_storage_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [databricks_mws_credentials.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/mws_credentials) | resource |
| [databricks_mws_networks.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/mws_networks) | resource |
| [databricks_mws_storage_configurations.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/mws_storage_configurations) | resource |
| [databricks_mws_workspaces.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/resources/mws_workspaces) | resource |
| [random_string.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [databricks_aws_assume_role_policy.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/aws_assume_role_policy) | data source |
| [databricks_aws_bucket_policy.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/aws_bucket_policy) | data source |
| [databricks_aws_crossaccount_policy.this](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs/data-sources/aws_crossaccount_policy) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_cidr_block"></a> [cidr_block](#input_cidr_block) | n/a | `string` | `"10.4.0.0/16"` |
| <a name="input_databricks_account_id"></a> [databricks_account_id](#input_databricks_account_id) | n/a | `any` | n/a |
| <a name="input_databricks_account_password"></a> [databricks_account_password](#input_databricks_account_password) | n/a | `any` | n/a |
| <a name="input_databricks_account_username"></a> [databricks_account_username](#input_databricks_account_username) | n/a | `any` | n/a |
| <a name="input_region"></a> [region](#input_region) | n/a | `string` | `"eu-west-1"` |
| <a name="input_tags"></a> [tags](#input_tags) | n/a | `map` | `{}` |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_databricks_host"></a> [databricks_host](#output_databricks_host) | n/a |
