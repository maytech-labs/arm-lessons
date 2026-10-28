# Lesson 00 solutions

Try each exercise first. Programs: [ex3.s](linux/solutions/ex3.s), [ex4.s](linux/solutions/ex4.s). Build them
here with `make` (inside the container).

Your addresses and sizes may differ a little from the ones below; that is fine.

## 00.1

1. `Apple clang version ...` and `Target: arm64-apple-darwin...`.
2. `Hello from Docker!`
3. `Linux aarch64`
4. Something like `gcc (Debian 12.2.0-14+deb12u1) 12.2.0`.

If any of these fail, go back to the matching step of the lesson. The usual
causes are: Xcode tools not installed (1), Docker not running (2), or running
the command on the Mac instead of in the container (3, 4).

## 00.2

1. `make` prints `cc -g -nostdlib -static -o check check.s`. `./check` prints
   `toolchain works`. `echo $?` prints `0`.
2. The second `echo $?` reports the exit status of the *first* `echo`, which
   succeeded, so it is 0. `$?` always describes the most recent command.
3. `make: Nothing to be done for 'all'.` The program `check` is newer than
   `check.s`, so there is nothing to rebuild.
4. The program `check` is deleted. `check.s` and `Makefile` remain.

## 00.3

See [ex3.s](linux/solutions/ex3.s). The only change is `mov x0, #0` becoming `mov x0, #7`.

## 00.4

See [ex4.s](linux/solutions/ex4.s). The only change is the text inside `.ascii "..."`.

The line `.equ len, . - msg` works out the length: it means "len is the
distance from `msg` to here", that is, the number of bytes of text. The
`write` call uses `len` as the byte count, so it updates by itself. Lesson 05
explains this properly.

## 00.5

1. `ELF 64-bit LSB executable, ARM aarch64, ... statically linked ...`: a Linux
   (ELF) program, 64-bit, for ARM AArch64 CPUs, that needs no libraries.
2. `assembler source, ASCII text`. It is a text file of source code, not a
   program. `file` guesses "assembler" from what the text looks like.
3. `ASCII text`. A Makefile is plain text too.

## 00.6

1. Something like `000000000040010c T _start`.
2. Something like `0000000000410130 d msg`.
3. `msg` has the bigger number. Comparing from the left, both start
   `00000000004`, then `_start` has `0` and `msg` has `1`. Code (`_start`) and
   data (`msg`) are placed in different areas of memory, with the data after
   the code. Lesson 03 explains this.

## 00.7

1. Nine instructions.
2. Each address is 4 more than the one before. That suggests every
   instruction is 4 bytes long, and that is right: every AArch64 instruction
   is exactly 4 bytes (32 bits). Lesson 03.
3. In `check` the line is `d2800000  mov x0, #0x0`. In `ex3` it is
   `d28000e0  mov x0, #0x7`. The text changed from 0 to 7, and so did part of
   the hex number: the number 7 is stored *inside* the instruction. Lesson 03
   shows exactly where.

## 00.8

`./hello` prints `hello from C`, and `echo $?` prints `5`.

1. `hello` is much bigger: tens of kilobytes, against about two kilobytes for
   `check`.
2. `hello` has dozens of symbols (36 here); `check` has 10.
3. `dynamically linked, interpreter /lib/ld-linux-aarch64.so.1`. The C program
   needs the C library, which is loaded from a separate file when it starts.
   `check` is `statically linked`: everything it needs is inside it, and it
   needs very little.
