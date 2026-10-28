# Lesson 21 (macOS): The heap

Do [lesson 21](../../lessons/21-the-heap/) in the main track first. This page covers
only what is different on macOS, then walks through the macOS version of each
example.

`malloc`, `calloc`, `realloc`, and `free` work the same way on macOS: same
arguments, same registers, same `NULL` on failure, same 16-byte alignment. The
growable array, the heap structs, and the ownership rules carry over unchanged.
What differs is the usual plumbing, how bugs show up, the tools that find them,
and how the allocator gets memory from the kernel.

## What is different

| Topic | Linux | macOS |
|-------|-------|-------|
| Function names | `malloc`, `calloc`, `realloc`, `free`, `memcpy` | `_malloc`, `_calloc`, `_realloc`, `_free`, `_memcpy` |
| `printf` arguments after the format | registers `x1`, `x2`, ... | on the stack, 8 bytes each (lesson 16) |
| Read-only tables of numbers | `.section .rodata` | `.section __TEXT,__const` (strings stay in `__TEXT,__cstring`) |
| Double free | glibc prints `free(): double free detected in tcache 2`, `SIGABRT`, status 134 | killed by `SIGTRAP`, status 133, often with no message |
| Finding leaks | `gcc -fsanitize=address` | `leaks --atExit -- ./prog` (AddressSanitizer's leak checker is not supported on macOS) |
| Finding double frees | `-fsanitize=address` | `clang -fsanitize=address` works too |
| How `malloc` gets memory | `brk` for small requests, `mmap` for big ones | `mmap`-style virtual memory calls only; there is no real `brk` heap |
| `mmap` in our example | raw system call 222 with `svc #0` | `bl _mmap` (the system call is not a stable interface) |
| `MAP_ANONYMOUS` value | `0x20` | `MAP_ANON` = `0x1000` |
| `mmap` failure | negative errno in `x0` (raw syscall) | returns `MAP_FAILED`, which is `(void *)-1` |
| Watching system calls | `strace` | `dtruss` needs SIP disabled; not worth it here |

Build and run everything natively:

```console
$ cd apple-silicon/21-the-heap/examples
$ make
```

## Walkthrough of the examples

### addresses.s

Same program. The three `printf` calls each have one argument after the format,
so each one becomes:

```asm
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    bl   _printf
    add  sp, sp, #16
```

The `printf("stack: ...")` call computes `add x1, sp, #24` *before* the
`sub sp, sp, #16`, so it still points at the local in `main`'s frame.

```console
$ ./addresses
static data: 0x102d68000
heap:        0x1034e9d00
stack:       0x16d09d8b8
```

The layout differs from Linux. Your program and its static data sit just above
`0x100000000` (macOS leaves the whole first 4 GiB unmapped so that a truncated
32-bit pointer always crashes), the heap is close above it, and the stack is
higher again. The pattern from the main lesson holds: static data and heap close
together, stack far away.

### malloc_array.s, calloc_realloc.s, vector.s, person.s

Line for line the same as the Linux versions, with `_`-prefixed names,
`@PAGE`/`@PAGEOFF`, and every `printf` argument stored on the stack. In
`vector.s` the push message has three arguments:

```asm
    ldr  x2, [sp, #32 + VEC_LEN]    // v.len   (read BEFORE sp moves)
    ldr  x3, [sp, #32 + VEC_CAP]    // v.cap
    sub  sp, sp, #32                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    str  x3, [sp, #16]
    bl   _printf
    add  sp, sp, #32
```

The `struct Vec` lives at `[sp, #32]` only while `sp` is where the prologue left
it. After `sub sp, sp, #32` the same struct would be at `[sp, #64]`. That is why
every load from the frame happens before the `sub`. Get this wrong and you print
garbage without any crash.

The outputs are identical to the main lesson.

### double_free.s

```console
$ ./double_free
freed once
zsh: trace trap  ./double_free
$ echo $?
133
```

macOS's allocator detects the second `free` too, but it stops the program with a
`brk` trap instruction (`SIGTRAP`, signal 5, so status 128 + 5 = 133) instead of
calling `abort`. Depending on your macOS version you may instead see a line like
`malloc: *** error for object 0x...: pointer being freed was not allocated`
followed by `Abort trap: 6` (status 134). Either way: the program is killed at the
bad `free`, not later.

To get a full report, build it with AddressSanitizer:

```console
$ clang -g -fsanitize=address double_free.s -o double_free_asan
$ ./double_free_asan
freed once
=================================================================
==57235==ERROR: AddressSanitizer: attempting double-free on 0x603000001c60 in thread T0:
...
$ rm -rf double_free_asan double_free_asan.dSYM
```

### leak.s

The program is the same. AddressSanitizer's leak checker does not run on macOS
(`detect_leaks is not supported on this platform`), but macOS ships its own tool,
`leaks`, which runs your program and inspects its heap just before it exits:

```console
$ leaks --atExit -- ./leak
...
Process 45658: 2 leaks for 224 total leaked bytes.
STACK OF 2 INSTANCES OF 'ROOT LEAK: <malloc in main_loop>':
...
```

Two leaks, as expected, but 224 bytes rather than 200: macOS's `malloc` rounds
each 100-byte request up to 112 bytes (a multiple of 16), and `leaks` reports the
real block size. Notice it even names the label `main_loop` where the leaked
blocks were allocated. `leaks` exits with status 1 when it finds a leak and 0 when
it finds none, so you can use it to check every program you write: run
`leaks --atExit -- ./exN` and look for `0 leaks for 0 total leaked bytes`.

Two environment variables are useful when hunting use-after-free bugs:
`MallocScribble=1` fills freed memory with `0x55` bytes, so reading a freed block
gives an obviously wrong value instead of the old one, and `MallocGuardEdges=1`
puts guard pages around large blocks.

### mmap_page.s

This is the one example that changes shape. On Linux it uses the raw `mmap`
system call. On macOS raw system calls are not a stable interface (lesson 05), so
we call the C library's `mmap`, which takes the same six arguments in `x0`-`x5`:

```asm
    .equ MAP_PRIVATE,   0x0002
    .equ MAP_ANON,      0x1000      // macOS value; Linux uses 0x20

    mov  x0, #0                     // addr: let the kernel choose
    mov  x1, #PAGE_SIZE             // length
    mov  w2, #(PROT_READ | PROT_WRITE)
    mov  w3, #(MAP_PRIVATE | MAP_ANON)
    mov  w4, #-1                    // fd: none
    mov  x5, #0                     // offset
    bl   _mmap
    cmn  x0, #1                     // failure returns MAP_FAILED, which is (void *)-1
    b.eq main_fail
```

`mmap` is not variadic, so all six arguments go in registers, even on macOS.
`prot`, `flags` and `fd` are C `int`s, so they go in `w` registers. The function
version reports failure differently from the raw Linux system call: it returns
`MAP_FAILED`, the all-ones address, and sets `errno` (lesson 25). `cmn x0, #1`
compares `x0` with -1. `munmap` returns the `int` 0 on success, so it is checked
with `cbnz w0`.

```console
$ ./mmap_page
got 4096 bytes from mmap
hello from a fresh page
page returned with munmap
```

macOS has no growing `brk` heap like Linux. Its allocator gets regions of virtual
memory from the kernel (through Mach virtual-memory calls, the same machinery
that sits behind `mmap`) and carves them up. The idea from the main lesson still applies: `malloc`
is library code that gets big chunks from the kernel and hands out small pieces.
Note that pages on Apple Silicon are really 16 KiB; asking for 4096 bytes still
works, the kernel just rounds up.

## Exercises

Do the exercises in the main lesson's
[exercises.md](../../lessons/21-the-heap/exercises.md) as macOS programs.
The macOS solutions are in [solutions/](solutions/). Where an exercise says to check
with `-fsanitize=address`, use `leaks --atExit -- ./exN` instead.

- `ex6.s` and `ex8.s` keep their tables of numbers (`widths`, `heights`, `sizes`)
  in `.section __TEXT,__const`. `__TEXT,__cstring` is only for strings: put
  `.quad` data there and the linker treats it as text and the program reads
  garbage.
- `ex8.s` maps its arena with `bl _mmap` and releases it with `bl _munmap`, as in
  `mmap_page.s`. Because `arena_init` and `arena_release` now call functions,
  they need a frame (`stp x29, x30` ...), which the Linux versions did not.
