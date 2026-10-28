# Lesson 19: Structs and unions

## Goals

After this lesson you can:

- Work out the layout of any C struct: member offsets, padding, size,
  alignment.
- Name offsets with `.equ` and access members with `[base, #OFFSET]`.
- Walk an array of structs and use pointers to structs (`p->field`).
- Pass and return structs by value, following AAPCS64's size rules.
- Use unions, and see that type punning is just reading the same bytes with a
  different load.
- Read and write C bit fields with `ubfx` and `bfi`.

## Before you start

You need lesson 12 (arrays, scaled addressing), 16 (calling C and being called
from C), and 18 (type sizes, loads). Some examples are a C file plus an
assembly file; their Makefiles have explicit rules, as in lesson 16.

```console
# cd lessons/19-structs-and-unions/linux/examples && make
```

## A struct is memory with named offsets

```c
struct point { long x, y; };
```

In memory, a `struct point` is 16 bytes: `x` at offset 0, `y` at offset 8.
That is all a struct is. There are no struct instructions; you access a member
by adding its offset to the struct's address. Give the offsets names with
`.equ`, like C's `offsetof`:

```asm
    .equ POINT_X, 0             // offsetof(struct point, x)
    .equ POINT_Y, 8             // offsetof(struct point, y)
    .equ POINT_SIZE, 16         // sizeof(struct point)
```

`examples/point.s`:

```asm
    adrp x9, p
    add x9, x9, :lo12:p         // q = &p
    ldr x10, [x9, #POINT_X]     // q->x
    add x10, x10, #10
    str x10, [x9, #POINT_X]     // q->x += 10

    ldp x1, x2, [x9]            // x and y are neighbours: one ldp loads both
```

`q->x` is `[x9, #POINT_X]`. And `p.x`, for a struct you know the address of,
is exactly the same thing. The `->` versus `.` distinction in C is about
whether you have a pointer or the struct itself; in assembly you always have
an address.

## Layout rules: alignment and padding

The compiler places members in the order written, but each member must start
at an offset that is a multiple of its own **alignment** (for basic types:
its size). Gaps are filled with unused **padding** bytes. Then the whole
struct's size is rounded up to a multiple of its largest member's alignment, so
that in an array every element is aligned too.

```c
struct padded { char c; int i; char d; };
```

```
offset:  0   1   2   3   4   5   6   7   8   9  10  11
         c   .   .   .   i   i   i   i   d   .   .   .
             padding     (int: offset 4)     padding to 12
```

- `c` at 0.
- `i` needs a multiple of 4: offsets 1-3 are padding, `i` at 4.
- `d` at 8.
- Largest alignment is 4, so the size rounds up from 9 to 12.

Reorder the members and the padding mostly disappears:

```c
struct packed { int i; char c; char d; };      // i at 0, c at 4, d at 5, size 8
```

**Rule of thumb:** order members from largest to smallest.

`examples/offsets.c` is a C program that prints what the compiler decided.
Run it whenever you compute a layout by hand:

```console
# ./offsets
struct point: size 16, x at 0, y at 8
struct padded: size 12, c at 0, i at 4, d at 8
struct packed: size 8, i at 0, c at 4, d at 5
struct student: size 24, name at 0, age at 16, score at 20
```

An array inside a struct (`char name[16]`) is laid out inline, element by
element, and aligned like its element type. A struct inside a struct is laid
out inline too, aligned like its most aligned member.

When you define a struct in `.data`, align it with `.p2align` to its
alignment (`.p2align 3` for 8).

## Arrays of structs

An array of structs is an array whose element size is `sizeof(struct)`.
`examples/students.s` uses

```c
struct student { char name[16]; int age; int score; };   // 24 bytes
```

The address of `class[i]` is `class + i * 24`. 24 is not a power of two, so
the scaled addressing mode cannot do it; use `madd`:

```asm
    mov x12, #STUDENT_SIZE
loop:
    ...
    madd x13, x11, x12, x9      // &class[i] = class + i * sizeof(struct student)
    ldr w14, [x13, #STUDENT_SCORE]
    ldr w15, [x10, #STUDENT_SCORE]
    cmp w14, w15
    csel x10, x13, x10, gt      // if (class[i].score > best->score) best = &class[i]
```

Keeping a **pointer** to the best element, not a copy of it, is the natural
way: one register instead of 24 bytes.

`best->name` is an array member, so its "value" in C is its address:

```asm
    add x1, x10, #STUDENT_NAME  // best->name: the address of the array member
```

```console
# ./students
best: Grace, age 85, score 97
```

To walk an array of structs with a pointer, add the struct size each time:
`add x9, x9, #STUDENT_SIZE` is `p++`.

## Passing and returning structs by value

C can pass whole structs to functions and return them. AAPCS64 decides how by
the struct's size:

| Size | Passed as an argument | Returned |
|------|-----------------------|----------|
| ≤ 8 bytes | in one register | in `x0` |
| 9-16 bytes | in two registers (`x0`:`x1`, or the next free pair) | in `x0`:`x1` |
| > 16 bytes | the **caller** makes a copy and passes a **pointer** to it | the **caller** passes the address for the result in **`x8`** |

(Structs of only `float`s or only `double`s, up to four of them, use the
floating-point registers instead. That is lesson 23.)

`examples/byvalue.s` has one function of each kind, called from
`byvalue_main.c`:

