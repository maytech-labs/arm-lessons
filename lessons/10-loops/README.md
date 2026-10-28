# Lesson 10: Loops

## Goals

After this lesson you can:

- Translate C's `while`, `do`/`while`, and `for` loops.
- Use `break` and `continue`.
- Write nested loops.
- Count down with `subs` so the loop needs no `cmp`.
- Think about a loop with an invariant, to get it right the first time.
- Replace small `if`s with branchless `csel`, `cset`, `cinc`, `cneg`.
- Translate a `switch` as a chain of compares.

## Before you start

You need lesson 09: `cmp`, `b.cond`, `cbz`, and the "invert the condition and
skip" pattern. A loop is just an `if` that jumps backwards.

```console
# cd lessons/10-loops/linux/examples && make
```

## `while`: test at the top

```c
long n = 10, i = 1, sum = 0;
while (i <= n) {
    sum = sum + i;
    i = i + 1;
}
```

A `while` loop is an `if` whose body ends by jumping back to the test.
`examples/sum.s`:

```asm
    mov x1, #10                 // n = 10
    mov x2, #1                  // i = 1
    mov x0, #0                  // sum = 0
loop:                           // invariant here: sum = 1 + 2 + ... + (i - 1)
    cmp x2, x1                  // test the condition: i <= n ?
    b.gt end_loop               // NOT (i <= n) is (i > n): leave the loop
    add x0, x0, x2              // body: sum = sum + i
    add x2, x2, #1              // i = i + 1
    b loop                      // back to the test
end_loop:
```

```console
# ./sum; echo $?
55
```

The shape is always the same:

```
loop:
    test; if false, b end_loop
    body
    b loop
end_loop:
```

Step through it in the debugger with `display $x0` and `display $x2`, and
watch the loop go round.

### Invariants

The comment on `loop:` says what is true **every time** execution reaches that
point: `sum` holds the total of everything before `i`. It is true the first
time (`sum = 0`, nothing before 1), and each pass keeps it true (add `i`, then
move `i` on). So when the loop ends with `i = n + 1`, `sum` must be
`1 + ... + n`.

Writing the invariant down before you write the loop is the most reliable way
to avoid off-by-one errors. In assembly, where nothing is named, it is also
the best documentation you can leave.

## `do` / `while`: test at the bottom

A `do`/`while` runs its body at least once and tests afterwards. That is even
simpler in assembly: one conditional branch backwards.
`examples/digits.s` counts decimal digits:

```c
do {
    count = count + 1;
    n = n / 10;
} while (n != 0);
```

```asm
loop:
    add x0, x0, #1              // body: count = count + 1
    udiv x1, x1, x2             //       n = n / 10
    cbnz x1, loop               // while (n != 0): test at the BOTTOM, jump back
```

Note that here the condition is **not** inverted: we jump back while it is
true. For `n = 0` the body still runs once and the answer is 1, which is
correct (0 has one digit). A `while` loop would have said 0.

## `for`: a `while` in disguise

```c
for (init; cond; step) { body }
```

is exactly

```c
init;
while (cond) { body; step; }
```

`examples/power.s` computes 3^5:

```asm
    mov x3, #0                  // init:      i = 0
for_test:
    cmp x3, x2                  // condition: i < exp ?
    b.ge for_end                //   NOT (i < exp) is (i >= exp): leave
    mul x0, x0, x1              // body:      result = result * base
    add x3, x3, #1              // step:      i++
    b for_test                  // back to the condition
for_end:
```

## Counting down: let `subs` do the compare

If you do not care which order the loop counts in, count **down to zero**.
`subs` subtracts *and* sets the flags, so the loop needs no separate `cmp`.
`examples/countdown.s` computes 5!:

```asm
    mov x1, #5                  // i = n = 5
    mov x0, #1                  // f = 1
    cbz x1, done                // a for loop tests first: skip it all if i == 0
loop:
    mul x0, x0, x1              // f = f * i
    subs x1, x1, #1             // i = i - 1, AND set the flags from the result
    b.ne loop                   // Z clear means i != 0: go again
done:
```

