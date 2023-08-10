# hosting-azure-aks

## Workstation Setup

* Install [terraform](https://developer.hashicorp.com/terraform/downloads)
* Install [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
* Install [kubelogin](https://azure.github.io/kubelogin/install.html)
* Install [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* Install [k8s cli aka kubectl](https://kubernetes.io/docs/tasks/tools/)
* Open a new non elevated command prompt and confirm each utility is available in the path

```
terraform --help
terragrunt --help
kubelogin --help
az --help
kubectl --help
```

## Required Access

* The user executing this setup process will require the rights to create a security group in Azure Active Directory
* The rights to create resources including resource groups in Azure
* The ability to connect to the required azure endpoints
* The ability to use git and access github.com
* The ability to access registry.terraform.io

## Setup State

* Create a Resource Group to contain the terraform state storage account
* Create a storage account with versioning enabled
* Create a container in the storage account named "tfstate"

## Configure

* Rename `deployments/*.template.yaml` to remove `.template`
* Update value files per comments in template
* If conditional access is in use aquire needed roles
* From a command prompt authenticate to azure `az login`
* `cd` to the `deployments/prod` directory
* Deploy `terragrunt run-all apply --terragrunt-non-interactive`

## Post deployment

* Configure diagnostic settings for azure resources to use the created azure eventhub
* Configure activity logging settings for AzureAD to use the created azuread eventhub
* Configure defender and intune to the respective defender and intune hubs
