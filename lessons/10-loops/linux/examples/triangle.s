// triangle.s - nested loops: row r has r stars.
//
// C:      for (long r = 1; r <= 5; r++) {
//             for (long c = 0; c < r; c++) {
//                 write(1, "*", 1);
//             }
//             write(1, "\n", 1);
//         }
// Build:  make
// Run:    ./triangle
// Expect: prints
//             *
//             **
//             ***
//             ****
//             *****
//         exit status 0

    .global _start              // make _start visible to the linker

    .data                       // data section
star:
    .ascii "*"                  // 1-byte buffer: '*'
newline:
    .ascii "\n"                 // 1-byte buffer: '\n'

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x19, #1                 // r = 1          (outer counter)
outer:
    cmp x19, #5                 // r <= 5 ?
    b.gt outer_end              //   no: all rows done
    mov x20, #0                 // c = 0          (inner counter, reset every row)
inner:
    cmp x20, x19                // c < r ?
    b.ge inner_end              //   no: this row is done
    mov x0, #1                  // fd 1
    adrp x1, star               // x1 = address of star
    add x1, x1, :lo12:star      //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, "*", 1)
    add x20, x20, #1            // c++
    b inner                     // next star
inner_end:
    mov x0, #1                  // fd 1
    adrp x1, newline            // x1 = address of newline
    add x1, x1, :lo12:newline   //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x8, #64                 // 64 = write
    svc #0                      // write(1, "\n", 1)
    add x19, x19, #1            // r++
    b outer                     // next row
outer_end:
    mov x0, #0                  // exit status 0
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(0)
