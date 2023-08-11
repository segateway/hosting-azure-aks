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
  source = "tfr:///seg-way/argocd-applicationset/kubernetes?version=1.0.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {


}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../k8s/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../argocd/projects/common",
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
  name = "logging-operator"

  repository = "https://kube-logging.github.io/helm-charts"


  release          = "logging-operator"
  chart            = "logging-operator"
  chart_version    = "4.2.2"
  namespace        = "logging-operator"
  create_namespace = true
  project          = "common"
  skipCrds         = false

  values = yamldecode(<<YAML
fullnameOverride: logging-operator
resources:
  requests: 
    cpu: 50m
    memory: 70Mi
watchNamespace: logging
spec:
  containerOverrides:
    image: ghcr.io/kube-logging/eventrouter:latest
YAML
  )
}
