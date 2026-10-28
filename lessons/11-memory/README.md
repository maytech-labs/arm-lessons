# Lesson 11: Memory

So far almost everything you have done happened inside registers. Registers are
fast, but there are only 31 of them, and each holds 8 bytes. Real programs keep
their data in *memory*: variables, arrays, input that arrives from the keyboard,
text waiting to be printed. This lesson teaches every way AArch64 moves data
between registers and memory.

At the end you will do something you could not do before: **print a number** as
decimal text, and **read a number** that the user types.

## Goals

After this lesson you can:

- Load and store 1, 2, 4 and 8 bytes with `ldrb`, `ldrh`, `ldr w`, `ldr x`,
  `strb`, `strh`, `str w` and `str x`.
- Choose between zero-extending loads and sign-extending loads (`ldrsb`,
  `ldrsh`, `ldrsw`).
- Use every addressing mode: base, base plus offset, register offset with a
  shift, pre-index (`!`) and post-index.
- Move two registers at once with `ldp` and `stp`.
- Lay out data with `.byte`, `.hword`, `.word`, `.quad`, and reserve zeroed
  space with `.bss` and `.space`.
- Explain alignment and why it matters.
- See little-endian byte order with your own eyes in the debugger.
- Read input with the `read` system call.
- Convert a number to decimal text and print it, and convert typed digits back
  into a number.

## Before you start

You need lessons 03 to 10. In particular:

- Memory is a long row of bytes, each with an address (lesson 03).
- `.data`, labels, and loading an address with `adrp` + `add :lo12:` (lesson 05).
- Examining memory with `x` in gdb (lesson 06).
- `udiv` and `msub` for remainders (lesson 07).
- `cmp`, `b.cond`, `cbz`/`cbnz`, loops (lessons 09 and 10).

All the programs are in [examples/](examples/). Build them all with `make` in
that directory.

## 1. Loading and storing: `ldr` and `str`

Here is a tiny C program with one global variable:

```c
long counter = 41;

int main(void) {
    counter = counter + 1;
    return counter;
}
```

The variable `counter` lives in memory. The CPU cannot add 1 to memory directly:
on AArch64, arithmetic only works on registers. So the work always has three
steps:

1. **Load**: copy the value from memory into a register.
2. Compute in the register.
3. **Store**: copy the register back into memory.

The two instructions are:

| Instruction | Meaning | C |
|-------------|---------|---|
| `ldr x2, [x1]` | load 8 bytes from the address in `x1` into `x2` | `x2 = *x1;` |
| `str x2, [x1]` | store the 8 bytes of `x2` at the address in `x1` | `*x1 = x2;` |

The square brackets mean "the memory at this address". `x1` holds an *address*;
`[x1]` is the *thing stored there*. This is exactly the difference between a
pointer `p` and `*p` in C.

Note the direction: `ldr` copies right to left (memory into register), but `str`
copies left to right (register into memory). The register is always written
first, the memory address second.

Open [examples/counter.s](examples/counter.s):

```asm
    .data
    .p2align 3
counter:
    .quad 41                    // 8 bytes holding the number 41

    .text
    .p2align 2
_start:
    adrp x1, counter            // x1 = page of counter
    add x1, x1, :lo12:counter   // x1 = address of counter
    ldr x2, [x1]                // x2 = the 8 bytes at address x1  (x2 = 41)
    add x2, x2, #1              // x2 = 42 (only the register changed)
    str x2, [x1]                // store x2 back into memory at x1
    mov x2, #0                  // wipe x2, to prove the next load is real
    ldr x0, [x1]                // x0 = counter, read fresh from memory
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(counter)
```

(`.p2align 3` puts `counter` on an address that is a multiple of 8. Section 9
explains why. For now, just copy it.)

**Predict:** what exit status do you get? What would it be if you deleted the
`str` line?

```console
$ make
$ ./counter; echo $?
42
```

Without the `str`, the 42 only ever existed in `x2`. Memory still held 41, and
the second `ldr` would read 41. Changing a register never changes memory by
itself.

## 2. Loading different sizes

C has variables of different sizes: `char` is 1 byte, `short` is 2, `int` is 4,
`long` is 8. AArch64 has a load for each size:

