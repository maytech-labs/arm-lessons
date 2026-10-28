// square.c - a tiny C file for reading compiler output. It is not built by make.
//
// See the assembly gcc writes for it:
//     gcc -S -O0 -o - square.c
//     gcc -S -O2 -o - square.c

int square(int x) {
    return x * x;
}

int sum_of_squares(int a, int b) {
    return square(a) + square(b);
}
