# Lesson 29 on macOS: Inline assembly

Read [the main lesson](../../lessons/29-inline-assembly/README.md) first.
Clang implements the same GCC extended `asm` syntax, constraints, modifiers,
clobbers, and `volatile` rules, and the instructions are the same. Every
example and solution is the **same C file** on both systems; only the Makefile
differs.

```console
$ cd apple-silicon/29-inline-assembly/examples && make
$ ./constraints
x = 15 after += 5
0x12345678 rotated right by 8 = 0x78123456
rbit(1) = 0x8000000000000000
swap: a = 2, b = 1
```

## Differences

**The timer frequency.** `cntfrq_el0` is whatever the operating system
reports:

```console
$ ./counter
timer frequency: 1000000000 Hz
the loop took more than 0 ticks: yes
```

On recent macOS versions and Apple chips it reads 1 GHz; the Linux container
on the same Mac reports 24 MHz. Always read `cntfrq_el0` rather than assuming
a value. (Apple also offers `mach_absolute_time()` as the supported C API for
the same clock.)

**Symbols in templates.** If a template refers to a global symbol by name
(rare; prefer passing its address as an operand), on macOS it needs the
underscore and `@PAGE`/`@PAGEOFF`, so the template is not portable. Operands
avoid this.

**`x18`.** Never name it in a template or a clobber list; macOS may change it
at any time.

**`objdump` names `main` as `_main`:**

```console
$ objdump -d volatile | grep -A12 '<_main>:'
```

## Exercises

Do the [main lesson's exercises](../../lessons/29-inline-assembly/exercises.md)
with the same C files. The answers are the same. In 29.6, Clang on Apple
Silicon targets ARMv8.5 by default, so `__atomic_fetch_add` already compiles to
a single `ldaddal`. macOS solutions are in [solutions/](solutions/).
