# Lesson 25 solutions

Try each exercise before reading these. Programs: `ex2.s`, `ex3.s`, `ex4.s`,
`ex6.s`, `ex7.s`, `ex8.s`, `ex9.s`. Build them all with `make`; `make clean`
also removes `copy.txt` if you made one while testing `ex6`. The commands in
each file's header are written to run from this directory, so they refer to
`../examples/sample.txt`.

## Exercise 25.1

1. `argc` is 5: `./prog`, `one`, `two three`, the empty string, `four`.
2. ```
   argv[0] = "./prog"
   argv[1] = "one"
   argv[2] = "two three"
   argv[3] = ""
   argv[4] = "four"
   argv[5] = NULL
   ```
3. `argv[3]` is a valid pointer to an empty string: its first byte is `'\0'`.
   `strlen` returns 0. (It is *not* `NULL`. An empty argument still counts.)
4. `argv` arrives in `x1`. With `argv` in `x20`: `ldr x0, [x20, #16]`
   (index 2 times 8 bytes). With the index in a register, `x21 = 2`:
   `ldr x0, [x20, x21, lsl #3]`.
5. `argc` is at `sp`, `argv[0]` at `sp + 8`, so `argv[2]` (the pointer) is
   at `sp + 24`: `ldr x0, [sp, #24]`.

## Exercise 25.5

Remember: stdout is line buffered on a terminal and fully buffered to a pipe or
file; `write` bypasses the buffer; stderr is unbuffered; `exit` flushes stdout.

**(a) Terminal**

```
one
three
four
two five
```

`one\n` is flushed by its newline. `two ` waits in the buffer (no newline).
`three` goes straight out through `write`, `four` straight out through stderr.
`five\n` completes the buffered line `two five\n`, which is then flushed.

**(b) `./prog | cat`**

stdout is now a pipe, so nothing is flushed until exit. The pipe carries:

```
three
one
two five
```

`four` does not go through the pipe at all: it is written straight to the
terminal by `prog`, so it usually appears before cat's lines, but the order
between `four` and cat's output is up to the two processes.

**(c) `./prog > out.txt`**

`out.txt` contains the same as the pipe in (b): `three`, `one`, `two five`.
`four` is printed on the terminal.

**With `fflush(stdout)` before `write`**: the buffer (`one\ntwo ` or just
`two `) is written out before `three`, so stdout reads, in all three cases:

```
one
two three
five
```

with `four` on stderr (in case (a) it appears between `two three` and `five`).
That is the fix whenever you must mix stdio with raw `write` on the same fd.
