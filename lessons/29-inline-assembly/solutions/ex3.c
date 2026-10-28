// ex3.c - Exercise 29.3: rbit and rev with inline asm, checked against
// __builtin_bswap64 and a C loop.
//
// Build:  make
// Run:    ./ex3
// Expected output:
//   rev(0x0102030405060708) = 0x0807060504030201, bswap: 0x0807060504030201
//   rbit(0x1) = 0x8000000000000000, loop: 0x8000000000000000
//   rbit(0xf0) = 0x0f00000000000000, loop: 0x0f00000000000000
#include <stdio.h>

static unsigned long rev64(unsigned long x) {
    unsigned long r;
    asm("rev %0, %1" : "=r"(r) : "r"(x));
    return r;
}

static unsigned long rbit64(unsigned long x) {
    unsigned long r;
    asm("rbit %0, %1" : "=r"(r) : "r"(x));
    return r;
}

static unsigned long rbit_loop(unsigned long x) {
    unsigned long r = 0;
    for (int i = 0; i < 64; i++) { r = (r << 1) | (x & 1); x >>= 1; }
    return r;
}

int main(void) {
    unsigned long v = 0x0102030405060708UL;
    printf("rev(0x%016lx) = 0x%016lx, bswap: 0x%016lx\n", v, rev64(v), (unsigned long)__builtin_bswap64(v));
    printf("rbit(0x1) = 0x%016lx, loop: 0x%016lx\n", rbit64(1), rbit_loop(1));
    printf("rbit(0xf0) = 0x%016lx, loop: 0x%016lx\n", rbit64(0xf0), rbit_loop(0xf0));
    return 0;
}
