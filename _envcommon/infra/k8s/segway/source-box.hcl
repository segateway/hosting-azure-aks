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
    box_values = yamldecode(file(find_in_parent_folders("box_values.yaml")))
}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../../infra/k8s/"
}

dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../infra/k8s-system/argocd/projects/segway",
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
  name = "eh-${local.hub}"


  repository = "https://segateway.github.io/charts"

  release          = "box"
  chart            = "segway-sys-source-box-enterprise"
  chart_version    = "v1.1.11"
  namespace        = "segateway"
  create_namespace = true
  project          = "segateway"
  skipCrds         = false


  values = yamldecode(<<YAML
resources:
  requests:
    cpu: 50m
    memory: 128Mi  
podAnnotations:
  reloader.stakater.com/auto: "true"

nexthop:
    name: ls-cloud-segateway-destination-logscale
secret:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  data:
    box.json: ${jsonencode(local.box_values.boxjson)}
YAML
  )

  ignoreDifferences = [
  ]
}
