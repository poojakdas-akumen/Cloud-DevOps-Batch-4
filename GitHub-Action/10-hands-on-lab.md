# Chapter 10 · Hands-On Lab

[🏠 Index](README.md)

---

Build your first complete pipeline, end to end.

| # | Task | What to do |
|---|------|------------|
| 1 | **Create the file** | Add `.github/workflows/ci.yml` to a repo |
| 2 | **Add a trigger** | Use `on: push` so it runs on every commit |
| 3 | **Checkout + test** | Use `actions/checkout@v4`, then `run` your tests |
| 4 | **Add a secret** | Store `AZURE_CREDENTIALS` in repo Settings |
| 5 | **Deploy** | Add `azure/login` → `azure/webapps-deploy` on `main` |
| 6 | **Watch it run** | Open the **Actions** tab and see the green checks |

## Starter file to copy

```yaml
name: My First Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'    # only deploy from main
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - uses: azure/webapps-deploy@v3
        with:
          app-name: my-app
          package: .
```

## Checklist

- [ ] Workflow file is in `.github/workflows/`
- [ ] It triggers on push and pull request
- [ ] Tests run in the `test` job
- [ ] `AZURE_CREDENTIALS` secret is set
- [ ] `deploy` job waits for `test` (`needs: test`)
- [ ] Deploy only runs on `main` (the `if:` guard)
- [ ] You can see the run in the Actions tab

---

|  | |
|---|---|
| [← Self-Hosted Runners](09-self-hosted-runners.md) | [Next → Cheat Sheet & Glossary](11-cheatsheet-glossary.md) |
