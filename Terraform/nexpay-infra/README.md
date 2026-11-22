# NexPay Infrastructure (Terraform on Azure)

Production-style infrastructure for the NexPay payment platform: one set of modules, deployed two ways
(Terraform workspaces **or** Terragrunt).

## Run order

```bash
# 0. login
az login
source scripts/set-azure-env.sh

# 1. remote state storage (once per subscription)
cd bootstrap
terraform init && terraform apply
terraform output -raw backend_hcl > ../terraform/backend.hcl

# 2a. Terraform + workspaces
cd ../terraform
terraform init -backend-config=backend.hcl
terraform workspace new dev          # or: terraform workspace select dev
terraform plan -out=tfplan
terraform apply tfplan
terraform output web_app_url

# 2b. OR Terragrunt (set storage_account_name in terragrunt/root.hcl first)
cd ../terragrunt/dev
terragrunt run --all apply
```

## Clean up
```bash
cd terraform && terraform workspace select dev && terraform destroy
cd ../terragrunt/dev && terragrunt run --all destroy
# bootstrap: remove the prevent_destroy lifecycle block first, then terraform destroy
```

## Environments (workspaces)

| Setting | dev | staging | prod |
|---|---|---|---|
| VNet | 10.10.0.0/16 | 10.20.0.0/16 | 10.30.0.0/16 |
| App Service SKU | B1 | B1 | P0v3 |
| Always On | false | true | true |
| Storage replication | LRS | ZRS | GRS |

Defined in `terraform/locals.tf` → `env_config`.

## Notes
- Contributor-only accounts: set `assign_storage_role = false` (in `terraform.tfvars`).
- Storage and web app names are globally unique — a random suffix is added automatically (workspaces) or via `unique_suffix` in `env.hcl` (Terragrunt).
