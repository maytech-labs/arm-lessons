# Lesson 05 on macOS: Hello, world

Read [the main lesson](../../lessons/05-hello-world/README.md) first. The
`write` system call, file descriptors, `.ascii`/`.asciz`, escapes, `. - msg`,
`.equ`, and the `adrp` + `add` idea are all the same. Three things change.

| | Linux | macOS |
|-|-------|-------|
| `write` number | 64 in `x8` | 4 in `x16` |
| Read-only data | `.section .rodata` | `.section __TEXT,__const` |
| Low bits of an address | `add x1, x1, :lo12:msg` | `add x1, x1, msg@PAGEOFF` |
| Page of an address | `adrp x1, msg` | `adrp x1, msg@PAGE` |

## The program

`examples/hello.s`:

```asm
    .global _main

    .data                           // initialised data goes here
msg:
    .ascii "Hello, world!\n"        // the 14 bytes we will print
    .equ msg_len, . - msg           // msg_len = (here) - (start of msg) = 14

    .text
    .p2align 2
_main:
    mov x0, #1                      // argument 1: file descriptor 1 = stdout
    adrp x1, msg@PAGE               // argument 2: the address of msg...
    add x1, x1, msg@PAGEOFF         // ...built in two steps (see the lesson)
    mov x2, #msg_len                // argument 3: how many bytes to write
    mov x16, #4                     // 4 = write
    svc #0x80                       // write(1, msg, 14)

    mov x0, #0                      // exit status 0: success
    mov x16, #1                     // 1 = exit
    svc #0x80                       // exit(0)
```

```console
$ cd apple-silicon/05-hello-world/examples && make
$ ./hello
Hello, world!
```

## `@PAGE` and `@PAGEOFF`

Same instructions, different spelling. `adrp` still finds the 4 KiB page and
`add` still adds the offset within it. Apple's assembler writes the two parts
as suffixes on the symbol:

- `msg@PAGE`: the page containing `msg` (Linux just writes `msg`)
- `msg@PAGEOFF`: the offset of `msg` within its page (Linux: `:lo12:msg`)

Forgetting `@PAGE` on the `adrp` is an error on macOS, so you will notice.

## Sections in Mach-O

Mach-O names its sections with two parts, *segment,section*:

| Linux (ELF) | macOS (Mach-O) | Holds |
|-------------|----------------|-------|
| `.text` | `__TEXT,__text` | code |
| `.data` | `__DATA,__data` | writable initialised data |
| `.rodata` | `__TEXT,__const` | read-only constants |
| (also `.rodata`) | `__TEXT,__cstring` | only zero-terminated strings |

`.text` and `.data` work as shorthands on both systems. For read-only data
write `.section __TEXT,__const`. Avoid `__TEXT,__cstring` unless every item in
it is an `.asciz` string: the linker merges and reorders its contents
assuming each item ends with a zero byte, and an `.ascii` string without one
gets glued onto the next.

To look at the bytes:

```console
$ objdump -s -j __const asciz
Contents of section __TEXT,__const:
 100000364 61736369 690a6173 63697a0a 00        ascii.asciz..
```

The same bytes as on Linux, at a different address.

## Exercises

Do the [main lesson's exercises](../../lessons/05-hello-world/exercises.md) as
macOS programs: `_main`, `x16`, `svc #0x80`, write = 4, exit = 1,
`__TEXT,__const`, `@PAGE`/`@PAGEOFF`. macOS solutions are in
[solutions/](solutions/).

Differences in the answers:

- **05.3.3** (delete the `add`): `adrp` alone gives the page start; what you
  see depends on layout, as on Linux.
- **05.3.5** (fd 0): same idea; `./hello < /dev/null` prints nothing.
- **05.7**: macOS reports system call errors differently. Instead of a
  negative number, the kernel sets the **carry flag** and puts a positive error
  number in `x0`. With fd 7, `x0` is 9 (`EBADF`), so `echo $?` shows `9`, not
  247. Lesson 09 explains flags; lesson 25 handles errors properly.
