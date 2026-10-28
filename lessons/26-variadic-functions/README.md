# Lesson 26: Variadic functions

## Goals

After this lesson you can:

- Say exactly where each argument of a variadic call like `printf` goes on Linux
  AArch64, and set up such a call by hand (you have done this since lesson 16;
  now you will know *why* it works).
- Explain what `va_list`, `va_start`, `va_arg`, `va_copy` and `va_end` really do on
  AAPCS64: the five-field `va_list` struct and the register save area.
- Write a variadic function in assembly: `sum(int n, ...)` and a small `myprintf`
  that understands `%d %s %c %x %%`.
- Forward your `...` arguments to `vprintf`/`vfprintf` by building a `va_list` in
  assembly and passing it.
- Test assembly variadic functions by calling them from C.

## Before you start

You need:

- Lesson 15 (AAPCS64: `x0`-`x7`, callee-saved registers, stack arguments).
- Lesson 16 (calling libc, calling assembly from C).
- Lesson 19 (structs: layout, and "a struct bigger than 16 bytes is passed by
  reference").
- Lesson 20 (`.equ`, multi-file programs, Makefiles).
- Lesson 23 (the `d` registers, and that doubles are passed in `d0`-`d7`).
- Lesson 25 (`stderr` through the GOT).

## What "variadic" means

A *variadic* function takes a variable number of arguments. In C you mark it
with `...` after at least one normal ("named") parameter:

```c
int printf(const char *fmt, ...);
int sum(int n, ...);
```

The named parameters (`fmt`, `n`) are ordinary. The `...` part can be zero or
more arguments of any type. Two facts drive everything in this lesson:

1. **The function cannot tell how many arguments it got, or their types.** No
   hidden count is passed. `printf` learns them by reading the format string;
   `sum` is told the count in `n`. If the caller lies (`printf("%d %d", 1)`),
   the function reads garbage. Nothing stops it.
2. **The default argument promotions apply** to everything in `...`: `char` and
   `short` become `int`, `float` becomes `double`. So a variadic function never
   receives a `char` or a `float` through `...`; it asks for `int` or `double`.

Inside the function, C gives you four macros from `<stdarg.h>`:

```c
#include <stdarg.h>

int sum(int n, ...) {
    va_list ap;              // a "cursor" over the unnamed arguments
    va_start(ap, n);         // start just after the last named parameter, n
    int total = 0;
    for (int i = 0; i < n; i++)
        total += va_arg(ap, int);   // fetch the next one, as an int, and advance
    va_end(ap);              // finished with the cursor
    return total;
}
```

`va_list` is just a type, and the macros are compiler built-ins. Our job is to
find out what they turn into. That depends on the ABI, and Linux and macOS
differ a lot here. This lesson teaches Linux (the standard AAPCS64). The
macOS companion shows Apple's much simpler design.

## Part 1: calling a variadic function (recap)

On Linux AArch64, a variadic argument is passed **exactly like a normal
argument of the same type** would be:

- integers and pointers in the next free `x` register (`x1`-`x7` after a
  format string in `x0`);
- `double`s in the next free `d` register (`d0`-`d7`), counted separately
  from the `x` registers;
- when a register class runs out, the rest go on the stack, one 8-byte slot
  each, in order, starting at `[sp]`.

So for

```c
printf("%d + %d = %d, pi is about %.2f, name %s\n", 2, 3, 5, 3.14159, "Ada");
```

the registers are `x0` = format, `x1` = 2, `x2` = 3, `x3` = 5, `d0` = 3.14159,
`x4` = "Ada". Notice the string goes in `x4`, not `x5`: the double used `d0`,
not an `x` register.

Predict: in `printf("%d %d %d %d %d %d %d %d %d\n", 1, 2, ..., 9)`, where do 8
and 9 go?

Look at [examples/callvar.s](examples/callvar.s), then run it:

```console
$ make callvar
$ ./callvar
2 + 3 = 5, pi is about 3.14, name Ada
1 2 3 4 5 6 7 8 9
```

`x0` holds the format, `x1`-`x7` take 1 to 7, and 8 and 9 are stored at
`[sp]` and `[sp, #8]` just before the `bl`. That is the same rule as for any
function with more than eight integer arguments (lesson 15).

> **Aside: x86-64 is different.** If you have seen x86-64 assembly, you may
> remember setting `al` to the number of vector registers used before calling
> `printf`. AArch64 has no such rule. Nothing extra is passed.

## Part 2: what the callee has to solve

Now turn it around. You are writing `sum(int n, ...)` in assembly. When `sum`
starts:

- `w0` = `n`;
- the first seven extra ints are in `x1`-`x7`;
- any more are on the stack at `[sp]`, `[sp, #8]`, ... (the caller's `sp`,
  which is your `sp` on entry);
- if there were doubles, the first eight would be in `d0`-`d7` (really
  `q0`-`q7`, the full 128-bit registers), and further ones on the stack mixed
  in with the extra ints, in argument order.

Your loop wants "the next argument", but the next one may be in a register or
on the stack, and you cannot index registers by a number (there is no
"register number `i`" instruction). The trick every AAPCS64 compiler uses:

1. **At function entry, store the argument registers into memory**, in a
   block called the **register save area**. Now every argument is in memory
   somewhere: the register ones in the save area, the rest in the caller's
   stack area.
2. **Keep a small struct that remembers where you are** in each of those
   places. That struct is `va_list`.

## Part 3: the AAPCS64 `va_list`

On Linux AArch64, `va_list` is this 32-byte struct (it is defined by the
AAPCS64 document, "Procedure Call Standard for the Arm 64-bit Architecture",
appendix B):

```c
typedef struct {
    void *__stack;    // offset 0:  next argument in the caller's stack area
    void *__gr_top;   // offset 8:  one byte past the end of the GR save area
    void *__vr_top;   // offset 16: one byte past the end of the VR save area
    int   __gr_offs;  // offset 24: where the next GR argument is, relative to __gr_top
    int   __vr_offs;  // offset 28: same for the next FP/SIMD argument
} va_list;
```

"GR" means general registers (`x0`-`x7`); "VR" means vector registers
(`q0`-`q7`, whose low halves are `d0`-`d7`).

The two *offsets* are the clever part. They are **negative while there are
register arguments left**, and count up towards zero:

```
            GR save area (x1..x7 here, 7 * 8 = 56 bytes)
            +----+----+----+----+----+----+----+
            | x1 | x2 | x3 | x4 | x5 | x6 | x7 |
            +----+----+----+----+----+----+----+
            ^                                   ^
   __gr_top - 56                             __gr_top

   __gr_offs = -56   next GR argument is x1, at __gr_top - 56
   __gr_offs = -48   next is x2
   ...
   __gr_offs =  -8   next is x7
   __gr_offs =   0   registers used up: take arguments from __stack
```

### `va_start(ap, last_named)`

Say the function has `g` named integer/pointer parameters and `v` named
floating point ones. Then `va_start` sets:

| Field | Value |
|-------|-------|
| `__stack` | `sp` on entry (the first stacked argument) |
| `__gr_top` | end of the GR save area |
| `__vr_top` | end of the VR save area |
| `__gr_offs` | `-(8 - g) * 8` |
| `__vr_offs` | `-(8 - v) * 16` (each `q` register is 16 bytes) |

For `sum(int n, ...)`: `g = 1`, `v = 0`, so `__gr_offs = -56` and
`__vr_offs = -128`. The callee only needs to save the registers that can
still hold unnamed arguments: `x1`-`x7` (and `q0`-`q7`).

A function that will never read a `double` from its `...` can skip saving the
FP registers. It sets `__vr_offs = 0`, meaning "no FP registers left", and the
value of `__vr_top` then does not matter. Our `sum` and `myprintf` do this.

### `va_arg(ap, int)` (or `long`, or a pointer)

In C, the algorithm from the AAPCS64 is:

```c
int offs = ap.__gr_offs;
if (offs >= 0) goto on_stack;      // GR save area already used up
ap.__gr_offs = offs + 8;           // one 8-byte register slot
if (ap.__gr_offs > 0) goto on_stack;   // only matters for 16-byte types
addr = ap.__gr_top + offs;         // offs is negative: inside the save area
goto done;
on_stack:
addr = ap.__stack;
ap.__stack += 8;                   // one 8-byte stack slot
done:
value = *(int *)addr;
```

For 8-byte (or smaller) arguments the second test can never be true: if
`offs` was negative it was at most `-8`. We leave it out. It exists for
16-byte arguments such as `__int128`, which take two registers.

### `va_arg(ap, double)`

The same, using the VR fields and 16-byte steps:

```c
int offs = ap.__vr_offs;
if (offs >= 0) goto on_stack;
ap.__vr_offs = offs + 16;
if (ap.__vr_offs > 0) goto on_stack;
addr = ap.__vr_top + offs;         // the double is in the low 8 bytes of the q slot
...
on_stack: addr = ap.__stack; ap.__stack += 8;
```

There is only one `__stack` pointer: once either class overflows, its
arguments sit on the stack in the order they were written in the call.

### `va_end(ap)` and `va_copy(dst, src)`

`va_end` does nothing on AArch64. `va_copy(dst, src)` copies the 32 bytes. The
copy shares the same save area, but has its own cursor fields, so you can walk
the arguments twice (exercise 26.6).

## Part 4: `sum` in assembly

Here is the plan for `sum`'s 112-byte frame:

```
    sp+0    x29, x30
    sp+16   va_list ap          (32 bytes)
    sp+48   x1 .. x7            (GR save area, 56 bytes; __gr_top = sp+104)
    sp+104  padding             (keeps the frame a multiple of 16)
    sp+112  = sp on entry       (__stack starts here)
```

Open [examples/sum.s](examples/sum.s). The steps are exactly the ones above:

1. **Prologue** and **spill** `x1`-`x7` into the save area, with `stp`.
2. **`va_start`**: store the five fields. `.equ` names (`VA_STACK`,
   `VA_GR_OFFS`, ...) keep the offsets readable.
3. **The loop** runs `n` times. Each time round it does `va_arg` by hand:

   ```asm
       ldr     w12, [sp, #AP + VA_GR_OFFS]     // offs = ap.__gr_offs
       tbz     w12, #31, from_stack            // offs >= 0: registers used up
       add     w13, w12, #8
       str     w13, [sp, #AP + VA_GR_OFFS]     // ap.__gr_offs = offs + 8
       ldr     x14, [sp, #AP + VA_GR_TOP]
       add     x14, x14, w12, sxtw             // addr = __gr_top + offs
       b       have_addr
   from_stack:
       ldr     x14, [sp, #AP + VA_STACK]       // addr = __stack
       add     x13, x14, #8
       str     x13, [sp, #AP + VA_STACK]       // __stack += 8
   have_addr:
       ldr     w15, [x14]                      // the int itself
   ```

   `tbz w12, #31` tests the sign bit: "branch if offs is not negative".
   `add x14, x14, w12, sxtw` sign-extends the negative 32-bit offset before
   adding it to the 64-bit pointer (lesson 18). Forget the `sxtw` and you add
   about four billion instead of subtracting 56.

`sum.s` has no `main`. It is tested from C, so the *compiler* sets up the
calls and we find out whether our `va_arg` agrees with it. Look at
[examples/sum_test.c](examples/sum_test.c). The 10-argument call puts seven
values in `x1`-`x7` and three on the stack, so it tests both paths.

Predict the output of `sum(4, -5, 100, -20, 1)` before you run it.

```console
$ make sum
$ ./sum
sum(0) = 0
sum(3, 10, 20, 30) = 60
sum(7, 1..7) = 28
sum(10, 1..10) = 55
sum(4, -5, 100, -20, 1) = 76
```

The Makefile has an explicit rule for `sum` that links `sum.s` with
`sum_test.c`:

```make
sum: sum.s sum_test.c
	$(CC) $(ASFLAGS) -o $@ $^
```

### What does gcc do?

Compile the C version of `sum` (it is at the top of `sum.s`) with
`gcc -O1 -S -o - sum.c`. The start, with comments added:

```asm
sum:
    sub     sp, sp, 96
    mov     w8, w0
    str     x1, [sp, 40]        // GR save area: x1..x7 at sp+40 .. sp+95
    ...
    str     x7, [sp, 88]
    add     x0, sp, 96
    str     x0, [sp]            // __stack  = sp on entry
    str     x0, [sp, 8]         // __gr_top = sp+96 (end of the save area)
    add     x0, sp, 32
    str     x0, [sp, 16]        // __vr_top: unused
    mov     w0, -56
    str     w0, [sp, 24]        // __gr_offs = -56
    str     wzr, [sp, 28]       // __vr_offs = 0: gcc saw no va_arg(ap, double)
```

The same five fields, the same values. gcc noticed that `sum` never asks for a
`double`, so like us it skips saving `q0`-`q7`. Later in its loop you can find
`tbnz w3, #31` (the sign test) and `cmp w4, 0` / `ble` (the "> 0" test we
dropped).

## Part 5: `myprintf`

A real `printf` is thousands of lines. Ours handles five conversions:

| Conversion | Argument | Prints |
|------------|----------|--------|
| `%d` | `int` | signed decimal |
| `%x` | `unsigned int` | lowercase hexadecimal |
| `%c` | `int` (a promoted `char`) | that character |
| `%s` | `char *` | the string, or `(null)` for `NULL` |
| `%%` | none | `%` |

Anything else after `%` is printed unchanged. It returns the number of
characters printed, like `printf`.

In C:

```c
int myprintf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int count = 0;
    for (const char *p = fmt; *p; p++) {
        if (*p != '%') { putchar(*p); count++; continue; }
        p++;
        switch (*p) {
        case 'd': count += print_signed(va_arg(ap, int)); break;
        case 'x': count += print_unsigned(va_arg(ap, unsigned), 16); break;
        case 's': count += print_str(va_arg(ap, char *)); break;
        case 'c': putchar(va_arg(ap, int)); count++; break;
        case '%': putchar('%'); count++; break;
        ...
        }
    }
    va_end(ap);
    return count;
}
```

Open [examples/myprintf.s](examples/myprintf.s). What is new compared with
`sum`:

- **`myprintf` calls other functions** (`putchar`), and those clobber `x1`-`x7`.
  That is fine: the very first thing we do is store them in the save area, and
  from then on we only read the save area. The *order* matters: spill first,
  call later.
- **The cursor lives in memory**, inside our frame. A call cannot clobber it.
  The loop pointer and the count live in `x19` and `x20` because they must
  survive the `putchar` calls (callee-saved, lesson 15).
- **`va_arg` is a helper function**, `next_gr`. It takes the address of a
  `va_list` in `x0` and returns the address of the next argument. Then each
  conversion picks the right load for its type:

  ```asm
  conv_d:
      add     x0, sp, #AP
      bl      next_gr                 // x0 = address of the next int
      ldrsw   x0, [x0]                // int, sign-extended to 64 bits
      bl      print_signed
  ```

  `%d` uses `ldrsw` (signed int), `%x` uses `ldr w0` (unsigned int,
  zero-extended), `%s` uses `ldr x0` (a pointer). Each slot is 8 bytes, but
  only the low 4 bytes of an `int` slot are meaningful; the upper half may be
  garbage. Always load an `int` with a 32-bit load.

- `next_gr` is a **leaf function** (it calls nothing), so it needs no frame
  and uses only temporaries.

The C driver [examples/myprintf_test.c](examples/myprintf_test.c) prints each
line twice, once with `myprintf` and once with the real `printf`, so you can
compare. Predict: what does `myprintf` return for the first line? Count the
characters (the `\n` counts, `%%` prints one character).

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

`INT_MIN` is the classic trap: `-(-2147483648)` does not fit in 32 bits. We
sign-extend to 64 bits with `ldrsw` first and negate the 64-bit value, so it
works.

Calling *your own* variadic function from assembly is no different from
calling `printf`. [examples/pfdemo.s](examples/pfdemo.s) does it, including a
call with nine variadic ints (two on the stack):

```console
$ make pfdemo
$ ./pfdemo
Ada is 36 years old (0x24), grade A
1 2 3 4 5 6 7 8 9
```

## Part 6: forwarding with `vprintf` / `vfprintf`

Often you want a function that *takes* `...` and hands the arguments on to
`printf`. You cannot pass `...` itself. Instead libc provides versions that
take a `va_list`:

```c
int vprintf(const char *fmt, va_list ap);
int vfprintf(FILE *stream, const char *fmt, va_list ap);
int vsnprintf(char *buf, size_t size, const char *fmt, va_list ap);
```

A typical logging function:

```c
int logmsg(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fputs("[log] ", stderr);
    int n = vfprintf(stderr, fmt, ap);
    va_end(ap);
    return n;
}
```

Two new things for the assembly version:

1. **Save the FP registers too.** `logmsg` does not know what the format
   contains. If it has `%f`, `vfprintf` will do `va_arg(ap, double)`, so the
   `va_list` must describe a real VR save area: store `q0`-`q7` (16 bytes
   each, `stp q0, q1, [sp, #...]`) and set `__vr_offs = -128` and `__vr_top`
   to the end of that area.
2. **Pass the `va_list` by reference.** The C prototype says `va_list ap`, by
   value. But `va_list` is a 32-byte struct, and AAPCS64 passes a struct
   bigger than 16 bytes by putting it in memory and passing its *address*
   (lesson 19). Strictly, the caller passes the address of a *copy*, because
   the callee may change it. We never use `ap` again after the call, so we
   pass the address of our own `ap`:

   ```asm
       mov     x1, x19                 // fmt
       add     x2, sp, #AP             // x2 = &ap
       bl      vfprintf
   ```

The frame of `logmsg` is 256 bytes:

```
    sp+0    x29, x30
    sp+16   x19, padding
    sp+32   va_list ap          (32 bytes)
    sp+64   x1 .. x7            (GR save area; __gr_top = sp+120)
    sp+120  padding
    sp+128  q0 .. q7            (VR save area, 128 bytes; __vr_top = sp+256)
    sp+256  = sp on entry       (__stack)
```

Read [examples/vforward.s](examples/vforward.s). Notice the order again: all
argument registers are saved *before* the `fputs` call, which would destroy
them. In `main`, the second call passes `"progress"` in `x1`, 37.5 in `d0`, 80
in `x2` and 2/3 in `d1`: integers and doubles fill their own register files
independently.

```console
$ make vforward
$ ./vforward
[log] 3 apples cost 1.25 dollars (cheap)
[log] progress: 37.5% of 80, then 0.667
```

Both lines go to `stderr`. Try `./vforward 2>/dev/null`: nothing is printed.

## C to assembly

| C | Linux AArch64 assembly |
|---|------------------------|
| call `f(fmt, 1, 2.5, "s")` | `x0`=fmt, `x1`=1, `d0`=2.5, `x2`="s", then `bl f` (like any call) |
| 9th integer argument | 8-byte slot at `[sp]` before the call |
| `va_list ap;` | 32 bytes in the frame: `__stack`, `__gr_top`, `__vr_top`, `__gr_offs`, `__vr_offs` |
| `va_start(ap, last)` | spill `x1`-`x7` (and `q0`-`q7`), fill in the five fields |
| `va_arg(ap, int)` | if `__gr_offs < 0`: `__gr_top + offs`, offs += 8; else `__stack`, `__stack += 8`; then `ldr w` |
| `va_arg(ap, long)` / pointer | same address, `ldr x` |
| `va_arg(ap, double)` | same with `__vr_offs`/`__vr_top`, steps of 16; then `ldr d` |
| `va_copy(b, a)` | copy 32 bytes |
| `va_end(ap)` | nothing |
| `vfprintf(f, fmt, ap)` | `x0`=f, `x1`=fmt, `x2`=`&ap` (struct > 16 bytes goes by reference) |

## Common mistakes

- **Calling a function before spilling `x1`-`x7`.** The call overwrites them
  and `va_arg` later reads garbage. Spill at the very top of the function.
- **Saving only `d0`-`d7` with `str d0`, but laying out 16-byte slots.** The
  VR save area holds full `q` registers, 16 bytes each. Use `stp q0, q1, ...`,
  or `str d` at 16-byte strides; `va_arg(ap, double)` steps by 16.
- **Forgetting `sxtw`** when adding the negative `__gr_offs` to `__gr_top`.
  Without it you add a huge positive number and crash with a segmentation
  fault.
- **Loading an `int` with `ldr x`.** The upper 4 bytes of the slot are not
  guaranteed to be zero or a sign extension. Load `int` with `ldr w`/`ldrsw`.
- **Asking for `char` or `float` with `va_arg`.** They were promoted to `int`
  and `double` by the caller. In assembly that means: read a 4-byte `int` and a
  `double` (`ldr d`), never a `float` (`ldr s`).
- **Wrong `__gr_offs` for the number of named arguments.** With two named
  pointer parameters (like `vfprintf`'s own `stream, fmt`), only `x2`-`x7` are
  variadic: `__gr_offs = -48`. Get this wrong and the first `va_arg` returns
  one of the named parameters.
- **Passing the `va_list` struct by value.** On Linux `vfprintf` expects the
  address of a `va_list` in `x2`, not its fields in `x2`-`x5`.
- **Assuming macOS works the same.** It does not: there, every variadic
  argument is on the stack and `va_list` is a plain pointer. See the companion
  lesson.

## Recap

- On Linux, variadic arguments are passed exactly like normal ones: `x1`-`x7`,
  `d0`-`d7`, then 8-byte stack slots.
- A variadic function does not know how many arguments it got; it needs a count
  or a format string. `char`/`short` arrive as `int`, `float` as `double`.
- The callee spills the argument registers into a register save area, so that
  every argument is in memory.
- The AAPCS64 `va_list` is a 32-byte struct: a stack pointer, two "top"
  pointers, and two negative offsets that count up to zero.
- `va_arg` checks the offset: negative means "still in the save area",
  otherwise take the next 8-byte stack slot.
- `va_copy` copies the struct; `va_end` does nothing.
- To forward `...`, build a full `va_list` (including `q0`-`q7`) and pass its
  address to `vprintf`/`vfprintf`.
- Test hand-written variadic functions from C: the compiler's calls are the
  reference.

## Homework

[exercises.md](exercises.md)
