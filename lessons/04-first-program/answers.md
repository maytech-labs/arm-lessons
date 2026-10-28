# Lesson 04 answers

Programs: [ex1.s](linux/solutions/ex1.s), [ex3.s](linux/solutions/ex3.s), [ex6.s](linux/solutions/ex6.s).

## 04.2

The shell sees N mod 256.

1. `0`
2. `255`
3. `0` (256 = 1 0000 0000; the low 8 bits are all zero)
4. `1`
5. `232` (1000 = 3 x 256 + 232)
6. `0`

## 04.4

```asm
    .global _start      // directive: export _start
    .text               // directive: code section
    .p2align 2          // directive: align to 4 bytes
// the answer...        // comment
_start:                 // label
    mov x1, #20         // instruction: x1 = 20
    mov x2, x1          // instruction: x2 = x1 = 20
    mov x0, x2          // instruction: x0 = x2 = 20
    mov x1, #30         // instruction: x1 = 30 (too late to matter)
    mov x8, #93         // instruction: x8 = 93
    svc #0              // instruction: system call exit(x0)
```

Exit status: **20**. Changing `x1` afterwards does not change `x0`: `mov`
copies a value at that moment; it does not link the registers together.

## 04.5

1. `T`: a global symbol in the text section.
2. `nm` shows a lowercase `t` (local). `ld` prints
   `warning: cannot find entry symbol _start; defaulting to 0000000000400078`.
   The program still exits with 42, by luck: the address `ld` defaulted to
   happens to be the start of `.text`, which is our first instruction.
3. In the `.o`, `_start` is at `0`; in the executable it is at an address like
   `0x400078`. The object file is not placed in memory yet; the linker chose
   the final address.
4. 12 bytes (`0xc`): three instructions of 4 bytes.

## 04.7

Exact wording depends on your assembler version; with GNU `as` you see
messages like:

1. `Error: comma expected between operands at operand 2`
2. `Error: unknown mnemonic 'move'`
3. `Error: unknown mnemonic '_start'`: without a colon, the assembler
   thinks the line is an instruction.
4. `Error: operand 1 must be an integer register`: in this position, register
   number 31 is spelled `xzr` or `sp`, never `x31`.
5. `Illegal instruction`, exit status 132 = 128 + 4: killed by signal 4,
   `SIGILL`. The CPU ran past the end of the code.
