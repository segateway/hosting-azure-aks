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
  source = "tfr:///seg-way/vault/azurerm?version=1.0.1"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {


}

dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../resourcegroup/"
}
dependency "admin" {
  config_path = "${get_terragrunt_dir()}/../../cluster-admins/"
}
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../../network/"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group = dependency.rg.outputs.resource_group_name
  location       = dependency.rg.outputs.resource_group_location
  prefix         = "${dependency.rg.outputs.resource_group_name}"

  virtual_network_subnet_ids = [
    dependency.net.outputs.virtual_subnet_id
  ]

  admin_group_id = dependency.admin.outputs.id
  tags           = dependency.rg.outputs.tags

}