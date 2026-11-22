# Chapter 04 · Triggers — `push`, `PR`, `schedule`, `workflow_dispatch`

[🏠 Index](README.md)

---

The `on:` key defines **when** a workflow runs. These are the four you'll use most.

## `push` — the classic CI trigger

Runs whenever commits are pushed to matching branches (or tags).

```yaml
on:
  push:
    branches: [main, develop]     # only these branches
    paths: ['src/**']             # only when files under src/ change (optional)
    tags: ['v*']                  # also run on version tags like v1.2.0 (optional)
```

## `pull_request` — test before merging

Runs when a PR is opened, updated (new commits), or reopened. This is what puts the green ✓ / red ✗ on the pull request.

```yaml
on:
  pull_request:
    branches: [main]              # PRs targeting main
    types: [opened, synchronize, reopened]   # default set (optional)
```

> **Tip:** Use `pull_request` (not `push`) to gate merges. Combine with branch protection rules so a PR can't merge unless the workflow passes.

## `schedule` — cron-based runs

Runs on a timer using POSIX cron syntax. Great for nightly builds, cleanups, and reports.

```yaml
on:
  schedule:
    - cron: '0 2 * * *'     # every day at 02:00 UTC
```

**Cron format:** `minute hour day-of-month month day-of-week`

```
┌───────── minute (0 - 59)
│ ┌─────── hour (0 - 23)
│ │ ┌───── day of month (1 - 31)
│ │ │ ┌─── month (1 - 12)
│ │ │ │ ┌─ day of week (0 - 6, Sunday = 0)
│ │ │ │ │
0 2 * * *
```

| Cron | Meaning |
|------|---------|
| `0 2 * * *` | Every day at 2 AM UTC |
| `*/15 * * * *` | Every 15 minutes |
| `0 9 * * 1` | Every Monday at 9 AM UTC |
| `0 0 1 * *` | First day of every month |

> **Note:** Schedules always run in **UTC**, and only on the **default branch**. They may be delayed a few minutes during peak load.

## `workflow_dispatch` — manual trigger

Adds a **"Run workflow"** button in the Actions tab so you (or teammates) can start it by hand. You can even collect inputs.

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options: [staging, production]
```

Access the input later with `${{ inputs.environment }}`.

## Combining triggers

A single workflow can respond to several events:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:
```

---

|  | |
|---|---|
| [← Workflow YAML Syntax](03-workflow-syntax.md) | [Next → The Actions Marketplace](05-marketplace.md) |
