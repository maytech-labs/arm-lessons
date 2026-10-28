// ex6.s - a cp clone using open/read/write/close (lesson 25)
//
// Build: make ex6
// Run:   ./ex6 ../examples/sample.txt copy.txt && cmp ../examples/sample.txt copy.txt && echo same
// Expected output:
//   same
// Run:   ./ex6 nope.txt copy.txt; echo $?
// Expected output (on stderr, then the status):
//   nope.txt: No such file or directory
//   1
// Run:   ./ex6; echo $?
// Expected output:
//   usage: ex6 SRC DST
//   2
//
// C version:
//   int main(int argc, char **argv) {
//       if (argc != 3) { fputs("usage: ex6 SRC DST\n", stderr); return 2; }
//       int in = open(argv[1], O_RDONLY);
//       if (in < 0) { perror(argv[1]); return 1; }
//       int out = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);
//       if (out < 0) { perror(argv[2]); close(in); return 1; }
//       char buf[4096];
//       long n;
//       int status = 0;
//       while ((n = read(in, buf, sizeof buf)) > 0)
//           if (write(out, buf, n) != n) { perror("write"); status = 1; break; }
//       if (n < 0) { perror("read"); status = 1; }
//       close(in);
//       close(out);
//       return status;
//   }

    .equ O_RDONLY, 0
    .equ O_WRONLY, 1
    .equ O_CREAT,  0x40             // Linux values (see /usr/include/asm-generic/fcntl.h)
    .equ O_TRUNC,  0x200
    .equ MODE,     0644             // rw-r--r-- (the leading 0 makes it octal)
    .equ BUFSIZE,  4096

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = argv, x20 = in
    stp x21, x22, [sp, #32]         // x21 = out, x22 = status
    stp x23, x24, [sp, #48]         // x23 = buf, x24 = n

    cmp w0, #3
    b.ne main_usage
    mov x19, x1

    ldr x0, [x19, #8]               // in = open(argv[1], O_RDONLY)
    mov w1, #O_RDONLY
    bl open
    cmp w0, #0
    b.lt main_fail_src
    mov w20, w0

    ldr x0, [x19, #16]              // out = open(argv[2], flags, 0644)
    mov w1, #(O_WRONLY | O_CREAT | O_TRUNC)
    mov w2, #MODE                   // third argument: an ordinary register on Linux
    bl open
    cmp w0, #0
    b.lt main_fail_dst
    mov w21, w0

    mov w22, #0                     // status = 0
    adrp x23, buf
    add x23, x23, :lo12:buf
main_loop:
    mov w0, w20                     // n = read(in, buf, BUFSIZE)
    mov x1, x23
    mov x2, #BUFSIZE
    bl read
    cmp x0, #0
    b.eq main_close                 // 0: end of file
    b.lt main_read_error            // -1: error, errno is set
    mov x24, x0                     // keep n: x0-x17 do not survive a call
    mov w0, w21                     // write(out, buf, n)
    mov x1, x23
    mov x2, x24
    bl write
    cmp x0, x24
    b.ne main_write_error           // wrote less than n (or -1)
    b main_loop

main_read_error:
    adrp x0, str_read
    add x0, x0, :lo12:str_read
    bl perror
    mov w22, #1
    b main_close
main_write_error:
    adrp x0, str_write
    add x0, x0, :lo12:str_write
    bl perror
    mov w22, #1
main_close:
    mov w0, w20
    bl close
    mov w0, w21
    bl close
    mov w0, w22
    b main_done

main_fail_dst:
    ldr x0, [x19, #16]
    bl perror
    mov w0, w20
    bl close
    mov w0, #1
    b main_done

main_fail_src:
    ldr x0, [x19, #8]
    bl perror
    mov w0, #1
    b main_done

main_usage:
    adrp x1, :got:stderr
    ldr x1, [x1, :got_lo12:stderr]
    ldr x1, [x1]
    adrp x0, msg_usage
    add x0, x0, :lo12:msg_usage
    bl fputs
    mov w0, #2

main_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

    .section .rodata
msg_usage: .asciz "usage: ex6 SRC DST\n"
str_read:  .asciz "read"
str_write: .asciz "write"

    .bss
    .p2align 4
buf: .space BUFSIZE
