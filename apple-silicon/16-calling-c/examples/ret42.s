// ret42.s - the smallest program that uses the C library (macOS).
//
// The C runtime (dyld + libSystem) calls _main and passes its return value
// to exit().
//
// Build: make ret42          (or: clang -g -arch arm64 -o ret42 ret42.s)
// Run:   ./ret42; echo $?
// Expected exit status: 42

    .text
    .global _main           // C's "main" is "_main" in a Mach-O file
    .p2align 2
_main:
    mov     w0, #42         // int main(void) returns an int, in w0
    ret                     // back to the runtime, which calls exit(42)
