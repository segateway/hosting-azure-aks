# hosting-azure-aks

## Setup Deployment Environment

The setup script uses a number of common infrastructure as code tools that must be installed to run

### Option 1 Admin Workstation

Setup a admin workstation

* Install [terraform](https://developer.hashicorp.com/terraform/downloads)
* Install [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
* Install [kubelogin](https://azure.github.io/kubelogin/install.html)
* Install [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* Install [k8s cli aka kubectl](https://kubernetes.io/docs/tasks/tools/)
* Open a new non elevated command prompt and confirm each utility is available in the path
* Download the project or a versioned release from the github repo
* CD to appropriate directory

```
terraform --help
terragrunt --help
kubelogin --help
az --help
kubectl --help
```

### Option 2 Azure Cloud Shell

* Launch [![Launch Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com/bash)
* Install terragrunt `curl -L -o ./bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.48.7/terragrunt_linux_amd64; chmod +x bin/terragrunt`
* Clone the repository `git clone https://github.com/seg-way/hosting-azure-aks.git`
* Change Directories `cd hosting-azure-aks/deployment`

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

* `cd` to the `deployments/prod` directory
* Rename `deployments/*.template.yaml` to remove `.template`

    ```bash
        cp azure_vars.template.yaml azure_vars.yaml 
        cp logging_vars.template.yaml logging_vars.yaml 
        cp segway_values.template.yaml segway_values.yaml 
    ```

* Launch editor for example VSCode `code .`
* Update value files per comments in template and save changes
* If conditional access is in use aquire needed roles
* If using a environment other than Azure Cloud Shell From a command prompt authenticate to azure `az login`
* Deploy `terragrunt run-all apply --terragrunt-non-interactiveterragrunt run-all apply --terragrunt-non-interactive`

## Post deployment

* Configure diagnostic settings for azure resources to use the created azure eventhub
* Configure activity logging settings for AzureAD to use the created azuread eventhub
* Configure defender and intune to the respective defender and intune hubs
