Creates EC2 instance with Terraform installed on it

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [aws_instance.sandbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.local](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [http_http.this_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_ami"></a> [ami](#input_ami) | AWS AMI to launch with. Defaults to Ubuntu 20.04 LTS | `string` | `"ami-02ae530dacc099fc9"` |
| <a name="input_instance_type"></a> [instance_type](#input_instance_type) | n/a | `string` | `"t2.xlarge"` |
| <a name="input_name"></a> [name](#input_name) | Name of the resources | `any` | n/a |
| <a name="input_tags"></a> [tags](#input_tags) | Tags applied to all resources created | `map(string)` | n/a |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | AWS VPC to launch EC2 instance | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssh_command"></a> [ssh_command](#output_ssh_command) | n/a |
