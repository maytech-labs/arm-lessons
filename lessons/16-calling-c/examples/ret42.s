// ret42.s - the smallest program that uses the C library.
//
// There is no _start here. The C runtime that gcc links in provides _start,
// sets things up, calls our main, and passes main's return value to exit().
//
// Build: make ret42          (or: gcc -g -o ret42 ret42.s)
// Run:   ./ret42; echo $?
// Expected exit status: 42

    .text
    .global main            // the C runtime looks for a global symbol "main"
    .p2align 2
main:
    mov     w0, #42         // int main(void) returns an int, in w0
    ret                     // return to the C runtime, which calls exit(42)
