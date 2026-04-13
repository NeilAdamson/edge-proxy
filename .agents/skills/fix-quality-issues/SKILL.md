---
name: fix-quality-issues
description: Use this skill when the task is to resolve lint errors, type errors, failing tests, or code quality drift.
---
# Fix Quality Issues

Use this skill when the task is to resolve lint errors, type errors, failing tests, or code quality drift.

## Objective
Bring the touched area back to a clean, standards-compliant state without introducing unnecessary refactors.

## Workflow
1. Determine the failing checks and their scope.
2. Inspect existing repo scripts, CI config, and container-based validation commands.
3. Reproduce the issue using Docker or Docker Compose where possible.
4. Fix the root cause rather than suppressing the check.
5. Re-run the relevant validation.
6. Report what failed, what was fixed, and what remains if anything could not be resolved.

## Constraints
- Do not silence lint or type checks casually.
- Do not use weak typing or ignore directives unless absolutely necessary and explicitly justified.
- Keep fixes targeted.
- Preserve existing code patterns unless the pattern itself is the root cause.
