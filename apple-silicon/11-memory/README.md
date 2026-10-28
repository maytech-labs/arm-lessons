# Lesson 11 on macOS: Memory

Do [lesson 11](../../lessons/11-memory/) first. Every load, store, addressing
mode, `ldp`/`stp`, alignment rule and byte order in it is exactly the same on
your Mac. This page covers the few things around them that differ, then walks
through the macOS versions of the examples.

```console
$ cd apple-silicon/11-memory/examples
$ make
```

## What is different

| Topic | Linux | macOS |
|-------|-------|-------|
| `read` system call | `x8 = 63`, `svc #0` | `x16 = 3`, `svc #0x80` |
| `write` / `exit` | 64 / 93 | 4 / 1 |
| Registers changed by a system call | only `x0` | **`x0` and `x1`** (and the carry flag) |
| Zero-filled data | `.bss` + `.space` | `.bss` + `.space` works too; `.zerofill` is the native form |
| Addresses | `adrp` + `:lo12:` | `adrp sym@PAGE` + `add sym@PAGEOFF` |
| Debugger breakpoints in `.s` files | `break 25` (by line) works | by line does **not** work; break on a label |

Nothing else changes. In particular, AArch64 on macOS is little-endian too, and
misaligned ordinary loads work but are slower, just as on Linux.

## A system call can change `x1`

This is the important one. On Linux a system call returns its result in `x0`
and leaves every other register alone. The BSD system call interface that macOS
inherited can return *two* values, in `x0` and `x1`, so the kernel writes `x1`
on the way back, even for calls like `read` that only have one result.

Try it. Copy `examples/echo.s` to `work/echo_bug.s` (with the Makefile), and
delete the two "load the buffer address again" lines, so it looks like this:

```asm
    mov x16, #3                 // 3 = read
    svc #0x80                   // x0 = number of bytes actually read

    mov x19, x0
    mov x2, x0
    mov x0, #1                  // fd 1 = stdout
                                // x1 "is still the buffer address" (it is not)
    mov x16, #4                 // 4 = write
    svc #0x80
```

```console
$ echo hello | ./echo_bug; echo $?
6
```

It read 6 bytes and printed nothing. In lldb, look at `x1` just before and just
after the `read` (five instructions take you to the `svc`):

```console
$ echo hello > in.txt
$ lldb ./echo_bug
(lldb) b main
(lldb) process launch -i in.txt
(lldb) si -c 5
(lldb) register read x1
      x1 = 0x0000000100004000  echo_bug`buf
(lldb) si
(lldb) register read x0 x1
      x0 = 0x0000000000000006
      x1 = 0x0000000000000000
```

The `write` then asked the kernel to print 6 bytes from address 0. The kernel
refused (it returned an error, which we did not check) and nothing appeared.

That is why every program in this course reloads `x1` after a system call, on
both platforms. Rule: **after `svc`, only trust registers other than `x0` and
`x1`.** (`x2` to `x17` and `x19` and up are preserved.)

This is also one reason Apple says raw system calls are not a stable interface:
from lesson 16 on you will call `read` and `write` in libSystem, which follow the
normal function-call rules from lesson 15 instead.

## `.bss` and `.zerofill`

The Linux spelling works unchanged:

```asm
    .bss
buf:
    .space 27
```

The assembler puts `buf` in the Mach-O section `__DATA,__bss`, which is marked
"zero fill": it takes no space in the file. You can check it with `size -m`:

```console
$ size -m bss
Segment __PAGEZERO: 4294967296 (zero fill)
Segment __TEXT: 16384
	Section __text: 68
	total 68
Segment __DATA: 16384
	Section __bss: 27 (zerofill)
	total 27
...
```

You will also see the native Mach-O directive in Apple's own code and in
compiler output. It does the label, the size and the alignment in one line,
without switching sections:

```asm
    .zerofill __DATA,__bss,buf,27,0     // segment,section,symbol,size,log2(align)
