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
  source = "tfr:///segateway/eventhub-namespace/azurerm?version=2.0.4"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../resourcegroup/"
}
# dependency "net" {
#   config_path = "${get_terragrunt_dir()}/../../network/"
# }

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  rg_name                  = dependency.rg.outputs.resource_group_name
  event_hub_namespace_name = dependency.rg.outputs.resource_group_name
  location                 = dependency.rg.outputs.resource_group_location

  public_network_access_enabled = false
  settings = {
    sku                      = local.azure.eventhubnamespace.settings.sku
    auto_inflate_enabled     = local.azure.eventhubnamespace.settings.auto_inflate_enabled
    maximum_throughput_units = local.azure.eventhubnamespace.settings.maximum_throughput_units

    network_rulesets = {
      default_action = local.azure.eventhubnamespace.settings.network_rulesets.default_action
      # For Azure, AzureAD, Intune and Defender sources this must be true without the sources
      # Can not deliver events. See https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=portal#destination-limitations
      trusted_service_access_enabled = true
      default_action = "Deny"
    }
  }
}