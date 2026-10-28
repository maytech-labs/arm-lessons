# Lesson 31: Capstone

## Goals

After this lesson you can:

- Plan a program of several hundred lines of assembly before writing any of it.
- Split it into functions with clear contracts and a register plan for each.
- Build it in small, tested steps, and find bugs with `gdb` when a step fails.
- Write five complete tools in assembly: `wc`, an RPN calculator, a word
  frequency counter with your own hash table, Conway's Game of Life, and a
  Brainfuck interpreter.

## Before you start

This lesson uses everything. The parts you will lean on most:

- Lesson 15 (calling convention) and lesson 16 (calling C): every project calls libc.
- Lesson 17 (strings) and lesson 25 (I/O and arguments): reading input, `argv`, `errno`.
- Lesson 21 (the heap) and lesson 19 (structs): the hash table and the grids.
- Lesson 24 (function pointers): the `qsort` comparator, and an optional jump table.
- Lesson 27 (compiler output): comparing your code with what `gcc` writes.

There is very little new in this lesson. It is about putting things together.

## How the capstone works

There are five projects. Each is an exercise in [exercises.md](exercises.md)
with a full specification: what the program must do, a suggested design,
milestones, and test inputs with their expected output.

Every project is a real command-line tool, and every one has automatic tests
in `tests/`. Do your work in `work/` inside this lesson, one directory per
project:

```console
$ mkdir -p work/wc
$ cd work/wc
$ printf 'include ../../../../mk/linux.mk\n' > Makefile
$ vi wc.s
$ make
$ cd ../..
$ ./tests/check.sh wc work/wc/wc
PASS wc/stdin-all
PASS wc/stdin-lines
...
11 passed, 0 failed
```

Notice the `include` line: `work/wc/` is one directory deeper than an
`examples/` directory, so it needs four `../` to reach the repository root.

`check.sh` runs your program on every test in `tests/PROJECT/cases` and
compares its output, its error messages and its exit status with the expected
ones. When a test fails it shows the difference: lines starting with `<` are
what was expected, `>` is what your program printed.

The solutions are in `solutions/wc/`, `solutions/rpn/`, and so on. Running
`make` in `solutions/` builds all five, and `./tests/check.sh all solutions`
tests all five. Try each project yourself before you look.

## A method for big programs

Up to now your programs have been one or two functions. The projects here are
200 to 500 lines. Typing 400 lines of assembly and then running it for the
first time does not work: something will be wrong, and you will have no idea
where. Here is a method that does work.

### 1. Write it in C first

Really write it, compile it, and run it against the tests. It takes twenty
minutes and gives you three things: you find the design problems while they are
cheap to fix, you have a reference to compare against, and the C becomes the
comment block at the top of your `.s` file (every solution here has one).

```console
$ gcc -Wall -O2 wc.c -o wc_c
$ ../../tests/check.sh wc ./wc_c
```

### 2. Split it into small functions

Each function should do one thing you can describe in one line. Write that line
as a comment, with the arguments and the return value:

```asm
// void count_stream(FILE *f, long *c)
//   Reads f to the end. Stores lines, words, bytes in c[0], c[1], c[2].
```

A function that fits on one screen is a function you can check by reading it.
And small functions keep the register juggling small: you only have to track
what is live inside *this* function.

### 3. Decide where every piece of data lives

For each piece of data, choose one of:

| Where | When | Example |
|-------|------|---------|
| A register | small, used in one function | a loop counter |
| A callee-saved register (`x19`-`x28`) | must survive a `bl` | a `FILE *` you read in a loop |
| The stack frame | an array or struct local to one call | the 1024-byte line buffer |
| `.bss` / `.data` | fixed size, needed by several functions | the 30000-byte Brainfuck tape |
| The heap | size known only at run time, or grows | the hash table |

### 4. Write a register plan for each function

Before writing a function, write a comment listing which register holds which
variable. This is the recipe from lesson 27:

```asm
// x19 = f, x20 = c, x21 = lines, x22 = words, x23 = bytes, x24 = inword
```

