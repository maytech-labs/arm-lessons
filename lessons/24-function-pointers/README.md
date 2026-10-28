# Lesson 24: Function pointers

## Goals

After this lesson you can:

- Explain why a function's name is just an address, and load that address with
  `adr` or `adrp` + `add`.
- Call a function through a register with `blr`, and say how `blr` differs from
  `bl` and `br`.
- Write a function that takes a callback, and keep that callback safe across calls.
- Sort and search any array with the C library's `qsort` and `bsearch`, using a
  comparator you wrote in assembly.
- Write your own generic `map` and `filter`.
- Turn a C `switch` into a jump table, with a bounds check.
- Build dispatch tables: arrays of function pointers, and structs whose fields are
  function pointers (the idea behind C++ virtual functions).

## Before you start

You need:

- [Lesson 14](../14-functions/) and [lesson 15](../15-calling-convention/): `bl`,
  `ret`, `x30`, and which registers survive a call. This lesson leans hard on
  "`x19`-`x28` survive, `x0`-`x17` do not".
- [Lesson 16](../16-calling-c/): calling `printf` and `puts`.
- [Lesson 19](../19-structs-and-unions/): struct offsets with `.equ`.
- [Lesson 20](../20-symbols-and-sections/): `.data`, `.rodata`, `.text`.

All the programs in this lesson use integers only. Build and run them in the
container:

```console
$ ./scripts/linux-shell.sh
# cd lessons/24-function-pointers/examples
# make
```

## A function is an address

Every label in your program is an address. You have used labels on data
(`adrp x0, msg`) and labels on code (`bl print_ints`). There is nothing special
about the second kind: `add_ints` is the address of the first instruction of
`add_ints`. That means you can put it in a register, store it in memory, pass it
to another function, and later jump to it. That is all a function pointer is.

In C:

```c
int add_ints(int a, int b) { return a + b; }
int sub_ints(int a, int b) { return a - b; }

int (*op)(int, int);    // op is a pointer to "a function taking two ints, returning int"
op = add_ints;          // no parentheses: we take the function, we do not call it
op(7, 2);               // call whatever op points at: 9
op = sub_ints;
op(7, 2);               // same line of code, different function: 5
```

The declaration `int (*op)(int, int)` is the ugliest syntax in C. Read it from
the name outwards: `op` is a pointer (`*op`) to a function taking `(int, int)`
that returns `int`. In assembly there is no type at all: `op` is just a 64-bit
register holding an address.

Two new things in assembly:

| Instruction | Meaning |
|-------------|---------|
| `adr x19, add_ints` | `x19` = address of `add_ints` (target within +/-1 MiB, so same file) |
| `blr x19` | call the address in `x19`: like `bl`, sets `x30` to the return address |

`adr` you met in the cheat sheet; it is the one-instruction version of
`adrp` + `add`, and works when the target is close (within a megabyte), which is
always true for a function in the same `.s` file. `adrp` + `add :lo12:` works too,
for any distance.

Here is the program. Read [examples/fnptr_basics.s](examples/fnptr_basics.s):

```asm
    adr  x19, add_ints              // x19 = op
    mov  w0, #7
    mov  w1, #2
    blr  x19                        // call the address in x19; x30 = return address
```

The arguments go in `w0` and `w1` exactly as for `bl`. The called function has no
idea it was called through a pointer; it runs, puts its answer in `w0`, and `ret`
jumps back through `x30`.

Before you run it, predict: what are the second and third lines of output?

```console
# make fnptr_basics
# ./fnptr_basics
add_ints lives at 0xaaaad5c10794
op(7, 2) = 9
op(7, 2) = 5
hello from puts, called through a pointer
```

The first line prints the function's address with `%p`. Run it twice: the number
changes, because Linux loads the program at a random address each time (address
space layout randomisation). `adr` is PC-relative, so it always gives the right
answer wherever the program landed.

### A pointer to a library function

The last part of the program calls `puts` through a pointer. `puts` lives in
libc, a separate file loaded at its own random address, so you cannot `adr` it.
Instead the program asks the *GOT* (global offset table), a table of addresses
the loader fills in at startup:

```asm
    adrp x19, :got:puts             // page of the GOT slot holding &puts
    ldr  x19, [x19, :got_lo12:puts] // x19 = &puts
    blr  x19
```

