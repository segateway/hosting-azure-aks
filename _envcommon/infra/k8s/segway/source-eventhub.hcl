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


  hub = yamldecode(file(find_in_parent_folders("hub.yaml")))
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
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../../../../infra/k8s-system/argocd/projects/segway",
    "${get_terragrunt_dir()}/../consumergroup",
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
  name = "eh-${local.hub.name}"


  repository = "https://segateway.github.io/charts"

  release          = "eh-${local.hub.name}"
  chart            = "segateway-source-azure-eventhub"
  chart_version    = "v3.0.1"
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
  maxReplicas: 3
  unprocessedEventThreshold: 5
podAnnotations:
  reloader.stakater.com/auto: "true"

nexthop:
    name: ls-cloud-segateway-destination-logscale
config:
  data:
    vendor: microsoft
    product: ${local.hub.name}
    appparser: microsoft-${local.hub.name}
  startingPosition: -1
secret:
  data:
    AZURE_STORAGE_CONN_STR: "${dependency.storage.outputs.storage_primary_connection_string}"
    AZURE_STORAGE_CONTAINER: "${local.hub.name}"
    AZURE_STORAGE_CUSTOM_ENDPOINT: storage-cluster-blob.privatelink.blob.core.windows.net
    EVENT_HUB_CONN_STR: "${dependency.ehns.outputs.default_primary_connection_string};EntityPath=${local.hub.name}"
    EVENT_HUB_CONSUMER_GROUP: "segway"
    # EVENT_HUB_TRANSPORT_TYPE: "AmqpOverWebsocket"  
    # EVENT_HUB_CUSTOM_ENDPOINT: sb://eventhubnamespace.privatelink.servicebus.windows.net
YAML
  )

  ignoreDifferences = [
  ]
}
