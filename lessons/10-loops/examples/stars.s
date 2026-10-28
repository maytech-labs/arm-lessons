// stars.s - print a row of stars, one write system call per character.
//
// C:      for (long i = 0; i < 10; i++) {
//             write(1, "*", 1);
//         }
//         write(1, "\n", 1);
// Build:  make
// Run:    ./stars
// Expect: prints ********** (10 stars) and a newline, exit status 0
//
// The system call puts its result in x0, so x0 cannot hold our counter.
// We keep the counter in x19, which a system call does not change.

    .global _start              // make _start visible to the linker

    .data                       // data section
star:
    .ascii "*"                  // a 1-byte buffer holding '*'
newline:
    .ascii "\n"                 // a 1-byte buffer holding '\n'

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x19, #0                 // i = 0
loop:
    cmp x19, #10                // i < 10 ?
    b.ge end_loop               //   no: leave
    mov x0, #1                  // fd 1 = standard output
    adrp x1, star               // x1 = address of star
    add x1, x1, :lo12:star      //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, "*", 1): x0 is overwritten here
    add x19, x19, #1            // i++
    b loop                      // again
end_loop:
    mov x0, #1                  // fd 1
    adrp x1, newline            // x1 = address of newline
    add x1, x1, :lo12:newline   //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, "\n", 1)

    mov x0, #0                  // exit status 0
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(0)
