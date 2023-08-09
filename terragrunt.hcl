# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load environment-level variables
  state_vars = read_terragrunt_config(find_in_parent_folders("state.hcl"))
  state_resourcegroup = local.state_vars.locals.resourcegroup
  state_storageaccount = local.state_vars.locals.storageaccount
  state_container = local.state_vars.locals.container

  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
}


# stage/terragrunt.hcl
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = local.state_resourcegroup
    storage_account_name = local.state_storageaccount
    container_name       = local.state_container
    key                  = "${path_relative_to_include()}/terraform.tfstate"

  }
}

generate "provider" {
  path      = "provider_azure.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "azurerm" {
  features {}

  subscription_id = "${local.azure.subscription_id}"
  tenant_id = "${local.azure.tenant_id}"
    
}    
  EOF
}