The loop is three instructions. Compilers turn many `for` loops into this
form. The `cbz` before the loop keeps the `for` semantics: if the count starts
at zero, the body must not run at all.

## `break` and `continue`

- `break` jumps **past** the loop: `b end_loop`.
- `continue` jumps to the **next iteration**. In a `for` loop that means the
  *step*, not the test, or the counter never moves.

`examples/skip.s` adds up 1..20, skipping multiples of 3:

```asm
loop:
    cmp x1, #20                 // if (i > 20)
    b.gt end_loop               //   break: jump PAST the loop
    udiv x2, x1, x3             // i / 3
    msub x2, x2, x3, x1         // x2 = i % 3
    cbz x2, continue            // if (i % 3 == 0) continue: jump to the step
    add x0, x0, x1              // sum += i
continue:
    add x1, x1, #1              // step: i++  (continue lands here, not at loop)
    b loop                      // next iteration
end_loop:
```

## A loop that is not about counting

`examples/gcd.s` is Euclid's algorithm. The loop runs until a condition
holds, however many steps that takes:

```asm
loop:                           // invariant: gcd(a, b) never changes
    cbz x1, done                // while (b != 0): leave when b == 0
    udiv x2, x0, x1             // q = a / b
    msub x2, x2, x1, x0         // t = a - q * b = a % b
    mov x0, x1                  // a = b
    mov x1, x2                  // b = t
    b loop
done:
```

`examples/collatz.s` has an `if`/`else` *inside* the loop body. Read it and
predict how its labels are arranged before you open it.

## Loops with output

`examples/stars.s` prints ten `*` characters with ten `write` calls of one
byte each. There is one catch: `write` returns its result in `x0` (lesson 05),
so `x0` cannot be the counter. Linux promises to change nothing else, but
macOS makes no such promise, and from lesson 14 on, every function you call
may change `x0`-`x17`. So get into the habit now: a value that must survive a
call lives in **`x19`** or above.

```asm
    mov x19, #0                 // i = 0
loop:
    cmp x19, #10                // i < 10 ?
    b.ge end_loop
    mov x0, #1                  // write(1, &star, 1)
    adrp x1, star
    add x1, x1, :lo12:star
    mov x2, #1
    mov x8, #64
    svc #0
    add x19, x19, #1            // i++
    b loop
end_loop:
```

Also notice that **all** of `write`'s arguments are set inside the loop, every
time. Lesson 15 explains which registers survive a call and why `x19` is a
good choice.

## Nested loops

A loop inside a loop just needs its own counter and its own labels.
`examples/triangle.s` prints a triangle; row `r` has `r` stars:

```asm
    mov x19, #1                 // r = 1          (outer counter)
outer:
    cmp x19, #5
    b.gt outer_end
    mov x20, #0                 // c = 0          (inner counter, reset every row)
inner:
    cmp x20, x19                // c < r ?
    b.ge inner_end
    ...write a star...
    add x20, x20, #1
    b inner
inner_end:
    ...write a newline...
    add x19, x19, #1
    b outer
outer_end:
```

Resetting the inner counter **inside** the outer loop is the step people
forget. A `break` in the inner loop (exercise 10.8) jumps to `inner_end`, not
`outer_end`: C's `break` leaves only the innermost loop.

## Branchless decisions: `csel` and friends

A short `if` that just picks between two values does not need a branch.
AArch64 has **conditional select** instructions that read the flags:

| Instruction | Meaning |
|-------------|---------|
| `csel xd, xn, xm, cond` | `xd = cond ? xn : xm` |
| `cset xd, cond` | `xd = cond ? 1 : 0` |
| `csinc xd, xn, xm, cond` | `xd = cond ? xn : xm + 1` |
| `cinc xd, xn, cond` | `xd = cond ? xn + 1 : xn` |
| `cneg xd, xn, cond` | `xd = cond ? -xn : xn` |

`examples/branchless.s`:

