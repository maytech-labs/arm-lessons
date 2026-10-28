# Further reading

## Official specifications

- **Arm Architecture Reference Manual for A-profile** (the "ARM ARM"): the
  definitive description of every instruction. Huge; use it to look things up.
  developer.arm.com, document DDI 0487.
- **Procedure Call Standard for the Arm 64-bit Architecture (AAPCS64)**: the
  calling convention. github.com/ARM-software/abi-aa
- **Writing ARM64 code for Apple platforms**: Apple's deviations from AAPCS64.
  developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms
- **Linux system call table for arm64**: `include/uapi/asm-generic/unistd.h` in
  the kernel source, or the `syscall(2)` man page.
- **GNU as manual**, AArch64-dependent features section.
  sourceware.org/binutils/docs/as/

## Tools

- Compiler Explorer, godbolt.org: compile C and see the assembly, live.
- `man gdb`, `help` inside `lldb`.

## Books

- *Programming with 64-Bit ARM Assembly Language*, Stephen Smith.
- *Computer Organization and Design, ARM Edition*, Patterson and Hennessy.
- *The C Programming Language*, Kernighan and Ritchie: the C refresher.
