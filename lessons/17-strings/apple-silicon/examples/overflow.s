// overflow.s - a buffer overflow: strcpy into a buffer that is too small (macOS).
//
// C version:
//     char name[8];                 // room for 7 characters + '\0'
//     char secret[8] = "s3cr3t";    // happens to sit right after name
//     printf("secret = %s\n", secret);
//     strcpy(name, "Bartholomew");  // 12 bytes into an 8-byte buffer!
//     printf("name = %s, secret = %s\n", name, secret);
//     safe_copy(name, "Bartholomew", sizeof name);   // a bounded copy
//     strcpy(secret, "s3cr3t");
//     printf("name = %s, secret = %s\n", name, secret);
//
// Build: make overflow
// Run:   ./overflow
// Expected output:
//     secret = s3cr3t
//     name = Bartholomew, secret = mew
//     name = Barthol, secret = s3cr3t

    .data
name:
    .space  8                       // char name[8]
secret:
    .asciz  "s3cr3t"                // the very next bytes in memory
    .space  1                       // (pad secret to 8 bytes)

    .section __TEXT,__const
long_name:
    .asciz  "Bartholomew"
secret_text:
    .asciz  "s3cr3t"
fmt_secret:
    .asciz  "secret = %s\n"
fmt_both:
    .asciz  "name = %s, secret = %s\n"

    .text
    .p2align 2
// void safe_copy(char *dst, const char *src, size_t size)
// Copies at most size - 1 characters and always writes the '\0'.
safe_copy:
    cbz     x2, safe_done           // size 0: no room even for '\0'
safe_loop:
    subs    x2, x2, #1              // one byte of room used up
    b.eq    safe_end                // only the '\0' still fits
    ldrb    w3, [x1], #1
    strb    w3, [x0], #1
    cbnz    w3, safe_loop
    ret                             // copied the '\0' already
safe_end:
    strb    wzr, [x0]
safe_done:
    ret

// print name and secret
show_both:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, fmt_both@PAGE
    add     x0, x0, fmt_both@PAGEOFF
    adrp    x1, name@PAGE
    add     x1, x1, name@PAGEOFF
    adrp    x2, secret@PAGE
    add     x2, x2, secret@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    bl      _printf
    add     sp, sp, #16
    ldp     x29, x30, [sp], #16
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt_secret@PAGE
    add     x0, x0, fmt_secret@PAGEOFF
    adrp    x1, secret@PAGE
    add     x1, x1, secret@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    bl      _printf
    add     sp, sp, #16

    adrp    x0, name@PAGE           // strcpy(name, "Bartholomew"): overflow!
    add     x0, x0, name@PAGEOFF
    adrp    x1, long_name@PAGE
    add     x1, x1, long_name@PAGEOFF
    bl      _strcpy
    bl      show_both

    adrp    x0, name@PAGE           // the safe way
    add     x0, x0, name@PAGEOFF
    adrp    x1, long_name@PAGE
    add     x1, x1, long_name@PAGEOFF
    mov     x2, #8                  // sizeof name
    bl      safe_copy
    adrp    x0, secret@PAGE         // repair the secret
    add     x0, x0, secret@PAGEOFF
    adrp    x1, secret_text@PAGE
    add     x1, x1, secret_text@PAGEOFF
    bl      _strcpy
    bl      show_both

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
