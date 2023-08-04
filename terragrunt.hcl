# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  azure_vars      = read_terragrunt_config(find_in_parent_folders("azure.hcl"))
  location        = local.azure_vars.locals.location
  subscription_id = local.azure_vars.locals.subscription_id
  tenant_id       = local.azure_vars.locals.tenant_id
  # Extract the variables we need for easy access
  rg_vars = read_terragrunt_config(find_in_parent_folders("resourcegroup.hcl"))
  rg_name = local.rg_vars.locals.name

  tag_vars = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags = jsonencode(merge(
    local.tag_vars.locals.tags,
    {
      Environment = local.env
      # Owner         = get_aws_caller_identity_user_id()
      GitRepository = run_cmd("sh", "-c", "git config --get remote.origin.url")
    },
  ))
}


# stage/terragrunt.hcl
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "segway-state"
    storage_account_name = "logsrlifetfstate"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"

  }
}

generate "provider" {
  path      = "provider_azure.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "azurerm" {
  features {}

  subscription_id = "${local.subscription_id}"
  tenant_id = "${local.tenant_id}"
    
}    
  EOF
}



# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.environment_vars.locals,
)