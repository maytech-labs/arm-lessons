# 0006: Fixed lesson layout, with exercises and full solutions

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

The learner wants slow, simple lessons with homework. Self-study has no teacher
to check work.

## Decision

Each lesson has `README.md`, `exercises.md`, `examples/`, and `solutions/`, as
specified in `docs/lesson-style-guide.md`. Every programming exercise has a
working solution; written exercises have answers in `solutions/README.md`.
Learners do their own work in a git-ignored `work/` directory.

## Alternatives considered

- **No solutions** - forces effort, but a stuck self-learner has no way forward.
- **Solutions in a separate branch** - harder to find when actually stuck.

## Consequences

Solutions must be kept building on both platforms. Exercises tell the reader to
attempt each one before looking.
