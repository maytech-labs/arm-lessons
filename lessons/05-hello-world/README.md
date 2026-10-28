# Lesson 05: Hello, world

## Goals

After this lesson you can:

- Print text with the `write` system call.
- Explain file descriptors 0, 1, and 2.
- Put data in your program with `.data` and `.section .rodata`.
- Write strings with `.ascii` and `.asciz`, including escape sequences.
- Let the assembler compute a string's length with `. - label` and `.equ`.
- Load the address of a label into a register with `adrp` and `add`.
- Use the value a system call returns.

## Before you start

You need lesson 04: `_start`, `mov`, and the `exit` system call. Work in the
container:

```console
$ ./scripts/linux-shell.sh
# cd lessons/05-hello-world/linux/examples && make
```

## The program

```asm
    .global _start

    .data                           // initialised data goes here
msg:
    .ascii "Hello, world!\n"        // the 14 bytes we will print
    .equ msg_len, . - msg           // msg_len = (here) - (start of msg) = 14

    .text
    .p2align 2
_start:
    mov x0, #1                      // argument 1: file descriptor 1 = stdout
    adrp x1, msg                    // argument 2: the address of msg...
    add x1, x1, :lo12:msg           // ...built in two steps (see the lesson)
    mov x2, #msg_len                // argument 3: how many bytes to write
    mov x8, #64                     // 64 = write
    svc #0                          // write(1, msg, 14)

    mov x0, #0                      // exit status 0: success
    mov x8, #93                     // 93 = exit
    svc #0                          // exit(0)
```

```console
# ./hello
Hello, world!
```

In C, the same program is:

```c
#include <unistd.h>

int main(void) {
    write(1, "Hello, world!\n", 14);
    return 0;
}
```

Not `printf`: `printf` is a C library function that does a lot of work and
then calls `write` itself. We are skipping the library and calling `write`
directly. There are four new ideas here: the `write` system call, data, the
string's length, and getting the string's address. One at a time.

## The `write` system call

`write` sends bytes to a file. It takes three arguments:

```c
write(fd, buf, count)
```

| Argument | Register | Meaning |
|----------|----------|---------|
| `fd` | `x0` | Which file to write to (a number, see below) |
| `buf` | `x1` | The **address** of the first byte to write |
| `count` | `x2` | How many bytes to write |

The system call number for `write` is **64**, in `x8`, as always. Then
`svc #0`.

Notice that `write` does not take a string. It takes an *address* and a
*count*. It has no idea what the bytes mean: it copies `count` bytes starting
at that address. That is why we must tell it the length.

### File descriptors

A **file descriptor** is a small number that stands for an open file. Every
program starts with three already open:

| fd | Name | Normally connected to |
|----|------|-----------------------|
| 0 | stdin | the keyboard (input) |
| 1 | stdout | the terminal (normal output) |
| 2 | stderr | the terminal (error messages) |

stdout and stderr both appear on your terminal, but they are separate, and the
shell can redirect them separately. `examples/stderr.s` writes to fd 2:

```console
# ./stderr; echo $?
something went wrong
1
# ./stderr 2>/dev/null; echo $?
1
```

`2>/dev/null` threw stderr away, so the message vanished. Error messages go
to stderr so that they do not get mixed into a program's real output when you
redirect it to a file.

## Data: putting bytes in your program

Until now, your programs were only instructions. A message has to live
somewhere in memory too. The assembler puts things in **sections** (lesson 03):

| Directive | Section | For |
|-----------|---------|-----|
| `.text` | text | code |
| `.data` | data | variables with a starting value; readable and writable |
| `.section .rodata` | read-only data | constants; writing to them crashes the program |

You can switch between sections as often as you like. The assembler collects
everything for each section together.

`hello.s` used `.data`. A message we never change is really a constant, so
from now on we will put messages in `.rodata`, like `examples/rodata.s`:

```asm
    .section .rodata                // read-only data: writing here would crash
msg:
    .ascii "Constants belong in .rodata\n"
```

This is the same as C's `const`: the compiler puts string literals in
`.rodata` too.

### `.ascii` and `.asciz`

`.ascii "text"` puts the bytes of the characters into memory, one byte per
character, using the ASCII codes from lesson 01 (`H` is 0x48, `e` is 0x65, ...).
It adds nothing else.

`.asciz "text"` does the same and adds one **zero byte** at the end. C strings
end with a zero byte: that is how C functions like `strlen` find the end. We
will need `.asciz` in lesson 16 when we call C functions. For `write`, the
zero byte is not useful: we give the length explicitly, and we do not want to
print a zero byte.

`examples/asciz.s` has one of each. Look at the bytes:

```console
# objdump -s -j .rodata asciz
Contents of section .rodata:
 ... 61736369 690a6173 63697a0a 00        ascii.asciz..
```

`61 73 63 69 69 0a` is "ascii\n". Then `61 73 63 69 7a 0a 00` is "asciz\n"
followed by the zero.

### Escape sequences

Inside the quotes, a backslash starts an escape sequence, as in C:

| Escape | Byte | Meaning |
|--------|------|---------|
| `\n` | 0x0a | newline |
| `\t` | 0x09 | tab |
| `\"` | 0x22 | a double quote |
| `\\` | 0x5c | a backslash |
| `\x41` | 0x41 | any byte, given in hex |

`examples/escapes.s` uses all of them. It also shows that several `.ascii`
lines in a row simply continue the same run of bytes.

## The length: `. - msg` and `.equ`

