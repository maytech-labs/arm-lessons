# AGENTS.md

Instructions for AI agents working in this repository.

## What this repo is

A self-study course in AArch64 assembly. Each lesson is a directory in
`lessons/` with shared prose (`README.md`, `exercises.md`, `answers.md`) and one
folder per flavor: `linux/` (Linux AArch64, the reference) and `apple-silicon/`
(macOS arm64). Content is prose (markdown) plus small assembly and C programs.
There is no application code. The book website is generated from the same
markdown by `scripts/build-book.py`.

## Read before changing anything

- `docs/curriculum.md` - the lesson list and order. Lessons may only use concepts
  from earlier lessons.
- `docs/lesson-style-guide.md` - required structure, voice, and code conventions.
- `docs/platform-differences.md` - what changes between the two flavors.
- `docs/decisions/` - decisions already made. Do not contradict one; propose a
  new record that supersedes it instead.

## Rules

- Keep the flavors in sync: any example or solution added or changed in
  `lessons/NN-*/linux/` needs its counterpart in `lessons/NN-*/apple-silicon/`.
- Every `.s` file must build and behave exactly as its header comment says.
  Verify before claiming a change is done:
  - Linux: `./scripts/build-all.sh linux` inside the container
    (`./scripts/linux-shell.sh`), or
    `docker run --rm -v "$PWD":/work -w /work arm-lessons ./scripts/build-all.sh linux`.
  - macOS: `./scripts/build-all.sh apple`.
  - Then run the programs you touched and compare output / exit codes:
    `./scripts/compare-tracks.sh NN` does both flavors and diffs them.
  - `python3 scripts/check-links.py` must report no broken links.
- Programs must behave the same on both flavors, or be listed in
  `scripts/known-differences.txt` with a reason. CI enforces this.
- Never use register `x18` (decision 0009).
- Never introduce an instruction or concept in a lesson before the lesson that
  teaches it, unless the text explicitly flags it as "explained in lesson N".
- Do not commit build output; `.gitignore` covers extensionless binaries in
  `examples/` and `solutions/`.
- New conventions or scope changes need a decision record in `docs/decisions/`
  and a row in its index.
- Never add AI or tool authorship to commits, PRs, or files.
- Never print or commit the environment, tokens, or machine-specific paths;
  `scripts/run-all.sh` runs programs with an empty environment for this reason.

## Commands

```console
$ make -C lessons/07-arithmetic/linux/examples      # build one directory
$ make -C lessons/07-arithmetic/linux/examples clean
$ ./scripts/build-all.sh linux|apple [clean]       # build a whole flavor
$ ./scripts/run-all.sh linux|apple                 # run every built program, one line each
$ ./scripts/diff-runs.sh A.txt B.txt               # compare two run-all outputs
$ ./scripts/compare-tracks.sh NN [stdin]           # run lesson NN in both flavors, diff the results
$ ./scripts/linux-shell.sh [subdir]                # Linux container shell
$ ./scripts/port-to-apple.py SRC DST               # port a freestanding (04-15) Linux file to macOS
$ ./scripts/port-libc-to-apple.py SRC DST          # port a libc (16+) Linux file to macOS
$ python3 scripts/check-links.py                   # check markdown links
$ python3 scripts/build-book.py [--build]          # generate (and build) the book
```

The port scripts do the mechanical part (entry point, syscall numbers,
`@PAGE`/`@PAGEOFF`, underscores, variadic `printf` arguments on the stack).
Always review their output and run `compare-tracks.sh`; anything with doubles
passed to variadic functions, or functions called from C, needs hand edits.
