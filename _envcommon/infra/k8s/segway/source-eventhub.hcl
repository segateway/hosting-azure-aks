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
  source = "git::https://github.com/logscale-contrib/terraform-argocd-applicationset.git?ref=v1.1.1"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Automatically load environment-level variables
  source_vars = read_terragrunt_config("_source.hcl")


}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../k8s/"
}
dependency "storage" {
  config_path = "${get_terragrunt_dir()}/../../../../storage-account/"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../eventhub-namespace/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../argocd/projects/segway",
    "${get_terragrunt_dir()}/../../../../eventhubs/${local.source_vars.locals.name}/consumergroups/segway/",
  ]
}
generate "provider" {
  path      = "provider_k8s.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

provider "kubernetes" {
    host                   = "${dependency.k8s.outputs.exec_host}"
    cluster_ca_certificate = base64decode("${dependency.k8s.outputs.ca_certificate}")
    exec {
      api_version = "${dependency.k8s.outputs.exec_api}"
      command     = "${dependency.k8s.outputs.exec_command}"
      args        = ${jsonencode(dependency.k8s.outputs.exec_args)}
    }
}
EOF
}
# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  name = "eh-${local.source_vars.locals.name}"


  repository = "https://seg-way.github.io/charts"

  release          = "eh-${local.source_vars.locals.name}"
  chart            = "segway-sys-source-ms-azure-eventhub"
  chart_version    = "1.4.2"
  namespace        = "seg-way"
  create_namespace = true
  project          = "segway"
  skipCrds         = false


  values = yamldecode(<<YAML
args:
  - -e
podAnnotations:
  reloader.stakater.com/auto: "true"

nexthop:
    name: ls-cloud-segway-sys-dest-logscale
config:
  data:
    vendor: microsoft
    product: ${local.source_vars.locals.name}
    appparser: microsoft-${local.source_vars.locals.name}
  startingPosition: -1
secret:
  data:
    AZURE_STORAGE_CONN_STR: "${dependency.storage.outputs.storage_primary_connection_string}"
    AZURE_STORAGE_CONTAINER: "${local.source_vars.locals.name}"
    EVENT_HUB_CONN_STR: "${dependency.ehns.outputs.default_primary_connection_string};EntityPath=${local.source_vars.locals.name}"
    EVENT_HUB_CONSUMER_GROUP: "segway"
    # EVENT_HUB_TRANSPORT_TYPE: "AmqpOverWebsocket"  
YAML
  )

  ignoreDifferences = [
  ]
}
