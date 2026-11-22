# Day 4 — Workspaces for Environments & Importing Existing Azure Resources

**Goal:** deploy dev / staging / prod from one codebase using workspaces, and bring "ClickOps" resources under Terraform control.

---

# Part A — Terraform Workspaces

## 1. The problem

NexPay needs 3 environments. Same architecture, different sizes:

| | dev | staging | prod |
|---|---|---|---|
| VNet | 10.10.0.0/16 | 10.20.0.0/16 | 10.30.0.0/16 |
| App Service SKU | B1 | B1 | P0v3 |
| Always On | no | yes | yes |
| Storage replication | LRS | ZRS | GRS |

If all three use the **same state file**, applying dev would overwrite prod. We need **one code, separate states**.

## 2. What is a workspace?

A workspace = **a separate state file for the same code**. Every folder starts with a workspace called `default`.

```bash
terraform workspace list           # * marks the current one
terraform workspace new dev        # create + switch
terraform workspace new staging
terraform workspace new prod
terraform workspace select dev     # switch
terraform workspace show           # print current
terraform workspace delete staging # must be empty (destroyed) and not selected
```

Where the states live:
- **Local backend:** `terraform.tfstate.d/dev/terraform.tfstate`, `terraform.tfstate.d/prod/...`
- **azurerm backend** with `key = "nexpay/app.tfstate"`: blobs `nexpay/app.tfstate` (default), `nexpay/app.tfstateenv:dev`, `nexpay/app.tfstateenv:prod`, … Open the `tfstate` container in the Portal and see them.

## 3. Using the workspace name in code

`terraform.workspace` returns the current workspace name. NexPay uses it to pick settings:

```hcl
# nexpay-infra/terraform/locals.tf
locals {
  env = terraform.workspace

  env_config = {
    dev = {
      address_space       = ["10.10.0.0/16"]
      app_sku             = "B1"
      always_on           = false
      storage_replication = "LRS"
      # ...
    }
    prod = {
      address_space       = ["10.30.0.0/16"]
      app_sku             = "P0v3"
      always_on           = true
      storage_replication = "GRS"
      # ...
    }
  }

  config      = lookup(local.env_config, local.env, local.env_config["dev"])
  name_prefix = "nexpay-${local.env}"          # nexpay-dev, nexpay-prod
}
```
```hcl
module "web_app" {
  sku_name  = local.config.app_sku             # B1 in dev, P0v3 in prod
  always_on = local.config.always_on
}
```

**Safety guard** — stop deployments to the `default` workspace:
```hcl
resource "terraform_data" "workspace_guard" {
  lifecycle {
    precondition {
      condition     = contains(keys(local.env_config), terraform.workspace)
      error_message = "Select a workspace first: terraform workspace select dev|staging|prod"
    }
  }
}
```

**Alternative style:** workspace + a tfvars file per environment:
```bash
terraform workspace select prod
terraform apply -var-file=env/prod.tfvars
```
It works, but people forget to match workspace and file. The map-in-locals approach can't mismatch.

## 4. When NOT to rely on workspaces

Workspaces share **the same backend and the same credentials**. Someone with access to dev state can also read prod state.

| Situation | Better choice |
|---|---|
| Learning, small team, same subscription | ✅ Workspaces |
| Prod in a separate subscription / strict access control | Separate folders + separate backends (or Terragrunt — Day 5) |
| Environments that differ a lot in architecture | Separate root modules |

Many companies use: **workspaces for short-lived feature/test environments**, and **separate directories/backends for prod**.

## 🧪 Lab 4A — Deploy NexPay dev and prod

```bash
cd nexpay-infra/terraform
source ../scripts/set-azure-env.sh
cp backend.hcl.example backend.hcl        # fill in storage_account_name from bootstrap
terraform init -backend-config=backend.hcl

terraform plan                            # default workspace -> guard error (expected!)

terraform workspace new dev
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
terraform output web_app_url              # open it in the browser

terraform workspace new prod
terraform plan                            # compare: P0v3, GRS, 10.30.0.0/16
```
**Try this:**
1. In the Portal, compare `rg-nexpay-dev` and `rg-nexpay-prod` tags.
2. List the blobs in the `tfstate` container. How many state files?
3. `terraform workspace select dev && terraform destroy`. Does prod still exist?
4. Try `terraform workspace delete prod` while it has resources — read the error.

