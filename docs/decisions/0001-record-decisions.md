# 0001: Record decisions as numbered markdown files

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

This is a long-lived teaching project. Choices like "which platform is primary"
or "when do we introduce libc" affect every lesson, and are easy to forget or
quietly contradict later.

## Decision

Keep lightweight architecture decision records in `docs/decisions/`, numbered
sequentially, using `0000-template.md`. The index in `README.md` lists all of them.

## Alternatives considered

- **A single "design notes" file** - grows into an unstructured wall of text;
  hard to see what was superseded.
- **Nothing written down** - decisions get relitigated.

## Consequences

Any change that alters a convention in `docs/lesson-style-guide.md` or the
curriculum needs a new decision record.
