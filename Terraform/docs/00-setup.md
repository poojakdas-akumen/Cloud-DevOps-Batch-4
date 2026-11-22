# Day 0 — Setup (do this before Day 1)

Every student needs these four tools and one Azure subscription.

| Tool | Why | Check |
|---|---|---|
| Terraform (1.9 or newer) | The IaC engine | `terraform version` |
| Azure CLI | Login to Azure; Terraform uses this login | `az version` |
| Terragrunt | Day 5 | `terragrunt --version` |
| VS Code + "HashiCorp Terraform" extension | Syntax highlight, autocomplete | — |

## 1. Install Terraform

**Ubuntu / WSL**
```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Windows**
```powershell
winget install --id Hashicorp.Terraform
```

**macOS**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## 2. Install Azure CLI

```bash
# Ubuntu / WSL
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Windows
winget install --id Microsoft.AzureCLI
# macOS
brew install azure-cli
```

## 3. Install Terragrunt (needed on Day 5)

Download the binary for your OS from the Terragrunt GitHub releases page, then:
```bash
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
terragrunt --version
```
(macOS: `brew install terragrunt` · Windows: `winget install --id Gruntwork.Terragrunt`)

## 4. Log in to Azure

```bash
az login                                   # opens the browser
az account list --output table             # see your subscriptions
az account set --subscription "<name-or-id>"
az account show --output table             # confirm
```

## 5. Tell Terraform which subscription to use

The azurerm provider **v4** requires a subscription ID. The easiest way is an environment variable:

```bash
# Linux / macOS / WSL
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"

# Windows PowerShell
$env:ARM_SUBSCRIPTION_ID = (az account show --query id --output tsv)
```

> Put the export line in `~/.bashrc` so you don't forget it every day.
> The project has a helper: `source nexpay-infra/scripts/set-azure-env.sh`

## 6. Permissions you need

| Role on subscription | What works |
|---|---|
| **Contributor** | Everything, except creating role assignments (set `assign_storage_role = false`) |
| **Owner** | Everything |

## 7. Smoke test

```bash
mkdir tf-test && cd tf-test
cat > main.tf <<'TF'
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}
provider "azurerm" {
  features {}
}
data "azurerm_client_config" "me" {}
output "subscription" { value = data.azurerm_client_config.me.subscription_id }
TF
terraform init && terraform apply -auto-approve
```
If you see your subscription ID printed — you are ready.

## Cost warning 💰

Everything in this course is small (Basic App Service plans, LRS storage). Still:
**run `terraform destroy` at the end of every lab.** The `prod` workspace uses a Premium v3 plan — deploy it for the demo, then destroy it the same day.
