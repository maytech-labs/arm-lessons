# Lesson style guide

How every lesson in this repo is written. Anyone (human or agent) adding or
editing a lesson follows this.

## The reader

Someone who can program a little (ideally some C) but has never written assembly.
They are patient and want to *understand*, not just copy. They will type every
example themselves.

## Voice

- Second person, plain words, short paragraphs.
- Slow. One new idea at a time. Never use an instruction before it has been
  introduced, unless you say "we will explain this in lesson N, for now just copy it."
- Show, then explain. Every new concept gets a tiny runnable program.
- Predict, then check: ask the reader what a program will do before running it.
- Always connect back to C. Most new constructs get a "In C you would write... In
  assembly..." side-by-side.
- Name the common mistakes. Beginners crash in predictable ways; tell them how.

## Lesson directory layout

```
lessons/NN-slug/
  README.md          the lesson itself (prose; its code samples are the Linux flavor)
  exercises.md       homework, shared by every flavor
  answers.md         answers to the written (non-code) exercises
  linux/
    examples/        every program the README uses, plus a Makefile
    solutions/       one solution per programming exercise, plus a Makefile
  apple-silicon/
    README.md        what is different on macOS for this lesson, and walkthroughs
                     of the macOS versions of the examples
    examples/        macOS versions of every example, plus a Makefile
    solutions/       macOS versions of every programming solution, plus a Makefile
```

Theory-only lessons (01, 02) have no `linux/` or code folders, and their
`apple-silicon/README.md` just says nothing differs. A new flavor (another OS
on AArch64) would be one more folder beside `linux/` and `apple-silicon/`.

Makefiles are two lines:

```make
include ../../../../mk/linux.mk   # or ../../../../mk/apple.mk
```

Programs that need more than one source file (lessons 16, 20 onward) write their
own rules below the include. An assembly file that is only part of a program
(no `main`) is listed in `PARTS := name` *before* the include, so the shared
rules do not try to link it alone. Lessons whose programs are C files (29)
add a `%: %.c` rule.

## README.md structure

1. `# Lesson NN: Title`
2. **Goals** - a bullet list of what you can do after this lesson.
3. **Before you start** - which earlier lessons it builds on.
4. Body sections. Each introduces one idea, shows a program, runs it, explains it.
5. **C to assembly** - a table mapping the C constructs in this lesson to assembly.
6. **Common mistakes** - what goes wrong and what it looks like when it does.
7. **Recap** - five to ten bullets.
8. **Homework** - a link to `exercises.md`.

Show terminal sessions like this:

```console
$ make
$ ./exit42
$ echo $?
42
```

## exercises.md structure

- Numbered `Exercise NN.1`, `NN.2`, ...
- Ordered easiest to hardest, tagged **[warm-up]**, **[core]**, or **[stretch]**.
- Five to ten exercises per lesson. Mix written questions (predict the output,
  trace the registers, convert by hand) with programs to write.
- Each programming exercise says the file name to create (e.g. `ex3.s`),
  exactly what the program must do, and how to check it (expected output or exit code).
- Tell the reader to work in a `work/` directory inside the lesson (git-ignored).
- Solutions live in `solutions/exN.s`; written answers in `solutions/README.md`.
  Remind the reader to try first.

## Assembly code conventions

- GNU assembler syntax, compatible with both GNU `as` and LLVM's integrated
  assembler (used by `clang` on macOS).
- Comments use `//`. Every line of the early lessons is commented; later lessons
  comment intent rather than mechanics.
- Lowercase mnemonics and registers. Indent instructions 4 spaces; labels at
  column 0. Align comments where practical.
- Start every file with a header comment: what the program does, how to build
  and run it, and the expected output or exit code.
- Use `.p2align` (explicit power of two) rather than `.align`.
- Never use `x18` (reserved on Apple platforms; avoid everywhere for portability).
- Linux flavor: freestanding programs use `_start` (lessons 04-15); from lesson 16
  on, programs define `main` and link libc. Load addresses with
  `adrp x0, sym` / `add x0, x0, :lo12:sym`.
- Apple flavor: every program defines `_main`; symbols are prefixed with `_`;
  addresses via `adrp x0, sym@PAGE` / `add x0, x0, sym@PAGEOFF`. See
  [platform-differences.md](platform-differences.md).
- Keep `sp` 16-byte aligned at all times.
- Never name a label after a register (`d1`, `s2`, `b3`, `x9`...): clang treats it as the register.
- Define `.equ` constants before their first use (Apple's assembler rejects forward references in immediates).

## Verification

Every program in `examples/` and `solutions/` must build and produce the output
its header comment claims, on its platform. Check with:

```console
$ ./scripts/build-all.sh linux   # inside ./scripts/linux-shell.sh
$ ./scripts/build-all.sh apple   # on macOS
```
