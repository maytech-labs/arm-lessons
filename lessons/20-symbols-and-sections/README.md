# Lesson 20: Symbols, sections, and multi-file programs

## Goals

After this lesson you can:

- Put every kind of C variable in the right section: `.text`, `.rodata`,
  `.data`, `.bss`.
- Explain global and local symbols, and translate C's `static` and `extern`.
- Write a static local variable.
- Split a program across several `.s` files and link them together.
- Read `nm` output and diagnose "undefined reference" and "multiple
  definition" errors.
- Use numbered local labels (`1:`, `1b`, `1f`).
- Write assembler macros with `.macro`, share them with `.include`, and
  generate data with `.rept` and `.set`.

## Before you start

You need lesson 03 (assembler and linker), 05 (sections), 14-16 (functions,
calling C). Real programs are not one file; this lesson is about how pieces
are named, placed, and joined.

```console
# cd lessons/20-symbols-and-sections/examples && make
```

## Sections, again

| Section | Holds | C example | In the file? | Writable? |
|---------|-------|-----------|--------------|-----------|
| `.text` | instructions | functions | yes | no |
| `.rodata` | constants | `const int t[] = {...};`, string literals | yes | no |
| `.data` | variables with a starting value | `long counter = 5;` | yes | yes |
| `.bss` | variables that start at zero | `long buffer[100];` | **no**, only its size | yes |

`.bss` takes no space in the executable: the loader just maps that many zero
bytes. A C global without an initialiser (or initialised to 0) goes there.

The loader maps each section with the permissions in the last two columns.
Writing to `.rodata` or `.text` is a crash, which is exactly how C's `const`
is enforced. `examples/const_write.s`:

```asm
    adrp x0, msg
    add x0, x0, :lo12:msg
    mov w1, #'j'
    strb w1, [x0]               // the page is mapped read-only: the CPU faults
```

```console
# ./const_write; echo $?
Segmentation fault (core dumped)
139
```

`examples/sections.s` puts one symbol in each section and checks the order the
linker chose: code, then constants, then data, then bss, with the stack far
above them all.

```console
# ./sections
code < constants: yes
constants < data: yes
data < bss: yes
bss < stack: yes
counter = 5, buffer[0] = 0
# objdump -h sections
```

`objdump -h` lists the sections with their sizes and addresses.

## Symbols: global and local

Every label is a **symbol**. By default, a symbol is **local**: the assembler
uses it inside the file, but the linker never sees it. `.global name` makes it
**global**: visible to the linker, and so to every other file.

| C | Assembly |
|---|----------|
| `long counter;` (file scope) | `.global counter` + the label |
| `static long counter;` | just the label: no `.global` |
| `int f(void) {...}` | `.global f` + `f:` |
| `static int f(void) {...}` | just `f:` |
| `extern long counter;` | nothing: an undefined symbol is assumed external |

C's `static` on a file-scope name means "local to this file". So in assembly it
is the *absence* of `.global`.

### Static local variables

```c
long next_ticket(void) {
    static long n = 100;         // initialised once, keeps its value
    return n++;
}
```

A `static` local is a global variable in disguise: it lives in `.data` (or
`.bss`), not on the stack, and it is only "local" because its name is visible
inside one function. In assembly, give it a local symbol with a name that says
whom it belongs to. `examples/static_local.s`:

```asm
    .data
    .p2align 3
next_ticket_n:                  // no .global: local to this file, like C static
    .quad 100
...
next_ticket:
    adrp x9, next_ticket_n
    add x9, x9, :lo12:next_ticket_n
    ldr x0, [x9]                // return the old value...
    add x10, x0, #1
    str x10, [x9]               // ...and store n + 1 for next time
    ret
```

```console
# ./static_local
100 101 102
```

## Multi-file programs

`examples/app.s` and `examples/mathlib.s` are one program in two files.
`mathlib.s` exports three names and keeps one private:

```asm
    .global square              // exported: other files may call these
    .global cube
    .global mathlib_calls
    ...
// long mul3(long a, long b, long c): not .global, so private to this file
mul3:
```

`app.s` just uses `square`, `cube`, and `mathlib_calls`. It does not declare
them: the assembler leaves any name it cannot find as an **undefined symbol**
for the linker to resolve.

The Makefile builds them together:

```make
PARTS := mathlib
include ../../../mk/linux.mk

app: app.s mathlib.s
	$(CC) $(ASFLAGS) -o $@ app.s mathlib.s
```

`PARTS` tells the shared rules that `mathlib.s` is not a program by itself (it
has no `main`), so they do not try to link it alone.

```console
# ./app
square(7) = 49, cube(3) = 27, calls = 2
```

### Reading `nm`

`make app.o mathlib.o` assembles each file without linking. `nm` lists each
object file's symbols:

```console
# nm app.o mathlib.o

app.o:
                 U cube
0000000000000000 r fmt
0000000000000000 T main
                 U mathlib_calls
                 U printf
                 U square

mathlib.o:
000000000000001c T cube
0000000000000000 D mathlib_calls
000000000000004c t mul3
0000000000000000 T square
```

