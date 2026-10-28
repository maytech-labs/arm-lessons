# ARM64 Assembly, from Zero to C

[![CI](https://github.com/maytech-labs/arm-lessons/actions/workflows/ci.yml/badge.svg)](https://github.com/maytech-labs/arm-lessons/actions/workflows/ci.yml)
[![License: REAL 1.0](https://img.shields.io/badge/License-REAL_1.0-blue.svg)](LICENSE.md)

A slow, thorough, hands-on course in AArch64 (64-bit ARM) assembly language,
for **Linux on ARM64** and **macOS on Apple Silicon**.

By the end you can take a C program and write it by hand in assembly:
arithmetic, control flow, pointers, functions, strings, structs, the heap,
data structures, floating point, function pointers, file I/O, variadic
functions, threads and atomics, inline assembly, and SIMD. More importantly,
you understand *why* every instruction is there.

## Who this is for

- You can program a little, ideally some C. You do not need to know any
  assembly.
- You want to understand what the machine actually does, not just copy code.
- You have an **Apple Silicon Mac** (M1 or later) or an **ARM64 Linux** machine
  (a Raspberry Pi 4/5 with a 64-bit OS, an ARM cloud server, and so on).

Each lesson takes one to three evenings, including the homework. There are
32 of them.

## What makes it different

- **Everything runs.** Every example and every exercise solution is a real
  program, built and run on both platforms by CI on every change.
- **Two flavors, side by side.** The instructions are the same on Linux and
  macOS; the system around them is not. Each lesson's `apple-silicon/` folder
  explains exactly what changes, with macOS versions of every program.
- **C is the reference.** Every construct is shown in C first, then in
  assembly, and each lesson ends with a C-to-assembly table.
- **Homework with answers.** Five to ten exercises per lesson, from warm-up to
  stretch, with full solutions.
- **Slow on purpose.** One new idea at a time, with "predict, then run" at
  every step.

## Read it

- **As a book:** <https://maytech-labs.github.io/arm-lessons/> (built from
  this repository by CI).
- **In the repository:** start at [lessons/00-setup](lessons/00-setup/).

## Getting started

You need:

- **On a Mac:** the Xcode command line tools (`xcode-select --install`) for the
  macOS flavor, and Docker (Docker Desktop, OrbStack, or Colima) for the Linux
  flavor. Apple Silicon runs the arm64 Linux container natively, with no
  emulation.
- **On ARM64 Linux:** `gcc`, `binutils`, `make`, and `gdb`.

```console
$ git clone https://github.com/maytech-labs/arm-lessons.git && cd arm-lessons
$ ./scripts/linux-shell.sh            # Linux container, repo mounted at /work
# cd lessons/04-first-program/linux/examples
# make && ./exit42; echo $?
42
```

On the Mac itself:

```console
$ cd lessons/04-first-program/apple-silicon/examples
$ make && ./exit42; echo $?
42
```

Then go to [lessons/00-setup](lessons/00-setup/) and take it from there.

## The syllabus

| Part | Lessons |
|------|---------|
| 1. Foundations | setup, binary and hex, signed numbers, the machine, your first program, hello world, the debugger |
| 2. Computing | arithmetic, bitwise operations, flags and branches, loops |
| 3. Memory and functions | loads and stores, arrays and pointers, the stack, functions, the calling convention, calling C |
| 4. C's data model | strings, integer types, structs and unions, symbols and sections, the heap, linked structures |
| 5. The rest of C, and beyond | floating point, function pointers, I/O and arguments, variadic functions, reading compiler output, threads and atomics, inline assembly, SIMD with NEON, capstone projects |

The full list: [docs/curriculum.md](docs/curriculum.md).

## How each lesson is laid out

```
lessons/NN-slug/
  README.md          the lesson: read it top to bottom
  exercises.md       homework
  answers.md         answers to the written questions
  linux/
    examples/        the programs from the lesson; `make` builds them all
    solutions/       solutions to the programming exercises
  apple-silicon/
    README.md        what is different on macOS
    examples/        the macOS versions
    solutions/
```

Do your own work in a `work/` folder inside `linux/` or `apple-silicon/`; git
ignores it.

## Repository map

| Path | What |
|------|------|
| `lessons/` | The 32 lessons |
| `docs/` | Curriculum, toolchain, platform differences, reference, glossary, style guide, [decision records](docs/decisions/) |
| `mk/` | Shared Makefile rules for each flavor |
| `scripts/` | Container shell, build/run/compare scripts, the book generator |
| `Dockerfile` | The Linux AArch64 environment |
| `AGENTS.md` | Rules for anyone (human or AI) changing the repository |

## Reference

- [AArch64 cheat sheet](docs/reference/aarch64-cheatsheet.md)
- [Linux vs macOS differences](docs/platform-differences.md)
- [Toolchain](docs/toolchain.md)
- [Glossary](docs/glossary.md)
- [Further reading](docs/reference/further-reading.md)

## Contributing

Found something wrong or confusing? Please
[open an issue](https://github.com/maytech-labs/arm-lessons/issues/new/choose).
Pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[REAL 1.0](LICENSE.md) (Reciprocal Ethical AI License). You may use, modify,
and share this course freely; modified versions must use the same license,
and the license sets reciprocal terms for AI training and limits on certain
uses. It is a source-available license, not an OSI-approved open-source one.
