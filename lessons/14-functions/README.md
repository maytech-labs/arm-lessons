# Lesson 14: Functions

## Goals

After this lesson you can:

- Call a function with `bl` and return with `ret`.
- Explain what the link register `x30` holds, and why a nested call destroys it.
- Write a prologue and epilogue that save and restore `x29` and `x30`.
- Tell a leaf function from a non-leaf function, and know which needs a frame.
- Pass arguments in `x0`, `x1`, ... and return a result in `x0`.
- Keep values that must survive a call in the frame or in `x19` and up.
- Read a backtrace in the debugger.
- Turn repeated code (like printing a number) into a reusable function.

## Before you start

You need lesson 13 (the stack, `stp`/`ldp` push and pop). This lesson covers
the mechanics of calling. Lesson 15 adds the complete rules (the *calling
convention*) for which registers a function may change.

```console
# cd lessons/14-functions/linux/examples && make
```

## The problem functions solve

In lessons 11-13 you copied the "print a number" block into every program,
sometimes twice in one file. A **function** is code written once, which can be
run from many places, and which then continues wherever it was called from.

The hard part is the last bit: *how does the function know where to go back
to?*

## `bl` and `ret`

```asm
_start:
    mov x0, #41                 // the argument goes in x0
    bl add_one                  // call: x30 = address of the next instruction, jump
    mov x8, #93                 // we come back here; the result is in x0
    svc #0

add_one:
    add x0, x0, #1
    ret                         // jump to the address in x30
```

- **`bl label`** ("branch with link") does two things: it puts the address of
  the *next* instruction into **`x30`**, then jumps to `label`.
- **`ret`** jumps to the address in `x30`.

`x30` is called the **link register** (`lr`). It "links" back to the caller.
That's `examples/first_call.s`; it exits with 42.

See it in the debugger:

```console
# gdb -q ./first_call
(gdb) break add_one
(gdb) run
(gdb) p/x $x30
$1 = 0x4000dc
(gdb) x/i $x30
   0x4000dc <_start+8>:	mov	x8, #0x5d                  	// #93
```

`x30` holds the address of the `mov x8, #93` right after the `bl`.

In C, this is:

```c
long add_one(long n) { return n + 1; }
...
exit(add_one(41));
```

## Arguments and results

There is nothing magic about which registers carry arguments; it is an
agreement between caller and function. Everyone on AArch64 uses the same one:

- arguments go in **`x0`, `x1`, `x2`, ...** in order
- the result comes back in **`x0`**

`examples/two_args.s` calls `max(a, b)` twice:

```asm
    mov x0, #17                 // first argument
    mov x1, #42                 // second argument
    bl max                      // x0 = max(17, 42)
    mov x1, #30                 // x0 is already the first argument
    bl max                      // x0 = max(x0, 30)
    ...

max:
    cmp x0, x1
    csel x0, x0, x1, gt
    ret
```

Notice how naturally the result of one call (`x0`) becomes the first argument
of the next: C's `max(max(17, 42), 30)`.

Document every function with a comment saying what goes in and what comes out:

```asm
// long max(long a, long b)
//   in:  x0 = a, x1 = b
//   out: x0 = the larger, as signed numbers
```

In assembly, that comment *is* the function's prototype. Nothing else records
it.

## The problem: calling from inside a function

What if a function calls another function? `bl` overwrites `x30`, so the
outer function loses its own return address. `examples/lost_return.s`:

```asm
_start:
    mov x19, #0                 // counter
    bl outer                    // x30 = address of the mov below
    mov x0, x19                 // exit(counter)
    ...

outer:
    bl inner                    // OVERWRITES x30 with the address of the add below
    add x19, x19, #1            // count how often we get here
    cmp x19, #3
    b.ge give_up                // safety net so the bug cannot loop forever
    ret                         // x30 still points at the add above: loops!
```

When `outer` executes `ret`, `x30` holds the return address *into outer*
that `bl inner` left behind. So `ret` jumps back to the `add`, which counts
again, reaches `ret` again, and so on. Without the safety net, this would
loop forever.

```console
# ./lost_return; echo $?
3
```

It should have been 1.

The linter from lesson 00 spots this bug without running the program. In a
Mac terminal, from this lesson's folder:

