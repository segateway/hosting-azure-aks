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
  source = "tfr:///seg-way/eventhub-consumergroup/azurerm?version=1.0.1"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
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

  group_vars = read_terragrunt_config("cgroup.hcl")
  group_name = local.group_vars.locals.name


  tag_vars = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags = local.tag_vars.locals.tags

}

dependency "rg_collectors" {
  config_path = "${get_terragrunt_dir()}/../../../../resourcegroup/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../eventhub-namespace/"
}
dependency "eh" {
  config_path = "${get_terragrunt_dir()}/../../hub/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name                = local.group_name
  namespace_name      = dependency.ehns.outputs.name
  eventhub_name       = dependency.eh.outputs.name
  resource_group_name = dependency.rg_collectors.outputs.resource_group_name


}