Anything live across a call goes in `x19`-`x28`. Scratch values that never cross
a call go in `x9`-`x15`. Then the prologue writes itself: save `x29`, `x30` and
exactly the callee-saved registers in the plan.

### 5. Build in milestones, and test each one

Each project in `exercises.md` has milestones: small versions that already run.
For `wc`: first count only bytes from stdin; then lines; then words; then
files; then flags. After each milestone, build and run. When something breaks,
the bug is in the twenty lines you just wrote.

### 6. When it crashes, use gdb

A segmentation fault tells you nothing on its own. `gdb` tells you exactly which
instruction faulted and what was in the registers (lesson 06):

```console
$ gdb --args ./wc -l poem.txt
(gdb) run
Program received signal SIGSEGV, Segmentation fault.
count_stream () at wc.s:97
97          ldrb w11, [x9], #1
(gdb) info registers x9 x10
(gdb) bt
(gdb) x/s $x0
```

`bt` (backtrace) shows the chain of calls that got you here, which only works
if every function sets up `x29` properly. That is one more reason to always
write the full prologue. To stop at a function and step through it:

```console
(gdb) break count_stream
(gdb) run
(gdb) stepi
(gdb) info registers
```

The most common crash causes are in the "Common mistakes" section below. Check
them first.

## Two building blocks

The `examples/` directory has two small programs that do the input handling
the projects need. Use them as a starting point.

### linecat: reading lines

`examples/linecat.s` reads stdin one line at a time with `fgets` and prints each
line with a number. `rpn` reads its input exactly this way. In C:

```c
char line[1024];
int n = 0;
while (fgets(line, sizeof line, stdin) != NULL) {
    n++;
    printf("%4d: %s", n, line);
}
```

The buffer is a local array, so it lives in the stack frame. The frame is
`16` (for `x29`, `x30`) `+ 16` (for `x19`, `x20`) `+ 1024` = 1056 bytes, which
is a multiple of 16, so `sp` stays aligned. The prologue cannot use
`stp x29, x30, [sp, #-1056]!` because a pre-index offset must be between -512
and 504, so it subtracts first and stores second:

```asm
    sub sp, sp, #1056
    stp x29, x30, [sp]
    mov x29, sp
    stp x19, x20, [sp, #16]
```

`stdin` is loaded once, through the GOT (lesson 25), into the callee-saved
`x20`, because it is needed again after every `fgets` and `printf`.

Predict the output for `poem.txt`, which has five lines, one of them empty. Then
check:

```console
$ cd examples
$ make
$ ./linecat < poem.txt
   1: The quick brown fox
   2: jumps over
   3: the lazy dog.
   4: 
   5: It was not amused.
```

Line 4 is `"\n"` on its own, so it prints as `   4: ` and a newline.

### slurp: reading a whole file

`examples/slurp.s` reads the file named in `argv[1]` into one heap buffer. `bf`
and `life` need their whole input in memory, and this is how they get it:

```c
FILE *f = fopen(argv[1], "rb");
fseek(f, 0, SEEK_END);       // jump to the end...
long size = ftell(f);        // ...and ask where we are: the size
fseek(f, 0, SEEK_SET);       // back to the start
char *buf = malloc(size + 1);
size_t n = fread(buf, 1, size, f);
buf[n] = '\0';               // a NUL at the end makes it a C string too
```

`SEEK_SET` and `SEEK_END` are just the numbers 0 and 2; the program names them
with `.equ`. The extra byte for the NUL means you can walk the buffer with
`ldrb` until you hit zero, like any string.

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

`fseek`/`ftell` only works on real files. Reading from a pipe needs the other
method: `fread` chunks into a buffer and `realloc` it bigger when it fills
(lesson 21). Neither project needs that, but it is a good extra exercise.

## The projects

Here is the shape of each project. The full specifications are in
[exercises.md](exercises.md).

### 1. wc: counting with a state machine

