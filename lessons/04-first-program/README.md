# Lesson 04: Your first program

## Goals

After this lesson you can:

- Write a complete assembly program from an empty file.
- Explain what `.global`, `.text`, `.p2align`, labels, and comments do.
- Use `mov` to put a constant or another register's value into a register.
- End a program with the `exit` system call and read its exit status.
- Assemble and link a program by hand, and say what each step produced.
- Recognise the crash you get when you forget to exit.

## Before you start

You need lesson 03: registers `x0`-`x30`, what an instruction is, and the
assembler, object file, and linker pipeline. Work inside the Linux container:

```console
$ ./scripts/linux-shell.sh
# cd lessons/04-first-program/examples
```

## The whole program

Here is the complete program. It does one thing: it stops, and reports the
number 42 to whoever started it.

```asm
    .global _start              // make the name _start visible to the linker
    .text                       // what follows is code
    .p2align 2                  // start on a 4-byte boundary (2^2)

_start:                         // the program begins here
    mov x0, #42                 // x0 = 42: the exit status we want
    mov x8, #93                 // x8 = 93: Linux's number for the exit system call
    svc #0                      // ask the kernel to run system call x8 with argument x0
```

That is `examples/exit42.s`. Build it and run it:

```console
# make
gcc -g -nostdlib -static -o exit42 exit42.s
...
# ./exit42
# echo $?
42
```

Running it printed nothing. That is correct: this program does not print. It
*exits with status 42*, and `echo $?` shows the status of the last command.

The C equivalent is:

```c
int main(void) {
    return 42;
}
```

or, closer to what we actually wrote, `exit(42);`. Now let's go through it
line by line. There are only three kinds of line in it: comments, directives,
and instructions, plus one label.

## Comments

Everything from `//` to the end of the line is a comment. The assembler
ignores it. In assembly, comments are not optional decoration: a line like
`mov x8, #93` says *what* happens but never *why*. Get into the habit now of
commenting every line. Later lessons will relax this to commenting intent.

## Directives: instructions to the assembler

Lines starting with a dot are **directives**. They do not become machine
instructions. They tell the assembler how to build the object file.

| Directive | Meaning |
|-----------|---------|
| `.global _start` | Export the name `_start` so the linker can see it. Without this, the name stays private to this file. |
| `.text` | Put what follows in the *text section*, which is where code lives. Lesson 05 adds a data section. |
| `.p2align 2` | Pad until the address is a multiple of 2^2 = 4. Every AArch64 instruction is 4 bytes and must start at an address divisible by 4. |

Why does the linker need to see `_start`? Because `_start` is the
**entry point**: the linker writes "begin at `_start`" into the executable's
header, and the operating system jumps there when the program starts. If the
linker cannot find `_start`, it guesses, as you will see in exercise 04.5.

## Labels: names for addresses

```asm
_start:
```

A name followed by a colon is a **label**. It does not produce any bytes. It
gives a name to the address where the *next* thing will be placed. Here that
next thing is the first `mov`, so `_start` means "the address of the first
instruction".

Labels go at the start of the line (column 0). Instructions are indented. The
assembler does not care about indentation, but people reading your code do.

## Instructions: `mov`

```asm
    mov x0, #42
```

This is your first real instruction. Read it as **x0 = 42**. The destination
comes first, then the source. Every AArch64 instruction is written this way:
destination on the left, like an assignment in C.

The `#` marks an **immediate**: a constant that is stored inside the
instruction itself. Lesson 03 showed that every instruction is a 32-bit number;
the `42` is literally some of those 32 bits.

`mov` can also copy one register into another:

```asm
    mov x4, x3                  // x4 = x3
```

There is no `#` here, because `x3` is a register, not a constant. Copying is
the right word: after this, `x3` still holds its value. Try `examples/copy.s`:

```asm
_start:
    mov x3, #7                  // x3 = 7
    mov x4, x3                  // x4 = x3   (copy a register, not a constant)
    mov x0, x4                  // x0 = x4   (the exit status must be in x0)
    mov x8, #93                 // exit
    svc #0
```

**Predict** the exit status before you run it. Then check:

```console
# ./copy; echo $?
7
```

In C this is just:

```c
long a = 7;
long b = a;
exit(b);
```

Notice that registers have no names like `a` and `b`. You decide which
register stands for which variable, and you keep track of it. Comments are
where you record that.

## The exit system call

Your program cannot simply stop. The CPU always runs the next instruction,
forever. To end, a program must ask the operating system kernel to remove it.
That request is a **system call** (lesson 03).

On Linux AArch64, a system call works like this:

1. Put the **system call number** in `x8`. It says which service you want.
   `exit` is number 93.
2. Put the **arguments** in `x0`, `x1`, `x2`, ... `exit` takes one argument:
   the status.
3. Execute `svc #0` ("supervisor call"). The CPU switches to the kernel, which
   reads `x8` and `x0` and does the work.

`exit` never returns: there is no next instruction for your program after it.

The numbers come from the kernel's system call table
(`include/uapi/asm-generic/unistd.h` in the Linux source). You do not need to
memorise them. You will use three for a while: `exit` 93, `write` 64,
`read` 63.

## Exit status is only 8 bits

`x0` holds 64 bits, but the shell sees only the lowest 8 bits of the exit
status. So the status is always 0-255, and larger values wrap around: the
shell sees the value mod 256.

