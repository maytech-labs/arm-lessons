# Lesson 06 on macOS: The debugger (lldb)

Read [the main lesson](../../lessons/06-debugger/README.md) first: the *method*
(predict, stop, look, find the first difference) is identical. macOS uses
**lldb** instead of gdb. lldb understands many gdb-style shortcuts (`si`, `c`,
`x/4xb`, `p/x`), but some commands are different. This page redoes the lesson
in lldb.

```console
$ cd apple-silicon/06-debugger/examples && make
$ lldb ./regs
```

## Starting

lldb has no `starti`. Set a breakpoint on `main` and run:

```console
(lldb) b main
Breakpoint 1: where = regs`main, address = 0x00000001000002d8
(lldb) run
Process 24687 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x00000001000002d8 regs`main
regs`main:
->  0x1000002d8 <+0>:  mov    x0, #0x1                  ; =1
    0x1000002dc <+4>:  mov    x1, #0x2                  ; =2
    0x1000002e0 <+8>:  mov    x2, #0xff                 ; =255
    0x1000002e4 <+12>: mov    x3, x2
```

Note **`b main`**, not `b _main`. lldb shows C-level names, and the C name of
the symbol `_main` is `main` (lesson 04 explained the underscore). `b _main`
gives `WARNING: Unable to resolve breakpoint to any actual locations`, and the
program runs straight to the end.

Every time lldb stops it shows the next few instructions, with `->` on the
next one to run. It shows disassembly rather than your source lines; your
comments are in your editor.

## Stepping and registers

```console
(lldb) si
(lldb) si
(lldb) register read x0 x1 x2
      x0 = 0x0000000000000001
      x1 = 0x0000000000000002
      x2 = 0x000000016fdfdc98
```

`si` steps one instruction, as in gdb. To step several, use `si -c 3`
(gdb's `si 3`).

Look at `x2`: it is not 0. On macOS, our code is called by `dyld`, which has
already used the registers, so they start out holding leftovers. On Linux
they started at zero. Either way: **never rely on a register you did not
set**.

| gdb | lldb |
|-----|------|
| `starti` | `b main` then `run` |
| `si` / `si 3` | `si` / `si -c 3` |
| `info registers` | `register read` (`re r`) |
| `info registers x0 x1` | `register read x0 x1` |
| `p/x $x2` | `p/x $x2` (works) or `register read -f x x2` |
| `p/t $x2` | `register read -f b x2` |
| `set $x0 = 7` | `register write x0 7` |
| `x/3i $pc` | `disassemble -p -c 3` |
| `disassemble` | `disassemble` (`di`) |

```console
(lldb) register read -f b x2
      x2 = 0b0000000000000000000000000000000000000000000000000000000011111111
```

## Examining memory

lldb accepts gdb's `x/NFU` shorthand, so the main lesson's commands mostly
work unchanged:

```console
$ lldb ./hello
(lldb) b main
(lldb) run
(lldb) si -c 3
(lldb) x/s $x1
0x100004000: "Hello, world!\n"
(lldb) x/14xb $x1
0x100004000: 0x48 0x65 0x6c 0x6c 0x6f 0x2c 0x20 0x77
0x100004008: 0x6f 0x72 0x6c 0x64 0x21 0x0a
```

The long form is `memory read`:

```console
(lldb) memory read -c 14 -f x -s 1 $x1      # count 14, hex, size 1 byte
(lldb) memory read -c 14 -f c $x1           # as characters
0x100004000: Hello, world!\n
```

Step over the `svc`; the output appears and `x0` holds the result:

```console
(lldb) si -c 3
Hello, world!
(lldb) register read x0
      x0 = 0x000000000000000e
```

`0xe` is 14.

Byte order, in `bytes`:

```console
(lldb) x/2gx $x1
0x100004008: 0x1122334455667788 0x000000000000002a
(lldb) x/8xb $x1
0x100004008: 0x88 0x77 0x66 0x55 0x44 0x33 0x22 0x11
(lldb) x/4xb &small
0x100004004: 0x01 0x02 0x03 0xff
```

To give a label as the address, write `&small`. A bare `small` is read as "the
value stored at `small`" and used as an address, which fails with
`memory read failed`.

## Breakpoints

| gdb | lldb |
|-----|------|
| `break LABEL` | `b LABEL` |
| `break file.s:23` | `b file.s:23` |
| `run` / `continue` | `run` (`r`) / `continue` (`c`) |
| `info breakpoints` | `breakpoint list` (`br l`) |
| `delete 1` | `breakpoint delete 1` (`br del 1`) |

Labels you add are breakpoint targets, as on Linux (exercise 06.7).

## Watching and the GUI

lldb has no `display`. The closest is a stop hook, which runs a command every
time the program stops:

```console
(lldb) target stop-hook add -o "register read x0 x1 x2"
```

`gui` opens a full-screen view with registers and disassembly (Escape to leave).

## Finding the bug

```console
$ lldb ./broken
(lldb) b main
(lldb) run
(lldb) si -c 5
(lldb) register read x0 x1 x2
      x0 = 0x0000000100004000  msg
      x1 = 0x0000000000000001
      x2 = 0x0000000000000004
```

lldb even labels `x0` as `msg` for you: it holds the address, and the fd is
in `x1`. Swapped, as on Linux.

## Batch mode

lldb can run commands non-interactively, which is handy for checking an
answer:

```console
$ lldb -b -o "b main" -o run -o "si -c 3" -o "register read x2" ./regs
```

## Exercises

Do the [main lesson's exercises](../../lessons/06-debugger/exercises.md) with
lldb commands:

- **06.1**: answers: `b main` + `run`, `si`, `si -c 5`, `p/x $x3`,
  `register read -f b x3`, `x/16xb $x1`, `x/s $x1`, `b loop`,
  `register write x0 99`.
- **06.2**: the "before" values are leftovers from `dyld`, not zeros.
- **06.4**: after the `svc`, macOS reports the error differently: `x0` holds
  `9` (`EBADF`) and the carry flag is set, instead of `-9`.
- **06.5**: `register write x0 7`, then `c`. lldb reports
  `exited with status = 7`.

macOS solutions are in [solutions/](solutions/).
