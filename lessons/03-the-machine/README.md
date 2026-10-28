# Lesson 03: The machine

## Goals

After this lesson you can:

- Describe the three parts that run a program: the CPU, memory, and the
  operating system.
- Picture memory as a numbered row of bytes, and say where a multi-byte value
  lives in it.
- Name the AArch64 registers: `x0`-`x30`, their `w` halves, `sp`, `xzr`,
  and `pc`, and say what happens to the upper half when you write a `w`
  register.
- Explain that an instruction is a 32-bit number, and pick apart one encoding.
- Walk through fetch, decode, execute.
- Say what the assembler, the linker, and the operating system's loader each
  do, and what ELF and Mach-O are.
- Say what a system call is and why a program needs one.

## Before you start

[Lesson 01](../01-binary-and-hex/README.md) (hex, bits, sizes) and
[lesson 02](../02-signed-numbers/README.md) (little-endian byte order). You
need the container from [lesson 00](../00-setup/README.md) for the examples.

This lesson is mostly ideas. You will build two small programs, but only to
look inside them; writing your own starts in lesson 04.

## The big picture

When you run `./check`, three things work together:

```
   +-------------------+          +-------------------------------+
   |        CPU        |  reads   |            MEMORY             |
   |                   | <------> |  a long row of bytes, each    |
   |  registers:       |  writes  |  with a number (its address)  |
   |  x0 ... x30, sp   |          |                               |
   |  pc               |          |  your program's instructions  |
   |                   |          |  your program's data          |
   +-------------------+          +-------------------------------+
             ^
             |  "please do this for me" (system calls)
             v
   +-----------------------------------------------------------+
   |  OPERATING SYSTEM (the kernel): loads programs, owns the  |
   |  screen, keyboard, files, and network                     |
   +-----------------------------------------------------------+
```

- **Memory** holds bytes: your program's instructions and its data.
- The **CPU** (processor) fetches instructions from memory one at a time and
  does what they say. It keeps the numbers it is working on in a few
  **registers** inside itself.
- The **operating system** (Linux, or macOS) puts your program into memory,
  starts it, and does anything that involves hardware on its behalf.

The rest of this lesson takes each piece in turn.

## Memory is a row of bytes

Think of memory as one enormous array of bytes. Each byte has an index,
called its **address**. Addresses start at 0 and go up by one per byte:

```
address:  0x1000  0x1001  0x1002  0x1003  0x1004  0x1005  ...
byte:      0x48    0x69    0x21    0x00    0x2a    0x00   ...
```

In C terms, it is as if all of memory were

```c
unsigned char memory[18446744073709551616];  /* one byte per address */
```

and a pointer is just an index into it. When C says `p` points to `x`, it
means "`p` holds the address of `x`'s first byte". On AArch64, addresses are
64 bits, so a pointer is a doubleword (8 bytes) and is always written in hex.

Every byte has its own address, which is why this is called
**byte-addressed** memory. A value bigger than a byte uses several addresses
in a row. A 32-bit word at `0x1004` occupies `0x1004`, `0x1005`, `0x1006`, and
`0x1007`, and (lesson 02) its *least significant* byte is at `0x1004`, the
lowest address. The next word after it starts at `0x1008`.

Memory is big but slow, compared with the CPU. Loading a number from memory
takes many times longer than adding two numbers that are already in the CPU.
That is what registers are for.

## Registers: the CPU's own tiny variables

A **register** is a storage slot inside the CPU. There are only a few of
them, each holds exactly 64 bits, and the CPU can use them instantly. Almost
every instruction works on registers: "add register 1 to register 2 and put
the answer in register 0". To work on something in memory, you first copy it
into a register (lesson 11), work on it there, and copy it back.

### The 31 general-purpose registers: `x0` to `x30`

AArch64 has 31 general-purpose registers, named **`x0`** to **`x30`**. Each
holds a 64-bit value: a number (signed or unsigned, lesson 02), an address,
some characters, anything. The CPU does not care what the bits mean.

Each one also has a 32-bit name, **`w0`** to **`w30`**: `w5` means "the low 32
bits of `x5`". It is the *same* register, not a different one:

```
            bit 63                         bit 32 bit 31                          bit 0
x5:        [  upper 32 bits                      |  lower 32 bits = w5                  ]
```

Use the `x` name for 64-bit values (C's `long`, pointers) and the `w` name for
32-bit values (C's `int`). The rules for the two halves:

- **Reading `w5`** gives you the low 32 bits of `x5`. The upper bits are
  ignored.
- **Writing `w5`** sets the low 32 bits *and sets the upper 32 bits to zero*.
  Always. If `x5` held `0xFFFFFFFFFFFFFFFF` and an instruction writes 5 into
  `w5`, `x5` is now `0x0000000000000005`.

That second rule surprises people, but it is useful: writing a 32-bit value
into a `w` register gives you the same number, zero-extended (lesson 02), in
the `x` register for free.

The registers are all general-purpose to the CPU, but programs agree on jobs
for some of them. You will meet these conventions as you need them; the full
list is in the [cheat sheet](../../docs/reference/aarch64-cheatsheet.md). The
ones that matter soonest:

| Register | Agreed job | Lesson |
|----------|------------|--------|
| `x0`-`x7` | values passed into a system call or function; `x0` also gets the result | 04, 15 |
| `x8` | on Linux, which system call you want | 04 |
| `x18` | reserved on some systems: **this course never uses it** | 15 |
| `x29` | the frame pointer | 14 |
| `x30` | the link register: where a function returns to | 14 |

### `sp`, `xzr`, and `pc`

Three more registers have special behaviour:

- **`sp`**, the **stack pointer**, holds the address of the top of the
  program's stack, a scratch area of memory (lesson 13). It is not one of
  `x0`-`x30`.
- **`xzr`** (and its 32-bit name **`wzr`**), the **zero register**. Reading it
  always gives 0; writing it throws the value away. That sounds useless, but
  it is handy: "store zero" can just store `xzr`. (Inside an instruction's
  encoding, `sp` and `xzr` share register number 31; each instruction decides
  which one 31 means. The assembler sorts it out for you.)
- **`pc`**, the **program counter**, holds the address of the instruction
  being run. You cannot write it like an ordinary register; it changes as the
  program runs, and branch instructions (lesson 09) change it on purpose.

So the complete set of integer registers you will use is: `x0`-`x30` (with
their `w` views), `sp`, `xzr`/`wzr`, and the program counter. That is all. In
C you can have as many variables as you like; in assembly you have about
thirty slots, and you decide which value lives in which.

(There is also a separate set of 32 registers for floating-point numbers,
`v0`-`v31`. They wait until lesson 23.)

## Instructions are numbers

An instruction is not text. `mov x0, #42` is how *people* write it; the CPU
sees a number. On AArch64, **every instruction is exactly 32 bits** (one
word, four bytes). Not some of them: every one.

Let's see that. In the container:

```console
$ cd /work/lessons/03-the-machine/examples
$ make
cc -g -nostdlib -static -o bytes bytes.s
cc -g -nostdlib -static -o encoding encoding.s
```

Open [examples/encoding.s](examples/encoding.s). You will learn to write a
file like this in lesson 04; for now the important part is the eight lines
between `_start:` and the end. Each one is a single instruction. `mov x0, #42`
means "put the number 42 into register `x0`" (the `#` marks a number written
into the instruction itself). `svc #0` asks the operating system to end the
program (lesson 04).

Disassemble it:

```console
$ objdump -d encoding

encoding:     file format elf64-littleaarch64


Disassembly of section .text:

00000000004000d4 <_start>:
  4000d4:	d2800020 	mov	x0, #0x1                   	// #1
  4000d8:	d2800040 	mov	x0, #0x2                   	// #2
  4000dc:	d2800540 	mov	x0, #0x2a                  	// #42
  4000e0:	d2800541 	mov	x1, #0x2a                  	// #42
  4000e4:	d2800542 	mov	x2, #0x2a                  	// #42
  4000e8:	52800540 	mov	w0, #0x2a                  	// #42
  4000ec:	d2800ba8 	mov	x8, #0x5d                  	// #93
  4000f0:	d4000001 	svc	#0x0
```

Three columns: the **address** where the instruction sits in memory, the
instruction **as a number** (eight hex digits = 32 bits), and the instruction
**as text**, rebuilt from the number. Notice the addresses go up by exactly 4
each time.

Before reading on, compare these lines and make some guesses:

- `mov x0, #1` is `d2800020` and `mov x0, #2` is `d2800040`. Where is the
  number?
- `mov x0, #42`, `mov x1, #42`, and `mov x2, #42` end in `40`, `41`, `42`.
  Where is the register?
- `mov w0, #42` is `52800540`; `mov x0, #42` is `d2800540`. What is different?

### Taking one apart

Write `d2800540` (`mov x0, #42`) out in binary and split it into the fields
the CPU reads. (The Arm Architecture Reference Manual lists the fields for
every instruction; this one is called MOVZ.)

```
hex:     d    2    8    0    0    5    4    0
binary:  1101 0010 1000 0000 0000 0101 0100 0000

bit 31     | 30 29 | 28 ......... 23 | 22 21 | 20 ................ 5 | 4 ...... 0
  1        |  1 0  |  1 0 0 1 0 1    |  0 0  | 0000 0000 0010 1010   | 0 0 0 0 0
  sf       |  opc  |  "this is a     |  hw   |  imm16                | Rd
  64-bit?  |       |   move-wide"    |       |  = 42                 | = register 0
```

- **Bits 0-4, Rd**: the destination register number. `00000` = 0, so `x0`.
  Five bits can name registers 0 to 31. That is why `mov x1` ends in `1` and
  `mov x2` ends in `2`.
- **Bits 5-20, imm16**: the number to put in it, 16 bits wide. `0000 0000
  0010 1010` = 42. Shifted up 5 places from bit 0, which is why 1 shows as
  `...020` and 2 as `...040`.
- **Bit 31, sf**: 1 for a 64-bit (`x`) register, 0 for a 32-bit (`w`)
  register. Flip it and `d...` becomes `5...`: `52800540` is `mov w0, #42`.
- The bits in between say which instruction this is.

You do not need to memorise encodings. The point is: **an instruction is
nothing but a number, with fields that the CPU decodes.** The assembler's
job is to work out those numbers from your text. One consequence you will
meet in lesson 07: the number lives inside a 32-bit instruction, so it
cannot be any 64-bit value; here it gets only 16 bits.

### Instructions sit in memory like any other bytes

The program's instructions are in memory, as bytes, right next to (well, near)
its data. [examples/bytes.s](examples/bytes.s) has three instructions and
some data. Dump the raw bytes of each part:

```console
$ objdump -s -j .data bytes

bytes:     file format elf64-littleaarch64

Contents of section .data:
 410118 01020304 78563412 486921             ....xV4.Hi!

$ objdump -s -j .text bytes

bytes:     file format elf64-littleaarch64

Contents of section .text:
 40010c 000080d2 a80b80d2 010000d4           ............
```

`-s` shows bytes in memory order, lowest address first, in groups of four.

- `.data` starts with the four bytes `01 02 03 04` exactly as written. Then
  the word `0x12345678` appears as `78 56 34 12`: little-endian, low byte
  first (lesson 02). Then `48 69 21`, the character codes for `H`, `i`, `!`.
  The right-hand column shows the bytes as text where it can.
- `.text` holds the instructions. The first is `00 00 80 d2`: reverse the
  bytes and you get `d2800000`, which is `mov x0, #0`. `objdump -d` shows
  each instruction as a number (bytes already reversed); `objdump -s` shows
  the raw bytes in memory order.

So code and data are both just bytes in memory. What makes bytes an
instruction is only that the program counter points at them.

## Fetch, decode, execute

The CPU runs a program by repeating three steps, billions of times a second:

1. **Fetch**: read the 4 bytes at the address in `pc`.
2. **Decode**: split the 32-bit number into fields and work out what it means.
3. **Execute**: do it (put 42 in `x0`, add two registers, ...). Then move `pc`
   on by 4 to the next instruction, unless the instruction itself changed
   `pc` (a branch, lesson 09).

Trace `encoding` by hand. The program starts with `pc` at `_start`, address
`0x4000d4`:

| `pc` before | Instruction | After it runs |
|-------------|-------------|---------------|
| `0x4000d4` | `mov x0, #1` | `x0` = 1 |
| `0x4000d8` | `mov x0, #2` | `x0` = 2 (the 1 is gone) |
| `0x4000dc` | `mov x0, #42` | `x0` = 42 |
| `0x4000e0` | `mov x1, #42` | `x1` = 42 |
| `0x4000e4` | `mov x2, #42` | `x2` = 42 |
| `0x4000e8` | `mov w0, #42` | `w0` = 42, upper half of `x0` = 0, so `x0` = 42 |
| `0x4000ec` | `mov x8, #93` | `x8` = 93 |
| `0x4000f0` | `svc #0` | the operating system ends the program, status `x0` |

What exit status do you predict? Check:

```console
$ ./encoding
$ echo $?
42
```

In lesson 06 you will watch this happen one instruction at a time in a
debugger.

## From text to a running program

You write text. The CPU runs numbers in memory. Three programs get you from
one to the other.

```
 encoding.s  --[ assembler ]-->  encoding.o  --[ linker ]-->  encoding  --[ loader ]-->  running
 (text)         as                (object file)   ld           (executable)  the OS        in memory
```

### The assembler: text to machine code

The **assembler** (`as`) reads your `.s` file and turns each instruction into
its 32-bit number. It writes an **object file** (`.o`). Run it yourself:

```console
$ as encoding.s -o encoding.o
$ objdump -d encoding.o
...
0000000000000000 <_start>:
   0:	d2800020 	mov	x0, #0x1                   	// #1
   4:	d2800040 	mov	x0, #0x2                   	// #2
...
```

The instruction numbers are already final, but the addresses start at **0**.
An object file is not a program yet: the assembler does not know where in
memory the code will end up. An object file holds:

- the machine code and data bytes, in **sections** (`.text` for code, `.data`
  for data);
- a **symbol table**: the names you defined (like `_start`) and where they are
  inside the sections;
- **relocations**: notes saying "this instruction needs the address of
  `msg`, please fill it in later" (you will see why in lesson 05).

### The linker: object files to an executable

The **linker** (`ld`) takes one or more object files and:

- decides the final memory address of every section;
- fills in every relocation now that addresses are known;
- records the **entry point**: the address where the program starts;
- writes an **executable** file.

```console
$ ld encoding.o -o encoding2
$ ./encoding2; echo $?
42
$ nm encoding.o
0000000000000000 T _start
$ nm encoding2
...
0000000000400078 T _start
```

`_start` was at 0 inside the object file and is at `0x400078` in the program.
(The `encoding` built by `make` has `_start` at `0x4000d4` instead, because
`gcc` asks the linker to add a little extra information at the start of the
file. Same idea.) `T` means "a name in the text section". The entry point is
written in the file's header:

```console
$ readelf -h encoding | grep Entry
  Entry point address:               0x4000d4
```

Usually you never run `as` and `ld` yourself. `make` runs `gcc`, and `gcc`
runs both for you; that is what `cc -g -nostdlib -static -o encoding
encoding.s` did. Lesson 04 does it by hand once more so you see it. Clean up
the extra files: `rm encoding.o encoding2`.

### Executable formats: ELF and Mach-O

An executable is not just machine code. It also has a header (what kind of
CPU, where the entry point is), a list of sections and where to load them, and
the symbol table. The layout of all that is the **executable format**:

- Linux uses **ELF** (Executable and Linkable Format). `file` says `ELF
  64-bit LSB executable, ARM aarch64`. ("LSB" means least significant byte
  first: little-endian.)
- macOS uses **Mach-O**. `file` says `Mach-O 64-bit executable arm64`.

The machine code inside is the same; the wrapping is different. That is one
reason a Linux program will not run on macOS even on the same CPU.

### The loader: the OS starts your program

When you type `./encoding`, the shell asks the kernel to run it. The kernel's
**loader**:

1. reads the executable's header and checks it is the right format and CPU;
2. gives the program its own memory, and copies (maps) each section into it at
   the address the linker chose;
3. sets up a stack and points `sp` at it;
4. sets `pc` to the entry point and lets the CPU go.

From then on the CPU fetches, decodes, and executes your instructions,
starting at `_start`.

Every program gets its own private view of memory. Your program's `0x4000d4`
is not the same memory as another program's `0x4000d4`. The operating system
and the CPU arrange this together; you do not need the details for this
course.

## System calls: asking the operating system

Your program can compute anything with registers and memory. But it cannot
touch the screen, the keyboard, files, or the network directly. Only the
kernel can; ordinary programs are not allowed to. Even *stopping* needs the
kernel, because the kernel has to clean up and tell the shell the exit status.

So a program asks. A **system call** is a request to the kernel. On Linux
AArch64:

1. Put the number of the service you want in `x8` (93 means "exit", 64 means
   "write").
2. Put its arguments in `x0`, `x1`, `x2`, ... (for exit, `x0` is the status).
3. Run the instruction **`svc #0`** ("supervisor call"). The CPU jumps into the
   kernel.
4. The kernel does the work and (if the call returns at all) puts the result
   in `x0` and continues your program at the next instruction.

That is exactly what the last two lines of `encoding.s` do: `mov x8, #93`,
then `svc #0`, with 42 already in `x0`. In C you would write `exit(42);`, and
the C library would do this for you. Lessons 04 and 05 use `exit` and `write`
for real.

## C to assembly

| C | Machine | Lesson |
|---|---------|--------|
| a `long` or pointer variable | a 64-bit `x` register, or 8 bytes of memory | 03, 11 |
| an `int` variable | a 32-bit `w` register, or 4 bytes of memory | 03, 18 |
| `&x` (address of `x`) | the address of `x`'s first byte | 05, 12 |
| `*p` (what `p` points at) | the bytes at the address in a register | 11 |
| `x = 42;` | `mov x0, #42` | 04, 07 |
| `exit(42);` | `mov x0, #42` / `mov x8, #93` / `svc #0` | 04 |
| compiling one `.c` file | assembling one `.s` file into a `.o` | 03 |
| building a program from several files | linking `.o` files | 20 |

## Common mistakes

- **Thinking `w5` and `x5` are different registers.** They are one register;
  `w5` is its low half.
- **Forgetting that writing a `w` register clears the upper half.** Writing
  `w5` never leaves old bits in the top of `x5`.
- **Reading object-file addresses as real ones.** In `objdump -d prog.o` the
  addresses start at 0. Only the linked program has final addresses.
- **Reading `objdump -s` bytes as numbers.** `-s` shows raw bytes, lowest
  address first; a word appears byte-reversed. `-d` shows instructions as
  numbers.
- **Expecting instructions of different sizes.** If you have read about x86,
  forget its variable-length instructions: on AArch64 every instruction is
  4 bytes.
- **Using `x18`.** Linux allows it, macOS does not. This course never uses it.

## Recap

- Memory is a row of bytes, each with an address; a pointer is an address. A
  multi-byte value uses consecutive addresses, low byte first.
- The CPU has 31 general registers `x0`-`x30` (64 bits), with 32-bit views
  `w0`-`w30`; writing a `w` register zeroes the upper 32 bits.
- `sp` is the stack pointer, `xzr`/`wzr` always read zero, `pc` is the
  address of the current instruction.
- Every AArch64 instruction is a 32-bit number with fields: register numbers,
  constants, and which operation.
- The CPU loops: fetch at `pc`, decode, execute, `pc += 4`.
- The assembler turns `.s` text into a `.o` object file; the linker places it
  at final addresses and writes an executable (ELF on Linux, Mach-O on macOS);
  the loader puts it in memory and jumps to the entry point.
- A system call asks the kernel to do something a program cannot do itself:
  number in `x8`, arguments in `x0`..., then `svc #0`.

## Homework

[exercises.md](exercises.md)
