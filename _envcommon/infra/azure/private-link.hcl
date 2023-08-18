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
  source = "tfr:///seg-way/network-privatelink/azurerm?version=1.0.2"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))
  link  = yamldecode(file("${path_relative_to_include()}/link.yaml"))
}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../../resourcegroup/"
}
dependency "subnet" {
  config_path = "${get_terragrunt_dir()}/../../network/subnets/endpoint/"
}
dependency "resource" {
  config_path = "${get_terragrunt_dir()}/../${local.link.resource}/"
}
dependency "zone" {
  config_path = "${get_terragrunt_dir()}/../../dns-private/${local.link.zone}/"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  resource_group_name              = dependency.rg.outputs.resource_group_name
  location                         = dependency.rg.outputs.resource_group_location
  name                             = dependency.resource.outputs.name
  subnet_id                        = dependency.subnet.outputs.id
  private_link_enabled_resource_id = dependency.resource.outputs.id
  private_dns_zone_id              = dependency.zone.outputs.id

  subresource_names = local.link.subresource_names
}