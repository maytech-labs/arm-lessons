// syscalls.s - print a file with raw openat/read/write/close (lesson 25)
//
// Build: make syscalls
// Run:   ./syscalls sample.txt
// Expected output: the contents of sample.txt (12 lines, "The quick brown fox" ... "seven")
// Run:   ./syscalls nope.txt; echo $?
// Expected output:
//   open failed: error 2
//   1
// Run:   ./syscalls; echo $?
// Expected output:
//   usage: syscalls FILE
//   2
//
// C version (with the system call wrappers from <unistd.h> and <fcntl.h>):
//   int main(int argc, char **argv) {
//       if (argc != 2) { fputs("usage: syscalls FILE\n", stderr); return 2; }
//       int fd = open(argv[1], O_RDONLY);
//       if (fd < 0) { printf("open failed: error %d\n", errno); return 1; }
//       char buf[4096];
//       long n;
//       while ((n = read(fd, buf, sizeof buf)) > 0)
//           write(1, buf, n);
//       close(fd);
//       return 0;
//   }
// The raw Linux system call does not set errno: it returns -errno in x0.

    .equ SYS_openat, 56
    .equ SYS_close,  57
    .equ SYS_read,   63
    .equ SYS_write,  64
    .equ AT_FDCWD,   -100           // "relative to the current directory"
    .equ O_RDONLY,   0
    .equ BUFSIZE,    4096

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    cmp w0, #2
    b.ne main_usage

    mov x0, #AT_FDCWD           // openat(AT_FDCWD, argv[1], O_RDONLY, 0)
    ldr x1, [x1, #8]            // argv[1]
    mov x2, #O_RDONLY
    mov x3, #0
    mov x8, #SYS_openat
    svc #0
    cmp x0, #0
    b.lt main_open_failed       // negative: x0 = -errno
    mov x19, x0                 // x19 = fd

    adrp x20, buf
    add x20, x20, :lo12:buf     // x20 = buf
main_loop:
    mov x0, x19                 // n = read(fd, buf, BUFSIZE)
    mov x1, x20
    mov x2, #BUFSIZE
    mov x8, #SYS_read
    svc #0
    cmp x0, #0
    b.le main_eof               // 0 = end of file, negative = error
    mov x2, x0                  // write(1, buf, n)
    mov x0, #1
    mov x1, x20
    mov x8, #SYS_write
    svc #0
    b main_loop

main_eof:
    mov x0, x19                 // close(fd)
    mov x8, #SYS_close
    svc #0
    mov w0, #0
    b main_done

main_open_failed:
    neg x1, x0                  // errno = -x0
    adrp x0, fmt_fail
    add x0, x0, :lo12:fmt_fail
    bl printf
    mov w0, #1
    b main_done

main_usage:
    adrp x8, :got:stderr
    ldr x8, [x8, :got_lo12:stderr]
    ldr x1, [x8]
    adrp x0, msg_usage
    add x0, x0, :lo12:msg_usage
    bl fputs
    mov w0, #2

main_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
fmt_fail:  .asciz "open failed: error %d\n"
msg_usage: .asciz "usage: syscalls FILE\n"

    .bss
    .p2align 4
buf: .space BUFSIZE
