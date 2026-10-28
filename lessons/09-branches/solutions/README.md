# Lesson 09 answers

Programs: [ex3.s](ex3.s) to [ex9.s](ex9.s).

## 09.1

1. Z C (5 - 5 = 0; no borrow)
2. N (5 - 6 = -1; it borrowed, so C = 0)
3. C (6 - 5 = 1; no borrow)
4. N (0 - 1 = -1; borrowed)
5. C (-1 + 2 = 1; unsigned, 0xffff...ffff + 2 carries out)
6. N V (the largest long + 1 becomes the most negative long: signed overflow)
7. **Unchanged**: `add` does not set flags. Whatever they were before stays.

## 09.2

1. `b.ne`
2. `b.lt`
3. `b.lo`
4. `b.hs` (pointers are unsigned addresses)
5. `b.gt`, after `cmp w1, w2`: the conditions are the same; the compare must
   use `w` registers so bit 31 is treated as the sign bit.

`cbz x1, L`.

## 09.7

`b.le` is a **signed** condition. As a signed number, `0x8000000000000000` is
the most negative `long`, which is less than 100, so the branch skips the
block. `size` is unsigned: use `b.ls`.
