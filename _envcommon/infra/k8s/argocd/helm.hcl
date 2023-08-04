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
  source = "tfr:///terraform-module/release/helm?version=2.8.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # dns         = read_terragrunt_config(find_in_parent_folders("dns.hcl"))
  # domain_name = local.dns.locals.domain_name

  # host_name = "argocd"

}


dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../k8s/"
}

generate "provider_k8s" {
  path      = "provider_k8s.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

provider "helm" {
  kubernetes {
    host                   = "${dependency.k8s.outputs.exec_host}"
    cluster_ca_certificate = base64decode("${dependency.k8s.outputs.ca_certificate}")
    exec {
      api_version = "${dependency.k8s.outputs.exec_api}"
      command     = "${dependency.k8s.outputs.exec_command}"
      args        = ${jsonencode(dependency.k8s.outputs.exec_args)}
    }
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
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"

  app = {
    name             = "cw"
    create_namespace = true

    chart   = "argo-cd"
    version = "5.42.1"

    wait   = true
    deploy = 1
  }
  values = [<<EOF
fullnameOverride: argocd
createAggregateRoles: true

argo-cd:
  config:
    application.resourceTrackingMethod: annotation+label
redis-ha:
  enabled: false
  topologySpreadConstraints: 
    enabled: true
  redis:
    resources:
      requests:
        cpu: "1100m"
        memory: 48Mi
      # limits:
      #   cpu: "2"
      #   memory: 256Mi
  haproxy:
    resources:
      requests:
        cpu: "10m"
        memory: 96Mi
      # limits:
      #   cpu: 500m
      #   memory: 128Mi


controller:
  replicas: 1
  # pdb: 
  #   enabled: true
  #   minAvailable: 1
  #   maxUnavailable: 1
  resources:
    requests:
      cpu: 200m
      memory: 300Mi
    # limits:
    #   cpu: 2
    #   memory: 1Gi
repoServer:
  # autoscaling:
  #   enabled: true
  #   minReplicas: 2
  #   maxReplicas: 3
  # pdb: 
  #   enabled: true
  #   minAvailable: 1
  #   maxUnavailable: 1
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    # limits:
    #   cpu: 2
    #   memory: 384Mi

applicationSet:
  replicas: 1
  # pdb: 
  #   enabled: true
  #   minAvailable: 1
  #   maxUnavailable: "1"
  resources:
    requests:
      cpu: 50m
      memory: 50Mi
    # limits:
    #   cpu: 250m
    #   memory: 100Mi
server:
  # autoscaling:
  #   enabled: true
  #   minReplicas: 2
  #   maxReplicas: 3
  # pdb: 
  #   enabled: true
  #   minAvailable: 1
  #   maxUnavailable: "1"
  extraArgs:
  - --insecure
  # service:
  #   annotations:
  #     cloud.google.com/neg: '{"ingress": true}' # Creates a NEG after an Ingress is created
  # ingress:
  #   enabled: true
  #   hosts:
  #     - $x{local.host_name}.$x{local.domain_name}
  #   annotations:
  #     external-dns.alpha.kubernetes.io/hostname: $x{local.host_name}.$x{local.domain_name}
  #     networking.gke.io/managed-certificates: ops-argocd-cert-google-gke-managed-cert
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    # limits:
    #   cpu: 2
    #   memory: 256Mi
dex:
  enabled: false
  pdb: 
    enabled: true
    minAvailable: 0
    maxUnavailable: "100%"
  resources:
    requests:
      cpu: 10m
      memory: 50Mi
    # limits:
    #   cpu: 250m
    #   memory: 128Mi
notifications:
  # pdb: 
  #   enabled: true
  #   minAvailable: 0
  #   maxUnavailable: "100%"
  resources:
    requests:
      cpu: 10m
      memory: 30Mi
    # limits:
    #   cpu: 150m
    #   memory: 96Mi
global:
  logging:
    # -- Set the global logging format. Either: `text` or `json`
    format: json
  topologySpreadConstraints: 
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule    
configs:
  cm:
    resource.compareoptions: |
      # disables status field diffing in specified resource types
      ignoreAggregatedRoles: true
      ignoreResourceStatusField: all
#     admin.enabled: false
#     url: "https://$x{local.host_name}.$x{xlocal.domain_name}"
#     oidc.config: |
#       name: SSO
#       issuer: $x{dependency.sso.outputs.issuer}
#       clientID: $x{dependency.sso.outputs.application_id}
#       clientSecret: $azuread-oidc:oidc.azure.clientSecret
#       requestedIDTokenClaims:
#         groups:
#             essential: true
#       requestedScopes:
#         - openid
#         - profile
#         - email    
#   rbac:
#     policy.default: role:readonly
#     policy.csv: |
#       g, "consultant", role:admin
#       g, "tech-lead", role:admin
#     scopes: '[groups, email]'      
# notifications:
#   argocdUrl: "https://$x{local.host_name}.$x{local.domain_name}"


EOF 
  ]
}