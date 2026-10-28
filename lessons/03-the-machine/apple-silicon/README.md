# Lesson 03 on macOS: The machine

Read [the main lesson](../README.md) first. The CPU,
the registers, memory, the instruction encodings, and fetch-decode-execute are
**identical** on your Mac. What differs is the operating system's side: the
file format, where programs are placed in memory, how they are started, and
how system calls are made.

## Building the examples

```console
$ cd lessons/03-the-machine/apple-silicon/examples
$ make
clang -g -arch arm64 -o bytes bytes.s
clang -g -arch arm64 -o encoding encoding.s
$ ./encoding; echo $?
42
```

## `encoding.s` on macOS

[examples/encoding.s](examples/encoding.s) differs from the Linux one in
three lines: the start label is `_main` instead of `_start`, and the exit
system call is `mov x16, #1` / `svc #0x80` instead of `mov x8, #93` / `svc #0`.
Lesson 04 explains both.

```console
$ objdump -d encoding

encoding:	file format mach-o arm64

Disassembly of section __TEXT,__text:

00000001000002d8 <_main>:
1000002d8: d2800020    	mov	x0, #0x1                ; =1
1000002dc: d2800040    	mov	x0, #0x2                ; =2
1000002e0: d2800540    	mov	x0, #0x2a               ; =42
1000002e4: d2800541    	mov	x1, #0x2a               ; =42
1000002e8: d2800542    	mov	x2, #0x2a               ; =42
1000002ec: 52800540    	mov	w0, #0x2a               ; =42
1000002f0: d2800030    	mov	x16, #0x1               ; =1
1000002f4: d4001001    	svc	#0x80
```

The first six encodings are exactly the Linux ones: same CPU, same numbers.
Only the last two differ, because they are different instructions.

Two things to notice:

- **Addresses start above `0x100000000`** (4 GiB). macOS reserves the whole
  first 4 GiB of every program's memory as an empty, forbidden area called
  `__PAGEZERO`. Any access to a small address, such as a null pointer, or a
  pointer that lost its upper 32 bits, crashes immediately instead of quietly
  reading garbage. You can see it with `otool -l encoding | grep -A3 PAGEZERO`.
- Apple's `objdump` writes comments with `;` (Linux's uses `//`). Apple's own
  tool, `otool -tv encoding`, shows the same disassembly in an older style.

## `bytes.s` on macOS: section names

Mach-O names sections as **segment, section**: code is in `__TEXT,__text`
and data in `__DATA,__data`. In the assembly source you still write `.text`
and `.data`; the assembler translates. To dump them, use the Mach-O section
names:

```console
$ objdump -s -j __data bytes

bytes:	file format mach-o arm64
Contents of section __DATA,__data:
 100004000 01020304 78563412 486921             ....xV4.Hi!

$ objdump -s -j __text bytes

bytes:	file format mach-o arm64
Contents of section __TEXT,__text:
 100000370 000080d2 300080d2 011000d4           ....0.......
```

The data bytes are identical to Linux: little-endian on both. In the code,
`300080d2` is `mov x16, #1` and `011000d4` is `svc #0x80`.

## The assembler and linker by hand

On macOS `as` is clang's assembler. The linker `ld` needs to be told where
Apple's system library lives, because **every macOS program must be linked
with libSystem**, even one that never calls it:

```console
$ as encoding.s -o encoding.o
$ file encoding.o
encoding.o: Mach-O 64-bit object arm64
$ ld encoding.o -o encoding2 -lSystem -syslibroot "$(xcrun --show-sdk-path)"
$ ./encoding2; echo $?
42
```

Leave out `-lSystem` and `ld` refuses: `dynamic executables or dylibs must
link with libSystem.dylib`. That is why `clang` is the everyday tool: it
adds those options for you. Delete the extra files afterwards.

There is no `readelf` on macOS (it reads ELF only). The entry point is in a
Mach-O *load command* called `LC_MAIN`:

```console
$ otool -l encoding | grep -A3 LC_MAIN
       cmd LC_MAIN
   cmdsize 24
  entryoff 728
 stacksize 0
```

`entryoff` is an offset from the start of the program: 728 = `0x2d8`, and
`0x100000000 + 0x2d8 = 0x1000002d8`, the address of `_main`.

## How macOS starts a program

On Linux, the kernel loads a freestanding program and jumps straight to
`_start`. On macOS there is one more step. The kernel loads your program
*and* Apple's dynamic loader, **dyld**. dyld loads libSystem, sets things up,
and then calls `_main` as if it were a function. That is why macOS programs
always start at `_main`, not `_start`, and why macOS cannot build the fully
self-contained ("static") programs the Linux flavor uses until lesson 16.

## System calls on macOS

The idea is the same; the details differ:

| | Linux | macOS |
|-|-------|-------|
| System call number goes in | `x8` | `x16` |
| Instruction | `svc #0` (`d4000001`) | `svc #0x80` (`d4001001`) |
| `exit` | 93 | 1 |
| `write` | 64 | 4 |

macOS's numbers come from BSD Unix, which macOS descends from. One warning,
repeated in every companion lesson until 16: Apple does **not** promise that
these numbers or this mechanism will stay the same. Real macOS programs call
functions in libSystem (like C's `exit()` and `write()`), which make the
system call for them. We make the system calls directly only while learning,
and switch to libSystem in lesson 16.

## `x18`

On macOS `x18` is reserved: the operating system may change it at any moment.
That is the reason this course never uses it, on either platform.

## Exercises on macOS

Do [the exercises](../exercises.md) in
`lessons/03-the-machine/apple-silicon/work/`, starting from the macOS examples.
Differences:

- **03.1, 03.2, 03.7, 03.9**: identical answers.
- **03.3**: your addresses start near `0x1000002d8`; `svc #0x80` is `d4001001`.
- **03.4**: the encodings are the same as on Linux. Solution:
  [solutions/ex4.s](solutions/ex4.s).
- **03.5**: use `objdump -s -j __data bytes`. Same data bytes. In
  `objdump -s -j __text bytes` the second group is `300080d2`, which is
  `mov x16, #1`.
- **03.6**: use the `as` and `ld` commands above. `file` says `Mach-O 64-bit
  object arm64` and `Mach-O 64-bit executable arm64`. Instead of `readelf -h`,
  use `otool -l encoding | grep -A3 LC_MAIN` and add `entryoff` to
  `0x100000000`. Running `./encoding.o` gives `permission denied`, as on Linux.
- **03.8**: the trace is the same on both systems except for the system call
  instruction; the exit status is 9.
