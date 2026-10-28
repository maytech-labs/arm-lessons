# Lesson 29 answers

Programs: [ex2.c](linux/solutions/ex2.c) to [ex6.c](linux/solutions/ex6.c).

## 29.1

1. `a`: output register, written; `b`: input register, read. Complete.
2. `x`: register, read and written; `3`: immediate. Complete. (The template
   becomes `lsl xN, xN, 3`; the assembler accepts an immediate with or
   without `#`.)
3. **Broken.** `c` is written by `cset` but listed as an input, and the asm
   changes the flags without a `"cc"` clobber. It also has no outputs, so the
   compiler treats it as volatile but has no idea `c` changed. Fix:
   `asm("cmp %1, %2\n\tcset %w0, lt" : "=r"(c) : "r"(a), "r"(b) : "cc");`
4. `*p`: memory output (`Q`, printed as `[xN]`); `v`: input register.
   Complete: the memory operand tells the compiler exactly what is written.
5. `t`: output register. **Missing `volatile`**: without it, two reads may be
   merged into one, or an unused read deleted, because the compiler thinks the
   result depends only on (no) inputs.

## 29.2

With `unsigned __int128`, GCC and Clang emit exactly one `umulh`. Inline asm
was not needed, and the C version is better: the optimiser understands it.

## 29.4

`volatile`: every read has a different result, so the compiler must not merge
or move the reads. `isb`: the CPU itself may otherwise read the timer before
earlier instructions have finished, which makes short measurements wrong.

## 29.5

Outputs are assumed to be written after all inputs are read, so the compiler
may put `r` in the same register as `b`. The first `add` then overwrites `b`
before the second `add` reads it. Mark `r` early-clobber: `"=&r"(r)`. In the
output of the fixed version, `r` always gets a register different from both
inputs.

## 29.6

At `-march=armv8-a`, `__atomic_fetch_add` compiles to an `ldaxr`/`stlxr`
loop like yours (or a call to a helper that chooses at run time,
`__aarch64_ldadd8_acq_rel`, with GCC's default outline-atomics). At
`-march=armv8.1-a` it becomes a single `ldaddal`.
