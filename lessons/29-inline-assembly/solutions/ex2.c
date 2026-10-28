// ex2.c - Exercise 29.2: the high 64 bits of a product, with inline asm,
// checked against unsigned __int128.
//
// Build:  make
// Run:    ./ex2
// Expected output:
//   mulhi(0xffffffffffffffff, 0xffffffffffffffff) = 0xfffffffffffffffe (int128: 0xfffffffffffffffe)
//   mulhi(0x100000000, 0x100000000) = 0x1 (int128: 0x1)
//   mulhi(0x3039, 0x10932) = 0x0 (int128: 0x0)
#include <stdio.h>

static unsigned long mulhi(unsigned long a, unsigned long b) {
    unsigned long hi;
    asm("umulh %0, %1, %2" : "=r"(hi) : "r"(a), "r"(b));
    return hi;
}

static void show(unsigned long a, unsigned long b) {
    unsigned long ref = (unsigned long)(((unsigned __int128)a * b) >> 64);
    printf("mulhi(0x%lx, 0x%lx) = 0x%lx (int128: 0x%lx)\n", a, b, mulhi(a, b), ref);
}

int main(void) {
    show(0xffffffffffffffffUL, 0xffffffffffffffffUL);
    show(0x100000000UL, 0x100000000UL);
    show(12345, 67890);
    return 0;
}
