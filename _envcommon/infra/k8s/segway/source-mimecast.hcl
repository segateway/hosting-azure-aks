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
  source = "tfr:///segateway/argocd-applicationset/kubernetes?version=1.0.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  segway_values = yamldecode(file(find_in_parent_folders("segway_values.yaml")))
  type          = basename(abspath("${get_terragrunt_dir()}/.."))
}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/k8s/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../../../infra/k8s-system/argocd/projects/segway",
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
  name = "${local.type}"


  repository = "https://segateway.github.io/charts"

  release          = "${local.type}"
  chart            = "segateway-source-mimecast"
  chart_version    = "v1.0.3"
  namespace        = "segateway"
  create_namespace = true
  project          = "segateway"
  skipCrds         = false


  values = yamldecode(<<YAML
args:
  - -e
resources:
  requests:
    cpu: 100m
    memory: 64Mi  
podAnnotations:
  reloader.stakater.com/auto: "true"
storage:
  storageClassName: azurefile-csi
nexthop:
    name: ls-cloud-segateway-destination-logscale
secret:
  data:
    MIMECAST_CLIENT_ID: ${local.segway_values.config.mimecast.client_id}
    MIMECAST_CLIENT_SECRET: ${local.segway_values.config.mimecast.secret_id}
    MIMECAST_HOST: ${local.segway_values.config.mimecast.host}
    MIMECAST_TYPE: "${local.type}"    
YAML
  )

  ignoreDifferences = [
  ]
}