| Instruction | Bytes read | Into | C type it suits |
|-------------|-----------|------|-----------------|
| `ldrb w1, [x0]` | 1 | `w1`, upper bits zeroed | `unsigned char` |
| `ldrh w1, [x0]` | 2 | `w1`, upper bits zeroed | `unsigned short` |
| `ldr w1, [x0]` | 4 | `w1`, upper bits zeroed | `unsigned int` |
| `ldr x1, [x0]` | 8 | `x1` | `long`, pointers |

The size is chosen by the mnemonic (`b` for byte, `h` for halfword) and, for 4
vs 8 bytes, by whether you name a `w` or an `x` register. The smaller loads fill
the rest of the register with zeros. This is called **zero-extension**. Because
writing any `w` register also zeroes the upper half of the `x` register (lesson
03), after `ldrb w1, [x0]` the whole 64-bit `x1` holds a number from 0 to 255.

[examples/sizes.s](examples/sizes.s) loads the same address four ways:

```asm
value:
    .quad 0x1122334455667788    // 8 bytes; in memory: 88 77 66 55 44 33 22 11
    ...
    ldrb w1, [x0]               // 1 byte:  x1 = 0x88
    ldrh w2, [x0]               // 2 bytes: x2 = 0x7788
    ldr w3, [x0]                // 4 bytes: x3 = 0x55667788
    ldr x4, [x0]                // 8 bytes: x4 = 0x1122334455667788
```

**Predict** before running: why is the 1-byte load `0x88` and not `0x11`? (The
comment on `.quad` gives it away. Section 6 explains it properly.)

```console
$ ./sizes; echo $?
136
```

136 is `0x88`. Now look at all four registers in the debugger:

```console
$ gdb ./sizes
(gdb) break 25
(gdb) run
(gdb) info registers x1 x2 x3 x4
x1             0x88                136
x2             0x7788              30600
x3             0x55667788          1432778632
x4             0x1122334455667788  1234605616436508552
```

(Line 25 is the `mov x0, x1` line; use `list` to find it if you changed the
file.)

## 3. Storing different sizes

Stores come in the same sizes. A store writes *only* its own number of bytes and
leaves the neighbours alone:

| Instruction | Bytes written | Which bytes of the register |
|-------------|---------------|-----------------------------|
| `strb w1, [x0]` | 1 | the lowest byte of `w1` |
| `strh w1, [x0]` | 2 | the lowest 2 bytes |
| `str w1, [x0]` | 4 | all of `w1` |
| `str x1, [x0]` | 8 | all of `x1` |

There is no `strsb`: storing just copies low bytes, so signed and unsigned are
the same thing.

[examples/stores.s](examples/stores.s) fills an 8-byte variable and then
overwrites parts of it. The comments show the eight bytes after each store,
lowest address first:

```asm
    str x1, [x0]                // 8 bytes: 44 33 22 11 dd cc bb aa
    mov w2, #0xeeff
    strh w2, [x0]               // 2 bytes: ff ee 22 11 dd cc bb aa
    mov w2, #0x99
    strb w2, [x0]               // 1 byte:  99 ee 22 11 dd cc bb aa
    mov w2, #0
    str w2, [x0]                // 4 bytes: 00 00 00 00 dd cc bb aa
    ldrb w0, [x0, #4]           // load the byte at target+4 (0xdd)
```

(`[x0, #4]` means "the address `x0 + 4`". Section 7 covers it.)

**Predict** the exit status, then check it. Then step through it in gdb and run
`x/8xb &target` after every store to watch the bytes change:

```console
$ ./stores; echo $?
221
$ gdb ./stores
(gdb) break _start
(gdb) run
(gdb) stepi 7
(gdb) x/8xb &target
0x410150:	0x44	0x33	0x22	0x11	0xdd	0xcc	0xbb	0xaa
```

(Your addresses may differ.) Keep doing `stepi 2` and `x/8xb &target`.

## 4. Laying out data: `.byte`, `.hword`, `.word`, `.quad`

You already met `.byte` and `.quad` in lesson 06. There is one directive per size:

| Directive | Bytes per value | C type |
|-----------|-----------------|--------|
| `.byte 10` | 1 | `char`, `unsigned char` |
| `.hword 20` | 2 | `short` |
| `.word 30` | 4 | `int` |
| `.quad 40` | 8 | `long`, pointers |

Each can take a list: `.word 1, 2, 3` lays down three 4-byte values, 12 bytes in
all. Negative numbers work too: `.byte -5` stores the two's complement bit
pattern `0xfb`.

