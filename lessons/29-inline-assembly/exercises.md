# Lesson 29 exercises

Work in `lessons/29-inline-assembly/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

The Makefile builds every `.c` file with `-O2`. After each exercise, look at
what the compiler did with your asm: `gcc -O2 -S -o - exN.c`. Try each exercise
before looking at the answers: programs are in [linux/solutions/](linux/solutions/),
written answers in [answers.md](answers.md).

## Exercise 29.1 [warm-up]

For each statement, say what each operand is (output/input, register/memory/
immediate, read/written), and whether anything is missing:

```c
asm("sub %0, %1, #1" : "=r"(a) : "r"(b));
asm("lsl %0, %0, %1" : "+r"(x) : "i"(3));
asm("cmp %0, %1\n\tcset %w2, lt" : : "r"(a), "r"(b), "r"(c));
asm("str %1, %0" : "=Q"(*p) : "r"(v));
asm("mrs %0, cntvct_el0" : "=r"(t));
```

## Exercise 29.2 [core]

Write `ex2.c` with `unsigned long mulhi(unsigned long a, unsigned long b)`
using `umulh` in inline asm. Check it against
`(unsigned long)(((unsigned __int128)a * b) >> 64)` for a few values. Then
look at the `-O2` output of the `__int128` version: did you need inline asm at
all?

Check:

```
mulhi(0xffffffffffffffff, 0xffffffffffffffff) = 0xfffffffffffffffe (int128: 0xfffffffffffffffe)
mulhi(0x100000000, 0x100000000) = 0x1 (int128: 0x1)
mulhi(0x3039, 0x10932) = 0x0 (int128: 0x0)
```

## Exercise 29.3 [core]

Write `ex3.c` with `rev64` and `rbit64` using the `rev` and `rbit`
instructions. Check `rev64` against `__builtin_bswap64`, and `rbit64` against
a C loop that reverses the bits one at a time.

Check:

```
rev(0x0102030405060708) = 0x0807060504030201, bswap: 0x0807060504030201
rbit(0x1) = 0x8000000000000000, loop: 0x8000000000000000
rbit(0xf0) = 0x0f00000000000000, loop: 0x0f00000000000000
```

## Exercise 29.4 [core]

Write `ex4.c` that times `sum_to(10000000)` (a simple loop) with the virtual
counter, and prints the time in ticks and in microseconds using
`cntfrq_el0`. Why does the timing read need `volatile` and `isb`?

Check: it prints the sum `50000005000000`, a time, and `ok`.

## Exercise 29.5 [core]

This function is supposed to return `a * 3 + b` but returns the wrong value
at `-O2` with some compilers and call sites:

```c
__attribute__((noinline)) static long times3_plus(long a, long b) {
    long r;
    asm("add %0, %1, %1, lsl #1\n\t"
        "add %0, %0, %2"
        : "=r"(r) : "r"(a), "r"(b));
    return r;
}
```

Explain the bug, fix it in `ex5.c`, and look at the register allocation in the
`-O2` output of both versions.

Check: `7 * 3 + 100 = 121`.

## Exercise 29.6 [stretch]

Write `ex6.c` with `atomic_inc(long *p)` implemented as an inline-asm
`ldaxr`/`add`/`stlxr`/`cbnz` retry loop (lesson 28). Use a `"+Q"(*p)` memory
operand and early-clobbered temporaries. Start four threads that each call it
a million times on one counter.

Check: `counter = 4000000`, every time. Then compare your code with what
`__atomic_fetch_add(p, 1, __ATOMIC_SEQ_CST)` compiles to (try both
`-march=armv8-a` and `-march=armv8.1-a`).
