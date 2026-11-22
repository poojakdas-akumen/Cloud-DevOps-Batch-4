# Chapter 02 · Where Files Live — The Full Path

[🏠 Index](README.md)

---

GitHub Actions discovers workflows by convention. They **must** live in a specific folder:

```
your-repo/
├── .github/
│   └── workflows/          ← ALL workflow files go here
│       ├── ci.yml
│       ├── deploy-azure.yml
│       └── nightly.yml
├── src/
├── tests/
├── package.json
└── README.md
```

## Rules for the path

- The folder is **`.github/workflows/`** — note the leading dot, and it's plural (`workflows`).
- It must be at the **root** of the repository, not inside a subfolder.
- Files use the **`.yml`** or **`.yaml`** extension.
- You can have **many** workflow files — each is independent and triggered by its own events.
- The **file name** is up to you (`ci.yml`, `release.yml`), but the `name:` field *inside* the file is what shows in the Actions tab UI.

## Creating one

### Option A — via the GitHub website

Repo → **Actions** tab → **New workflow** → pick a template or "set up a workflow yourself". GitHub commits the file to `.github/workflows/` for you.

### Option B — locally (recommended for learning)

```bash
# from the root of your repo
mkdir -p .github/workflows
touch .github/workflows/ci.yml
# edit the file, then:
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push
```

The moment the file lands on GitHub, Actions starts listening for its triggers.

---

|  | |
|---|---|
| [← The Mental Model](01-mental-model.md) | [Next → Workflow YAML Syntax](03-workflow-syntax.md) |
