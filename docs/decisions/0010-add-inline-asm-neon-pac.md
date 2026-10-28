# 0010: Add inline assembly, NEON, and PAC/BTI to the curriculum

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

Reviewing the 30-lesson curriculum against "learn ARM64 assembly" (not only
"write C in assembly") found three gaps a working programmer meets quickly:

- Inline assembly is how most real-world assembly is written: a few
  instructions inside a C function.
- NEON/SIMD is a large part of practical ARM64 work (image, audio, crypto,
  string routines), and the course had no introduction to it.
- Pointer authentication and branch target identification (`paciasp`,
  `autiasp`, `bti`) appear in Apple system code and modern compiler output;
  without an explanation they are confusing.

## Decision

Amend decision 0008's scope:

- New lesson **29-inline-assembly**: GCC/Clang extended `asm`, operands,
  constraints, clobbers, `volatile`, when inline assembly is (and is not) worth it.
- New lesson **30-simd-neon**: vector registers and lane arrangements, loading
  and storing vectors, element-wise arithmetic on arrays, reductions, handling
  leftover elements. An introduction, not full coverage.
- The capstone moves from 29 to **31-capstone**.
- **27-compiler-output** gains a section on PAC/BTI: what the instructions do,
  why they appear, and that hand-written code may ignore them (Linux, and macOS
  `arm64`), while `arm64e` binaries use them.

## Alternatives considered

- **Renumber so NEON follows floating point (lesson 24)** - more logical
  placement, but would rename six existing lesson directories and their
  cross-references. Inline assembly and NEON depend on nothing after lesson 23
  except compiler output (27), so placing them at 29-30 loses little.
- **Leave them out** - the course would be complete for its original goal but
  leave the learner unable to read a large class of real ARM64 code.
- **Also cover A32/Thumb, bare metal, or encoding** - separate courses.

## Consequences

32 lessons. Out of scope remains: 32-bit ARM, microcontrollers, kernel and
bare-metal programming, SVE, and NEON beyond the introduction.
