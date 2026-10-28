# Lesson 27: Reading compiler output

## Goals

After this lesson you can:

- Translate any C function into assembly by hand with a fixed recipe, instead
  of staring at a blank file.
- Ask `gcc` (and `clang`) for the assembly they generate, and strip out the noise.
- Explain why `-O0` output looks so clumsy, and what `-O1` / `-O2` change.
- Recognise the common optimizations on sight: division by a constant done with
  a multiply, `csel` for a ternary, loop rotation, strength reduction, inlining,
  tail calls, leaf functions without a frame, and `stp`/`ldp` pairing.
- Read `objdump -d` of a whole program, including `_start` and the `printf@plt` stub.
- Time two versions of a function crudely and compare them.

## Before you start

You need everything up to lesson 25, especially:

- Lesson 14 and 15: frames, prologues and epilogues, callee-saved registers.
- Lesson 16: calling C from assembly and assembly from C, and the first look at `gcc -S`.
- Lesson 18: `int` vs `long`, sign extension, `umulh`.
- Lesson 10: `csel`.

There is very little new in this lesson. It is about *method*: a reliable way to
write assembly from C, and a reliable way to read the assembly a compiler writes.
Do it slowly. Type every command.

## Why read compiler output?

Two reasons.

1. **It checks your work.** When you translate C by hand, the compiler is a free
   second opinion. If your version and its version disagree about what a
   function returns, one of you is wrong, and usually it is you.
2. **It teaches you tricks.** Compilers have decades of tricks built in. Some of
   them, like dividing by 10 without a divide instruction, you would never
   think of on your own. Once you have seen them, you can use them.

You do not need to beat the compiler. You need to understand it.

## Part 1: a recipe for translating C by hand

When you face a C function and an empty `.s` file, follow these steps in order.
Write the answers to steps 1 to 4 down as a comment block before you write a
single instruction. It feels slow. It saves hours of debugging.

1. **Signature.** Where does each argument arrive (`w0`/`x0`, `w1`/`x1`, ... or
   `d0`, ... for floating point), and where does the result go? Note each
   argument's C type: `int` means a `w` register, `long` or a pointer means `x`.
2. **List the variables.** Every parameter and every local. Write their types.
3. **Decide where each one lives.** Ask one question per variable: *is it
   used after a function call?* (A call is any `bl` or `blr`.)
   - No: put it in a scratch register (`x9`-`x15`, or an argument register you
     no longer need).
   - Yes: put it in a callee-saved register (`x19`-`x28`), because the call is
     allowed to destroy every scratch register.
   - If its address is taken (`&x`), or it is an array or a struct you pass by
     pointer: it must live in memory, in a stack slot.
4. **Lay out the frame.** Does the function call anything? If yes, it needs to
   save `x29` and `x30`. Add 8 bytes for every callee-saved register you chose,
   plus the stack slots from step 3. Round the total up to a multiple of 16.
   Draw the frame with offsets.
5. **Prologue and epilogue.** Write them straight from the drawing: `stp x29,
   x30, [sp, #-SIZE]!`, `mov x29, sp`, then save the callee-saved registers in
   pairs. The epilogue restores in reverse.
6. **Statement by statement.** Now translate the body one C statement at a
   time, writing the C as a comment next to each group of instructions. Loops
   use the shapes from lesson 10; `if` uses the shapes from lesson 9.

### A worked example

Here is the C. Open [linux/examples/triangles.c](linux/examples/triangles.c):

```c
long print_triangles(int n) {
    long total = 0;
    long t = 0;
    for (int i = 1; i <= n; i++) {
        t += i;
        printf("T(%d) = %ld\n", i, t);
        total += t;
    }
    return total;
}

int main(void) {
    long s = print_triangles(5);
    printf("sum = %ld\n", s);
    return 0;
}
```

The *n*th triangle number is 1 + 2 + ... + n. Before reading on, predict: what
does this program print?

Now the recipe, for `print_triangles`.

**Step 1, signature.** `n` is an `int`, so it arrives in `w0`. The result is a
`long`, so it goes back in `x0`.

**Step 2, variables.** `n` (int), `total` (long), `t` (long), `i` (int).

**Step 3, where they live.** Look at the loop body. `printf` is called in the
middle of it. After the call we still use `i` (for `i++` and the test), `t`
(for `total += t` and the next `t += i`), `total`, and `n` (the loop test).
All four survive a call, so all four go into callee-saved registers:

| Variable | Type | Used after a call? | Register |
|----------|------|--------------------|----------|
| `n` | int | yes (loop test) | `w19` |
| `i` | int | yes | `w20` |
| `t` | long | yes | `x21` |
| `total` | long | yes | `x22` |

No variable has its address taken, so nothing needs a stack slot.

**Step 4, the frame.** We call `printf`, so we save `x29` and `x30` (16 bytes),
plus four callee-saved registers (32 bytes). Total 48, already a multiple of 16.

```
sp+40  x22
sp+32  x21
sp+24  x20
sp+16  x19
sp+8   x30
sp+0   x29   <- sp and x29 after the prologue
```

