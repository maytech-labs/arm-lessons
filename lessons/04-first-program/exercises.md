# Lesson 04 exercises

Work in `lessons/04-first-program/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

`make` builds every `.s` file in the directory. Try each exercise before
looking at the answers: programs are in [solutions/](solutions/), written
answers in [solutions/README.md](solutions/README.md).

## Exercise 04.1 [warm-up]

Write `ex1.s` from an empty file, without looking at the lesson, that exits
with a status of your choice between 1 and 255.

Check: `./ex1; echo $?` prints your number.

## Exercise 04.2 [warm-up]

Without running anything, predict what `echo $?` prints if a program does
`mov x0, #N` and then exits, for each N:

1. `0`
2. `255`
3. `256`
4. `257`
5. `1000`
6. `512`

Then check two of them by editing `ex1.s`.

## Exercise 04.3 [core]

Write `ex3.s` that puts 9 into `x2`, then copies it to `x5`, then from `x5` to
`x11`, then from `x11` to `x0`, then exits. Only the first `mov` may use `#`.

Check: `./ex3; echo $?` prints `9`.

## Exercise 04.4 [core]

Label each line of this program as a comment, directive, label, or
instruction. For each instruction, write what it does in C-like notation
(e.g. `x0 = 42`). What is the exit status?

```asm
    .global _start
    .text
    .p2align 2
// the answer to everything
_start:
    mov x1, #20
    mov x2, x1
    mov x0, x2
    mov x1, #30
    mov x8, #93
    svc #0
```

## Exercise 04.5 [core]

Assemble and link `examples/exit42.s` by hand with `as` and `ld` (see the
lesson). Then:

1. Run `nm` on the `.o` file. What letter is next to `_start`?
2. Delete the `.global _start` line, assemble and link again. What does `nm`
   show now? What does `ld` print? Does the program still work?
3. Run `objdump -d` on the `.o` and on the executable. At what address does
   `_start` begin in each? Why are they different?
4. How many bytes is the whole `.text` section? (Hint: `objdump -h`.)

## Exercise 04.6 [core]

`xzr` is the zero register from lesson 03: it always reads as 0. Write `ex6.s`
that first puts 5 into `x0`, then uses `mov` with `xzr` (no `#`) to make the
exit status 0.

Check: `./ex6; echo $?` prints `0`.

## Exercise 04.7 [stretch]

Break things on purpose, one at a time, and write down the exact error
message for each. Restore the file after each step.

1. Write `mov x0 #42` (no comma).
2. Write `move x0, #42`.
3. Write `mov x0, #42` with the label line changed to `_start` (no colon).
4. Write `mov x31, #42`.
5. Remove the `svc #0` line. What happens when you run it, and what does the
   exit status mean?

Learning what the assembler's messages look like now will save you hours later.