A label in front of a directive is the address of its first byte. So these four
lines are the assembly version of four C globals:

```asm
q:  .quad 40                    // 8 bytes  (C: long  q = 40;)
w:  .word 30                    // 4 bytes  (C: int   w = 30;)
h:  .hword 20                   // 2 bytes  (C: short h = 20;)
b:  .byte 10                    // 1 byte   (C: char  b = 10;)
```

(A label can sit on the same line as the directive. That is just a shorter way
of writing it.)

The important thing to understand: **memory does not remember sizes.** The
assembler just lays down 8 + 4 + 2 + 1 = 15 bytes in a row. Nothing in memory
says "this is an `int`". It is your job to use the load that matches the
directive: `ldr x` for `.quad`, `ldr w` for `.word`, `ldrh` for `.hword`, `ldrb`
for `.byte`. In C the compiler remembers the type for you; in assembly, you do.

[examples/directives.s](examples/directives.s) loads each one with the right
instruction and adds them up.

```console
$ ./directives; echo $?
100
```

**Try it:** change `ldrh w2, [x9]` to `ldr x2, [x9]` and predict what happens.
The 8-byte load reads `h`, then `b`, then whatever comes after: garbage. Your
exit status will be wrong, and nothing warns you.

## 5. Sign-extending loads: `ldrsb`, `ldrsh`, `ldrsw`

Suppose memory holds the byte `0xfb`. What number is it?

- As an `unsigned char`, `0xfb` is 251.
- As a `signed char`, `0xfb` is -5 (lesson 02).

The byte is the same; only the meaning differs. When you load it into a 64-bit
register you must choose:

- `ldrb w2, [x0]` **zero-extends**: `x2 = 0x00000000000000fb` = 251.
- `ldrsb x1, [x0]` **sign-extends**: it copies the top bit of the byte into all
  the upper bits, so `x1 = 0xfffffffffffffffb` = -5.

The full set:

| Instruction | Reads | Extends | C type |
|-------------|-------|---------|--------|
| `ldrsb x1, [x0]` | 1 byte | sign | `signed char` into a `long` |
| `ldrsh x1, [x0]` | 2 bytes | sign | `short` into a `long` |
| `ldrsw x1, [x0]` | 4 bytes | sign | `int` into a `long` |
| `ldrsb w1, [x0]` | 1 byte | sign, to 32 bits only | `signed char` into an `int` |
| `ldrsh w1, [x0]` | 2 bytes | sign, to 32 bits only | `short` into an `int` |

The rule for C: **if the type is signed, use a signed load; if it is unsigned,
use the plain load.** Then the 64-bit register holds the correct value and
`cmp` / `b.lt` / `sdiv` work as you expect.

[examples/signext.s](examples/signext.s):

```asm
small:
    .byte -5                    // stored as the bit pattern 0xfb
    ...
    ldrsb x1, [x0]              // x1 = 0xfffffffffffffffb = -5  (signed load)
    ldrb w2, [x0]               // x2 = 0x00000000000000fb = 251 (unsigned load)

    cmp x1, #0                  // is the signed load negative?
    b.lt negative
```

```console
$ ./signext; echo $?
1
```

Now change `ldrsb x1` to `ldrb w1`, rebuild, and **predict**. It exits 2: the
program now thinks the byte is 251, a positive number. This is a classic bug in
both C and assembly: a negative `char` read as unsigned.

You can also see both registers in gdb with `break done`, `run`,
`info registers x1 x2`.

## 6. Byte order: little-endian, in the debugger

A 4-byte number like `0x11223344` takes four addresses. Which byte goes first?
AArch64 (on Linux and macOS) is **little-endian**: the *least* significant byte
(the "little end", `0x44`) is stored at the lowest address.

```
.word 0x11223344

address:   n     n+1   n+2   n+3
byte:      44    33    22    11
```

You met this in lesson 02. Now prove it. [examples/endian.s](examples/endian.s)
loads the single byte at the lowest address:

```asm
number:
    .word 0x11223344
    ...
    ldrb w1, [x0]               // the byte at the lowest address
```

**Predict** the exit status: 0x11 (17) or 0x44 (68)?

```console
$ ./endian; echo $?
68
```

And in the debugger, `x` with the `b` (byte) size shows memory in address
order, while the `w` (word, 4 bytes) size puts the bytes back together into a
number:

```console
$ gdb ./endian
(gdb) break _start
(gdb) run
(gdb) x/4xb &number
0x410128:	0x44	0x33	0x22	0x11
(gdb) x/1xw &number
0x410128:	0x11223344
```

Same four bytes, two views. When you look at memory byte by byte, multi-byte
numbers appear "backwards". When you load them with the right size, the CPU puts
them back in the right order for you. That is why `sizes.s` got `0x88` from its
1-byte load: `0x88` is the lowest byte of `0x1122334455667788`, so it sits at
the lowest address.

## 7. Addressing modes

So far you wrote `[x0]`. The part inside the brackets is the **addressing
mode**: the recipe for computing the address. AArch64 has five you will use all
the time.

| Mode | Syntax | Address used | Does the base register change? |
|------|--------|--------------|-------------------------------|
| Base | `[x0]` | `x0` | no |
| Base + offset | `[x0, #8]` | `x0 + 8` | no |
| Register offset | `[x0, x9, lsl #3]` | `x0 + (x9 << 3)` | no |
| Pre-index | `[x0, #8]!` | `x0 + 8` | yes: `x0 = x0 + 8`, *before* the access |
| Post-index | `[x0], #8` | `x0` | yes: `x0 = x0 + 8`, *after* the access |

In C terms, if `long *p` is in `x0` and `long i` is in `x9`:

| C | Assembly |
|---|----------|
| `x1 = *p;` | `ldr x1, [x0]` |
| `x1 = p[1];` | `ldr x1, [x0, #8]` |
| `x1 = p[i];` | `ldr x1, [x0, x9, lsl #3]` |
| `x1 = *++p;` | `ldr x1, [x0, #8]!` |
| `x1 = *p++;` | `ldr x1, [x0], #8` |

Notice that the offsets are in **bytes**, not elements. `p[1]` for a `long` is 8
bytes along, so the offset is `#8`. In C, `p + 1` adds 8 for you because the
compiler knows `p` points to `long`. In assembly you do the multiplying. The
register-offset mode does it with a shift: `lsl #3` multiplies the index by 8.
The shift must be either 0 or the log2 of the access size: `lsl #3` for 8-byte
loads, `lsl #2` for 4-byte, `lsl #1` for 2-byte, and none (or `lsl #0`) for
bytes. Lesson 12 uses this a lot.

[examples/modes.s](examples/modes.s) reads all five elements of an array, each
with a different mode:

```asm
a:  .quad 10, 20, 30, 40, 50    // 5 x 8 bytes = 40 bytes
    ...
    ldr x1, [x0]                // base:            a[0], address x0
    ldr x2, [x0, #8]            // base + offset:   a[1], address x0 + 8
    mov x9, #2
    ldr x3, [x0, x9, lsl #3]    // register offset: a[2], address x0 + (2 << 3)

    add x10, x0, #16            // x10 = address of a[2]
    ldr x4, [x10, #8]!          // pre-index:  x10 += 8 first, then load a[3]
    add x10, x10, #8            // x10 = address of a[4]
    ldr x5, [x10], #8           // post-index: load a[4] from x10, then x10 += 8
```

**Predict:** what is in `x10` at the very end, relative to the address of `a`?
(Answer: `a + 40`, one past the end of the array.) Check in gdb: `break 36` (the first
`add` after the loads), `run`, then `print $x10 - $x0`.

```console
$ ./modes; echo $?
150
```

A few rules worth knowing:

- Every mode works with every size of load and store (`ldrb w1, [x0], #1` is
  fine), and with `ldp`/`stp` (except register offset).
- The offset can be negative: `[x0, #-8]` is the 8 bytes *before* `x0`.
- The `!` is part of the syntax. Forget it and `[x0, #8]` silently becomes the
  plain offset mode: the load works but `x0` does not move.
- Offsets have limited ranges. A plain positive offset that is a multiple of the
  size can be large (up to 32760 for `ldr x`); pre- and post-index offsets must
  be between -256 and 255. You will almost never hit these limits.

### Walking through memory with post-index

Post-index is perfect for loops: load an element and step to the next one in a
single instruction. Here is a loop that adds up eight bytes:

```c
unsigned char data[8] = {1, 2, 3, 4, 5, 6, 7, 8};
unsigned char *p = data;
int sum = 0;
for (int n = 8; n != 0; n--)
    sum += *p++;
```