**Step 5, prologue and epilogue.** Straight from the drawing:

```asm
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    ...
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
```

**Step 6, statement by statement.** The whole result is in
[linux/examples/triangles.s](linux/examples/triangles.s). The body:

```asm
    mov w19, w0                 // n = argument
    mov x22, #0                 // long total = 0;
    mov x21, #0                 // long t = 0;
    mov w20, #1                 // int i = 1;
loop:
    cmp w20, w19                // i <= n ?
    b.gt done                   // no: leave the loop
    add x21, x21, w20, sxtw     // t += i;   (i is int, t is long: sign-extend)
    adrp x0, fmt_t              // printf("T(%d) = %ld\n", i, t);
    add x0, x0, :lo12:fmt_t
    mov w1, w20
    mov x2, x21
    bl printf
    add x22, x22, x21           // total += t;
    add w20, w20, #1            // i++
    b loop
done:
    mov x0, x22                 // return total;
```

One line deserves a closer look: `add x21, x21, w20, sxtw`. In C, `t += i`
adds an `int` to a `long`, so `i` is first converted to `long` (lesson 18). You
could write that as two instructions, `sxtw x9, w20` then `add x21, x21, x9`.
`add` can also sign-extend its last operand on the way in: `w20, sxtw` means
"take `w20`, sign-extend it to 64 bits, then add". It is the same thing in one
instruction, and the compiler uses it all the time, so get used to reading it.
`uxtw` is the zero-extending version, for `unsigned`.

Build and run both versions:

```console
$ cd lessons/27-compiler-output/linux/examples
$ make
$ ./triangles
T(1) = 1
T(2) = 3
T(3) = 6
T(4) = 10
T(5) = 15
sum = 35
$ ./triangles_c
T(1) = 1
T(2) = 3
T(3) = 6
T(4) = 10
T(5) = 15
sum = 35
```

Same output. Was your prediction right?

Notice what the recipe did for you: by the time you wrote the first
instruction, every decision was already made. The body was just bookkeeping.

## Part 2: asking the compiler

You met `gcc -S` in lesson 16. Here is the form to use from now on:

```console
$ gcc -O2 -S -o - funcs.c | grep -v '\.cfi'
```

- `-O2` is the optimization level (more below).
- `-S` means "stop after generating assembly".
- `-o -` means "write it to the terminal" instead of to `funcs.s`. Keep it this
  way: a `funcs.s` sitting in `examples/` would be picked up by the Makefile as
  a program to build.
- `grep -v '\.cfi'` deletes the `.cfi_...` lines. Those are *call frame
  information* for debuggers and exception unwinders. They do not turn into
  instructions, and they make the listing twice as long.

Pipe it through `less` if it scrolls off the screen.

Open [linux/examples/funcs.c](linux/examples/funcs.c). It is a set of tiny functions, each
chosen to show one idea. It has no `main`; it is never run, only compiled.

### What the noise means

Here is the first function, `div10`, exactly as `gcc -O2` prints it:

```asm
	.align	2
	.p2align 4,,11
	.global	div10
	.type	div10, %function
div10:
.LFB0:
	mov	w1, 52429
	movk	w1, 0xcccc, lsl 16
	umull	x0, w0, w1
	lsr	x0, x0, 35
	ret
.LFE0:
	.size	div10, .-div10
```

- `.align 2` and `.p2align 4,,11`: align the function start. `.p2align 4,,11`
  means "align to 16 bytes, but only if that costs at most 11 bytes of
  padding". Alignment helps the CPU fetch instructions; it changes nothing
  about what the code does.
- `.global`, `.type`, `.size`: you know these from lesson 20.
- `.LFB0` / `.LFE0`: "function begin / end" labels for the debug info. Labels
  starting with `.L` are *local*: they never appear in the symbol table.
- gcc writes immediates without `#` (`mov w1, 52429`). The assembler accepts
  both; our code always uses `#`.

Everything else is instructions. In the listings below the noise is removed.

## Part 3: -O0, the literal translation

`-O0` means "no optimization". The compiler translates each statement on its
own, as if it had forgotten everything it did on the previous line. The result
is easy to follow in a debugger, and that is the whole point of `-O0`.

`max` from `funcs.c`:

```c
int max(int a, int b) {
    return a > b ? a : b;
}
```

```console
$ gcc -O0 -S -o - funcs.c | grep -v '\.cfi'
```

```asm
max:
	sub	sp, sp, #16
	str	w0, [sp, 12]        // a goes to its stack slot
	str	w1, [sp, 8]         // b goes to its stack slot
	ldr	w0, [sp, 12]        // load a
	ldr	w2, [sp, 8]         // load b
	ldr	w1, [sp, 8]         // load b again
	cmp	w2, w0
	csel	w0, w1, w0, ge
	add	sp, sp, 16
	ret
```

(The comments are added by hand. The compiler writes none.)

At `-O0` **every variable lives in a stack slot**. Each statement loads what it
needs from the stack, computes, and stores the result back. That is why the
debugger can always show you every variable: it is always in memory.

Here is `sum_array` at `-O0`:

```c
long sum_array(const int *a, long n) {
    long s = 0;
    for (long i = 0; i < n; i++)
        s += a[i];
    return s;
}
```

```asm
sum_array:
	sub	sp, sp, #32
	str	x0, [sp, 8]         // a -> [sp, 8]
	str	x1, [sp]            // n -> [sp]
	str	xzr, [sp, 24]       // s = 0      ([sp, 24])
	str	xzr, [sp, 16]       // i = 0      ([sp, 16])
	b	.L8                 // jump to the test
.L9:
	ldr	x0, [sp, 16]        // i
	lsl	x0, x0, 2           // i * 4
	ldr	x1, [sp, 8]         // a
	add	x0, x1, x0          // &a[i]
	ldr	w0, [x0]            // a[i]
	sxtw	x0, w0              // (long)a[i]
	ldr	x1, [sp, 24]        // s
	add	x0, x1, x0          // s + a[i]
	str	x0, [sp, 24]        // s = ...
	ldr	x0, [sp, 16]        // i
	add	x0, x0, 1
	str	x0, [sp, 16]        // i++
.L8:
	ldr	x1, [sp, 16]        // i
	ldr	x0, [sp]            // n
	cmp	x1, x0
	blt	.L9                 // i < n: go round again
	ldr	x0, [sp, 24]        // return s
	add	sp, sp, 32
	ret
```

This is the best kind of listing for *learning*: you can match every C
operation to its instructions. Notice the loop shape: jump to the test at the
bottom first, body above it. It is the `while` shape from lesson 10. (gcc
writes `blt` for `b.lt`; both spellings mean the same instruction.)

Rule of thumb: **read `-O0` to see what a construct means; read `-O2` to see
how to do it well.**

## Part 4: -O1 and -O2, the idioms

`-O1` keeps variables in registers and removes obviously wasted work. `-O2`
adds many more transformations. (`-O3` adds more still, mostly loop
vectorization with the SIMD registers, which this course does not cover.
`-Os` optimizes for size.)

Run this and keep the output open while you read the rest of this section:

```console
$ gcc -O2 -S -o - funcs.c | grep -v '\.cfi'
```

### Leaf functions have no frame

Look at `max` at `-O2`:

```asm
max:
	cmp	w1, w0
	csel	w0, w1, w0, ge
	ret
```

Three instructions, and no `stp x29, x30` at all. `max` is a *leaf function*:
it calls nothing, so `x30` is never overwritten and does not need saving. It
uses only argument registers, so nothing else needs saving either. No frame is
needed. Your own leaf functions should look like this too.

### Ternaries become `csel`

`a > b ? a : b` became `cmp w1, w0` then `csel w0, w1, w0, ge`: "if `b >= a`
pick `b`, else `a`". The compiler swapped the comparison around, which is why
you see `ge` instead of `gt`. Work through `a = b` to convince yourself the
answer is the same either way.

Simple `if`/`else` statements that only choose between two values become
`csel` too. Its relatives also show up:

| C | Instruction |
|---|-------------|
| `x = c ? a : b` | `csel` |
| `x = c ? 1 : 0` | `cset` |
| `x = c ? a + 1 : a` | `cinc` |
| `x = x < 0 ? -x : x` | `csneg` (`cneg`) |

### Division by a constant becomes a multiply

`udiv` is slow: tens of cycles on some cores, compared with a few for a
multiply. When the divisor is a constant, the compiler replaces the division
with a multiplication by a "magic number" followed by a shift:

```c
unsigned div10(unsigned x) {
    return x / 10;
}
```

```asm
div10:
	mov	w1, 52429               // w1 = 0xcccd
	movk	w1, 0xcccc, lsl 16      // w1 = 0xcccccccd
	umull	x0, w0, w1              // x0 = (64-bit) x * 0xcccccccd
	lsr	x0, x0, 35              // x0 = that >> 35
	ret
```

`umull` is new: *unsigned multiply long*. It multiplies two 32-bit `w`
registers and puts the full 64-bit product in an `x` register, so nothing is
lost. (`smull` is the signed version. `umulh`/`smulh`, from lesson 18, do the
same job one size up: the high half of a 64 by 64 product.)

Why does this work? Dividing by 10 is the same as multiplying by 1/10. We
cannot multiply by a fraction, but we can multiply by 2^35 / 10 and then
divide by 2^35, which is a right shift by 35:

```
2^35 / 10 = 3435973836.8   round up ->   3435973837 = 0xcccccccd
```

Try it by hand for x = 123:

```
123 * 3435973837 = 422624781951
422624781951 >> 35 = 422624781951 / 34359738368 = 12.3...  -> 12
```

and 123 / 10 is indeed 12. Rounding the magic number *up* makes a tiny error,
and the compiler chose the shift (35) so that the error is too small to ever
change the answer for any 32-bit `x`. You do not need to derive magic numbers
yourself: when you need one, write the C and let the compiler find it.

`x % 10` uses the same trick, then computes `x - (x / 10) * 10`.

Signed division needs one more step, because C rounds signed division toward
zero and a right shift rounds toward minus infinity:

```asm
div7:
	mov	w1, 9363
	movk	w1, 0x9249, lsl 16      // magic number for 7
	smull	x1, w0, w1              // signed 64-bit product
	lsr	x1, x1, 32              // high 32 bits
	add	w1, w0, w1
	asr	w1, w1, 2               // w1 = rounded-down quotient
	sub	w0, w1, w0, asr 31      // x >= 0: subtract 0;  x < 0: subtract -1
	ret
```

The last line is the fix-up. `w0, asr 31` is 0 when `x` is non-negative and
-1 (all ones) when `x` is negative. Subtracting -1 adds 1, which turns
"rounded down" into "rounded toward zero" for negative numbers.

Division by a power of two is simpler still: unsigned `x / 8` is `lsr w0, w0, #3`.

### Loops are rotated

Here is `sum_array` at `-O1` (the `-O2` version is nearly identical):

```asm
sum_array:
	cmp	x1, 0
	ble	.L7                 // n <= 0: skip the loop entirely
	mov	x2, x0              // p = a
	add	x3, x0, x1, lsl 2   // end = a + n
	mov	x0, 0               // s = 0
.L6:
	ldrsw	x1, [x2], 4         // s += *p++
	add	x0, x0, x1
	cmp	x2, x3              // p != end ?
	bne	.L6
.L4:
	ret
.L7:
	mov	x0, 0
	b	.L4
```

Compare with `-O0`. Three things changed.

1. **Loop rotation.** The test moved to the *bottom* of the loop, so each trip
   round runs one branch (`bne`) instead of two (`b` to the test, then `blt`
   back). To keep the meaning of a `for` loop, which might run zero times, the
   compiler adds a *guard* in front: `cmp x1, 0` / `ble`. Guard plus
   bottom-tested loop: that is the shape of almost every optimized loop you
   will read. In C it is:

   ```c
   if (n > 0) {
       do { ... } while (...);
   }
   ```

2. **The index became a pointer.** There is no `i` any more. The compiler
   computed `end = a + n` once and walks a pointer `p` until it reaches `end`,
   using a post-index load (lesson 11) to step it by 4. The `lsl` that scaled
   `i` on every trip is gone.

3. **Everything is in registers.** No stack slots, no `sub sp`.

### Strength reduction

*Strength reduction* replaces an expensive operation inside a loop with a
cheaper one. The classic case: a multiplication by the loop counter.

```c
void fill_multiples(int *a, int n) {
    for (int i = 0; i < n; i++)
        a[i] = i * 12;
}
```

```asm
fill_multiples:
	cmp	w1, 0
	ble	.L10                // guard: n <= 0
	add	w1, w1, w1, lsl 1   // w1 = n + 2n = 3n
	mov	w2, 0               // v = 0       (v is always i * 12)
	lsl	w1, w1, 2           // w1 = 3n * 4 = 12n   (the final value of v)
.L12:
	str	w2, [x0], 4         // *p++ = v
	add	w2, w2, 12          // v += 12     (instead of v = i * 12)
	cmp	w2, w1
	bne	.L12                // until v == 12n
.L10:
	ret
```

There is no `mul` in the loop. The compiler noticed that `i * 12` grows by
exactly 12 each time round, so it keeps a running value `v` and adds 12. It
also dropped `i` altogether: the loop now ends when `v` reaches `12 * n`.

Notice too how it computed `12 * n` with no multiply: `n + (n << 1)` is `3n`,
and `3n << 2` is `12n`. Shifted operands (lesson 8) make small multiplications
very cheap.

### Inlining

```c
static int square(int x) {
    return x * x;
}
int sum_of_squares(int a, int b) {
    return square(a) + square(b);
}
```

```asm
sum_of_squares:
	mul	w1, w1, w1          // b * b
	madd	w0, w0, w0, w1      // a * a + (b * b)
	ret
```

There is no `bl square`, and `square` itself does not appear in the output at
all. The compiler *inlined* it: pasted its body into the caller. Because
`square` is `static`, nothing outside this file can call it, so once every call
is inlined the function is not needed. Inlining saves the call and the frame,
and often makes more optimizations possible afterwards (here, `madd` combines
the second multiply with the add).

When you read `-O2` output and a function you wrote in C seems to be missing,
it was inlined.

### Tail calls

```c
int helper(int x);
int call_helper(int x) {
    return helper(x + 1);
}
```

```asm
call_helper:
	add	w0, w0, 1
	b	helper
```

`b`, not `bl`. When the very last thing a function does is return what another
function returns, there is nothing left to do after the call. So instead of
calling `helper` and then returning, `call_helper` *jumps* to `helper`, leaving
`x30` untouched. When `helper` executes `ret`, it returns straight to
`call_helper`'s caller. This is a *tail call*. It needs no frame, and a
recursive function whose recursive call is a tail call uses no stack at all.

You can do this in your own code whenever a call is the last thing before your
epilogue: restore everything first, then `b` instead of `bl` + `ret`.

### Callee-saved registers and `stp`/`ldp` pairing

