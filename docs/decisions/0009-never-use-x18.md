# 0009: Never use register x18, on either platform

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

AAPCS64 calls `x18` the "platform register". Linux leaves it free for use as a
temporary; Apple reserves it, and the OS may change it at any moment.

## Decision

No code in either track uses `x18`. Lesson 15 explains why.

## Alternatives considered

- **Use `x18` on Linux only** - creates code that silently breaks when ported,
  which is exactly the habit to avoid.

## Consequences

Learners have one fewer scratch register (`x9`-`x15` remain).