Compare with loading an address of your own data: `ldr` instead of `add`,
because the GOT slot *contains* the address; it is not the address. You will see
`:got:` again in lesson 25 for `stdout`. For now, remember: your own functions
use `adr`; a library function's address comes from the GOT.

## `bl`, `blr`, `br`

You now have three ways to transfer control to code:

| Instruction | Target | Sets `x30`? | Use it for |
|-------------|--------|-------------|------------|
| `bl label` | fixed label | yes | ordinary calls |
| `blr xN` | address in `xN` | yes | calling through a function pointer |
| `br xN` | address in `xN` | **no** | jumping (a computed `goto`), e.g. jump tables |

`ret` is really `br x30` with a hint to the CPU that this is a return.

Which register to use for the target? Any of `x0`-`x15` or `x19`-`x28`. If the
pointer must survive other calls (it will be called again, in a loop), keep it in
a callee-saved register like `x19`. If you load it just before the call, a
temporary like `x9` is fine. Avoid `x16` and `x17`: the linker is allowed to
insert small stubs between a `bl` and its target that overwrite them.

## Callbacks

A *callback* is a function pointer you pass to another function, so that it can
call you back. In C:

```c
void show(int x)        { printf("[%d]", x); }
void show_square(int x) { printf("[%d]", x * x); }

void for_each(const int *a, long n, void (*fn)(int)) {
    for (long i = 0; i < n; i++)
        fn(a[i]);
}

for_each(nums, 5, show);
for_each(nums, 5, show_square);
```

`for_each` does not know what it will do with each element; the caller decides.
In assembly, passing `show` is just passing its address in a register:

```asm
    adrp x0, nums
    add  x0, x0, :lo12:nums         // arg 1: a
    mov  x1, #5                     // arg 2: n
    adr  x2, show                   // arg 3: fn (the address, not a call)
    bl   for_each
```

Inside `for_each`, the important question is *where do we keep `fn`?* It arrives
in `x2`. But `fn` is called five times, and each call (to `show`, which calls
`printf`) may destroy every register from `x0` to `x17`. So `for_each` copies its
arguments into callee-saved registers first, exactly like any function that
makes calls in a loop (lesson 15):

```asm
    mov x19, x0                     // a
    mov x20, x1                     // n
    mov x21, x2                     // fn
    mov x22, #0                     // i = 0
for_each_loop:
    cmp x22, x20
    b.ge for_each_done
    ldr w0, [x19, x22, lsl #2]      // argument: a[i]
    blr x21                         // fn(a[i])
    add x22, x22, #1
    b   for_each_loop
```

Read the whole file, [examples/callback.s](examples/callback.s). Predict the
output, then run it:

```console
# ./callback
[3][1][4][1][5]
[9][1][16][1][25]
```

Try this: change `mov x21, x2` to keep `fn` in `x9` instead, and use `blr x9`.
Build and run it. It crashes (`Bus error` or `Segmentation fault`) before
printing anything you can see, because `printf` reused `x9` and the second
`blr x9` jumped to garbage. That is the most common function-pointer bug.

## Sorting with `qsort`, searching with `bsearch`

The C library has a sort that works on *any* array, of any element type, because
you hand it a function that knows how to compare two elements:

```c
void qsort(void *base, size_t count, size_t size,
           int (*compar)(const void *, const void *));
```

- `base`: the array; `count`: how many elements; `size`: bytes per element.
- `compar(pa, pb)` gets *pointers to* two elements and returns a negative number
  if the first should come first, zero if they are equal, positive otherwise.

`qsort` only moves bytes around; it never looks inside an element. Your comparator
is the only code that knows these are `int`s.

For `int`s, in C:

```c
int cmp_int(const void *pa, const void *pb) {
    int a = *(const int *)pa, b = *(const int *)pb;
    return (a > b) - (a < b);       // 1, 0 or -1
}
```

In assembly, the comparator is a leaf function (it calls nothing), so it needs
no frame:

```asm
cmp_int:
    ldr  w2, [x0]                   // a = *pa
    ldr  w3, [x1]                   // b = *pb
    cmp  w2, w3
    cset w0, gt                     // w0 = (a > b)
    cset w4, lt                     // w4 = (a < b)
    sub  w0, w0, w4                 // return (a > b) - (a < b)
    ret
```

