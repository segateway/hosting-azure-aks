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
  source = "tfr:///segateway/akscluster/azurerm?version=2.1.1"
}


# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  azure = yamldecode(file(find_in_parent_folders("azure_vars.yaml")))

}


dependency "rg" {
  config_path = "${get_terragrunt_dir()}/../resourcegroup/"
}
dependency "subnet_k8s" {
  config_path = "${get_terragrunt_dir()}/../network/subnets/k8s"
}
dependency "subnet_agw" {
  config_path = "${get_terragrunt_dir()}/../network/subnets/agw"
}
dependency "adminGroup" {
  config_path = "${get_terragrunt_dir()}/../k8s-admins/"
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


  subnet_id      = dependency.subnet_k8s.outputs.id
  subnet_id_ag   = dependency.subnet_agw.outputs.id
  service_cidr   = "10.0.4.0/24"
  dns_service_ip = "10.0.4.10"
  # arm Standard_D2plds_v5
  # intel Standard_A2_v2
  agent_size = local.azure.aks.agents.size
  agent_max  = local.azure.aks.agents.max

  admins_group_ids = concat([dependency.adminGroup.outputs.id],local.azure.admingroups)

  workload_identity_enabled           = true
  ingress_application_gateway_enabled = false

}