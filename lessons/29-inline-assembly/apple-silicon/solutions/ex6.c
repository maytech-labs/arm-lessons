// ex6.c - Exercise 29.6: an atomic increment written with inline asm,
// hammered by four threads.
//
// Build:  make
// Run:    ./ex6
// Expected output:
//   counter = 4000000
#include <pthread.h>
#include <stdio.h>

static long counter;

static void atomic_inc(long *p) {
    long tmp;
    int fail;
    asm volatile("1: ldaxr %0, %2\n\t"      // load-acquire exclusive
                 "add %0, %0, #1\n\t"
                 "stlxr %w1, %0, %2\n\t"    // store-release exclusive; %w1 = 0 if it worked
                 "cbnz %w1, 1b"             // someone else got in: try again
                 : "=&r"(tmp), "=&r"(fail), "+Q"(*p)  // "Q": a memory operand [reg]
                 :
                 : "memory");
}

static void *worker(void *arg) {
    (void)arg;
    for (int i = 0; i < 1000000; i++) atomic_inc(&counter);
    return NULL;
}

int main(void) {
    pthread_t t[4];
    for (int i = 0; i < 4; i++) pthread_create(&t[i], NULL, worker, NULL);
    for (int i = 0; i < 4; i++) pthread_join(t[i], NULL);
    printf("counter = %ld\n", counter);
    return 0;
}
