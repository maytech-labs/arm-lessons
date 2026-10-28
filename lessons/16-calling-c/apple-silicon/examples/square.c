// square.c - a tiny C file for reading compiler output. It is not built by make.
//
// See the assembly clang writes for it:
//     clang -S -O0 -o - square.c
//     clang -S -O2 -o - square.c

int square(int x) {
    return x * x;
}

int sum_of_squares(int a, int b) {
    return square(a) + square(b);
}
