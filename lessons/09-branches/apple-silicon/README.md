# Lesson 09 on macOS: Flags and branches

Read [the main lesson](../README.md) first. Flags,
`cmp`, every condition code, `cbz`/`tbz`, and every translation pattern are
**identical** on your Mac. The examples differ only in the lesson 04
boilerplate.

```console
$ cd lessons/09-branches/apple-silicon/examples && make
$ ./elseif; echo $?
66
```

## Seeing the flags in lldb

lldb shows the flags register as a number rather than a list:

```console
$ lldb ./flags
(lldb) b main
(lldb) run
(lldb) si -c 3
(lldb) register read cpsr
    cpsr = 0x60000000
```

The flags are the top four bits of `cpsr`: bit 31 is N, 30 is Z, 29 is C,
28 is V. Read the first hex digit in binary:

| First hex digit | Binary (N Z C V) | Flags set |
|-----------------|------------------|-----------|
| `6` | `0110` | Z C |
| `8` | `1000` | N |
| `9` | `1001` | N V |
| `2` | `0010` | C |
| `0` | `0000` | none |

So `0x60000000` is Z and C, matching gdb's `[ C Z ]`. Exercise 09.1 is good
practice at reading these.

## Exercises

Do the [main lesson's exercises](../exercises.md) as
macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
