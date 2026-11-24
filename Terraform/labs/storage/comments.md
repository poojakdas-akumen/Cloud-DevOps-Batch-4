az login
az account show
terraform init
terraform workspace new dev  # create dev workspaces
terraform workspace list  # verify 
terraform apply -var-file="dev.tfvars"
terraform workspace new prod
terraform workspace list
terraform apply -var-file="prod.tfvars"
terraform workspace show       # Current workspace
terraform workspace select dev  # switch between workspaces
terraform workspace select dev
terraform state list      # check the state of resource
terraform state show azurerm_storage_account.storage      
terraform destroy -var-file "dev.tfvars"