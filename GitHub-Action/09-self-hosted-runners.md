# Chapter 09 · Self-Hosted Runners on Azure VMs

[🏠 Index](README.md)

---

GitHub-hosted runners are convenient, but sometimes you need your own machine — for **private-network access**, **custom hardware** (GPU, more RAM), **specialized software**, or **persistent caches**. Enter **self-hosted runners**.

## GitHub-hosted vs Self-hosted

| | GitHub-hosted | Self-hosted |
|-|---------------|-------------|
| **Setup** | None — ready to use | You provision & register the machine |
| **Maintenance** | GitHub patches everything | You patch & secure it |
| **Environment** | Fresh VM every run | Persists between runs (faster, but dirtier) |
| **Network** | Public internet only | Can reach private VNet, databases, on-prem |
| **Hardware** | Fixed sizes | Any CPU / GPU / RAM you want |
| **Billing** | Per-minute | You pay for the VM (Azure) |
| **Best for** | Most public/standard work | Private resources, heavy or custom builds |

## When to choose self-hosted

- Your pipeline needs to reach a **private Azure database** or VNet-isolated resource.
- You need **GPUs** or large machines for ML / heavy builds.
- You want **pre-installed tools** and warm caches for speed.
- Compliance requires builds to run **inside your own network**.

## Step 1 — Provision an Azure VM

```bash
az vm create \
  --resource-group my-rg \
  --name runner-vm \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys
```

## Step 2 — Register the runner on the VM

Get the registration token from: Repo → Settings → Actions → Runners → **New self-hosted runner**. Then SSH into the VM and run:

```bash
# on the Ubuntu VM
mkdir actions-runner && cd actions-runner

# download the runner package
curl -o actions-runner-linux.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.xxx/actions-runner-linux-x64.tar.gz

# extract it
tar xzf actions-runner-linux.tar.gz

# configure it against your repo
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO \
  --token YOUR_RUNNER_TOKEN

# start it
./run.sh
```

You should see:

```
√ Connected to GitHub
Listening for Jobs...
```

## Step 3 — Run it as a service (so it survives reboots)

Instead of `./run.sh` in a terminal, install it as a background service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

## Step 4 — Target it from a workflow

Simply set `runs-on: self-hosted`:

```yaml
jobs:
  build:
    runs-on: self-hosted        # uses YOUR Azure VM
    steps:
      - uses: actions/checkout@v4
      - run: ./build.sh
```

You can also target by **labels** for finer control:

```yaml
runs-on: [self-hosted, linux, gpu]
```

## Security warnings

> ⚠️ **Never use self-hosted runners on public repositories.** A malicious PR could run arbitrary code on your machine and inside your network.
> - Keep the VM patched and isolated.
> - Use ephemeral runners (fresh per job) where possible.
> - Restrict the service principal / network access to least privilege.

---

|  | |
|---|---|
| [← Deploying to Azure](08-deploy-azure.md) | [Next → Hands-On Lab](10-hands-on-lab.md) |
