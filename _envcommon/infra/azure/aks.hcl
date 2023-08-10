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
  source = "tfr:///seg-way/akscluster/azurerm?version=1.1.0"
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
dependency "net" {
  config_path = "${get_terragrunt_dir()}/../../network/"
}
dependency "admins" {
  config_path = "${get_terragrunt_dir()}/../../cluster-admins/"
}
dependency "registry" {
  config_path = "${get_terragrunt_dir()}/../registry/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../eventhub-namespace/"
}
dependency "eh" {
  config_path = "${get_terragrunt_dir()}/../../eventhubs/azure/hub"
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  cluster_name   = dependency.rg.outputs.resource_group_name
  resource_group = dependency.rg.outputs.resource_group_name
  location       = dependency.rg.outputs.resource_group_location
  tags           = dependency.rg.outputs.tags

  # sku_tier = "Standard"

  admins_group_id = dependency.admins.outputs.id


  subnet_id    = dependency.net.outputs.virtual_subnet_id
  subnet_id_ag = dependency.net.outputs.virtual_subnet_id_ag
  # arm Standard_D2plds_v5
  # intel Standard_A2_v2
  agent_size = local.azure.aks.agents.size
  agent_max  = local.azure.aks.agents.max

  registry_id = dependency.registry.outputs.id



  workload_identity_enabled           = true
  ingress_application_gateway_enabled = false

  eventhub_namespace      = dependency.ehns.outputs.name
  eventhub_name           = dependency.eh.outputs.name
  eventhub_resource_group = dependency.rg.outputs.resource_group_name


}