// ex8_main.c - Exercise 27.8: times count_primes_asm (ex8.s) against the
// same functions in C.
//
// Build: make            (gcc -O2, linked with ex8.s)
// Run:   ./ex8
// See ex8.s for the expected output. The counts must match; times vary.
#include <stdio.h>
#include <time.h>

#define N    200000
#define REPS 10

int count_primes_asm(int n);

static int is_prime_c(int k) {
    if (k < 2) return 0;
    for (int d = 2; d * d <= k; d++)
        if (k % d == 0) return 0;
    return 1;
}

__attribute__((noinline))
int count_primes_c(int n) {
    int count = 0;
    for (int k = 2; k < n; k++)
        count += is_prime_c(k);
    return count;
}

static double seconds(clock_t start) {
    return (double)(clock() - start) / CLOCKS_PER_SEC;
}

int main(void) {
    // volatile: the compiler must really read n before every call, so it
    // cannot prove that every call has the same argument and make just one.
    volatile int n = N;
    volatile int sink;
    clock_t start;

    start = clock();
    for (int r = 0; r < REPS; r++)
        sink = count_primes_asm(n);
    printf("asm:     count = %d   time = %.3f s\n", sink, seconds(start));

    start = clock();
    for (int r = 0; r < REPS; r++)
        sink = count_primes_c(n);
    printf("C -O2:   count = %d   time = %.3f s\n", sink, seconds(start));
    return 0;
}
