# Lesson 24 exercises: Function pointers

Work in `lessons/24-function-pointers/work/` (it is git-ignored). Copy the
Makefile from `examples/` into it so `make` works there. Try every exercise
before you look at `solutions/`: written answers are in
[solutions/README.md](solutions/README.md), programs are `solutions/exN.s`.

All programs define `main`, link libc, and print with `printf` or `puts`.

## Exercise 24.1 [warm-up]

Answer on paper.

1. The instruction `blr x9` is at address `0x1000`. What is in `x30` right after
   it executes? What would be in `x30` if it were `br x9` instead?
2. Why does `for_each` in `callback.s` copy its `fn` argument into `x21` instead
   of calling `blr x2` every time round the loop?
3. A jump table starts at address `0x2040` and holds `.word` entries
   `-40, -32, -24, -16`. The index is 3. Which address does `br` jump to?
4. The bounds check in `calc` is `cmp w0, #4` / `b.hs calc_default`. What happens
   for `op = -1` if you replace `b.hs` with `b.ge`?
5. Give two values `a`, `b` of type `int` for which a comparator returning
   `a - b` gives the wrong sign.
6. Why is the `ops` table in `dispatch_table.s` in `.data`, while `calc_table`
   in `jump_table.s` can sit in `.text`?

## Exercise 24.2 [warm-up]

File: `ex2.s`. Write `int twice(int (*f)(int), int x)` that returns `f(f(x))`,
and two callbacks, `add3` (returns `x + 3`) and `square` (returns `x * x`).
`main` prints:

```console
$ ./ex2
twice(add3, 10) = 16
twice(square, 3) = 81
```

Hint: `twice` calls `f` twice, so `f` must survive the first call.

## Exercise 24.3 [core]

File: `ex3.s`. Sort `int nums[7] = {5, 12, -3, 7, 0, 12, 1}` into *descending*
order with `qsort` and your own comparator `cmp_desc`. Print the array on one
line, then use `bsearch` to find `7` and print its index:

```console
$ ./ex3
12 12 7 5 1 0 -3
found 7 at index 2
```

Think about which comparator `bsearch` must use on an array sorted in
descending order.

## Exercise 24.4 [core]

File: `ex4.s`. Sort an array of strings:

```c
const char *words[5] = {"pear", "apple", "fig", "banana", "cherry"};
```

with `qsort`, using a comparator that calls `strcmp`, then print one per line
with `puts`:

```console
$ ./ex4
apple
banana
cherry
fig
pear
```

Careful: the elements are pointers (8 bytes each), and the comparator receives
*pointers to* those pointers. Where must `words` live, and why?

## Exercise 24.5 [core]

File: `ex5.s`. Write

```c
long reduce(const long *a, long n, long init, long (*f)(long, long));
```

which starts with `acc = init` and does `acc = f(acc, a[i])` for every element.
With `long nums[5] = {4, -2, 9, 7, 1}`, use it three times: with an `add`
function and `init = 0`, with a `max` function and `init = nums[0]`, and with a
`mul` function and `init = 1`. Print:

```console
$ ./ex5
sum = 19
max = 9
product = -504
```

## Exercise 24.6 [core]

File: `ex6.s`. Translate this `switch` into a jump table (gaps and shared cases
included, no compare chains):

```c
int f(int x) {
    switch (x) {
    case 1:  return x * 10;
    case 2:  return x + 100;
    case 3:
    case 4:  return -x;
    case 6:  return 0;
    default: return 99;
    }
}
```

`main` prints `f(x)` for `x` from -1 to 7:

```console
$ ./ex6
f(-1) = 99
f(0) = 99
f(1) = 10
f(2) = 102
f(3) = -3
f(4) = -4
f(5) = 99
f(6) = 0
f(7) = 99
```

## Exercise 24.7 [core]

File: `ex7.s`. Build a command table: an array of

```c
struct command { const char *name; void (*run)(void); };   // 16 bytes
```

ending with a `{0, 0}` entry, holding commands `hello` (prints `Hello!`), `count`
(prints `1 2 3`) and `help` (prints every command name in the table, indented two
spaces). Write `void dispatch(const char *word)` that prints `> word`, finds the
command with `strcmp`, and calls its `run`; if nothing matches it prints
`unknown command: word`. `main` dispatches `"hello"`, `"count"`, `"nope"`,
`"help"`:

```console
$ ./ex7
> hello
Hello!
> count
1 2 3
> nope
unknown command: nope
> help
  hello
  count
  help
```

## Exercise 24.8 [stretch]

File: `ex8.s`. Write a tiny stack machine. A program is an array of 8-byte words;
`PUSH` is followed by its operand:

| Opcode | Name | Effect |
|--------|------|--------|
| 0 | `HALT` | stop, return 0 |
| 1 | `PUSH n` | push `n` |
| 2 | `ADD` | pop `b`, pop `a`, push `a + b` |
| 3 | `SUB` | pop `b`, pop `a`, push `a - b` |
| 4 | `MUL` | pop `b`, pop `a`, push `a * b` |
| 5 | `PRINT` | pop `a`, print it with `printf("%ld\n")` |
| 6 | `DUP` | push a copy of the top |

Any other opcode prints `bad opcode N` and returns 1. Decode instructions with a
jump table. Run this program, which computes `(2 + 3) * 7`, `10 * 10` and `1 - 50`:

```
PUSH 2, PUSH 3, ADD, PUSH 7, MUL, PRINT,
PUSH 10, DUP, MUL, PRINT,
PUSH 1, PUSH 50, SUB, PRINT,
HALT
```

```console
$ ./ex8
35
100
-49
$ echo $?
0
```

Then put a `9` in the program and check that you get `bad opcode 9` and exit
status 1.
