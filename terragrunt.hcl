# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {

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
    environment          = local.azure.environment.short
    resource_group_name  = local.azure.resourcegroup
    storage_account_name = local.azure.statestorageaccount
    container_name       = local.azure.statecontainer
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    subscription_id      = local.azure.subscription_id
  }
}

generate "provider" {
  path      = "provider_azure.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "azurerm" {
  features {}
  environment = "${local.azure.environment.short}"
  subscription_id = "${local.azure.subscription_id}"
  skip_provider_registration = true
}    
  EOF
}


