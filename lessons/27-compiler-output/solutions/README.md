# Lesson 27 solutions

Programs: `ex4.s` to `ex8.s` (plus `ex8_main.c`). Build them all with `make`;
each file's header says what it prints. Written answers are below.

## Exercise 27.1

`gcc -O0` output (noise removed):

```asm
square:
	sub	sp, sp, #16
	str	w0, [sp, 12]
	ldr	w0, [sp, 12]
	mul	w0, w0, w0
	add	sp, sp, 16
	ret
sum_of_squares:
	stp	x29, x30, [sp, -48]!
	mov	x29, sp
	str	x19, [sp, 16]
	str	w0, [sp, 44]
	str	w1, [sp, 40]
	ldr	w0, [sp, 44]
	bl	square
	mov	w19, w0
	ldr	w0, [sp, 40]
	bl	square
	add	w0, w19, w0
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 48
	ret
```

1. Called, with `bl square`. `-O0` never inlines.
2. The result of the first `square(a)` is needed after the second call, to add
   to it. Even `-O0` keeps that temporary in a callee-saved register (`w19`)
   rather than a stack slot, so it must save and restore `x19`.
3. 48 bytes: `[sp, 0]` `x29`, `[sp, 8]` `x30`, `[sp, 16]` saved `x19`,
   `[sp, 40]` `b`, `[sp, 44]` `a`. The rest (24 to 39) is unused padding: gcc
   does not always pack `-O0` frames tightly.
4. At `-O2`, `square` is inlined and then deleted, since it is `static` and
   nothing calls it any more. `sum_of_squares` is `mul` + `madd` + `ret`.

## Exercise 27.2

```c
int mystery1(int x) {               // absolute value
    return x < 0 ? -x : x;
}

unsigned mystery4(unsigned x) {     // remainder by 10
    return x % 10;
}

long mystery5(long a, long b) {
    return a * 8 + b * 5;
}
```

- `mystery1`: `csneg w0, w0, w0, ge` is "`x >= 0 ? x : -x`".
- `mystery4`: the first four instructions are `q = x / 10` (the magic number
  `0xcccccccd` and shift 35 from the lesson). Then `add w1, w1, w1, lsl 2` is
  `q + 4q = 5q`, and `sub w0, w0, w1, lsl 1` is `x - 2 * 5q = x - 10q`, the
  remainder. It is unsigned because of `umull` and `lsr`.
- `mystery5`: `b + (b << 2)` is `5b`, then `5b + (a << 3)` is `5b + 8a`. No
  `mul` at all. `x` registers, so `long` (or `unsigned long`).

## Exercise 27.3

```asm
mystery2:
	ldrb	w1, [x0]
	cbz	w1, .L5             // s[0] == 0: return 0
	stp	x29, x30, [sp, -16]!
	add	x0, x0, 1
	mov	x29, sp
	bl	strlen              // !
	add	x0, x0, 1
	ldp	x29, x30, [sp], 16
	ret
.L5:
	mov	x0, 0
	ret

mystery3:
	mov	w1, 21846
	movk	w1, 0x5555, lsl 16  // magic number for 3
	smull	x1, w0, w1
	lsr	x1, x1, 32
	sub	w0, w1, w0, asr 31  // round toward zero for negative x
	b	g                   // tail call
```

- `mystery2` is the surprise. gcc recognised that the loop *is* `strlen`, and
  called the library's `strlen`, which is much faster than a byte-at-a-time
  loop for long strings. (It checks the first byte itself and calls
  `strlen(s + 1) + 1`, which is the same value.) This is called *idiom
  recognition*. `memset` and `memcpy` loops get the same treatment. Note the
  shrink-wrapping too: the frame is only built on the path that calls
  `strlen`. (Apple clang goes one step further and compiles all of `mystery2`
  to `b _strlen`.)
- `mystery3` is signed division by a constant (magic number `0x55555556`, the
  sign fix-up) followed by a tail call: `b g` instead of `bl g` + `ret`. No
  frame.

## Exercise 27.4

