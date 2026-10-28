# Lesson 09: Flags and branches

## Goals

After this lesson you can:

- Explain the four condition flags N, Z, C, V, and which instructions set them.
- Compare with `cmp`, `cmn`, and `tst`.
- Jump with `b`, and jump conditionally with `b.eq`, `b.lt`, `b.hi`, and the rest.
- Choose the **signed** or **unsigned** condition correctly.
- Use `cbz`/`cbnz` and `tbz`/`tbnz` to branch without a compare.
- Translate C's `if`, `if`/`else`, `else if` chains, `&&`, and `||`.

## Before you start

You need lesson 02 (carry vs overflow), 07 (`add`/`sub`), and 08 (`and`, bit
tests). Every program so far ran straight from top to bottom. This lesson is
about making decisions.

```console
# cd lessons/09-branches/examples && make
```

## Jumping: `b`

```asm
    b done                      // continue at the label done
```

`b` ("branch") is an unconditional jump: the next instruction executed is the
one at the label. It is C's `goto`. The CPU does it by putting the label's
address in `pc`.

A jump on its own is not very useful. The power comes from jumping *only if*
something is true.

## The condition flags

The CPU has a special register, **PSTATE**, that holds four one-bit **flags**.
Some instructions set them based on their result:

| Flag | Name | Set to 1 when the result... |
|------|------|-----------------------------|
| **N** | Negative | has bit 63 (or 31) set: negative, read as signed |
| **Z** | Zero | is zero |
| **C** | Carry | carried out of the top bit (add), or did *not* borrow (subtract) |
| **V** | oVerflow | overflowed as a **signed** number |

C and V are lesson 02 again: C means the *unsigned* result did not fit, V
means the *signed* result did not fit.

Most instructions **do not** touch the flags. `add`, `sub`, `mov`, `mul`: all
leave them alone. Only instructions that say so set them:

| Sets flags | Same as | but sets the flags |
|------------|---------|--------------------|
| `adds xd, xn, xm` | `add` | yes |
| `subs xd, xn, xm` | `sub` | yes |
| `ands xd, xn, xm` | `and` | yes (N and Z; C and V cleared) |
| `cmp xn, xm` | `subs xzr, xn, xm` | yes, result thrown away |
| `cmn xn, xm` | `adds xzr, xn, xm` | yes, result thrown away |
| `tst xn, xm` | `ands xzr, xn, xm` | yes, result thrown away |

**`cmp` is a subtraction whose result is discarded.** It computes `a - b` only
to set the flags. That is all a comparison is.

### Watching the flags

