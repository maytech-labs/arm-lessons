// volatile.c - without volatile, an asm with an unused result may be deleted.
//
// Build:  make            (built with -O2, so the optimiser is active)
// Run:    ./volatile
// Look:   objdump -d volatile | grep -A12 '<main>:'
//         The non-volatile asm whose result is unused has disappeared;
//         the volatile one is still there.
// Expected output:
//   done
#include <stdio.h>

int main(void) {
    long unused;
    asm("mov %0, #1111" : "=r"(unused));            // result never used: removed
    asm volatile("mov x9, #2222" ::: "x9");         // volatile: always kept
    puts("done");
    return 0;
}
