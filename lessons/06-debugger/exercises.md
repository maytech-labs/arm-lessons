# Lesson 06 exercises

Work in `lessons/06-debugger/linux/work/` (on macOS: `apple-silicon/work/`) inside the container, using the programs
in `examples/` (build them with `make -C ../examples`).

Try each exercise before looking at the answers: programs are in
[linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

## Exercise 06.1 [warm-up]

From memory, write the `gdb` command that:

1. pauses a program before its first instruction
2. executes one instruction
3. executes five instructions
4. shows `x3` in hex
5. shows `x3` in binary
6. shows 16 bytes of memory in hex, starting at the address in `x1`
7. shows the zero-terminated string at the address in `x1`
8. stops whenever the program reaches the label `loop`
9. makes `x0` equal 99

## Exercise 06.2 [warm-up]

Run `regs` under `gdb`. Before each `si`, write down what you expect `x0`-`x4`
to be *after* that instruction. Then step and check. Fill in a table:

| After instruction | x0 | x1 | x2 | x3 | x4 |
|-------------------|----|----|----|----|----|
| `mov x0, #1` | | | | | |
| ... | | | | | |

What value did each register have before the program changed it?

## Exercise 06.3 [core]

Use `bytes` and the `x` command to answer:

1. What are the four bytes at `word`, in hex? Which character is each?
2. What is the byte at `small+3`, in hex and in decimal?
3. `x/1xw &small` shows the four bytes `01 02 03 ff` as one 32-bit word.
   Predict the value before you run it, then check.
4. What does `x/2xw &big` show, and why are the two words in that order?
5. What does `x/s &word` print, and why does it not stop after `ARM!`?

## Exercise 06.4 [core]

Using only the debugger (not by reading the source), prove what is wrong with
`broken.s`: stop just before the `write` system call and show which registers
hold the wrong values. Then stop just after it and show the value `write`
returned. Finally, write a fixed `ex4.s` that prints `Hi!`.

## Exercise 06.5 [core]

Without editing any file, make `regs` exit with status 7: run it under `gdb`,
stop before its final `svc`, change a register, and continue. Which register
did you change, and why that one?

## Exercise 06.6 [core]

In `hello`, stop just before the `write`'s `svc` and change `x2` to 5.
Continue. What is printed? What does `write` return in `x0`?

## Exercise 06.7 [stretch]

Write `ex7.s`: a copy of `hello.s` with two extra labels, `before_write` right
before the `write`'s `svc` and `before_exit` right before the `exit`'s `svc`.
Then, using only breakpoints and `continue` (no `si`):

1. Stop at `before_write` and show the three arguments.
2. Stop at `before_exit` and show `write`'s result.
3. Make the program exit with 7.

Do the extra labels change the program's output or size? Check with
`objdump -d`.

## Exercise 06.8 [stretch]

Use `display/x $pc` and step through `hello` with `si`. Write down every value
of `pc`. By how much does it grow each step? What is `pc` right after the
first `svc` returns, relative to the `svc` instruction's own address?
