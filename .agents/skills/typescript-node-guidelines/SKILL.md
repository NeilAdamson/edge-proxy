---
name: typescript-node-guidelines
description: TypeScript and Node backend conventions
---

# TypeScript and Node Guidelines

TypeScript/Node rules:
- Prefer strict typing over weak typing.
- Avoid unnecessary use of any, ts-ignore, or disabled compiler checks.
- Follow existing naming conventions for services, controllers, handlers, DTOs, schemas, and tests.
- Keep modules cohesive and avoid cross-layer leakage.
- Reuse existing error-handling, validation, and logging patterns.
- Prefer existing scripts for lint, typecheck, build, and test.

*(Applicable to: TypeScript files, package.json, tsconfig.json)*
