---
name: dockerized-validation
description: Use this skill when the task requires validating builds, linting, tests, or runtime behavior in a Docker-first repository.
---
# Dockerized Validation

Use this skill when the task requires validating builds, linting, tests, or runtime behavior in a Docker-first repository.

## Objective
Validate changes through containerized commands rather than host-local execution.

## Workflow
1. Inspect README, compose files, Dockerfiles, Makefile, package manifests, and CI scripts for the standard validation commands.
2. Prefer commands such as:
   - docker compose up
   - docker compose exec ...
   - docker compose run ...
3. Run the narrowest relevant validation first, then broaden only if needed.
4. Capture what was validated and whether the result passed or failed.
5. If validation could not be run, explain precisely why.

## Constraints
- Never switch to host-local runtime or host-local service execution if a Docker path exists.
- Do not invent validation commands when repo-standard commands already exist.
- Keep the validation path reproducible.
