# Lesson 16 on Apple Silicon: Calling C

Read [lesson 16](../../lessons/16-calling-c/README.md) first. Everything there
about the C runtime, saving `x30`, callee-saved registers and calling
assembly from C is true on macOS too. This page covers what is different, and
one difference is big: **how `printf` gets its arguments.**

Build and run the macOS examples natively:

```console
$ cd apple-silicon/16-calling-c/examples
$ make
```

## What changes, in one table

| | Linux | macOS |
|-|-------|-------|
| Our entry point | `main` | `_main` (you have been writing it since lesson 04) |
| Calling a C function | `bl puts` | `bl _puts`: every C name gets a leading `_` |
| C name of an assembly function `_sum3` | | `sum3` (C adds the `_` itself) |
| String section | `.section .rodata` | `.section __TEXT,__cstring` |
| Address of a label | `adrp` + `:lo12:` | `adrp x0, msg@PAGE` + `add x0, x0, msg@PAGEOFF` |
| `printf`'s extra arguments | `x1`, `x2`, ... | **on the stack**, 8 bytes each |
| Build | `gcc` | `clang -arch arm64` (the Makefile does it) |

## `_main` was always a libc program

On macOS you could never write a freestanding `_start` program: every
executable is linked with libSystem (Apple's C library), and the kernel starts
it through `dyld`, the dynamic loader. So the switch in this lesson is smaller
for you: you stop making raw `svc #0x80` system calls (which Apple does not
promise to keep working) and call libSystem functions instead, the way every
real macOS program does.

### What runs before `_main`

1. The kernel loads your program and `dyld`.
2. `dyld` loads libSystem and the other libraries, connects your calls such
   as `bl _puts` to the real functions, and runs the libraries' initialisers.
3. It looks up the entry point recorded in the executable and calls it:

   ```console
   $ otool -l ret42 | grep -A3 LC_MAIN
          cmd LC_MAIN
      cmdsize 24
     entryoff 728
    stacksize 0
   ```

   `entryoff` is where `_main` is in the file.
4. When `_main` returns, the startup code calls `exit()` with the return value,
   which flushes `stdout` and ends the process.

[`examples/ret42.s`](examples/ret42.s) is the lesson's `ret42.s` with `_main`:

```console
$ ./ret42; echo $?
42
```

## The underscore

Mach-O, the macOS object format, puts an `_` in front of every C name. When C
code says `puts`, the symbol is `_puts`. So in assembly you write `bl _puts`,
`bl _printf`, `bl _strlen`, `bl _exit`. `nm` shows it:

```console
$ nm hello
0000000100000000 T __mh_execute_header
0000000100000410 T _main
                 U _puts
000000010000043c s msg
```

`U _puts` means "used here, defined in a library". Our own label `msg` has no
underscore because no C code ever refers to it. Labels that only your own
assembly uses can be named anything; only names shared with C need the `_`.

[`examples/hello.s`](examples/hello.s) is otherwise identical to the Linux
version:

```asm
    adrp    x0, msg@PAGE            // x0 = first argument = address of msg
    add     x0, x0, msg@PAGEOFF
    bl      _puts                   // C's puts is _puts
```

## The variadic rule

`printf` is a *variadic* function: its prototype is

```c
int printf(const char *format, ...);
```

The `...` means "any number of extra arguments of any type". Apple's version
of the calling convention handles those differently from Linux:

- **Named** arguments (here only `format`) go in registers as usual: `x0`.
- **Every variadic argument** (everything that matches the `...`) goes **on
  the stack**, in order, **one 8-byte slot each**: the first at `[sp]`, the
  second at `[sp, #8]`, the third at `[sp, #16]`, and so on.
- The slots are 8 bytes even for an `int`. Store the full `x` register.
- `sp` must still be 16-byte aligned at the `bl`, so the area you reserve is
  rounded up: 1 or 2 slots need 16 bytes, 3 or 4 need 32, and so on.

Why? A variadic function does not know what types it was passed, so it has to
walk through them in memory one by one. Linux's convention makes `printf` copy
the registers to memory first; Apple's makes the caller put them there in the
first place.

Here is `printf("%d + %d = %d\n", 2, 3, 5)` the macOS way, from
[`examples/printf_args.s`](examples/printf_args.s):

```asm
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #32             // room for 3 slots, rounded up to 16

    adrp    x0, fmt_sum@PAGE        // format string: in x0 as usual
    add     x0, x0, fmt_sum@PAGEOFF
    mov     x9, #2
    str     x9, [sp]                // 1st variadic argument: slot 0
    mov     x9, #3
    str     x9, [sp, #8]            // 2nd: slot 1
    mov     x9, #5
    str     x9, [sp, #16]           // 3rd: slot 2
    bl      _printf
```

Just before the `bl`, memory looks like this:

```
        sp + 24  | (unused padding) |
        sp + 16  |        5         |   3rd variadic argument
        sp + 8   |        3         |   2nd
        sp + 0   |        2         |   1st
```

The second call, `printf("%s is %ld years old\n", "Ada", 36L)`, reuses the same
area: the pointer to `"Ada"` in slot 0, `36` in slot 1. When `_main` is done
with calls, `add sp, sp, #32` gives the area back before the epilogue.

```console
$ ./printf_args
2 + 3 = 5
Ada is 36 years old
```

You do not have to reserve a fresh area for every call. A function that calls
`printf` many times can reserve the slots once, after its prologue, and reuse
them, as `greet.s` does below.

### What clang does

Compile the C version and compare:

```console
$ clang -S -O2 -o - printf.c       # a file with just that printf in main
...
	mov	w8, #5
	str	x8, [sp, #16]
	mov	w8, #3
	mov	w9, #2
	stp	x9, x8, [sp]
	adrp	x0, l_.str@PAGE
	add	x0, x0, l_.str@PAGEOFF
	bl	_printf
```

The same three slots, filled with `str` and `stp`.

### The wrong version

Code written for Linux puts the numbers in `w1`, `w2`, `w3`. It assembles and
links without a single warning, and then prints the wrong thing.
[`examples/printf_wrong.s`](examples/printf_wrong.s) does exactly that, but
first leaves `7`, `8` and `9` in the three stack slots, so you can see where
`printf` really looks:

```asm
    mov     x9, #7                  // "leftover" values in the three slots
    str     x9, [sp]
    mov     x9, #8
    str     x9, [sp, #8]
    mov     x9, #9
    str     x9, [sp, #16]

    adrp    x0, fmt_sum@PAGE
    add     x0, x0, fmt_sum@PAGEOFF
    mov     w1, #2                  // WRONG on macOS: printf ignores x1-x7
    mov     w2, #3                  // for its variadic arguments
    mov     w3, #5
    bl      _printf
```

Predict the output before you run it.

```console
$ ./printf_wrong
7 + 8 = 9
```

`printf` never looked at `w1`-`w3`. In real wrong code nobody stored anything
in those slots, so you get whatever old bytes happen to be on the stack, and
the numbers change from run to run, for example `-16 + 1838897480 = -197164800`.
With `%s` it is worse: `printf` treats a random number as a pointer and the
program crashes. **If `printf` prints garbage on your Mac, check this first.**

The rule applies to every variadic function: `printf`, `fprintf`, `sprintf`,
`snprintf`, `scanf`, `open` (its `mode` argument), and your own `...` functions
(lesson 26). Ordinary functions such as `puts`, `strlen`, `putchar` and
`exit` take their arguments in registers, the same as on Linux.

## `libc_tour.s`

[`examples/libc_tour.s`](examples/libc_tour.s) mixes both kinds of call:

```asm
    mov     x0, x19
    bl      _strlen                 // not variadic: argument in x0 as usual
    mov     x20, x0                 // x20 = n (kept across calls)

    sub     sp, sp, #16             // printf is variadic: 2 slots on the stack
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    stp     x19, x20, [sp]          // slot 0 = s, slot 1 = n
    bl      _printf
    add     sp, sp, #16
    ...
    ldrb    w0, [x19, x20]          // putchar is not variadic: w0
    bl      _putchar
    ...
    mov     w0, #3
    bl      _exit                   // flushes stdout, ends the process
```

`stp` stores two registers into two neighbouring slots in one instruction:
slot 0 gets `x19`, slot 1 gets `x20`.

```console
$ ./libc_tour; echo $?
"assembly" has 8 characters
ylbmessa
3
```

## Calling assembly from C

C adds the underscore when it compiles, so the assembly defines `_sum3` and
the C file says `sum3`. [`examples/sum3.s`](examples/sum3.s):

```asm
    .global _sum3
    .p2align 2
_sum3:
    add     x0, x0, x1
    add     x0, x0, x2
    ret
```

[`examples/sum3_main.c`](examples/sum3_main.c) is identical to the Linux file:
`long sum3(long a, long b, long c);` and two calls. The Makefile rule is the
same too, with `clang`:

```console
$ make sum3
clang -g -arch arm64 -o sum3 sum3_main.c sum3.s
$ ./sum3
sum3(1, 2, 3) = 6
sum3(100, -50, 7) = 57
```

If you forget the underscore and define `sum3:` instead, the link fails with
`Undefined symbols for architecture arm64: "_sum3", referenced from: _main`.

[`examples/greet.s`](examples/greet.s) is called from C and calls `printf`.
It reserves the two variadic slots once, after saving its registers, and
reuses them on every trip round the loop:

```asm
_greet:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    sub     sp, sp, #16             // printf's 2 variadic slots, reused each call
    ...
greet_loop:
    cmp     w21, w20                // while (i <= times)
    b.gt    greet_done
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    str     x21, [sp]               // slot 0 = i (mov w21 zeroed the top half)
    str     x19, [sp, #8]           // slot 1 = name
    bl      _printf
    ...
greet_done:
    add     sp, sp, #16
    ldr     x21, [sp, #32]
```

Note the order at the end: first `add sp, sp, #16` to drop the slots, *then*
the loads at `[sp, #32]` and `[sp, #16]` find the saved registers where the
prologue put them.

```console
$ ./greet
1: Hello, world!
1: Hello, Ada!
2: Hello, Ada!
```

## Reading clang's output

On the Mac the compiler is clang (`gcc` is also clang, under another name):

```console
$ clang -S -O0 -o - square.c
```

You will see the same structure as gcc's output in the main lesson, with a few
differences in spelling:

- Every function name has its `_`: `_square`, `bl _square`.
- Comments start with `;` in clang's Apple output. In your own files keep
  using `//`, which works on both platforms.
- Local labels look like `LBB0_2` and strings like `l_.str` (an `L` or `l`
  prefix keeps them out of the symbol table, like `.L` on Linux).
- `.cfi_...` lines are information for debuggers. Ignore them. `Lloh0:` labels
  and `.loh` lines are hints for the linker; ignore those too.
- `.subsections_via_symbols` at the end tells the linker it may drop unused
  functions. Not needed in your files.
- `stur`/`ldur` are `str`/`ldr` with a small, possibly negative, offset.

With `-O2`:

```console
$ clang -S -O2 -o - square.c
...
_sum_of_squares:
	mul	w8, w0, w0
	madd	w0, w1, w1, w8
	ret
```

On [godbolt.org](https://godbolt.org), choose an "armv8-a clang" compiler and
add `-target arm64-apple-macos` to the options to get Apple-flavoured output.

## Common mistakes on macOS

- **Variadic arguments in registers.** No warning, wrong output (see
  `printf_wrong.s`). Put them on the stack, 8 bytes each, from `[sp]` up.
- **Forgetting to make room for them.** Storing to `[sp]` without first doing
  `sub sp, sp, #16` overwrites your own saved `x29`/`x30`, and the program
  crashes when it returns.
- **Odd-sized argument areas.** `sub sp, sp, #24` for three slots misaligns
  `sp`. Round up to 32.
- **Missing underscore.** `bl puts` fails with
  `Undefined symbols for architecture arm64: "puts"`. A C-visible function
  named `sum3` without the `_` gives `"_sum3", referenced from: _main`.
- **Labels with register names.** clang's assembler reads `s1@PAGEOFF` as the
  register `s1` and fails with `unexpected token in argument list`. Avoid
  labels such as `s1`, `d0`, `b2`, `h3`, `q4`, `w5` or `x6`.

## The exercises

Do the exercises in [the main lesson](../../lessons/16-calling-c/exercises.md)
as macOS programs. macOS solutions are in [`solutions/`](solutions/); the
written answers in the main lesson's
[`solutions/README.md`](../../lessons/16-calling-c/solutions/README.md) apply
to both. Note that 16.3, 16.5, 16.8 and 16.9 call `printf`, so their macOS
versions put the numbers on the stack. In 16.9 the `int` from the array is
loaded with `ldrsw` so that a negative value fills its whole 8-byte slot
correctly.

On macOS, exercise 16.10's `clang -O2` output looks very different from gcc's:
clang turns the recursion into a loop and then unrolls it, doing four
multiplications per trip. It computes the same result.
