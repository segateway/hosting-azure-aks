
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
  source = "tfr:///segateway/monitor-diagnostics/azurerm?version=1.2.3"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  azure    = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
  hub      = basename(abspath("${get_terragrunt_dir()}/../.."))
  resource = yamldecode(file("${path_relative_to_include()}/resource.yaml"))
}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../../../../../infra/resourcegroup/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../../../infra/eventhub-namespace/namespace/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../eventhub",
  ]
}
dependency "created" {
  config_path = "${get_terragrunt_dir()}/../../../../../../${local.resource.path}/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group_name = dependency.rg.outputs.resource_group_name
  name                = dependency.rg.outputs.resource_group_name

  eventhub_namespace_name = dependency.ehns.outputs.name
  eventhub_name           = local.hub

  target_ids = [
    dependency.created.outputs.id
  ]

  logs = local.resource.logs

}