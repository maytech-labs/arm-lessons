# Lesson 13 exercises

Work in `lessons/13-the-stack/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Try each exercise before looking at the answers: programs are in
[solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md).

## Exercise 13.1 [warm-up]

`sp` starts at `0x1000`, `x1 = 1`, `x2 = 2`, `x3 = 3`. After each line, what is
`sp`, and which values are stored at which addresses?

```asm
    stp x1, x2, [sp, #-16]!
    str x3, [sp, #-16]!
    ldr x4, [sp], #16
    ldp x5, x6, [sp], #16
```

What are `x4`, `x5`, `x6` at the end?

## Exercise 13.2 [warm-up]

How many bytes should you reserve with `sub sp` for each set of locals?

1. one `long`
2. one `int`
3. three `long`s
4. `char buf[100]`
5. `int a[5]` and two `long`s

## Exercise 13.3 [core]

Write `ex3.s` that swaps `x1 = 3` and `x2 = 7` using one `stp` and one `ldp`
and no other register, then exits with `x1 * 10 + x2`.

Check: exit status `73`.

## Exercise 13.4 [core]

Write `ex4.s` that prints `7 365 1000000` by converting each number in its
**own** 32-byte stack buffer, reserved just before and released just after it
is printed. (Lesson 14 will make this a function; for now, repeat the block.)

Check: output `7 365 1000000`; `sp` at the end equals `sp` at the start
(check in the debugger).

## Exercise 13.5 [core]

Write `ex5.s` that reads a line (up to 128 bytes) into a stack buffer and
prints it with every lowercase letter changed to uppercase. Hint: subtracting
`'a'` and doing one **unsigned** compare tests "is it between `'a'` and
`'z'`" in one go.

Check: `echo 'Hello, World 42' | ./ex5` prints `HELLO, WORLD 42`.

## Exercise 13.6 [core]

Write `ex6.s` with a local array `long sq[10]` on the stack. Fill it with
`i * i`, then add the elements up and exit with the sum.

Check: the sum is 285; the exit status is `29` (285 mod 256).

## Exercise 13.7 [stretch]

Write `ex7.s` that reads a line and checks that the brackets `()`, `[]`, `{}`
in it are balanced and properly nested. Print `balanced` (exit 0) or
`unbalanced` (exit 1). Use the stack as a stack: on an opening bracket, push
the closing bracket you now expect; on a closing bracket, pop and compare.
Ignore other characters.

Check:

| Input | Output |
|-------|--------|
| `{a[b(c)d]e}` | balanced |
| `(]` | unbalanced |
| `((` | unbalanced |
| `)` | unbalanced |
| (empty line) | balanced |

## Exercise 13.8 [stretch]

This program should exit with 30 but crashes. Find both bugs without running
it, then confirm with the debugger.

```asm
_start:
    sub sp, sp, #24             // three longs
    mov x0, #10
    str x0, [sp]
    mov x0, #20
    str x0, [sp, #8]
    ldp x1, x2, [sp]
    add x0, x1, x2
    add sp, sp, #16
    mov x8, #93
    svc #0
```