```

The last number works like `.p2align`: `3` would mean "8-byte aligned". Both
forms produce the same result; the examples use `.bss` + `.space` so the code
matches the main lesson.

(`__PAGEZERO` is 4 GiB of address space at the bottom of memory that is not
mapped at all. Any load or store to an address below `0x100000000` crashes,
which catches null pointers and "I used a number as an address" bugs
immediately.)

## lldb instead of gdb

Line-number breakpoints do not resolve for assembly files built this way, so
break on `main` or on a label, and step with `si`. (`_main` is written `main` in
lldb: it hides the leading underscore.)

| Lesson's gdb command | lldb |
|----------------------|------|
| `break _start` | `b main` |
| `break done` | `b done` (labels are symbols, so they work) |
| `break 25` | `b main` then `si -c 6` (step 6 instructions) |
| `run` | `run` (`process launch -i file` to feed a file as stdin) |
| `stepi 7` | `si -c 7` |
| `info registers x1 x2` | `register read x1 x2` |
| `x/8xb &target` | `x/8xb &target` (the same) |
| `x/1xw &number` | `x/1xw &number` |

To see the four sizes from `sizes.s`:

```console
$ lldb ./sizes
(lldb) b main
(lldb) run
(lldb) si -c 6
(lldb) register read x1 x2 x3 x4
      x1 = 0x0000000000000088
      x2 = 0x0000000000007788
      x3 = 0x0000000055667788
      x4 = 0x1122334455667788
```

And little-endian order, from `endian.s`:

```console
$ lldb ./endian
(lldb) b main
(lldb) run
(lldb) x/4xb &number
0x100004000: 0x44 0x33 0x22 0x11
(lldb) x/1xw &number
0x100004000: 0x11223344
```

## The examples on macOS

Each file in [examples/](examples/) is the Linux program with the platform
plumbing swapped. Expected results are the same as in the main lesson.

| Program | Run | Expect | Notes |
|---------|-----|--------|-------|
| `counter.s` | `./counter; echo $?` | 42 | |
| `sizes.s` | `./sizes; echo $?` | 136 | registers via lldb, above |
| `stores.s` | `./stores; echo $?` | 221 | `b main`, `si -c 7`, `x/8xb &target` |
| `directives.s` | `./directives; echo $?` | 100 | |
| `signext.s` | `./signext; echo $?` | 1 | `b done`, `run`, `register read x1 x2` |
| `endian.s` | `./endian; echo $?` | 68 | |
| `modes.s` | `./modes; echo $?` | 150 | |
| `bytesum.s` | `./bytesum; echo $?` | 36 | |
| `pairs.s` | `./pairs; echo $?` | 42 | |
| `bss.s` | `./bss` | the alphabet | `.bss` lands in `__DATA,__bss` |
| `align.s` | `nm -n align` | `aligned` on a multiple of 8 | |
| `echo.s` | `echo hello \| ./echo` | `hello` | `read` is 3; reloads `x1` |
| `printnum.s` | `./printnum` | `1234567` | |
| `double.s` | `echo 21 \| ./double` | `42` | reloads `x1` after `read` |

The system call lines change like this, everywhere:

```asm
    // Linux                      // macOS
    mov x8, #63                   mov x16, #3      // read
    mov x8, #64                   mov x16, #4      // write
    mov x8, #93                   mov x16, #1      // exit
    svc #0                        svc #0x80
```

and every address load like this:

```asm
    adrp x1, buf                  adrp x1, buf@PAGE
    add x1, x1, :lo12:buf         add x1, x1, buf@PAGEOFF
```

`align.s` shows the same layout as on Linux, at a different address:

```console
$ nm -n align | grep -E 'one|after|aligned'
0000000100004000 d one
0000000100004001 d after
0000000100004008 d aligned
```

## Exercises

Do the exercises in the main lesson's [exercises.md](../../lessons/11-memory/exercises.md)
as macOS programs. macOS versions of every programming solution are in
[solutions/](solutions/); the written answers are in the main lesson's
[solutions/README.md](../../lessons/11-memory/solutions/README.md).
