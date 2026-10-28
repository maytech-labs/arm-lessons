// funcs.c - small C functions to feed to the compiler.
//
// This file has no main: it is not a program. Look at what the compiler
// makes of it at different optimization levels:
//
//     gcc -O0 -S -o - funcs.c
//     gcc -O2 -S -o - funcs.c
//
// Each function shows one idiom from the lesson.

// 1. Division by a constant: becomes a multiply, not a udiv.
unsigned div10(unsigned x) {
    return x / 10;
}

// 2. Signed division by a constant: same trick plus a sign fix-up.
int div7(int x) {
    return x / 7;
}

// 3. A ternary: becomes cmp + csel, no branch.
int max(int a, int b) {
    return a > b ? a : b;
}

// 4. A counting loop: rotated so the test is at the bottom.
long sum_array(const int *a, long n) {
    long s = 0;
    for (long i = 0; i < n; i++)
        s += a[i];
    return s;
}

// 5. Strength reduction: i * 12 becomes "add 12 each time round".
void fill_multiples(int *a, int n) {
    for (int i = 0; i < n; i++)
        a[i] = i * 12;
}

// 6. Inlining: square() disappears into its caller.
static int square(int x) {
    return x * x;
}
int sum_of_squares(int a, int b) {
    return square(a) + square(b);
}

// 7. A tail call: "return f(...)" becomes a plain branch.
int helper(int x);
int call_helper(int x) {
    return helper(x + 1);
}

// 8. Values live across calls: callee-saved registers, saved with stp/ldp.
long twice(long x);
long combine(long a, long b) {
    long x = twice(a);
    long y = twice(b);
    return x + y + a;
}
