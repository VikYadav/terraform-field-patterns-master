Creates AWS Cross-account IAM Role, where Databricks AWS account it is allowed to do `sts:AssumeRole`

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cross_account_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_role_for_databricks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cross_account_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_databricks_account_id"></a> [databricks_account_id](#input_databricks_account_id) | Default databricks AWS Account ID | `string` | `"414351767826"` |
| <a name="input_external_id"></a> [external_id](#input_external_id) | External ID you find on https://accounts.cloud.databricks.com/#aws | `string` | n/a |
| <a name="input_prefix"></a> [prefix](#input_prefix) | Prefix for resources created for | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role_arn](#output_role_arn) | n/a |
| <a name="output_role_name"></a> [role_name](#output_role_name) | n/a |