Why not just `return a - b`? Try `a = 2000000000`, `b = -2000000000`. The true
difference, 4000000000, does not fit in an `int`: the subtraction wraps to a
negative number and `qsort` gets told the larger number is smaller. The
`cset` version cannot overflow.

The call itself is four arguments, the last one being the comparator's address:

```asm
    adrp x0, nums
    add  x0, x0, :lo12:nums         // base
    mov  x1, #N                     // count
    mov  x2, #4                     // size = sizeof(int)
    adr  x3, cmp_int                // compar
    bl   qsort
```

`bsearch` finds a key in a *sorted* array with the same kind of comparator:

```c
void *bsearch(const void *key, const void *base, size_t count, size_t size,
              int (*compar)(const void *, const void *));
```

It returns a pointer to a matching element, or `NULL`. Notice that `key` is a
*pointer* to the value you are looking for, because the comparator receives
pointers. In assembly that means the key must be in memory: the program stores
it in the stack frame and passes its address (`add x0, sp, #16`). To turn the
returned pointer into an index, subtract the array's address and divide by the
element size (`asr #2` divides by 4).

The array lives in `.data`, not `.rodata`: `qsort` rearranges it in place, and
writing to `.rodata` would crash.

Read [examples/qsort_ints.s](examples/qsort_ints.s). Predict all four lines, then
run it:

```console
# ./qsort_ints
before: 42 -7 19 0 88 3 -20 19
after:  -20 -7 0 3 19 19 42 88
found 88 at index 7
5 is not in the array
```

Who calls `cmp_int`? Not your code: `qsort` does, from inside libc, many times.
Put a breakpoint on it in gdb (`break cmp_int`, `run`, then `bt`) and you will see
`qsort` in the backtrace. Your assembly function is being called by C, so it must
follow the calling convention exactly: arguments in `x0`/`x1`, result in `w0`,
and if it used `x19`-`x28` it would have to save them.

## Writing your own generic functions

Now write the other side: functions that *take* a function pointer. Two classics:

```c
// replace every element with f(element)
void map(int *a, long n, int (*f)(int)) {
    for (long i = 0; i < n; i++) a[i] = f(a[i]);
}

// copy the elements for which keep() returns non-zero; return how many
long filter(const int *src, long n, int *dst, int (*keep)(int)) {
    long k = 0;
    for (long i = 0; i < n; i++)
        if (keep(src[i])) dst[k++] = src[i];
    return k;
}
```

`map` is `for_each` plus a store. `filter` needs six values alive across the call
(`src`, `n`, `dst`, `keep`, `i`, `k`), so it saves `x19`-`x24`. One detail:
after `blr x22` returns, you need `src[i]` again to copy it. It was in `w0` before
the call, but `w0` now holds `keep`'s answer, so reload it from memory:

```asm
    ldr w0, [x19, x23, lsl #2]
    blr x22                         // keep(src[i])
    cbz w0, filter_next             // 0 means "drop it"
    ldr w9, [x19, x23, lsl #2]      // reload src[i]: the call may have trashed w9
    str w9, [x21, x24, lsl #2]      // dst[k] = src[i]
    add x24, x24, #1                // k++
```

The callbacks themselves are tiny leaf functions:

```asm
is_odd:
    and w0, w0, #1
    ret
square:
    mul w0, w0, w0
    ret
```

Read [examples/map_filter.s](examples/map_filter.s). The program filters 1..10
for odd numbers, then squares the result. Predict the three lines, then run it:

```console
# ./map_filter
start:   1 2 3 4 5 6 7 8 9 10
odd:     1 3 5 7 9
squared: 1 9 25 49 81
```

## `switch` and jump tables

Here is a `switch`:

```c
int calc(int op, int a, int b) {
    switch (op) {
    case 0:  return a + b;
    case 1:  return a - b;
    case 2:  return a * b;
    case 3:  return a / b;
    default: return -1;
    }
}
```

You already know one translation: a chain of `cmp` / `b.eq`, one per case. That
is fine for three cases. With fifty cases it is fifty comparisons for the last
one. When the case values are small and close together, compilers do something
smarter: they build a *table of where each case's code is*, use `op` as an index
into it, and jump there in one step. That is a *jump table*.

It takes four steps.

