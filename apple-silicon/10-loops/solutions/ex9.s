// ex9.s - Exercise 10.9: FizzBuzz in symbols for 1..15 (macOS).
//
// C:      for (long i = 1; i <= 15; i++) {
//             const char *p = ".";
//             if (i % 3 == 0) p = "F";
//             if (i % 5 == 0) p = "B";
//             if (i % 15 == 0) p = "X";
//             write(1, p, 1);
//         }
//         write(1, "\n", 1);
// Build:  make
// Run:    ./ex9
// Expect: prints ..F.BF..FB.F..X and a newline, exit status 0
//
// The choice is made with csel on ADDRESSES: no branches inside the body.

    .global _main               // make _main visible to the linker

    .data                       // data section
dot:    .ascii "."              // one byte each
fizz:   .ascii "F"              // one byte
buzz:   .ascii "B"              // one byte
both:   .ascii "X"              // one byte
newline: .ascii "\n"           // one byte

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    adrp x21, dot@PAGE          // load the four addresses once, before the loop
    add x21, x21, dot@PAGEOFF   // x21 = &"."
    adrp x22, fizz@PAGE         // page of "fizz"
    add x22, x22, fizz@PAGEOFF  // x22 = &"F"
    adrp x23, buzz@PAGE         // page of "buzz"
    add x23, x23, buzz@PAGEOFF  // x23 = &"B"
    adrp x24, both@PAGE         // page of "both"
    add x24, x24, both@PAGEOFF  // x24 = &"X"
    mov x25, #3                 // divisors, kept in registers
    mov x26, #5                 //   5
    mov x27, #15                //   15
    mov x19, #1                 // i = 1
loop:
    cmp x19, #15                // i <= 15 ?
    b.gt done                   //   no: finished
    mov x1, x21                 // p = "."
    udiv x2, x19, x25           // i / 3
    msub x2, x2, x25, x19       // i % 3
    cmp x2, #0                  // == 0 ?
    csel x1, x22, x1, eq        // p = (i % 3 == 0) ? "F" : p
    udiv x2, x19, x26           // i / 5
    msub x2, x2, x26, x19       // i % 5
    cmp x2, #0                  // == 0 ?
    csel x1, x23, x1, eq        // p = (i % 5 == 0) ? "B" : p
    udiv x2, x19, x27           // i / 15
    msub x2, x2, x27, x19       // i % 15
    cmp x2, #0                  // == 0 ?
    csel x1, x24, x1, eq        // p = (i % 15 == 0) ? "X" : p
    mov x0, #1                  // fd 1
    mov x2, #1                  // 1 byte (x1 already holds p)
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(1, p, 1)
    add x19, x19, #1            // i++
    b loop                      // again
done:
    mov x0, #1                  // fd 1
    adrp x1, newline@PAGE       // x1 = address of newline
    add x1, x1, newline@PAGEOFF //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(1, "\n", 1)
    mov x0, #0                  // exit status 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