[examples/bytesum.s](examples/bytesum.s):

```asm
    adrp x1, data
    add x1, x1, :lo12:data      // x1 = p = address of data[0]
    mov x2, #8                  // x2 = n, bytes left
    mov x0, #0                  // x0 = sum
loop:
    ldrb w3, [x1], #1           // w3 = *p; then p = p + 1
    add x0, x0, x3              // sum += that byte
    sub x2, x2, #1              // n--
    cbnz x2, loop               // keep going while n != 0
```

`*p++` really is one instruction. For bytes the step is `#1`; for `long`s it
would be `#8`.

```console
$ ./bytesum; echo $?
36
```

## 8. Two at once: `ldp` and `stp`

`ldp` ("load pair") loads two registers from two neighbouring memory slots, and
`stp` ("store pair") stores two:

```asm
    ldp x2, x3, [x0]            // x2 = 8 bytes at x0, x3 = 8 bytes at x0 + 8
    stp x2, x3, [x1]            // 8 bytes at x1 = x2, 8 bytes at x1 + 8 = x3
```

With `w` registers they move two 4-byte values (`x0` and `x0 + 4`). They accept
base, offset, pre-index and post-index modes. The offset must be a multiple of
the register size, between -512 and 504 for `x` registers.

[examples/pairs.s](examples/pairs.s) copies a 16-byte record from `src` to `dst`
and reads it back:

```c
long src[2] = {7, 6};
long dst[2];
dst[0] = src[0]; dst[1] = src[1];
return dst[0] * dst[1];
```

```console
$ ./pairs; echo $?
42
```

`stp` and `ldp` will be your best friends in lesson 13, where they push and pop
registers on the stack.

## 9. Zero-filled memory: `.bss` and `.space`

Sometimes you need memory with no particular starting value: a buffer for input,
a place to build some text. In C you would write a global with no initialiser:

```c
char buf[27];      /* global: starts as all zeros */
```

You could write `.data` and 27 zeros, but there is a better section for this:
`.bss`. Everything in `.bss` is set to zero when the program starts, and it
takes **no space in the executable file**: the file just records "I need 27
zeroed bytes", and the operating system provides them. A 1 MiB buffer in `.bss`
adds almost nothing to your program's size; in `.data` it would add a megabyte.

`.space N` reserves N bytes (zero bytes).

```asm
    .bss                        // zero-filled at startup, takes no file space
buf:
    .space 27                   // reserve 27 bytes
```

You can only reserve space in `.bss`; you cannot put real values there (no
`.quad 5`). That is what `.data` is for. `.space` also works in `.data`, where
it does put real zero bytes into the file.

[examples/bss.s](examples/bss.s) fills `buf` with the alphabet using
`strb w3, [x2], #1` (that is `*p++ = c`), adds a newline, and writes it:

```console
$ ./bss
ABCDEFGHIJKLMNOPQRSTUVWXYZ
```

## 10. Alignment

An address is **aligned** to N if it is a multiple of N. A value of size N is
*naturally aligned* when its address is a multiple of N: a `.word` at an address
divisible by 4, a `.quad` at an address divisible by 8.

Why care?

- **Speed.** Memory is fetched in aligned chunks. A misaligned 8-byte load can
  straddle two chunks (or even two pages) and cost more.
- **Some things require it.** The stack pointer must be 16-byte aligned or the
  CPU faults (lesson 13). The atomic instructions in lesson 28 fault on
  misaligned addresses. Instructions themselves must be 4-byte aligned, which
  is why every `.text` starts with `.p2align 2`.
- **C expects it.** Every C compiler places `int`s on multiples of 4 and `long`s
  on multiples of 8. When your assembly shares data with C (lesson 16 on), you
  must match. Lesson 19 builds on this for struct padding.

Ordinary loads and stores on Linux and macOS *do* work on misaligned addresses;
they are just slower, and the habit will bite you later. So: **align everything
to its size.**

The assembler places data exactly where you put it, one item after another, so
if a 1-byte `.byte` is followed by a `.quad`, the `.quad` lands on an odd
address. `.p2align k` fixes that: it skips forward (filling with zero bytes) to
the next address that is a multiple of 2^k.

