# Lesson 04 on macOS: Your first program

Read [the main lesson](../README.md) first. Every
idea in it applies on your Mac: comments, directives, labels, `mov`, system
calls, exit status mod 256, and crashing when you forget to exit. Only four
things change:

| | Linux | macOS |
|-|-------|-------|
| Entry point | `_start` | `_main` |
| System call number register | `x8` | `x16` |
| `exit` number | 93 | 1 |
| System call instruction | `svc #0` | `svc #0x80` |

## The whole program

`examples/exit42.s`:

```asm
    .global _main               // make the name _main visible to the linker
    .text                       // what follows is code
    .p2align 2                  // start on a 4-byte boundary (2^2)

_main:                          // the program begins here
    mov x0, #42                 // x0 = 42: the exit status we want
    mov x16, #1                 // x16 = 1: macOS's number for the exit system call
    svc #0x80                   // ask the kernel to run system call x16 with argument x0
```

```console
$ cd lessons/04-first-program/apple-silicon/examples
$ make
clang -g -arch arm64 -o exit42 exit42.s
...
$ ./exit42; echo $?
42
```

### Why `_main` and not `_start`?

On Linux we built a program with no C library at all, so our code was the
very first thing to run. macOS does not allow that: every program is linked
against **libSystem** (Apple's C library) and is started by the system's
loader, `dyld`, which then calls a function named `main`.

C compilers on macOS add an underscore to every C name, so the C function
`main` is the symbol `_main` in assembly. You will see this underscore on
every C-visible name from now on (`_printf`, `_exit`, ...).

Nothing else about this program uses the C library. Starting at `_main` just
means "dyld calls us". We still end the program ourselves with a system call.

### macOS system calls

| Step | Linux | macOS |
|------|-------|-------|
| Number goes in | `x8` | `x16` |
| Arguments go in | `x0`, `x1`, ... | `x0`, `x1`, ... (same) |
| Trap instruction | `svc #0` | `svc #0x80` |

macOS's numbers come from its BSD heritage: `exit` is 1, `read` 3, `write` 4.

**Important caveat:** Linux promises that its system call numbers never
change. Apple does not: the supported interface is the C library, and raw
`svc` calls may break in a future macOS. `exit`, `read`, and `write` have had
the same numbers for decades, so they are fine for learning. From lesson 16
on, both flavors call the C library instead
([decision 0005](../../../docs/decisions/0005-raw-syscalls-before-libc.md)).

## The other examples

`copy.s`, `wrap.s`, and `no_exit.s` are line-for-line the same as on Linux,
with the entry point and system call changed.

```console
$ ./copy; echo $?
7
$ ./wrap; echo $?
44
$ ./no_exit; echo $?
132
```

`no_exit` dies with `SIGILL` (illegal instruction), status 132, the same as on
Linux. The shell may print nothing else; the status is your clue.

## Assembling and linking by hand

The assembler step works the same way:

```console
$ as -o exit42.o exit42.s
$ file exit42.o
exit42.o: Mach-O 64-bit object arm64
$ nm exit42.o
0000000000000000 T _main
0000000000000000 t ltmp0
$ objdump -d exit42.o
0000000000000000 <ltmp0>:
       0: d2800540      mov     x0, #0x2a               ; =42
       4: d2800030      mov     x16, #0x1               ; =1
       8: d4001001      svc     #0x80
```

- The file format is **Mach-O**, not ELF.
- `ltmp0` is a temporary local label the assembler adds at the start of the
  section; ignore it. `objdump` happens to name the code after it.
- Apple's `objdump` writes comments with `;` instead of `//`. Your source
  files still use `//`.
- The machine code for `mov x0, #42` is `d2800540` on both systems: same CPU,
  same instruction.

The linker step needs more on macOS, because every program must link against
libSystem:

```console
$ ld -o exit42 exit42.o -lSystem -syslibroot "$(xcrun --show-sdk-path)" -e _main
$ ./exit42; echo $?
42
```

| Flag | Meaning |
|------|---------|
| `-lSystem` | Link against libSystem. Required for every macOS program. |
| `-syslibroot ...` | Where to find libSystem: inside the SDK that Xcode installed. |
| `-e _main` | Make `_main` the entry point. |

This is exactly why we let `clang` drive the linker: it knows all of this.

## Exercises

Do the [main lesson's exercises](../exercises.md)
as macOS programs, with these changes:

- Use `_main`, `x16`, `1`, and `svc #0x80` everywhere the exercise expects
  `_start`, `x8`, `93`, and `svc #0`.
- **04.4**: read the program as if it were macOS code: the answer is the same.
- **04.5**: use the `as` and `ld` commands above. Removing `.global _main`
  gives a different result on macOS: the link fails with

  ```
  Undefined symbols for architecture arm64:
    "_main", referenced from:
        <initial-undefines>
  ```

  macOS does not guess an entry point. Without a global `_main`, there is no
  program.
- **04.7**: clang's assembler words its errors differently:

  | Mistake | clang says |
  |---------|------------|
  | `mov x0 #42` | `error: unexpected token in argument list` |
  | `move x0, #42` | `error: unrecognized instruction mnemonic, did you mean: fmov, mov, ...` |
  | `_main` without colon | `error: unrecognized instruction mnemonic` |
  | `mov x31, #42` | **no error!** clang treats `x31` as `xzr`, so the value is thrown away |

  The last one is a trap: the program builds and silently does nothing useful.
  Never write `x31`.

macOS solutions are in [solutions/](solutions/). Written answers are the same
as the [Linux flavor's](../answers.md),
except for the 04.5 and 04.7 differences above.