`examples/flags.s` sets the flags four times. Step through it and print
`$cpsr` (gdb's name for the flags register) after each one:

```console
# gdb -q ./flags
(gdb) starti
(gdb) si 3
(gdb) p $cpsr
$1 = [ EL=0 BTYPE=0 SS C Z ]
```

gdb lists the flags that are set. (`EL`, `BTYPE`, and `SS` are other state
bits; `SS` appears because you are single-stepping. Ignore them.)

```asm
    adds x0, x1, x2             // 1: 1 + (-1) = 0         -> Z=1, and C=1
    subs x0, x3, #5             // 2: 3 - 5 = -2           -> N=1, C=0 (it borrowed)
    adds w0, w4, #1             // 3: 0x7fffffff + 1 = 0x80000000 -> N=1, V=1
    cmp x3, #3                  // 4: 3 - 3 = 0, result thrown away -> Z=1, C=1
```

The four results print as `C Z`, `N`, `V N`, `C Z`. Work out *why* for each
one before reading the comments. Case 1 is the surprising one: 1 + (-1) carries
because, unsigned, it is 1 + 0xffffffffffffffff.

## Conditional branches: `b.cond`

`b.cond label` jumps only if the condition is true, judging by the flags. If it
is false, execution simply continues with the next instruction.

After `cmp a, b`:

| Condition | Jumps if | For | Flags tested |
|-----------|----------|-----|--------------|
| `b.eq` | `a == b` | any | Z=1 |
| `b.ne` | `a != b` | any | Z=0 |
| `b.lt` | `a < b` | **signed** | N≠V |
| `b.le` | `a <= b` | **signed** | Z=1 or N≠V |
| `b.gt` | `a > b` | **signed** | Z=0 and N=V |
| `b.ge` | `a >= b` | **signed** | N=V |
| `b.lo` | `a < b` | **unsigned** | C=0 |
| `b.ls` | `a <= b` | **unsigned** | C=0 or Z=1 |
| `b.hi` | `a > b` | **unsigned** | C=1 and Z=0 |
| `b.hs` | `a >= b` | **unsigned** | C=1 |
| `b.mi` | result negative | | N=1 |
| `b.pl` | result positive or zero | | N=0 |
| `b.vs` | signed overflow | | V=1 |
| `b.vc` | no signed overflow | | V=0 |

`lo`/`hs` also have the names `cc`/`cs` (carry clear / carry set).

You do not need to remember the "flags tested" column. Remember the C meaning,
and remember which conditions are signed: **lt, le, gt, ge** (think "less",
"greater") are signed; **lo, ls, hi, hs** ("lower", "higher") are unsigned.

## The first `if`

```c
long x = 15, r = 0;
if (x > 10) {
    r = 1;
}
```

In assembly you cannot "do the block if true". You can only "jump if true".
So you jump **over** the block when the condition is **false**:

```asm
    mov x1, #15                 // x = 15
    mov x0, #0                  // r = 0
    cmp x1, #10                 // compare x with 10 (sets flags from x - 10)
    b.le end_if                 // NOT (x > 10) is (x <= 10): skip the then-block
    mov x0, #1                  // then-block: r = 1
end_if:
```

This is the most important pattern in the lesson. **Invert the condition and
skip the block.** The opposites:

| C condition | Skip the block with |
|-------------|---------------------|
| `a == b` | `b.ne` |
| `a != b` | `b.eq` |
| `a < b` | `b.ge` (signed) / `b.hs` (unsigned) |
| `a <= b` | `b.gt` / `b.hi` |
| `a > b` | `b.le` / `b.ls` |
| `a >= b` | `b.lt` / `b.lo` |

That is `examples/if.s`. Change `x` to 5 and the exit status becomes 0.

## `if` / `else`

```c
if (a >= b) m = a; else m = b;
```

Now there are two blocks. Skip to the else-block when the condition is false,
and at the end of the then-block, jump over the else-block:

```asm
    cmp x1, x2                  // compare a with b
    b.lt else                   // NOT (a >= b) is (a < b): go to the else-block
    mov x0, x1                  // then-block: m = a
    b end_if                    // skip over the else-block
else:
    mov x0, x2                  // else-block: m = b
end_if:
```

Forget the `b end_if` and the then-block **falls through** into the
else-block, running both. That is one of the most common beginner bugs.

## `else if` chains

`examples/elseif.s` turns a score into a letter grade. Each test either runs
its block and jumps to the end, or falls through to the next test:

```asm
    cmp x1, #90                 // if (s >= 90)
    b.lt try_b                  //   no: try the next test
    mov x0, #'A'                //   g = 'A' (the assembler turns 'A' into 65)
    b done                      //   finished: skip all the other tests
try_b:
    cmp x1, #80                 // else if (s >= 80)
    b.lt try_c
    mov x0, #'B'
    b done
try_c:
    ...
grade_f:
    mov x0, #'F'                // else g = 'F'
done:
```

`#'A'` is a character constant: the assembler replaces it with 65, like C.

## `&&` and `||`

C evaluates `&&` and `||` left to right and stops as soon as the answer is
known ("short-circuit"). Branches do that naturally. From `examples/logical.s`:

**`&&`: if any test fails, skip the body.**

```asm
    // if (x >= 10 && x <= 20) r += 1;
    cmp x1, #10                 // first test: x >= 10 ?
    b.lt end_and                //   false: whole && is false, skip
    cmp x1, #20                 // second test: x <= 20 ?
    b.gt end_and                //   false: skip
    add x0, x0, #1              // both true: r += 1
end_and:
```

**`||`: if any test succeeds, jump into the body; if all fail, skip it.**

```asm
    // if (c == ' ' || c == '\n') r += 2;
    cmp x2, #' '                // first test: c == ' ' ?
    b.eq or_body                //   true: whole || is true, run the body now
    cmp x2, #'\n'               // second test: c == '\n' ?
    b.ne end_or                 //   false too: skip the body
or_body:
    add x0, x0, #2              // r += 2
end_or:
```

In the `||`, the first test uses the condition **as written** (jump into the
body), and only the last test is inverted (skip the body).

## Signed or unsigned? It matters

The same `cmp` sets all four flags at once; the condition you test decides
whether the numbers are read as signed or unsigned. `examples/signedness.s`
compares `a = -1` (all bits set) with `b = 1`:

```asm
    cmp x1, x2
    b.ge skip_signed            // signed: -1 < 1 is true, so no jump
    add x0, x0, #1
skip_signed:
    cmp x1, x2
    b.hs skip_unsigned          // unsigned: 0xffff...ffff < 1 is false, jump
    add x0, x0, #2
skip_unsigned:
```

The exit status is 1: only the signed test was true. Use signed conditions for
C's `int`/`long`, unsigned for `unsigned`, `size_t`, and **pointers**.
Choosing wrong works fine for small positive numbers and fails mysteriously for
large or negative ones (exercise 09.7).

## Branching without `cmp`: `cbz`, `cbnz`, `tbz`, `tbnz`

Testing for zero and testing one bit are so common that they have their own
instructions, which do not use or change the flags:

| Instruction | Jumps if |
|-------------|----------|
| `cbz xn, label` | `xn == 0` |
| `cbnz xn, label` | `xn != 0` |
| `tbz xn, #bit, label` | bit `bit` of `xn` is 0 |
| `tbnz xn, #bit, label` | bit `bit` of `xn` is 1 |

From `examples/cbz.s`:

```asm
    cbz x1, skip_nonzero        // if (n != 0) ...: skip when n == 0
    add x0, x0, #10
skip_nonzero:
    tbz x1, #0, skip_odd        // if (n & 1) ...: skip when bit 0 is 0
    add x0, x0, #1
skip_odd:
```

`tbnz x1, #63, negative` jumps if `x1` is negative (bit 63 is the sign bit).

## Labels need unique names

Every label in a file must be different. In a program with several `if`s,
name them after what they do: `end_if_positive`, `try_lower`, `skip_odd`.
(Lesson 20 shows numbered local labels that can be reused.)

## C to assembly

| C | Assembly |
|---|----------|
| `goto L;` | `b L` |
| `if (a == b) {...}` | `cmp xa, xb` / `b.ne end` / ... / `end:` |
| `if (a < b) {...}` (signed) | `cmp xa, xb` / `b.ge end` / ... |
| `if (a < b) {...}` (unsigned) | `cmp xa, xb` / `b.hs end` / ... |
| `if (...) {...} else {...}` | `b.!cond else` / then / `b end` / `else:` / else / `end:` |
| `if (x == 0)` | `cbnz x, end` |
| `if (x != 0)` | `cbz x, end` |
| `if (x & (1 << n))` | `tbz x, #n, end` |
| `if (x < 0)` | `tbz x, #63, end` (or `cmp x, #0` / `b.ge end`) |
| `if (A && B)` | test A, skip if false; test B, skip if false; body |
| `if (A \|\| B)` | test A, jump to body if true; test B, skip if false; body |

## Common mistakes

- **Not inverting the condition.** `if (x > 10)` needs `b.le` to skip, not
  `b.gt`.
- **Missing `b end_if` after the then-block.** Both blocks run.
- **Signed condition for unsigned data** (or the reverse). Works for small
  numbers, breaks for big or negative ones.
- **Using `add`/`sub` and expecting flags.** Only the `s` versions (`adds`,
  `subs`) and `cmp`/`cmn`/`tst` set them.
- **Changing the flags between `cmp` and `b.cond`.** Any `adds`, `subs`,
  `cmp`, or `tst` in between replaces them. (`mov`, `add`, and branches are
  safe.)
- **`b.lt` with the operands the wrong way round.** `cmp a, b` then `b.lt`
  means `a < b`. Swap the operands and you test `b < a`.
- **Duplicate label names.** The assembler stops with an error saying the
  symbol is already defined.

## Recap

- `b` jumps; `b.cond` jumps if the condition holds; otherwise execution
  continues with the next instruction.
- Flags N, Z, C, V are set only by `cmp`, `cmn`, `tst`, and `s`-suffixed
  instructions.
- `cmp a, b` is `a - b` with the result thrown away.
- Signed: `lt le gt ge`. Unsigned: `lo ls hi hs`. Both: `eq ne`.
- `if`: invert the condition and branch over the block.
- `if`/`else`: branch to `else` on false; `b end` after the then-block.
- `&&`: each failing test skips. `||`: each passing test jumps into the body.
- `cbz`/`cbnz` test for zero, `tbz`/`tbnz` test a bit, without flags.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/09-branches/README.md) next.
