// signedness.s - the same bits compared as signed and as unsigned.
//
// C:      long a = -1, b = 1;                 // a is 0xffffffffffffffff
//         long r = 0;
//         if (a < b) r += 1;                  // signed:   -1 < 1, true
//         if ((unsigned long)a < (unsigned long)b)
//             r += 2;                         // unsigned: 18446744073709551615 < 1, false
//         return r;
// Build:  make
// Run:    ./signedness; echo $?
// Expect: exit status 1

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #-1                 // a = -1 (all 64 bits set)
    mov x2, #1                  // b = 1
    mov x0, #0                  // r = 0

    cmp x1, x2                  // one compare...
    b.ge skip_signed            // signed: NOT (a < b) is (a >= b)
    add x0, x0, #1              // r += 1
skip_signed:
    cmp x1, x2                  // ...the same compare again (add changed nothing,
                                //   but being explicit is clearer)
    b.hs skip_unsigned          // unsigned: NOT (a < b) is (a >= b) = hs
    add x0, x0, #2              // r += 2
skip_unsigned:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(r)
