# AI-Assisted Development Rules (Project Baseline)

## 1. Operating principles
1. **Understand intent first**: restate the goal, users, and non-goals before coding.
2. **Ask questions when unsure**: do not invent requirements, URLs, credentials, or external dependencies.
3. **No churn**: if something fails ~5 times (build, test, deploy), stop and escalate with evidence (logs, commands, hypothesis).
4. **Security first**: treat auth, secrets, and data protection as core requirements (not “later”).
5. **Docs are part of the product**: update docs as you implement changes (PRD, architecture, deployment, API).
6. **Decouple** features into small components/services with clear boundaries and APIs.
7. **Externalise configuration**: no hard-coded endpoints or secrets; use env vars and config modules.
8. **Docker-first**: local runtime is containers; commands run inside containers; no “works on my machine”.

## 2. Default technology choices (unless a PRD overrides)
- Runtime/services: containers via Docker Compose
- Database: PostgreSQL
- Reverse proxy: Caddy (or equivalent)
- CI/CD: {{CI_PROVIDER}}
- Secrets: environment variables + CI secret store

## 3. Evidence required when escalating
- What you attempted (commands + config changes)
- What you expected to happen
- What happened (errors, logs)
- A short hypothesis list (top 3 likely causes)