```asm
    cmp x1, x2                  // one compare; every instruction below reads it
    csel x3, x1, x2, lt         // mn = (a < b) ? a : b     = 17
    csel x4, x1, x2, gt         // mx = (a > b) ? a : b     = 42
    cset x5, eq                 // eq = (a == b) ? 1 : 0    = 0
    mov x6, #5                  // n = 5
    cinc x6, x6, lt             // n = (a < b) ? n + 1 : n  = 6
    ...
    sub x0, x1, x2              // d = a - b = -25
    cmp x0, #0
    cneg x0, x0, lt             // ad = (d < 0) ? -d : d = 25
```

These are C's `?:` operator, and `cset` is how C turns a comparison into a
value (`int eq = (a == b);`). Compilers use them heavily. Branchless code is
often faster, because the CPU does not have to guess which way a branch will go.

Use them for choosing a *value*. When the two paths do different *work*, use
branches.

## `switch`: a chain of compares

`examples/switch.s` implements a calculator's `switch (op)`. The simplest
translation compares against each case in turn, and each case ends with
`b end_switch` (that is C's `break`):

```asm
    cmp x3, #'+'                // case '+' ?
    b.eq case_add
    cmp x3, #'-'                // case '-' ?
    b.eq case_sub
    cmp x3, #'*'
    b.eq case_mul
    cmp x3, #'/'
    b.eq case_div
    b case_default              // no case matched
case_add:
    add x0, x1, x2
    b end_switch                // break
case_sub:
    ...
case_default:
    mov x0, #0
end_switch:
```

Leave out a `b end_switch` and execution falls through into the next case,
exactly like a missing `break` in C. With many dense cases, a jump table is
faster; that is lesson 24.

## C to assembly

| C | Assembly shape |
|---|----------------|
| `while (c) { B }` | `top:` test, `b.!c end` / B / `b top` / `end:` |
| `do { B } while (c);` | `top:` B / test, `b.c top` |
| `for (I; c; S) { B }` | I / `top:` test, `b.!c end` / B / S / `b top` / `end:` |
| `for (i = n; i != 0; i--)` | `cbz` guard / `top:` B / `subs i, i, #1` / `b.ne top` |
| `break;` | `b end` |
| `continue;` | `b step` (in a `for`) or `b top` (in a `while`) |
| `x = c ? a : b;` | `cmp` / `csel x, a, b, c` |
| `x = (a == b);` | `cmp a, b` / `cset x, eq` |
| `if (c) x++;` | `cmp` / `cinc x, x, c` |
| `x = c ? -x : x;` | `cmp` / `cneg x, x, c` |
| `switch` (few cases) | `cmp`/`b.eq` per case; `b end` per `break` |

## Common mistakes

- **An infinite loop.** You forgot the step, or `continue` jumps to the test
  and skips the step. Press `Ctrl-c` to stop it, then use the debugger.
- **Off by one.** `b.ge` vs `b.gt` decides whether the last value is
  included. Check the first and last iteration by hand.
- **Not resetting the inner counter** in a nested loop. The inner loop runs
  only during the first outer iteration.
- **Keeping a counter in `x0`-`x8` across a system call.** The `svc` changes it.
  Use `x19` and up.
- **Using `subs` to count down but `b.gt` to loop.** Fine if the counter can
  never start negative; otherwise think about which flags `subs` sets.
- **A `do` loop where a `while` was needed.** The body runs once even when it
  should not.
- **Missing `b end_switch`.** Cases fall through.

## Recap

- A loop is a conditional branch backwards.
- `while`/`for`: test at the top, inverted, jumping out; `b` back at the bottom.
- `do`/`while`: one conditional branch at the bottom, not inverted.
- Counting down with `subs` + `b.ne` saves the `cmp`.
- `break` jumps past the loop; `continue` jumps to the step.
- Write the invariant at the loop label.
- Keep values that must survive a system call in `x19` or above.
- `csel`, `cset`, `cinc`, `cneg` choose values without branching.
- `switch` can be a chain of `cmp`/`b.eq`, with `b end` for each `break`.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md) next.
