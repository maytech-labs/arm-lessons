# Lesson 08 exercises

Work in `lessons/08-bitwise/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Try each exercise before looking at the answers: programs are in
[linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

## Exercise 08.1 [warm-up]

Work these out by hand, in 8-bit binary (treat the values as `unsigned char`).
Then check two of them in the debugger.

1. `0b1100_1010 & 0b0110_0110`
2. `0b1100_1010 | 0b0110_0110`
3. `0b1100_1010 ^ 0b0110_0110`
4. `0b1100_1010 & ~0b0110_0110`
5. `0b1100_1010 << 2` (keep 8 bits)
6. `0b1100_1010 >> 3` (logical)
7. `0b1100_1010 >> 3` (arithmetic, treating it as a signed 8-bit value)
8. `x ^ x`, for any `x`

## Exercise 08.2 [warm-up]

Write the single instruction for each, with `x0` as the variable:

1. set bit 12
2. clear bit 4
3. toggle bits 0 and 1 together
4. keep only the low byte
5. `x0 = x1 * 17` (no `mul`)
6. `x0 = x0 / 8` for an `unsigned long`
7. `x0 = x0 / 8` for a `long` that is never negative. What changes if it can be
   negative?

## Exercise 08.3 [core]

Write `ex3.s`: start with 178, set bit 0, clear bit 7, then toggle bit 4. Exit
with the result.

Check: exit status `35`.

## Exercise 08.4 [core]

Write `ex4.s` that computes `x * 9` and `x * 15` for `x = 13` using only
shifts, `add`, and `sub` (no `mul`). Exit with `x * 15`.

Check: exit status `195`; `x * 9` (117) visible in the debugger.

## Exercise 08.5 [core]

FAT file systems store a date in 16 bits: bits 15-9 are the year minus 1980,
bits 8-5 the month, bits 4-0 the day. Write `ex5.s` that unpacks the date
`0x5d5b` into day, month, and year with `ubfx`, and exits with the month.

Check: exit status `10`; the debugger shows day 27 and year 2026.

## Exercise 08.6 [core]

Write `ex6.s` that rounds 37 **up** to the next multiple of 16 with one `add`
and one `and`. Why does the trick only work for powers of two?

Check: exit status `48`. Try 32 (stays 32) and 33 (becomes 48).

## Exercise 08.7 [core]

Write `ex7.s` that reverses the byte order of the 32-bit value `0x11223344`
using one instruction on `w` registers, and exits with the result.

Check: exit status `17` (`0x11`); the debugger shows `0x44332211`.

## Exercise 08.8 [stretch]

For `x = 88`, compute in `ex8.s`:

1. `x & -x` (what does it give, and why?)
2. the number of trailing zero bits of `x`, with `rbit` and `clz`

Exit with the trailing-zero count.

Check: exit status `3`; `x & -x` is 8.

## Exercise 08.9 [stretch]

Write `ex9.s` that computes the absolute value of -42 **without any branch**.
Hint: `m = x >> 63` (arithmetic) is all ones for a negative `x` and all zeros
otherwise. What are `x ^ m` and `(x ^ m) - m` in each case?

Check: exit status `42`. Also try `x = 42`.

## Exercise 08.10 [stretch]

The reverse of 08.5: write `ex10.s` that packs day 27, month 10, year 2026
into the 16-bit FAT date format with `bfi`.

Check: exit status `91` (`0x5b`); the debugger shows `0x5d5b`.
