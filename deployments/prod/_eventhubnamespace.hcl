# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  settings = {
    sku                      = "Standard"
    auto_inflate_enabled     = true
    maximum_throughput_units = 5
    network_rulesets = {
      default_action                = "Deny"
      public_network_access_enabled = "false"
    }
  }
}