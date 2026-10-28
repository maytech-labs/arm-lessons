// overflow.s - a buffer overflow: strcpy into a buffer that is too small.
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

    .section .rodata
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
    adrp    x0, fmt_both
    add     x0, x0, :lo12:fmt_both
    adrp    x1, name
    add     x1, x1, :lo12:name
    adrp    x2, secret
    add     x2, x2, :lo12:secret
    bl      printf
    ldp     x29, x30, [sp], #16
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, fmt_secret
    add     x0, x0, :lo12:fmt_secret
    adrp    x1, secret
    add     x1, x1, :lo12:secret
    bl      printf

    adrp    x0, name                // strcpy(name, "Bartholomew"): overflow!
    add     x0, x0, :lo12:name
    adrp    x1, long_name
    add     x1, x1, :lo12:long_name
    bl      strcpy
    bl      show_both

    adrp    x0, name                // the safe way
    add     x0, x0, :lo12:name
    adrp    x1, long_name
    add     x1, x1, :lo12:long_name
    mov     x2, #8                  // sizeof name
    bl      safe_copy
    adrp    x0, secret              // repair the secret
    add     x0, x0, :lo12:secret
    adrp    x1, secret_text
    add     x1, x1, :lo12:secret_text
    bl      strcpy
    bl      show_both

    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret
