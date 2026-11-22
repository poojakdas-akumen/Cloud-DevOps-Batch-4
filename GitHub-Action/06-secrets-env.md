# Chapter 06 · Secrets and Environment Variables

[🏠 Index](README.md)

---

**Never hard-code passwords, API keys, or connection strings in your workflow files.** They'd be visible to anyone with repo access and live forever in git history. Instead, store them encrypted in GitHub and inject them at runtime.

## Where to store secrets

Repo → **Settings** → **Secrets and variables** → **Actions**

Two tabs:
- **Secrets** — encrypted, masked in logs. For sensitive values (passwords, tokens, credentials).
- **Variables** — plain text, visible. For non-sensitive config (region names, feature flags).

You can define them at three levels:

| Level | Scope |
|-------|-------|
| **Repository** | Available to all workflows in the repo |
| **Environment** | Scoped to a named environment (e.g. `production`) — can require approvals |
| **Organization** | Shared across many repos |

## Using a secret in a workflow

Reference secrets with the `${{ secrets.NAME }}` expression:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Use an API token
        run: ./deploy.sh
        env:
          API_TOKEN: ${{ secrets.API_TOKEN }}
```

> **Security:** Secrets are automatically **masked** in logs — if you accidentally `echo` one, GitHub replaces it with `***`. They are **not** passed to workflows triggered by pull requests from forks (to prevent credential theft).

## Environment variables

Non-sensitive config set with `env:`, at three possible scopes:

```yaml
env:
  GLOBAL_VAR: available-to-all-jobs      # workflow level

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      JOB_VAR: available-to-this-job     # job level
    steps:
      - name: Print vars
        env:
          STEP_VAR: available-to-this-step   # step level
        run: |
          echo "$GLOBAL_VAR"
          echo "$JOB_VAR"
          echo "$STEP_VAR"
          echo "${{ vars.MY_REPO_VARIABLE }}"   # a repo-level variable
```

## Built-in variables (`GITHUB_*`)

GitHub provides context automatically — no setup needed:

| Variable | Value |
|----------|-------|
| `${{ github.sha }}` | The commit SHA that triggered the run |
| `${{ github.ref }}` | The branch/tag ref (e.g. `refs/heads/main`) |
| `${{ github.actor }}` | Who triggered the workflow |
| `${{ github.repository }}` | `owner/repo` |
| `${{ github.run_number }}` | Incrementing run counter |
| `${{ secrets.GITHUB_TOKEN }}` | Auto-generated token to interact with the repo |

## Secrets vs Variables — quick rule

> If leaking it would be a security problem → **Secret.**
> If it's just configuration → **Variable.**

---

|  | |
|---|---|
| [← The Actions Marketplace](05-marketplace.md) | [Next → Matrix Builds](07-matrix-builds.md) |
