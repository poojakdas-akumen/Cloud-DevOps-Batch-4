# Day 3 — Modules: Reusable Infrastructure Components

**Goal:** turn copy-pasted code into reusable building blocks and assemble the NexPay platform from them.

---

## 1. What is a module?

A module is simply **a folder of `.tf` files**. You've already written one — every folder you ran `terraform apply` in is the **root module**. A **child module** is a folder you call from another folder.

Think of it as a function:

| Programming | Terraform module |
|---|---|
| function parameters | `variable` blocks (inputs) |
| function body | resources |
| return value | `output` blocks |
| calling the function | `module "x" { source = ... }` |

## 2. Why modules?

Without modules, dev/staging/prod each have 300 lines of the same VNet + NSG + subnet code. A security fix = 3 edits, and one gets forgotten.

With modules:
- **Write once, use many times** (DRY: Don't Repeat Yourself)
- **Standards built in** — every storage account gets TLS 1.2, no public blobs, versioning
- **Simple for users** — they give 5 inputs instead of learning 40 arguments
- **Tested and versioned** like software

## 3. Module structure

```
modules/storage-account/
├── main.tf        # resources
├── variables.tf   # inputs
├── outputs.tf     # outputs
├── versions.tf    # required providers (no provider "azurerm" {} block here!)
└── README.md      # how to use it
```

> ⚠️ Child modules declare `required_providers` but **never** contain a `provider "azurerm" {}` block. The root module configures the provider; modules inherit it.

## 4. Building a module — step by step (storage-account)

**Inputs** (`variables.tf`) — with validation so mistakes fail early:
```hcl
variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase letters/numbers."
  }
}

variable "replication_type" {
  type    = string
  default = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.replication_type)
    error_message = "Must be LRS, ZRS, GRS or GZRS."
  }
}

variable "containers" {
  type    = list(string)
  default = []
}
```

**Resources** (`main.tf`) — the security baseline is **not optional** for users:
```hcl
resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  blob_properties {
    versioning_enabled = true
  }
  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
```
> Naming convention: when a module has one main resource, call it `this`.

**Outputs** (`outputs.tf`) — the only things the caller can see:
```hcl
output "id"   { value = azurerm_storage_account.this.id }
output "name" { value = azurerm_storage_account.this.name }
```

## 5. Calling a module

```hcl
module "storage" {
  source              = "../modules/storage-account"   # where the module lives
  name                = "stnexpaydevab12cd"
  resource_group_name = module.rg.name                 # output of ANOTHER module
  location            = module.rg.location
  replication_type    = "LRS"
  containers          = ["invoices", "receipts"]
}

output "storage_name" {
  value = module.storage.name                          # module.<NAME>.<OUTPUT>
}
```
After adding or changing a `module` block's `source`, run **`terraform init`** again.

## 6. Module sources

| Source | Example | Use for |
|---|---|---|
| Local path | `"../modules/network"` | same repo (this course) |
| Terraform Registry | `"Azure/avm-res-storage-storageaccount/azurerm"` + `version = "~> 0.5"` | public, community/Microsoft modules |
| Git | `"git::https://github.com/org/tf-modules.git//network?ref=v1.2.0"` | company module library |

- `//network` = sub-folder inside the repo.
- `?ref=v1.2.0` = **pin a tag**. Never use a moving branch for prod.
- **Azure Verified Modules (AVM)** are Microsoft's official Terraform modules — search "avm-res-" on the registry. Great for production; our hand-made modules are for learning how modules work.

## 7. Module composition — the NexPay platform

```
                       root module (nexpay-infra/terraform)
                                   │
     ┌─────────────────┬───────────┴─────────┬──────────────────┐
     ▼                 ▼                     ▼                  ▼
 module "rg"     module "network"      module "storage"   module "web_app"
 resource-group   VNet, 2 subnets,     storage account,   App Service plan,
                  NSG                  containers         Linux web app,
     │                 │                     │            managed identity
     └── name ────────►├──── app_subnet_id ─────────────────►│
                       │                     └── name ──────►│ (app settings)
                                                             │
                         azurerm_role_assignment: web app identity ──► Storage Blob Data Contributor
```

From `nexpay-infra/terraform/main.tf`:
```hcl
module "rg" {
  source   = "../modules/resource-group"
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "../modules/network"
  name_prefix         = local.name_prefix
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = local.config.address_space
  app_subnet_prefix   = local.config.app_subnet_prefix
  data_subnet_prefix  = local.config.data_subnet_prefix
  tags                = local.common_tags
}

module "web_app" {
  source    = "../modules/web-app"
  name      = "app-${local.name_prefix}-${local.suffix}"
  subnet_id = module.network.app_subnet_id      # output of network → input of web_app
  # ...
}
```
Terraform sees `module.network.app_subnet_id` inside `module.web_app` and automatically builds the network first.

## 8. `count` and `for_each` on modules

```hcl
variable "regions" {
  default = ["centralindia", "southindia"]
}

module "rg" {
  for_each = toset(var.regions)
  source   = "../modules/resource-group"
  name     = "rg-nexpay-${each.value}"
  location = each.value
}

output "rg_ids" {
  value = { for k, m in module.rg : k => m.id }
}
```

## 9. Module best practices

- One module = one job (network, storage, web app). Not "everything-module".
- Every variable has `description` and `type`; add `validation` for common mistakes.
- Security defaults inside the module; don't expose settings you never want changed.
- Output IDs and names that callers will need.
- Version modules (Git tags) and pin them.
- Write a README with an example.

---

## 🧪 Lab 3 — Build with modules

**Part A — read the modules** (`nexpay-infra/modules/`). For each one, write down: inputs, outputs, and the security settings it enforces.

**Part B — use them in a scratch folder**
```bash
mkdir -p ~/lab3 && cd ~/lab3
```
Create `main.tf`:
```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
provider "azurerm" {
  features {}
}

locals {
  me = "manoop"            # <-- your name
}

module "rg" {
  source   = "<path-to>/nexpay-infra/modules/resource-group"
  name     = "rg-lab3-${local.me}"
  location = "centralindia"
}

module "storage" {
  source              = "<path-to>/nexpay-infra/modules/storage-account"
  name                = "stlab3${local.me}01"
  resource_group_name = module.rg.name
  location            = module.rg.location
  containers          = ["uploads"]
}

output "storage" {
  value = module.storage.name
}
```
```bash
terraform init && terraform apply
```

**Try this:**
1. Pass `replication_type = "XYZ"` → read the validation error.
2. Name the RG `lab3-manoop` (no `rg-`) → validation error from the resource-group module.
3. Add the `network` module and pass `module.rg.name` into it.
4. Add a second storage module call with a different name — no copy-paste of resource code needed.
5. `terraform destroy`.

## ✅ Day 3 recap
- Module = folder with inputs (variables), logic (resources), outputs.
- Call with `module "x" { source = ... }`, read outputs with `module.x.output`.
- Sources: local, registry (pin `version`), git (pin `?ref=`).
- Root module configures providers; child modules only declare `required_providers`.

## ❓ Quick quiz
1. Why should a child module not contain `provider "azurerm" {}`?
2. How does one module use another module's output?
3. What does `?ref=v1.2.0` do in a git source?
4. What command must you run after adding a new module block?
