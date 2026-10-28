# Lesson 24 solutions

Programs: `ex2.s` to `ex8.s` in this directory. Build them all with `make`.

## Exercise 24.1

1. `blr` sets `x30` to the address of the next instruction: `0x1004`. `br` does
   not touch `x30`, so it keeps whatever it held before.
2. `x2` is a caller-saved argument register. The first call to `fn` (which calls
   `printf`) is allowed to overwrite it, so the second `blr x2` would jump to
   garbage. `x21` is callee-saved: every function that uses it restores it.
3. Entry 3 is `-16`, so the target is `0x2040 - 16 = 0x2030`.
4. `-1` is less than `4` as a signed number, so `b.ge` does not branch. The code
   then loads `table[-1]` (`uxtw` turns `-1` into `0xffffffff`, so it actually
   reads about 16 GiB past the table) and jumps to whatever it finds: a crash at
   best. `b.hs` treats `-1` as `0xffffffff`, which is >= 4, and goes to default.
5. For example `a = 2000000000`, `b = -2000000000`: `a - b` should be
   4000000000 (positive) but wraps to -294967296 (negative). Or `a = INT_MIN`,
   `b = 1`: the result wraps to `INT_MAX`, positive, though `a < b`.
6. `ops` holds absolute addresses (`.quad add_ints`). The program is loaded at a
   random address, so the loader must write the real addresses into the table at
   startup, which needs a writable section. `calc_table` holds differences
   between two labels in the same section, which are fixed when the file is
   assembled and never need patching, so read-only `.text` is fine.

## Exercise 24.3

`bsearch` must use the *same* ordering the array was sorted with. With
ascending `cmp_int` it would look at the middle, see that 7 is "less", and go
left, where the larger numbers are.

## Exercise 24.4

The comparator gets `&words[i]` and `&words[j]`, so it does one `ldr` on each to
get the `char *`, then calls `strcmp`. Because it calls a function, it needs a
frame to save `x30`. `words` must be in `.data`: it is an array of addresses
(needs relocation) and `qsort` rearranges it.

## Exercise 24.8

Try `.quad 9` before `OP_HALT` in `program`: the bounds check (`cmp x9, #NOPS` /
`b.hs run_bad`) catches it, prints `bad opcode 9`, and `run` returns 1, which
`main` returns as the exit status.
