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
  hub = basename(abspath("${get_terragrunt_dir()}/.."))
}

dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/k8s/"
}
dependency "storage" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/storage/account"
}
dependency "ehns" {
  config_path = "${get_terragrunt_dir()}/../../../../../infra/eventhub-namespace/namespace/"
}
dependency "consumergroup" {
  config_path = "${get_terragrunt_dir()}/../consumergroup"
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
  name = "eh-${local.hub}"


  repository = "https://segateway.github.io/charts"

  release          = "eh-${local.hub}"
  chart            = "segateway-source-azure-eventhub"
  chart_version    = "v3.0.2"
  namespace        = "segateway"
  create_namespace = true
  project          = "segateway"
  skipCrds         = false


  values = yamldecode(<<YAML
args:
  - -e
resources:
  requests:
    cpu: 200m
    memory: 128Mi  
autoscaling: 
  enabled: false
  keda: true
  maxReplicas: 6
  unprocessedEventThreshold: 1000
podAnnotations:
  reloader.stakater.com/auto: "true"

nexthop:
    name: ls-cloud-segateway-destination-logscale
config:
  data:
    vendor: microsoft
    product: ${local.hub}
    appparser: microsoft-${local.hub}
  startingPosition: -1
secret:
  data:
    AZURE_STORAGE_CONN_STR: "${dependency.storage.outputs.storage_primary_connection_string}"
    AZURE_STORAGE_CONTAINER: "${local.hub}"
    EVENT_HUB_CONN_STR: "${dependency.consumergroup.outputs.connection_string}"
    EVENT_HUB_CONSUMER_GROUP: "${dependency.consumergroup.outputs.name}"
    # EVENT_HUB_TRANSPORT_TYPE: "AmqpOverWebsocket"  
YAML
  )

  ignoreDifferences = [
  ]
}