```asm
// struct pair swap_pair(struct pair p): p.a in x0, p.b in x1
swap_pair:
    mov x9, x0
    mov x0, x1                  // result.a = p.b
    mov x1, x9                  // result.b = p.a
    ret

// long sum_triple(struct triple t): too big for registers, so x0 = &copy
sum_triple:
    ldp x9, x10, [x0]           // t.a, t.b
    ldr x11, [x0, #16]          // t.c
    ...

// struct triple make_triple(long a, long b, long c): x8 = where to write it
make_triple:
    stp x0, x1, [x8]            // result->a, result->b
    str x2, [x8, #16]           // result->c
    ret
```

```console
# ./byvalue
swap_pair({1, 2}) = {2, 1}
sum_triple({10, 20, 30}) = 60
make_triple(7, 8, 9) = {7, 8, 9}
```

This is why `x8` appeared in lesson 15's table as the "indirect result"
register. A function returning a big struct is really a function that takes a
hidden pointer argument and writes through it.

Passing big structs by value costs a copy every call; that is why C programmers
usually pass `const struct x *` instead.

## Unions: one place, several types

```c
union word { unsigned int u; unsigned short h[2]; unsigned char b[4]; };
```

Every member of a union starts at **offset 0**. The union is as big as its
largest member. Writing one member and reading another (**type punning**) just
reads the same bytes with a different load. `examples/union.s`:

```asm
    str w10, [x9]               // w.u = 0x11223344

    ldr w1, [x9]                // w.u        (every member starts at offset 0)
    ldrh w2, [x9]               // w.h[0]
    ldrh w3, [x9, #2]           // w.h[1]
    ldrb w4, [x9]               // w.b[0]
    ...
```

```console
# ./union
11223344: halves 3344 1122, bytes 44 33 22 11
```

Little-endian again: `b[0]` is the lowest byte.

A union is usually paired with a **tag** that says which member is valid, in a
struct (exercise 19.7). That pattern is how interpreters represent "a value of
any type".

## Bit fields

```c
struct perms {
    unsigned read  : 1;         // bit 0
    unsigned write : 1;         // bit 1
    unsigned mode  : 4;         // bits 2-5
};
```

The members share one `unsigned` (4 bytes). GCC and Clang on ARM64 allocate
fields from bit 0 upwards. Reading a field is lesson 08's `ubfx`; writing one
is a read-modify-write with `bfi`, so the other fields are kept.
`examples/bitfields.s`:

```asm
get_mode:
    ldr w9, [x0]
    ubfx w0, w9, #2, #4         // bits 2-5
    ret

set_mode:
    ldr w9, [x0]                // read the whole unit...
    bfi w9, w1, #2, #4          // ...replace bits 2-5 with the low 4 bits of mode...
    str w9, [x0]                // ...and write it back: the other fields are kept
    ret
```

```console
# ./bitfields
read 1, write 0, mode 5 (raw 0x15)
after set_mode(9): read 1, write 0, mode 9 (raw 0x25)
```

`0x15` is `01 0101`: `mode` = `0101` = 5 in bits 2-5, `write` = 0, `read` = 1.

The exact bit order of bit fields is up to the ABI, so for data you exchange
with other programs or hardware, use explicit masks and shifts instead.

## C to assembly

| C | Assembly |
|---|----------|
| `struct s { ... };` | `.equ S_FIELD, offset` for each member, `.equ S_SIZE, size` |
| `p->field` (8 bytes) | `ldr x0, [xp, #S_FIELD]` |
| `p->field = v` (4 bytes) | `str w0, [xp, #S_FIELD]` |
| `&p->field` | `add x0, xp, #S_FIELD` |
| `a[i].field` | `madd xt, xi, xsize, xa` then `[xt, #S_FIELD]` |
| `p++` (`struct s *p`) | `add xp, xp, #S_SIZE` |
| `struct pair f(struct pair)` (≤ 16 bytes) | in `x0`:`x1`, out `x0`:`x1` |
| `f(struct big b)` | `x0` = pointer to the caller's copy |
| `struct big f(void)` | caller passes the result address in `x8` |
| `u.member` (union) | every member at offset 0 |
| `x = p->bits` (bit field) | `ldr` + `ubfx` |
| `p->bits = v` | `ldr` + `bfi` + `str` |

## Common mistakes

- **Forgetting padding.** Adding member sizes gives the wrong offsets and the
  wrong struct size. Use the rules, then check with a C program.
- **Wrong element size for arrays of structs.** `lsl #3` for a 24-byte struct
  is wrong; use `madd` with the real size.
- **Loading a member with the wrong width.** An `int` member needs `ldr w`, not
  `ldr x`, or you read the next member's bytes too.
- **Missing `.p2align`** before struct data: members can end up misaligned.
- **Treating a big struct argument as being in registers.** Over 16 bytes, it
  is a pointer in `x0` (and so on).
- **Ignoring `x8`** when writing a function that returns a big struct.
- **Writing a bit field with `str` of only the new value.** It wipes the other
  fields in the unit. Read, `bfi`, write.

## Recap

- A struct is a block of memory; members are at fixed offsets.
- Each member is aligned to its own alignment; the struct's size is rounded to
  its largest alignment. Order members large to small to reduce padding.
- Name offsets with `.equ`; access with `[base, #OFFSET]`.
- Arrays of structs: element `i` is at `base + i * size` (`madd`).
- Structs ≤ 16 bytes go in registers; larger ones by hidden pointer, and big
  returns go through `x8`.
- Union members all start at offset 0.
- Bit fields are `ubfx` to read and `ldr`/`bfi`/`str` to write.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](apple-silicon/README.md)
next.
