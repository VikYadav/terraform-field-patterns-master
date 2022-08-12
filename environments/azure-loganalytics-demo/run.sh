#/bin/bash


# The following must be set to use a service principal
export ARM_CLIENT_ID="$ARM_CLIENT_ID"
export ARM_CLIENT_SECRET="$ARM_CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID"
export ARM_TENANT_ID="$ARM_TENANT_ID"

# Log in as service principal
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# In the event that multiple subscriptions exist, set to the proper one.
az account set --subscription $ARM_SUBSCRIPTION_ID

# For app monitor
#chmod +x `pwd`/resources/spark-monitoring/build.sh
#docker run -it --rm -v `pwd`/resources/spark-monitoring:/spark-monitoring -v "$HOME/.m2":/root/.m2 maven:3.6.1-jdk-8 `pwd`/resources/spark-monitoring/build.sh

# Initialize terraform
terraform init

# Import example: resource group
# terraform import <INSERT RESOURCE Ex. "azurerm_resource_group.rg_name"> <RESOURCE ID/DIRECTORY>

# Run terraform
terraform plan -var-file="parameters.tfvars"
terraform apply -var-file="parameters.tfvars"

# Add Linux performance counters and Syslog logging to Log Analytics under "Advanced Settings MANUALLY in Azure Portal" 
# Ensure that Syslog has "NOTICE", "INFO", and "DEBUG" removed, to avoid noise.
