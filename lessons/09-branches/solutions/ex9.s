// ex9.s - Exercise 09.9: detect signed overflow (V) and unsigned carry (C).
//
// C (gcc builtins):
//         long r = 0, s;  unsigned long u;
//         if (__builtin_add_overflow(0x7fffffffffffffffL, 1L, &s)) r += 1;
//         if (__builtin_add_overflow(0xffffffffffffffffUL, 1UL, &u)) r += 2;
//         return r;
// Build:  make
// Run:    ./ex9; echo $?
// Expect: exit status 3

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x0, #0                  // r = 0

    mov x1, #0x7fffffffffffffff // the largest signed long (a logical immediate)
    adds x2, x1, #1             // add and set flags: wraps to the smallest long
    b.vc no_signed_overflow     // V clear: no signed overflow, skip
    add x0, x0, #1              // r += 1
no_signed_overflow:
    mov x1, #-1                 // the largest unsigned long, 0xffffffffffffffff
    adds x2, x1, #1             // wraps to 0 and carries out of bit 63
    b.cc no_carry               // C clear: no unsigned overflow, skip
    add x0, x0, #2              // r += 2
no_carry:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(r)
