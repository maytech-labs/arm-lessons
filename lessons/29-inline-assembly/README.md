# Lesson 29: Inline assembly

## Goals

After this lesson you can:

- Write GCC/Clang extended `asm` statements inside C functions.
- Connect C variables to instructions with output and input operands.
- Choose constraints: `r`, `i`, `+r`, `=&r`, `Q`, and the `%w` modifier.
- Declare clobbers: registers, `"cc"`, and `"memory"`.
- Know when `volatile` is required, and what the optimiser may do without it.
- Read system registers (the timer) with `mrs`.
- Decide when inline assembly is worth it, and when a builtin or a separate
  `.s` file is better.

## Before you start

You need lesson 16 (C and assembly together), 18 (`w` vs `x`), 27 (reading
optimised output), and for the last exercise 28 (exclusive loads and stores).

Until now, assembly and C met at function boundaries: a `.s` file and a `.c`
file, linked together, talking through the calling convention. Inline assembly
puts a few instructions **inside** a C function instead. It is how most
assembly in real programs is written: a handful of lines where C has no way to
say what you need.

```console
# cd lessons/29-inline-assembly/linux/examples && make
```

These examples are built with `-O2`, so you see how `asm` statements interact
with the optimiser.

## The shape of an `asm` statement

```c
asm("add %0, %1, %2"        // the template: %0, %1, %2 are the operands below
    : "=r"(r)               // outputs:  %0 = r, in any register ("r"), written ("=")
    : "r"(a), "r"(b));      // inputs:   %1 = a, %2 = b, each in some register
```

An extended `asm` statement has four parts, separated by colons:

```c
asm [volatile] ( "template"
                 : outputs
                 : inputs
                 : clobbers );
```

- **The template** is assembly text. The compiler copies it into its own
  output, replacing `%0`, `%1`, ... with the registers it chose.
- **Outputs** are C lvalues the instructions write.
- **Inputs** are C expressions the instructions read.
- **Clobbers** list anything else the instructions change.

The key idea: **you do not choose the registers; the compiler does.** You say
"put `a` in some register and call it `%1`", and the compiler fits that into
its own register allocation. That is what makes inline assembly cheap: no
call, no saving registers, no moving arguments into `x0`-`x7`.

The template is opaque to the compiler. It does not read your instructions.
Everything it knows about what they do comes from the operands and clobbers,
so those must be exactly right.

### Named operands

Numbers get hard to follow; operands can have names:

```c
asm("madd %[res], %[x], %[y], %[z]"
    : [res] "=r"(r)
    : [x] "r"(a), [y] "r"(b), [z] "r"(c));
```

```console
# ./basic
20 + 22 = 42
10 * 3 + 12 = 42
```

Look at what the compiler did with it: `objdump -d basic` (or
`gcc -O2 -S basic.c`). The `add` and `madd` sit right in the middle of the
compiler's code, using whatever registers it picked.

## Constraints

The string before each operand is its **constraint**: where it may live and
how it is used. The common ones on AArch64:

| Constraint | Meaning |
|------------|---------|
| `r` | a general-purpose register |
| `i` | an immediate constant (must be known at compile time) |
| `I`, `J`, `K`, `L` | immediates valid for `add`, `sub`-negated, 32-bit logical, 64-bit logical |
| `w` | a floating-point / SIMD register (lesson 23, 30) |
| `Q` | a memory operand addressed by one register: prints as `[xN]` |
| `m` | a general memory operand |

and the **modifiers** in front of them:

| Modifier | Meaning |
|----------|---------|
| `=` | output: written, not read |
| `+` | read **and** written |
| `&` | early clobber: written before all inputs are read (see below) |

`examples/constraints.c` uses most of them:

```c
long x = 10;
asm("add %0, %0, #5" : "+r"(x));            // "+r": read AND written

asm("ror %w0, %w1, %2"                      // %w0: the 32-bit name of operand 0
    : "=r"(r)
    : "r"(v), "i"(8));                      // "i": an immediate constant
```

### `%w`: choosing the register width

`%0` prints as `x5` (say). For 32-bit instructions you need `w5`: write `%w0`.
Use it whenever the C variable is an `int` or `unsigned`. Getting it wrong is
usually an assembler error, but `%0` on a 32-bit value used with a 64-bit
instruction can silently read garbage in the top half.

### Early clobber: `=&r`

The compiler assumes your instructions read **all inputs first** and write
outputs **last**. So it may reuse an input's register for an output. That is
fine for one instruction, but in a multi-instruction template it breaks as soon
as you write an output before reading the last input:

```c
asm("add %0, %1, %1, lsl #1\n\t"     // writes %0...
    "add %0, %0, %2"                 // ...then reads %2: but %0 may BE %2
    : "=r"(r) : "r"(a), "r"(b));
```

`"=&r"` forbids the sharing. When a template has more than one instruction,
check every output: is it written before some input is read? Then it needs
`&`. Exercise 29.5 is this exact bug.

