# Chapter 00 · Introduction

[🏠 Index](README.md)

---

**GitHub Actions** is a CI/CD (Continuous Integration / Continuous Delivery) platform built directly into GitHub. It lets you automate your software workflows — building, testing, and deploying code — in response to events that happen in your repository.

The key idea: **you never leave GitHub, and you never maintain a separate CI server.** You commit a small configuration file to your repo, and from then on GitHub watches for events (a push, a pull request, a scheduled time) and runs your automation on machines it provides — called *runners*.

## Why it matters

| Without CI/CD | With GitHub Actions |
|---------------|---------------------|
| Manually run tests on your laptop | Tests run automatically on every push |
| "Works on my machine" surprises | Every change tested in a clean environment |
| Manual FTP / portal clicks to deploy | Push to `main` → it ships automatically |
| A separate Jenkins/CI server to patch and secure | GitHub hosts and maintains the runners |
| No visibility into who broke what | Green ✓ / red ✗ shown on every pull request |

## What you can automate

- **CI** — compile code, run unit/integration tests, lint, check formatting, scan for vulnerabilities.
- **CD** — build container images, push to a registry, deploy to Azure / AWS / GCP / Kubernetes.
- **Automation** — label issues, comment on PRs, publish releases, send notifications, run nightly cleanups.

## The 30-second example

```yaml
# .github/workflows/ci.yml
name: CI
on: push                     # run on every push
jobs:
  test:
    runs-on: ubuntu-latest   # GitHub gives you a fresh Ubuntu machine
    steps:
      - uses: actions/checkout@v4   # grab your code
      - run: npm ci                 # install dependencies
      - run: npm test               # run the tests
```

Commit that file, push it, and open the **Actions** tab in your repo. You'll see the workflow run live.

---

|  | |
|---|---|
| [🏠 Index](README.md) | [Next → The Mental Model](01-mental-model.md) |
