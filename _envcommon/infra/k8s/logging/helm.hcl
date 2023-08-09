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

locals {

  logscale = yamldecode(file(find_in_parent_folders("logscale_vars.yaml")))

}



dependency "k8s" {
  config_path = "${get_terragrunt_dir()}/../../../k8s/"
}
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../../argocd/projects/common",
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

  name = "logging-operator-logging"

  repository = "https://kube-logging.github.io/helm-charts"

  release          = "logs"
  chart            = "logging-operator-logging"
  chart_version    = "4.2.2"
  namespace        = "logging"
  create_namespace = true
  project          = "common"

  values = yamldecode(<<EOF
nameOverride: logs
controlNamespace: logging
# errorOutputRef: logscale
# -- EventTailer config
eventTailer: 
  name: cluster
  containerOverrides:
    resources:
      requests:
        cpu: 50m
        memory: 50Mi

# -- HostTailer config
hostTailer:
  name: cluster
  workloadOverrides:
    tolerations:
      - operator: "Exists"

  systemdTailers:
    - name: host-tailer-systemd-kubelet
      disabled: false
      maxEntries: 200
      systemdFilter: "kubelet.service"
      containerOverrides:
        resources:
          requests:
            cpu: 50m
            memory: 50Mi
enableRecreateWorkloadOnImmutableFieldChange: true
clusterFlows:
  - name: k8s-infra-hosts
    spec:
      filters:
        - record_transformer:
            records:
            - cluster_name: "${dependency.k8s.outputs.name}"
      match:
      - select:
          labels:
            app.kubernetes.io/name: host-tailer
          namespaces:
            - logging
      globalOutputRefs:
        - logscale-infra-host
  - name: k8s-infra-events
    spec:
      filters:
        - record_transformer:
            records:
            - cluster_name: "${dependency.k8s.outputs.name}"
      match:
      - select:
          labels:
            app.kubernetes.io/name: event-tailer
          namespaces:
            - logging
      globalOutputRefs:
        - logscale-infra-event
  - name: k8s-infra-pods
    spec:
      filters:
        - record_transformer:
            records:
            - cluster_name: "${dependency.k8s.outputs.name}"
      match:
      - exclude:
          labels:
            app.kubernetes.io/name: event-tailer
          namespaces:
            - logging
      - exclude:
          labels:
            app.kubernetes.io/name: host-tailer
          namespaces:
            - logging          
      - select:
          namespaces:
            - argocd
      - select:
          namespaces:
            - cert-manager
      - select:
          namespaces:
            - external-dns
      - select:
          namespaces:
            - k8s-image-swapper
      - select:
          namespaces:
            - kube-node-lease
      - select:
          namespaces:
            - kube-public
      - select:
          namespaces:
            - kube-system
      - select:
          namespaces:
            - logging
      - select:
          namespaces:
            - monitoring
      - select:
          namespaces:
            - reloader
      - select:
          namespaces:
            - gatekeeper-system
      globalOutputRefs:
        - logscale-infra-pod
  - name: k8s-app-pods
    spec:
      filters:
        - record_transformer:
            records:
            - cluster_name: "${dependency.k8s.outputs.name}"
      match:
      - exclude:
          namespaces:
            - argocd
      - exclude:
          namespaces:
            - cert-manager
      - exclude:
          namespaces:
            - external-dns
      - exclude:
          namespaces:
            - k8s-image-swapper
      - exclude:
          namespaces:
            - kube-node-lease
      - exclude:
          namespaces:
            - kube-public
      - exclude:
          namespaces:
            - kube-system
      - exclude:
          namespaces:
            - logging
      - exclude:
          namespaces:
            - monitoring
      - exclude:
          namespaces:
            - gatekeeper-system        
      - exclude:
          namespaces:
            - reloader
      - select: {}
      globalOutputRefs:
        - logscale-app-pod



clusterOutputs:
  - name: logscale-infra-event
    spec:
      splunkHec:
        ca_path: 
          value: /etc/ssl/certs/
        hec_host: ${local.logscale.instance.host}
        insecure_ssl: ${local.logscale.instance.insecure}
        protocol: ${local.logscale.instance.protocol}
        hec_port: ${local.logscale.instance.port}
        hec_token:
          valueFrom:
            secretKeyRef:
              name: logscale-k8s-infra-events
              key: token
        format:
          type: json
  - name: logscale-infra-host
    spec:
      splunkHec:
        ca_path: 
          value: /etc/ssl/certs/
        hec_host: ${local.logscale.instance.host}
        insecure_ssl: ${local.logscale.instance.insecure}
        protocol: ${local.logscale.instance.protocol}
        hec_port: ${local.logscale.instance.port}
        hec_token:
          valueFrom:
            secretKeyRef:
              name: logscale-k8s-infra-hosts
              key: token
        format:
          type: json
  - name: logscale-infra-pod
    spec:
      splunkHec:
        ca_path: 
          value: /etc/ssl/certs/
        hec_host: ${local.logscale.instance.host}
        insecure_ssl: ${local.logscale.instance.insecure}
        protocol: ${local.logscale.instance.protocol}
        hec_port: ${local.logscale.instance.port}
        hec_token:
          valueFrom:
            secretKeyRef:
              name: logscale-k8s-infra-pods
              key: token
        format:
          type: json          
  - name: logscale-app-pod
    spec:
      splunkHec:
        ca_path: 
          value: /etc/ssl/certs/
        hec_host: ${local.logscale.instance.host}
        insecure_ssl: ${local.logscale.instance.insecure}
        protocol: ${local.logscale.instance.protocol}
        hec_port: ${local.logscale.instance.port}
        hec_token:
          valueFrom:
            secretKeyRef:
              name: logscale-k8s-app-pods
              key: token
        format:
          type: json          

fluentbit:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
  tolerations:
    - operator: "Exists"

fluentd:
  scaling:
    replicas: 2
  resources:
    requests:
      cpu: "100m"
      memory:  128Mi
EOF
  )

  ignoreDifferences = [
  ]
}