Several instructions go in one string separated by `\n\t` (newline, then a tab
so the compiler's assembly output stays readable).

## Clobbers

If your instructions change anything that is not an output, list it as a
clobber, or the compiler will assume it is unchanged. `examples/clobbers.c`:

```c
static int add_overflows(long a, long b) {
    int v;
    asm("adds %1, %1, %2\n\t"   // changes the flags...
        "cset %w0, vs"
        : "=r"(v), "+r"(a)
        : "r"(b)
        : "cc");                // ...so say so
    return v;
}
```

| Clobber | Says |
|---------|------|
| `"x9"`, `"x10"`, ... | I use this register as scratch |
| `"cc"` | I change the condition flags |
| `"memory"` | I read or write memory that is not an operand; do not keep memory values cached in registers across me |

`"memory"` matters whenever the asm touches memory through a pointer:

```c
asm volatile("stp xzr, xzr, [%0]\n\t"
             "stp xzr, xzr, [%0, #16]"
             :                          // no outputs
             : "r"(p)
             : "memory");               // it writes memory through p
```

Without it, the compiler might keep `a[0]` in a register from before the
asm and print the old value. A cheaper, more precise alternative is a memory
operand like `"+Q"(*p)` (exercise 29.6), which says exactly which memory is
touched.

Never clobber `sp`, `x29`, `x30`, or `x18`. If you need more scratch registers,
prefer extra output operands (`"=&r"(tmp)`) over hard-coded clobbers, so the
compiler can pick registers that are free.

## `volatile`

The compiler treats an `asm` without `volatile` as a pure function of its
inputs: if its outputs are unused, it may **delete** it; if it appears twice
with the same inputs, it may run it once; it may move it out of a loop.
`examples/volatile.c`:

```c
long unused;
asm("mov %0, #1111" : "=r"(unused));            // result never used: removed
asm volatile("mov x9, #2222" ::: "x9");         // volatile: always kept
```

```console
# objdump -d volatile | grep -A12 '<main>:'
```

Only the `#2222` is there. Use `volatile` when the asm has an effect the
operands do not describe: reading a timer (each read is different), changing
system state, barriers, or anything with no outputs. An asm with no outputs is
treated as volatile automatically, but write it anyway; it documents intent.

## A real use: system registers

Some things simply have no C equivalent. The timer is one. `examples/counter.c`
reads the virtual counter and its frequency with `mrs` ("move from system
register"):

```c
static inline unsigned long ticks(void) {
    unsigned long t;
    asm volatile("isb\n\t"              // finish earlier instructions first
                 "mrs %0, cntvct_el0"   // mrs: move from system register
                 : "=r"(t));
    return t;
}
```

```console
# ./counter
timer frequency: 24000000 Hz
the loop took more than 0 ticks: yes
```

`isb` makes sure earlier instructions have finished before the timer is read,
so the measurement is not skewed. This is the most precise clock you can read
from user code, and the basis of exercise 29.4.

Most system registers are privileged (only the kernel can read them).
`cntvct_el0` and `cntfrq_el0` are among the few that user programs may read.

## When to use inline assembly (and when not)

Inline assembly is a sharp tool. Before reaching for it, check:

1. **Does C already say it?** `a * b` with `unsigned __int128` compiles to
   `umulh`; `x >> 63` to `asr`. Look at the compiler output first (lesson 27).
2. **Is there a builtin?** `__builtin_clzl`, `__builtin_bswap64`,
   `__builtin_add_overflow`, `__builtin_prefetch`, `<stdatomic.h>` for atomics,
   `<arm_acle.h>` and `<arm_neon.h>` for many special instructions. Builtins
   are understood by the optimiser; inline asm is a black box to it.
3. **Is it big?** More than a dozen instructions, or loops and labels: put it
   in a `.s` file and call it. The calling convention is simpler to get right
   than a long template.

Good uses of inline asm: system registers, single special instructions with no
builtin, barriers, and code where you must control the exact instruction
sequence.

## C to assembly

| You want | Write |
|----------|-------|
| `r = a + b` in one instruction | `asm("add %0, %1, %2" : "=r"(r) : "r"(a), "r"(b));` |
| modify a variable in place | `asm("..." : "+r"(x));` |
| a 32-bit register | `%w0` in the template |
| a compile-time constant | `"i"(8)`, written as `%2` where the immediate goes |
| several instructions | `"insn1\n\t" "insn2"` |
| an output written early | `"=&r"(tmp)` |
| the asm changes flags | clobber `"cc"` |
| the asm writes memory through a pointer | `"+Q"(*p)` or clobber `"memory"` |
| the asm must not be removed or merged | `asm volatile(...)` |
| read a system register | `asm volatile("mrs %0, cntvct_el0" : "=r"(t));` |

## Common mistakes

- **Missing clobbers.** The compiler keeps a value in a register you
  overwrote, or trusts flags you changed. Works at `-O0`, fails at `-O2`.
- **Missing early clobber** in multi-instruction templates (exercise 29.5).
- **`%0` instead of `%w0`** for 32-bit values.
- **Forgetting `volatile`** on asm with side effects: it disappears.
- **Hard-coding registers** (`mov x0, ...`) instead of using operands. The
  compiler may be using `x0` for something else. If you must, list it as a
  clobber.
- **Branching out of an asm** or to a label in another asm. Use numbered local
  labels (`1:`, `1b`) inside one template only.
- **Touching `sp`, `x29`, `x30`, or `x18`.**
- **Using inline asm where a builtin exists.** It blocks optimisation and is
  harder to read.

## Recap

- `asm("template" : outputs : inputs : clobbers)`; the compiler chooses the
  registers.
- Constraints: `r` register, `i` immediate, `Q`/`m` memory; modifiers `=`
  written, `+` read-write, `&` early clobber.
- `%w0` names the 32-bit register.
- Clobber everything else you change: scratch registers, `"cc"`, `"memory"`.
- `volatile` stops the compiler deleting, merging, or moving the asm.
- Use inline asm for what C and builtins cannot express; use a `.s` file for
  anything long.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md)
next.
