# 0007: Teach every construct by its C equivalent

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

The goal is to be able to write in assembly anything one could write in C.

## Decision

C is the reference language. Every new construct (an `if`, a loop, a struct, a
call) is shown in C first and then in assembly, and every lesson ends with a
"C to assembly" table. From lesson 16 on, learners are encouraged to compare
their hand-written code with `gcc -S -O0` and `-O2` output.

## Alternatives considered

- **Teach assembly on its own terms** - leaves the learner unable to map
  familiar program structure onto instructions, which is the actual goal.

## Consequences

Learners need to read basic C. Lesson 00 points to a C refresher.
