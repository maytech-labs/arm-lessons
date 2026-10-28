# Lesson 24 (macOS): Function pointers

Do [the main lesson](../../lessons/24-function-pointers/) first. Function
pointers work exactly the same on macOS: `adr`, `blr`, `br`, jump tables,
`qsort` and `bsearch` comparators, dispatch tables and vtables are identical
instructions. This page covers only what differs, then walks through each macOS
example.

```console
$ cd apple-silicon/24-function-pointers/examples
$ make
```

## What is different

### Names

C-visible names get a leading underscore: `_main`, `_printf`, `_puts`,
`_qsort`, `_bsearch`, `_strcmp`. Functions that only your file knows about
(`cmp_int`, `for_each`, `calc_case2`) are just labels, so they need no
underscore: you pass their address, never their name, to C.

### Addresses

Same as every macOS lesson: `adrp x0, sym@PAGE` / `add x0, x0, sym@PAGEOFF`.
For a function in the same file, `adr x2, show` works unchanged.

A library function's address comes from the GOT, with Apple's spelling:

| | Linux | macOS |
|-|-------|-------|
| GOT page | `adrp x19, :got:puts` | `adrp x19, _puts@GOTPAGE` |
| GOT slot | `ldr x19, [x19, :got_lo12:puts]` | `ldr x19, [x19, _puts@GOTPAGEOFF]` |

### Variadic arguments to `printf`

This is the one change you will make in nearly every function. On macOS every
argument after `printf`'s format string goes on the stack, in 8-byte slots,
starting at `[sp]` (lesson 16). The examples use one pattern throughout:
build the frame as usual, then reserve a 16-aligned area below it for the
variadic slots, and release it before the epilogue:

```asm
show:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16                 // room for printf's variadic argument
    str x0, [sp]                    // printf("[%d]", x): x goes on the stack
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    bl   _printf
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
```

Two `int`s go in two 8-byte slots: `stp x19, x0, [sp]`. Do not write
`stp w19, w0, [sp]`: that packs them into 4-byte slots, and `printf` reads the
second one from the wrong place.

Only `printf` is variadic here. `qsort`, `bsearch`, `strcmp`, `puts`, and *your
comparator* take ordinary arguments in `x0`-`x7` on both platforms.

### Sections

Strings go in `.section __TEXT,__cstring`; read-only numbers (the arrays in
`callback.s`, `map_filter.s`, `ex5.s`, the bytecode in `ex8.s`) in
`.section __TEXT,__const`. Arrays that `qsort` rearranges go in `.data`.

### Tables of addresses

Tables of `.quad` addresses (dispatch tables, vtables, arrays of string
pointers) must be writable for the loader to patch, exactly as on Linux. The
difference is how a mistake shows up. On Linux a `.quad` table in `.rodata`
links and silently marks the program `TEXTREL`. On macOS the link fails:

```console
$ make dispatch_table
Illegal text-relocations:
  text-relocation in 'ops' (...) to 'add_ints'
ld: Found illegal text-relocations
```

The examples use `.data`. macOS also has `.section __DATA,__const`, a section
the loader patches and then makes read-only; it works too and is what `clang`
uses for a `const` array of function pointers.

Offset tables (`.word case - table`) in `__TEXT,__text` need no relocation and
work unchanged.

### `x16` and `x17`

As on Linux, the linker's call stubs may overwrite `x16`/`x17`, so do not keep a
function pointer there. And never `x18`.

## The examples

### `fnptr_basics.s`

`adr x19, add_ints` then `blr x19`, then the same through `adrp`/`add` with
`@PAGE`/`@PAGEOFF`, then `_puts` through the GOT. All three `printf` calls put
their one argument at `[sp]`, inside a 16-byte area reserved after saving `x19`.
The address printed looks like `0x104668410`: macOS loads programs above 4 GiB,
at a different place each run.

```console
$ ./fnptr_basics
add_ints lives at 0x104668410
op(7, 2) = 9
op(7, 2) = 5
hello from puts, called through a pointer
```

### `callback.s`

`for_each` is unchanged: it never calls `printf` itself, only `blr x21`. The two
callbacks, `show` and `show_square`, each reserve 16 bytes and store their
number at `[sp]` (see the snippet above).

```console
$ ./callback
[3][1][4][1][5]
[9][1][16][1][25]
```

### `qsort_ints.s`

`cmp_int` and the `_qsort` call are identical to Linux. Two places change:

- `print_ints` loads `a[i]` into `w9` and stores it at `[sp]` instead of putting it
  in `w1`.
- `find` stores `key` at `[sp, #16]` *before* reserving the variadic area, so
  after `sub sp, sp, #16` the key is no longer at `sp + 16`. It uses
  `add x0, x29, #16` instead: `x29` still points at the frame, so offsets from
  it do not move when `sp` does. The found value and its index go out with
  `stp x9, x10, [sp]`.

```console
$ ./qsort_ints
before: 42 -7 19 0 88 3 -20 19
after:  -20 -7 0 3 19 19 42 88
found 88 at index 7
5 is not in the array
```

### `map_filter.s`

`map`, `filter`, `is_odd` and `square` are unchanged. Only `print_ints` differs,
as in `qsort_ints.s`. `nums` is in `__TEXT,__const`, `out` in `.bss`.

```console
$ ./map_filter
start:   1 2 3 4 5 6 7 8 9 10
odd:     1 3 5 7 9
squared: 1 9 25 49 81
```

### `jump_table.s`

`calc` and `calc_table` are byte-for-byte the same instructions. `main` reserves
16 bytes and passes `op` and the result with `stp x19, x0, [sp]`.

```console
$ ./jump_table
calc(-1, 12, 4) = -1
calc(0, 12, 4) = 16
calc(1, 12, 4) = 8
calc(2, 12, 4) = 48
calc(3, 12, 4) = 3
calc(4, 12, 4) = -1
```

`objdump -d jump_table` shows the same layout as on Linux: the four cases before
the table, offsets -40, -32, -24, -16.

### `dispatch_table.s`

`ops` and `names` are `.quad` tables in `.data`. The call is `ldr x9, [x20, x19,
lsl #3]` / `blr x9`, as on Linux; the name and result go to `printf` with
`stp x9, x0, [sp]`.

```console
$ ./dispatch_table
add(9, 4) = 13
sub(9, 4) = 5
mul(9, 4) = 36
max(9, 4) = 9
```

### `vtable.s`

Same structs, same `.equ` offsets, same two loads and `blr`. `printf` has four
variadic arguments here, so `main` reserves 32 bytes: name and `w` at `[sp]` and
`[sp, #8]`, `h` at `[sp, #16]`, the area at `[sp, #24]`.

```console
$ ./vtable
rectangle 6x4: area 24
triangle 6x4: area 12
square 5x5: area 25
```

## Exercises

Do the exercises in the main lesson's
[exercises.md](../../lessons/24-function-pointers/exercises.md) as macOS
programs. macOS versions of every programming solution are in
[solutions/](solutions/); the written answers are in the main lesson's
[solutions/README.md](../../lessons/24-function-pointers/solutions/README.md).
Things to watch for:

- 24.2, 24.3, 24.5, 24.6: every `printf` argument goes on the stack.
- 24.4: `cmp_str` calls `_strcmp`, which is not variadic; nothing changes.
- 24.7: `dispatch` stores `word` at `[sp]` once and both of its `printf` calls
  reuse that slot, since nothing else writes there.
- 24.8: the bytecode lives in `__TEXT,__const`; `PRINT` stores the popped value at
  `[sp]`.
