// clobbers.c - telling the compiler what else the asm changes.
//
//   "cc"      the condition flags
//   "memory"  memory the compiler cannot see in the operands
//   "x9"...   any register used as scratch
//
// Build:  make
// Run:    ./clobbers
// Expected output:
//   add_overflows(INT64_MAX, 1) = 1
//   add_overflows(40, 2) = 0
//   zeroed 4 longs: 0 0 0 0
#include <stdio.h>
#include <stdint.h>

static int add_overflows(long a, long b) {
    int v;
    asm("adds %1, %1, %2\n\t"   // changes the flags...
        "cset %w0, vs"
        : "=r"(v), "+r"(a)
        : "r"(b)
        : "cc");                // ...so say so
    return v;
}

static void zero4(long *p) {
    asm volatile("stp xzr, xzr, [%0]\n\t"
                 "stp xzr, xzr, [%0, #16]"
                 :                          // no outputs
                 : "r"(p)
                 : "memory");               // it writes memory through p
}

int main(void) {
    printf("add_overflows(INT64_MAX, 1) = %d\n", add_overflows(INT64_MAX, 1));
    printf("add_overflows(40, 2) = %d\n", add_overflows(40, 2));
    long a[4] = {1, 2, 3, 4};
    zero4(a);
    printf("zeroed 4 longs: %ld %ld %ld %ld\n", a[0], a[1], a[2], a[3]);
    return 0;
}
