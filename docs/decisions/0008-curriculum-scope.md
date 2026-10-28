# 0008: Scope: everything needed to write any C program in assembly

- **Status:** Accepted (amended by 0010)
- **Date:** 2026-10-27

## Context

"Assembly" can extend into operating systems, performance engineering, and
vector programming. The learner's goal is narrower: be able to write by hand
anything they would write in C.

## Decision

The curriculum (`docs/curriculum.md`) covers the C language and its standard
library usage: integer and floating-point arithmetic, control flow, memory and
pointers, functions and the calling convention, strings, structs and unions,
globals and linkage, the heap, data structures, function pointers, I/O,
variadic functions, threads and atomics, plus the skills around them (debugging,
reading compiler output). It ends with capstone projects.

Out of scope: kernel/bare-metal programming, SIMD vectorization, and
domain-specific libraries (graphics, networking, engines).

## Alternatives considered

- **Stop at functions and strings** - leaves major C features (structs, heap,
  floats, function pointers, threads) untranslatable.
- **Include OS development** - a different course.

## Consequences

30 lessons. New lessons that fall outside this scope need a new decision record.
