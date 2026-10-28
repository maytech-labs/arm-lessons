# Lesson 16: Calling C

## Goals

After this lesson you can:

- write a program that starts at `main` instead of `_start`, and explain what
  runs before `main` and after it returns
- call C library functions (`puts`, `printf`, `strlen`, `putchar`, `exit`)
  from assembly
- keep the stack aligned and your values safe across those calls
- write an assembly function that C code calls, and build the two together
- read the assembly that `gcc -S` and `clang -S` produce for a C function

## Before you start

You need lessons 13 to 15: the stack and its 16-byte alignment, `bl`/`ret`
and frame records, and the AAPCS64 calling convention (arguments in `x0`-`x7`,
result in `x0`, `x19`-`x28` callee-saved). Everything in this lesson is just
the calling convention applied to functions somebody else wrote.

## Goodbye `_start`

Up to now every program was *freestanding*: it began at `_start`, talked to
the kernel with `svc #0`, and was linked with `-nostdlib -static`. Nothing ran
that you had not typed.

Real C programs are not like that. They start at `main`, and they call the C
library (libc) for everything: printing, reading files, memory, strings. From
this lesson on, every program in the course does the same (see
[decision 0005](../../docs/decisions/0005-raw-syscalls-before-libc.md)).

Here is the smallest libc program. In C:

```c
int main(void) {
    return 42;
}
```

In assembly, [`linux/examples/ret42.s`](linux/examples/ret42.s):

```asm
    .text
    .global main            // the C runtime looks for a global symbol "main"
    .p2align 2
main:
    mov     w0, #42         // int main(void) returns an int, in w0
    ret                     // return to the C runtime, which calls exit(42)
```

Notice what is missing: no `svc`, no `_start`, no exit system call. `main` is
an ordinary function. It puts its result in `w0` and returns with `ret`.

Why `w0` and not `x0`? `main` returns an `int`, and an `int` is 32 bits, so it
lives in the 32-bit half of the register. Lesson 18 is all about this; for
now remember: `int` uses a `w` register, `long` and pointers use an `x`
register.

Predict: what will `echo $?` print?

```console
$ make ret42
cc -g  -o ret42 ret42.s
$ ./ret42; echo $?
42
```

The shared Makefile noticed that the file has no `_start:` and so linked it
the normal way, with the C library, exactly as `gcc -o ret42 ret42.s` would.

## What runs before `main`

If our program has no `_start`, where does it begin? Ask `nm`, which lists the
symbols in a binary:

```console
$ nm ret42 | grep -E ' (_start|main|__libc_start_main)'
                 U __libc_start_main@GLIBC_2.34
0000000000000600 T _start
0000000000000714 T main
```

(Your addresses may differ.) There *is* a `_start`, and we did not write it.
gcc quietly linked a few extra object files into the program: the *C runtime
startup code*, files with names like `Scrt1.o`, `crti.o` and `crtn.o`. This is
what happens when you run `./ret42`:

1. The kernel loads the program and jumps to `_start`, just like before.
2. `_start` (from `Scrt1.o`) picks `argc`, `argv` and the environment off the
   stack and calls `__libc_start_main` in libc, passing it the address of
   `main`. The `U` in the `nm` output means "undefined here, found in a shared
   library at run time".
3. `__libc_start_main` sets up the library: the `stdin`/`stdout`/`stderr`
   buffers, thread-local storage, constructors.
4. It calls `main(argc, argv, envp)`. (We ignore the arguments until lesson 25.)
5. When `main` returns, it calls `exit(value_main_returned)`.
6. `exit` runs the `atexit` handlers, flushes every `stdout`/`FILE` buffer, and
   finally makes the exit system call you already know.

So `return 42;` from `main` and `exit(42);` do the same thing. The only
difference is that `exit` can be called from anywhere, even deep inside
nested functions, and never returns.

## Your first libc call: `puts`

In C:

```c
#include <stdio.h>

int main(void) {
    puts("Hello from libc!");
    return 0;
}
```

`puts(s)` writes the string `s` and then a newline. It takes one argument, a
pointer, so the pointer goes in `x0`. [`linux/examples/hello.s`](linux/examples/hello.s):

