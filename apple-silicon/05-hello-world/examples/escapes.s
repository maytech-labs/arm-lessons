// escapes.s - escape sequences inside .ascii strings (macOS).
//
// Build:  make
// Run:    ./escapes
// Expected output:
//   name:	"asm"
//   path:	C:\temp
//   hex:	ABC
// Exit status (echo $?): 0

    .global _main

    .section __TEXT,__const
msg:
    .ascii "name:\t\"asm\"\n"       // \t = tab, \" = a double quote
    .ascii "path:\tC:\\temp\n"      // \\ = one backslash
    .ascii "hex:\t\x41\x42\x43\n"   // \x41 = the byte 0x41 = 'A'
    .equ msg_len, . - msg           // three .ascii lines, one message

    .text
    .p2align 2
_main:
    mov x0, #1
    adrp x1, msg@PAGE
    add x1, x1, msg@PAGEOFF
    mov x2, #msg_len
    mov x16, #4                     // write(1, msg, msg_len)
    svc #0x80

    mov x0, #0
    mov x16, #1                     // exit(0)
    svc #0x80