```c
long twice(long x);
long combine(long a, long b) {
    long x = twice(a);
    long y = twice(b);
    return x + y + a;
}
```

```asm
combine:
	stp	x29, x30, [sp, -48]!
	mov	x29, sp
	stp	x19, x20, [sp, 16]  // two callee-saved registers in one store
	mov	x20, x0             // a  -> x20   (needed after both calls)
	str	x21, [sp, 32]       // an odd one out: a single str
	mov	x21, x1             // b  -> x21   (needed after the first call)
	bl	twice
	mov	x19, x0             // x  -> x19   (needed after the second call)
	mov	x0, x21
	bl	twice
	add	x0, x19, x0         // x + y
	ldr	x21, [sp, 32]
	add	x0, x0, x20         // + a
	ldp	x19, x20, [sp, 16]
	ldp	x29, x30, [sp], 48
	ret
```

This is the recipe from Part 1, done by the compiler. `a`, `b` and `x` each
survive a call, so they go in `x19`-`x21`; `y` is used right after the last
call, so it stays in `x0`. The frame is 16 (for `x29`/`x30`) + 24 (three
registers) = 40, rounded up to 48. Registers are saved in pairs with `stp`
wherever possible, because one `stp` does the work of two `str`s.

You will also see the compiler mix the saves in among other instructions
(`str x21` after `mov x20, x0`). The order does not matter, as long as each
register is saved before it is changed and restored before `ret`.

### The worked example, compiled

Compare your hand translation of `print_triangles` with `gcc -O2`:

```console
$ gcc -O2 -S -o - triangles.c | grep -v '\.cfi'
```

```asm
print_triangles:
	stp	x29, x30, [sp, -64]!
	mov	x29, sp
	stp	x21, x22, [sp, 32]
	cmp	w0, 0
	ble	.L4                 // guard: n <= 0
	mov	w22, w0             // n
	str	x23, [sp, 48]
	adrp	x23, .LC0           // the format string's address, kept in x23
	add	x23, x23, :lo12:.LC0
	mov	x21, 0              // total
	stp	x19, x20, [sp, 16]
	mov	x19, 1              // i, as a 64-bit value
	mov	x20, 0              // t
.L3:
	add	x20, x20, x19       // t += i
	mov	w1, w19
	mov	x2, x20
	mov	x0, x23
	add	x19, x19, 1         // i++ (moved up, before the call)
	bl	printf
	add	x21, x21, x20       // total += t
	cmp	w22, w19
	bge	.L3                 // bottom-tested loop
	ldp	x19, x20, [sp, 16]
	mov	x0, x21
	ldp	x21, x22, [sp, 32]
	ldr	x23, [sp, 48]
	ldp	x29, x30, [sp], 64
	ret
.L4:
	mov	x21, 0
	mov	x0, x21
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 64
	ret
```

Same register choices as ours, more or less, plus three tricks:

- **Loop-invariant code motion.** The address of the format string is the same
  every time round, so the compiler computes it once, before the loop, and
  keeps it in a fifth callee-saved register, `x23`. We recomputed it with
  `adrp`/`add` on every trip. That is two instructions per trip traded for one
  extra register save.
- **Widening `i`.** Keeping `i` in a 64-bit register avoids the sign extension
  in `t += i`. It is safe because `i` only counts from 1 up to an `int`.
- **Shrink-wrapping.** Look at the `n <= 0` path (`.L4`): it never saves `x19`,
  `x20` or `x23`, because it never uses them. The compiler moved those saves
  *after* the guard, so the early exit is cheaper.

None of these change what the function does. That is the rule for every
optimization: the program must behave exactly as the C says, only faster.

## Part 5: gcc vs clang

