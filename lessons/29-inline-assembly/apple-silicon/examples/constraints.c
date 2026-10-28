// constraints.c - read-write operands, immediates, w registers, early clobber.
//
// Build:  make
// Run:    ./constraints
// Expected output:
//   x = 15 after += 5
//   0x12345678 rotated right by 8 = 0x78123456
//   rbit(1) = 0x8000000000000000
//   swap: a = 2, b = 1
#include <stdio.h>

int main(void) {
    long x = 10;
    asm("add %0, %0, #5" : "+r"(x));            // "+r": read AND written

    unsigned int v = 0x12345678, r;
    asm("ror %w0, %w1, %2"                      // %w0: the 32-bit name of operand 0
        : "=r"(r)
        : "r"(v), "i"(8));                      // "i": an immediate constant
    printf("x = %ld after += 5\n", x);
    printf("0x%x rotated right by 8 = 0x%x\n", v, r);

    unsigned long one = 1, rev;
    asm("rbit %0, %1" : "=r"(rev) : "r"(one));  // no C operator for this one
    printf("rbit(1) = 0x%016lx\n", rev);

    long a = 1, b = 2, t;
    asm("mov %0, %1\n\t"                        // several instructions: separate with \n\t
        "mov %1, %2\n\t"
        "mov %2, %0"
        : "=&r"(t), "+r"(a), "+r"(b));          // "&": t is written before a, b are read
    printf("swap: a = %ld, b = %ld\n", a, b);
    return 0;
}
