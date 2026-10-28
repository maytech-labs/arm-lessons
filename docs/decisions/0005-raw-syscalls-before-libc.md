# 0005: Raw system calls first, the C library from lesson 16

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

Calling `printf` requires understanding the stack, `bl`/`ret`, and the calling
convention, which are lessons 13-15. But learners need to see output from
lesson 05.

## Decision

- Lessons 04-15 in the Linux track are freestanding: they define `_start`, use
  `svc #0` system calls (`exit`, `write`, `read`), and link with
  `-nostdlib -static`. Nothing is hidden: the program is exactly what was typed.
- The Apple track defines `_main` (macOS cannot link without libSystem) but
  mirrors the Linux examples with raw BSD system calls (`x16`, `svc #0x80`),
  and says clearly that Apple does not guarantee this interface.
- From lesson 16 on, both tracks define `main`/`_main` and call the C library.
- Printing numbers before lesson 16 uses the exit status (0-255) or small helper
  routines the learner writes; this doubles as practice.

## Alternatives considered

- **libc from day one with "copy this boilerplate"** - gets output sooner, but
  front-loads unexplained ritual (prologue, alignment, the Apple variadic rule).
- **Raw system calls forever** - real C programs use libc; the course must
  teach calling it.

## Consequences

Early lessons rely on `echo $?` and `write`. The switch to libc is a lesson of
its own (16), which is also where calling assembly from C is taught.
