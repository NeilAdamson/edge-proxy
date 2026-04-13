---
name: implement-feature-from-prd
description: Use this skill when the task is to build or extend functionality based on a product requirement or feature description.
---
# Implement Feature From PRD

Use this skill when the task is to build or extend functionality based on a product requirement or feature description.

## Objective
Deliver a feature that aligns to the PRD, the existing architecture, and the repository's Docker-first runtime model.

## Required context
Read these when present before coding:
- docs/PRD.md
- docs/architecture.md
- README.md
- docs/deployment.md
- docs/security.md

## Workflow
1. Understand the requested feature and determine the likely acceptance expectations from the PRD.
2. Inspect the relevant existing implementation, folder structure, APIs, schemas, and tests before changing patterns.
3. Identify the minimum viable set of code changes needed.
4. Implement the feature using existing conventions, naming standards, and module boundaries.
5. Ensure all runtime or setup changes remain Docker-first.
6. Run the most relevant validation available, preferably through Docker.
7. Update documentation if behavior, setup, architecture, or env vars changed.
8. Summarize what changed, what was validated, and any assumptions or limitations.

## Constraints
- Prefer targeted changes over broad rewrites.
- Do not weaken security or validation to make the feature work.
- Do not leave lint or type errors unresolved.
- Do not add unnecessary dependencies.