```console
$ armtool lint linux/examples/lost_return.s
linux/examples/lost_return.s:24:5: warning[abi/link-register]: this call overwrites x30, and 'outer' never saves it, so it can't return to its caller. Save it first: stp x29, x30, [sp, #-16]!
linux/examples/lost_return.s:25:5: warning[abi/callee-saved]: 'outer' changes x19 without saving it, but callers expect x19 to survive the call. Save it in the prologue and restore it before ret
```

The first warning is the bug above, and its suggested fix is the one this
lesson uses next. The second is about which registers a function may change
freely. Lesson 15 explains that rule; this program breaks it on purpose, to
keep the counter simple.

## The fix: save `x30` on the stack

A function that calls other functions must save `x30` before its first `bl`
and restore it before its `ret`. The stack (lesson 13) is the place to save
it. `examples/fixed_return.s`:

```asm
outer:
    stp x29, x30, [sp, #-16]!   // prologue: save the frame pointer and return address
    mov x29, sp                 //           x29 = this function's frame
    bl inner                    // free to overwrite x30 now
    add x19, x19, #1
    ldp x29, x30, [sp], #16     // epilogue: restore them...
    ret                         // ...so ret goes back to _start
```

Now it exits with 1.

### The frame record: `x29` and `x30`

Why save `x29` too? `x29` is the **frame pointer** (`fp`). By convention,
every function that sets up a frame:

1. pushes the caller's `x29` and its own return address `x30` as a pair, and
2. sets `x29` to point at that pair.

That pair is called the **frame record**. Each record contains the previous
`x29`, which points at the *previous* record, and so on: the frame records
form a linked list through the stack, from the current function back to the
first one. Debuggers follow it to show you who called whom.

These two instructions are the standard **prologue**:

```asm
    stp x29, x30, [sp, #-N]!    // N = frame size, a multiple of 16
    mov x29, sp
```

and this is the standard **epilogue**:

```asm
    ldp x29, x30, [sp], #N
    ret
```

You will write these hundreds of times. They are also exactly what a C
compiler produces for most functions.

## Leaf and non-leaf functions

| Kind | Calls other functions? | Must save `x30`? | Example |
|------|------------------------|------------------|---------|
| **leaf** | no | no | `add_one`, `max`, `square` |
| **non-leaf** | yes | **yes** | `outer`, `sum_squares` |

A leaf function can just use `x30` where it is. It may still use the stack for
local variables (as `print_uint` below does), but it does not need a frame
record. A `svc` is not a function call: it does not touch `x30`.

## Keeping values across a call

`examples/frame.s` computes `square(a) + square(b)`:

```c
long square(long n) { return n * n; }
long sum_squares(long a, long b) { return square(a) + square(b); }
```

`sum_squares` has two problems: it needs `b` *after* the first call to
`square`, and it needs the first result *after* the second call. But a called
function is allowed to change `x0`-`x18` (lesson 15 states the exact rules).
So both values go into the frame:

```asm
// Frame (32 bytes):
//   [sp, #0]   saved x29
//   [sp, #8]   saved x30
//   [sp, #16]  b          (square may change x1, so keep b in memory)
//   [sp, #24]  square(a)
sum_squares:
    stp x29, x30, [sp, #-32]!   // reserve 32 bytes, save x29 and x30 at the bottom
    mov x29, sp
    str x1, [sp, #16]           // save b: we still need it after the first call

    bl square                   // x0 = square(a)
    str x0, [sp, #24]           // save it: the second call will overwrite x0

    ldr x0, [sp, #16]           // x0 = b
    bl square                   // x0 = square(b)

    ldr x1, [sp, #24]           // x1 = square(a)
    add x0, x0, x1              // result = square(a) + square(b)

    ldp x29, x30, [sp], #32     // restore and release the whole frame
    ret
```

The prologue's `stp ..., [sp, #-32]!` reserves the whole 32-byte frame and saves
the frame record at its bottom in one instruction. The epilogue's
`ldp ..., [sp], #32` restores the record and releases the frame in one.

Write the frame layout as a comment before writing the function.

### `x19` and up

The other way to keep a value across a call is to keep it in **`x19`-`x28`**,
which functions promise not to change. `_start` in `print_uint.s` keeps its
loop counter in `x19` for that reason. But that promise has a cost: a function
that *itself* wants to use `x19` must save the old value first and restore it
before returning. That is lesson 15. In this lesson, our functions only use
`x0`-`x15` for their own work, and only `_start` uses `x19`.

## The backtrace

