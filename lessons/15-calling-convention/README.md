# Lesson 15: The calling convention

## Goals

After this lesson you can:

- State the AAPCS64 rules: which registers carry arguments and results,
  which a function may change, and which it must preserve.
- Use callee-saved registers (`x19`-`x28`) for values that live across calls,
  and save and restore them correctly.
- Pass more than eight arguments, using the stack.
- Write recursive functions: factorial, Fibonacci, Towers of Hanoi.
- Explain stack depth, and why deep recursion overflows the stack.
- Turn a tail call into a plain branch.

## Before you start

You need lesson 14: `bl`, `ret`, frame records, prologues and epilogues. In
lesson 14 we followed a loose rule ("functions may change `x0`-`x18`; keep
long-lived values in `x19`+"). This lesson makes that precise.

```console
# cd lessons/15-calling-convention/examples && make
```

## Why a convention?

When you call a function you did not write (a C library function, or code a
compiler produced), you cannot read it to see which registers it changes. And
it cannot know which of your registers you still need. Both sides need an
agreement in advance. On AArch64 that agreement is the **Procedure Call
Standard for the Arm 64-bit Architecture**, **AAPCS64**. Every compiler,
library, and operating system on ARM64 follows it (Apple with small changes,
see the companion lesson). If your assembly follows it too, your functions can
call C and be called from C (lesson 16).

## The register rules

| Registers | Role | Who saves them? |
|-----------|------|-----------------|
| `x0`-`x7` | arguments 1-8; `x0` (and `x1`) the result | **caller** (the callee may change them) |
| `x8` | address for a large returned struct (lesson 19) | caller |
| `x9`-`x15` | temporaries | caller |
| `x16`, `x17` | temporaries the linker may use between a call and its target | caller |
| `x18` | platform register | **never use** ([decision 0009](../../docs/decisions/0009-never-use-x18.md)) |
| `x19`-`x28` | long-lived values | **callee** (must restore before returning) |
| `x29` | frame pointer | callee |
| `x30` | link register | callee (it must come back to the right place) |
| `sp` | stack pointer | callee (it must be the same on return) |

Two words to learn:

- **Caller-saved** (also "volatile", "scratch"): `x0`-`x17`. A function may
  change them freely. If *you* (the caller) need a value in one of them after
  a call, it is your job to put it somewhere safe first.
- **Callee-saved** (also "non-volatile", "preserved"): `x19`-`x28`, `x29`,
  `x30`, `sp`. A function may use them, but **it must put the old value back
  before it returns**. So a caller can count on them surviving any call.

From the caller's point of view: after `bl f`, assume `x0`-`x17` hold garbage
(except `x0`/`x1`, the result) and `x19`-`x28` hold exactly what they held
before.

### Why `x16` and `x17` are special

The linker sometimes inserts a tiny piece of code between your `bl` and the
real function (a *veneer*, when the target is too far away for `bl`, or a stub
for a shared library in lesson 16). That code is allowed to use `x16` and
`x17`. So even the *arguments* must not be in `x16`/`x17`: they may be changed
before the function even starts. Treat them as "may change at any `bl`".

### Why never `x18`

AAPCS64 lets each operating system decide what `x18` is for. Linux leaves it
as a temporary; Apple reserves it and may change it at any moment; Windows
uses it for thread data. Code that uses it is not portable, so this course
never does.

## Using callee-saved registers

A function that keeps values in `x19`-`x28` must save the caller's values in
its prologue and restore them in its epilogue. `examples/callee_saved.s`:

```asm
// Frame (48 bytes): [sp] x29, [sp,#8] x30, [sp,#16] x19, [sp,#24] x20,
//                   [sp,#32] x21, [sp,#40] unused (keeps the size a multiple of 16)
sum_of_squares:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]     // save the CALLER's x19 and x20
    str x21, [sp, #32]          // and x21 (the running total)

    mov x19, x0                 // p
    mov x20, x1                 // n
    mov x21, #0                 // total
sum_of_squares_loop:
    cbz x20, sum_of_squares_done
    ldr x0, [x19], #8           // x0 = *p++
    bl square                   // square may change x0-x18, not x19-x21
    add x21, x21, x0
    ...
sum_of_squares_done:
    mov x0, x21

    ldr x21, [sp, #32]          // restore in reverse
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
```

Meanwhile `_start` keeps *its* loop counter in `x19` and calls
`sum_of_squares` three times. Because `sum_of_squares` restores `x19`, the
counter survives. Everyone uses `x19`, and nobody steps on anyone, because
everyone puts it back.

### What happens when a function does not

`examples/clobber_bug.s` has a helper that uses `x19` as a scratch register
without saving it:

```asm
bad_helper:
    mov x19, #1                 // "just a temporary"... but it belongs to the caller
    add x0, x19, #1
    ret
```

`_start`'s loop was supposed to run 3 times; it runs once (exit status 1).
In a real program the symptom shows up far from the cause: a loop in some
caller misbehaves, and the function that broke it looks perfectly fine. When a
caller's `x19`-`x28` changes "by itself" across a call, suspect the callee.

### Choosing registers: a rule of thumb

- A value that is **not** needed after the next call: use `x9`-`x15`. No
  saving required.
- A value that **is** needed after a call: put it in `x19`-`x28` (save and
  restore that register once, in the prologue and epilogue) or in a frame
  slot (store before the call, load after). Registers are faster and easier
  when you have several values and several calls.

## Recursion

A recursive function is just a non-leaf function that happens to call
itself. Because every call gets its own frame on the stack, every call has its
own copy of its saved registers and locals. That is what makes recursion work.

`examples/factorial.s`:

```c
unsigned long fact(unsigned long n) {
    if (n <= 1) return 1;
    return n * fact(n - 1);
}
```

```asm
fact:
    cmp x0, #1
    b.hi fact_recurse           // n > 1: recursive case
    mov x0, #1                  // base case: no frame needed, we call nothing
    ret
fact_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]          // save the caller's x19 (maybe an outer fact's n)
    mov x19, x0                 // x19 = n
    sub x0, x0, #1
    bl fact                     // x0 = fact(n - 1)
    mul x0, x19, x0             // n * fact(n - 1)
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
```

`n` is needed after the recursive call, so it lives in `x19`. Each level saves
the *previous* level's `x19` (its `n`) before overwriting it, and restores it
on the way out. The base case returns without building a frame at all, since it
calls nothing.

Watch the frames pile up:

```console
# gdb -q ./factorial
(gdb) break fact if $x0 == 1
(gdb) run
(gdb) bt 4
#0  fact () at factorial.s:34
#1  0x000000000040011c in fact_recurse () at factorial.s:44
#2  0x000000000040011c in fact_recurse () at factorial.s:44
#3  0x000000000040011c in fact_recurse () at factorial.s:44
(More stack frames follow...)
```

`break fact if $x0 == 1` is a **conditional breakpoint**: it stops only at
the deepest call. `bt 4` shows the innermost four frames; plain `bt` shows all
20. Every saved return address is the same, the instruction after `bl fact`:
each level returns into the level above it.

`examples/fib.s` makes two recursive calls per call. After the first call it
needs both `n` (for the second call) and the first result (for the sum), so it
uses two callee-saved registers:

```asm
fib_recurse:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // x19 = n
    sub x0, x19, #1
    bl fib
    mov x20, x0                 // x20 = fib(n - 1)
    sub x0, x19, #2
    bl fib                      // x0 = fib(n - 2)
    add x0, x20, x0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
```

`examples/hanoi.s` keeps four values (`n`, `from`, `to`, `via`) in `x19`-`x22`
across two recursive calls and the printing in between. Read it with the C in
its header.

## Stack depth

Each active call holds a frame on the stack until it returns. `fact(20)` is 20
frames deep at its deepest; that is nothing. But a recursion one million levels
deep, with 32-byte frames, needs 32 MB of stack, and the stack is 8 MiB: it
overflows and crashes with `Segmentation fault` (lesson 13). Exercise 15.8
shows this, and the fix.

## Tail calls

If the very last thing a function does is call another function and return
its result, the caller's frame has no more work to do. So instead of `bl`
(which needs `x30` saved) followed by `ret`, the function can simply **jump**
with `b`. The called function's `ret` will then return straight to the
original caller. `examples/tail_call.s`:

```c
unsigned long gcd(unsigned long a, unsigned long b) {
    if (b == 0) return a;
    return gcd(b, a % b);           // the call is the last thing
}
```

```asm
gcd:
    cbz x1, gcd_done
    udiv x2, x0, x1
    msub x2, x2, x1, x0         // x2 = a % b
    mov x0, x1                  // new a = b
    mov x1, x2                  // new b = a % b
    b gcd                       // tail call: jump, do not link
gcd_done:
    ret                         // x0 = a
```

No frame, no stack growth: the "recursion" is really a loop. Compilers do this
at `-O2` ("tail call optimisation"). `fact` above is **not** a tail call,
because after `fact(n - 1)` returns, it still has to multiply by `n`.

## More than eight arguments

Arguments 1-8 go in `x0`-`x7`. The rest go **on the stack**, in order, each in
its own 8-byte slot, starting at the address in `sp` at the moment of the
call. The caller makes room for them (keeping `sp` 16-byte aligned) and
removes them afterwards. `examples/many_args.s`:

```asm
    mov x0, #1                  // arguments 1-8 in x0-x7
    ...
    mov x7, #8
    mov x9, #9                  // arguments 9 and 10 go on the stack:
    mov x10, #10                //   the 9th at [sp], the 10th at [sp, #8]
    stp x9, x10, [sp, #-16]!    // (16 bytes: sp stays aligned)
    bl sum10
    add sp, sp, #16             // the CALLER removes its stack arguments
```

Inside `sum10`, the 9th argument is at `[sp]` and the 10th at `[sp, #8]`, as
long as `sum10` has not moved `sp`. A function with a prologue finds them above
its own frame: at `[x29, #N]`, where N is its frame size.

## The whole convention on one page

When **calling** a function:

1. Put arguments in `x0`-`x7` (and the stack, beyond eight).
2. Anything you need afterwards that is in `x0`-`x17`: save it first.
3. Keep `sp` 16-byte aligned.
4. `bl`. The result is in `x0`. `x19`-`x28`, `x29`, `sp` are unchanged.

When **writing** a function:

1. If you call anything, save `x29`/`x30` (the frame record).
2. For every `x19`-`x28` you use, save the old value and restore it.
3. Use `x9`-`x15` freely for temporaries.
4. Never touch `x18`.
5. Put the result in `x0`, restore everything, and make `sp` what it was.

## C to assembly

| C | Assembly |
|---|----------|
| `f(a, ..., h)` (up to 8 args) | `x0`-`x7`, `bl f` |
| `f(a, ..., h, i, j)` | 9th, 10th at `[sp]`, `[sp, #8]` before `bl` |
| a local used across calls | `x19`-`x28` (saved in prologue) or a frame slot |
| a temporary between calls | `x9`-`x15` |
| `return f(x);` (tail call) | set up args, `b f` (no frame needed for it) |
| recursion | an ordinary non-leaf function that calls itself |

## Common mistakes

- **Using `x19`-`x28` without saving them.** The bug appears in your caller,
  not in your function.
- **Restoring in the wrong slots** (saving `x19` at `#16` and restoring from
  `#24`). Write the frame layout down first.
- **Relying on `x0`-`x17` after a call.** Even if it "works", the next version
  of the callee can break it.
- **Passing arguments in `x16`/`x17`.**
- **Forgetting the base case**, or a base case that is never reached:
  infinite recursion, then a stack overflow.
- **Turning a non-tail call into `b`.** If there is any work after the call
  (like `fact`'s multiply), `b` skips it.
- **Stack arguments without alignment.** One extra argument still needs 16
  bytes of stack.

## Recap

- AAPCS64: arguments `x0`-`x7`, result `x0`; beyond eight, on the stack.
- Caller-saved: `x0`-`x17`. Callee-saved: `x19`-`x28`, `x29`, `x30`, `sp`.
- `x16`/`x17` may change at any `bl`; `x18` is never used.
- Using a callee-saved register means saving it in the prologue and
  restoring it in the epilogue.
- Recursion works because each call has its own frame.
- Deep recursion can overflow the stack.
- A call that is the very last action can be a `b`: a tail call, no stack
  growth.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/15-calling-convention/README.md)
next.
