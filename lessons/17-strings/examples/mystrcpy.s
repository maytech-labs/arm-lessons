// mystrcpy.s - our own strcpy and strcat, building a string in a buffer.
//
// C version:
//     char *my_strcpy(char *dst, const char *src) {
//         char *d = dst;
//         while ((*d++ = *src++) != '\0') { }
//         return dst;
//     }
//     char *my_strcat(char *dst, const char *src) {
//         my_strcpy(dst + strlen(dst), src);   // copy onto the end
//         return dst;
//     }
//     char buf[64];
//     int main(void) {
//         my_strcpy(buf, "Hello");
//         my_strcat(buf, ", ");
//         my_strcat(buf, "world");
//         puts(my_strcat(buf, "!"));
//         printf("length %ld\n", strlen(buf));
//     }
//
// Build: make mystrcpy
// Run:   ./mystrcpy
// Expected output:
//     Hello, world!
//     length 13

    .section .rodata
hello:
    .asciz  "Hello"
comma:
    .asciz  ", "
world:
    .asciz  "world"
bang:
    .asciz  "!"
fmt_len:
    .asciz  "length %ld\n"

    .bss
buf:
    .space  64                      // char buf[64]: big enough, we checked

    .text
    .p2align 2
// char *my_strcpy(char *dst, const char *src)
my_strcpy:
    mov     x2, x0                  // d = dst (x0 stays dst, for the return)
strcpy_loop:
    ldrb    w3, [x1], #1            // c = *src++
    strb    w3, [x2], #1            // *d++ = c   (copies the 0 too)
    cbnz    w3, strcpy_loop
    ret

// char *my_strcat(char *dst, const char *src)
my_strcat:
    mov     x2, x0                  // d = dst
strcat_find_end:
    ldrb    w3, [x2]                // walk to dst's 0 byte
    cbz     w3, strcat_copy
    add     x2, x2, #1
    b       strcat_find_end
strcat_copy:                        // then copy src over it, like strcpy
    ldrb    w3, [x1], #1
    strb    w3, [x2], #1
    cbnz    w3, strcat_copy
    ret

    .global main
    .p2align 2
main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]

    adrp    x19, buf
    add     x19, x19, :lo12:buf

    mov     x0, x19
    adrp    x1, hello
    add     x1, x1, :lo12:hello
    bl      my_strcpy
    mov     x0, x19
    adrp    x1, comma
    add     x1, x1, :lo12:comma
    bl      my_strcat
    mov     x0, x19
    adrp    x1, world
    add     x1, x1, :lo12:world
    bl      my_strcat
    mov     x0, x19
    adrp    x1, bang
    add     x1, x1, :lo12:bang
    bl      my_strcat               // returns dst in x0...
    bl      puts                    // ...which is exactly puts's argument

    mov     x0, x19
    bl      strlen
    mov     x1, x0
    adrp    x0, fmt_len
    add     x0, x0, :lo12:fmt_len
    bl      printf

    mov     w0, #0
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
