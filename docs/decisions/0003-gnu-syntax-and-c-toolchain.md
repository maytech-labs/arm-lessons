# 0003: GNU assembler syntax, built through gcc/clang

- **Status:** Accepted
- **Date:** 2026-10-27

## Context

AArch64 assembly can be written for GNU `as`, LLVM's integrated assembler, or
Arm's own `armasm`. Linking freestanding and libc programs by hand with `ld`
requires knowing platform-specific paths and startup files.

## Decision

- Write GNU syntax restricted to what both GNU `as` and LLVM accept, with `//`
  comments and `.p2align` for alignment.
- Files use the `.s` extension (no C preprocessor).
- Build through the compiler driver: `gcc` in the Linux container, `clang` on
  macOS. Shared rules live in `mk/linux.mk` and `mk/apple.mk`.
- Lesson 03 explains what the assembler and linker do, so the driver is not magic.

## Alternatives considered

- **`.S` with the C preprocessor** - useful, but adds a second macro language;
  `.macro`/`.equ` are taught instead in lesson 20.
- **Calling `as` and `ld` directly** - shown once for understanding, but too
  fiddly as the everyday workflow, and impractical on macOS.
- **armasm syntax** - not available in free toolchains on either platform.

## Consequences

Some ELF-only directives (`.type`, `.size`, `.section .rodata`) are confined to
the Linux track; the Apple track uses Mach-O equivalents.
