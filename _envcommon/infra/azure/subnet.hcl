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
  source = "tfr:///seg-way/subnet/azurerm?version=1.2.0"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
  vnet  = yamldecode(file("${path_relative_to_include()}/subnet.yaml"))

}

dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../../resourcegroup/"
}
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../../vnet/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name           = local.vnet.name
  resource_group = dependency.rg.outputs.resource_group_name

  virtual_network_name                          = dependency.net.outputs.virtual_network_name
  subnet                                        = local.vnet.subnet
  private_endpoint_network_policies_enabled     = local.vnet.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = local.vnet.private_link_service_network_policies_enabled
  service_endpoints                             = local.vnet.service_endpoints
}