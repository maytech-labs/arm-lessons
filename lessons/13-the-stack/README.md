# Lesson 13: The stack

## Goals

After this lesson you can:

- Explain what the stack is, where it lives, and which way it grows.
- Keep `sp` 16-byte aligned, and recognise the crash when you do not.
- Reserve and release stack space with `sub sp` and `add sp`.
- Push and pop registers with `stp`/`ldp` using pre- and post-indexing.
- Keep local variables and local arrays on the stack instead of in `.bss`.
- Inspect the stack in the debugger.
- Recognise a stack overflow.

## Before you start

You need lesson 11 (loads, stores, pre/post-index, `ldp`/`stp`) and lesson 12
(arrays). There are still no functions; that is lesson 14. But functions need
the stack, so we learn it first, on its own.

```console
# cd lessons/13-the-stack/linux/examples && make
```

## Why a stack?

So far every variable lived in a register or in `.data`/`.bss`. Both have
limits:

- There are only about 30 registers.
- `.data` and `.bss` are fixed at build time: one copy of each variable for
  the whole program. That is how C's *global* variables work.

C's **local** variables are different. They exist only while their block (or
function) runs, and when a function calls itself (lesson 15), each call needs
its *own* copy. The **stack** provides that: a region of memory where space is
taken and given back in last-in, first-out order.

## Where the stack is

When the kernel starts your program, it sets up a few megabytes of memory for
the stack (8 MiB by default on Linux) and points the **stack pointer**, `sp`,
at its top. Look:

```console
# gdb -q ./sp
(gdb) starti
(gdb) p/x $sp
$1 = 0xfffffffffd20
```

Your number will differ, but it will be large (near the top of the address
space) and end in 0.

The stack **grows downward**. To take space, you *subtract* from `sp`; to give
it back, you *add*. The bytes at `sp` and above are in use; below `sp` is free.

```
 high addresses
 +-----------------+
 |  (in use)       |
 |  ...            |
 |  your data      |  <- sp: the lowest byte in use
 +-----------------+
 |  free           |  <- grows this way when you subtract from sp
 |                 |
 low addresses
```

## Rule: `sp` is always a multiple of 16

AArch64 requires that whenever `sp` is used to access memory, it is
**16-byte aligned**: a multiple of 16. `examples/sp.s` exits with `sp % 16`,
which is always 0.

So you always move `sp` in multiples of 16. Need 8 bytes? Take 16. Need 20?
Take 32. The rounding trick from lesson 08 computes it:
`(n + 15) & ~15`.

What happens if you break the rule? `examples/misaligned.s`:

```asm
    sub sp, sp, #8              // WRONG: sp is now 8 bytes off a multiple of 16
    mov x0, #42
    str x0, [sp]                // any load/store through a misaligned sp faults
```

```console
# ./misaligned; echo $?
Bus error (core dumped)
135
```

`SIGBUS` (signal 7; 128 + 7 = 135). The CPU checked the alignment of `sp` and
refused. This crash is very common in hand-written assembly. When you see
`Bus error`, check every `sub sp` and `add sp`.

If you installed arm-tools (lesson 00), the linter finds this before you
run anything. In a Mac terminal, from this lesson's folder:

```console
$ armtool lint linux/examples/misaligned.s
linux/examples/misaligned.s:13:5: warning[abi/stack-alignment]: this moves sp by 8 bytes, which isn't a multiple of 16, so sp loses its required 16-byte alignment. Use 16
linux/examples/misaligned.s:16:5: warning[abi/stack-alignment]: this moves sp by 8 bytes, which isn't a multiple of 16, so sp loses its required 16-byte alignment. Use 16
```

With `armls` in your editor, the same warning appears under the line as
you type it.

## Reserving space: `sub sp` and `add sp`

`examples/locals.s` keeps four `long` locals on the stack:

```c
long w = 6, h = 7;
long area = w * h;
long perimeter = 2 * (w + h);
return area - perimeter;
```

```asm
    sub sp, sp, #32             // make room for four longs (32 bytes, a multiple of 16)

    mov x0, #6
    str x0, [sp, #0]            // w = 6
    mov x0, #7
    str x0, [sp, #8]            // h = 7

    ldp x1, x2, [sp, #0]        // x1 = w, x2 = h (two neighbours in one load)
    mul x3, x1, x2
    str x3, [sp, #16]           // area = w * h
    ...
    add sp, sp, #32             // give the space back
```

The block of stack your code reserves is called a **stack frame**. Decide its
**layout** first and write it in a comment:

```
    [sp, #0]   w
    [sp, #8]   h
    [sp, #16]  area
    [sp, #24]  perimeter
```

Every local is then just "`sp` plus a fixed offset". The C compiler does
exactly the same; that is where local variables live when they do not fit in
registers.

`add sp, sp, #32` does not erase anything. The bytes are still there; they are
just no longer "in use", and the next `sub sp` may reuse them. That is why an
uninitialised C local holds garbage: it is whatever the last user left there.

**Every `sub sp` must be matched by an `add sp` of the same amount.**

## Pushing and popping

The stack can also be used as a *stack* in the data-structure sense: push
values, then pop them in reverse order. AArch64 has no `push` or `pop`
instruction. Instead:

| Operation | Instruction | Meaning |
|-----------|-------------|---------|
| push two | `stp x1, x2, [sp, #-16]!` | `sp -= 16`, then store `x1` at `sp`, `x2` at `sp + 8` |
| pop two | `ldp x1, x2, [sp], #16` | load `x1` from `sp`, `x2` from `sp + 8`, then `sp += 16` |
| push one | `str x1, [sp, #-16]!` | `sp -= 16`, store (8 bytes wasted, alignment kept) |
| pop one | `ldr x1, [sp], #16` | load, then `sp += 16` |