Counting lines and bytes is easy: bytes is the sum of what `fread` returns,
lines is the number of `'\n'` bytes. Words need one bit of *state*: are we
inside a word right now? A word starts at a non-space byte that follows a space
(or the start of the input):

```c
if (is_space(ch)) inword = 0;
else if (!inword) { inword = 1; words++; }
```

Keep `inword` in a register that survives from one `fread` chunk to the next,
or a word split across two chunks is counted twice. The `-l`/`-w`/`-c` flags are
a bitmask (lesson 08): bit 0 for lines, bit 1 for words, bit 2 for bytes. The
printing loop tests one bit per count.

### 2. rpn: a stack machine

Reverse Polish notation puts the operator after its operands: `3 4 +` means
3 + 4, and `3 4 + 2 *` means (3 + 4) * 2. No parentheses are ever needed. The
evaluator is a loop over tokens with an array as a stack: a number is pushed;
an operator pops two values and pushes the result.

Two useful tricks:

- Split the line *in place*: walk to the end of a token and write a `0` byte
  there. The token is now a C string you can pass to `strtol` or `strcmp`,
  and you did not copy anything.
- `strtol(tok, &end, 10)` tells you whether the *whole* token was a number:
  afterwards, `end` points at the first byte it did not use. If `*end == 0`, it
  used everything. `&end` is the address of an 8-byte slot in your frame.

### 3. wordfreq: your own hash table

A hash table is an array of slots. Each slot holds a key (a `char *`) and a
count. To find a word, compute a number from its bytes (the *hash*), and use
`hash & (capacity - 1)` as the starting slot. Capacity is always a power of two,
so that `and` is the same as `% capacity`, but one instruction. If the slot holds
a different word, try the next slot (*linear probing*), wrapping at the end.

```c
struct entry { char *key; long count; };   // 16 bytes: index with lsl #4
```

The hash is FNV-1a, which is two instructions per byte:

```c
uint64_t h = 0xcbf29ce484222325;          // the "offset basis"
for (p = s; *p; p++) {
    h ^= (unsigned char)*p;
    h *= 0x100000001b3;                   // the "FNV prime"
}
```

Neither constant fits in a `mov` immediate. Build them with `movz` and `movk`
(lesson 07), 16 bits at a time.

When the table is 70% full, probing gets slow. Allocate a table twice the size,
re-insert every entry (their slots change, because the mask changed), and free
the old array. Finally, copy the entries into a plain array and sort it with
`qsort` and a comparator (lesson 24) that compares counts first and words
second.

### 4. life: two grids

Conway's Game of Life is a grid of cells, each alive or dead. Every generation,
each cell counts its eight neighbours: a live cell with 2 or 3 live neighbours
stays alive, a dead cell with exactly 3 becomes alive, everything else dies.

All cells change *at the same time*, so you cannot update the grid in place:
the cells you already changed would corrupt the counts of their neighbours.
Use two grids. Compute the next generation from `cur` into `next`, then swap
the two pointers (two registers: no copying).

On a torus the right edge wraps round to the left and the bottom to the top.
The neighbour to the left of column 0 is column `width - 1`. You could use `%`,
but `(c - 1 + width) % width` costs a division per neighbour. Comparing and
selecting is cheaper:

```asm
    sub w9, w20, #1         // c - 1
    cmp w20, #0
    csel w9, w22, w9, eq    // if c == 0 use width - 1 (kept in w22)
```

A grid of `rows * cols` bytes, indexed `r * cols + c`, is the 2D array from
lesson 12. Store each cell as the character you print, `'.'` or `'#'`, and each
row prints with a single `fwrite`.

### 5. bf: an interpreter

Brainfuck has a tape of 30000 bytes, a pointer into it, and eight one-character
commands:

| Command | C |
|---------|---|
| `>` | `ptr++;` |
| `<` | `ptr--;` |
| `+` | `tape[ptr]++;` |
| `-` | `tape[ptr]--;` |
| `.` | `putchar(tape[ptr]);` |
| `,` | `tape[ptr] = getchar();` (0 at end of file) |
| `[` | `while (tape[ptr]) {` |
| `]` | `}` |

