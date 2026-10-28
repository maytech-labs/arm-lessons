# Lesson 25 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p lessons/25-io-and-args/work && cd lessons/25-io-and-args/work
$ cp ../examples/Makefile ../examples/sample.txt .
```

The copied Makefile builds every `.s` file in the directory. Try each exercise
before you look at the solutions: programs are in [linux/solutions/](linux/solutions/),
written answers in [answers.md](answers.md). On macOS, write
the same programs for your Mac; the macOS solutions are in
[apple-silicon/solutions/](apple-silicon/solutions/).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 25.1 [warm-up]

Written. You run:

```console
$ ./prog one "two three" '' four
```

1. What is `argc`?
2. Write out every element of `argv`, including the last one.
3. What is `argv[3]`, and what does `strlen(argv[3])` return?
4. In `main`, which register holds `argv`, and what single instruction loads
   `argv[2]` into `x0` if `argv` has been copied to `x20`?
5. In a freestanding `_start` program, at what address is `argv[2]`?

## Exercise 25.2 [warm-up]

Write `ex2.s`, a clone of `echo`: print the arguments (not `argv[0]`) separated
by single spaces, then a newline. Use `fputs` with `stdout` (loaded through the
GOT) for the words and `putchar` for the space and the newline.

```console
$ ./ex2 hello   "big world"
hello big world
$ ./ex2

```

(The second run prints just an empty line.)

## Exercise 25.3 [core]

Write `ex3.s`: print the arguments in reverse order, one per line, without
`argv[0]`.

```console
$ ./ex3 a b c
c
b
a
```

## Exercise 25.4 [core]

Write `ex4.s`: convert each argument with `atoi`, add them up in a 64-bit
`long`, and print `sum = N`. Remember `atoi` returns an `int`: sign-extend it
before adding.

```console
$ ./ex4 10 20 -5
sum = 25
$ ./ex4
sum = 0
```

## Exercise 25.5 [core]

Written. Predict the exact output of this program in three cases: (a) run on a
terminal, (b) run as `./prog | cat`, (c) run as `./prog > out.txt; cat out.txt`.
Then explain what changes if you add `fflush(stdout);` right before the
`write` call.

```c
int main(void) {
    printf("one\n");
    printf("two ");
    write(1, "three\n", 6);
    fprintf(stderr, "four\n");
    printf("five\n");
    return 0;
}
```

(Case (c): `four` goes to the terminal, not into `out.txt`.)

## Exercise 25.6 [core]

Write `ex6.s`, a `cp` clone: `./ex6 SRC DST` copies the file `SRC` to `DST`
using the libc wrappers `open`, `read`, `write`, and `close` (no stdio for the
data). Open `DST` with `O_WRONLY | O_CREAT | O_TRUNC` and mode `0644`. Look up
the flag values in `/usr/include/asm-generic/fcntl.h` (in the container); they
are not the same on every system.

- Wrong number of arguments: print `usage: ex6 SRC DST` to `stderr`, exit 2.
- `SRC` or `DST` cannot be opened: `perror` the file name, exit 1.
- Loop `read` until it returns 0; check that each `write` wrote everything.

```console
$ ./ex6 sample.txt copy.txt && cmp sample.txt copy.txt && echo same
same
$ ./ex6 nope.txt copy.txt; echo $?
nope.txt: No such file or directory
1
$ ./ex6 ex6 ex6copy && cmp ex6 ex6copy && echo same
same
```

## Exercise 25.7 [core]

Write `ex7.s`, a tiny `grep`: `./ex7 WORD [FILE]` prints every line of `FILE`
(or `stdin`) that contains `WORD`. Use `fgets` with a 256-byte buffer and
`strstr(line, word)`, which returns a pointer to the first match or `NULL`.
Exit status like the real `grep`: 0 if any line matched, 1 if none did, 2 for a
usage error or a file that cannot be opened.

```console
$ ./ex7 the sample.txt; echo $?
jumps over the lazy dog.
with the lid off.
0
$ ./ex7 zebra sample.txt; echo $?
1
$ printf 'cat\ndog\ncatalog\n' | ./ex7 cat
cat
catalog
```

## Exercise 25.8 [stretch]

Write `ex8.s`, a `uniq` clone: read lines from `stdin` and print each line
unless it is identical to the line just before it. Use two 256-byte buffers in
`.bss`, read into one, compare with the other using `strcmp`, then *swap the two
pointers* instead of copying the line.

```console
$ printf 'a\na\nb\na\na\na\nc\n' | ./ex8
a
b
a
c
```

## Exercise 25.9 [stretch]

Write `ex9.s`, a `wc` that accepts any number of files, like the real one.
Move the counting loop into a function
`void count_stream(FILE *in, struct counts *c)` where
`struct counts { long lines, words, bytes; }` is laid out with `.equ` offsets
(lesson 19). `main` keeps one `struct counts` for the current file and one for
the running total in its stack frame.

- No arguments: count `stdin` and print `lines words bytes`.
- Otherwise print `lines words bytes name` for each file, and a
  `lines words bytes total` line if more than one file was counted.
- A file that cannot be opened: `perror`, remember to exit 1, keep going.

```console
$ ./ex9 sample.txt sample.txt
12 24 117 sample.txt
12 24 117 sample.txt
24 48 234 total
$ printf 'one two\nthree\n' | ./ex9
2 3 14
$ ./ex9 nope.txt sample.txt; echo $?
nope.txt: No such file or directory
12 24 117 sample.txt
1
```