**1. Bounds check.** The table has an entry only for 0, 1, 2, 3. Any other `op`
must go to `default`, and must not be used as an index (it would read garbage
from past the end of the table and jump to it). One unsigned comparison catches
both "too big" and "negative":

```asm
    cmp  w0, #NCASES                // NCASES = 4
    b.hs calc_default               // unsigned >= 4
```

Why does that catch negatives? As an unsigned number, `-1` is `0xffffffff`,
which is much bigger than 4. So `b.hs` (unsigned higher-or-same) rejects
`op >= 4` *and* `op < 0` with one instruction. Using signed `b.ge` here would let
negative numbers through.

**2. Find the table.**

```asm
    adr  x9, calc_table
```

**3. Load the entry.** Each entry is a 4-byte `.word`, so entry `op` is at
`table + op * 4`:

```asm
    ldrsw x10, [x9, w0, uxtw #2]    // x10 = table[op]
```

`uxtw #2` means "zero-extend `w0` to 64 bits, then shift left by 2". You need the
zero-extension because `op` is an `int`: only `w0` is defined; the top half of
`x0` may hold anything (lesson 18). After the bounds check you know `w0` is 0..3.

**4. Jump.**

```asm
    add  x10, x9, x10               // address of the case
    br   x10
```

`br`, not `blr`: this is a `goto`, not a call. Each case ends with `ret`, which
returns straight to whoever called `calc`, because `x30` was never touched.

And the table itself:

```asm
calc_table:
    .word calc_case0 - calc_table
    .word calc_case1 - calc_table
    .word calc_case2 - calc_table
    .word calc_case3 - calc_table
```

Each entry is not an address but a *distance*: "case 0 is this many bytes from
the start of the table". The assembler computes these numbers itself, because
both labels are in the same section of the same file. The cases sit before the
table, so the distances are negative, which is why the load is `ldrsw` (sign
extend) rather than `ldr w`. Adding the distance back to the table's address
(step 4) gives the real address.

Why distances instead of `.quad calc_case0`? A distance stays correct wherever
the program is loaded, so nothing has to be patched at startup and the table can
live in read-only `.text`. More on that in the next section.

Let us trace `calc(2, 12, 4)` by hand. Suppose (`objdump -d jump_table` will show
you the real numbers) that the code is laid out like this:

| Address | Contents |
|---------|----------|
| `calc + 24` | `calc_case0` |
| `calc + 32` | `calc_case1` |
| `calc + 40` | `calc_case2` |
| `calc + 48` | `calc_case3` |
| `calc + 56` | `calc_default` |
| `calc + 64` | `calc_table`: `-40, -32, -24, -16` |

1. `cmp w0, #4`: 2 is lower, so no branch.
2. `x9 = calc + 64`.
3. `x10 = table[2] = -24`.
4. `x10 = calc + 64 - 24 = calc + 40`: `calc_case2`. `mul w0, w1, w2` = 48. `ret`.

Read [examples/jump_table.s](examples/jump_table.s). `main` calls `calc` for
`op` from -1 to 4. Predict all six lines (`12 / 4` with `sdiv`), then run:

```console
# ./jump_table
calc(-1, 12, 4) = -1
calc(0, 12, 4) = 16
calc(1, 12, 4) = 8
calc(2, 12, 4) = 48
calc(3, 12, 4) = 3
calc(4, 12, 4) = -1
```

A few more facts about real `switch` statements:

- **Gaps.** `case 1: case 2: case 5:` with nothing for 3 and 4 still makes a
  table; the entries for 3 and 4 point at `default`.
- **Shared bodies.** `case 3: case 4: return -x;` gives two entries with the same
  target.
- **Not starting at zero.** For `case 100` to `case 107`, subtract 100 first,
  then bounds-check against 8.
- **Sparse cases** like `case 1: case 1000: case 50000:` would need a huge mostly
  empty table, so compilers fall back to compare-and-branch.

Write the C version of `calc` in a file and look at `gcc -S -O2`. You will find
the same four steps; gcc packs its entries into `.byte` or `.hword` and scales
them, to make the table smaller.

## Dispatch tables: arrays of function pointers

A jump table jumps to labels inside one function. A *dispatch table* is an array
of whole functions you call with `blr`:

