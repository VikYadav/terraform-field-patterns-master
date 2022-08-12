Creates AWS S3 bucket that is writeable by Databricks

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_databricks_account_id"></a> [databricks_account_id](#input_databricks_account_id) | Default databricks AWS Account ID | `string` | `"414351767826"` |
| <a name="input_force_destroy"></a> [force_destroy](#input_force_destroy) | Allows bucket to be destroyed by terraform even if it has data.<br>    It is discouraged to enable this option for critical data buckets. | `bool` | `false` |
| <a name="input_name"></a> [name](#input_name) | Name of the bucket | `any` | n/a |
| <a name="input_region"></a> [region](#input_region) | Region where bucket is located | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |
| <a name="input_versioning"></a> [versioning](#input_versioning) | Either or not apply versioning for root bucket | `bool` | `false` |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output_arn) | n/a |
| <a name="output_bucket"></a> [bucket](#output_bucket) | n/a |
