# Lesson 00 exercises

Work in `lessons/00-setup/linux/work/` (on macOS: `apple-silicon/work/`) (create it, and copy `examples/Makefile` into
it, as the lesson showed). Everything in `work/` is ignored by git.

Try every exercise before you look at the answers. Written answers are in
[answers.md](answers.md); programs are in
[linux/solutions/](linux/solutions/).

Do these exercises in the Linux container. The companion lesson,
[apple-silicon/](apple-silicon/), says how to do
the same ones on macOS.

## Exercise 00.1 [warm-up]

Get the environment working. Write down the output of each of these:

1. On macOS: `clang --version` (the first two lines).
2. On macOS: `docker run --rm hello-world` (the line that starts "Hello").
3. Inside `./scripts/linux-shell.sh`: `uname -sm`.
4. Inside the container: `gcc --version` (the first line).

Check: (1) mentions `arm64`, (2) says `Hello from Docker!`, (3) says
`Linux aarch64`, (4) mentions `gcc`.

## Exercise 00.2 [warm-up]

In the container, in `lessons/00-setup/linux/examples/`:

1. Run `make`, then `./check`, then `echo $?`. Write down what each printed.
2. Now run `./check`, then `echo $?`, then `echo $?` again. Why is the second
   `echo $?` 0 whatever the program did?
3. Run `make` again without changing anything. What does it say, and why?
4. Run `make clean`, then `ls`. What disappeared?

## Exercise 00.3 [core]

Copy `examples/check.s` to `work/ex3.s`. Find the line that sets the exit
status (it says "exit status" in its comment) and change the program so it
exits with status **7** instead of 0. Change nothing else.

Check:

```console
$ make ex3
$ ./ex3
toolchain works
$ echo $?
7
```

## Exercise 00.4 [core]

Copy `examples/check.s` to `work/ex4.s`. Change the program so that it prints
`I built this myself!` (followed by a new line) instead of `toolchain works`.
You only need to change the text between the quotes. Keep the `\n` at the end.

Check:

```console
$ make ex4
$ ./ex4
I built this myself!
```

Then answer: the message got longer, but you did not tell the program the
new length anywhere. Look at the last line of the file. Can you guess which
line works the length out for you? (Lesson 05 explains it.)

## Exercise 00.5 [core]

Use `file` to answer these about the programs in `examples/` (build them first):

1. What does `file check` say about the file format and the CPU?
2. What does `file check.s` say? Why is it different?
3. What does `file Makefile` say?

## Exercise 00.6 [core]

Use `nm check`.

1. Find the line for `_start`. Write down the hex number in front of it.
2. Find the line for `msg`. Write down its hex number.
3. Which one has the bigger number? (Both are hex, which is lesson 01, but you
   can compare them digit by digit from the left, just like decimal.)

## Exercise 00.7 [stretch]

Use `objdump -d check`.

1. How many instructions does `check` contain? (Count the lines under
   `<_start>:`.)
2. Look at the address column on the left. By how much does it go up from one
   instruction to the next? What does that suggest about the size of an
   instruction?
3. Find the instruction `mov x0, #0x0`. That is the line you changed in
   exercise 00.3. Now run `objdump -d` on your `work/ex3`. What changed in that
   line, in both the middle (hex) column and the right (text) column?

## Exercise 00.8 [stretch]

Compile a C program in the container. In `work/`, create `hello.c`:

```c
#include <stdio.h>

int main(void) {
    printf("hello from C\n");
    return 5;
}
```

Build it with `gcc hello.c -o hello` (not `make`: the Makefile only handles
`.s` files). Run it and check its exit status. Then compare it with `check`:

1. `ls -l hello ../examples/check`: which file is bigger?
2. `nm hello | wc -l` and `nm ../examples/check | wc -l`: how many symbols does each have?
3. `file hello`: what does it say that `file check` did not?

You do not need to understand the answers yet. The point: a C program comes
with a lot of extra machinery (the C library). The assembly programs in
lessons 04 to 15 have none; every byte in them is one you wrote.
