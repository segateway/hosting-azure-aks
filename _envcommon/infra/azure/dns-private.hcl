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
  source = "tfr:///segateway/dns-zone-private/azurerm?version=2.0.0"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
  dns   = yamldecode(file("${path_relative_to_include()}/dns.yaml"))

  dnsmap = yamldecode(<<YAML
  public:
    azclient.ms: azclient.ms
    azure.com: azure.com
    cloudapp.net: cloudapp.net
    core.windows.net: core.windows.net
    msidentity.com: msidentity.com
    trafficmanager.net: trafficmanager.net
    windows.net: windows.net
  usgovernment:
    azclient.ms: azclient.us
    azure.com: azure.us
    cloudapp.net: usgovcloudapp.net
    core.windows.net: core.usgovcloudapi.net
    msidentity.com: msidentity.us
    trafficmanager.net: usgovtrafficmanager.net
    windows.net: usgovcloudapi.net
YAML
  )

  environment = lookup(local.dnsmap, local.azure.environment.short, {})
  domain      = lookup(local.environment, local.dns.suffix, "")
}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../resourcegroup/"
}
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../../network/vnet/"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group_name = dependency.rg.outputs.resource_group_name
  name                = local.dns.name
  domain              = local.domain
  virtual_network_id  = dependency.net.outputs.virtual_network_id
}