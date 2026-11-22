# Chapter 01 · The Mental Model

[🏠 Index](README.md)

---

Before syntax, internalize the hierarchy. Everything in GitHub Actions nests like this:

```
EVENT (something happens in the repo)
   │
   └── WORKFLOW  (.github/workflows/ci.yml)
          │
          ├── JOB: build           ← runs on its own runner (VM)
          │     ├── STEP: checkout code
          │     ├── STEP: install deps
          │     └── STEP: run tests
          │
          └── JOB: deploy          ← another runner, can wait for "build"
                ├── STEP: log in to Azure
                └── STEP: deploy
```

## The vocabulary

| Term | What it is | Analogy |
|------|-----------|---------|
| **Event** | A trigger — push, PR, schedule, manual click | The doorbell ringing |
| **Workflow** | A `.yml` file describing the whole automation | The recipe |
| **Job** | A group of steps that run together on one runner | One cook at one station |
| **Step** | A single task — a command or a reusable action | One instruction in the recipe |
| **Action** | A pre-packaged, reusable step from the Marketplace | A store-bought sauce |
| **Runner** | The machine that executes a job | The kitchen |

## Key behaviors to remember

- **Jobs run in parallel by default.** Use `needs:` to make one wait for another.
- **Steps run in order, top to bottom**, on the *same* runner, sharing the same filesystem.
- **Each job gets a fresh, clean runner.** Files don't automatically carry between jobs (use *artifacts* or *caching* for that).

> Keep this hierarchy in your head. Every workflow file you read or write is just some combination of **Event → Workflow → Jobs → Steps.**

---

|  | |
|---|---|
| [← Introduction](00-introduction.md) | [Next → Where Files Live](02-file-path.md) |
