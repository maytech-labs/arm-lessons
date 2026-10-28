# Lesson 05 exercises

Work in `lessons/05-hello-world/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Try each exercise before looking at the answers: programs are in
[linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 05.1 [warm-up]

Answer without running anything:

1. Which register holds each of `write`'s three arguments, and which holds the
   system call number?
2. What do file descriptors 0, 1, and 2 refer to?
3. How many bytes does `.ascii "Hi!\n"` produce? And `.asciz "Hi!\n"`?
4. What is the value of `len` here?

   ```asm
   s:  .ascii "abc"
       .ascii "\t\n"
       .equ len, . - s
   ```

5. In `hello.s`, which instruction produces the address of `msg`: `adrp`,
   `add`, or both?

## Exercise 05.2 [warm-up]

Write `ex2.s` that prints `Hi, my name is NAME.` (with your name) followed by
a newline, then exits with status 0. Put the message in `.rodata` and let the
assembler compute the length.

Check: `./ex2` prints your line; `echo $?` prints `0`.

## Exercise 05.3 [core]

Break `hello.s` on purpose, one change at a time. For each, predict the
output first, then run it (pipe through `xxd` to see invisible bytes:
`./hello | xxd`).

1. Replace `#msg_len` with `#5`.
2. Replace `#msg_len` with `#40`.
3. Delete the `add x1, x1, :lo12:msg` line.
4. Change `.ascii` to `.asciz` (keep `. - msg`).
5. Change the fd to 0.

## Exercise 05.4 [core]

Write `ex4.s` that prints this box using exactly **two** strings in `.rodata`
and **three** `write` calls:

```
+------+
| asm! |
+------+
```

## Exercise 05.5 [core]

Write `ex5.s` that prints `working...` to stdout, then `error: disk full` to
stderr, and exits with status 3.

Check:

```console
# ./ex5 2>/dev/null       # only "working..."
# ./ex5 >/dev/null        # only "error: disk full"
# ./ex5; echo $?          # both lines, then 3
```

## Exercise 05.6 [stretch]

Keep the string `"Hello, world!\n"` exactly as in `hello.s`. Write `ex6.s`
that prints only `world`, followed by a newline. You may add one more tiny
string for the newline. Do not type the length of `world` into the
`.rodata` section.

## Exercise 05.7 [stretch]

`write` returns the number of bytes written in `x0`. Modify `hello.s` so that
it exits with that number, without any `mov x0` before the `exit`. What does
`echo $?` show? What would it show if the write failed? (Try changing the fd
to 7, a file descriptor that is not open, and run it.)