Every other character is a comment. An interpreter is a loop: fetch the command
at `pc`, do it, `pc++`. Loops are the only hard part. When `[` sees a zero it
must jump to the matching `]`, and searching for it every time is slow. Instead,
match all the brackets once, before running, with a stack of positions (the
stack from lesson 22, or just an array): push the position of each `[`; at each
`]`, pop the matching `[` and record each one's partner in a `jump` array.
Then `[` and `]` are one load each.

Dispatching on the command character is a `switch`: a chain of `cmp`/`b.eq`
works, and a jump table indexed by the character (lesson 24) is the fast way.
Remember that `tape[ptr]++` on a byte wraps from 255 to 0: `strb` stores only
the low 8 bits, so it wraps for free.

## C to assembly

The patterns these projects use, all from earlier lessons:

| C | Assembly |
|---|----------|
| `char line[1024];` (local array) | `sub sp, sp, #N` then index from `sp` |
| `while (fgets(line, n, stdin))` | `bl fgets` / `cbz x0, done` / ... / `b loop` |
| `stdin`, `stdout`, `stderr` | `adrp x0, :got:stdin` / `ldr x0, [x0, :got_lo12:stdin]` / `ldr x0, [x0]` |
| `strtol(tok, &end, 10)` | `add x1, sp, #off` (address of a frame slot) / `bl strtol` / `ldr x9, [sp, #off]` |
| `if (flags & (1 << i))` | `lsr w9, w22, w21` / `tbz w9, #0, skip` |
| `count += (ch == '\n')` | `cmp w11, #'\n'` / `cinc x21, x21, eq` |
| `h = (h ^ c) * PRIME` | `eor x0, x0, x9` / `mul x0, x0, x10` (with `x10` built by `movz`/`movk`) |
| `i = h & (cap - 1)` | `sub x9, cap, #1` / `and x9, x0, x9` |
| `table[i].count` (16-byte struct) | `add x9, table, i, lsl #4` / `ldr x10, [x9, #8]` |
| `qsort(a, n, 16, cmp)` | `adrp x3, cmp` / `add x3, x3, :lo12:cmp` / `bl qsort` |
| `grid[r * cols + c]` | `madd w9, w19, w21, w20` / `ldrb w10, [x23, w9, uxtw]` |
| `c == 0 ? width - 1 : c - 1` | `sub` / `cmp` / `csel` |
| `swap(cur, next)` (pointers) | `mov x9, x23` / `mov x23, x24` / `mov x24, x9` |
| `tape[ptr]++` (unsigned char) | `ldrb w9, [x20, x21]` / `add w9, w9, #1` / `strb w9, [x20, x21]` |
| `switch (cmd)` | `cmp`/`b.eq` chain, or a jump table and `br` |
| `fprintf(stderr, "x: %s: %s\n", name, strerror(errno))` | `bl __errno_location` / `ldr w0, [x0]` / `bl strerror` / `bl fprintf` |
| `return 2;` from `main` | `mov w0, #2` / epilogue / `ret` |

## Common mistakes

- **A value lost across a call.** You kept the `FILE *` or a loop counter in
  `x9`, called `printf`, and now it is garbage. Anything you need after a `bl`
  lives in `x19`-`x28` (or in the frame). The register plan comment catches this
  before you run.
- **A callee-saved register used but not saved.** Your function works, but
  `main` crashes after it returns, because you overwrote `x22` that `main` was
  using. Every `x19`-`x28` you write must be saved in the prologue and restored
  in the epilogue, on *every* return path.
- **`sp` misaligned.** A frame of 1048 bytes, or an odd number of 8-byte
  pushes, and `printf` crashes deep inside libc. Every frame size is a multiple
  of 16.
- **Early returns that skip the epilogue.** An error path `ret`s straight out
  of the middle of the function, leaving the frame on the stack. Branch to one
  shared exit label instead.
