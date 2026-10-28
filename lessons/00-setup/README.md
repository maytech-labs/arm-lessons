# Lesson 00: Setup

## Goals

After this lesson you can:

- Install the tools this course needs on an Apple Silicon Mac.
- Open a Linux AArch64 shell in a Docker container, with this repo inside it.
- Build every program in a directory with `make`, run one, and read its exit status.
- Find your way around a lesson: `README.md`, `exercises.md`, `answers.md`,
  the `linux/` and `apple-silicon/` folders, and your own `work/` directory.
- Run three tools that look inside a program: `file`, `nm`, and `objdump`.

## Before you start

Nothing. This is the first lesson. You need:

- An Apple Silicon Mac (M1 or later).
- A little programming experience. Some C is ideal; see
  [A C refresher](#a-c-refresher) below if yours is rusty.
- Comfort typing commands in Terminal (`cd`, `ls`, `cat`).

## How this course is organised

Every lesson comes in two flavors:

| Flavor | Folder in each lesson | What it is |
|--------|-----------------------|------------|
| Linux | `linux/` | The programs the lesson text uses. Linux on 64-bit ARM ("AArch64"). |
| Apple Silicon | `apple-silicon/` | What is different on macOS, plus macOS versions of every program. |

Why Linux first, when you are on a Mac? Your Mac's CPU runs exactly the same
instructions as an ARM Linux machine. What differs is the operating system
around it. Linux's rules are the standard, published, stable ones; most books
and tutorials use them; and macOS's rules are easiest to learn as "the
standard, with these changes". So you learn on Linux, then read the companion
to see what changes on macOS. The full reasoning is in
[decision 0002](../../docs/decisions/0002-linux-primary-track-apple-companion.md).

You will not need a Linux computer. Docker runs a small ARM Linux system
inside your Mac. Because your Mac is already ARM, this is not emulation: your
programs run directly on your CPU at full speed.

## Step 1: Install the Xcode command line tools

These give you `clang` (Apple's C compiler, which also assembles), the linker,
`make`, `git`, `objdump`, `nm`, and the `lldb` debugger. In Terminal:

```console
$ xcode-select --install
```

A window pops up; click Install and wait. If it says the tools are already
installed, you are done. Check:

```console
$ clang --version
Apple clang version ...
Target: arm64-apple-darwin...
```

The important word is `arm64`. That is Apple's name for AArch64.

## Step 2: Install Docker

Install one of these (any one works):

- **Docker Desktop**: docker.com, "Download for Mac - Apple Silicon".
- **OrbStack**: orbstack.dev. Smaller and faster to start.
- **Colima**: `brew install colima docker`, then `colima start`.

Start it, then check that the `docker` command can talk to it:

```console
$ docker run --rm hello-world
...
Hello from Docker!
...
```

## Step 3: Build the course's Linux image

An *image* is a recipe for a little Linux system. This repo's recipe is the
`Dockerfile` at the top of the repo: Debian Linux plus `gcc`, `as`, `ld`,
`gdb`, `make`, and a few inspection tools. Build it once, from the repo root:

```console
$ cd path/to/arm-lessons
$ docker build --platform linux/arm64 -t arm-lessons .
```

This takes a minute or two the first time. `-t arm-lessons` names the image so
you can refer to it later. (If you skip this step, the script in step 4 builds
it for you the first time you run it.)

## Step 4: Open a Linux shell

```console
$ ./scripts/linux-shell.sh
root@3f2a9c1e7b44:/work#
```

The prompt changed. You are now inside Linux, as the user `root`, in the
directory `/work`. `/work` *is* this repo: the script mounts your Mac's copy
of it there. A file you edit on the Mac appears instantly inside the
container, and a file you build inside the container appears on the Mac.

Prove you are on 64-bit ARM Linux:

```console
root@3f2a9c1e7b44:/work# uname -sm
Linux aarch64
```

To leave, type `exit` or press Ctrl-D. You are back on macOS. Nothing you
installed inside the container survives that, but your files in `/work` do,
because they live on your Mac.

You can also jump straight into a lesson directory:

```console
$ ./scripts/linux-shell.sh lessons/00-setup/linux/examples
root@...:/work/lessons/00-setup/linux/examples#
```

From here on, terminal sessions are shown with a plain `$` prompt. In a
lesson's `linux/` folder that always means *inside the container*. In its
`apple-silicon/` folder it means your normal macOS Terminal.

## Step 5: Build and run your first program

Inside the container:

```console
$ cd /work/lessons/00-setup/linux/examples
$ ls
Makefile  check.s
```

`check.s` is an assembly program. It is plain text; open it in your editor
and have a look. **You are not expected to understand it yet.** By the end of
lesson 05 you will understand every single line. Each line has a comment
saying which lesson explains it.

Build it:

```console
$ make
cc -g -nostdlib -static -o check check.s
$ ls
Makefile  check  check.s
```

`make` read the `Makefile`, saw `check.s`, and ran `cc` to turn it into a
program called `check` (no extension). On this Linux system `cc` is just
another name for `gcc`, the GNU C compiler, which also knows how to build
assembly files. Now, before you run it: the comment
at the top of `check.s` says what it should do. What do you expect to see?

```console
$ ./check
toolchain works
```

The `./` means "the program in this directory". Without it, the shell looks
only in the usual system places and says `command not found`.

## Exit status: a program's one-number answer

Every program, when it ends, hands the operating system a small number called
its **exit status**. By convention 0 means "success" and anything else means
"something went wrong". The shell keeps the last program's exit status in a
special variable, `$?`. Print it *straight after* running the program:

```console
$ ./check
toolchain works
$ echo $?
0
```

In C, the exit status is what `main` returns, or what you pass to `exit()`:

```c
int main(void) {
    return 0;       /* exit status 0 */
}
```

Exit status matters a lot in the early lessons. Until lesson 05 your programs
cannot print anything, so the exit status is the only way they can tell you
an answer.

`echo $?` reports on the *last* command, and `echo` itself is a command. Run
`echo $?` twice and the second one prints the status of the first `echo`
(which is 0). Always check it immediately.

## How `make` works here

Every `examples/` and `solutions/` directory has a two-line `Makefile`:

```make
# `make` builds every .s file here into a program; `make clean` removes them.
include ../../../../mk/linux.mk
```

The real rules live in `mk/linux.mk` at the top of the repo. They say: for
every file `foo.s` in this directory, build a program `foo`. The commands you
will use:

| Command | What it does |
|---------|--------------|
| `make` | Build every program whose `.s` file changed since the last build. |
| `make check` | Build just `check`. |
| `make clean` | Delete the built programs, leaving only the source. |

Run `make` twice in a row. The second time it prints something like
`make: Nothing to be done for 'all'.`: nothing changed, so nothing to do.

What does `cc -g -nostdlib -static` mean? Lesson 04 explains it properly.
Briefly: `gcc` here is acting as a front end that runs the *assembler* and
then the *linker*; `-g` keeps information for the debugger; `-nostdlib
-static` means "this program uses no C library, and needs nothing from
outside itself".

## How each lesson works

Every lesson directory looks like this:

```
lessons/NN-slug/
  README.md            the lesson: read it top to bottom
  exercises.md         homework
  answers.md           answers to the written questions
  linux/
    examples/          every program the lesson shows, plus a Makefile
    solutions/         worked solutions to the programming exercises
    work/              YOUR directory: create it yourself
  apple-silicon/
    README.md          what is different on macOS for this lesson
    examples/          the macOS versions of the examples
    solutions/         the macOS versions of the solutions
    work/              your macOS homework
```

The routine for each lesson:

1. Read `README.md`. Every time it shows a program, find it in
   `linux/examples/`, build it, and run it yourself. When the text asks you
   to predict something, actually stop and predict before running.
2. Read `apple-silicon/README.md` and run the macOS versions natively on your
   Mac.
3. Do `exercises.md` in a `work/` directory.
4. Only then compare with `answers.md` and the `solutions/` folders.

### Your `work/` directory

Do your homework in a directory called `work/` inside the flavor folder:
`linux/work/` in the container, `apple-silicon/work/` on macOS. Git ignores
every `work/` directory, so your experiments never get mixed up with the
course files. Make one and give it the same Makefile as `examples/`:

```console
$ cd /work/lessons/00-setup/linux
$ mkdir work
$ cp examples/Makefile work/
$ cd work
```

The Makefile's `include ../../../../mk/linux.mk` path still works from
`work/`, because `work/` is at the same depth as `examples/`. Now any `.s`
file you create in `work/` builds with `make`.

### Solutions

Try every exercise before you look. Getting stuck and then un-stuck is where
the learning happens. When you do look, programming solutions are in
`linux/solutions/exN.s` (and `apple-silicon/solutions/exN.s`), and answers to
written questions are in `answers.md`.

## Editing assembly files

Use any plain-text editor. Some tips:

- **VS Code** works well. Search the extensions for "Arm Assembly" (by
  dan-c-underwood) for syntax colouring of `.s` files.
- Other good choices: Zed, Sublime Text, BBEdit, or `vim`/`nano` in Terminal.
  Do not use TextEdit or Word; they can insert "smart" quotes and invisible
  formatting that the assembler rejects.
- Edit on the Mac and build in the container. Keep two Terminal tabs: one on
  macOS for the editor and git, one inside `./scripts/linux-shell.sh`.
- Use spaces, not tabs, in `.s` files: four spaces before each instruction,
  labels at the far left. The repo's `.editorconfig` sets this up for editors
  that support it. (The one exception is a Makefile, which needs real tabs.)
- Turn on "show whitespace" if your editor has it.
- Save before you run `make`. "I changed it but nothing happened" is almost
  always an unsaved file.

### Recommended: arm-tools

[arm-tools](https://github.com/maytech-labs/arm-tools) are tools made
alongside this course, and they make it a lot easier. Installing them is
optional, but recommended. There are two programs:

- **`armls`** runs inside your editor. It underlines mistakes as you type,
  using the same error messages the assembler would give. Hover over an
  instruction to see what it does, or over a register to see its job.
- **`armtool`** runs in Terminal. `armtool check` finds errors without
  building anything. `armtool lint` also finds mistakes that assemble fine
  but break at run time, like a function that forgets to save a register.

Install them on the Mac:

```console
$ brew tap maytech-labs/tap
$ brew trust maytech-labs/tap
$ brew install arm-tools
```

(Or download `armls` and `armtool` from the
[releases page](https://github.com/maytech-labs/arm-tools/releases) and put
them on your `PATH`.) Then connect `armls` to your editor:
[arm-tools/editors](https://github.com/maytech-labs/arm-tools/tree/main/editors)
has setups for VS Code, Neovim, and Helix.

Run `armtool` on the Mac, even for the Linux flavor. The repo comes with
`armtool.toml` files that tell the tools which folders hold Linux code and
which hold macOS code:

```console
$ armtool check lessons/00-setup/linux/examples
armtool: 1 file checked, no errors or warnings
$ armtool lint lessons/00-setup/linux/work
```

Most warnings will make sense only once a later lesson explains them. Until
then, `armtool explain <rule>` describes any rule a warning names. A few
example programs make mistakes on purpose (lessons 13 to 15 each break a rule
and then show what goes wrong), and the linter flags those too. arm-tools is
pre-release, so if it flags code you are sure is correct, trust the lesson
and run the program.

## Looking inside a program

A program is just a file of bytes. Three tools let you look at those bytes in
a way people can read. Try each on `check` now. You will understand the output
much better after lesson 03; for now, just get used to running them.

**`file`** says what kind of file something is:

```console
$ file check
check: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, BuildID[sha1]=..., with debug_info, not stripped
$ file check.s
check.s: assembler source, ASCII text
```

"ELF" is the format Linux uses for programs. "ARM aarch64" is the kind of CPU
it is for.

**`nm`** lists the *symbols* in a program: names that the program gave to
places in itself.

```console
$ nm check
0000000000410140 D __bss_end__
...
000000000040010c T _start
0000000000000010 a len
0000000000410130 d msg
```

You can see `_start`, `len`, and `msg` from `check.s`, plus a few names the
linker added (the ones starting with `_`). The long hex number in front is
where each one ended up in memory (hex is lesson 01).

**`objdump -d`** *disassembles*: it turns the machine code back into
assembly text.

```console
$ objdump -d check

check:     file format elf64-littleaarch64

Disassembly of section .text:

000000000040010c <_start>:
  40010c:	d2800020 	mov	x0, #0x1                   	// #1
  400110:	90000081 	adrp	x1, 410000 <_start+0xfef4>
  400114:	9104c021 	add	x1, x1, #0x130
  400118:	d2800202 	mov	x2, #0x10                  	// #16
  ...
```

Look at the middle column: each instruction you wrote became an 8-digit hex
number. That number *is* the instruction, as the CPU sees it. Lesson 03 is all
about this.

(The exact addresses on your machine may differ slightly from these. That is
fine.)

## A C refresher

This course explains every assembly construct by showing the C you would
write for it. You need to read simple C: variables, `if`, loops, functions,
arrays, pointers, structs. You do not need to be an expert.

If your C is rusty or new:

- *The C Programming Language*, Kernighan and Ritchie ("K&R"), 2nd edition.
  Short and clear. Chapters 1 to 6 cover everything this course leans on.
  Read chapter 1 now; come back to chapter 5 (pointers) before lesson 12.
- [Compiler Explorer](https://godbolt.org) lets you type C and see the
  assembly a compiler makes. From lesson 16 on we use it a lot.

The Linux container has `gcc`, so you can compile and run C right there:

```console
$ cat > hello.c
#include <stdio.h>
int main(void) { printf("hi\n"); return 3; }
^D
$ gcc hello.c -o hello && ./hello; echo $?
hi
3
```

(Type the two lines of C, then press Ctrl-D for the `^D`. Do this in your
`work/` directory.) On the Mac, `clang` does the same.

## C to assembly

You have not written any assembly yet, so this table is tiny. It grows every
lesson.

| C | Assembly (Linux) | Lesson |
|---|------------------|--------|
| `int main(void) { ... }` | `_start:` | 04 |
| `return 0;` from `main` / `exit(0);` | `mov x0, #0` / `mov x8, #93` / `svc #0` | 04 |
| `printf("toolchain works\n");` | the `write` system call | 05 |

## Common mistakes

- **Running `make` on the Mac instead of in the container.** In `lessons/`,
  `make` uses Linux rules. On macOS it fails with errors like
  `ADR/ADRP relocations must be GOT relative` or `unknown AArch64 fixup kind!`,
  or builds something that will not run. Check your prompt: inside the
  container it starts with `root@`.
- **`./check: cannot execute binary file: Exec format error`** on the Mac.
  You built it in the container (it is a Linux program) and then tried to run
  it on macOS. Linux programs run in the container; macOS programs (from
  `apple-silicon/` folders) run on the Mac.
- **`docker: Cannot connect to the Docker daemon`.** Docker Desktop (or
  OrbStack, or Colima) is not running. Start it and try again.
- **`command not found` for `check`.** You typed `check` instead of `./check`.
- **`echo $?` prints 0 when you expected something else.** You ran another
  command in between (even `echo` or `ls`). Run the program again and check
  `$?` immediately.
- **Mixing up builds.** If you run `make` in the container and later on
  the Mac (or the other way round) in the *same* directory, `make` may think
  the program is up to date when it is the wrong kind. `make clean` first.

## Recap

- Your Mac's CPU is AArch64. Linux and macOS run the same instructions; what
  differs is the operating system around them.
- The Linux flavor runs in an arm64 Linux container: `./scripts/linux-shell.sh`.
  The repo is mounted at `/work`.
- `make` builds every `foo.s` in a directory into a program `foo`; `make clean`
  removes them.
- Run a program with `./name`. Read its exit status with `echo $?`, straight
  away.
- `file`, `nm`, and `objdump -d` show what kind of file a program is, which
  names it contains, and its instructions.
- Do homework in `linux/work/` (or `apple-silicon/work/`) with a copy of the
  Makefile. Try before reading the solutions.
- After each lesson, read its `apple-silicon/README.md`.
- Optional but recommended: install arm-tools so your editor catches mistakes
  as you type, and run `armtool lint` on your homework.

## Homework

[exercises.md](exercises.md)
