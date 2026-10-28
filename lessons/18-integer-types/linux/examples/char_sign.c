// char_sign.c - is plain char signed or unsigned on this platform?
// (A C program, because the answer is a property of the C ABI, not the CPU.)
//
// Build:  make
// Run:    ./char_sign
// Expected output on Linux AArch64:
//   (char)0xff = 255: char is unsigned
//   compiled as: ldrb (zero-extend)
#include <stdio.h>

char c = (char)0xff;

int main(void) {
    int i = c;                              // promote char to int
    printf("(char)0xff = %d: char is %s\n", i, i < 0 ? "signed" : "unsigned");
    printf("compiled as: %s\n", i < 0 ? "ldrsb (sign-extend)" : "ldrb (zero-extend)");
    return 0;
}
