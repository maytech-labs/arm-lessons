// c11.c - C11 atomics, to compare with the instructions the compiler picks.
//
// Build: make c11            (compiled with -O2)
// Run:   ./c11
// Expected output:
//     after two bumps: 2
//     cas 2->10: 1, counter = 10
//     cas 2->20: 0, counter = 10
//     after publish: 99
//
// Look at the code:
//     objdump -d c11 | less          (search for <bump>, <swap_if>, ...)
//     gcc -O2 -S c11.c -o -          (default: calls to __aarch64_* helpers)
//     gcc -O2 -march=armv8.1-a -S c11.c -o -   (single LSE instructions)
#include <stdatomic.h>
#include <stdio.h>

atomic_long counter;

// atomic_fetch_add: returns the old value. Default ordering is seq_cst.
__attribute__((noinline)) long bump(void) {
    return atomic_fetch_add(&counter, 1);
}

// If counter == expected, set it to desired and return 1; else return 0.
__attribute__((noinline)) int swap_if(long expected, long desired) {
    return atomic_compare_exchange_strong(&counter, &expected, desired);
}

__attribute__((noinline)) long peek(void) {
    return atomic_load_explicit(&counter, memory_order_acquire);
}

__attribute__((noinline)) void publish(long v) {
    atomic_store_explicit(&counter, v, memory_order_release);
}

int main(void) {
    int ok;
    bump();
    bump();
    printf("after two bumps: %ld\n", peek());
    ok = swap_if(2, 10);
    printf("cas 2->10: %d, counter = %ld\n", ok, peek());
    ok = swap_if(2, 20);
    printf("cas 2->20: %d, counter = %ld\n", ok, peek());
    publish(99);
    printf("after publish: %ld\n", peek());
    return 0;
}
