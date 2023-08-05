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
  logscale_vars    = read_terragrunt_config("_segway.hcl")

  # repos: |
  #  $     {yamlencode(local.logscale_vars.locals.repos)}

  base_values = yamldecode(<<YAML
args:
  - -e
podAnnotations:
  reloader.stakater.com/auto: "true"
secret:
  # Specifies whether a service account should be created
  create: true
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  url: ${local.logscale_vars.locals.url}

YAML
  )

  merged_values = merge(local.base_values, {
  "config" = { "syslogng" = local.logscale_vars.locals.syslogng } })
}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../k8s/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../argocd/projects/segway",
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
  name = "ls-cloud"


  repository = "https://seg-way.github.io/charts"

  release          = "ls-cloud"
  chart            = "segway-sys-dest-logscale"
  chart_version    = "2.0.0"
  namespace        = "seg-way"
  create_namespace = true
  project          = "segway"
  skipCrds         = false


  values = local.merged_values

  ignoreDifferences = [
  ]
}