```asm
    .section .rodata
msg:
    .asciz  "Hello from libc!"  // puts adds the newline itself

    .text
    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!   // bl below overwrites x30: save it (and fp)
    mov     x29, sp

    adrp    x0, msg                 // x0 = first argument = address of msg
    add     x0, x0, :lo12:msg
    bl      puts                    // puts(msg)

    mov     w0, #0                  // return 0
    ldp     x29, x30, [sp], #16
    ret
```

Three things to see:

- **`bl puts`** is an ordinary call. We never defined `puts`; the linker finds
  it in libc. (The string lives in `.section .rodata`, the read-only data
  section. Lesson 20 covers sections properly.)
- **The prologue is not optional.** `main` is a function that calls another
  function. `bl` overwrites `x30`, so without the `stp`, our final `ret` would
  jump back into `main` itself, forever or until it crashed. This is exactly
  lesson 14's rule.
- **`sp` stays 16-byte aligned.** The C runtime calls `main` with an aligned
  `sp`. We subtract 16, so it is still aligned when we call `puts`. libc
  functions assume this, and some of them will crash with `Bus error` if you
  break it.

```console
$ make hello
$ ./hello
Hello from libc!
```

## `printf` with arguments

`printf` takes a format string and then any number of extra arguments. In C:

```c
printf("%d + %d = %d\n", 2, 3, 5);
printf("%s is %ld years old\n", "Ada", 36L);
```

On Linux, `printf` is called exactly like any other function: the format string
is the first argument (`x0`), the next ones go in `x1`, `x2`, `x3`, and so on.
Use a `w` register for an `int` (`%d`) and an `x` register for a `long`
(`%ld`) or a pointer (`%s`, `%p`).
[`linux/examples/printf_args.s`](linux/examples/printf_args.s):

```asm
    adrp    x0, fmt_sum             // 1st argument: the format string
    add     x0, x0, :lo12:fmt_sum
    mov     w1, #2                  // 2nd argument: an int, so a w register
    mov     w2, #3                  // 3rd
    mov     w3, #5                  // 4th
    bl      printf

    adrp    x0, fmt_age
    add     x0, x0, :lo12:fmt_age
    adrp    x1, name                // %s wants a pointer
    add     x1, x1, :lo12:name
    mov     x2, #36                 // %ld wants a long, so an x register
    bl      printf
```

```console
$ make printf_args
$ ./printf_args
2 + 3 = 5
Ada is 36 years old
```

Note that we reload `x0` before the second call. After any `bl`, assume that
`x0`-`x17` hold garbage: they are caller-saved, and `printf` is free to use them.

> **macOS is different here.** On Apple Silicon, `printf`'s extra arguments go
> on the stack, not in `x1`-`x7`. The companion lesson shows how. This is the
> single most common reason assembly that works on Linux prints nonsense on a Mac.

## Keeping values across calls

Here is a longer program that uses four libc functions. In C:

```c
int main(void) {
    const char *s = "assembly";
    long n = strlen(s);
    printf("\"%s\" has %ld characters\n", s, n);
    for (int i = 0; i < n; i++) {   // print it backwards
        putchar(s[n - 1 - i]);
    }
    putchar('\n');
    exit(3);
}
```

Before reading the assembly, think: `s` and `n` are needed after the calls to
`strlen`, `printf` and `putchar`. Which registers can hold them?