| Letter | Meaning |
|--------|---------|
| `U` | **undefined**: used here, must be defined elsewhere |
| `T` / `t` | text (code), global / local |
| `D` / `d` | data, global / local |
| `B` / `b` | bss, global / local |
| `R` / `r` | read-only data, global / local |

Uppercase is global, lowercase is local. The linker's job, in one sentence:
match every `U` in every file with exactly one uppercase definition somewhere.

### The two classic link errors

- **Undefined reference**: a `U` that nothing defines. Remove `.global cube`
  from `mathlib.s` and rebuild: `undefined reference to 'cube'`. The function
  exists, but nobody outside its file can see it.
- **Multiple definition**: two files define the same global name. Add a global
  `square` to `app.s` too: `multiple definition of 'square'`. (Two *local*
  symbols with the same name in different files are fine: they never meet.)

These are the same errors you get in C, for the same reasons.

## Numbered local labels

Every label must be unique in a file, which is painful for loop labels. GNU
assembler syntax has **numbered local labels**: a label that is just a number
(`1:`) may appear many times. A reference says which one: `1b` is the nearest
`1:` **b**ackwards, `1f` the nearest **f**orwards. `examples/local_labels.s`:

```asm
1:  ldrb w10, [x9], #1          // the outer loop: label "1"
    cbz w10, 3f                 // end of string: jump FORWARD to the next "3"
    ...
2:  ldrb w12, [x11], #1         // the inner loop: label "2"
    cbz w12, 1b                 // not a vowel: back to the most recent "1"
    cmp w10, w12
    b.ne 2b                     // try the next vowel: back to the most recent "2"
    add x2, x2, #1
    b 1b
3:
```

They are ideal for short loops and skips inside a function. For anything you
would want to see in a backtrace or set a breakpoint on, use a real name.

## Macros

A **macro** is a named piece of text the assembler pastes in, with
parameters substituted. `examples/macros.inc`:

```asm
    .macro LOAD_ADDR reg, sym
    adrp \reg, \sym
    add \reg, \reg, :lo12:\sym
    .endm

    .macro PROLOGUE
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    .endm
```

Inside the macro, `\reg` and `\sym` are replaced by the arguments.
`LOAD_ADDR x0, head` becomes the two instructions. `.include "macros.inc"`
pastes a whole file in, like C's `#include`.

A macro generates code at every use: it is not a function call, there is no
`bl`. Use macros for short repeated patterns like address loading and
prologues; use functions for anything substantial.

### Generating data: `.rept` and `.set`

`.rept N` ... `.endr` repeats its lines N times. `.set` (like `.equ`, but
re-assignable) gives you a counter. `examples/macros.s` makes the assembler
build a table of squares:

```asm
squares:
    .set i, 0
    .rept 10                    // the next lines, ten times...
    .quad i * i                 // ...with i = 0, 1, 2, ... 9
    .set i, i + 1
    .endr
```

```console
# ./macros
squares: 0 1 4 9 16 25 36 49 64 81
```

No instruction computes the squares; they are in the file. This is how you
build lookup tables.

## C to assembly

| C | Assembly |
|---|----------|
| `long g = 5;` | `.data` / `.global g` / `g: .quad 5` |
| `long z;` | `.bss` / `.global z` / `z: .space 8` |
| `static long s = 1;` (file scope) | `.data` / `s: .quad 1` (no `.global`) |
| `static long n;` inside `f` | `.bss` / `f_n: .space 8` |
| `const int t[] = {1, 2};` | `.section .rodata` / `t: .word 1, 2` |
| `extern long g;` / `int f(void);` | nothing; just use the name |
| `static int helper(...)` | `helper:` without `.global` |
| `#include "x.h"` | `.include "x.inc"` |
| `#define SIZE 16` | `.equ SIZE, 16` |
| function-like `#define` | `.macro` ... `.endm` |

## Common mistakes

- **Forgetting `.global`** on something another file needs: undefined
  reference.
- **`.global` on a private helper** that another file also defines: multiple
  definition.
- **Initialised data in `.bss`.** `.bss` can only hold zeros: `.quad 5` there is
  an error or silently becomes 0. Use `.data`.
- **Writing to `.rodata`**: a crash.
- **`1b` when you meant `1f`**: the branch goes the wrong way and loops, or
  skips the loop.
- **Expecting a macro to behave like a function**: it has no frame, its labels
  are duplicated at every use (use numbered labels inside macros), and its
  code is copied each time.
- **Linking a part on its own.** A file without `main` cannot be a program:
  list it in `PARTS`.

## Recap

- `.text` code, `.rodata` constants, `.data` initialised variables, `.bss`
  zeroed variables (no file space).
- Labels are local unless `.global`; C's `static` is "no `.global`".
- Undefined names are external; the linker resolves them across files.
- `nm`: `U` undefined, `T D B R` global, `t d b r` local.
- Undefined reference = nobody exports it; multiple definition = two export
  it.
- `1:` with `1b`/`1f` gives reusable local labels.
- `.macro`/`.endm`, `.include`, `.rept`/`.endr`, `.set` move repetitive work to
  the assembler.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/20-symbols-and-sections/README.md)
next.
