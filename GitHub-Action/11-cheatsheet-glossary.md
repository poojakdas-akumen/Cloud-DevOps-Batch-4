# Chapter 11 · Cheat Sheet & Glossary

[🏠 Index](README.md)

---

## Quick Reference Cheat Sheet

### Structure

```yaml
name: <workflow name>
on: <trigger(s)>
jobs:
  <job-id>:
    runs-on: <runner>
    needs: <other-job>        # optional dependency
    strategy:
      matrix: { ... }         # optional matrix
    env: { ... }              # optional job vars
    steps:
      - uses: <owner/repo@version>
        with: { ... }
      - run: <shell command>
        env: { ... }
```

### Triggers

| Trigger | Fires when |
|---------|-----------|
| `push` | Commits pushed to matching branches/tags |
| `pull_request` | PR opened / updated / reopened |
| `schedule` | On a cron timer (UTC, default branch) |
| `workflow_dispatch` | Manually via "Run workflow" button |

### Common expressions

| Expression | Meaning |
|-----------|---------|
| `${{ secrets.NAME }}` | A repository/org secret |
| `${{ vars.NAME }}` | A repository/org variable |
| `${{ inputs.NAME }}` | A `workflow_dispatch` input |
| `${{ matrix.NAME }}` | Current matrix value |
| `${{ github.sha }}` | Triggering commit SHA |
| `${{ github.ref }}` | Branch/tag reference |
| `${{ needs.JOB.outputs.X }}` | Output from a dependency job |

### Runners

| `runs-on:` | Machine |
|-----------|---------|
| `ubuntu-latest` | Linux |
| `windows-latest` | Windows |
| `macos-latest` | macOS |
| `self-hosted` | Your own VM |

### Useful CLI

```bash
# create workflow folder
mkdir -p .github/workflows

# create an Azure service principal
az ad sp create-for-rbac --name gh-actions --role contributor \
  --scopes /subscriptions/<id>/resourceGroups/<rg> --sdk-auth

# register a self-hosted runner
./config.sh --url https://github.com/<org>/<repo> --token <token>
./run.sh
```

---

## Glossary

| Term | Definition |
|------|-----------|
| **Workflow** | An automated process defined in a `.yml` file under `.github/workflows/`. |
| **Event** | A repository activity that triggers a workflow (push, PR, schedule, etc.). |
| **Job** | A set of steps that execute on the same runner. Jobs run in parallel by default. |
| **Step** | An individual task within a job — either a `run` command or a `uses` action. |
| **Action** | A reusable, packaged unit of work referenced with `uses:`. |
| **Runner** | The server (GitHub-hosted or self-hosted) that executes a job. |
| **Marketplace** | GitHub's catalog of publishable, reusable actions. |
| **Secret** | An encrypted, masked value for sensitive data. |
| **Variable** | A plain-text configuration value. |
| **Matrix** | A strategy that expands one job into many across combinations of values. |
| **Artifact** | Files produced by a job and saved for download or later jobs. |
| **Service Principal** | An Azure identity that GitHub Actions uses to authenticate. |
| **OIDC** | OpenID Connect — issues short-lived tokens instead of stored secrets. |
| **Self-hosted runner** | A machine you provide and manage to run jobs (e.g. an Azure VM). |

---

> **End of guide.** For the official documentation, see <https://docs.github.com/actions>.

|  | |
|---|---|
| [← Hands-On Lab](10-hands-on-lab.md) | [🏠 Index](README.md) |
