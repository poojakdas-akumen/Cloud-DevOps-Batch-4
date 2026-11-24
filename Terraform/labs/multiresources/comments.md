terraform init

terraform validate  - #terraform validate is used to check whether your Terraform configuration files are written correctly before you execute them.

terraform apply -auto-approve -   means Terraform will execute the infrastructure changes without asking you for manual confirmation.


What is Terraform State Drift?

You can answer:

State drift occurs when the Terraform state file does not match the actual infrastructure. For example, Terraform may believe a Storage Account exists because it's present in terraform.tfstate, but the resource was deleted manually in Azure. This causes errors during terraform plan or terraform apply. The issue can be fixed using commands such as terraform state rm, terraform import, or by recreating the resource.

terraform state rm azurerm_storage_account.storage