```c
int (*ops[4])(int, int) = {add_ints, sub_ints, mul_ints, max_ints};
const char *names[4]    = {"add", "sub", "mul", "max"};

for (long i = 0; i < 4; i++)
    printf("%s(9, 4) = %d\n", names[i], ops[i](9, 4));
```

`ops` is an array of four 8-byte addresses. Indexing it is exactly like indexing
any array of pointers (lesson 12), and then you call what you loaded:

```asm
    ldr  x9, [x20, x19, lsl #3]     // x9 = ops[i]
    mov  w0, #9
    mov  w1, #4
    blr  x9                         // ops[i](9, 4)
```

The table is written with `.quad`:

```asm
    .data
    .p2align 3
ops:
    .quad add_ints
    .quad sub_ints
    .quad mul_ints
    .quad max_ints
```

**Why `.data` and not `.rodata`?** A `.quad add_ints` holds an absolute address,
and you saw that the program is loaded at a different address every run. So
the assembler cannot know the number; it leaves a note (a *relocation*) and the
loader writes the real address into the slot when the program starts. The loader
can only write to writable sections. Put the table in `.text` or `.rodata`
and, on this Linux, it still links and runs, but `readelf -d dispatch_table`
shows a `TEXTREL` flag: the loader has to make your code writable for a moment
to patch it. That is a security hole, and many systems refuse to load such
programs. The macOS linker refuses outright ("Illegal text-relocations"). Rule
of thumb:

- A table of *offsets* (`.word a - b`) needs no relocation: put it anywhere.
- A table of *addresses* (`.quad sym`), including an array of string pointers,
  goes in `.data`.

That is why `names` is in `.data` too, even though we never change it.

Read [examples/dispatch_table.s](examples/dispatch_table.s), predict, run:

```console
# ./dispatch_table
add(9, 4) = 13
sub(9, 4) = 5
mul(9, 4) = 36
max(9, 4) = 9
```

## Structs with function pointer fields

Put function pointers in a struct and you get one of the most useful patterns in
C: objects that carry their own behaviour. Here each shape points to a table of
operations for its kind (C++ calls this table a *vtable*, and builds virtual
functions on exactly this):

```c
struct shape;
struct shape_ops {                          // offset
    long (*area)(const struct shape *);     //  0
    const char *name;                       //  8
};
struct shape {
    const struct shape_ops *ops;            //  0
    long w;                                 //  8
    long h;                                 // 16
};                                          // size 24

long rect_area(const struct shape *s)   { return s->w * s->h; }
long tri_area(const struct shape *s)    { return s->w * s->h / 2; }
long square_area(const struct shape *s) { return s->w * s->w; }

struct shape_ops rect_ops   = {rect_area,   "rectangle"};
struct shape_ops tri_ops    = {tri_area,    "triangle"};
struct shape_ops square_ops = {square_area, "square"};

struct shape shapes[3] = { {&rect_ops, 6, 4}, {&tri_ops, 6, 4}, {&square_ops, 5, 5} };

for (long i = 0; i < 3; i++) {
    struct shape *s = &shapes[i];
    long a = s->ops->area(s);
    printf("%s %ldx%ld: area %ld\n", s->ops->name, s->w, s->h, a);
}
```

The loop never asks "what kind of shape is this?". It follows two pointers
and calls whatever it finds. In assembly, `s->ops->area(s)` is two loads and a
`blr`, using the `.equ` offsets from lesson 19:

```asm
    ldr  x21, [x19, #SHAPE_OPS]     // x21 = s->ops
    ldr  x9,  [x21, #OPS_AREA]      // x9  = s->ops->area
    mov  x0, x19                    // the shape passes itself as the argument
    blr  x9                         // a = s->ops->area(s)
```

Passing the struct to its own function (`s`, or `this` in C++) is how the
function finds `w` and `h`.

Read [examples/vtable.s](examples/vtable.s). Predict the three lines, then run:

```console
# ./vtable
rectangle 6x4: area 24
triangle 6x4: area 12
square 5x5: area 25
```

To add a new kind of shape you write one function and one `shape_ops`; the loop
does not change. That is the payoff of function pointers.

## C to assembly

