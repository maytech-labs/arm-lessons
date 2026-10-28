# Lesson 09 exercises

Work in `lessons/09-branches/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

For every program, test **every path**: change the starting values so each
branch is taken at least once. Try each exercise before looking at the
answers: programs are in [solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md).

## Exercise 09.1 [warm-up]

Which flags (N, Z, C, V) are set after each instruction? Assume 64-bit
registers. Check two of them in the debugger with `p $cpsr`.

1. `mov x1, #5` / `cmp x1, #5`
2. `mov x1, #5` / `cmp x1, #6`
3. `mov x1, #6` / `cmp x1, #5`
4. `mov x1, #0` / `subs x0, x1, #1`
5. `mov x1, #-1` / `adds x0, x1, #2`
6. `mov x1, #0x7fffffffffffffff` / `adds x0, x1, #1`
7. `mov x1, #5` / `add x0, x1, #5` (careful)

## Exercise 09.2 [warm-up]

After `cmp x1, x2`, which branch jumps when:

1. `x1` and `x2` differ
2. `x1 < x2`, both `long`
3. `x1 < x2`, both `unsigned long`
4. `x1 >= x2`, both pointers
5. `x1 > x2`, both `int` (in `w1`, `w2`: what changes?)

And: which single instruction replaces `cmp x1, #0` / `b.eq L`?

## Exercise 09.3 [core]

Write `ex3.s`: absolute value with a branch.

```c
long x = -42;
if (x < 0) x = -x;
return x;
```

Check: exit status `42`; also `42` with `x = 42`.

## Exercise 09.4 [core]

Write `ex4.s` that exits with the sign of `x`: -1, 0, or 1. Use **one** `cmp`
for both tests. (Branches do not change the flags.)

Check: `x = -5` gives `255`, `x = 0` gives `0`, `x = 9` gives `1`.

## Exercise 09.5 [core]

Write `ex5.s`: is `y` a leap year?

```c
if ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0) leap = 1;
```

Check: 2024 → 1, 1900 → 0, 2000 → 1, 2023 → 0.

## Exercise 09.6 [core]

Write `ex6.s` that classifies the character in `x1`: exit 1 for a digit,
2 for a lowercase letter, 3 for an uppercase letter, 0 otherwise. Use
character constants like `#'a'`.

Check: `'q'` → 2, `'7'` → 1, `'Q'` → 3, `'#'` → 0.

## Exercise 09.7 [core]

This program should report that a huge size is too big, but exits with 0. Run
it, explain the bug, and write the fixed `ex7.s`.

```asm
    movz x1, #0x8000, lsl #48   // size  = 0x8000000000000000 (unsigned long)
    mov x2, #100                // limit = 100
    mov x0, #0                  // too_big = 0
    cmp x1, x2
    b.le end_if                 // if (size > limit) ...
    mov x0, #1                  // too_big = 1
end_if:
```

Check: the fixed version exits with `1`.

## Exercise 09.8 [stretch]

Write `ex8.s` that classifies a triangle with sides `a`, `b`, `c`: exit 0 if
the sides cannot form a triangle (any two sides add up to no more than the
third), 1 for equilateral, 2 for isosceles, 3 for scalene.

Check: 3,4,5 → 3; 2,2,2 → 1; 5,5,8 → 2; 1,2,3 → 0.

## Exercise 09.9 [stretch]

Write `ex9.s` that detects overflow: add 1 to the largest `long`
(`0x7fffffffffffffff`) and branch on V; add 1 to the largest `unsigned long`
(`0xffffffffffffffff`) and branch on C. Exit with 1 for a signed overflow
plus 2 for an unsigned overflow.

Check: exit status `3`. Then change the second addition to `0xfffffffffffffffe + 1`:
exit status `1`.
