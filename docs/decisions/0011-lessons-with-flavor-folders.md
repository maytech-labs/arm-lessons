# 0011: One folder per lesson, with a subfolder per flavor

- **Status:** Accepted
- **Date:** 2026-10-28

## Context

Decision 0002 put the Linux track in `lessons/NN-slug/` and the Apple Silicon
companion in a parallel tree, `apple-silicon/NN-slug/`. In practice every
lesson is one unit: one text, one set of exercises, and the same programs in
two flavors. Keeping them in two trees meant every cross-reference crossed
between trees, the book had to stitch them together, and adding another
platform would mean a third parallel tree.

## Decision

Each lesson is one directory with its platform-specific material in flavor
subfolders:

```
lessons/NN-slug/
  README.md, exercises.md, answers.md     the lesson, shared by all flavors
  linux/examples/, linux/solutions/       Linux AArch64 programs
  apple-silicon/README.md                 what differs on macOS
  apple-silicon/examples/, .../solutions/ macOS programs
```

The lesson prose stays as it was: written around the Linux code, with the
`apple-silicon/README.md` explaining the differences. Decision 0002's choice of
Linux as the reference flavor still holds; only its directory layout is
superseded. The old `apple-silicon/README.md` overview moved to
`docs/apple-silicon.md`. Learners' `work/` directories live inside a flavor
folder, at the same depth as `examples/`, so the copied Makefile's include path
keeps working.

## Alternatives considered

- **Keep the two parallel trees** - works, but scatters each lesson.
- **Platform-neutral prose with all code in flavor folders** - cleaner in
  theory, but a rewrite of every lesson for little benefit to the reader.

## Consequences

Makefiles include `../../../../mk/*.mk` (one level deeper). Scripts iterate
`lessons/*/linux/` and `lessons/*/apple-silicon/`. A new flavor is a new folder
in each lesson plus an `mk/` file.
