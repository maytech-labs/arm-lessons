# Lesson 30: SIMD with NEON

## Goals

After this lesson you can:

- Explain SIMD: one instruction operating on several values ("lanes") at once.
- Name a vector register's lanes with arrangements: `.16b`, `.8h`, `.4s`, `.2d`.
- Load and store whole vectors with `ld1`/`st1`, and de-interleave with
  `ld2`/`ld3`.
- Do lane-wise integer and floating-point arithmetic, including `mla` and
  `fmla` by an element.
- Reduce a vector to one value with `addv`, `sminv`, `smaxv`, `uaddlv`.
- Use vector compares as masks, to replace branches.
- Structure a vectorised loop: a vector body plus a scalar tail.

## Before you start

You need lesson 12 (arrays), 18 (lane sizes are C's integer sizes), and 23
(the floating-point registers `s0`/`d0` are parts of the vector registers).

This is an introduction. NEON has hundreds of instructions; this lesson
teaches the model and the core of them, enough to read vectorised compiler
output and write simple vector loops.

```console
# cd lessons/30-simd-neon/examples && make
```

## The idea

Most loops do the same thing to every element of an array. A scalar `add`
handles one element per instruction. AArch64's 32 **vector registers**
`v0`-`v31` are 128 bits wide, and the **Advanced SIMD** instructions (better
known as **NEON**) treat a register as several independent **lanes**:

```
v0 as .16b  | b15 | b14 | ... | b1 | b0 |     16 lanes of 8 bits
v0 as .8h   |  h7  |  h6  | ... |  h0  |     8 lanes of 16 bits
v0 as .4s   |    s3    |    s2    |    s1    |    s0    |   4 lanes of 32 bits
v0 as .2d   |          d1         |          d0         |   2 lanes of 64 bits
```

One `add v0.4s, v1.4s, v2.4s` performs **four** 32-bit additions, lane by
lane. No lane affects another: there are no carries between lanes.

These are the same registers you used for `float` and `double` in lesson 23:
`s0` is the low 32 bits of `v0`, `d0` the low 64 bits. The calling convention
is the same too: `v8`-`v15` are callee-saved, but **only their low 64 bits**
(`d8`-`d15`); the rest are caller-saved.

## Arrangements

The suffix after the register name says how to split it:

| Arrangement | Lanes | Lane size | C element |
|-------------|-------|-----------|-----------|
| `.16b` | 16 | 8 bits | `char`, `uint8_t` |
| `.8h` | 8 | 16 bits | `short` |
| `.4s` | 4 | 32 bits | `int`, `float` |
| `.2d` | 2 | 64 bits | `long`, `double` |
| `.8b`, `.4h`, `.2s` | | | the same, using only the low 64 bits |

A single lane is written with an index: `v0.s[2]` is lane 2 of `v0` as 32-bit
lanes; `v0.b[15]` is the top byte.

## Load, compute, store

`examples/lanes.s`:

```asm
    ld1 {v0.4s}, [x0]           // v0 = a[0..3]: 4 lanes of 32 bits
    ...
    ld1 {v1.4s}, [x0]           // v1 = b[0..3]
    add v8.4s, v0.4s, v1.4s     // FOUR additions, one instruction

    mov w1, v8.s[0]             // copy single lanes out to general registers
    mov w2, v8.s[1]
```

```console
# ./lanes
{1 2 3 4} + {10 20 30 40} = {11 22 33 44}
the same 16 bytes as 8 halfwords: 11 0 22 0 33 0 44 0
```

- `ld1 {v0.4s}, [x0]` loads 16 bytes as four `int`s. `st1` stores. Both
  support post-increment: `ld1 {v0.4s}, [x0], #16`.
- `mov w1, v8.s[0]` (also spelled `umov`) copies one lane to a general
  register. `smov` sign-extends. `mov v0.s[1], w1` (`ins`) puts a value into
  one lane.
- The register's bits are just bits. Reading the same register as `.8h` lanes
  shows each 32-bit sum split into a low and a high 16-bit half.

Note that `main` saves `d8` because it uses `v8` across a `printf` call.

### Getting constants into vectors

| Instruction | Does |
|-------------|------|
| `movi v0.16b, #'a'` | every byte lane = `'a'` |
| `movi v0.4s, #0` | zero (also `movi v0.2d, #0`) |
| `dup v0.4s, w1` | every 32-bit lane = `w1` |
| `ld1r {v0.4s}, [x0]` | load one `int` and copy it into every lane |

## Lane-wise arithmetic

The same mnemonics as scalar code, with arrangements:

| Instruction | Does |
|-------------|------|
| `add`, `sub`, `mul` | integer arithmetic per lane |
| `mla vd, vn, vm` | `vd += vn * vm` per lane |
| `smin`, `smax`, `umin`, `umax` | per-lane minimum / maximum |
| `and`, `orr`, `eor`, `bic` (`.16b`) | bitwise |
| `shl`, `ushr`, `sshr` | shifts by an immediate |
| `fadd`, `fsub`, `fmul`, `fdiv` (`.4s`, `.2d`) | floating point per lane |
| `fmla vd.4s, vn.4s, vm.s[k]` | `vd += vn * (lane k of vm)` |
| `scvtf`, `fcvtzs` | convert between `int` and `float` per lane |

`examples/saxpy.s` is the classic `y = a*x + y` on floats:

```asm
    ldr s2, [x11]               // a, in lane 0 of v2
    mov x12, #N
1:  ld1 {v0.4s}, [x9], #16      // 4 x values
    ld1 {v1.4s}, [x10]          // 4 y values
    fmla v1.4s, v0.4s, v2.s[0]  // y += x * a   (a: lane 0 of v2, used for every lane)
    st1 {v1.4s}, [x10], #16     // store 4 results
    subs x12, x12, #4
    b.ne 1b
```

The "by element" form `v2.s[0]` uses one lane as a scalar for all four lanes,
so there is no need to `dup` `a` first.

## Reductions: from four lanes to one value

At the end of a vector loop you have several partial results, one per lane.
**Across-lanes** instructions combine them:

| Instruction | Gives |
|-------------|-------|
| `addv s0, v1.4s` | sum of the lanes, in `s0` |
| `sminv`, `smaxv`, `uminv`, `umaxv` | minimum / maximum of the lanes |
| `uaddlv h0, v1.16b` | sum of 16 bytes, widened to 16 bits (no overflow) |
| `addp` | pairwise add (for `.2d`, which has no `addv`) |

The result is in the low lane of a vector register. Move it out with
`fmov w1, s0` or `umov`.

`examples/sum_array.s` keeps four partial sums, minimums, and maximums:

```asm
    movi v0.4s, #0              // four partial sums
    ld1r {v1.4s}, [x9]          // four partial minimums, all = a[0]
    mov v2.16b, v1.16b          // four partial maximums, all = a[0]

vector_loop:                    // while at least 4 elements remain
    cmp x10, #4
    b.lo reduce
    ld1 {v3.4s}, [x9], #16      // the next 4 elements
    add v0.4s, v0.4s, v3.4s
    smin v1.4s, v1.4s, v3.4s
    smax v2.4s, v2.4s, v3.4s
    sub x10, x10, #4
    b vector_loop

reduce:                         // combine the 4 lanes into one value each
    addv s0, v0.4s              // s0 = lane0 + lane1 + lane2 + lane3
    sminv s1, v1.4s
    smaxv s2, v2.4s
    ...
tail_loop:                      // the 0-3 elements that did not fill a vector
```

```console
# ./sum_array
sum 190, min 1, max 19
```

## The tail

Arrays are rarely a multiple of the vector width. The standard structure is:

1. **Vector loop** while at least one full vector of elements remains.
2. **Reduce** (if the loop accumulates).
3. **Scalar tail** loop for the last few elements.

`sum_array.s` has 19 elements: four vector iterations (16 elements) and three
tail iterations. Forgetting the tail is the most common vectorisation bug, and
reading past the end of the array instead of having a tail is the second.

## Compares as masks: no branches

A vector compare does not set flags (there would be one result per lane). It
writes a **mask**: all ones in each lane where the comparison is true, all
zeros where it is false. Masks combine with `and`/`bic`/`bsl` to select
values lane by lane.

| Instruction | Lane = all ones if |
|-------------|--------------------|
| `cmeq` | equal |
| `cmgt`, `cmge` | greater (than or equal), signed |
| `cmhi`, `cmhs` | higher (or same), unsigned |
| `fcmgt`, `fcmeq`, ... | floating point |

`examples/upper.s` uppercases 16 characters per step. For each byte, "is it
between `'a'` and `'z'`" is the unsigned trick from lesson 13 exercise 13.5:
`c - 'a' < 26`:

```asm
    movi v4.16b, #'a'           // 16 copies of 'a'
    movi v5.16b, #26            // 16 copies of 26
    movi v6.16b, #0x20          // 16 copies of the case bit
vector_loop:
    ...
    ld1 {v0.16b}, [x9]          // 16 characters
    sub v1.16b, v0.16b, v4.16b  // c - 'a' (wraps for c < 'a': becomes large)
    cmhi v2.16b, v5.16b, v1.16b // 26 > c - 'a' ?  0xff : 0x00, per byte
    and v2.16b, v2.16b, v6.16b  // 0x20 where it is a lowercase letter
    eor v0.16b, v0.16b, v2.16b  // flip bit 5 there
    st1 {v0.16b}, [x9], #16
```

```console
# ./upper
HELLO, SIMD WORLD! 0123456789 ABC XYZ {}
```

Sixteen decisions, no branches. This is how fast string functions (`strlen`,
`memchr`, `strchr`) are written in C libraries.

## Interleaved data: `ld2`, `ld3`, `ld4`

Data often comes interleaved: RGB pixels are `R G B R G B ...`, stereo audio
is `L R L R ...`. `ld3 {v0.16b, v1.16b, v2.16b}, [x0]` loads 48 bytes and
**de-interleaves** them: all 16 reds in `v0`, greens in `v1`, blues in `v2`.
`st3` interleaves on the way back. Exercise 30.5 uses it.

## Letting the compiler do it

At `-O2` (GCC) or `-O1` (Clang) and above, compilers **auto-vectorise** simple
loops. Compile a loop like `for (i...) sum += a[i];` with
`gcc -O3 -S` and you will find `ld1`, `add v.4s`, `addv`, and a tail, much like
`sum_array.s`. Reading that output is now within your reach. For loops the
compiler cannot vectorise, C programmers use **intrinsics** from `<arm_neon.h>`
(`vaddq_s32`, `vld1q_f32`, ...), which map one-to-one onto these instructions.

## C to assembly

| C (intrinsics or intent) | Assembly |
|--------------------------|----------|
| `int32x4_t v = vld1q_s32(p);` | `ld1 {v0.4s}, [x0]` |
| `vst1q_s32(p, v);` | `st1 {v0.4s}, [x0]` |
| `vaddq_s32(a, b)` | `add v0.4s, v1.4s, v2.4s` |
| `vmlaq_s32(acc, a, b)` | `mla v0.4s, v1.4s, v2.4s` |
| `vfmaq_laneq_f32(y, x, a, 0)` | `fmla v0.4s, v1.4s, v2.s[0]` |
| `vdupq_n_s32(x)` | `dup v0.4s, w0` |
| `vaddvq_s32(v)` (sum of lanes) | `addv s0, v0.4s` |
| `vgetq_lane_s32(v, 1)` | `mov w0, v0.s[1]` |
| `vceqq_u8(a, b)` | `cmeq v0.16b, v1.16b, v2.16b` |
| `vld3q_u8(p)` | `ld3 {v0.16b, v1.16b, v2.16b}, [x0]` |
| a loop over an array | vector body + reduction + scalar tail |

## Common mistakes

- **No tail loop**: the last `n % 4` elements are skipped, or the vector loop
  reads past the end.
- **Overflowing narrow lanes.** Sixteen bytes of 0xff summed in byte lanes
  wrap. Widen first (`uaddlv`, `uaddl`, `uxtl`).
- **Wrong arrangement**: `add v0.16b` on `int` data adds bytes, with no carries
  between them.
- **Forgetting that only `d8`-`d15` are callee-saved.** The upper halves of
  `v8`-`v15` and all of `v16`-`v31` may change across a call.
- **Expecting compares to set flags.** Vector compares produce masks; test
  them with reductions (`umaxv` of the mask is non-zero if any lane matched).
- **Misaligned or out-of-bounds loads** at the end of a buffer: a 16-byte load
  near the end of memory can cross into an unmapped page.

## Recap

- 32 vector registers `v0`-`v31`, 128 bits, split into lanes by arrangement:
  `.16b`, `.8h`, `.4s`, `.2d`.
- `ld1`/`st1` move whole vectors; `ld2`-`ld4` de-interleave.
- Arithmetic is lane by lane, with no interaction between lanes.
- Reductions (`addv`, `smaxv`, `uaddlv`, ...) combine lanes at the end.
- Vector compares produce masks; combine them with bitwise operations instead
  of branching.
- A vectorised loop = vector body + reduction + scalar tail.
- Compilers auto-vectorise simple loops; intrinsics expose these instructions
  to C.

## Homework

[exercises.md](exercises.md). On a Mac, read the
[Apple Silicon companion](../../apple-silicon/30-simd-neon/README.md) next.
