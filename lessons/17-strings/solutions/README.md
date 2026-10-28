# Lesson 17 answers

Programs: [ex2.s](ex2.s) to [ex9.s](ex9.s).

## 17.1

1. Five bytes: `48 69 21 0a 00`.
2. 0, 1, and 1: `strlen` stops at the first zero byte, so the `b` is never seen.
3. The first two bytes are equal; at index 2, `'c'` (0x63) is less than `'d'`
   (0x64), so the result is negative (`strcmp` returns the difference of the
   first bytes that differ, or at least its sign).
4. Index 2: the terminator 0 of `"ab"` against `'c'`. 0 < 0x63, so negative:
   a prefix sorts before the longer string.
5. `'a' ^ 0x20` = `'A'`; `'A' | 0x20` = `'a'`. Uppercase letters are
   0x41-0x5a and lowercase 0x61-0x7a: the same letters 32 (0x20, bit 5) apart.
6. Division produces the digits last-first (`n % 10` is the *last* digit).
   Writing from the end backwards leaves them in the right order without a
   reversing pass.

## 17.6

String literals in `.rodata` are read-only: storing into them crashes with
`Segmentation fault`. In C, modifying a string literal is undefined behaviour
for the same reason; `char s[] = "..."` (an array, in `.data` or on the stack)
is modifiable, `char *s = "..."` is not.