With frame records in place, the debugger can show the chain of calls:

```console
# gdb -q ./frame
(gdb) break square
(gdb) run
(gdb) bt
#0  square () at frame.s:50
#1  0x00000000004000f8 in sum_squares () at frame.s:36
#2  0x00000000004000e0 in _start () at frame.s:19
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
```

Read it bottom to top: `_start` called `sum_squares`, which called `square`.
The addresses are the return addresses saved in each frame. The last line is
gdb running out of frame records at `_start`, which has no caller; it is
harmless here.

`bt` is the first thing to type when a program crashes inside a function:
it tells you where you are and how you got there.

## A real reusable function: `print_uint`

`examples/print_uint.s` finally turns the print block into functions:

```asm
// void print_uint(unsigned long n)
//   in:  x0 = n
print_uint:
    sub sp, sp, #32             // char buf[32]
    add x5, sp, #32             // x5 = end of buf
    mov x1, x5                  // x1 = p
    mov x3, #10
print_uint_digit:
    udiv x4, x0, x3             // x4 = n / 10
    msub x6, x4, x3, x0         // x6 = n % 10
    add w6, w6, #'0'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x0, x4                  // n /= 10
    cbnz x0, print_uint_digit
    mov x0, #1                  // write(1, p, end - p)
    sub x2, x5, x1
    mov x8, #64
    svc #0
    add sp, sp, #32
    ret
```

It is a leaf (no `bl`), with a 32-byte local buffer. `print_char` is a leaf
too, with a 16-byte frame for its 1-byte buffer. The main loop calls them:

```console
# ./print_uint
1 4 9 16 25
```

Labels inside a function are prefixed with the function's name
(`print_uint_digit`), so that they cannot clash with labels in other functions
in the same file.

From now on, every example copies these helpers in rather than repeating the
block inline.

## A recipe for writing a function

1. Write the C prototype as a comment, with which register holds what.
2. Leaf or non-leaf? Non-leaf needs the prologue and epilogue.
3. Which values must survive a call? Give each a slot in the frame.
4. Write the frame layout as a comment and compute its size (round up to 16).
5. Write the body.
6. Check: every path to `ret` goes through the epilogue, and the epilogue's
   size matches the prologue's.

## C to assembly

| C | Assembly |
|---|----------|
| `long f(long a, long b)` | `f:` with `a` in `x0`, `b` in `x1` |
| `return x;` | put `x` in `x0`, then `ret` (after the epilogue) |
| `y = f(1, 2);` | `mov x0, #1` / `mov x1, #2` / `bl f` / result in `x0` |
| `f(g(x))` | `bl g` then `bl f` (g's result is already in `x0`) |
| non-leaf function | `stp x29, x30, [sp, #-N]!` / `mov x29, sp` ... `ldp x29, x30, [sp], #N` / `ret` |
| local variable used across a call | a slot in the frame: `str` before, `ldr` after |

## Common mistakes

- **Not saving `x30` in a non-leaf function.** `ret` goes to the wrong place:
  an infinite loop or a crash.
- **Mismatched prologue and epilogue sizes.** `sp` is wrong when you return,
  and the caller's frame is corrupted.
- **An early `ret` that skips the epilogue.** Every exit path must restore
  `x29`/`x30` and `sp`. Branch to one epilogue label instead.
- **Expecting `x1`-`x15` to survive a call.** They are the callee's to use.
  Keep the value in the frame (or in `x19`+, lesson 15).
- **Forgetting that the result is in `x0`**, and overwriting it while setting
  up the next call's arguments.
- **Falling into a function.** If `_start` does not end with `exit`, execution
  runs on into the first function below it. Put functions after the exit.
- **Using `b` instead of `bl`.** `b` does not set `x30`, so the function's
  `ret` returns to wherever `x30` last pointed.

## Recap

- `bl f` sets `x30` to the return address and jumps; `ret` jumps to `x30`.
- Arguments in `x0`, `x1`, ...; the result in `x0`.
- A non-leaf function must save `x30`; together with `x29` it forms the frame
  record: `stp x29, x30, [sp, #-N]!` / `mov x29, sp`.
- Restore with `ldp x29, x30, [sp], #N` before `ret`.
- Leaf functions need no frame record.
- Values needed after a call go into the frame (or `x19`+).
- `bt` in the debugger follows the frame records.
- Document every function's inputs and outputs in a comment.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
