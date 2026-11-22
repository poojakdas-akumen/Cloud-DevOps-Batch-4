# Partial backend configuration.
# The real values live in backend.hcl (not hard-coded, easy to change per team/subscription):
#   terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {}
}