`examples/wrap.s` exits with 300. Predict what `echo $?` shows, then run it:

```console
# ./wrap; echo $?
44
```

300 = 256 + 44. In binary, 300 is `1 0010 1100`; keep the low 8 bits and you
get `0010 1100` = 44. This is the same wraparound you met in lesson 01.

Until lesson 11, the exit status is the only way your programs will report a
number, so you will use `echo $?` a lot. Keep your answers between 0 and 255.

By convention, status 0 means success and anything else means something went
wrong. The shell's `&&` and `||` use this: `./exit42 && echo ok` prints nothing.

## Forgetting to exit

What happens if you leave out the `svc`? `examples/no_exit.s` does exactly
that:

```asm
_start:
    mov x0, #1
    mov x8, #93
                                // ...but forget the svc
```

```console
# ./no_exit; echo $?
Illegal instruction (core dumped)
132
```

After the second `mov`, the CPU fetches the next 4 bytes and tries to run
them. Nothing we wrote is there; it might be zero padding, or the end of the
program's memory. Here it was bytes that are not a valid instruction, so the
CPU raised a fault and the kernel killed the program. Status 132 means
"killed by signal 4" (128 + 4), which is `SIGILL`, illegal instruction. You
might also see `Segmentation fault` (139, signal 11) in other situations.

Remember this one. "My program crashed right at the end" almost always means
the program ran past its last instruction.

## What `make` did: assembling and linking by hand

`make` ran `gcc -g -nostdlib -static -o exit42 exit42.s`. `gcc` here is only a
driver: it runs the assembler and the linker for you. Do it yourself once, so
you know there is no magic:

```console
# as -o exit42.o exit42.s       # assemble: text -> object file
# ld -o exit42 exit42.o         # link: object file -> executable
# ./exit42; echo $?
42
```

Look at each stage:

```console
# file exit42.o
exit42.o: ELF 64-bit LSB relocatable, ARM aarch64, ...
# nm exit42.o
0000000000000000 T _start
# objdump -d exit42.o

0000000000000000 <_start>:
   0:   d2800540        mov     x0, #0x2a                       // #42
   4:   d2800ba8        mov     x8, #0x5d                       // #93
   8:   d4000001        svc     #0x0
```

- The object file is **relocatable**: its addresses start at 0 because it has
  not been placed in memory yet.
- `nm` lists `_start` with `T`: a global symbol in the text section. Remove
  `.global` and it becomes a lowercase `t` (local).
- `objdump -d` shows three instructions, 4 bytes each, at offsets 0, 4, 8.
  `0x2a` is 42 and `0x5d` is 93, in hex.

Run `objdump -d exit42` on the linked executable and you will see the same
three instructions, now at a real address such as `0x400078`. The linker
decided where they go.

The flags `make` uses mean:

| Flag | Meaning |
|------|---------|
| `-g` | Keep debug information, for lesson 06. |
| `-nostdlib` | Do not link the C library or its startup code. Our `_start` is the very first thing that runs. |
| `-static` | Produce a self-contained executable with no shared libraries. |

From lesson 16 on we *will* link the C library, and the C library will provide
`_start` and call our `main` instead.

## Writing your own

Create a work directory and start from an empty file:

```console
# mkdir -p ../work && cd ../work
# cp ../examples/Makefile .
```

Type `exit42.s` in again from memory, with your own exit status. Then `make`
and run it. If it does not build, read the error message: the assembler tells
you the file and line.

## C to assembly

| C | Assembly (Linux) |
|---|------------------|
| a program starts at `main` | a freestanding program starts at `_start` (made visible with `.global`) |
| `long a = 7;` | `mov x3, #7` (you choose the register) |
| `b = a;` | `mov x4, x3` |
| `exit(42);` | `mov x0, #42` / `mov x8, #93` / `svc #0` |
| `// comment` | `// comment` |

## Common mistakes

- **Forgetting `svc #0`.** The program crashes with `Illegal instruction` or
  `Segmentation fault` after your last line.
- **Swapping source and destination.** `mov 42, x0` is an error. The
  destination always comes first.
- **Missing `#` before a number.** GNU `as` and clang both quietly accept
  `mov x0, 42`, but `#` is the standard notation, and it is what `objdump`
  shows you. Always write `#42`.
- **Forgetting `.global _start`.** The linker warns
  `cannot find entry symbol _start` and guesses an address. The program might
  even work by luck. Fix the warning anyway.
- **Expecting an exit status above 255.** You get the value mod 256.
- **Running `echo $?` too late.** `$?` is the status of the *last* command.
  Run anything in between (even another `echo`) and it is gone.

## Recap

- A program is comments, directives, labels, and instructions.
- `.global` exports a name, `.text` starts code, `.p2align 2` aligns to 4 bytes.
- A label names the address of whatever follows it.
- `_start` is the entry point of a program without the C library.
- `mov xD, #imm` loads a constant; `mov xD, xS` copies a register. The
  destination is always first.
- System calls: number in `x8`, arguments in `x0`..., then `svc #0`.
  `exit` is 93.
- The shell sees the exit status mod 256; read it with `echo $?`.
- A program that does not exit runs off the end of its code and crashes.
- `as` turns `.s` into `.o`; `ld` turns `.o` into an executable. `gcc` runs
  both for you.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/04-first-program/README.md) next.
