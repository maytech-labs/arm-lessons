// ex4.s - Exercise 10.4: print a rectangle of '#', 4 rows by 6 columns (macOS).
//
// C:      for (long r = 0; r < 4; r++) {
//             for (long c = 0; c < 6; c++) write(1, "#", 1);
//             write(1, "\n", 1);
//         }
// Build:  make
// Run:    ./ex4
// Expect: prints four lines of ###### and exit status 0

    .global _main               // make _main visible to the linker

    .data                       // data section
hash:
    .ascii "#"                  // 1-byte buffer: '#'
newline:
    .ascii "\n"                 // 1-byte buffer: '\n'

    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x19, #4                 // rows left (counting down)
row:
    mov x20, #6                 // columns left in this row
col:
    mov x0, #1                  // fd 1
    adrp x1, hash@PAGE          // x1 = address of hash
    add x1, x1, hash@PAGEOFF    //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(1, "#", 1)
    subs x20, x20, #1           // one column fewer
    b.ne col                    // more columns: again
    mov x0, #1                  // fd 1
    adrp x1, newline@PAGE       // x1 = address of newline
    add x1, x1, newline@PAGEOFF //   (low 12 bits)
    mov x2, #1                  // 1 byte
    mov x16, #4                 // 4 = write
    svc #0x80                   // write(1, "\n", 1)
    subs x19, x19, #1           // one row fewer
    b.ne row                    // more rows: again
    mov x0, #0                  // exit status 0
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(0)
