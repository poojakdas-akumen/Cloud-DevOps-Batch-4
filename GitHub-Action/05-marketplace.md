# Chapter 05 · The Actions Marketplace — Reusable Actions

[🏠 Index](README.md)

---

Instead of writing every step from scratch, you pull in pre-built **actions** from the [GitHub Marketplace](https://github.com/marketplace?type=actions) — 20,000+ community and official building blocks.

## How you reference one

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
```

The format is **`owner/repo@version`**:

- `actions/checkout` → the `checkout` action published by the `actions` org.
- `@v4` → the version. **Always pin the version.**

## Pinning versions (important for security & stability)

| Style | Example | Notes |
|-------|---------|-------|
| Major tag | `@v4` | Gets latest v4.x — convenient, common |
| Full tag | `@v4.1.7` | Exact version — most reproducible |
| Commit SHA | `@a1b2c3d...` | Most secure — immune to tag tampering |
| Branch | `@main` | ⚠️ Avoid — can change under you, unsafe |

## `with:` passes inputs

The `with:` block configures an action — versions, paths, credentials, flags:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'                  # cache dependencies between runs
    registry-url: 'https://registry.npmjs.org'
```

## Essential actions you'll use constantly

| Action | What it does |
|--------|--------------|
| `actions/checkout@v4` | Clones your repo onto the runner so steps can access files. **Almost every workflow starts with this.** |
| `actions/setup-node@v4` | Installs a specific Node.js version + caches deps |
| `actions/setup-python@v5` | Same, for Python |
| `actions/upload-artifact@v4` | Save build outputs to download later |
| `actions/download-artifact@v4` | Retrieve artifacts in a later job |
| `actions/cache@v4` | Cache dependencies to speed up runs |
| `azure/login@v2` | Authenticate to Azure |
| `azure/webapps-deploy@v3` | Deploy to Azure Web App |
| `docker/build-push-action@v6` | Build and push container images |

## Anatomy of a marketplace listing

When you browse the Marketplace, each action shows:
- the **`uses:` string** to copy,
- required and optional **inputs** (`with:`),
- **outputs** it produces,
- example workflows,
- a **version** dropdown.

---

|  | |
|---|---|
| [← Triggers](04-triggers.md) | [Next → Secrets & Environment Variables](06-secrets-env.md) |
