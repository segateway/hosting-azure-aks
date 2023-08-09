# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mysql. The common variables for each environment to
# deploy mysql are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If any environment
# needs to deploy a different module version, it should redefine this block with a different ref to override the
# deployed version.
terraform {
  source = "tfr:///kumarvna/storage/azurerm?version=2.5.0"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))

}


dependency "rg_collectors" {
  config_path = "${get_terragrunt_dir()}/../resourcegroup/"
}
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../network/"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group_name  = dependency.rg_collectors.outputs.resource_group_name
  location             = dependency.rg_collectors.outputs.resource_group_location
  storage_account_name = local.azure.shortname

  containers_list = [
    { name = "azure", access_type = "private" },
    { name = "azuread", access_type = "private" },
    { name = "defender", access_type = "private" },
    { name = "intune", access_type = "private" }
  ]
  # network_rules = {
  #   bypass = [
  #     "Logging",
  #     "Metrics",
  #     "AzureServices"
  #   ]
  #   ip_rules = []
  #   subnet_ids = [
  #     dependency.net.outputs.virtual_subnet_id
  #   ]
  # }

}