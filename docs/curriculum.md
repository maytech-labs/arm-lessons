# Curriculum

The full syllabus. Each lesson lives in `lessons/NN-slug/`, with its programs in
two flavors: `linux/` (Linux AArch64) and `apple-silicon/` (macOS arm64). Do them
in order: every lesson assumes everything before it.

The goal: by the end you can take any C program that uses the core language and
the standard library, and write it by hand in AArch64 assembly, and you
understand *why* each instruction is there.

## Part 1: Foundations

| # | Lesson | You will learn |
|---|--------|----------------|
| 00 | `00-setup` | Install tools, build and run a program, how the lessons work |
| 01 | `01-binary-and-hex` | Bits, bytes, binary, hexadecimal, converting by hand, unsigned addition |
| 02 | `02-signed-numbers` | Two's complement, negation, overflow vs carry, sign extension, byte order |
| 03 | `03-the-machine` | CPU, registers, memory as a byte array, instructions as numbers, assembler and linker |
| 04 | `04-first-program` | `_start`, directives, labels, the `exit` system call, exit status |
| 05 | `05-hello-world` | The `write` system call, data sections, strings, loading addresses |
| 06 | `06-debugger` | Stepping instructions, reading registers and memory in gdb / lldb |

## Part 2: Computing

| # | Lesson | You will learn |
|---|--------|----------------|
| 07 | `07-arithmetic` | `mov`, `movz`/`movk`, immediates, `add`, `sub`, `mul`, `udiv`/`sdiv`, remainder |
| 08 | `08-bitwise` | `and`, `orr`, `eor`, `mvn`, `bic`, shifts, shifted operands, bit fields, masks |
| 09 | `09-branches` | Condition flags, `cmp`, `b.cond`, signed vs unsigned conditions, `if`/`else` |
| 10 | `10-loops` | `while`, `do`, `for`, `break`/`continue`, nested loops, `csel` and branchless code |

## Part 3: Memory and functions

| # | Lesson | You will learn |
|---|--------|----------------|
| 11 | `11-memory` | Loads and stores of every size, addressing modes, alignment, `.bss` |
| 12 | `12-arrays-and-pointers` | Indexing, pointer arithmetic and scaling, 2D arrays, sorting |
| 13 | `13-the-stack` | `sp`, 16-byte alignment, pushing and popping with `stp`/`ldp`, locals |
| 14 | `14-functions` | `bl`, `ret`, the link register, frames, prologue and epilogue |
| 15 | `15-calling-convention` | AAPCS64: argument and return registers, who saves what, recursion |
| 16 | `16-calling-c` | Calling libc from assembly, calling assembly from C, reading `gcc -S` |

## Part 4: C's data model

| # | Lesson | You will learn |
|---|--------|----------------|
| 17 | `17-strings` | C strings, `strlen`/`strcmp`/`strcpy`, number-to-text and text-to-number |
| 18 | `18-integer-types` | `char`/`short`/`int`/`long`, casts, promotions, `w` vs `x`, 128-bit math |
| 19 | `19-structs-and-unions` | Layout, padding, alignment, arrays of structs, passing and returning structs |
| 20 | `20-symbols-and-sections` | Globals, `static`, `const`, multiple source files, linking, macros, Makefiles |
| 21 | `21-the-heap` | `malloc`/`calloc`/`realloc`/`free`, growable arrays, memory bugs |
| 22 | `22-linked-structures` | Linked lists, stacks, queues, binary search trees |

## Part 5: The rest of C, and beyond

| # | Lesson | You will learn |
|---|--------|----------------|
| 23 | `23-floating-point` | FP/SIMD registers, `float`/`double` arithmetic, conversions, comparisons |
| 24 | `24-function-pointers` | `blr`, callbacks, `qsort`, jump tables for `switch`, dispatch tables |
| 25 | `25-io-and-args` | `argc`/`argv`/`envp`, files, `errno`, buffered vs unbuffered I/O |
| 26 | `26-variadic-functions` | Calling and writing variadic functions, `va_list` |
| 27 | `27-compiler-output` | Reading optimized compiler output, a method for translating C by hand, pointer authentication and branch protection (PAC/BTI) |
| 28 | `28-threads-and-atomics` | `pthread`, data races, exclusive loads/stores, atomics, memory ordering |
| 29 | `29-inline-assembly` | `asm volatile` in C: operands, constraints, clobbers, when to use it |
| 30 | `30-simd-neon` | Vector registers and lanes, NEON arithmetic on arrays, loads/stores of vectors |
| 31 | `31-capstone` | Larger projects that combine everything |

## What is deliberately out of scope

- Writing an operating system, bootloader, or kernel code (exception levels, MMU).
- NEON/SIMD beyond the introduction in lesson 30 (intrinsics, auto-vectorization, SVE).
- 32-bit ARM (A32/Thumb) and microcontrollers.
- Libraries built on top of C (graphics, networking frameworks, game engines).
- Instruction-level performance tuning beyond the basics in lesson 27.

See [decisions/0008-curriculum-scope.md](decisions/0008-curriculum-scope.md) and
[decisions/0010-add-inline-asm-neon-pac.md](decisions/0010-add-inline-asm-neon-pac.md).