| C | Assembly (Linux) |
|---|------------------|
| `int (*f)(int);` | a 64-bit register or an 8-byte memory slot |
| `f = my_func;` (same file) | `adr x9, my_func` (or `adrp` + `add :lo12:`) |
| `f = puts;` (library) | `adrp x9, :got:puts` / `ldr x9, [x9, :got_lo12:puts]` |
| `f(x)` | `mov w0, ...` then `blr x9` |
| `f` called in a loop | keep `f` in `x19`-`x28` |
| pass `my_func` as an argument | `adr x2, my_func` then `bl other` |
| `qsort(a, n, size, cmp)` | `x0`=a, `x1`=n, `x2`=size, `x3`=&cmp, `bl qsort` |
| `bsearch(&key, a, n, size, cmp)` | key in memory, `x0`=&key ... `x4`=&cmp; result `x0` or 0 |
| comparator `(a > b) - (a < b)` | `cmp` / `cset gt` / `cset lt` / `sub` |
| `switch (x)` with dense cases | bounds check `cmp`/`b.hs`, `adr`, `ldrsw [.., uxtw #2]`, `add`, `br` |
| case table entry | `.word case_k - table` |
| `int (*ops[4])(int,int) = {...}` | `.data` + `.quad f0, f1, f2, f3` |
| `ops[i](a, b)` | `ldr x9, [base, i, lsl #3]` / `blr x9` |
| `s->ops->fn(s)` | `ldr x9, [s, #OPS]` / `ldr x9, [x9, #FN]` / `mov x0, s` / `blr x9` |

## Common mistakes

- **Keeping the function pointer in a temporary register across a call.**
  `blr x9` works the first time, then `x9` is overwritten by whatever the callee
  called, and the second `blr x9` jumps to a random address: `Segmentation fault`,
  `Bus error` or `Illegal instruction`. Use `x19`-`x28` for anything that must survive.
- **Calling instead of passing.** `bl show` then passing `x0` gives `for_each` the
  *return value* of `show`, not `show`. Use `adr x2, show`.
- **Using `br` where you meant `blr`.** The function runs, then its `ret` goes to
  wherever `x30` pointed before, usually your own caller. The program skips code
  or loops forever.
- **Using `bl` inside a jump-table case.** That is fine, but remember it overwrites
  `x30`: the function holding the jump table must have saved `x30` in its frame,
  like any non-leaf function.
- **A signed bounds check.** `b.ge` instead of `b.hs` lets negative indexes through,
  and the program jumps to whatever number it finds before the table.
- **Forgetting the bounds check entirely.** Same result for values past the end.
- **`ldr w` instead of `ldrsw` for offsets.** Negative offsets become huge positive
  ones and `br` jumps into nowhere.
- **Comparators that subtract.** `return a - b` overflows for far-apart values and
  sorts wrongly, with no crash to warn you.
- **Comparing pointers instead of values.** The comparator gets *pointers to*
  elements. For an array of strings, that is a `char **`: load once to get the
  `char *`, then compare (exercise 24.4).
- **Sorting `.rodata`.** `qsort` writes to the array: `Segmentation fault` inside
  `qsort` means your array is read-only.
- **A table of `.quad` addresses in `.text` or `.rodata`.** On Linux the program
  silently gets the `TEXTREL` flag (check with `readelf -d`); on macOS the link
  fails with "Illegal text-relocations". Move it to `.data`.
- **Wrong element size.** Passing `size = 8` for an `int` array makes `qsort` treat
  pairs of `int`s as one element.

## Recap

- A function's name is an address. `adr` (or `adrp` + `add`) loads it; a library
  function's address comes from the GOT.
- `blr xN` calls the address in `xN` and sets `x30`; `br xN` jumps without setting
  `x30`.
- A callback is just an argument that holds an address. Keep it in a callee-saved
  register if you call it more than once.
- `qsort` and `bsearch` are generic because your comparator does all the
  type-specific work. Comparators get pointers to elements and return
  negative/zero/positive.
- A dense `switch` becomes a jump table: unsigned bounds check, load an offset with
  `ldrsw`, add the table address, `br`.
- Offset tables (`.word a - b`) need no relocations; address tables (`.quad sym`)
  must live in `.data`.
- An array of function pointers is a dispatch table; a struct of function pointers
  is a vtable. Both turn "which code runs" into data.

## Homework

Do the exercises in [exercises.md](exercises.md), then read the macOS companion,
[../../apple-silicon/24-function-pointers/](../../apple-silicon/24-function-pointers/).
