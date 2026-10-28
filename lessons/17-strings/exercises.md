# Lesson 17 exercises

Work in `lessons/17-strings/work/` inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Each program has a `main` that tests your function on a few strings and prints
the results with `printf` (lesson 16). Where libc has the same function,
print both results side by side. Try each exercise before looking at the
answers: programs are in [solutions/](solutions/), written answers in
[solutions/README.md](solutions/README.md).

## Exercise 17.1 [warm-up]

Without running anything:

1. How many bytes does `.asciz "Hi!\n"` occupy? What are they, in hex?
2. What does `strlen` return for `""`, `"a"`, and `"a\0b"`?
3. `strcmp("abc", "abd")` returns a negative number. Why negative, and which
   byte comparison decides it?
4. `strcmp("ab", "abc")`: which bytes are compared last, and what is the sign of
   the result?
5. What is `'a' ^ 0x20`? What is `'A' | 0x20`? Why does flipping bit 5 change
   case?
6. Why does `my_itoa` write the digits from the **end** of the buffer?

## Exercise 17.2 [warm-up]

Write `ex2.s` with `long count_char(const char *s, int c)` that counts how
many times `c` appears in `s`. Test it on `"mississippi"` with `'s'`, `'i'`,
`'p'`, and `'z'`.

Check:

```
's' appears 4 times in mississippi
'i' appears 4 times in mississippi
'p' appears 2 times in mississippi
'z' appears 0 times in mississippi
```

## Exercise 17.3 [core]

Write `ex3.s` with `my_strrchr(s, c)`: a pointer to the **last** `c` in `s`,
or `NULL`. Compare with libc's `strrchr` on `"/usr/local/bin"` with `'/'`,
`"notes.tar.gz"` with `'.'`, and a third string with a character it does not contain. Print the rest of the
string from the returned pointer, or `(none)`.

Check:

```
mine: /bin  libc: /bin
mine: .gz  libc: .gz
mine: (none)  libc: (none)
```

## Exercise 17.4 [core]

Write `ex4.s` with `int is_palindrome(const char *s)` using two pointers, one
from each end. Test `"racecar"`, `"abba"`, `"abca"`, `"a"`, and `""`.

Check: `1 1 0 1 1`, each as `"racecar": 1` and so on. Make sure `""` does not
read before the start of the string.

## Exercise 17.5 [core]

Write `ex5.s` with `long word_count(const char *s)`, where a word is a run of
non-space characters. Test `"  hello   world  "`, `"one"`, `""`, `"a b c d"`.

Check: `2`, `1`, `0`, `4`.

## Exercise 17.6 [core]

Write `ex6.s` with `void capitalize(char *s)` that, **in place**, makes the
first letter of every word uppercase and every other letter lowercase. The
strings must be in `.data`, not `.rodata`: why?

Check: `"hello big wORLD"` becomes `Hello Big World`;
`"assembly IS fun, really"` becomes `Assembly Is Fun, Really`.

## Exercise 17.7 [core]

Using `my_itoa` from `examples/itoa.s`, write `ex7.s` that prints 2026 in
bases 2, 8, 10, 16, and 36, and for 8, 10, and 16 also with `printf`'s `%o`,
`%d`, `%x` for comparison.

Check:

```
base 2: 11111101010
base 8: 3752 (printf: 3752)
base 10: 2026 (printf: 2026)
base 16: 7ea (printf: 7ea)
base 36: 1ka
```

## Exercise 17.8 [stretch]

`examples/atoi.s`'s `parse_long` silently wraps around on numbers that do not
fit in a `long`. Write `ex8.s` with a version that rejects them. Collect the
digits as an unsigned magnitude and, before each `n = n * 10 + d`, check that
the result will not pass the limit: 9223372036854775807 for positive numbers,
9223372036854775808 for negative ones.

Check:

```
"9223372036854775807": 9223372036854775807
"9223372036854775808": invalid
"-9223372036854775808": -9223372036854775808
"-9223372036854775809": invalid
"99999999999999999999": invalid
"-17": -17
"12a": invalid
```

## Exercise 17.9 [stretch]

Write `ex9.s` with `my_strstr(hay, needle)`: a pointer to the first place
`needle` occurs in `hay`, or `NULL`. An empty needle matches at the start.
Compare with libc's `strstr` on `"a needle in a haystack"` with `"needle"`,
`"hay"`, `""`, `"pin"`, and `"stacks"`.

Check: `needle in a haystack`, `haystack`, `a needle in a haystack`, `(none)`,
`(none)`, the same from both versions.
