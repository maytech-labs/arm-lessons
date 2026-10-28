# Decision records

Every decision that shapes this repo is written down here, one file per decision,
so you can see what was chosen, what else was considered, and why.

Format: copy [0000-template.md](0000-template.md) to the next number. Never
rewrite an accepted decision; write a new one that supersedes it and update the
old one's status.

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-record-decisions.md) | Record decisions as numbered markdown files | Accepted |
| [0002](0002-linux-primary-track-apple-companion.md) | Linux AArch64 is the main track; Apple Silicon is a companion track | Accepted; layout superseded by 0011 |
| [0003](0003-gnu-syntax-and-c-toolchain.md) | GNU assembler syntax, built through `gcc`/`clang` | Accepted |
| [0004](0004-docker-for-linux.md) | Run the Linux track in an arm64 Docker container on the Mac | Accepted |
| [0005](0005-raw-syscalls-before-libc.md) | Raw system calls first, the C library from lesson 16 | Accepted |
| [0006](0006-lesson-layout-and-solutions.md) | Fixed lesson layout, with exercises and full solutions | Accepted |
| [0007](0007-c-as-reference-language.md) | Teach every construct by its C equivalent | Accepted |
| [0008](0008-curriculum-scope.md) | Scope: everything needed to write any C program in assembly | Accepted, amended by 0010 |
| [0009](0009-never-use-x18.md) | Never use register `x18`, on either platform | Accepted |
| [0010](0010-add-inline-asm-neon-pac.md) | Add inline assembly, NEON, and PAC/BTI to the curriculum | Accepted |
| [0011](0011-lessons-with-flavor-folders.md) | One folder per lesson, with a subfolder per flavor | Accepted |
| [0012](0012-license-real.md) | License the course under REAL 1.0 | Accepted |
| [0013](0013-book-and-ci.md) | Publish the lessons as a book, and test both flavors in CI | Accepted |
