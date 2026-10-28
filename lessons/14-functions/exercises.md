# Lesson 14 exercises

Work in `lessons/14-functions/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Copy `print_uint` and `print_char` from `examples/print_uint.s` into any
program that prints. Try each exercise before looking at the answers:
programs are in [linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

## Exercise 14.1 [warm-up]

In `examples/frame.s`, use the debugger to find the value of `x30`:

1. at the first instruction of `sum_squares`
2. at the first instruction of `square`, the first time it is called
3. at the first instruction of `square`, the second time
4. just before `sum_squares` executes its `ret`

For each, use `x/i $x30` to see which instruction it points at. Which of
these values are the same, and why?

## Exercise 14.2 [warm-up]

For each function, say whether it is leaf or non-leaf, and whether it must
save `x30`:

1. a function that adds its two arguments
2. a function that calls `print_uint` twice
3. a function that makes a `write` system call and returns
4. a function that calls itself
5. a function that uses `b` (not `bl`) to jump to another function's label at
   its very end, instead of returning itself

## Exercise 14.3 [core]

Write `ex3.s` with a leaf function `max(a, b)` and a non-leaf function
`max3(a, b, c)` that calls `max` twice. Exit with `max3(12, 99, 57)`.

Check: exit status `99`.

## Exercise 14.4 [core]

Write `ex4.s` with a non-leaf function `print_line(n)` that prints `n`
followed by a newline (by calling `print_uint` and `print_char`), and a loop in
`_start` that calls it for 1 to 10.

Check: prints 1 to 10, one per line.

## Exercise 14.5 [core]

Write `ex5.s` with a leaf `abs_(x)` and a non-leaf `dist(a, b)` that returns
`abs_(a - b)`. Print `dist(3, 10)`, `dist(10, 3)`, and `dist(-4, 4)`.

Check: prints `7 7 8`.

## Exercise 14.6 [core]

Write `ex6.s` with a leaf function `print_hex(n)` that prints `n` in
hexadecimal with a `0x` prefix and lowercase digits. Use `and`/`lsr` (lesson
08) instead of division.

Check: `print_hex(0xdeadbeef)`, `print_hex(0)`, `print_hex(255)` print
`0xdeadbeef 0x0 0xff`.

## Exercise 14.7 [stretch]

Write `ex7.s` with a function `print_row(n)` that prints `n`, `n²`, and `n³`
separated by spaces and followed by a newline. It must keep `n` in its frame
across its calls. Call it for `n` = 1 to 5.

Check:

```
1 1 1
2 4 8
3 9 27
4 16 64
5 25 125
```

## Exercise 14.8 [stretch]

Each of these functions has one bug. Find it, say what would happen at run
time, and fix it.

```asm
// (a) long twice_square(long n) { return 2 * square(n); }
twice_square:
    bl square
    lsl x0, x0, #1
    ret

// (b) long sum3(long a, long b, long c) { return add(add(a, b), c); }
sum3:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    bl add
    mov x1, x2
    bl add
    ldp x29, x30, [sp], #16
    ret

// (c) long clamp0(long x) { if (x < 0) return 0; return helper(x); }
clamp0:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    cmp x0, #0
    b.ge clamp0_call
    mov x0, #0
    ret
clamp0_call:
    bl helper
    ldp x29, x30, [sp], #16
    ret
```
