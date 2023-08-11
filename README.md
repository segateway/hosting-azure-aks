# hosting-azure-aks

## Required Access

* The user executing this setup process will require the rights to create a security group in Azure Active Directory
* The rights to create resources including resource groups in Azure
* The ability to connect to the required azure endpoints
* The ability to use git and access github.com
* The ability to access registry.terraform.io

## Setup Deployment Environment

The default AzureShell contains all required tools except terragrunt install one time using the following procedure

* Launch [![Launch Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com/bash)
* Install terragrunt

    ```bash
    curl -L -o ./bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.48.7/terragrunt_linux_amd64; chmod +x bin/terragrunt
    ```

* Clone the repository

    ```bash
    git clone https://github.com/seg-way/hosting-azure-aks.git
    ```

## Setup State

This activity is completed one time and will be used and reused via configuration

* Launch the AzureShell using the link above
* Create a Resource Group to contain the terraform state storage account

    ```bash
    # replace "segway-state" with a meaningful name conforming to org standards
    # --tags should be modified to conform to org standards or removed
    az group create --name segway-state2 --location centralus --tags this=that apple=fruit
    ```

* Create a storage account with versioning enabled

    ```bash
    az storage account create --name orgshortnamesegwaystate --resource-group "segway-state" --tags this=that apple=fruit
    ```

* Create a container in the storage account named "tfstate"

    ```bash
    az storage container create --name tfstate --auth-mode login --account-name orgshortnamesegwaystate --public-access off
    ```

## Configure

* `cd` to the directory

    ```bash
    cd hosting-azure-aks/deployment
    ```

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
* Deploy

    ```bash
    terragrunt run-all apply --terragrunt-non-interactiveterragrunt run-all apply --terragrunt-non-interactive
    ```

## Post deployment

* Configure diagnostic settings for azure resources to use the created azure eventhub
* Configure activity logging settings for AzureAD to use the created azuread eventhub
* Configure defender and intune to the respective defender and intune hubs

## Upgrades

* Launch [![Launch Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com/bash)
* `cd` to the directory

    ```bash
    cd hosting-azure-aks
    ```

* Update the repo

    ```bash
    git pull
    ```

* `cd` to the directory

    ```bash
    cd deployment
    ```

* Compare the template files in deployments to the configured versions used previously add/remove values accordingly

* Deploy

    ```bash
    terragrunt run-all apply --terragrunt-non-interactiveterragrunt run-all apply --terragrunt-non-interactive
    ```