| Directive | Next address is a multiple of | Use before |
|-----------|------------------------------|------------|
| `.p2align 1` | 2 | `.hword` |
| `.p2align 2` | 4 | `.word`, code |
| `.p2align 3` | 8 | `.quad` |
| `.p2align 4` | 16 | anything you want 16-byte aligned |

[examples/align.s](examples/align.s) puts two bytes and then an aligned
`.quad`. `nm -n` lists symbols sorted by address:

```console
$ nm -n align | grep -E 'one|after|aligned'
0000000000410118 d one
0000000000410119 d after
0000000000410120 d aligned
```

`after` is one byte after `one`. Without `.p2align 3`, `aligned` would be at
`...11a`. With it, the assembler skipped six bytes to `...120`, a multiple of 8.

That is why `directives.s` ordered its variables from biggest to smallest: each
one then stays aligned without any padding.

## 11. Reading input: the `read` system call

You already know `write(fd, buf, n)`. Its mirror image is `read`:

```c
long read(int fd, void *buf, unsigned long n);
```

| Register | Meaning |
|----------|---------|
| `x8` | 63 (the `read` system call number) |
| `x0` | file descriptor: 0 is standard input |
| `x1` | address of a buffer to fill |
| `x2` | the most bytes you are willing to accept |
| result in `x0` | how many bytes actually arrived; 0 means end of input |

Three things surprise people:

1. `read` returns **as soon as some input is available**. From a terminal, that
   is one line, when you press Enter, *including* the newline character. So if
   you type `hello` and Enter, you get 6 bytes: `h e l l o \n`.
2. It does **not** add a zero byte at the end. You get exactly the count in
   `x0`, and the rest of the buffer is untouched.
3. If the input is longer than `x2`, you only get the first `x2` bytes. The rest
   waits for your next `read`.

[examples/echo.s](examples/echo.s) reads into a 64-byte buffer in `.bss` and
writes back exactly as many bytes as it got:

```asm
    mov x0, #0                  // fd 0 = stdin
    adrp x1, buf
    add x1, x1, :lo12:buf       // where to put the bytes
    mov x2, #64                 // at most 64 of them
    mov x8, #63                 // 63 = read
    svc #0                      // x0 = number of bytes actually read

    mov x19, x0                 // keep the count safe in x19
    mov x2, x0                  // write exactly as many bytes as we read
    mov x0, #1                  // fd 1 = stdout
    adrp x1, buf                // load the buffer address again: do not
    add x1, x1, :lo12:buf       // count on x1 surviving a system call
    mov x8, #64                 // 64 = write
    svc #0
```

You can feed it input from a pipe, or type it yourself:

```console
$ echo hello | ./echo
hello
$ echo $?
6
$ ./echo
testing 1 2 3
testing 1 2 3
```

**Predict:** what is the exit status for `echo hi | ./echo`? (3: `h`, `i`, and
the newline.)

On Linux, a system call changes only `x0`, so reloading `x1` is not strictly
needed here. But macOS changes `x1` as well, so code that relies on `x1`
surviving breaks there. The safe habit, which every program in this course
follows: **after a system call, treat `x0` and `x1` as changed, and reload any
address you still need.** The macOS companion shows the bug this prevents.

## 12. Printing a number

Until now the only way to see a number was the exit status, which only goes up
to 255. Now you have everything you need to print any number as text.

The idea: the last digit of `n` is `n % 10`, and `n / 10` removes it. For 1234:

| n | n % 10 | n / 10 |
|---|--------|--------|
| 1234 | 4 | 123 |
| 123 | 3 | 12 |
| 12 | 2 | 1 |
| 1 | 1 | 0 (stop) |

The digits come out **backwards**: 4, 3, 2, 1. The easy fix is to fill the
buffer from the end towards the start. Each digit `d` becomes the character
`'0' + d` (the ASCII codes for `'0'` to `'9'` are 48 to 57, in order).

In C:

```c
char buf[32];
unsigned long n = 1234567;
char *p = buf + 32;               /* one past the end */
*--p = '\n';
do {
    *--p = '0' + n % 10;          /* last digit first */
    n = n / 10;
} while (n != 0);
write(1, p, (buf + 32) - p);
```

`*--p = c` means "move `p` back one byte, then store `c` there". That is
exactly a **pre-index** store with a negative offset: `strb w6, [x1, #-1]!`.

It is a `do ... while` rather than a `while` so that the number 0 still prints
one digit, `0`.

