# Lesson 27 on macOS: reading compiler output

Do [lesson 27](../README.md) first. The recipe for
translating C by hand and the optimization idioms are the same on macOS. What
differs here:

- The compiler is Apple `clang`, so the listings look like clang's, not gcc's.
- `printf` arguments in the worked example go on the stack (variadic rule).
- Apple clang lays out frames differently.
- `objdump` on macOS is LLVM's, with different flags, and a Mach-O program has
  no `_start` and no PLT: it has `__stubs` instead.
- On the benchmark, clang vectorizes the C loop, so the C version wins.

## Building the examples

```console
$ cd lessons/27-compiler-output/apple-silicon/examples
$ make
$ ./triangles
T(1) = 1
T(2) = 3
T(3) = 6
T(4) = 10
T(5) = 15
sum = 35
$ ./triangles_c
...same output...
$ ./bench
asm:     sum = 332833500000   time = 0.062 s
C -O2:   sum = 332833500000   time = 0.012 s
```

`funcs.c`, `triangles.c` and `bench_main.c` are the same C files as in the
Linux flavor.

## The worked example: `triangles.s`

The recipe gives the same answer as on Linux: `n`, `i`, `t` and `total` all
survive the `printf` call, so they live in `w19`, `w20`, `x21` and `x22`, and
the frame is 48 bytes. The one change is the call itself. Both `i` and `t` are
variadic arguments of `printf`, so on macOS they go on the stack, one 8-byte
slot each:

```asm
    adrp x0, fmt_t@PAGE         // printf("T(%d) = %ld\n", i, t);
    add x0, x0, fmt_t@PAGEOFF
    sub sp, sp, #16             // room for the two variadic arguments
    str w20, [sp]               // i in the first 8-byte slot
    str x21, [sp, #8]           // t in the second
    bl _printf
    add sp, sp, #16
```

`sub sp, sp, #16` right before the call and `add sp, sp, #16` right after it
keep `sp` 16-byte aligned and leave our saved registers above untouched. You
could instead make the frame 16 bytes bigger and keep the argument area at the
bottom of it permanently; that is what clang does (see below).

Everything else is the Linux version with `_` prefixes, `@PAGE`/`@PAGEOFF`,
`__TEXT,__cstring` for the strings, and no `.type`/`.size`.

## Asking clang

```console
$ clang -O2 -S -o - funcs.c | grep -v '\.cfi'
```

The noise is different from gcc's:

- Comments start with `;` (clang adds lots: `; -- Begin function`, `; =0xcccd`,
  `; 16-byte Folded Spill`). Add `| grep -v '^\s*;'` to drop the comment-only lines.
- `.build_version macos, ...` at the top and `.subsections_via_symbols` at the
  bottom are Mach-O bookkeeping.
