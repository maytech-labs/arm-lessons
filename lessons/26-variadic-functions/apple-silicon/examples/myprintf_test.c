// myprintf_test.c - C test driver for myprintf.s. Each line is printed once
// by myprintf and once by the real printf, so you can compare them.
//
// Build and run:
//     make myprintf
//     ./myprintf
// Expected output:
//     int 42, negative -7, hex ff, char A, string hi, 100%
//     int 42, negative -7, hex ff, char A, string hi, 100%
//     myprintf returned 53, printf returned 53
//     1 2 3 4 5 6 7 8 9 10
//     1 2 3 4 5 6 7 8 9 10
//     -2147483648 2147483647 ffffffff
//     -2147483648 2147483647 ffffffff
//     unknown %q stays, (null) string
#include <limits.h>
#include <stdio.h>

int myprintf(const char *fmt, ...);   // implemented in myprintf.s

int main(void) {
    const char *f1 = "int %d, negative %d, hex %x, char %c, string %s, 100%%\n";
    int a = myprintf(f1, 42, -7, 255, 'A', "hi");
    int b = printf(f1, 42, -7, 255, 'A', "hi");
    printf("myprintf returned %d, printf returned %d\n", a, b);

    // Ten variadic arguments: seven arrive in x1-x7, three on the stack.
    const char *f2 = "%d %d %d %d %d %d %d %d %d %d\n";
    myprintf(f2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    printf(f2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    const char *f3 = "%d %d %x\n";
    myprintf(f3, INT_MIN, INT_MAX, -1);
    printf(f3, INT_MIN, INT_MAX, -1);

    // Only myprintf here: a NULL %s is undefined behaviour for the real printf.
    myprintf("unknown %q stays, %s string\n", (char *)0);
    return 0;
}