The container has only `gcc`, but your Mac has `clang`, and clang can generate
Linux assembly too as long as the file does not `#include` any headers (it
would need Linux's headers for that). `funcs.c` includes nothing, so, on the
Mac, in this lesson's `examples/` directory:

```console
$ clang -O2 -S --target=aarch64-linux-gnu -o - funcs.c | grep -v '\.cfi'
```

The output has the same ideas, written differently:

```asm
div10:
	mov	w8, #52429                      // =0xcccd
	movk	w8, #52428, lsl #16
	umull	x8, w0, w8
	lsr	x0, x8, #35
	ret
max:
	cmp	w0, w1
	csel	w0, w0, w1, gt
	ret
call_helper:
	add	w0, w0, #1
	b	helper
```

- clang likes `x8`/`w8` as its first scratch register; gcc picks the lowest free
  argument register. Register choice is arbitrary. Do not read meaning into it.
- clang writes `#` before immediates and adds comments like `// =0xcccd`.
- Same magic number for `div10`, the same `csel` (with the comparison the other
  way round), the same tail call.
- clang's `sum_array` and `fill_multiples` at `-O2` are much longer and use
  registers like `v0.2d` and `q4`. That is **vectorization**: processing 4 or 8
  array elements per instruction with the SIMD registers. It is out of scope
  for this course. Add `-fno-vectorize` to turn it off and you get loops very
  like gcc's.

Reading two compilers' output for the same function is a good way to separate
what is essential (the magic number, the `csel`) from what is just one
compiler's habit (which register, which order).

You can also use Compiler Explorer (godbolt.org) in a browser: paste C on the
left, pick "ARM64 gcc" or "armv8-a clang" and see assembly on the right, with
each C line coloured to match its instructions.

## Part 6: reading `objdump` of a real program

`gcc -S` shows one file before it is assembled. `objdump -d` shows the finished
executable, after linking, with everything the C library added. Build the
examples if you have not, then:

```console
$ objdump -d --no-show-raw-insn triangles | less
```

`-d` disassembles every section that holds code. `--no-show-raw-insn` hides the
4-byte machine code of each instruction (drop it if you want to see the
encodings from lesson 03). To see just one function:

```console
$ objdump -d --no-show-raw-insn --disassemble=main triangles
```

Here is the part of the output that matters, from `examples/triangles`. Your
addresses may differ slightly.

```
0000000000000630 <printf@plt>:
 630:	adrp	x16, 20000 <__libc_start_main@GLIBC_2.34>
 634:	ldr	x17, [x16, #32]
 638:	add	x16, x16, #0x20
 63c:	br	x17

0000000000000640 <_start>:
 640:	nop
 644:	mov	x29, #0x0
 648:	mov	x30, #0x0
 64c:	mov	x5, x0
 650:	ldr	x1, [sp]
 654:	add	x2, sp, #0x8
 658:	mov	x6, sp
 65c:	adrp	x0, 1f000 <__FRAME_END__+0x1e730>
 660:	ldr	x0, [x0, #4056]
 664:	mov	x3, #0x0
 668:	mov	x4, #0x0
 66c:	bl	5f0 <__libc_start_main@plt>
 670:	bl	620 <abort@plt>
...
0000000000000754 <print_triangles>:
 754:	stp	x29, x30, [sp, #-48]!
 758:	mov	x29, sp
 ...
0000000000000774 <loop>:
 774:	cmp	w20, w19
 778:	b.gt	7a0 <done>
 77c:	add	x21, x21, w20, sxtw
 780:	adrp	x0, 0 <__abi_tag-0x278>
 784:	add	x0, x0, #0x7f8
 788:	mov	w1, w20
 78c:	mov	x2, x21
 790:	bl	630 <printf@plt>
 ...
00000000000007b4 <main>:
 7b4:	stp	x29, x30, [sp, #-16]!
 7b8:	mov	x29, sp
 7bc:	mov	w0, #0x5
 7c0:	bl	754 <print_triangles>
 ...
```

Read it from left to right: the address, a colon, the instruction. Branch
targets are shown as an address plus the nearest symbol in `<...>`.

Things to notice:

- **`_start` is not ours.** We wrote `main`. The C library's startup code
  provides `_start`, which the kernel jumps to. It zeroes `x29` and `x30` (so a
  debugger knows this is the outermost frame), picks `argc` and `argv` off the
  stack (`ldr x1, [sp]`, `add x2, sp, #8`), loads the address of `main` from
  the GOT (`adrp` + `ldr`, lesson 25), and calls `__libc_start_main`. That
  function calls `main`, then `exit` with `main`'s return value. It never
  returns, so if it somehow did, `abort` is next.
- **`bl printf` became `bl 630 <printf@plt>`.** `printf` lives in the shared
  library `libc.so.6`, whose address is not known until the program runs. So
  the linker made a small stub, `printf@plt` (*procedure linkage table*), and
  pointed our `bl` at it. The stub loads the real address of `printf` from a
  table that the dynamic loader fills in at startup, and jumps there with
  `br x17`. Because `br` is a jump, not a call, `x30` still holds the return
  address in our code, so `printf`'s `ret` comes straight back to us.
- **This is why `x16` and `x17` are "intra-procedure-call scratch"
  registers** (lesson 15). Stubs like this one use them between your `bl` and
  the real function. Never expect `x16`/`x17` to survive a call, not even
  "into" the call.
- **`adrp x0, 0` + `add x0, x0, #0x7f8`.** Our `adrp x0, fmt_t` /
  `add x0, x0, :lo12:fmt_t`, with the linker's numbers filled in: the string is
  on page 0 of this program, at offset `0x7f8`. The `<__abi_tag-0x278>` part
  is just objdump naming the address after the nearest symbol it knows; ignore it.
- **Our labels `loop` and `done` show up as if they were functions.** Any
  label that does not start with `.L` goes into the symbol table, and
  `objdump` starts a new heading at each symbol. That is harmless, but if you
  want cleaner disassembly and debugger backtraces, name loop labels `.Lloop`,
  `.Ldone` and so on, like the compiler does.
- **Addresses are small** (`0x754`). The program is a *position-independent
  executable*: the kernel loads it at a random base address every run, and
  these numbers are offsets from that base. That is why every address in our
  code is computed with `adrp` (relative to the current instruction) rather
  than written as a constant.

There is a lot more in the full output (`_init`, `frame_dummy`,
`__do_global_dtors_aux`...). That is C library and linker machinery. When you
read a real program, find `main` first and work outwards from there.

## Part 7: crude timing

Is hand-written assembly faster than the compiler? Measure, do not guess.
[linux/examples/bench.s](linux/examples/bench.s) contains a hand-written leaf function:

```asm
// long sum_squares_asm(const int *a, long n)
sum_squares_asm:
    mov x2, #0                  // s = 0
    cbz x1, 2f                  // n == 0: nothing to do
    add x3, x0, x1, lsl #2      // end = a + n
1:
    ldrsw x4, [x0], #4          // x4 = *a++ (sign-extended to long)
    madd x2, x4, x4, x2         // s += x4 * x4
    cmp x0, x3
    b.ne 1b                     // loop until a == end
2:
    mov x0, x2
    ret
```

(`1:` and `2:` are *numeric local labels*: `1b` means "the
nearest `1:` backwards", `2f` "the nearest `2:` forwards".)

[linux/examples/bench_main.c](linux/examples/bench_main.c) has the same loop in C, fills a
million-element array, and times 200 calls of each version with `clock()`,
which returns the CPU time used so far, in units of `CLOCKS_PER_SEC` per
second. Two details matter in any benchmark like this:

- `__attribute__((noinline))` on the C version, so the compiler cannot paste it
  into `main` and notice that all 200 calls return the same answer.
- `volatile` variables for the argument `n` and for each result. `volatile`
  tells the compiler "this memory can change, or be looked at, behind your
  back", so it must really read `n` before every call and really store every
  result. Without that, gcc can notice that `sum_squares_c` only reads memory,
  that nothing changes between the calls, and that the argument is the same
  each time, and call it *once* instead of 200 times.

Without these, an optimizing compiler can make the "fast" version look ten
times faster than it is, or take zero time, by not doing the work, and your
benchmark measures nothing. (Exercise 27.8 lets you watch this happen.)

The Makefile builds it with an explicit rule, because `bench.s` has no `main`
of its own:

```make
bench: bench.s bench_main.c
	$(CC) $(ASFLAGS) -O2 -o $@ $^
```

Predict: which will be faster? Then:

```console
$ ./bench
asm:     sum = 332833500000   time = 0.058 s
C -O2:   sum = 332833500000   time = 0.058 s
```

Your times will be different, and will change a little each run: run it three
or four times. The sums must always match.

They are about the same, and the disassembly shows why:

```console
$ objdump -d --no-show-raw-insn --disassemble=sum_squares_c bench
```

```
 a18:	ldr	w1, [x2], #4
 a1c:	smaddl	x0, w1, w1, x0
 a20:	cmp	x3, x2
 a24:	b.ne	a18 <sum_squares_c+0x18>
```

gcc wrote almost exactly the same four-instruction loop. (`smaddl` is *signed
multiply-add long*: it multiplies two 32-bit values into a 64-bit result and
adds it, so it does not even need the `ldrsw`.) For simple code, a good
compiler is as fast as careful hand-written assembly. The value of knowing
assembly is mostly in *understanding*: knowing what your C turns into, reading
crash dumps and disassembly, and writing the rare piece C cannot express.

Crude timing rules:

- Repeat the work enough times that it takes at least a tenth of a second.
- Run the whole thing several times and look at the spread.
- Always print a result computed from the work, and check it.
- Compare on the same machine, same build, nothing else heavy running.

## Part 8: pointer authentication and branch protection

Compile almost anything with a recent compiler for a hardened system and you
will meet instructions this course has not used:

```console
# printf 'long g(long);\nlong f(long x){return g(x)+1;}\nlong leaf(long x){return x+1;}\n' > p.c
# gcc -O2 -S -mbranch-protection=standard -o - p.c
```

```asm
f:
	hint	25 // paciasp
	stp	x29, x30, [sp, -16]!
	mov	x29, sp
	bl	g
	add	x0, x0, 1
	ldp	x29, x30, [sp], 16
	hint	29 // autiasp
	ret
leaf:
	hint	34 // bti c
	add	x0, x0, 1
	ret
```

These come from two security features added to the architecture after
ARMv8.0.

### PAC: pointer authentication

A classic attack overwrites a saved return address on the stack (lesson 17's
buffer overflow) so that `ret` jumps into the attacker's code. **Pointer
authentication** makes that much harder:

- `paciasp` ("PAC instruction-address with key A, using sp") is executed
  first, while `x30` is still trustworthy. It computes a cryptographic
  signature of `x30` combined with the current `sp` and a secret key that
  only the kernel knows, and stores it in the unused top bits of `x30`.
- The signed `x30` is saved and restored by the normal prologue and
  epilogue.
- `autiasp` checks the signature before `ret`. If the saved value was
  changed, the check fails: `x30` becomes an invalid address (or, on newer
  CPUs, the instruction traps at once), and the program crashes instead of
  jumping where the attacker wanted.

Leaf functions do not save `x30` on the stack, so they do not need signing;
`leaf` above has none.

### BTI: branch target identification

An attacker who can make a `br`/`blr` (an indirect branch, lesson 24) jump
anywhere could land in the middle of a function. With **branch target
identification**, pages can be marked so that an indirect branch may only land
on a `bti` instruction (`bti c` for call targets, `bti j` for jump targets).
`paciasp` counts as a valid landing pad too, which is why `f` above has no
separate `bti c`.

### Why they are written as `hint`

`paciasp`, `autiasp`, and `bti` are encoded in the `hint` space, a range of
instructions that older CPUs execute as **no-ops**. So one binary runs
everywhere: protected on new hardware, unprotected (but working) on old.
That is also why `objdump` may show `hint #25` instead of `paciasp`.

### What it means for your code

- **Reading compiler output:** treat `paciasp`/`autiasp` (or `pacibsp`/`retab`
  on Apple) as part of the prologue and epilogue, and `bti` as a marker at the
  top of functions. They do not change what the function computes.
- **Writing assembly:** on Linux and on standard macOS `arm64`, nothing in
  this course needs them, and programs without them run fine. If you link into
  a program built with `-mbranch-protection=standard` and the system enforces
  BTI, every function that is called indirectly needs a `bti c` first.
- **Never edit `x30` between `paciasp` and `autiasp`**, and keep `sp` the same
  at both, since the signature includes `sp`.

## C to assembly

| C | Unoptimized (`-O0`) | Optimized (`-O2`) |
|---|---------------------|-------------------|
| a local variable | a stack slot, loaded and stored around every use | a register, or nothing at all |
| a variable live across a call | stack slot | callee-saved register `x19`-`x28` |
| `x / 10` (unsigned) | `udiv` | `umull` by `0xcccccccd`, `lsr #35` |
| `x / 8` (unsigned) | `lsr #3` (even at `-O0`) | `lsr #3` |
| `c ? a : b` | sometimes branches | `cmp` + `csel` |
| `x < 0 ? -x : x` | branches | `cmp` + `csneg` |
| `for (i = 0; i < n; i++)` | jump to test at the bottom | guard + bottom-tested `do`/`while` |
| `a[i]` in a loop | `lsl` + `add` + `ldr` each time | pointer with post-index `ldr [p], #4` |
| `i * 12` in a loop | `mul` each time | running sum `v += 12` |
| a call to a small `static` function | `bl` | the body, inlined |
| `return f(x);` | `bl f` then epilogue and `ret` | epilogue then `b f` |
| a function that calls nothing | frame anyway | no frame, no saves |
| two register saves | `str`, `str` | one `stp` |
| `(long)i + t` | `sxtw` then `add` | `add x, x, w, sxtw` |
| `printf(...)` in a linked program | `bl printf@plt` | `bl printf@plt` |

## Common mistakes

- **Skipping steps 2 to 4 of the recipe.** Then you discover halfway through
  the body that `i` was in `x9` and `printf` destroyed it. The symptom: a loop
  that runs the wrong number of times, or forever, only after you add a
  `printf` to debug it.
- **Putting a value that survives a call in `x9`-`x15`, or `x0`-`x7`.** Same
  symptom. Every one of those can be changed by any call.
- **Using a callee-saved register without saving it.** Your function works; its
  caller crashes later, somewhere unrelated. Every `x19`-`x28` you write must be
  in the prologue and the epilogue.
- **Forgetting the frame size must be a multiple of 16.** Three saved
  registers plus `x29`/`x30` is 40 bytes: round up to 48.
- **Generating `.s` files into `examples/` or `solutions/`.** `gcc -S funcs.c`
  writes `funcs.s` next to `funcs.c`, and `make` then tries to build it as a
  program and fails with "undefined reference to `main`". Use `-o -`, or work
  in your `work/` directory.
- **Reading meaning into register numbers.** `w8` vs `w1` in two compilers'
  output is a coin toss, not a difference in behaviour.
- **"My function disappeared from the `-O2` output."** It was inlined (and, if
  `static`, then deleted). Mark it `__attribute__((noinline))` or look at `-O1`.
- **Benchmarks that measure nothing.** If the optimized version takes 0.000 s,
  the compiler probably deleted the work. Use the result, use `noinline` and
  `volatile`.
- **Trusting one timing run.** Times jump around by 10% or more. Run several times.

## Recap

- Translate C by hand with the recipe: signature, variables, where each lives
  (callee-saved if used after a call), frame drawing, prologue/epilogue, then
  statement by statement.
- `gcc -O2 -S -o - file.c | grep -v '\.cfi'` shows the compiler's assembly.
- `-O0` keeps every variable in a stack slot: easy to read, slow.
- `-O2` keeps values in registers and applies idioms: magic-number division,
  `csel`, rotated loops with a guard, pointers instead of indexes, strength
  reduction, inlining, tail calls, frameless leaf functions, `stp`/`ldp` pairs.
- gcc and clang reach the same ideas with different register choices; clang
  vectorizes more eagerly (`-fno-vectorize` turns it off).
- `objdump -d` shows the whole linked program: `_start` from the C library,
  `printf@plt` stubs that use `x16`/`x17`, and real addresses.
- Measure with repeated runs, `noinline`, `volatile`, and a checked result.
  For simple loops the compiler is as fast as you.

## Homework

[exercises.md](exercises.md)