- Local labels start with `L` (Mach-O's local prefix), not `.L`: `LBB3_2` is
  "basic block 2 of function 3".
- `Lloh0:` labels and `.loh AdrpAdd Lloh0, Lloh1` lines are *linker
  optimization hints*: they tell Apple's linker which `adrp`/`add` pairs it may
  shorten. Ignore them.

Here is part of the `-O2` output (with `-fno-vectorize`, see below):

```asm
_div10:
	mov	w8, #52429                      ; =0xcccd
	movk	w8, #52428, lsl #16
	umull	x8, w0, w8
	lsr	x0, x8, #35
	ret
_max:
	cmp	w0, w1
	csel	w0, w0, w1, gt
	ret
_sum_array:
	cmp	x1, #1
	b.lt	LBB3_4
	mov	x8, #0                          ; =0x0
LBB3_2:
	ldrsw	x9, [x0], #4
	add	x8, x8, x9
	subs	x1, x1, #1
	b.ne	LBB3_2
	mov	x0, x8
	ret
LBB3_4:
	mov	x8, #0                          ; =0x0
	mov	x0, x8
	ret
_call_helper:
	add	w0, w0, #1
	b	_helper
```

Same ideas as gcc: the magic number for `/ 10`, `csel`, a guard plus a
bottom-tested loop, a tail call. Notice that clang's `sum_array` counts `n`
down to zero with `subs` and tests the flags it set, instead of comparing a
pointer with an end pointer. Both are standard loop shapes.

Without `-fno-vectorize`, `sum_array` and `fill_multiples` come out several
times longer, full of `ldp q16, q17`, `smlal2.2d` and `v0`-`v7`. That is clang
using the SIMD registers to handle 4 or 8 elements per instruction. It is out
of scope for this course; turn it off with `-fno-vectorize` when you want to
read the plain loop.

### `-O0` on clang

clang's `-O0` is even more literal than gcc's. `max` does not get a `csel`; it
branches, through a temporary stack slot:

```asm
_max:
	sub	sp, sp, #16
	str	w0, [sp, #12]
	str	w1, [sp, #8]
	ldr	w8, [sp, #12]
	ldr	w9, [sp, #8]
	subs	w8, w8, w9
	b.le	LBB2_2
	b	LBB2_1
LBB2_1:
	ldr	w8, [sp, #12]
	str	w8, [sp, #4]
	b	LBB2_3
LBB2_2:
	ldr	w8, [sp, #8]
	str	w8, [sp, #4]
	b	LBB2_3
LBB2_3:
	ldr	w0, [sp, #4]
	add	sp, sp, #16
	ret
```

That is the C `if`/`else` translated word for word, including a `b LBB2_1`
that jumps to the very next instruction. At `-O0` clang does not even remove
that.

### Apple clang's frames

`combine` at `-O2`:

```asm
_combine:
	stp	x22, x21, [sp, #-48]!
	stp	x20, x19, [sp, #16]
	stp	x29, x30, [sp, #32]
	add	x29, sp, #32
	mov	x19, x1
	mov	x20, x0
	bl	_twice
	mov	x21, x0
	mov	x0, x19
	bl	_twice
	add	x8, x21, x20
	add	x0, x8, x0
	ldp	x29, x30, [sp, #32]
	ldp	x20, x19, [sp, #16]
	ldp	x22, x21, [sp], #48
	ret
```

Three differences from gcc and from our own frames:

- The `x29`/`x30` pair (the *frame record*) is at the **top** of the frame,
  and `x29` points at it (`add x29, sp, #32`), not at the bottom. Apple's
  tools expect the frame record there. Both layouts are valid AAPCS64; the
  rules only say `x29` must point at the saved `x29`/`x30` pair.
- It saves `x22` although it never uses it. It needed three callee-saved
  registers (`x19`-`x21`), and saving four lets it use only `stp`, never a
  lone `str`, with no change in frame size.
- The pairs are written high register first (`x22, x21`). That is just habit.

At `-O0`, clang also uses `stur`/`ldur` (`stur x0, [x29, #-8]`): these are
ordinary stores and loads whose offset is not a multiple of the access size, or
negative. The assembler picks them for you when you write `str x0, [x29, #-8]`.

### The worked example, compiled by Apple clang

```console
$ clang -O2 -S -o - triangles.c | grep -v '\.cfi'
```

The `print_triangles` function is there, and it keeps the outgoing argument
area permanently at the bottom of its frame (`stp x23, x21, [sp]` right
before `bl _printf`, no `sub sp`). But look at `main`:

```asm
_main:
	...
	mov	w8, #1
	stp	x8, x8, [sp]            ; i = 1, t = 1
	adrp	x19, l_.str@PAGE
	add	x19, x19, l_.str@PAGEOFF
	mov	x0, x19
	bl	_printf
	mov	w20, #3
	mov	w8, #2
	stp	x8, x20, [sp]           ; i = 2, t = 3
	mov	x0, x19
	bl	_printf
	...
	mov	w8, #35
	str	x8, [sp]                ; sum = 35
	...
	bl	_printf
```

clang inlined `print_triangles(5)` into `main`, saw that `n` is the constant
5, *unrolled* the loop completely (five copies of the body, no loop left), and
computed every `t` and the total at compile time. The program is now five
`printf` calls with constants. This is the extreme case of the lesson's rule:
the program must behave as the C says, and nothing more. Nothing in the C says
the additions must happen at run time.

## `objdump` on macOS

macOS ships LLVM's `objdump`. The option to pick a function is
`--disassemble-symbols`, and symbol names have their `_`:

```console
$ objdump -d --no-show-raw-insn --disassemble-symbols=_main triangles
```

```
0000000100000478 <_main>:
100000478:     	stp	x29, x30, [sp, #-0x10]!
10000047c:     	mov	x29, sp
100000480:     	mov	w0, #0x5                ; =5
100000484:     	bl	0x100000410 <_print_triangles>
100000488:     	sub	sp, sp, #0x10
10000048c:     	str	x0, [sp]
100000490:     	adrp	x0, 0x100000000 <_printf+0x100000000>
100000494:     	add	x0, x0, #0x4d2
100000498:     	bl	0x1000004ac <_printf+0x1000004ac>
10000049c:     	add	sp, sp, #0x10
1000004a0:     	mov	w0, #0x0                ; =0
1000004a4:     	ldp	x29, x30, [sp], #0x10
1000004a8:     	ret
```

`otool -tv triangles` is the traditional Apple tool for the same job, and it
annotates better: it prints `bl 0x1000004ac ; symbol stub for: _printf` and
`; literal pool for: "T(%d) = %ld\n"` next to the `adrp`/`add` of a string.

What is different from the Linux walkthrough:

- **Addresses start at `0x100000000`.** The first 4 GiB of every 64-bit macOS
  process is `__PAGEZERO`, an unmapped region that makes any pointer that was
  truncated to 32 bits crash immediately. Code starts above it. The program is
  still position-independent and is slid to a random address at run time.
- **There is no `_start`.** A Mach-O executable names its entry point with an
  `LC_MAIN` load command (see it with `otool -l triangles | grep -A3 LC_MAIN`).
  The dynamic loader, `dyld`, loads libSystem and then calls `_main` directly,
  and passes `main`'s return value to `exit`.
- **No PLT; `__stubs` instead.** `bl _printf` goes to a stub in the
  `__TEXT,__stubs` section:

  ```console
  $ objdump -d --no-show-raw-insn -j __stubs triangles
  ```

  ```
  00000001000004ac <__stubs>:
  1000004ac:     	adrp	x16, 0x100004000 <_printf+0x100004000>
  1000004b0:     	ldr	x16, [x16]
  1000004b4:     	br	x16
  ```

  Same idea as Linux's `printf@plt`: load the real address of `printf` from a
  table `dyld` filled in, and jump with `br`, so `x30` still points back into
  our code. And again it uses `x16`, the intra-procedure-call scratch register.
- objdump's `<_printf+0x100000000>` labels are nonsense guesses at the nearest
  symbol; trust the address and `otool`'s comments instead.

## The benchmark

On an M-series Mac, clang's `-O2` *vectorizes* `sum_squares_c` (the SIMD
registers again: `objdump --disassemble-symbols=_sum_squares_c bench` shows
`smlal2.2d` and friends), so it does four or more elements per instruction and
beats the hand-written scalar loop by about five times:

