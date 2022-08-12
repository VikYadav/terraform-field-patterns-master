/**
 * Jenkins CI sample integration
 *
 *  Pull Jenkins Docker image:
 * https://github.com/jenkinsci/docker/blob/master/README.md
 *
 * export JENKINS_USERNAME="admin"
 * export JENKINS_PASSWORD="..."
 *
 *  In the container, you have to run:
 *
 *  1. `ssh-keygen` to generate SSH keypair
 *  2. `cat ~/.ssh/id_rsa.pub` and supply that as value for `jenkins_public_key` variable
 *  3. `ssh git@github.com` to add github to known hosts
 */

variable "jenkins_url" {}

variable "jenkins_public_key" {
  description = "Public SSH key of your private Jenkins installation"
}

provider "jenkins" {
  server_url = var.jenkins_url
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

resource "jenkins_job" "seed" {
  name     = "seed-${random_string.naming.result}"
  template = templatefile("${path.module}/seed.xml", {
    JOB_DSL = templatefile("${path.module}/seed.groovy", {})
  })
}

resource "github_repository" "demo" {
  name        = "demo-${random_string.naming.result}"
  description = "My awesome codebase"
  visibility = "private"
  auto_init = true
}

resource "github_repository_deploy_key" "jenkins" {
  title      = "SSH Public key of ${var.jenkins_url}"
  repository = github_repository.demo.name
  key        = var.jenkins_public_key
  read_only  = "false"
}

resource "github_repository_file" "gitignore" {
  repository          = github_repository.demo.name
  branch              = "main"
  file                = ".gitignore"
  content             = "**/*.tfstate"
  commit_message      = "Managed by Terraform"
  commit_author       = "Terraform User"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

resource "jenkins_job" "freestyle" {
  name     = "freestyle-${random_string.naming.result}"
  template = templatefile("${path.module}/freestyle.xml", {
    GIT_URL = github_repository.demo.ssh_clone_url
    BRANCH = github_repository.demo.default_branch
    DESCRIPTION = "Demonstration from Terraform"
    SHELL_SCRIPT = <<-EOF
      pip install databricks-cli
    EOF
  })
}

output "github_url" {
  value = github_repository.demo.html_url
}

output "configure_credentials" {
  value = "${var.jenkins_url}/credentials/store/system/domain/_/newCredentials"
}