# Chapter 03 · Workflow YAML Syntax — `on`, `jobs`, `steps`

[🏠 Index](README.md)

---

Every workflow is YAML with three essential building blocks. YAML is **indentation-sensitive** — use **spaces, never tabs**, and be consistent (2 spaces per level is standard).

## The anatomy of a workflow file

```yaml
name: CI Pipeline              # 1. Display name (shown in Actions tab) — optional

on:                            # 2. TRIGGER — WHEN the workflow runs
  push:
    branches: [main]

jobs:                          # 3. JOBS — WHAT work to do
  build:                       #    job id (you choose this name)
    runs-on: ubuntu-latest     #    which runner to use
    steps:                     # 4. STEPS — run in order on the runner
      - uses: actions/checkout@v4   # a reusable action
      - name: Install & test        # a named shell step
        run: |
          npm ci
          npm test
```

## The three layers explained

### `on:` — the trigger

Defines the event(s) that start the workflow. Covered in depth in [Chapter 04](04-triggers.md).

```yaml
on: push                          # shorthand: any push
# or
on:
  push:
    branches: [main, develop]     # only these branches
```

### `jobs:` — units of work

A workflow has one or more jobs. Each job:
- has a unique **id** (`build`, `test`, `deploy` — your choice),
- runs on its own **runner** (`runs-on:`),
- runs **in parallel** with other jobs unless told to wait.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps: [ ... ]

  deploy:
    needs: build          # wait for "build" to succeed first
    runs-on: ubuntu-latest
    steps: [ ... ]
```

**Runner options for `runs-on:`**

| Value | Machine |
|-------|---------|
| `ubuntu-latest` | Linux (most common, fastest, cheapest) |
| `windows-latest` | Windows Server |
| `macos-latest` | macOS (for iOS/Mac builds) |
| `self-hosted` | Your own machine — see [Chapter 09](09-self-hosted-runners.md) |

### `steps:` — ordered tasks

Steps run **sequentially** inside a job, sharing the same filesystem. There are two kinds:

```yaml
steps:
  # 1. "uses" — pull in a reusable action from the Marketplace
  - name: Check out repository
    uses: actions/checkout@v4

  # 2. "run" — execute shell commands directly
  - name: Build the project
    run: |
      npm ci
      npm run build
```

| Keyword | Purpose |
|---------|---------|
| `name:` | Human-readable label (optional but recommended) |
| `uses:` | Reference a reusable action (`owner/repo@version`) |
| `run:` | Run shell command(s); `|` allows multiple lines |
| `with:` | Pass input parameters to a `uses:` action |
| `env:` | Set environment variables for the step |

## A complete, real CI example

```yaml
name: Node.js CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test
```

---

|  | |
|---|---|
| [← Where Files Live](02-file-path.md) | [Next → Triggers](04-triggers.md) |
