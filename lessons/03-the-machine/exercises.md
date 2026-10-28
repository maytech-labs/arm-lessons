# Lesson 03 exercises

Work in `lessons/03-the-machine/linux/work/` (on macOS: `apple-silicon/work/`) inside the container (create it and
copy `examples/Makefile` into it, as in lesson 00). Build the examples first:
`make -C ../examples`.

Try each exercise before looking at the answers. Written answers are in
[answers.md](answers.md); the one program is
[linux/solutions/ex4.s](linux/solutions/ex4.s).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 03.1 [warm-up]

Registers.

1. How many general-purpose registers does AArch64 have, and what are they
   called? How many bits does each hold?
2. What is `w7`?
3. `x3` holds `0xFFFFFFFFFFFFFFFF`. An instruction writes the value 5 into
   `w3`. What does `x3` hold now?
4. `x4` holds `0x123456789ABCDEF0`. What value does an instruction that reads
   `w4` see?
5. An instruction writes 7 into `xzr`. Then another reads `xzr`. What does it
   get?
6. Which register holds the address of the instruction being run?
7. Which register must you never use in this course?

## Exercise 03.2 [warm-up]

Memory.

1. A 32-bit word is stored at address `0x2000`. Which addresses does it
   occupy? At what address does the next word start?
2. A 64-bit doubleword is stored at `0x2000`. Which addresses does it occupy?
3. How many bytes are there from address `0x1000` up to and including
   `0x1FFF`?
4. A C `long` holding the value 1 is stored at `0x3000`. Which address holds
   the byte `01`? What is in the other seven bytes?
5. On AArch64, how many bytes does a pointer take?

## Exercise 03.3 [core]

Run `objdump -d ../examples/encoding`.

1. How many instructions does the program have?
2. How many bytes of code is that?
3. What are the address of the first instruction and the address of the last
   one? Check: is the difference what you expect from your answer to 2?
4. Write down the hex encoding of `svc #0`.

## Exercise 03.4 [core]

Predict, then check. Using what you found in the lesson about the fields of
`mov` (register in bits 0-4, number in bits 5-20, bit 31 for `x` vs `w`),
write down the hex encoding you expect for each:

1. `mov x3, #42`
2. `mov x0, #43`
3. `mov w1, #42`

Then check yourself: copy `../examples/encoding.s` to `ex4.s` in your `work/`
directory, replace the six `mov` lines before `mov x8, #93` with your three
instructions followed by `mov x0, #42`, build it with `make ex4`, and look at
`objdump -d ex4`. The program must still exit with status 42:

```console
$ make ex4
$ ./ex4; echo $?
42
```

## Exercise 03.5 [core]

Look at `../examples/bytes.s`, then *before running anything* predict what
`objdump -s -j .data ../examples/bytes` will print in the hex columns. Run it
and compare.

Then answer without running anything:

1. If the `.word` line said `.word 0xCAFEF00D`, what four bytes would appear
   in its place?
2. If the `.ascii` line said `.ascii "ABC"`, what three bytes would appear?
   (The character code of `A` is `0x41`, and the letters go up by one from
   there.)
3. In `objdump -s -j .text ../examples/bytes`, the second group is `a80b80d2`.
   Which instruction is it? (Reverse the bytes, then compare with the
   `objdump -d` output.)

## Exercise 03.6 [core]

Run the assembler and linker yourself, in `work/`:

```console
$ cp ../examples/encoding.s .
$ as encoding.s -o encoding.o
$ ld encoding.o -o encoding
```

1. What does `file encoding.o` say? What does `file encoding` say? Which word
   shows the difference?
2. Compare the addresses in `objdump -d encoding.o` with `objdump -d
   encoding`. Why are they different?
3. What is the entry point address in `readelf -h encoding`? Which symbol in
   `nm encoding` has that address?
4. Run `./encoding.o`. What happens, and why?
5. Run `./encoding; echo $?`. Does your hand-built program behave the same as
   the one `make` built?

## Exercise 03.7 [core]

For each task, say whether a program can do it with ordinary instructions on
its own, or whether it needs a system call:

1. Add two numbers in registers.
2. Print a message on the screen.
3. Copy a value from one register to another.
4. Read a file from the disk.
5. End the program and report an exit status.
6. Compare two numbers.
7. Find out the current time.
8. Read a byte from the program's own memory.

## Exercise 03.8 [stretch]

Trace this program by hand, fetch-decode-execute style. It is loaded with
`_start` at address `0x400100`.

```asm
_start:
    mov x0, #5
    mov x1, #7
    mov x0, #9
    mov w1, #3
    mov x8, #93
    svc #0
```

Make a table with a row per instruction showing `pc` before it runs, and the
values of `x0` and `x1` after it runs. What is the exit status? What is the
address of the `svc` instruction?

## Exercise 03.9 [stretch]

Decode and encode by hand, using the `mov` fields from the lesson.

1. Decode `d2800ba8`: which register, which number? (Check: it is in
   `encoding`.)
2. Decode `52800fe1`. Is it an `x` or a `w` register?
3. Encode `mov x30, #0xFFFF`.
4. Encode `mov x5, #0`.
5. Why can this instruction not hold the number 70000? (Hint: how many bits
   does the number field have?) Lesson 07 shows how to build bigger numbers.
