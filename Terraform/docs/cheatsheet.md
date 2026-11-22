# Terraform on Azure — Cheat Sheet

## Core workflow
```bash
terraform init                              # providers, modules, backend
terraform init -backend-config=backend.hcl  # partial backend config
terraform init -migrate-state               # move state to new backend
terraform init -upgrade                     # newer provider versions
terraform fmt -recursive                    # format all files
terraform validate                          # syntax + references
terraform plan -out=tfplan                  # preview + save
terraform apply tfplan                      # apply saved plan
terraform apply -refresh-only               # sync state with reality (detect drift)
terraform destroy                           # delete everything
terraform output -raw web_app_url           # one output, no quotes
terraform console                           # try expressions interactively
```

## State
```bash
terraform state list
terraform state show module.web_app.azurerm_linux_web_app.this
terraform state mv <old-address> <new-address>
terraform state rm <address>                # forget, don't delete
terraform force-unlock <LOCK_ID>
```

## Workspaces
```bash
terraform workspace list | new dev | select dev | show | delete dev
```
In code: `terraform.workspace` · azurerm blob name: `<key>env:<workspace>`

## Import
```hcl
import {
  to = azurerm_resource_group.legacy
  id = "/subscriptions/<sub>/resourceGroups/rg-legacy"
}
```
```bash
terraform plan -generate-config-out=generated.tf
terraform import azurerm_resource_group.legacy /subscriptions/<sub>/resourceGroups/rg-legacy   # classic
az resource show --ids <id>        # check an ID
az group show --name <rg> --query id --output tsv
```

## HCL quick reference
```hcl
var.name                         # variable
local.name                       # local
module.network.app_subnet_id     # module output
data.azurerm_client_config.current.subscription_id
"rg-${var.env}"                  # interpolation
var.env == "prod" ? "P0v3" : "B1"            # conditional
[for s in var.list : upper(s)]               # for expression (list)
{ for k, v in var.map : k => lower(v) }      # for expression (map)
merge(local.tags, { env = "dev" })           # merge maps
lookup(local.cfg, "dev", {})                 # map lookup with default
toset(["a", "b"])                             # for for_each
```

## Plan symbols
`+` create · `~` update in place · `-/+` replace · `-` destroy · `<=` read

## Terragrunt
```bash
terragrunt plan | apply | destroy | output
terragrunt run --all plan        # all units under current folder
terragrunt run --all apply
terragrunt run --all destroy
terragrunt dag graph
```
```hcl
include "root" { path = find_in_parent_folders("root.hcl") }
terraform { source = "../../../modules//network" }
dependency "rg" { config_path = "../resource-group" }
inputs = { resource_group_name = dependency.rg.outputs.name }
```

## Azure auth env vars
| Variable | Use |
|---|---|
| `ARM_SUBSCRIPTION_ID` | required by azurerm v4 |
| `ARM_TENANT_ID`, `ARM_CLIENT_ID` | service principal / OIDC |
| `ARM_CLIENT_SECRET` | SP with secret (avoid; prefer OIDC) |
| `ARM_USE_OIDC=true` | GitHub Actions / Azure Pipelines federated login |

## Common errors
| Error | Fix |
|---|---|
| `subscription ID could not be determined` | `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)` |
| `StorageAccountAlreadyTaken` | storage names are global — change the suffix |
| `Error acquiring the state lock` | someone else is running; wait (or `force-unlock` a stale lock) |
| `Backend initialization required` | run `terraform init` (again) |
| `Module not installed` | `terraform init` after adding a module |
| `AuthorizationFailed ... roleAssignments/write` | you're Contributor, not Owner → `assign_storage_role = false` |
| `resource already exists - to be managed via Terraform this resource needs to be imported` | use an `import` block |
