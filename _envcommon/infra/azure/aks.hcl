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
  source = "git::https://github.com/seg-way/teraform-azure-aks-cluster.git?ref=v1.0.4"
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
}


generate "provider" {
  path      = "provider_azure.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "azurerm" {
  features {}

  subscription_id = "${local.subscription_id}"
  tenant_id = "${local.tenant_id}"
    
}    
  EOF
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
  agent_size = "Standard_D2plds_v5"
  agent_max  = 6

  registry_id = dependency.registry.outputs.id



  workload_identity_enabled           = true
  ingress_application_gateway_enabled = false

  eventhub_namespace      = dependency.ehns.outputs.name
  eventhub_name           = dependency.eh.outputs.name
  eventhub_resource_group = dependency.rg.outputs.resource_group_name


}