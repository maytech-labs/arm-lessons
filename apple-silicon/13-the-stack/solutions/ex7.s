// ex7.s - Exercise 13.7: check that the brackets in a line are balanced, (macOS)
// using the stack as a stack of expected closing brackets.
//
// Build:  make
// Run:    echo '{a[b(c)d]e}' | ./ex7; echo $?
//         echo '(]' | ./ex7; echo $?
// Expected output:
//   balanced      (exit status 0)
//   unbalanced    (exit status 1)
//
// Each opening bracket pushes its matching closer (16 bytes per push, to keep
// sp aligned). Each closer must equal the top of the stack. x20 counts the
// pushes so we can tell an empty stack and clean up at the end.

    .global _main
    .text
    .p2align 2

_main:
    sub sp, sp, #128            // char line[128] at the bottom of our area
    mov x0, #0
    mov x1, sp
    mov x2, #128
    mov x16, #3                 // n = read(0, line, 128)
    svc #0x80
    mov x19, x0                 // x19 = n
    mov x21, sp                 // x21 = line (sp will move as we push)
    mov x20, #0                 // depth = 0
    mov x9, #0                  // i = 0

scan:
    cmp x9, x19
    b.ge finished
    ldrb w10, [x21, x9]         // c = line[i]
    add x9, x9, #1

    mov w11, #')'
    cmp w10, #'('
    b.eq push
    mov w11, #']'
    cmp w10, #'['
    b.eq push
    mov w11, #'}'
    cmp w10, #'{'
    b.eq push

    cmp w10, #')'               // is it a closer?
    b.eq close
    cmp w10, #']'
    b.eq close
    cmp w10, #'}'
    b.eq close
    b scan                      // anything else: ignore

push:
    str x11, [sp, #-16]!        // push the closer we now expect
    add x20, x20, #1
    b scan

close:
    cbz x20, bad                // nothing open: unbalanced
    ldr x11, [sp], #16          // pop the expected closer
    sub x20, x20, #1
    cmp x11, x10
    b.ne bad                    // wrong kind of bracket
    b scan

finished:
    cbnz x20, bad               // something left open
    mov x22, #0                 // result: balanced
    b report
bad:
    mov x22, #1                 // result: unbalanced

report:
    mov sp, x21                 // pop anything still pushed, in one go
    adrp x1, msg_ok@PAGE
    add x1, x1, msg_ok@PAGEOFF
    mov x2, #msg_ok_len
    cbz x22, say
    adrp x1, msg_bad@PAGE
    add x1, x1, msg_bad@PAGEOFF
    mov x2, #msg_bad_len
say:
    mov x0, #1
    mov x16, #4
    svc #0x80

    add sp, sp, #128            // free line[]
    mov x0, x22
    mov x16, #1
    svc #0x80

    .section __TEXT,__const
msg_ok:
    .ascii "balanced\n"
    .equ msg_ok_len, . - msg_ok
msg_bad:
    .ascii "unbalanced\n"
    .equ msg_bad_len, . - msg_bad