[examples/printnum.s](examples/printnum.s):

```asm
    // ---- print x19 in decimal, followed by a newline ----
    adrp x1, numbuf
    add x1, x1, :lo12:numbuf
    add x5, x1, #32             // x5 = end of buffer (one past the last byte)
    mov x1, x5                  // x1 = p, moves backwards
    mov w2, #10                 // '\n'
    strb w2, [x1, #-1]!         // *--p = '\n'
    mov x2, x19                 // x2 = n, the number being printed
    mov x3, #10                 // the divisor
digit:
    udiv x4, x2, x3             // x4 = n / 10
    msub x6, x4, x3, x2         // x6 = n - (n / 10) * 10 = n % 10
    add w6, w6, #'0'            // 0..9 -> '0'..'9'
    strb w6, [x1, #-1]!         // *--p = digit
    mov x2, x4                  // n = n / 10
    cbnz x2, digit              // do ... while (n != 0)
    mov x0, #1                  // fd 1 = stdout
                                // x1 = p, the first digit
    sub x2, x5, x1              // length = end - p
    mov x8, #64                 // 64 = write
    svc #0
    // ---- end of print ----
```

New detail: `#'0'` is a character constant. The assembler replaces it with 48,
just like `'0'` in C.

The length is the distance between two addresses: `end - p`. Subtracting
pointers to get a count is something you will do constantly.

```console
$ ./printnum
1234567
```

**Try it:** put 0 in `x19` (`mov x19, #0`) and check it prints `0`. Then try the
largest 64-bit number, `mov x19, #-1`, which prints `18446744073709551615` (20
digits; that is why the buffer is 32 bytes).

This block is 18 lines long, and you will paste it into every program that
prints a number until lesson 14, where it becomes a function you can *call*.
The surrounding `// ----` comments make it easy to find and copy.

## 13. Reading a number

The reverse: turn the characters `'4' '2' '\n'` into the number 42. Read the
digits left to right, and for each one, multiply what you have so far by 10 and
add the new digit:

| char | digit | n = n * 10 + digit |
|------|-------|--------------------|
| `'4'` | 4 | 0 * 10 + 4 = 4 |
| `'2'` | 2 | 4 * 10 + 2 = 42 |
| `'\n'` | not a digit | stop |

`n * 10 + d` is one `madd` instruction (lesson 07).

To test "is this a digit?", you could write two comparisons (`c >= '0'` and
`c <= '9'`). Here is a neater trick: subtract `'0'` first, then do **one
unsigned** comparison against 9. If `c` was `'0'`..`'9'`, the result is 0..9.
If `c` was smaller than `'0'` (a newline is 10, a space is 32), the subtraction
wraps around to a huge unsigned number, which is also "greater than 9". So
`b.hi` (unsigned higher) catches both cases at once.

[examples/double.s](examples/double.s) reads a number, doubles it, and prints
it:

```asm
    // ---- parse decimal digits: x19 = value ----
    mov x19, #0                 // n = 0
    mov x3, #10
parse:
    cbz x0, parsed              // no bytes left
    ldrb w2, [x1], #1           // w2 = *p++
    sub w2, w2, #'0'            // '0'..'9' -> 0..9; anything else -> other
    cmp w2, #9
    b.hi parsed                 // unsigned > 9: not a digit (newline, etc.)
    madd x19, x19, x3, x2       // n = n * 10 + d
    sub x0, x0, #1              // len--
    b parse
parsed:
```

The loop stops at the first non-digit, or when it has used up all the bytes
`read` returned (`x0` counts them down). Because `madd` uses `x2` while the
digit was computed in `w2`, it matters that writing `w2` zeroed the upper half of
`x2`.

```console
$ echo 21 | ./double
42
$ echo 1000000 | ./double
2000000
$ ./double
123
246
```

This parser does not handle a minus sign, and it does not notice if the number
is too big for 64 bits. Exercise 11.9 deals with signs. Lesson 17 does the full
job.

## C to assembly

