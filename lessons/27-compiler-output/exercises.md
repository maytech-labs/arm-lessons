# Lesson 27 exercises

Work in a `work/` directory inside this lesson's `linux/` folder (on macOS: `apple-silicon/`) (it is git-ignored):

```console
$ mkdir -p lessons/27-compiler-output/work
$ cd lessons/27-compiler-output/work
```

Generate compiler output there too, never in `examples/` or `solutions/`. For
the programming exercises, write the C first (`exN.c`), translate it by hand
with the recipe from the lesson, *then* compare with `gcc -O2 -S -o - exN.c`.

Try each exercise properly before you look at the solution. Solutions are in
[linux/solutions/](linux/solutions/); written answers are in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 27.1 [warm-up]

Copy `examples/funcs.c` into `work/` and run:

```console
$ gcc -O0 -S -o - funcs.c | grep -v '\.cfi' | less
```

Find `sum_of_squares` and `square` and answer:

1. At `-O0`, is `square` called with `bl`, or inlined?
2. `sum_of_squares` uses `x19` even at `-O0`. Why does it need a callee-saved
   register? (Hint: what is still needed after the first `bl square`?)
3. How big is its frame, and what is in each slot?
4. Now look at the same two functions at `-O2`. What happened to `square`?

## Exercise 27.2 [warm-up]

Each listing below is real `gcc -O2` output for a short C function (noise
removed). Write C that would produce it. Give each function a sensible name
and type.

```asm
mystery1:
	cmp	w0, 0
	csneg	w0, w0, w0, ge
	ret
```

```asm
mystery4:
	mov	w1, 52429
	movk	w1, 0xcccc, lsl 16
	umull	x1, w0, w1
	lsr	x1, x1, 35
	add	w1, w1, w1, lsl 2
	sub	w0, w0, w1, lsl 1
	ret
```

```asm
mystery5:
	add	x1, x1, x1, lsl 2
	add	x0, x1, x0, lsl 3
	ret
```

(`csneg Wd, Wn, Wm, cond` is "`Wd = cond ? Wn : -Wm`".)

Check: put your C in `work/mystery.c` and compile it with `gcc -O2 -S -o -`.
Your output should match, apart from register numbers.

## Exercise 27.3 [core]

For each C function, **predict** what `gcc -O2` will generate. Write your
prediction down (roughly: which instructions, any calls, any frame). Then
compile and compare.

```c
long mystery2(const char *s) {
    long n = 0;
    while (s[n] != 0)
        n++;
    return n;
}

int g(int);
int mystery3(int x) {
    return g(x / 3);
}
```

Which idioms from the lesson do you see? Was there anything you did not expect?

## Exercise 27.4 [core]

File: `ex4.s`. Write in C, then translate with the recipe:

```c
int digit_sum(unsigned n) {
    int s = 0;
    while (n != 0) {
        s += n % 10;
        n /= 10;
    }
    return s;
}
```

`digit_sum` is a leaf: it must have no frame and use only scratch registers.
Write a `main` that prints `digit_sum` of 0, 7, 12345 and 4294967295 (keep the
values in a `.word` table and loop over it). Expected output:

```
digit_sum(0) = 0
digit_sum(7) = 7
digit_sum(12345) = 15
digit_sum(4294967295) = 57
```

Then compare your `digit_sum` with `gcc -O2`. Does gcc use `udiv`?

## Exercise 27.5 [core]

File: `ex5.s`. Write `void reverse(int *a, long n)` that reverses an array in
place, and `void print_array(const int *a, long n)` that prints the elements
separated by spaces and ends the line, choosing the separator with a ternary:

```c
printf("%d%c", a[i], i == n - 1 ? '\n' : ' ');
```

Use `csel` for that ternary. In `reverse`, walk two pointers towards each
other, as an optimizing compiler would, instead of two indexes. Print, reverse
and print again an array of 1 to 7, then an array `{-5, 10}`. Expected output:

```
1 2 3 4 5 6 7
7 6 5 4 3 2 1
-5 10
10 -5
```

## Exercise 27.6 [core]

File: `ex6.s`.

```c
int is_prime(int k) {
    if (k < 2) return 0;
    for (int d = 2; d * d <= k; d++)
        if (k % d == 0) return 0;
    return 1;
}

int count_primes(int n) {          // primes p with 2 <= p < n
    int count = 0;
    for (int k = 2; k < n; k++)
        count += is_prime(k);
    return count;
}
```

Before writing any code, write the recipe's table for `count_primes` as a
comment: every variable, whether it is used after a call, and its register.
Draw the frame. Then translate. Use guard + bottom-tested loops. `main`
prints `count_primes(n)` for n = 10, 100, 1000, 10000. Expected output:

```
primes below 10: 4
primes below 100: 25
primes below 1000: 168
primes below 10000: 1229
```

## Exercise 27.7 [stretch]

File: `ex7.s`. Write `unsigned long udiv10(unsigned long x)` with **no
`udiv`**, the way the compiler does 64-bit division by 10. Find out how by
compiling

```c
unsigned long udiv10(unsigned long x) { return x / 10; }
```

with `gcc -O2 -S` and reading it. (You will see `umulh` from lesson 18.)
Then explain, in a comment, why the magic number works.

Your `main` must test it: compare `udiv10(x)` against `x / 10` done with
`udiv` for every `x` from 0 to 9,999,999, and for at least ten edge values
such as `0xffffffffffffffff`, `0x8000000000000000`, `0xffffffff` and
`0x100000000`. On any mismatch print `mismatch at X: got G, want W`. If there
are none, print `ok`. Expected output:

```
ok
```

and exit status 0.

## Exercise 27.8 [stretch]

Files: `ex8.s` and `ex8_main.c`. Benchmark your `count_primes` from 27.6.

- `ex8.s`: copy `is_prime` and `count_primes` from your `ex6.s`, renamed
  `is_prime_asm` and `count_primes_asm`, and without `main`.
- `ex8_main.c`: the C versions of both functions (call them `is_prime_c` and
  `count_primes_c`), and a `main` that times 10 calls of each with `n = 200000`
  using `clock()`, the way `examples/bench_main.c` does. Print the count and
  the time for each. Build with:

  ```console
  $ gcc -O2 -o ex8 ex8.s ex8_main.c
  ```

Expected output (your times will differ, the counts must not):

```
asm:     count = 17984   time = 0.054 s
C -O2:   count = 17984   time = 0.052 s
```

Then do this experiment: in `main`, pass the constant `200000` directly
instead of reading it from a `volatile int n`. Rebuild and run. What happens to
the C time, and why? Look at `main` with
`objdump -d --no-show-raw-insn --disassemble=main ex8` to confirm.

## Exercise 27.9 [stretch]

Compile `examples/triangles.c` (or any C file with a function that calls
another) with and without `-mbranch-protection=standard`:

```console
# gcc -O2 -S -o plain.s triangles.c
# gcc -O2 -S -mbranch-protection=standard -o hardened.s triangles.c
# diff plain.s hardened.s
```

1. Which functions got `paciasp`/`autiasp`, and which got only `bti c`? Why?
2. Build both and check with `objdump -d` how the new instructions are shown.
   Do both programs give the same output?
3. In the hardened version, what would happen if a buffer overflow changed the
   saved `x30` of a function before it returned?

