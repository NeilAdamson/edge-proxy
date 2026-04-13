# Docker-Only Runtime Rule

This repository is Docker-only for local development and runtime unless the user explicitly says otherwise.

Runtime rules:
- Always use Docker or Docker Compose for local development and runtime.
- Never instruct the user to run the application stack directly on the host OS if a Docker path exists.
- Never introduce host-only startup steps for app services, databases, queues, caches, workers, or supporting infrastructure unless explicitly requested.
- If a task would normally be done locally, translate it into the equivalent Docker or Docker Compose command.
- Prefer changes to Dockerfiles, compose files, entrypoints, startup scripts, and environment configuration over host-based runtime instructions.
- Keep dev and prod behavior clearly separated.
- Externalize runtime configuration through environment variables or env files.

When changing runtime behavior:
- Keep ports, health checks, service names, volumes, networks, and dependencies coherent.
- Update setup and deployment docs where relevant.

Validation:
- Prefer commands such as:
  - docker compose up
  - docker compose exec ...
  - docker compose run ...
