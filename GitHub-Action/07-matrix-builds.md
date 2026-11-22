# Chapter 07 · Matrix Builds — Multi-Version Testing

[🏠 Index](README.md)

---

A **matrix** lets one job definition expand into **many parallel runs** across different versions, operating systems, or any dimension you choose. Perfect for testing that your code works everywhere.

## The problem it solves

You want to test your app on Node 18, 20, and 22, across both Ubuntu and Windows. Writing 6 near-identical jobs by hand is painful. A matrix does it in a few lines.

## Basic syntax

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm ci
      - run: npm test
```

## What this expands to

`2 operating systems × 3 Node versions =` **6 parallel jobs**:

| | Node 18 | Node 20 | Node 22 |
|-|---------|---------|---------|
| **ubuntu-latest** | ✓ | ✓ | ✓ |
| **windows-latest** | ✓ | ✓ | ✓ |

All six run **at the same time**, so you get full coverage without waiting six times as long.

## Advanced controls

```yaml
strategy:
  fail-fast: false          # don't cancel other jobs if one fails
  max-parallel: 3           # cap concurrent jobs (default: as many as possible)
  matrix:
    node: [18, 20, 22]
    include:                # add an extra specific combination
      - node: 23
        experimental: true
    exclude:                # remove a specific combination
      - os: windows-latest
        node: 18
```

| Option | Effect |
|--------|--------|
| `fail-fast: false` | Let every combination finish even if one fails (see all failures at once) |
| `max-parallel: N` | Limit how many run simultaneously |
| `include:` | Add extra one-off combinations |
| `exclude:` | Drop specific combinations you don't need |

## Why it's valuable

- **Catch version-specific bugs early** — before users on that version do.
- **Cross-platform confidence** — Linux, Windows, macOS in one pass.
- **Fast** — parallelism means broad coverage without slow pipelines.

---

|  | |
|---|---|
| [← Secrets & Environment Variables](06-secrets-env.md) | [Next → Deploying to Azure](08-deploy-azure.md) |
