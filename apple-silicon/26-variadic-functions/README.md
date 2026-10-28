# Lesson 26 on macOS: Variadic functions

Do [lesson 26](../../lessons/26-variadic-functions/README.md) first. This page
covers what is different on Apple Silicon, and here the difference is large:
Apple changed the variadic part of the calling convention, and the result is
much simpler than the Linux design.

## The one rule

On macOS arm64:

> **Named arguments are passed as usual (`x0`-`x7`, `d0`-`d7`). Every variadic
> argument, of any type, goes on the stack in its own 8-byte slot, in order,
> starting at `[sp]` at the moment of the call.**

You have been following this rule since lesson 16 every time you called
`printf`. This lesson looks at it from the other side: what it means for the
function that *receives* the `...`.

## Calling a variadic function (recap)

For

```c
printf("%d + %d = %d, pi is about %.2f, name %s\n", 2, 3, 5, 3.14159, "Ada");
```

the format is the only named argument, so it goes in `x0`. The other five are
variadic:

```
    [sp, #0]    2
    [sp, #8]    3
    [sp, #16]   5
    [sp, #24]   3.14159   (the 8 bytes of the double, stored with str d0)
    [sp, #32]   "Ada"     (the pointer)
```

Five slots are 40 bytes; `sp` must stay 16-byte aligned, so reserve 48. Nothing
goes in `x1`-`x4` or `d0`. If you put the double only in `d0`, `printf` prints
garbage (often `0.00`).

[examples/callvar.s](examples/callvar.s) makes this call and a second one with
nine ints (nine slots, 72 bytes, reserved as 80):

```console
$ make callvar
$ ./callvar
2 + 3 = 5, pi is about 3.14, name Ada
1 2 3 4 5 6 7 8 9
```

Compare with the Linux version: there, the first call uses no stack at all.

## `va_list` on macOS is a `char *`

Since every variadic argument is already in memory, in a row, 8 bytes apart,
the callee has nothing to collect. No register save area, no offsets. Apple's
`<stdarg.h>` defines

```c
typedef char *va_list;
```

and the macros become:

| C | What it does on macOS | Assembly |
|---|-----------------------|----------|
| `va_start(ap, last)` | `ap` = address of the first variadic slot = `sp` on entry | `mov x9, sp` (before moving `sp`) or `add x9, sp, #FRAME` (after the prologue) |
| `va_arg(ap, int)` | read 4 bytes at `ap`, `ap += 8` | `ldr w0, [x9], #8` |
| `va_arg(ap, long)` / pointer | read 8 bytes, `ap += 8` | `ldr x0, [x9], #8` |
| `va_arg(ap, double)` | read 8 bytes as a double, `ap += 8` | `ldr d0, [x9], #8` |
| `va_copy(b, a)` | `b = a` | `mov x10, x9` |
| `va_end(ap)` | nothing | |

Post-indexed addressing (lesson 11) is exactly `va_arg`: load from the
pointer, then advance it by one slot.

## `sum` on macOS

Open [examples/sum.s](examples/sum.s). The whole function:

```asm
_sum:
    mov     x9, sp                  // va_start: x9 = ap = first variadic slot
    mov     w11, #0                 // total
loop:
    cmp     w0, #0
    b.le    done
    ldr     w10, [x9], #8           // va_arg(ap, int): load 4 bytes, step one slot
    add     w11, w11, w10
    sub     w0, w0, #1
    b       loop
done:
    mov     w0, w11
    ret
```

`sum` calls nothing and never moves `sp`, so it is a leaf with no frame: `sp`
on entry is simply `sp`. Compare the Linux version's 112-byte frame, register
spills and five-field struct.

The C test driver [examples/sum_test.c](examples/sum_test.c) is identical to
the Linux one. Clang does the calls for you, putting all the extra ints on the
stack.

```console
$ make sum
$ ./sum
sum(0) = 0
sum(3, 10, 20, 30) = 60
sum(7, 1..7) = 28
sum(10, 1..10) = 55
sum(4, -5, 100, -20, 1) = 76
```

Clang agrees with us. `clang -O1 -S -o - sum.c` (the C is in the header of
`sum.s`) gives:

```asm
_sum:
    sub     sp, sp, #16
    add     x8, sp, #16
    str     x8, [sp, #8]            // ap = sp on entry (clang keeps ap in memory)
    cmp     w0, #1
    b.lt    LBB0_3
    mov     w8, #0
LBB0_2:
    ldr     x9, [sp, #8]
    add     x10, x9, #8
    str     x10, [sp, #8]           // ap += 8
    ldr     w9, [x9]                // the int
    add     w8, w9, w8
    subs    w0, w0, #1
    b.ne    LBB0_2
    ...
```

## The `int` slot trap

An `int` occupies a whole 8-byte slot, but only its low 4 bytes are defined.
Always read it with `ldr w` (or `ldrsw` to sign-extend), never `ldr x`. The
callers in this lesson store ints with `str x9` after `mov x9, #-5`, which
happens to fill the whole slot, but clang may store only 4 bytes.

## `myprintf` on macOS

[examples/myprintf.s](examples/myprintf.s) has the same structure as the
Linux version, minus all the `va_list` machinery. The cursor lives in a
callee-saved register, `x22`, because it must survive the `putchar` calls:

```asm
    add     x22, sp, #FRAME                 // va_start: x22 = ap
    ...
conv_d:
    ldrsw   x0, [x22], #8                   // va_arg(ap, int), sign-extended
    bl      print_signed
    ...
conv_s:
    ldr     x0, [x22], #8                   // va_arg(ap, char *)
```

`add x22, sp, #FRAME` runs after the prologue moved `sp` down by `FRAME`
bytes, so it gives back `sp` on entry. There is no "spill the registers
first" rule to remember: `x1`-`x7` are not used at all.

The C driver is the same file as on Linux:

```console
$ make myprintf
$ ./myprintf
int 42, negative -7, hex ff, char A, string hi, 100%
int 42, negative -7, hex ff, char A, string hi, 100%
myprintf returned 53, printf returned 53
1 2 3 4 5 6 7 8 9 10
1 2 3 4 5 6 7 8 9 10
-2147483648 2147483647 ffffffff
-2147483648 2147483647 ffffffff
unknown %q stays, (null) string
```

[examples/pfdemo.s](examples/pfdemo.s) calls `_myprintf` from assembly. It
puts every variadic argument on the stack, exactly as for `_printf`:

```console
$ make pfdemo
$ ./pfdemo
Ada is 36 years old (0x24), grade A
1 2 3 4 5 6 7 8 9
```

## Forwarding to `vfprintf`

Since `va_list` is a pointer, forwarding is simple:

```asm
_logmsg:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0                         // fmt
    add     x20, sp, #32                    // va_start: x20 = ap = sp on entry
    ... fputs("[log] ", stderr) ...
    ... x0 = stderr ...
    mov     x1, x19
    mov     x2, x20                         // va_list is a pointer: pass it as is
    bl      _vfprintf
```

Three points:

- **No FP registers to save.** On Linux, `logmsg` had to save `q0`-`q7` in case
  the format contained `%f`. On macOS the doubles are already on the stack.
- **`vfprintf` itself is not variadic.** Its three parameters are named, so they
  go in `x0`, `x1`, `x2` as usual. Only `...` parameters go on the stack.
- **`stderr` is `___stderrp`**, loaded through the GOT (lesson 25).

[examples/vforward.s](examples/vforward.s):

```console
$ make vforward
$ ./vforward
[log] 3 apples cost 1.25 dollars (cheap)
[log] progress: 37.5% of 80, then 0.667
```

## Why Apple did this

The standard AAPCS64 design makes calls to variadic functions as cheap as normal
calls, but makes the variadic function itself complicated. Apple chose the
reverse: the callee is trivial, `va_list` is a pointer, and `va_arg` is one load.
The cost is a different calling sequence at the call site, and you have
already paid that: **calling a variadic function as if it were not variadic is
a real bug on macOS.** If you declare `int sum();` (no prototype) or cast
`printf` to a non-variadic function pointer type, the compiler passes the
arguments in registers and the callee reads garbage from the stack.

## Differences from the main lesson, summarised

| | Linux AArch64 | macOS arm64 |
|-|---------------|-------------|
| Variadic arguments at the call | registers like normal, then stack | always stack, 8-byte slots |
| Variadic doubles | `d0`-`d7`, then stack | stack |
| `va_list` | 32-byte struct | `char *` |
| `va_start` | spill `x1`-`x7`, `q0`-`q7`; fill 5 fields | `ap = sp on entry` |
| `va_arg(ap, int)` | check `__gr_offs`, pick save area or stack | `ldr w, [ap], #8` |
| `va_copy` | copy 32 bytes | copy a pointer |
| Pass a `va_list` to `vfprintf` | address of the struct | the pointer itself |
| Stack slot per variadic argument | 8 bytes | 8 bytes |

## Exercises

Do the exercises from the main lesson's
[exercises.md](../../lessons/26-variadic-functions/exercises.md) as macOS
programs. The expected output is the same. Some are much shorter here: in
26.7 there is no VR save area, and in 26.6 `va_copy` is one `mov`. For 26.2,
answer for Linux as asked, then think about what the macOS answers would be
(there is no save area, and all seven extra ints are on the stack).

macOS solutions are in [solutions/](solutions/); the written answers are in the
main lesson's [solutions/README.md](../../lessons/26-variadic-functions/solutions/README.md).
Note `print_result` in `solutions/ex3.s` and `print_double` in `solutions/ex7.s`:
small helpers that put one value in `printf`'s stack slot, so `main` does not
repeat the same five lines for every call.

## Common mistakes on macOS

- **Reading variadic arguments from `x1`-`x7`.** They are not there. On macOS
  those registers hold leftovers from before the call.
- **Taking `ap` after the prologue without adding the frame size.** `mov x9, sp`
  after `stp x29, x30, [sp, #-32]!` points at your saved `x29`, not at the
  first argument. Use `add x9, sp, #32`.
- **Labels named like registers.** Clang's assembler reads `s1@PAGEOFF` as the
  register `s1` followed by junk ("unexpected token in argument list"). Do not
  name labels `s0`-`s31`, `d0`-`d31`, `x0`-`x30`, `w0`-`w30`, `q0`-`q31`,
  `b0`-`b31` or `h0`-`h31`.
- **Passing a double variadic argument in `d0` only.** Store it on the stack.
