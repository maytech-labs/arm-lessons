# 0002: Linux AArch64 is the main track; Apple Silicon is a companion track

- **Status:** Accepted; the directory layout is superseded by [0011](0011-lessons-with-flavor-folders.md)
- **Date:** 2026-10-27

## Context

The learner works on an Apple Silicon Mac and wants to learn ARM64 assembly in
general, with a separate place for Apple-specific material. The instruction set
is identical on both, but macOS differs in system calls, symbol naming,
relocation syntax, section names, a reserved register, and variadic calls.

## Decision

- `lessons/` is the main track and targets **Linux AArch64** (ELF, AAPCS64 as
  published by Arm). Lesson prose lives here.
- `apple-silicon/` mirrors the lesson numbering. Each companion explains what
  differs on macOS for that lesson and provides macOS versions of every example
  and solution. It does not repeat the full lesson.
- `docs/platform-differences.md` is the single summary of the differences.

## Alternatives considered

- **macOS as the main track** - runs without Docker, but Apple's ABI is a
  variant of the standard one, raw system calls are unsupported, and most
  books, tutorials, and compiler-explorer output assume Linux. Learning the
  standard first and the variant second is easier than the reverse.
- **Fully duplicate lessons per platform** - twice the prose to keep in sync.
- **Abstract platform differences behind macros** - hides exactly the details
  an assembly course should teach.

## Consequences

Every example exists twice. Lessons must be completed in the main track first,
then the companion read. The learner gets fluent in both ABIs.