- **`w` vs `x` in index arithmetic.** `ldr x0, [x20, w21, sxtw #3]` is right for
  an `int` index; `[x20, x21, lsl #3]` with garbage in the top half of `x21`
  reads somewhere random. Writing `w21` clears the top half; loading with
  `ldrsw` sign-extends.
- **Signed vs unsigned bytes.** Brainfuck cells and hash bytes are `unsigned
  char`: use `ldrb`, not `ldrsb`. A `getchar()` result is an `int` that may be
  `-1` (EOF): compare it with `cmn w0, #1` before you store it as a byte.
- **Off by one at the end of a buffer.** `malloc(size)` with no room for the
  NUL, or a loop that checks `<=` instead of `<`. These often work by luck and
  fail on the next input.
- **A word split across two `fread` chunks** counted twice, because the
  `inword` state was reset for every chunk. Test with an input bigger than the
  buffer (the `stdin-big` test does).
- **Updating a Life grid in place.** The glider falls apart after one
  generation. Use two grids.
- **Forgetting that output is buffered.** If your program crashes, output it had
  already "printed" with `printf` may never appear, because it was still in the
  buffer (lesson 25). Do not trust the last line you see; use `gdb`.

## Recap

- Write the program in C first, test it, and keep it as the comment block.
- Split it into one-screen functions, each with a contract comment.
- Decide where each piece of data lives: register, callee-saved register,
  stack frame, `.bss`, or heap.
- Write a register plan per function; anything live across a call goes in
  `x19`-`x28`, and the prologue saves exactly those.
- Build in milestones and run the tests after each one.
- Use `gdb`, `bt` and `info registers` the moment something crashes.
- Every project here is ordinary C: if you can write it in C, you can now write
  it in assembly.

## Where to go next

You have reached the goal of this course: you can take a C program and write
it, by hand, in AArch64 assembly, and you know why every instruction is there.
Some directions from here:

- **Keep reading compiler output.** Paste small functions into Compiler
  Explorer (godbolt.org) or run `gcc -O2 -S`, and ask yourself why each
  instruction is there. It is the fastest way to learn the tricks and idioms
  that lesson 27 only started.
- **Read the real specifications.** The *Arm Architecture Reference Manual for
  A-profile* (the "Arm ARM") defines every instruction exactly. The *Procedure
  Call Standard for the Arm 64-bit Architecture* (AAPCS64), on Arm's GitHub
  (`ARM-software/abi-aa`), is the calling convention you have been using, with
  every corner case. Apple's "Writing ARM64 code for Apple platforms" lists the
  macOS differences.
- **SIMD with NEON.** The `v` registers can hold 16 bytes, 8 halfwords, 4 floats
  and work on all of them at once. Search through a string 16 bytes at a time, or
  add four floats per instruction. Arm's "Neon Programmer's Guide" is a good start;
  then read what `gcc -O3` makes of a simple loop.
- **Bare metal and operating systems.** Write a program that runs with no
  operating system at all, under `qemu-system-aarch64` with the `virt` machine:
  set up a stack, print to the UART, take an exception. You will meet exception
  levels, system registers (`mrs`/`msr`) and the MMU, everything this course
  left out.
- **Write a compiler.** A small compiler for a C-like language that emits
  AArch64 assembly is the best possible test of everything you have learned:
  you have to produce, automatically, exactly the code you have been writing by
  hand. Nora Sandler's *Writing a C Compiler* and Rui Ueyama's `chibicc` are good
  guides.
- **Another instruction set.** RISC-V (`rv64`) will feel very familiar: it is
  also a load/store architecture with many registers. x86-64 is the opposite: few
  registers, memory operands everywhere, variable-length instructions. Seeing
  both makes it clearer which parts of AArch64 are design choices and which are
  universal.
- **Performance.** Learn to measure with `perf` on Linux (or Instruments on
  macOS), and read about pipelines, caches and branch prediction. Arm publishes
  "Software Optimization Guides" for its cores.

## Homework

[exercises.md](exercises.md): the five projects.
