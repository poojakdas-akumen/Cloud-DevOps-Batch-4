# Remote state in Azure Blob Storage.
# Fill in your values (from nexpay-infra/bootstrap output), then:
#   terraform init            (fresh folder)
#   terraform init -migrate-state   (if you already had a local state)
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nexpay-tfstate"
    storage_account_name = "sttfnexpayXXXXXX"
    container_name       = "tfstate"
    key                  = "labs/day2/<your-name>.tfstate"
  }
}
