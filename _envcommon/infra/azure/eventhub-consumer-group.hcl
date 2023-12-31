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
  source = "tfr:///segateway/eventhub-consumergroup/azurerm?version=1.1.1"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
}

dependency "rg_collectors" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/resourcegroup/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/eventhub-namespace/namespace/"
}
dependency "eh" {
  config_path = "${get_terragrunt_dir()}/../eventhub/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name                = "segateway"
  namespace_name      = dependency.ehns.outputs.name
  eventhub_name       = dependency.eh.outputs.name
  resource_group_name = dependency.rg_collectors.outputs.resource_group_name
}