```asm
msg:
    .ascii "Hello, world!\n"
    .equ msg_len, . - msg
```

The assembler keeps track of the address it is currently putting bytes at.
Inside the assembler, `.` (a single dot) means **this address, right here**.

- `msg` is the address where the string starts.
- After the `.ascii` line, `.` is the address just past the string's end.
- So `. - msg` is the number of bytes in between: the length, 14.

`.equ name, value` gives a constant a name, like `#define` in C. It creates no
bytes in memory. When you later write `#msg_len`, the assembler puts 14 there.

Why not just write `mov x2, #14`? Because the day you change the message to
"Hello, everybody!\n", you would have to recount and edit 14 too. Let the
assembler count.

The `.equ` must come **right after** the string. If you put anything between,
it gets counted too.

## The address: `adrp` and `add`

`x1` must hold the **address** of `msg`. Where is `msg`? The linker decides
that, after the assembler has run. And an address is 64 bits, while a whole
instruction is only 32 bits: it cannot contain a full address.

AArch64 solves this by asking: how far is `msg` from *this instruction*? Code
and data are near each other, so that distance is small. Two instructions do
the job:

```asm
    adrp x1, msg                    // x1 = the 4 KiB page that msg is in
    add x1, x1, :lo12:msg           // x1 = x1 + msg's offset within that page
```

1. **`adrp`** ("address of page") computes the address of the 4096-byte
   *page* containing `msg`: the address with its low 12 bits set to zero. It
   can reach anything within 4 GiB of the instruction.
2. **`add`** adds the low 12 bits of `msg`'s address (`:lo12:msg` means
   exactly that: "the lowest 12 bits of the address of msg").

Together they give the full address. You will write this pair constantly, so
just learn its shape: `adrp reg, label` then `add reg, reg, :lo12:label`.

`add` is new; it is covered fully in lesson 07. For now, `add x1, x1, N`
means `x1 = x1 + N`.

There is also a single instruction, `adr x1, msg`, which works if `msg` is
within 1 MiB of the instruction. It often works in small programs, but it
depends on where the linker puts things. The `adrp`/`add` pair always works,
so this course uses it.

### Pointing into the middle of a string

An address is just a number. If `x1` points at `H`, then `x1 + 7` points at
`w`:

```
offset:  0 1 2 3 4 5 6 7 8 9 10 11 12 13
byte:    H e l l o ,   w o r l d  !  \n
```

Exercise 05.6 uses this to print only "world". This is pointer arithmetic, the
same as `msg + 7` in C.

## Several writes

Each `write` prints one run of bytes. To print two separate strings, call
`write` twice, as in `examples/two_lines.s`. Notice that the second call sets
`x0` to 1 **again**. Why?

## System calls return a value

After `svc #0`, the kernel puts a **result** in `x0`. For `write`, the result
is the number of bytes actually written (or a negative error code if
something went wrong). Your fd number in `x0` is gone.

`examples/result.s` writes 6 bytes and then calls `exit` *without* setting
`x0`, so the exit status is whatever `write` returned:

```console
# ./result; echo $?
12345
6
```

Rule: **assume every `svc` changes `x0`**. Set all the argument registers
before every system call.

## C to assembly

| C | Assembly (Linux) |
|---|------------------|
| `char msg[] = "Hi\n";` (global) | `.data` / `msg: .ascii "Hi\n"` |
| `const char msg[] = "Hi\n";` | `.section .rodata` / `msg: .ascii "Hi\n"` |
| a string literal's hidden zero byte | `.asciz` |
| `#define LEN 14` | `.equ LEN, 14` |
| `sizeof msg` | `. - msg` right after the string |
| `p = msg;` | `adrp x1, msg` / `add x1, x1, :lo12:msg` |
| `p = msg + 7;` | then `add x1, x1, #7` |
| `n = write(1, p, len);` | `mov x0, #1` / (x1 = p) / `mov x2, #len` / `mov x8, #64` / `svc #0`; result in `x0` |

## Common mistakes

- **Wrong length.** Too short cuts the message off. Too long prints whatever
  bytes come after it in memory: garbage, or the next message.
- **Forgetting the `\n`.** The output runs into your shell prompt.
- **`mov x1, msg` instead of `adrp`/`add`.** `mov` cannot load an address.
  Worse, GNU `as` does not always complain: it can quietly assemble this as
  `mov x1, #0`, so `write` gets address 0 and prints nothing. Always use the
  `adrp`/`add` pair.
- **Forgetting `add` after `adrp`.** `x1` points to the start of the page, not
  to your string. You print the wrong bytes, often nothing visible.
- **Not resetting `x0` before the next system call.** The previous call's
  result is in `x0`, not your fd.
- **Using `.asciz` and counting the zero byte.** You print a zero byte; it
  is invisible on screen but shows up if you pipe the output to `xxd`.
- **Putting the `.equ` in the wrong place.** `. - msg` must come immediately
  after the string it measures.

## Recap

- `write(fd, buf, count)`: number 64 in `x8`; `fd` in `x0`, address in `x1`,
  count in `x2`. It copies bytes; it knows nothing about strings.
- fd 0 is stdin, 1 is stdout, 2 is stderr.
- `.data` holds writable data, `.section .rodata` holds constants, `.text` holds
  code.
- `.ascii` stores characters; `.asciz` adds a zero byte at the end.
- `.` is the current address; `. - label` is the size since `label`.
  `.equ` names a constant.
- Load an address with `adrp reg, label` then `add reg, reg, :lo12:label`.
- A system call returns its result in `x0`, overwriting what was there.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
