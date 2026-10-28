# Lesson 16 solutions

Try each exercise yourself first. Programs: `ex2.s`, `ex3.s`, `ex5.s`,
`ex6.s` + `ex6_main.c`, `ex7.s` + `ex7_main.c`, `ex8.s`, `ex9.s` + `ex9_main.c`.
`make` builds them all.

## Exercise 16.1

1. It prints `44`. The exit status is only 8 bits: 300 = 256 + 44, and the
   kernel keeps `300 & 0xff = 44`. (`main` returning 300 is the same as
   `exit(300)`.)
2. Before: the kernel jumps to `_start` (the startup code in `Scrt1.o`), which
   collects `argc`/`argv`/`envp` and calls `__libc_start_main`, which
   initialises libc (stdio, thread-local storage, constructors) and calls
   `main`. After: `__libc_start_main` calls `exit` with `main`'s return value;
   `exit` runs `atexit` handlers, flushes the stdio buffers, and makes the
   exit system call.
3. It never executes `bl`, so `x30` still holds the return address when `ret`
   runs, and it does not move `sp` or touch any callee-saved register.
   `hello.s` calls `puts`, and `bl puts` overwrites `x30`.

## Exercise 16.3

`i` has to survive each `printf` call, so it lives in a callee-saved register
(`w19` in the solution). Because `main` is a function too, it saves the
caller's `x19` in its prologue and restores it before returning.

## Exercise 16.4

1. **`x30` is not saved.** `bl printf` overwrites it, so `ret` jumps to the
   instruction after `bl printf`, which is inside this function: it runs
   `add`, `ldr`, `ret` again and loops (or crashes). Save `x29`/`x30` with
   `stp x29, x30, [sp, #-16]!` and restore them.
2. **`sp` becomes misaligned.** `str x19, [sp, #-8]!` moves `sp` by 8, so it is
   no longer a multiple of 16 when `printf` is called. Accesses through a
   misaligned `sp` fault with `Bus error`. Allocate in multiples of 16.
   (Saving `x19` is pointless anyway: the function never uses it.)
3. **`n` is kept in `x9` across the call.** `x9` is caller-saved; `printf` may
   change it, so `x9 + 1` is garbage. Keep `n` in `x19` (that is what the saved
   `x19` should have been for).

A fixed version:

```asm
show_and_inc:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]
    mov     x19, x0
    mov     x1, x0
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    bl      printf
    add     x0, x19, #1
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
```

## Exercise 16.6

The Makefile rule:

```make
ex6: ex6_main.c ex6.s
	$(CC) $(ASFLAGS) -o $@ ex6_main.c ex6.s
```

`csel ..., gt` is the *signed* comparison, which is right for `long`. With
`hi` instead, `max3(-5, -2, -9)` would return `-2`... by luck, but
`max3(-1, 1, 0)` would return `-1`, since `-1` is the biggest *unsigned* value.

## Exercise 16.10

The `-O0` output:

```asm
fact:
	stp	x29, x30, [sp, -32]!   // prologue: 32-byte frame
	mov	x29, sp
	str	x0, [sp, 24]           // n gets a home on the stack
	ldr	x0, [sp, 24]
	cmp	x0, 1
	bgt	.L2                    // gcc's spelling of b.gt
	mov	x0, 1                  // n <= 1: return 1
	b	.L3
.L2:
	ldr	x0, [sp, 24]
	sub	x0, x0, #1
	bl	fact                   // fact(n - 1)
	mov	x1, x0
	ldr	x0, [sp, 24]           // reload n from the stack
	mul	x0, x1, x0             // fact(n - 1) * n
.L3:
	ldp	x29, x30, [sp], 32
	ret
```

1. gcc keeps `n` in the function's own stack frame (`[sp, 24]`), not in a
   callee-saved register. Both work: each recursive call has its own frame, so
   each has its own copy of `n`. Saving `x19` and keeping `n` there is the other
   common choice. `.L2` and `.L3` are local labels gcc invents (the `.L` prefix
   keeps them out of the symbol table).
2. At `-O2` there is no `bl` at all: gcc turned the recursion into a loop
   (`x0` is the running product, `x1` counts down):

   ```asm
   fact:
	mov	x1, x0
	mov	x0, 1
	cmp	x1, x0
	ble	.L1
   .L2:
	mov	x2, x1
	sub	x1, x1, #1
	mul	x0, x0, x2
	cmp	x1, 1
	bne	.L2
   .L1:
	ret
   ```

   The compiler is allowed to do this because the result is the same.