gcc's `digit_sum` at `-O2` does not use `udiv`: it computes `n / 10` with
`umull` by `0xcccccccd` and `lsr #35`, then `n % 10` as `n - 10 * (n / 10)`
with two shifted `add`/`sub`, and tests `n > 9` (`cmp w4, 9` / `bhi`) instead of
`n / 10 != 0`. Our solution uses `udiv` + `msub`, which is shorter to read but
slower.

## Exercise 27.5

Nothing to write beyond the program. If your output has a trailing space or no
final newline, check your `csel` condition: it must pick `'\n'` exactly when
`i == n - 1`.

## Exercise 27.6

The table, as in the `ex6.s` comments:

| Variable | Used after `bl is_prime`? | Register |
|----------|---------------------------|----------|
| `n` | yes (loop test) | `w19` |
| `k` | yes (`k++`, test) | `w20` |
| `count` | yes | `w21` |

`is_prime` calls nothing, so it is a leaf and uses scratch registers. Frame of
`count_primes`: `x29`, `x30`, `x19`, `x20`, `x21` = 40 bytes, rounded to 48.

## Exercise 27.7

`gcc -O2` gives:

```asm
udiv10:
	mov	x1, -3689348814741910324    // 0xcccccccccccccccc
	movk	x1, 0xcccd, lsl 0           // 0xcccccccccccccccd
	umulh	x0, x0, x1
	lsr	x0, x0, 3
	ret
```

Why it works: `umulh` keeps the high 64 bits of the 128-bit product, which
is the product shifted right by 64; the `lsr #3` makes 67 in total. So the
result is `(x * M) >> 67` with `M = 0xcccccccccccccccd`.

2^67 ends in ...928, so 2^67 is 2 short of a multiple of 10, and
`M = (2^67 + 2) / 10` exactly. Then

```
x * M / 2^67  =  x/10 + 2x / (10 * 2^67)  =  x/10 + x / (5 * 2^67)
```

The extra term is less than 2^64 / (5 * 2^67) = 1/40 for any 64-bit `x`. The
fractional part of `x/10` is at most 9/10, and 9/10 + 1/40 is still below 1,
so the shift (which truncates) always lands on exactly `x / 10`. The test in
`ex7.s` checks this for ten million values and the awkward edges.

## Exercise 27.8

With `n` read from a `volatile int`, both versions take about the same time.

With the constant `200000` passed directly, the C time drops to about a tenth.
`main` shows why:

```asm
 728:	mov	w0, #0xd40
 72c:	movk	w0, #0x3, lsl #16       // 200000
 730:	bl	960 <count_primes_c>    // called ONCE
 734:	mov	w1, #0xa                // 10
 738:	str	w0, [sp, #44]           // sink = result ...
 73c:	subs	w1, w1, #0x1
 740:	b.ne	738 <main+0x78>         // ... ten times
```

gcc worked out that `count_primes_c` has no side effects and depends only on
its argument (it is *pure*), so ten calls with the same argument must give the
same answer. It calls it once and stores the answer into `sink` ten times.
`noinline` stopped it pasting the body into `main`, but not this. It cannot do
the same to `count_primes_asm`, because it cannot see inside assembly, so the
asm loop really runs ten times. The benchmark was comparing 10 calls against 1.

The lesson: before you believe a benchmark, look at the disassembly of the
timing loop.

## 27.9

1. Non-leaf functions (those that save `x30` on the stack) get `paciasp` at the
   start and `autiasp` before `ret`. Leaf functions only get `bti c`, because
   they never store `x30` in memory, so there is nothing to protect, but they
   may still be the target of an indirect call. `paciasp` doubles as a BTI
   landing pad, so signed functions need no separate `bti c`.
2. `objdump` shows them as `paciasp`/`autiasp`/`bti c`, or as `hint #25`,
   `hint #29`, `hint #34` with older tools. Both programs print the same: the
   new instructions do not change the computation.
3. `autiasp` would find that the signature no longer matches `x30` and make it
   an invalid address (or trap at once on CPUs with FEAT_FPAC). The `ret`
   crashes the program instead of jumping to the attacker's chosen address.

