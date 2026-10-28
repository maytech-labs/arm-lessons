# ARM64 Assembly, from Zero to C

A slow, thorough, hands-on course in AArch64 (64-bit ARM) assembly language.
By the end you will be able to write, by hand, anything you could write in C:
arithmetic, control flow, pointers, functions, strings, structs, the heap, data
structures, floating point, function pointers, file I/O, variadic functions, and
threads, and you will understand why every instruction is there.

## Two tracks

| Track | Directory | Runs on |
|-------|-----------|---------|
| Main: Linux AArch64 | [`lessons/`](lessons/) | Linux on ARM64, or a Docker container on an Apple Silicon Mac |
| Companion: Apple Silicon | [`apple-silicon/`](apple-silicon/) | macOS on M-series Macs, natively |

Read each lesson in `lessons/` first, then its companion in `apple-silicon/`,
which explains what is different on macOS and has macOS versions of every
program. Why it is set up this way: [decision 0002](docs/decisions/0002-linux-primary-track-apple-companion.md).

## Getting started

1. Install the Xcode command line tools: `xcode-select --install`
2. Install Docker Desktop (or OrbStack / Colima).
3. Start with [lessons/00-setup](lessons/00-setup/).

```console
$ ./scripts/linux-shell.sh            # Linux shell with this repo at /work
# cd lessons/04-first-program/examples
# make && ./exit42; echo $?
42
```

## Syllabus

Thirty-two lessons in five parts: foundations, computing, memory and functions,
C's data model, and the rest of C (plus inline assembly and NEON), ending with
capstone projects.
Full list: [docs/curriculum.md](docs/curriculum.md).

## How each lesson works

```
lessons/NN-slug/
  README.md      read this
  examples/      the programs from the lesson; `make` builds them all
  exercises.md   homework, from warm-up to stretch
  solutions/     worked solutions (try first!)
```

Do your homework in a `work/` directory inside the lesson; it is git-ignored.

## Repository map

| Path | What |
|------|------|
| `lessons/` | Main track (Linux AArch64) |
| `apple-silicon/` | Companion track (macOS arm64) |
| `docs/` | Curriculum, style guide, references, decision records |
| `mk/` | Shared Makefile rules for each track |
| `scripts/` | Container shell and build-everything scripts |
| `Dockerfile` | The Linux AArch64 environment |
| `AGENTS.md` | Instructions for AI coding agents working in this repo |

## Reference

- [AArch64 cheat sheet](docs/reference/aarch64-cheatsheet.md)
- [Linux vs macOS differences](docs/platform-differences.md)
- [Toolchain](docs/toolchain.md)
- [Glossary](docs/glossary.md)
- [Decision records](docs/decisions/)
