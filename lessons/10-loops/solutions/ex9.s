// ex9.s - Exercise 10.9: FizzBuzz in symbols for 1..15.
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

    .global _start              // make _start visible to the linker

    .data                       // data section
dot:    .ascii "."              // one byte each
fizz:   .ascii "F"              // one byte
buzz:   .ascii "B"              // one byte
both:   .ascii "X"              // one byte
newline: .ascii "\n"           // one byte

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    adrp x21, dot               // load the four addresses once, before the loop
    add x21, x21, :lo12:dot     // x21 = &"."
    adrp x22, fizz              // page of "fizz"
    add x22, x22, :lo12:fizz    // x22 = &"F"
    adrp x23, buzz              // page of "buzz"
    add x23, x23, :lo12:buzz    // x23 = &"B"
    adrp x24, both              // page of "both"
    add x24, x24, :lo12:both    // x24 = &"X"
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
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, p, 1)
    add x19, x19, #1            // i++
    b loop                      // again
done:
    mov x0, #1                  // fd 1
    adrp x1, newline            // x1 = address of newline
    add x1, x1, :lo12:newline   //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, "\n", 1)
    mov x0, #0                  // exit status 0
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(0)
