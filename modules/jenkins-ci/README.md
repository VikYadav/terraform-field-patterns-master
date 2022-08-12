Jenkins CI sample integration

 Pull Jenkins Docker image:
https://github.com/jenkinsci/docker/blob/master/README.md

export JENKINS_USERNAME="admin"
export JENKINS_PASSWORD="..."

 In the container, you have to run:

 1. `ssh-keygen` to generate SSH keypair
 2. `cat ~/.ssh/id_rsa.pub` and supply that as value for `jenkins_public_key` variable
 3. `ssh git@github.com` to add github to known hosts

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [github_repository.demo](https://registry.terraform.io/providers/integrations/github/4.5.1/docs/resources/repository) | resource |
| [github_repository_deploy_key.jenkins](https://registry.terraform.io/providers/integrations/github/4.5.1/docs/resources/repository_deploy_key) | resource |
| [github_repository_file.gitignore](https://registry.terraform.io/providers/integrations/github/4.5.1/docs/resources/repository_file) | resource |
| [jenkins_job.freestyle](https://registry.terraform.io/providers/taiidani/jenkins/0.7.0-beta2/docs/resources/job) | resource |
| [jenkins_job.seed](https://registry.terraform.io/providers/taiidani/jenkins/0.7.0-beta2/docs/resources/job) | resource |
| [random_string.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

#### Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_jenkins_public_key"></a> [jenkins_public_key](#input_jenkins_public_key) | Public SSH key of your private Jenkins installation | `any` | n/a |
| <a name="input_jenkins_url"></a> [jenkins_url](#input_jenkins_url) | n/a | `any` | n/a |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_configure_credentials"></a> [configure_credentials](#output_configure_credentials) | n/a |
| <a name="output_github_url"></a> [github_url](#output_github_url) | n/a |
