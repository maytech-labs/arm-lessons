// ex4.s - Exercise 03.4: instructions whose encodings you predicted (macOS). Exits with status 42.
//
// Build:  make
// Look:   objdump -d ex4
// Expected encodings (middle column of objdump):
//     mov x3, #42    d2800543
//     mov x0, #43    d2800560
//     mov w1, #42    52800541
//     mov x0, #42    d2800540
// Exit status (echo $?): 42

    .global _main
    .text
    .p2align 2
_main:
    mov x3, #42                 // register 3 in bits 0-4: ...43
    mov x0, #43                 // 43 << 5 = 0x560: ...560
    mov w1, #42                 // bit 31 (the "64-bit" bit) is 0: 5... instead of d...
    mov x0, #42                 // exit status 42
    mov x16, #1                 // macOS system call number for exit
    svc #0x80                   // exit