These are the pre-index (`[...]!`: move first) and post-index (`[...], #n`:
move after) modes from lesson 11. Pushing moves `sp` *before* storing; popping
moves it *after* loading.

`examples/push_pop.s`:

```asm
    stp x1, x2, [sp, #-16]!     // push 10, 20
    stp x3, x4, [sp, #-16]!     // push 30, 40
    ...wipe the registers...
    ldp x13, x14, [sp], #16     // pop: the LAST pair pushed (30, 40)
    ldp x11, x12, [sp], #16     // pop: the first pair (10, 20)
```

Last in, first out. Pairs are the natural unit, because two 8-byte registers
are exactly 16 bytes and keep `sp` aligned. This exact `stp ... [sp, #-16]!`
instruction will start almost every function you write from lesson 14 on.

### Looking at it in the debugger

Stop after the two pushes and examine memory at `sp`:

```console
(gdb) x/4gx $sp
0xfffffffffcf0: 0x000000000000001e  0x0000000000000028
0xfffffffffd00: 0x000000000000000a  0x0000000000000014
```

The most recent push (30 = `0x1e`, 40 = `0x28`) is at `sp`, the lowest
address. The earlier one (10, 20) is 16 bytes higher. `x/4gx $sp` ("4 giant
words in hex at sp") is the command you will use most for the stack.

## Local arrays

A local array is just a bigger frame. `examples/stack_buffer.s` is the print
block from lessons 11 and 12, but the 32-byte digit buffer is now a local
`char buf[32]` instead of a `.bss` variable:

```asm
    sub sp, sp, #32             // char buf[32], at sp .. sp+31
    ...
    add x5, sp, #32             // x5 = buf + 32 (one past the end)
    mov x1, x5                  // x1 = p
    ...
    strb w6, [x1, #-1]!         // *--p = digit
    ...
    add sp, sp, #32             // free buf
```

`sp` itself is the address of `buf[0]`, so `add x5, sp, #32` is `buf + 32`.

`examples/reverse_line.s` reads a line into a 64-byte stack buffer and prints
it backwards:

```console
# echo hello | ./reverse_line
olleh
```

Note `mov x1, sp`: `read` needs the buffer's address, and that address is just
`sp`.

## Stack overflow

The stack is big, but not infinite. `examples/overflow.s` pushes forever:

```asm
again:
    stp x1, x1, [sp, #-16]!     // push 16 bytes, forever
    add x1, x1, #1
    b again
```

```console
# ./overflow; echo $?
Segmentation fault (core dumped)
139
```

After about 8 MiB, `sp` moves below the memory the kernel set aside, and the
next store touches an address that does not exist: `SIGSEGV`. This is a
**stack overflow**. In real programs it usually comes from recursion that
never stops (lesson 15) or a huge local array. In gdb, `p $x1` after the crash
shows how many pushes succeeded.

## `sp` is special

- In most instructions, register number 31 means `xzr`. In `add`, `sub`,
  `mov`, and addressing modes it means `sp`. The assembler handles this; you
  just write `sp`.
- You cannot use `sp` everywhere: `mul x0, sp, x1` is an error. Copy it to a
  normal register first (`mov x1, sp`).

## C to assembly

| C | Assembly |
|---|----------|
| `{ long a, b, c, d; ...}` | `sub sp, sp, #32` ... `add sp, sp, #32` |
| `a = 5;` (a local at offset 0) | `mov x0, #5` / `str x0, [sp, #0]` |
| `x = b;` (offset 8) | `ldr x0, [sp, #8]` |
| `char buf[64];` | `sub sp, sp, #64`; `buf` is `sp` |
| `&buf[i]` | `add x1, sp, xi` |
| `long sq[10];` (80 bytes) | `sub sp, sp, #80` |
| `int t[3];` (12 bytes) | `sub sp, sp, #16`: rounded up to 16 |
| saving two values for later | `stp x19, x20, [sp, #-16]!` ... `ldp x19, x20, [sp], #16` |

## Common mistakes

- **Moving `sp` by a non-multiple of 16.** `Bus error`. Round up.
- **Unbalanced `sub`/`add`.** `sp` ends up somewhere else, and every offset
  after that is wrong. Count them.
- **Popping in the wrong order.** Last in, first out: pop in the reverse order
  you pushed.
- **Using memory below `sp`.** It is free space; anything may overwrite it.
  (There is no "red zone" on Linux AArch64.)
- **Keeping a pointer into the stack after `add sp`.** The data is no longer
  yours. In C this is returning the address of a local variable.
- **Reading a local before writing it.** You get leftovers, not zero.
- **Using `x31`** when you mean `sp`. Write `sp`.

## Recap

- The stack is memory that grows **downward**; `sp` points at the lowest byte
  in use.
- `sp` must always be a multiple of 16; otherwise `Bus error`.
- `sub sp, sp, #N` reserves N bytes; `add sp, sp, #N` releases them. Always in
  pairs.
- Locals are at fixed offsets from `sp`; write the frame layout as a comment.
- Push a pair with `stp a, b, [sp, #-16]!`; pop with `ldp a, b, [sp], #16`.
- Local arrays are bigger frames; `sp` is the address of element 0.
- Running out of stack is a stack overflow: `Segmentation fault`.
- `x/4gx $sp` shows the top of the stack in gdb.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
