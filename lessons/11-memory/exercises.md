# Lesson 11 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p work && cd work
$ cp ../examples/Makefile .
```

Then `make` builds every `.s` file you put there. Try each exercise properly
before you look at [linux/solutions/](linux/solutions/). Written answers are in
[answers.md](answers.md).

Several programs need to print a number. Copy the "print x19 in decimal" block
from [linux/examples/printnum.s](linux/examples/printnum.s), together with its `numbuf` in
`.bss`.

## Exercise 11.1 [warm-up]

Memory at address `x0` holds these bytes, lowest address first:

```
x0+0: 0x9c   x0+1: 0xff   x0+2: 0x01   x0+3: 0x80
```

Write down the full 64-bit value of `x1` (in hex) after each instruction, run on
its own:

1. `ldrb w1, [x0]`
2. `ldrsb x1, [x0]`
3. `ldrh w1, [x0]`
4. `ldrsh x1, [x0]`
5. `ldr w1, [x0]`
6. `ldrsw x1, [x0]`
7. `ldrsb w1, [x0, #3]`

Check yourself in gdb: put the four bytes in `.data` with `.byte`, run each
load, and `info registers x1`.

## Exercise 11.2 [warm-up]

`x0` = `0x1000` and `x9` = 3 before each line (each line runs on its own). For
each, give the address that is accessed and the value of `x0` afterwards.

1. `ldr x1, [x0]`
2. `ldr x1, [x0, #16]`
3. `ldr x1, [x0, x9, lsl #3]`
4. `ldr w1, [x0, x9, lsl #2]`
5. `ldr x1, [x0, #16]!`
6. `ldr x1, [x0], #16`
7. `strb w1, [x0, #-1]!`
8. `ldp x1, x2, [x0], #16` (give both addresses)

## Exercise 11.3 [warm-up]

The assembler starts this `.data` section at address `0x2000`:

```asm
    .data
a:  .byte 0x41
b:  .word 0xcafebabe
    .p2align 3
c:  .quad 1
d:  .hword 0x1234
```

1. What address does each label get?
2. Write out every byte from `0x2000` up to the end of `d`, including any
   padding.
3. Is `b` naturally aligned? Rewrite the section so that every value is
   naturally aligned while wasting as few bytes as possible.

## Exercise 11.4 [core]

File: `ex4.s`. In `.data` define two `.quad` variables, `x` = 7 and `y` = 42.
Swap them in memory (load both, store each into the other). Then exit with the
value now in `x`.

Check: `./ex4; echo $?` prints `42`. Bonus: do the swap with one `ldp` and one
`stp`, by placing `x` and `y` next to each other.

## Exercise 11.5 [core]

File: `ex5.s`. In `.data`, put the string `"hello, world\n"` with `.ascii` and a
length (use `.equ`). Count how many bytes are the letter `'l'` and exit with the
count. Walk the string with a post-index `ldrb`.

Check: `./ex5; echo $?` prints `3`.

## Exercise 11.6 [core]

File: `ex6.s`. Read a line from standard input into a buffer in `.bss`, change
every lowercase letter (`'a'` to `'z'`) to uppercase, and write the result.
Leave other characters alone. (Uppercase is lowercase minus 32.)

Check:

```console
$ echo 'Hello, World 42!' | ./ex6
HELLO, WORLD 42!
```

## Exercise 11.7 [core]

File: `ex7.s`. Print the numbers 1 to 10, one per line, by putting the print
block inside a loop. Keep the loop counter in `x19` or `x20` (the print block
uses only `x0`-`x6`).

Check: `./ex7` prints `1` to `10` on ten lines.

## Exercise 11.8 [core]

File: `ex8.s`. Read one line containing two decimal numbers separated by one
or more spaces, and print their sum.

Hint: parse the first number with the loop from `double.s`. When it stops on a
non-digit, skip spaces, then parse the second number with a second copy of the
loop. Think about what the pointer and the byte count hold when the first loop
stops.

Check:

```console
$ echo '12 30' | ./ex8
42
$ echo '1000000   2345' | ./ex8
1002345
```

## Exercise 11.9 [stretch]

File: `ex9.s`. Print a **signed** number. Put `-12345` in `x19` (`mov x19,
#-12345`). If it is negative, print a `'-'` (a 1-byte `write` from a buffer, or
store it before the digits), then print its absolute value with the usual
block (`neg` gives the absolute value).

Check: `./ex9` prints `-12345`. Change the value to `678` and to `0` and check
those print correctly too.

## Exercise 11.10 [stretch]

File: `ex10.s`. Print the number in `x19` in **hexadecimal**, as `0x` followed
by exactly 16 hex digits. Put the 16 characters `"0123456789abcdef"` in `.data`
and pick each digit with a register-offset `ldrb` from that table. Take the
4-bit groups with `and` and `lsr` (lesson 08), filling the buffer backwards
just like the decimal block.

Check: with `x19 = 0xdeadbeef`, `./ex10` prints `0x00000000deadbeef`.
