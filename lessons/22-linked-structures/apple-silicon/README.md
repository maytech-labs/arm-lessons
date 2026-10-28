# Lesson 22 (macOS): Linked structures

Do [the main lesson](../) first. Lists, stacks,
queues, and trees are pure data-structure code: the node layouts, the `.equ`
offsets, the pointer walks, the recursion, and every instruction in the
functions that manipulate nodes are identical on macOS. Only the usual plumbing
changes.

## What is different

| | Linux | macOS |
|-|-------|-------|
| Entry point | `main` | `_main` |
| C library calls | `bl malloc`, `bl free`, `bl printf`, `bl puts`, `bl putchar`, `bl exit` | `bl _malloc`, `bl _free`, `bl _printf`, `bl _puts`, `bl _putchar`, `bl _exit` |
| Address of a string | `adrp x0, fmt` / `add x0, x0, :lo12:fmt` | `adrp x0, fmt@PAGE` / `add x0, x0, fmt@PAGEOFF` |
| Strings | `.section .rodata` | `.section __TEXT,__cstring` |
| Read-only tables (`keys:`) | `.section .rodata` | `.section __TEXT,__const` |
| `printf(" %ld", v)` | `v` in `x1` | `v` stored at `[sp]` (variadic) |

Your own functions (`push_front`, `bst_insert`, ...) are not visible outside
the file, so they need no underscore. The underscore is only for C names:
`_main` and the libc functions.

### The one real change: printing a value

Every program here prints with `printf(" %ld", value)`. `printf` is variadic,
and on macOS every variadic argument goes on the stack (lesson 16). So each such
call reserves 16 bytes (to keep `sp` 16-byte aligned), stores the value at
`[sp]`, calls, and gives the 16 bytes back. From `print_list`:

```asm
// Linux                                  // macOS
    adrp x0, fmt_item                         adrp x0, fmt_item@PAGE
    add x0, x0, :lo12:fmt_item                add x0, x0, fmt_item@PAGEOFF
    ldr x1, [x19, #NODE_VALUE]                sub sp, sp, #16
    bl printf                                 ldr x9, [x19, #NODE_VALUE]
                                              str x9, [sp]   // variadic argument goes on the stack
                                              bl _printf
                                              add sp, sp, #16
```

The `sub sp` / `add sp` pair sits *after* the prologue has saved `x29`, `x30`,
and `x19` in the frame, so `[sp]` during the call is fresh space below the
frame, not the saved registers. If you instead wrote the value to `[sp]`
without the `sub`, you would overwrite the saved `x29` and the function would
return into garbage.

Calls whose only argument is the format string (`printf(label)` in
`print_list`, `printf("in order:")` in `bst.s`) are the same as on Linux: the
format itself is a named argument and goes in `x0`.

### A tip for finding memory bugs

macOS ships a leak checker. It runs your program and, when it exits, reports
every `malloc` block nobody freed:

```console
$ leaks --atExit -- ./list_ops
...
Process 12345: 0 leaks for 0 total leaked bytes.
```

Delete the `bl free_list` from `main` and run it again: it reports 3 leaks:
the three nodes still in the list. Setting `MallocScribble=1` in the environment makes
`free` fill freed blocks with `0x55` bytes, so use-after-free bugs (like the one
in exercise 22.2) show up as garbage instead of seeming to work:

```console
$ MallocScribble=1 ./list_ops
```

## The examples

Build them all:

```console
$ cd lessons/22-linked-structures/apple-silicon/examples
$ make
```

### list_basics.s

`push_front`, `print_list`, `list_length`, `free_list`, exactly as in the main
lesson. `push_front` calls `_malloc` and branches to `out_of_memory` (which
calls `_puts` and `_exit`) on `NULL`. `print_list` stores each value at `[sp]`
around `_printf`; `main` does the same for the length.

```console
$ ./list_basics
list: 30 20 10
length: 3
```

### list_ops.s

Append, find, remove, reverse. The list functions themselves have no libc calls
except `_malloc` and `_free`, so they differ from Linux only in those two names.
`report_find` picks `"yes"` or `"no"` with `csel` and prints it with `_puts`
(not variadic: same as Linux).

```console
$ ./list_ops
built: 1 2 3 4 5
find 3: yes
find 9: no
remove 1: 2 3 4 5
remove 4: 2 3 5
remove 9: 2 3 5
reverse: 5 3 2
```

### stack_queue.s

The stack and queue structs live in `main`'s frame at `[sp, #32]` and
`[sp, #40]`. The pop loop reads `s.top` with `ldr x9, [sp, #MAIN_STACK]`
*before* the `sub sp, sp, #16` for `_printf`. That order matters: after the
`sub`, `sp` has moved, and `[sp, #MAIN_STACK]` would point 16 bytes too low. If
you ever need a frame variable while `sp` is lowered, address it from `x29`
instead, which does not move.

```console
$ ./stack_queue
pop: 3 2 1
dequeue: 1 2 3
```

### list_recursive.s

`length_rec`, `print_forwards`, and `print_backwards` are unchanged apart from
the `_printf` call in the two printers. Each recursive level lowers `sp` by its
32-byte frame and, during its `_printf`, by 16 more; it all comes back as the
calls return.

```console
$ ./list_recursive
forwards: 1 2 3 4
length (loop): 4
length (recursion): 4
backwards: 4 3 2 1
```

### bst.s

The keys table moves to `__TEXT,__const` and the strings to `__TEXT,__cstring`:

```asm
    .section __TEXT,__const
    .p2align 3
keys:        .quad 50, 30, 70, 20, 40, 60, 80, 35
    .section __TEXT,__cstring
fmt_item:    .asciz " %ld"
```

`report_search` chooses between two format strings with `csel` and passes the
key on the stack. `NKEYS` is defined with the other `.equ`s at the top of the
file rather than computed after the table: Apple's assembler refuses to use a
symbol in an instruction's immediate (`cmp x20, #NKEYS`) if the symbol is only
defined further down. Defining constants before their first use always works on
both assemblers.

```console
$ ./bst
in order: 20 30 35 40 50 60 70 80
height: 4
search 60: found
search 65: not found
```

## Exercises

Do the exercises from the main lesson's
[../exercises.md](../exercises.md) as macOS
programs. macOS versions of every programming solution are in
[solutions/](solutions/); the written answers are in the main lesson's
[../answers.md](../answers.md).
In `ex5.s`, `remove_all` uses `add x19, sp, #32` to get `&head`; it makes no
variadic call, so `sp` never moves while `link` points into the frame.
