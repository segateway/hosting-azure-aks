locals {
  url = "https://logscale-ps-inputs.gcp.logsr.life"
  syslogng = {
    filters = [
      {
        name      = "f_azure"
        condition = "tags('vendor:microsoft') and tags('product:azure');"
      },
      {
        name      = "f_azuread"
        condition = "tags('vendor:microsoft') and tags('product:azuread');"
      },
      {
        name      = "f_defender"
        condition = "tags('vendor:microsoft') and tags('product:defender');"
      },
      {
        name      = "f_intune"
        condition = "tags('vendor:microsoft') and tags('product:intune');"
      }
    ]
    repos = [
      {
        name  = "segway-iaas-microsoft-azure"
        token = "ba7f4777-be75-4709-bd41-9edb82febfa0"
      },
      {
        name  = "segway-saas-microsoft-azuread"
        token = "9812f04e-efa3-4621-aea4-ffb369a826c4"
      },
      {
        name  = "segway-saas-microsoft-defender"
        token = "44d68003-5ded-4aed-acbf-9bcc2479756f"
      },
      {
        name  = "segway-saas-microsoft-intune"
        token = "c0882e90-aa08-47e1-b8c2-42311e08d5c4"
      },
      {
        name       = "app-segway-fallback"
        token      = "9ac06d52-1f02-43fc-b49c-290f87d3d9a4"
        isCatchAll = "true"
      }
    ]
    logPaths = [
      {
        name = "azure"
        filters = [
          "filter(f_azure)"
        ]
        destinations = [
          "segway-iaas-microsoft-azure"
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "azuread"
        filters = [
          "filter(f_azuread)"
        ]
        destinations = [
          "segway-saas-microsoft-azuread"
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "defender"
        filters = [
          "filter(f_defender)"
        ]
        destinations = [
          "segway-saas-microsoft-defender"
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "intune"
        filters = [
          "filter(f_intune)"
        ]
        destinations = [
          "segway-saas-microsoft-intune"
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "fallback"
        destinations = [
          "app-segway-fallback"
        ]
        flags = ["catchall", "fallback", "final"]
      }
    ]
  }
}