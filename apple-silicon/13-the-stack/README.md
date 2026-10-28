# Lesson 13 on macOS: The stack

Read [the main lesson](../../lessons/13-the-stack/README.md) first. The stack,
the 16-byte rule, `sub`/`add sp`, push and pop with `stp`/`ldp`, frames, and
local arrays all work **identically** on your Mac. The examples differ only
in the boilerplate (`_main`, `x16`/`svc #0x80`).

```console
$ cd apple-silicon/13-the-stack/examples && make
$ ./push_pop; echo $?
236
$ echo hello | ./reverse_line
olleh
```

## Differences you will notice

**Where the stack is.** `register read sp` in lldb shows an address like
`0x000000016fdfd600`. On macOS the stack sits lower in the address space than
on Linux, and the main thread's stack is also 8 MiB by default.

**Signal numbers.** A misaligned `sp` still gives a bus error, but macOS
numbers its signals differently: `SIGBUS` is signal 10, so

```console
$ ./misaligned; echo $?
138
```

(128 + 10) where Linux shows 135. `SIGSEGV` is 11 on both, so `overflow`
exits with 139 on both.

**The red zone.** On Linux, memory below `sp` is never safe to use. Apple's
ABI reserves a 128-byte *red zone* below `sp` that the system promises not to
touch, so leaf code may use it without moving `sp`. Do not rely on it: the
habit of always reserving space with `sub sp` works everywhere, and this
course never uses the red zone.

**`dyld` was here first.** On Linux, `_start` is the first code to run, so
`sp` points at the very top of the stack. On macOS, `dyld` has already used
some stack before calling `_main`. That changes nothing in these programs:
just never assume what is above `sp` when you start.

## Viewing the stack in lldb

```console
$ lldb ./push_pop
(lldb) b main
(lldb) run
(lldb) si -c 6
(lldb) x/4gx $sp
0x16fdfd600: 0x000000000000001e 0x0000000000000028
0x16fdfd610: 0x000000000000000a 0x0000000000000014
```

## Exercises

Do the [main lesson's exercises](../../lessons/13-the-stack/exercises.md) as
macOS programs. The answers are the same, except that exercise 13.8's crash
exits with 138. macOS solutions are in [solutions/](solutions/).

One trap from writing these: **do not name a label after a register**. A loop
label like `d1:` works on Linux, but clang reads `d1` as the floating-point
register `d1`, and `cbnz x19, d1` fails with
`error: expected label or encodable integer pc offset`. Use names like
`digit1`.