---

# Part B — Importing existing Azure resources

## 5. Why import?

Real life: the company already has resources created in the Portal ("ClickOps"). You want Terraform to manage them **without deleting and re-creating** (downtime, data loss).

Import = **tell Terraform "this real Azure resource belongs to this block in my code"**. It writes the resource into the state. Nothing in Azure changes.

## 6. Step 1 — find the Azure resource ID

Every Azure resource has an ID:
```
/subscriptions/<sub-id>/resourceGroups/<rg>/providers/<Provider.Namespace>/<type>/<name>
```
```bash
az group show --name rg-legacy-manoop --query id --output tsv
az network vnet show --name vnet-legacy-manoop --resource-group rg-legacy-manoop --query id --output tsv
az resource list --resource-group rg-legacy-manoop --query "[].{name:name, id:id}" --output table
```
Each azurerm resource doc page has an **"Import"** section at the bottom showing the exact ID format.

## 7. Method 1 (modern ✅) — `import` blocks

Available since Terraform 1.5. Imports are **code**: reviewed in Git, visible in `plan`, work in pipelines.

```hcl
# import.tf
data "azurerm_client_config" "current" {}

import {
  to = azurerm_resource_group.legacy
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-legacy-manoop"
}
```
```hcl
# main.tf - must describe the resource AS IT IS in Azure
resource "azurerm_resource_group" "legacy" {
  name     = "rg-legacy-manoop"
  location = "centralindia"
  tags = {
    created_by = "portal"
  }
}
```
```bash
terraform plan     # Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
terraform apply
```
After a successful apply you can delete the `import` blocks (or keep them as documentation — they're ignored once imported).

### Let Terraform write the code for you
Don't know every setting? Keep only the `import` block and run:
```bash
terraform plan -generate-config-out=generated.tf
```
Terraform reads the real resource and writes a full `resource` block into `generated.tf`. **Review and clean it** (remove defaults, replace hard-coded IDs with references), then `apply`.

## 8. Method 2 (classic) — `terraform import` command

```bash
terraform import azurerm_resource_group.legacy \
  "/subscriptions/<sub-id>/resourceGroups/rg-legacy-manoop"
```
- Writes to state immediately — **no plan, no review**.
- You still need the `resource` block in code first.
- One resource per command.

You'll see it in old blogs and scripts. For new work, use `import` blocks.

## 9. After import — the golden rule

Run `terraform plan` and aim for **"No changes"**.

| Plan shows | Meaning | Fix |
|---|---|---|
| `~ tags` | code differs from reality | copy the real value into code (or accept the change) |
| `-/+` must be replaced | an immutable setting differs (name, location) | **fix the code** — never apply this on an imported prod resource |
| No changes ✅ | code == reality | done |

## 🧪 Lab 4B — Import (`labs/day4-import-demo`)

```bash
cd labs/day4-import-demo
./create-legacy.sh manoop                 # simulates Portal-created resources
# edit terraform.tfvars -> student_name = "manoop"
terraform init
terraform plan                            # 2 to import
terraform apply
terraform state list                      # both are now managed
terraform plan                            # No changes
```
**Try this:**
1. Delete `main.tf`, keep `import.tf` → `terraform plan -generate-config-out=generated.tf`. Read `generated.tf`.
2. In the Portal, add a tag `owner = finance` on the RG → `terraform plan`. Terraform detects the drift.
3. Change `location` in code to `southindia` → plan says replace. Why must you never apply this?
4. Clean up: `terraform destroy`.

## ✅ Day 4 recap
- Workspace = separate state for the same code; `terraform.workspace` in code.
- Blob names: `<key>env:<workspace>`.
- Workspaces share backend + credentials → strong isolation needs separate backends.
- Import = attach existing resource to code + state; nothing changes in Azure.
- Prefer `import` blocks + `-generate-config-out`; goal after import = "No changes".

## ❓ Quick quiz
1. Where is the state of workspace `prod` stored in the azurerm backend?
2. Why is the guard against the `default` workspace useful?
3. Difference between `import {}` blocks and `terraform import`?
4. After an import, plan shows `-/+`. What do you do?
