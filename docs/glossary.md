# Glossary

**AAPCS64** - Procedure Call Standard for the Arm 64-bit Architecture. The rules for
which registers carry arguments, which must be preserved, and how the stack is used.

**ABI** - Application Binary Interface. Everything two pieces of compiled code must
agree on to work together: calling convention, data layout, system call interface.

**Addressing mode** - The way a load or store computes the memory address, e.g.
`[x1, #8]` or `[x1], #8`.

**Alignment** - An address is N-aligned when it is a multiple of N. Data is usually
aligned to its size; `sp` must always be 16-aligned.

**Assembler** - The program that turns assembly text into machine code in an object file.

**Assembler directive** - A line starting with `.` that instructs the assembler
rather than producing an instruction: `.global`, `.text`, `.asciz`.

**Big-endian / little-endian** - Byte order of multi-byte values in memory. AArch64
on Linux and macOS is little-endian: the least significant byte is at the lowest address.

**Bit, byte, halfword, word, doubleword** - 1 bit; 8 bits; 16 bits; 32 bits; 64 bits.
In Arm terminology a "word" is 32 bits.

**Callee-saved register** - A register a function must restore before returning
if it changes it (`x19`-`x28`, `x29`, `x30`, `sp`, low halves of `v8`-`v15`).

**Caller-saved register** - A register any called function may overwrite; the caller
must save it if it needs the value after the call (`x0`-`x17`).

**Carry flag (C)** - Set when an unsigned addition overflows, or when a subtraction
does *not* borrow.

**Condition flags (NZCV)** - Four bits set by `cmp`, `adds`, etc.: Negative, Zero,
Carry, oVerflow. Conditional branches read them.

**ELF** - Executable and Linkable Format, the object and executable format on Linux.

**Epilogue** - The instructions at the end of a function that restore saved
registers and the stack, then return.

**Exit status** - The small integer (0-255 as seen by the shell) a process returns
when it ends. Read it with `echo $?`.

**Frame pointer (`x29`)** - Points at the current function's saved frame record,
forming a chain debuggers follow to show a backtrace.

**GOT** - Global Offset Table. A table of addresses filled in at load time, used to
reach symbols defined in shared libraries.

**Immediate** - A constant written into the instruction itself, like `#42`.

**Label** - A name for an address in the program, written `name:`.

**Leaf function** - A function that calls no other functions, and so need not save `x30`.

**Link register (`x30`, `lr`)** - Holds the return address after `bl`.

**Linker** - Combines object files and libraries into an executable, resolving
symbol names into addresses.

**Mach-O** - The object and executable format on macOS.

**Mnemonic** - The human-readable name of an instruction, e.g. `add`.

**Object file** - Assembler output (`.o`): machine code plus symbol and relocation
information, not yet runnable.

**Overflow flag (V)** - Set when a signed result does not fit, e.g. adding two large
positive numbers gives a negative one.

**Program counter (PC)** - Address of the instruction being executed.

**Prologue** - The instructions at the start of a function that save registers and
set up its stack frame.

**Register** - A small, fast storage slot inside the CPU. AArch64 has 31
general-purpose 64-bit registers plus `sp` and the zero register.

**Relocation** - A note in an object file saying "fill in the address of symbol X
here", resolved by the linker.

**Section** - A named region of an object file: `.text` for code, `.data` for
initialised variables, `.bss` for zeroed variables, `.rodata` for constants.

**Sign extension** - Widening a signed value by copying its top bit into the new
upper bits, so `-1` stays `-1`.

**Stack** - Memory that grows downward from a high address, used for return
addresses, saved registers, and local variables.

**Symbol** - A name the assembler and linker track: a label, function, or variable.

**System call** - A request to the operating system kernel, made with `svc`.

**Two's complement** - The standard representation of signed integers: negate by
inverting all bits and adding one.

**Zero extension** - Widening a value by filling the new upper bits with zeros.

**Zero register (`xzr`/`wzr`)** - Always reads as 0; writing to it discards the result.
