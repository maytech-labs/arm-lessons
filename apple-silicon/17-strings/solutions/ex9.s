// ex9.s - Exercise 17.9: my_strstr, find a substring (macOS).
//
// C version:
//     char *my_strstr(const char *hay, const char *needle) {
//         for (;; hay++) {
//             const char *h = hay, *n = needle;
//             while (*n && *h == *n) { h++; n++; }
//             if (*n == '\0') return (char *)hay;  // all of needle matched
//             if (*hay == '\0') return NULL;
//         }
//     }
//
// Build: make ex9
// Run:   ./ex9
// Expected output:
//     "needle": mine "needle in a haystack", libc "needle in a haystack"
//     "hay": mine "haystack", libc "haystack"
//     "": mine "a needle in a haystack", libc "a needle in a haystack"
//     "pin": mine (none), libc (none)
//     "stacks": mine (none), libc (none)

    .section __TEXT,__const
hay:
    .asciz  "a needle in a haystack"
fmt:
    .asciz  "\"%s\": mine %s, libc %s\n"
none:
    .asciz  "(none)"
n1:     .asciz  "needle"
n2:     .asciz  "hay"
n3:     .asciz  ""
n4:     .asciz  "pin"
n5:     .asciz  "stacks"
quoted_fmt:
    .asciz  "\"%s\""

    .data
    .p2align 3
needles:
    .quad   n1, n2, n3, n4, n5
needles_end:

    .bss
mine_buf:
    .space  64
libc_buf:
    .space  64

    .text
    .p2align 2
// char *my_strstr(const char *hay, const char *needle)
my_strstr:
strstr_outer:
    mov     x2, x0                  // h
    mov     x3, x1                  // n
strstr_inner:
    ldrb    w5, [x3]
    cbz     w5, strstr_found        // end of needle: match
    ldrb    w4, [x2]
    cmp     w4, w5
    b.ne    strstr_next
    add     x2, x2, #1
    add     x3, x3, #1
    b       strstr_inner
strstr_next:
    ldrb    w4, [x0]
    cbz     w4, strstr_missing
    add     x0, x0, #1
    b       strstr_outer
strstr_missing:
    mov     x0, #0
strstr_found:
    ret

// void quote(char *dst, const char *s): dst = "\"s\"" or "(none)" if s == NULL
quote:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    cbz     x1, quote_none
    mov     x2, x1
    adrp    x1, quoted_fmt@PAGE
    add     x1, x1, quoted_fmt@PAGEOFF
    sub     sp, sp, #16         // macOS: variadic arguments go on the stack
    str     x2, [sp, #0]
    bl      _sprintf                // like printf, but into dst
    add     sp, sp, #16
    b       quote_done
quote_none:
    adrp    x1, none@PAGE
    add     x1, x1, none@PAGEOFF
    bl      _strcpy
quote_done:
    ldp     x29, x30, [sp], #16
    ret

    .global _main
    .p2align 2
_main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    adrp    x19, needles@PAGE
    add     x19, x19, needles@PAGEOFF
    adrp    x20, needles_end@PAGE
    add     x20, x20, needles_end@PAGEOFF
    adrp    x22, hay@PAGE
    add     x22, x22, hay@PAGEOFF
loop:
    cmp     x19, x20
    b.hs    done
    ldr     x21, [x19], #8          // needle
    mov     x0, x22
    mov     x1, x21
    bl      my_strstr
    mov     x1, x0
    adrp    x0, mine_buf@PAGE
    add     x0, x0, mine_buf@PAGEOFF
    bl      quote
    mov     x0, x22
    mov     x1, x21
    bl      _strstr
    mov     x1, x0
    adrp    x0, libc_buf@PAGE
    add     x0, x0, libc_buf@PAGEOFF
    bl      quote
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    mov     x1, x21
    adrp    x2, mine_buf@PAGE
    add     x2, x2, mine_buf@PAGEOFF
    adrp    x3, libc_buf@PAGE
    add     x3, x3, libc_buf@PAGEOFF
    sub     sp, sp, #32         // macOS: variadic arguments go on the stack
    str     x1, [sp, #0]
    str     x2, [sp, #8]
    str     x3, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    b       loop
done:
    mov     w0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
