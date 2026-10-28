# Lesson 14 on macOS: Functions

Read [the main lesson](../README.md) first. `bl`,
`ret`, `x30`, the frame record, prologues and epilogues, and leaf versus
non-leaf are **identical** on your Mac. The examples differ only in the
boilerplate (`_main`, `x16`/`svc #0x80`).

```console
$ cd lessons/14-functions/apple-silicon/examples && make
$ ./lost_return; echo $?
3
$ ./fixed_return; echo $?
1
$ ./print_uint
1 4 9 16 25
```

## `_main` is a function on macOS

There is one real difference. On Linux, `_start` is not called by anyone:
it has no return address and must end with `exit`. On macOS, `_main` **is
called**, by `dyld`'s startup code, with a valid return address in `x30`. That
means a macOS `_main` could, in principle, end with `ret` instead of a raw
`exit` system call, and the process would exit with `x0` as its status.

We still end every `_main` with `exit` until lesson 16, to keep the two flavors
the same. But note the consequence for the examples: **`_main` calls
functions, so it overwrites `x30`**. If you wanted `_main` to return, it would
need its own prologue and epilogue, exactly like any other non-leaf function.
Lesson 16 does that properly.

## The backtrace in lldb

```console
$ lldb ./frame
(lldb) b square
(lldb) run
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
  * frame #0: 0x0000000100000318 frame`square
    frame #1: 0x00000001000002fc frame`sum_squares + 16
    frame #2: 0x00000001000002e4 frame`main + 12
```

Same chain as gdb shows: `main` called `sum_squares`, which called `square`.
lldb shows it as `main` (the C name of `_main`). Use `register read lr` (or
`x30`) and `disassemble -s $lr -c 1` to see where `x30` points.

| gdb | lldb |
|-----|------|
| `bt` | `bt` |
| `p/x $x30` | `register read lr` |
| `x/i $x30` | `disassemble -s $lr -c 1` |
| `finish` (run until this function returns) | `finish` |
| `ni` (step over a `bl`) | `ni` |

## Exercises

Do the [main lesson's exercises](../exercises.md) as
macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
