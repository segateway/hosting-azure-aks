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
  source = "tfr:///libre-devops/event-hub/azurerm?version=1.0.0"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  hub = basename(abspath("${get_terragrunt_dir()}/.."))
}


dependency "rg_collectors" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/resourcegroup/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/eventhub-namespace/namespace/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  rg_name  = dependency.rg_collectors.outputs.resource_group_name
  location = dependency.rg_collectors.outputs.resource_group_location

  event_hub_name = local.hub
  namespace_name = dependency.ehns.outputs.name

  settings = {
    status            = "Active"
    partition_count   = "32"
    message_retention = "1"
  }
  storage_account_id = ""

}