# Lesson 19 answers

Programs: [ex3.s](linux/solutions/ex3.s) to [ex7.s](linux/solutions/ex7.s), with drivers `ex5_main.c` and
`ex6_main.c`.

## 19.1

| Struct | Offsets | Size |
|--------|---------|------|
| `a` | `c` 0, `l` 8 | 16 |
| `b` | `i` 0, `s` 4, `c` 6 | 8 |
| `c` | `c1` 0, `s` 2, `c2` 4, `i` 8 | 12 |
| `d` | `name` 0, `id` 16 | 24 |
| `e` | `inner` 0 (8 bytes, aligned 4), `flag` 8 | 12 |

## 19.2

- `struct c { int i; short s; char c1; char c2; }`: 8 bytes.
- `struct d { long id; char name[10]; }`: 18 bytes rounded up to 24 for an
  8-byte alignment, so no smaller. Reordering cannot help when the padding is
  at the end; only a smaller member or a shorter array would.

## 19.5

16 bytes: the result comes back in `x0` (min) and `x1` (max).

## 19.6

24 bytes, more than 16. The caller makes copies of `a` and `b` and passes
`x0` = `&copy_of_a`, `x1` = `&copy_of_b`, and `x8` = the address where the
result must be written.

## 19.7

`tag` at 0 (4 bytes), 4 bytes of padding, the union at 8 (aligned to 8 for
`long` and pointers), size 16.
