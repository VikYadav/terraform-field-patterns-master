REM This is for Windows box deployment.

REM Azure Blob Storage account access keys (Key1)
SET ARM_ACCESS_KEY=%ARM_ACCESS_KEY%

REM HOME Directory for the Terraform Databricks Monitoring Solution project
SET HOME=%HOME%

REM Service Principal Authentication
SET ARM_CLIENT_ID=%ARM_CLIENT_ID%
SET ARM_CLIENT_SECRET=%$ARM_CLIENT_SECRET%
SET ARM_SUBSCRIPTION_ID=%$ARM_SUBSCRIPTION_ID%
SET TF_VAR_subscription_id=%$ARM_SUBSCRIPTION_ID%
SET ARM_TENANT_ID=%ARM_TENANT_ID%

SET env=test

REM Select the workspace
terraform workspace select %env%

REM Initialize terraform
terraform init

REM Run terraform
terraform plan -var-file="parameters.tfvars" -out "db-analytics-%env%.tfplan"

REM Apply terraform
terraform apply "db-analytics-%env%.tfplan"
