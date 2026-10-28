# Lesson 15 on macOS: The calling convention

Read [the main lesson](../../lessons/15-calling-convention/README.md) first.
Apple's arm64 ABI is AAPCS64 with a short list of changes, documented in
Apple's *Writing ARM64 code for Apple platforms*. Everything in the main
lesson holds on macOS (argument and result registers, caller- and
callee-saved registers, frame records, recursion, tail calls), except the
points below. The examples differ only in the usual boilerplate, and every
program prints exactly what it prints on Linux.

```console
$ cd apple-silicon/15-calling-convention/examples && make
$ ./hanoi | head -3
A->C
A->B
C->B
$ ./many_args; echo $?
55
```

## What Apple changes

**`x18` is reserved.** On Linux it is merely "platform-defined" and in practice
free. On macOS the kernel may change it at any time, for example during a
context switch. Code that stores something in `x18` can see it vanish. This is
why the course never uses it, on either platform.

**The frame pointer is mandatory.** AAPCS64 allows code without frame records.
Apple requires `x29` to always point at a valid frame record, so that
profilers and crash reporters can walk the stack. The prologue/epilogue you
learned in lesson 14 does exactly this; just never use `x29` as a general
register.

**Stack arguments are packed.** On Linux, every argument beyond the eighth
takes a full 8-byte slot. On macOS, each takes only its own size, aligned to
its own size: an `int` takes 4 bytes, a `char` 1 byte. For `long` and pointer
arguments, as in `many_args.s`, the layout is the same as on Linux. For
example, with `void f(long a1, ..., long a8, int i, int j)`:

| | Linux | macOS |
|-|-------|-------|
| `i` | `[sp]` (8-byte slot) | `[sp]` (4 bytes) |
| `j` | `[sp, #8]` | `[sp, #4]` |

**Narrow arguments are extended by the caller.** When a `char`, `short`, or
`bool` is passed in a register, Apple requires the caller to sign- or
zero-extend it to 32 bits, so the callee can trust the whole `w` register.
Linux makes no such promise: the callee must extend the value itself.
(Lesson 18 covers extension.)

**Variadic functions are different.** Arguments after the `...` in a function
like `printf` go on the stack on macOS, not in registers. This matters as soon
as you call `printf`, in lesson 16.

**The red zone.** macOS guarantees that 128 bytes below `sp` are not changed
by signal handlers or the system, so a leaf function may use them without
moving `sp`. Linux has no red zone. The course does not use it.

## Conditional breakpoints in lldb

```console
$ lldb ./factorial
(lldb) breakpoint set -n fact -c '$x0 == 1'
(lldb) run
(lldb) bt 3
  * frame #0: 0x00000001000002f8 factorial`fact
    frame #1: 0x0000000100000320 factorial`fact_recurse + 24
    frame #2: 0x0000000100000320 factorial`fact_recurse + 24
```

`-n` names the function and `-c` gives the condition. (The short `b` command
does not accept `-c`.) The backtrace shows one `fact` frame per level, as
on Linux.

## Exercises

Do the [main lesson's exercises](../../lessons/15-calling-convention/exercises.md)
as macOS programs. The answers are the same. In 15.1, add: `x18` is reserved by
macOS and must never be used. For exercise 15.8, the plain recursive version
also crashes on macOS with `Segmentation fault` (exit status 139); the main
thread's stack is 8 MiB there too. macOS solutions are in
[solutions/](solutions/).
