# Lesson 31 on macOS: Capstone

Do [lesson 31](../../lessons/31-capstone/README.md) in the main track first. The
projects and their specifications are the same on macOS, and so are the tests:
the exercises are in
[../../lessons/31-capstone/exercises.md](../../lessons/31-capstone/exercises.md).
This page covers what changes when you write them as macOS programs.

## Working and testing

Work in `work/` inside this directory, one directory per project, with the
Apple include line:

```console
$ mkdir -p work/wc && cd work/wc
$ printf 'include ../../../../mk/apple.mk\n' > Makefile
```

The tests live in the main track. Run `check.sh` from there, pointing it at your
macOS binary (it works with the old bash 3.2 that macOS ships):

```console
$ cd apple-silicon/31-capstone
$ ../../lessons/31-capstone/tests/check.sh wc work/wc/wc
PASS wc/stdin-all
...
11 passed, 0 failed
$ make -C solutions
$ ../../lessons/31-capstone/tests/check.sh all solutions
```

The expected outputs are identical on both systems, error messages included:
`strerror(ENOENT)` is `No such file or directory` on both.

One trap: macOS already has `wc` (and `life` is not unusual either) on the
`PATH`. Always run yours as `./wc`, or you will be testing Apple's.

## What differs

Nothing in the projects needs a new idea on macOS. The differences are the same
ones you have met since lesson 16, but a 400-line program meets all of them:

| | Linux | macOS |
|-|-------|-------|
| Entry point and libc names | `main`, `printf` | `_main`, `_printf` |
| Your own functions | `count_stream` | any name: they are local to the file, so no `_` is needed (it only matters for symbols C can see) |
| stdin / stdout / stderr | `:got:stdin` / `:got_lo12:stdin` | `___stdinp@GOTPAGE` / `___stdinp@GOTPAGEOFF` (and `___stdoutp`, `___stderrp`) |
| `errno` | `bl __errno_location` | `bl ___error` |
| Strings | `.section .rodata` | `.section __TEXT,__cstring` |
| `printf("%8ld", n)` | `n` in `x1` | `n` on the stack at `[sp]` |
| `char` | unsigned | **signed** |

### Variadic calls are everywhere

`printf` and `fprintf` appear in every project, and every argument after the
format string goes on the stack, 8 bytes per argument (lesson 16). The
solutions use the same three-line pattern each time:

```asm
    sub sp, sp, #16             // room for up to two 8-byte slots
    str x9, [sp]                // first variadic argument
    bl _printf
    add sp, sp, #16
```

With two arguments, store both with one `stp`. For example `wc`'s
"cannot open" message, `fprintf(stderr, "wc: %s: %s\n", name, strerror(errno))`:
`stderr` and the format are ordinary arguments, so they go in `x0` and `x1`;
`name` and the message are variadic, so they go in the two slots:

```asm
    bl ___error
    ldr w0, [x0]                // errno
    bl _strerror                // x0 = message
    sub sp, sp, #16
    ldr x9, [x20, w21, sxtw #3] // argv[i]
    stp x9, x0, [sp]            // slot 0 = name, slot 1 = message
    adrp x0, ___stderrp@GOTPAGE
    ldr x0, [x0, ___stderrp@GOTPAGEOFF]
    ldr x0, [x0]                // x0 = stderr
    adrp x1, fmt_open@PAGE
    add x1, x1, fmt_open@PAGEOFF
    bl _fprintf
    add sp, sp, #16
```

Notice the order: the message is in `x0` when `_strerror` returns, so it is
stored *before* `x0` is reused for `stderr`.

Store the full 8-byte register even for an `int` or a `char`: `printf` reads one
8-byte slot per argument. Writing a `w` register clears the top half of the `x`
register, so `str x20, [sp]` after `mov w20, ...` is safe.

If one function does many variadic calls, you can instead reserve the
argument slots once at the bottom of its frame and leave `sp` alone. Both work;
the `sub`/`add` pair is easier to get right.

### Signed char

On macOS `char` is signed. That matters only where your C reference reads a
`char` and compares it as a number: a byte of 200 is `-56` as a `char`. In
assembly you choose the load yourself, so the rule is the same on both
systems: use `ldrb` (zero-extending) for text, Brainfuck cells and hash input.
The C version of `wordfreq` should cast to `unsigned char` before hashing, or
your C and your assembly will disagree on macOS for non-ASCII input.

### Everything else is the same

`fgets`, `fread`, `fopen`, `fseek`/`ftell`, `strtol`, `strcmp`, `strdup`,
`calloc`, `qsort`, `getchar`, `putchar`, `fwrite`, `atoi` and `usleep` all take
the same arguments in the same registers (none of them is variadic). `SEEK_SET`
and `SEEK_END` are 0 and 2 on both systems. A 64-bit FNV-1a hash and `udiv`/`sdiv`
are just instructions.

### lldb instead of gdb

```console
$ lldb -- ./wc -l poem.txt
(lldb) breakpoint set -n count_stream
(lldb) run
(lldb) register read x9 x10
(lldb) thread backtrace
(lldb) stepi
```

`bt` also works as a short form of `thread backtrace`, and `x/s $x0` reads a
string as in gdb.

## The examples

```console
$ cd examples
$ make
```

### linecat.s

The same program as the main track's, with the Apple spellings. The `printf`
call is the interesting part: `printf("%4d: %s", n, line)` has two variadic
arguments, `n` and the address of the line buffer:

```asm
    add x9, sp, #32             // line (computed before sp moves!)
    sub sp, sp, #16
    stp x19, x9, [sp]           // variadic: n in slot 0, line in slot 1
    bl _printf
    add sp, sp, #16
```

The buffer's address is computed *before* `sub sp`: afterwards it would be at
`sp + 48`. Mixing up addresses relative to a moving `sp` is the most common
macOS-only bug in these projects.

```console
$ ./linecat < poem.txt
   1: The quick brown fox
   2: jumps over
   3: the lazy dog.
   4: 
   5: It was not amused.
```

`stdin` is the libSystem variable `__stdinp` (with the extra underscore, three
in all: `___stdinp`), loaded through the GOT once and kept in `x20`.

### slurp.s

Also the same, except for the one variadic call, `printf("%ld bytes\n", n)`,
which puts `n` at `[sp]`, and `stdout` for `fwrite`, which is `___stdoutp`:

```console
$ ./slurp poem.txt
65 bytes
The quick brown fox
jumps over
the lazy dog.

It was not amused.
$ ./slurp nope.txt; echo $?
nope.txt: No such file or directory
1
```

## The solutions

`solutions/wc/`, `solutions/rpn/`, `solutions/wordfreq/`, `solutions/life/` and
`solutions/bf/` are the macOS versions of the main track's solutions, with the
same design; only the differences above change. `make -C solutions` builds all five;
the design notes are in
[../../lessons/31-capstone/solutions/README.md](../../lessons/31-capstone/solutions/README.md).

## Where to go next on a Mac

Everything in the main track's "Where to go next" applies. A few Mac-specific
pointers:

- Apple's "Writing ARM64 code for Apple platforms" documents every way the
  macOS ABI differs from AAPCS64.
- `clang -O2 -S` (or `otool -tvV` on any binary, even system ones) shows you
  what Apple's compiler does, including the `@PAGE`/`@PAGEOFF` and GOT forms
  you write by hand.
- Instruments (part of Xcode) has a CPU Counters template for measuring
  performance on Apple's cores.
- For bare-metal experiments, `qemu-system-aarch64` runs on macOS too
  (`brew install qemu`).
