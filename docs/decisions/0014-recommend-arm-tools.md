# 0014: Recommend arm-tools, and ship its configuration

- **Status:** Accepted
- **Date:** 2026-10-28

## Context

Beginners lose most of their time to mistakes the assembler reports badly or
not at all: a misspelled operand, a stack moved by 8, a callee-saved register
clobbered, `x30` lost across a call. [arm-tools](https://github.com/maytech-labs/arm-tools)
was built alongside this course. It has a language server (`armls`) that shows
clang's errors as you type, plus a linter (`armtool lint`) whose rules match
what lessons 13 to 16 teach.

The tools treat a file as Darwin unless told otherwise. Many Linux lesson
files contain no Linux-only syntax, so without configuration the tools read
them as macOS code and report wrong warnings, such as wanting the syscall
number in x16.

## Decision

- Recommend arm-tools, as optional, in the root README, lesson 00, and
  `docs/toolchain.md`. The course never depends on it: every step still works
  with only the toolchain from decisions 0003 and 0004.
- Ship an `armtool.toml` at the repo root (for `apple-silicon/`, which is
  Darwin by default) and one in each `lessons/NN-*/linux/` folder that sets
  `platform = "linux"`. The nearest file wins with no merging, so each Linux
  one repeats the root's `[format]`.
- Turn off `elf/gnu-stack` and `elf/function-symbol` for Linux. The course
  doesn't teach `.note.GNU-stack`, `.type`, or `.size`, and they would
  produce over a thousand warnings on correct course code.
- `[format]` matches the course's style (no mnemonic padding) for students'
  own files. Existing course files are not reformatted, because their comment
  columns vary.
- Keep the deliberately broken examples (`misaligned.s`, `lost_return.s`,
  `clobber_bug.s`, `no_exit.s`) as they are. The linter flagging them is the
  point.

## Alternatives considered

- **Don't mention it** - students would miss the fastest feedback available,
  on exactly the bugs the course warns about.
- **Make it required** - it's pre-release and source-available. Requiring it
  would also add a dependency to CI and to the Linux container.
- **A `// armtool: platform=linux` comment in every Linux `.s` file** - 350
  files of noise in code students read line by line, and students would need
  to copy it into their own files.
- **Lint in CI** - not yet. The linter still has false positives on this code
  (it doesn't know `exit` never returns), and the intentional bug demos would
  need suppressions.

## Consequences

- A new lesson with a `linux/` folder needs a copy of an existing
  `linux/armtool.toml`.
- Changes to the root `[format]` must be copied into every Linux config.
- `armtool check lessons` reports no errors today. Keeping it that way is
  cheap, but nothing enforces it yet.
