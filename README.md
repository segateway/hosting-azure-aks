# hosting-azure-aks

## Setup State

Create a resource group and Microsoft Storage account for use by terraform for state tracking

See https://developer.hashicorp.com/terraform/language/settings/backends/azurerm

* The user/users should be granted owner access to this storage account

## Configure

* Update `deployments/state.hcl` with the resource group and storage account from the prior step
* Rename `deployments/*.template.yaml` to remove `.template`
* 
* execute `az login`
* cd to `deployments/prod` and execute `terragrunt run-all apply --terragrunt-non-interactive`