Not `x0`-`x17`: every call may destroy those. They must go in callee-saved
registers, `x19`-`x28`, which every function (including libc's) promises to
give back unchanged. And because *our* `main` is also a function, we must save
the old values of `x19` and `x20` before using them, and restore them at the end.
[`linux/examples/libc_tour.s`](linux/examples/libc_tour.s):

```asm
main:
    stp     x29, x30, [sp, #-32]!   // frame record + room for x19, x20
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // callee-saved: they survive our calls

    adrp    x19, word               // x19 = s (kept across calls)
    add     x19, x19, :lo12:word

    mov     x0, x19
    bl      strlen                  // x0 = strlen(s)
    mov     x20, x0                 // x20 = n (kept across calls)

    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     x1, x19
    mov     x2, x20
    bl      printf

loop:                               // while (n > 0) putchar(s[--n]);
    cbz     x20, done
    sub     x20, x20, #1
    ldrb    w0, [x19, x20]          // the character, as an int argument
    bl      putchar
    b       loop
done:
    mov     w0, #'\n'
    bl      putchar

    mov     w0, #3
    bl      exit                    // exit flushes stdout, then ends the process
```

`strlen` returns a `size_t` (an unsigned 64-bit count) in `x0`. `putchar`
takes an `int`, so the character goes in `w0`. `#'\n'` is the assembler's way
of writing the character constant 10.

Why is there no epilogue? `exit` never returns, so nothing after `bl exit`
would ever run. (We would still restore `x19`/`x20` if we returned from `main`
with `ret`. Try changing `bl exit` into a normal return as practice.)

Predict the output and exit status, then check:

```console
$ make libc_tour
$ ./libc_tour; echo $?
"assembly" has 8 characters
ylbmessa
3
```

## Calling assembly from C

Now turn it around: write a function in assembly and call it from C. This is
how assembly is used in real projects: a few hot or special functions, called
from a C program.

The function, in C, would be:

```c
long sum3(long a, long b, long c) {
    return a + b + c;
}
```

In assembly, [`linux/examples/sum3.s`](linux/examples/sum3.s):

```asm
    .text
    .global sum3            // without .global, the C file could not find it
    .p2align 2
sum3:                       // a leaf function: no calls, so no frame needed
    add     x0, x0, x1      // a + b
    add     x0, x0, x2      // + c, returned in x0
    ret
```

And the C program that calls it, [`linux/examples/sum3_main.c`](linux/examples/sum3_main.c):

```c
#include <stdio.h>

long sum3(long a, long b, long c);   // the prototype: tells C how to call it

int main(void) {
    printf("sum3(1, 2, 3) = %ld\n", sum3(1, 2, 3));
    printf("sum3(100, -50, 7) = %ld\n", sum3(100, -50, 7));
    return 0;
}
```

### The prototype is the contract

The C compiler never sees `sum3.s`. All it knows about `sum3` is the
*prototype* line. From that line it decides that `a`, `b`, `c` go in `x0`,
`x1`, `x2` and that the result comes back in `x0`, as a `long`. Your assembly
must match it exactly. If the prototype said `int sum3(int, int, int)`, the
compiler would pass 32-bit values in `w0`-`w2` and only look at `w0` for the
result.

If you leave the prototype out, gcc warns
`implicit declaration of function 'sum3'` and *guesses* that it returns an
`int`, which silently throws away the top half of `x0`. Always write the
prototype. (Newer compilers make this an error.)

Your assembly function must also keep the rest of the contract: preserve
`x19`-`x28`, `x29`, `sp`, and return to `x30`. The C code calling you relies
on it, exactly as you rely on `printf` doing the same.

### Building a program from two files

`gcc` happily takes a mix of `.c` and `.s` files. It compiles the C file to
assembly, assembles both, and links them together with libc:

```console
$ gcc -g -o sum3 sum3_main.c sum3.s
$ ./sum3
sum3(1, 2, 3) = 6
sum3(100, -50, 7) = 57
```

The shared Makefile turns *each* `.s` file into its own program, which would
fail here: `sum3.s` has no `main`. So [`linux/examples/Makefile`](linux/examples/Makefile)
adds its own rules below the `include` line:

```make
include ../../../../mk/linux.mk

sum3: sum3_main.c sum3.s
	$(CC) $(ASFLAGS) -o $@ sum3_main.c sum3.s
```

Read it as: "the file `sum3` is made from `sum3_main.c` and `sum3.s`; to make
it, run this command". `$@` means the target, `sum3`. The command line must
start with a **tab** character, not spaces. When make has its own rule for a
target, it uses it instead of the shared one. Lesson 20 covers Makefiles in
more depth.

### Assembly in the middle

An assembly function called from C can call C functions itself. In C:

```c
void greet(const char *name, int times) {
    for (int i = 1; i <= times; i++)
        printf("%d: Hello, %s!\n", i, name);
}
```

[`linux/examples/greet.s`](linux/examples/greet.s) needs three values that survive the
`printf` calls (`name`, `times`, `i`), so it saves three callee-saved
registers. `x21` needs its own 8-byte slot; the frame is 48 bytes so that it
stays a multiple of 16:

```asm
greet:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // we use three callee-saved registers,
    str     x21, [sp, #32]          // so we must save and restore them

    mov     x19, x0                 // x19 = name
    mov     w20, w1                 // w20 = times
    mov     w21, #1                 // w21 = i
greet_loop:
    cmp     w21, w20                // while (i <= times)
    b.gt    greet_done
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    mov     w1, w21
    mov     x2, x19
    bl      printf
    add     w21, w21, #1
    b       greet_loop
greet_done:
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
```

[`linux/examples/greet_main.c`](linux/examples/greet_main.c) declares
`void greet(const char *name, int times);` and calls it twice.

```console
$ make greet
$ ./greet
1: Hello, world!
1: Hello, Ada!
2: Hello, Ada!
```

## Reading compiler output

You now know enough to read what a C compiler produces. This is the best
teacher you have for the rest of the course: whenever you wonder how to write
something in assembly, write it in C and ask the compiler (see
[decision 0007](../../docs/decisions/0007-c-as-reference-language.md)).

[`linux/examples/square.c`](linux/examples/square.c):

```c
int square(int x) {
    return x * x;
}

int sum_of_squares(int a, int b) {
    return square(a) + square(b);
}
```

`gcc -S` stops after compiling and writes assembly instead of a program.
`-O0` means "no optimisation", `-o -` means "print to the terminal" (without
it gcc would write `square.s` into the directory, and our Makefile would then
try to build it as a program). `-fno-asynchronous-unwind-tables` removes a lot
of `.cfi_` lines that are only there for debuggers and exceptions:

```console
$ gcc -S -O0 -fno-asynchronous-unwind-tables -o - square.c
	.arch armv8-a
	.file	"square.c"
	.text
	.align	2
	.global	square
	.type	square, %function
square:
	sub	sp, sp, #16
	str	w0, [sp, 12]
	ldr	w0, [sp, 12]
	mul	w0, w0, w0
	add	sp, sp, 16
	ret
	.size	square, .-square
	.align	2
	.global	sum_of_squares
	.type	sum_of_squares, %function
sum_of_squares:
	stp	x29, x30, [sp, -48]!
	mov	x29, sp
	str	x19, [sp, 16]
	str	w0, [sp, 44]
	str	w1, [sp, 40]
	ldr	w0, [sp, 44]
	bl	square
	mov	w19, w0
	ldr	w0, [sp, 40]
	bl	square
	add	w0, w19, w0
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 48
	ret
	.size	sum_of_squares, .-sum_of_squares
	.ident	"GCC: (Debian 12.2.0-14+deb12u1) 12.2.0"
	.section	.note.GNU-stack,"",@progbits
```

Almost all of it is familiar. Line by line, for `sum_of_squares`:

- `stp x29, x30, [sp, -48]!` / `mov x29, sp`: the prologue from lesson 14. gcc
  writes immediates without `#`; both forms are accepted.
- `str x19, [sp, 16]`: it is going to keep a value across a call in `x19`, so
  it saves `x19` first. Exactly what you did in `libc_tour.s`.
- `str w0, [sp, 44]` / `str w1, [sp, 40]`: at `-O0` gcc gives every variable,
  including the parameters, a home on the stack, and loads it each time it is
  used. Slow, but easy to follow.
- `bl square`, `mov w19, w0`: the first result is kept safe in `x19`.
- `add w0, w19, w0`: `square(a) + square(b)`, as an `int`, in `w0`.
- The epilogue restores `x19`, `x29`, `x30` and returns.

The directives you have not seen are bookkeeping: `.align 2` is gcc's spelling
of `.p2align 2`; `.type` and `.size` record that `square` is a function and how
long it is (ELF only, harmless); `.ident` and `.note.GNU-stack` are notes for
the linker.

Now turn on optimisation:

```console
$ gcc -S -O2 -fno-asynchronous-unwind-tables -o - square.c
...
square:
	mul	w0, w0, w0
	ret
...
sum_of_squares:
	mul	w1, w1, w1
	madd	w0, w0, w0, w1
	ret
```

At `-O2` the stack traffic is gone and the compiler has *inlined* `square`:
`sum_of_squares` no longer calls it at all. `madd w0, w0, w0, w1` is
`w0 = w1 + w0 * w0`. Optimised output is shorter but harder to map back to the
C, so start with `-O0`. Lesson 27 is about reading `-O2`.

### Other ways to see compiler output

- **clang** does the same with the same flags. The container does not include
  clang, but the one on your Mac can produce *Linux* AArch64 assembly:
  `clang -S -O0 -target aarch64-linux-gnu -fno-asynchronous-unwind-tables -o - square.c`.
  Its `-O0` code differs in small ways (it uses `w8`, `w9` as scratch and the
  instructions `stur`/`ldur`, which are `str`/`ldr` with a small negative
  offset), but the ideas are the same.
- **`objdump -d prog`** disassembles a finished program, including the code
  gcc compiled from your `.c` file.
- **Compiler Explorer** at <https://godbolt.org> shows C and assembly side by
  side, colour-matched line by line. Pick the language "C", a compiler such as
  "ARM64 gcc" (any recent version), and type `-O0` in the options box. Hover
  over a line of C to see which instructions it became.

## C to assembly

| C | Assembly (Linux) |
|---|------------------|
| `int main(void) { return 42; }` | `.global main` / `main: mov w0, #42` / `ret` |
| `return n;` from `main` | `mov w0, n` then epilogue and `ret`; the runtime calls `exit(n)` |
| `exit(n);` | `mov w0, n` / `bl exit` (never returns) |
| `puts(s);` | `adrp x0, s` / `add x0, x0, :lo12:s` / `bl puts` |
| `printf(fmt, a, b);` | `x0` = fmt, `x1`/`w1` = a, `x2`/`w2` = b, `bl printf` |
| `n = strlen(s);` | `x0` = s, `bl strlen`, result in `x0` |
| `putchar(c);` | `w0` = c, `bl putchar` |
| a variable used after a call | keep it in `x19`-`x28` (save them in the prologue) |
| `long f(long a);` in C, defined in a `.s` file | `.global f` / `f:` ... `ret`, args in `x0`-`x7` |
| `gcc main.c f.s` | compile, assemble and link both files together |

## Common mistakes

- **Defining `_start` in a libc program.** If your file has a `_start:` label,
  the shared Makefile links it freestanding, and `bl printf` fails with
  `undefined reference to 'printf'`. If you link it with libc yourself, you get
  `multiple definition of '_start'`. Libc programs define `main` only.
- **Forgetting `.global main`.** The linker reports
  `undefined reference to 'main'` (from the startup code, which looks for it).
- **No prologue in a function that calls something.** `bl` overwrites `x30`,
  your `ret` returns to the wrong place, and the program loops or crashes with
  `Segmentation fault`.
- **Keeping a value in `x0`-`x17` across a call.** It works sometimes, then a
  different input or libc version changes it. Use `x19`-`x28`, and save them.
- **Using a callee-saved register without saving it.** Your function works,
  but its *caller* (maybe the C runtime, maybe `main.c`) finds its own value
  changed. This bug shows up far away from its cause.
- **Misaligned `sp` at a call.** For example `sub sp, sp, #8`. Calls into libc
  may crash with `Bus error`, or work until one day they do not.
- **`w` vs `x` mismatch with `printf`.** `%d` reads 32 bits, `%ld` reads 64.
  Passing a `long` to `%d` prints only the low half.
- **Raw `exit` system call after `printf`.** `printf` collects output in a
  buffer that `exit()` flushes. If you leave with `svc #0` instead, buffered
  output can be lost (try `./prog | cat`). Return from `main` or call `exit`.
- **Missing prototype in the C file.** The compiler guesses `int` and drops the
  top 32 bits of your result.
- **Running `gcc -S square.c` in `examples/`.** It writes `square.s`, and the
  next `make` tries to build it as a program without `main`. Use `-o -` or work
  in `work/`.

## Recap

- From now on programs define `main` and are linked with libc by plain `gcc`.
- The startup code (`_start` in `Scrt1.o`) sets up libc, calls `main`, and calls
  `exit` with its return value. `exit` flushes output buffers.
- A libc function is called with `bl`, following the calling convention you
  already know: arguments in `x0`-`x7`, result in `x0`.
- Any function that calls another needs a prologue that saves `x29`/`x30`, and
  must keep `sp` 16-byte aligned.
- Values that must survive a call live in `x19`-`x28`, saved and restored by you.
- To call assembly from C: `.global` the symbol, declare a matching prototype
  in C, follow the convention, and link both files with `gcc a.c b.s`.
- `gcc -S -O0 -o - file.c` shows you how the compiler translates any C code.
  Use it constantly.

## Homework

[exercises.md](exercises.md)
