# AGENTS.md

Instructions for AI agents working in this repository.

## What this repo is

A self-study course in AArch64 assembly. The main track (`lessons/`) targets
Linux AArch64; the companion track (`apple-silicon/`) covers macOS arm64. Content
is prose (markdown) plus small assembly programs. There is no application code.

## Read before changing anything

- `docs/curriculum.md` - the lesson list and order. Lessons may only use concepts
  from earlier lessons.
- `docs/lesson-style-guide.md` - required structure, voice, and code conventions.
- `docs/platform-differences.md` - what changes between the two tracks.
- `docs/decisions/` - decisions already made. Do not contradict one; propose a
  new record that supersedes it instead.

## Rules

- Keep the two tracks in sync: any example or solution added or changed in
  `lessons/NN-*` needs its macOS counterpart in `apple-silicon/NN-*`.
- Every `.s` file must build and behave exactly as its header comment says.
  Verify before claiming a change is done:
  - Linux: `./scripts/build-all.sh linux` inside the container
    (`./scripts/linux-shell.sh`), or
    `docker run --rm -v "$PWD":/work -w /work arm-lessons ./scripts/build-all.sh linux`.
  - macOS: `./scripts/build-all.sh apple`.
  - Then run the programs you touched and compare output / exit codes.
- Never use register `x18` (decision 0009).
- Never introduce an instruction or concept in a lesson before the lesson that
  teaches it, unless the text explicitly flags it as "explained in lesson N".
- Do not commit build output; `.gitignore` covers extensionless binaries in
  `examples/` and `solutions/`.
- New conventions or scope changes need a decision record in `docs/decisions/`
  and a row in its index.
- Never add AI/Claude authorship to commits, PRs, or files.

## Commands

```console
$ make -C lessons/07-arithmetic/examples          # build one directory
$ make -C lessons/07-arithmetic/examples clean
$ ./scripts/build-all.sh linux|apple [clean]       # build a whole track
$ ./scripts/linux-shell.sh [subdir]                # Linux container shell
$ ./scripts/compare-tracks.sh NN [stdin]           # run lesson NN on both tracks, diff the results
$ ./scripts/port-to-apple.py SRC DST               # port a freestanding (04-15) Linux file to macOS
$ ./scripts/port-libc-to-apple.py SRC DST          # port a libc (16+) Linux file to macOS
```

The port scripts do the mechanical part (entry point, syscall numbers,
`@PAGE`/`@PAGEOFF`, underscores, variadic `printf` arguments on the stack).
Always review their output and run `compare-tracks.sh`; anything with doubles
passed to variadic functions, or functions called from C, needs hand edits.
