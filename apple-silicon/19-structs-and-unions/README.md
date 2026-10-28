# Lesson 19 on macOS: Structs and unions

Read [the main lesson](../../lessons/19-structs-and-unions/README.md) first.
Struct layout, padding, alignment, unions, bit-field allocation, and the
by-value rules (≤ 16 bytes in registers, larger by hidden pointer, big returns
through `x8`) are **identical** on your Mac. `offsets.c` prints the same
numbers:

```console
$ cd apple-silicon/19-structs-and-unions/examples && make
$ ./offsets
struct point: size 16, x at 0, y at 8
struct padded: size 12, c at 0, i at 4, d at 8
struct packed: size 8, i at 0, c at 4, d at 5
struct student: size 24, name at 0, age at 16, score at 20
$ ./byvalue
swap_pair({1, 2}) = {2, 1}
sum_triple({10, 20, 30}) = 60
make_triple(7, 8, 9) = {7, 8, 9}
```

The examples differ only in the lesson 16 rules: `_main`, `_printf`,
`@PAGE`/`@PAGEOFF`, variadic arguments on the stack, and **an underscore on
every function the C files call**: `_swap_pair`, `_sum_triple`,
`_make_triple`, `_get_mode`, `_set_mode`. The C code still says `swap_pair`;
the compiler adds the underscore.

## Small differences

- **`long double`** is 16 bytes on Linux AArch64 but 8 bytes (just a `double`)
  on macOS. A struct containing one has a different layout on the two systems.
- **Stack-passed struct arguments.** Beyond the eighth argument, Linux puts
  each argument in 8-byte slots; Apple packs them by their natural alignment.
  A small struct passed on the stack may therefore sit at a different offset.
  This only matters for functions with many arguments.

## Tables of addresses

`solutions/ex7.s` stores the address of a string in a struct
(`.quad hello`). On macOS, data containing absolute addresses must be in a
`__DATA` section (`.data`), never in `__TEXT` (`.section __TEXT,__const`):
the linker refuses with `illegal text-relocation`. The values array is in
`.data`, so it works on both systems.

## Exercises

Do the [main lesson's exercises](../../lessons/19-structs-and-unions/exercises.md)
as macOS programs. The answers are the same. macOS solutions are in
[solutions/](solutions/).
