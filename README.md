Terraform field patterns
---

Maintained set of Terraform deployment patterns, that can be used as reproducible reference architectures.

## Environments (Demos)

Each environment should be built from module, by just assigning it different parameters. 

* [azure-eventhubs-demo](environments/azure-eventhubs-demo)
* [azure-loganalytics-demo](environments/azure-loganalytics-demo)
* [azure-msi-demo](environments/azure-msi-demo)
* [azure-vnet-injection-demo](environments/azure-vnet-injection-demo)
* [e2-double-workspace-demo](environments/e2-double-workspace-demo)
* [e2-single-workspace-demo](environments/e2-single-workspace-demo)
* [e2-workspace](environments/e2-workspace)
* [elk-demo](environments/elk-demo)
* [splunk-demo](environments/splunk-demo)

## Modules

**Important**: All modules must have the following configuration in order to work with Databricks in terraform 0.13+:

```
terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
    }
  }
}
```

* [aws-databricks-bucket/](modules/aws-databricks-bucket/) Creates AWS S3 bucket that is writeable by Databricks
* [aws-databricks-crossaccount/](modules/aws-databricks-crossaccount/) Creates AWS Cross-account IAM Role, where Databricks AWS account it is allowed to do `sts:AssumeRole`
* [aws-databricks-department/](modules/aws-databricks-department/) E2 design pattern, that creates restricted S3 bucket with EC2 instance profile to access data, registers it within Databricks, attaches it to cluster policy and allows usage to this group.
* [aws-e2workspace/](modules/aws-e2workspace/) Databricks E2 workspace with BYOVPC
* [aws-e2workspace-privatelink/](modules/aws-e2workspace-privatelink/) E2 pattern with AWS Private Link
* [aws-ec2-sandbox/](modules/aws-ec2-sandbox/) Creates EC2 instance with Terraform installed on it
* [aws-ecs-elk/](modules/aws-ecs-elk/) ELK Stack (ElasticSearch + FileBeat + Kibana in this case) on AWS
* [aws-elk-instance/](modules/aws-elk-instance/) Single-node ELK Stack (ElasticSearch + FileBeat + Kibana in this case) on AWS
* [aws-mws/](modules/aws-mws/) E2 pattern with two VPCs and two workspaces with fully-featured security measures
* [aws-splunk-instance/](modules/aws-splunk-instance/) Splunk on AWS EC2 instance
* [azure-audit/](modules/azure-audit/) Azure Monitor setting to send audit logs over to storage account
* [azure-audit-eventhubs/](modules/azure-audit-eventhubs/) Azure EventHubs for structured streaming
* [azure-autoloader/](modules/azure-autoloader/) Creates Autoloader configuration for Azure with relevant notebooks, dummy data generator and secrets
* [azure-autoloader-queue/](modules/azure-autoloader-queue/) Creates Azure Databricks Autoloader for ADLSv2
* [azure-containerregistry/](modules/azure-containerregistry/) Creates Azure Container Registry, sample Docker image and Databricks cluster with it
* [azure-databricks-clusterpolicies/](modules/azure-databricks-clusterpolicies/) Samples of cluster policies
* [azure-loganalytics/](modules/azure-loganalytics/) Creates Azure Log Analytics workspace and integrates it with Azure Databricks through init scripts
* [azure-mlworkspace/](modules/azure-mlworkspace/) AzureML workspace connected to Azure Databricks workspace
* [azure-msi-sandbox/](modules/azure-msi-sandbox/) #### Modules
* [azure-vnet-injection/](modules/azure-vnet-injection/) Azure Databricks workspace in custom VNet
* [cluster-logs/](modules/cluster-logs/) Log forwarders
* [databricks-cluster-policy/](modules/databricks-cluster-policy/) Extendable enterprisse cluster policy module, that customers should tune to their own use-cases
* [jenkins-ci/](modules/jenkins-ci/) Jenkins CI sample integration

## Conventions

* Each module should have cloud-specific prefix, like `aws-` or `azure-` and contain reusable functionality.
* All resources within each module should be named `this`, unless there's more than 1 instance of them.
* `README.md` file for each module is auto-generated, so please do make sure that each and every module has
a valid comment header like:

```
/**
 * Creates AWS S3 bucket that is writeable by Databricks
 */
```

* Azure resources should work with single resource group, primarily identified by its workspace
* Azure modules should get `databricks_resource_id` parameter, so that the module could be applied to
the whole workspace and removed, when no longer needed. This code snippet can help you retrieve resource group
information and workspace name from the resource id:

```
variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/.+/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[0]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[1]
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

# Most likely, dependent resources would have
# ...
    name = replace(data.azurerm_resource_group.this.name, "rg", "akv")
    resource_group_name = data.azurerm_resource_group.this.name
    location = data.azurerm_resource_group.this.location
    tags = data.azurerm_resource_group.this.tags
# ...
```

* names of resources should always have the same prefix as resource group they are in, so that it's easier to navigate
in Azure Portal. You can easily achieve that by using `replace(data.azurerm_resource_group.this.name, "rg", "hub")`.

> This file is auto-generated by ./gen-readme.sh > README.md
