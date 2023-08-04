# Set common variables for the environment. This is automatically pulled in in the root terragrunt.hcl configuration to
# feed forward to the child modules.
locals {
  location        = "EastUS"
  subscription_id = "1b0f918f-3c13-43ad-b400-436773701221"
  tenant_id       = "4d40b7e0-fca8-48d9-8fea-3d117a06b2a7"
}