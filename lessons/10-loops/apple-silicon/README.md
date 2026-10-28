# Lesson 10 on macOS: Loops

Read [the main lesson](../README.md) first. Loops,
invariants, `break`/`continue`, `csel` and friends, and `switch` chains are
**identical** on your Mac. The examples differ only in the boilerplate from
lessons 04 and 05: `_main`, `x16` with `svc #0x80` (write = 4, exit = 1), and
`@PAGE`/`@PAGEOFF`.

```console
$ cd lessons/10-loops/apple-silicon/examples && make
$ ./triangle
*
**
***
****
*****
```

## Registers across system calls

The lesson keeps loop counters in `x19` and up. On macOS this matters more
than on Linux: the kernel returns results in `x0` and `x1`, uses `x16` for the
call number, and Apple does not document which other registers survive a raw
system call. `x19`-`x28` are safe on both systems.

## Watching a loop in lldb

```console
$ lldb ./sum
(lldb) b main
(lldb) run
(lldb) target stop-hook add -o "register read x0 x2"
(lldb) si
```

Each step now prints `x0` (the sum) and `x2` (`i`). For exercise 10.1, put a
label `loop` in your program and use `b loop` then `c` repeatedly.

## Exercises

Do the [main lesson's exercises](../exercises.md) as macOS
programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