```console
$ ./bench
asm:     sum = 332833500000   time = 0.062 s
C -O2:   sum = 332833500000   time = 0.012 s
```

To compare like with like, build the C without vectorization:

```console
$ clang -O2 -fno-vectorize -o bench_nv bench.s bench_main.c
$ ./bench_nv
asm:     sum = 332833500000   time = 0.067 s
C -O2:   sum = 332833500000   time = 0.059 s
```

Now they are about level, as on Linux with gcc. (gcc 12 at `-O2` does not
vectorize this loop; at `-O3` it would.) Delete `bench_nv` afterwards, or
build it in your `work/` directory.

## Pointer authentication on Apple

Apple uses pointer authentication more than anyone, but only in the **`arm64e`**
architecture, which system libraries and Apple's own apps are built for.
Normal programs, including everything in this course, are plain **`arm64`**,
where the compiler emits no PAC instructions.

```console
$ printf 'long g(long);\nlong f(long x){return g(x)+1;}\n' > p.c
$ clang -O2 -S -arch arm64e -o - p.c
_f:
	pacibsp
	stp	x29, x30, [sp, #-16]!
	mov	x29, sp
	bl	_g
	add	x0, x0, #1
	ldp	x29, x30, [sp], #16
	retab
```

- `pacibsp` signs `x30` with key **B** (Linux uses key A: `paciasp`).
- `retab` checks the signature and returns in one instruction (Linux:
  `autiasp` then `ret`).

You will see these whenever you disassemble Apple's own binaries, which are
`arm64e`:

```console
$ file /bin/ls
/bin/ls: Mach-O universal binary with 2 architectures: [x86_64:...] [arm64e:...]
$ otool -arch arm64e -tv /bin/ls | grep -m3 'pacibsp\|retab'
0000000100000960	pacibsp
00000001000016d4	pacibsp
00000001000019ec	retab
```
 Your own
`arm64` programs do not need them. Exercise 27.9 works on macOS with
`clang -arch arm64e -S`; building and *running* `arm64e` programs outside
Apple's own software is not generally supported.

## Exercises

Do the exercises in the [main lesson](../exercises.md),
writing macOS programs. Notes:

- **27.1-27.3**: the listings in the exercises are gcc's. Do them as written
  (you can read gcc output without gcc), then also compile the same C with
  `clang -O2 -S` and compare. clang gives `mystery1` as `cmp w0, #0` /
  `cneg w0, w0, mi` and `mystery2` as a single `b _strlen`: it recognises the
  `strlen` loop too, and since `strlen` returns exactly what `mystery2` must
  return, the call becomes a tail call.
- **27.4-27.7**: every `printf` argument after the format string goes on the
  stack. `ex7`'s mismatch message has three, so reserve 32 bytes.
- **27.8**: build with `clang -O2 -o ex8 ex8.s ex8_main.c`. The `volatile`
  experiment works the same: with the constant passed directly, clang also
  calls `count_primes_c` once instead of ten times.

Solutions are in [solutions/](solutions/); the written answers are in the
[main lesson's solutions/README.md](../answers.md).