| C | Assembly |
|---|----------|
| `long g = 5;` (global) | `.data` / `.p2align 3` / `g: .quad 5` |
| `int g = 5;` | `.p2align 2` / `g: .word 5` |
| `short g = 5;` | `.p2align 1` / `g: .hword 5` |
| `char g = 5;` | `g: .byte 5` |
| `char buf[64];` (global, no initialiser) | `.bss` / `buf: .space 64` |
| `x = *p;` with `long *p` | `ldr x1, [x0]` |
| `x = *p;` with `int *p` / `unsigned *p` | `ldrsw x1, [x0]` / `ldr w1, [x0]` |
| `x = *p;` with `short *p` / `unsigned short *p` | `ldrsh x1, [x0]` / `ldrh w1, [x0]` |
| `x = *p;` with `signed char *p` / `unsigned char *p` | `ldrsb x1, [x0]` / `ldrb w1, [x0]` |
| `*p = x;` (8, 4, 2, 1 bytes) | `str x1` / `str w1` / `strh w1` / `strb w1`, `[x0]` |
| `p[3]` with `long *p` | `[x0, #24]` |
| `p[i]` with `long *p` | `[x0, x9, lsl #3]` |
| `*p++` | `[x0], #size` |
| `*++p` / `*--p` | `[x0, #size]!` / `[x0, #-size]!` |
| `a = p[0]; b = p[1];` | `ldp x1, x2, [x0]` |
| `read(0, buf, n)` | `x0=0`, `x1=buf`, `x2=n`, `x8=63`, `svc #0` |
| `end - p` (pointer difference in bytes) | `sub x2, x5, x1` |

## Common mistakes

- **Mixing up `ldr` and `str` direction.** `str x2, [x1]` writes `x2` *into
  memory*. If you meant to load, the variable silently gets overwritten.
- **Wrong size.** Loading a `.word` with `ldr x` reads 4 extra bytes of whatever
  follows. Storing with `str x` into a `.byte` variable wipes out 7 neighbours.
  No error, just wrong data. Always match the load/store to the directive.
- **Unsigned load of signed data** (or the reverse). `-1` stored as a byte comes
  back as 255 with `ldrb`. Comparisons with `b.lt` then go the wrong way.
- **Forgetting that offsets are in bytes.** `[x0, #1]` on an array of `long`s is
  *not* element 1; it is a misaligned read starting in the middle of element 0.
  Element 1 is `[x0, #8]`.
- **Wrong shift in register offset.** `ldr x1, [x0, x9, lsl #2]` is an
  assembler error (the shift for 8-byte loads must be 3 or 0). `ldr w1, [x0,
  x9]` is legal but uses the index as a byte count, not an element count.
- **Forgetting the `!`.** `[x0, #-1]` instead of `[x0, #-1]!` stores every digit
  in the same byte, and the length comes out 0.
- **Storing into `.text`.** Code is read-only. A store to an address in `.text`
  (or to a string in a read-only section) kills the program with
  `Segmentation fault`.
- **Using an address that is not an address.** `ldr x0, [x1]` where `x1` holds a
  number like 42 instead of a pointer is a segmentation fault. In gdb, `info
  registers x1` usually shows the problem at once.
- **Assuming `read` added a terminator, or read the whole input.** Use the count
  in `x0`.
- **Relying on `x1` after a system call.** Reload any address you still need.

## Recap

- Arithmetic happens in registers; memory is reached only by loads and stores.
- `ldrb`/`ldrh`/`ldr w`/`ldr x` read 1/2/4/8 bytes and zero-extend;
  `ldrsb`/`ldrsh`/`ldrsw` sign-extend. Pick by the C type.
- `strb`/`strh`/`str w`/`str x` write exactly 1/2/4/8 bytes.
- `.byte`/`.hword`/`.word`/`.quad` lay down 1/2/4/8-byte values; memory itself
  has no types.
- Addressing modes: `[x0]`, `[x0, #off]`, `[x0, x9, lsl #s]`, `[x0, #off]!`
  (pre-index), `[x0], #off` (post-index). Offsets are in bytes.
- `ldp`/`stp` move two registers to or from neighbouring slots.
- `.bss` + `.space` reserves zeroed memory that costs no file space.
- Align every value to its size with `.p2align`.
- AArch64 is little-endian: the lowest byte of a number is at the lowest
  address.
- `read` (63) returns how many bytes arrived, 0 at end of input, no terminator.
- To print a number: divide by 10 repeatedly, store `'0' + remainder` backwards
  with `strb w, [x1, #-1]!`, write from there to the end. To parse: `n = n * 10
  + (c - '0')` until a non-digit.

## Homework

[exercises.md](exercises.md)
