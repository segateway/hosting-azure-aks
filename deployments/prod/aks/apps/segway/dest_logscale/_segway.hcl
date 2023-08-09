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
        name  = "iaas-microsoft-azure"
        token = "ba7f4777-be75-4709-bd41-9edb82febfa0"
      },
      {
        name  = "saas-microsoft-azuread"
        token = "9812f04e-efa3-4621-aea4-ffb369a826c4"
      },
      {
        name  = "saas-microsoft-defender"
        token = "44d68003-5ded-4aed-acbf-9bcc2479756f"
      },
      {
        name  = "saas-microsoft-intune"
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
          "iaas-microsoft-azure"
        ]
        template = "t_logscale_parsed"
        tags = [
          {
            name : "vendor"
            value : "microsoft"
          },
          {
            name : "type"
            value : "azure"
          }
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "azuread"
        filters = [
          "filter(f_azuread)"
        ]
        destinations = [
          "saas-microsoft-azuread"
        ]
        template = "t_logscale_parsed"
        tags = [
          {
            name : "vendor"
            value : "microsoft"
          },
          {
            name : "type"
            value : "azuread"
          }
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "defender"
        filters = [
          "filter(f_defender)"
        ]
        destinations = [
          "saas-microsoft-defender"
        ]
        template = "t_logscale_parsed"
        tags = [
          {
            name : "vendor"
            value : "microsoft"
          },
          {
            name : "type"
            value : "microsoft365"
          }
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "intune"
        filters = [
          "filter(f_intune)"
        ]
        destinations = [
          "saas-microsoft-intune"
        ]
        template = "t_logscale_parsed"
        tags = [
          {
            name : "vendor"
            value : "microsoft"
          },
          {
            name : "type"
            value : "intune"
          }
        ]
        flags = ["catchall", "final"]
      },
      {
        name = "fallback"
        destinations = [
          "app-segway-fallback"
        ]
        tags = [
          {
            name : "vendor"
            value : "segway"
          },
          {
            name : "type"
            value : "unknown"
          }
        ]
        flags = ["catchall", "fallback", "final"]
      }
    ]
  }
}