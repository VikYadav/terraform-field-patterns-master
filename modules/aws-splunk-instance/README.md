Splunk on AWS EC2 instance

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [aws_instance.sandbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.local](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_security_group.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet_ids.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [http_http.this_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_instance_type"></a> [instance_type](#input_instance_type) | n/a | `string` | `"i3.large"` |
| <a name="input_name"></a> [name](#input_name) | Name of the resources | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | AWS VPC to launch EC2 instance | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password"></a> [admin_password](#output_admin_password) | n/a |
| <a name="output_private_ip"></a> [private_ip](#output_private_ip) | n/a |
| <a name="output_splunk_ui"></a> [splunk_ui](#output_splunk_ui) | n/a |
| <a name="output_ssh_command"></a> [ssh_command](#output_ssh_command) | n/a |
