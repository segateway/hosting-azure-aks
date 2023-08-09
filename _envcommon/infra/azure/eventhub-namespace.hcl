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
  source = "tfr:///seg-way/event-hub-namespace/azurerm?version=1.0.1"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  azure_vars      = read_terragrunt_config(find_in_parent_folders("azure.hcl"))
  subscription_id = local.azure_vars.locals.subscription_id
  tenant_id       = local.azure_vars.locals.tenant_id

  # Automatically load environment-level variables
  config   = read_terragrunt_config(find_in_parent_folders("_eventhubnamespace.hcl"))
  settings = local.config.locals.settings
}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../resourcegroup/"
}
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../network/"
}
dependency "consumers" {
  config_path = "${get_terragrunt_dir()}/../eventhub-consumers/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  rg_name                  = dependency.rg.outputs.resource_group_name
  event_hub_namespace_name = dependency.rg.outputs.resource_group_name
  location                 = dependency.rg.outputs.resource_group_location

  settings = {
    sku                      = local.settings.sku
    auto_inflate_enabled     = local.settings.auto_inflate_enabled
    maximum_throughput_units = local.settings.maximum_throughput_units

    network_rulesets = {
      default_action                 = local.settings.network_rulesets.default_action
      public_network_access_enabled  = local.settings.network_rulesets.public_network_access_enabled
      trusted_service_access_enabled = true

      virtual_network_rule = {
        subnet_id                                       = dependency.net.outputs.virtual_subnet_id // uses sn1
        ignore_missing_virtual_network_service_endpoint = false
      }
    }
  }




  role_assignments = [
    {
      role  = "Azure Event Hubs Data Receiver",
      group = dependency.consumers.outputs.id
    }
  ]
}