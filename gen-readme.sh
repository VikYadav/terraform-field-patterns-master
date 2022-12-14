#!/usr/bin/env bash
MODULES_DIR="$(pwd)/modules"
DEMO_DIR="$(pwd)/environments"

cat << EOF
Terraform field patterns
---

Maintained set of Terraform deployment patterns, that can be used as reproducible reference architectures.

## Environments (Demos)

Each environment should be built from module, by just assigning it different parameters. 

EOF

for DEMO in $(ls -1 $DEMO_DIR); do
    echo "* [$DEMO](environments/$DEMO)"
done

cat <<'EOF'

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

EOF

for MODULE in $(ls -1p $MODULES_DIR | grep '/$'); do
    terraform-docs --hide requirements --hide providers md modules/$MODULE > modules/$MODULE/README.md
    if [ $? -eq 0 ] ; then
        git add "./modules/$MODULE/README.md"
    fi
    DESCRIPTION=$(head -n1 modules/$MODULE/README.md)
    echo "* [$MODULE](modules/$MODULE) $DESCRIPTION"
done


cat <<'EOF'

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

EOF

echo "> This file is auto-generated by $0 > README.md"