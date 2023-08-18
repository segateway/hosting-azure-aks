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
  source = "tfr:///seg-way/storage-account/azurerm?version=1.3.0"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))

}


dependency "rg_collectors" {
  config_path = "${get_terragrunt_dir()}/../../resourcegroup/"
}
# dependency "net" {
#   config_path = "${get_terragrunt_dir()}/../network/"
# }

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group_name = dependency.rg_collectors.outputs.resource_group_name
  location            = dependency.rg_collectors.outputs.resource_group_location
  name                = local.azure.clusterstorage

  public_network_access_enabled = local.azure.public_network_access_enabled
  firewall_bypass_current_ip    = true

}