# Lesson 20 exercises

Work in `lessons/20-symbols-and-sections/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

For multi-file exercises, adjust `PARTS` and add a rule, as in
`examples/Makefile`. Try each exercise before looking at the answers:
programs are in [linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

## Exercise 20.1 [warm-up]

Which section, and global or local, for each C declaration at file scope?

1. `int count = 0;`
2. `int total = 7;`
3. `static char buf[256];`
4. `const double pi = 3.14159;`
5. `static const char *names[] = {"a", "b"};` (careful)
6. `int main(void)`
7. `static void helper(void)`
8. `extern int errno_value;`

## Exercise 20.2 [warm-up]

Run `nm` on `examples/app.o`, `examples/mathlib.o`, and the linked `app`.
For each symbol in the object files, say what its letter means. Which `U`
symbols are still undefined in the linked `app`, and why is that allowed?

## Exercise 20.3 [core]

Write `ex3.s` with two functions, `next_id` (returns 1, 2, 3, ...) and
`next_even` (returns 2, 4, 6, ...), each with its own static local counter.
Call each three times and print the results.

Check: `ids: 1 2 3, evens: 2 4 6`.

## Exercise 20.4 [core]

Write a stack module in `stack.s` with three exported functions,
`stack_push(long)`, `stack_pop()`, and `stack_size()`, and **private**
storage (`items[16]` and `count` in `.bss`, not global). Write `ex4.s` with
`main` that pushes 10, 20, 30, prints the size, pops three times, and prints
the size again. Link them together.

Check: `size 3, popped 30 20 10, size 0`. Then try to read `count` from
`ex4.s`: what does the linker say?

## Exercise 20.5 [core]

Write `ex5.s` that builds a table of the cubes 0³..7³ with `.rept` and
`.set`, and prints it using a macro `PRINTF1 fmt, reg` that you define.

Check: `cubes: 0 1 8 27 64 125 216 343`.

## Exercise 20.6 [core]

Produce each of these errors on purpose with `app.s` and `mathlib.s`, and
copy the exact message. Then explain each in one sentence.

1. undefined reference (or "Undefined symbols")
2. multiple definition (or "duplicate symbol")
3. storing a non-zero value in `.bss`
4. `cbz x0, 1b` with no `1:` before it

## Exercise 20.7 [stretch]

Write `ex7.s` with a table of twelve pointers to the month names "Jan" to
"Dec", and a function `show(m)` that prints `m is NAME`. Which section do the
strings go in, and which section does the table go in? Why might they differ?

Check:

```
1 is Jan
6 is Jun
12 is Dec
```
