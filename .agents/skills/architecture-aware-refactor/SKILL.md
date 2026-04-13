---
name: architecture-aware-refactor
description: Use this skill when the task involves refactoring code, reshaping modules, or improving structure while preserving behavior.
---
# Architecture-Aware Refactor

Use this skill when the task involves refactoring code, reshaping modules, or improving structure while preserving behavior.

## Objective
Improve maintainability or structure without drifting away from the intended architecture or introducing regressions.

## Required context
Read these when present:
- docs/architecture.md
- README.md
- docs/PRD.md
- docs/security.md

## Workflow
1. Understand the current architecture and identify which boundaries must remain intact.
2. Inspect neighboring code and current naming patterns.
3. Keep the refactor incremental and reversible.
4. Preserve public interfaces unless change is explicitly required.
5. Keep runtime, deployment, and Docker behavior stable unless the task explicitly includes them.
6. Re-run relevant validation after refactoring.
7. Update architecture or setup documentation if structure or operational assumptions changed.

## Constraints
- Do not mix refactoring with unrelated feature work.
- Do not introduce new abstractions without a clear payoff.
- Do not weaken validation, security, or consistency.
