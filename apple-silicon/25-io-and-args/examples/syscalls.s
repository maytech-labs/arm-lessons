// syscalls.s - print a file with open/read/write/close (lesson 25, macOS)
//
// On Linux this example makes raw system calls (svc #0). On macOS the system
// call interface is not a stable ABI, so we call libSystem's wrappers _open,
// _read, _write and _close. They are unbuffered: one call, one system call.
// They return -1 on failure and leave the reason in errno.
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
// C version:
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

    .equ O_RDONLY, 0
    .equ BUFSIZE,  4096

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    cmp w0, #2
    b.ne main_usage

    ldr x0, [x1, #8]            // open(argv[1], O_RDONLY)
    mov w1, #O_RDONLY           // no mode argument, so nothing goes on the stack
    bl _open
    cmp w0, #0
    b.lt main_open_failed       // -1: the reason is in errno
    mov w19, w0                 // x19 = fd

    adrp x20, buf@PAGE
    add x20, x20, buf@PAGEOFF   // x20 = buf
main_loop:
    mov w0, w19                 // n = read(fd, buf, BUFSIZE)
    mov x1, x20
    mov x2, #BUFSIZE
    bl _read
    cmp x0, #0
    b.le main_eof               // 0 = end of file, -1 = error
    mov x2, x0                  // write(1, buf, n)
    mov w0, #1
    mov x1, x20
    bl _write
    b main_loop

main_eof:
    mov w0, w19                 // close(fd)
    bl _close
    mov w0, #0
    b main_done

main_open_failed:
    bl ___error                 // x0 = &errno
    ldr w9, [x0]
    sub sp, sp, #16
    str x9, [sp]                // variadic: on the stack
    adrp x0, fmt_fail@PAGE
    add x0, x0, fmt_fail@PAGEOFF
    bl _printf
    add sp, sp, #16
    mov w0, #1
    b main_done

main_usage:
    adrp x8, ___stderrp@GOTPAGE
    ldr x8, [x8, ___stderrp@GOTPAGEOFF]
    ldr x1, [x8]
    adrp x0, msg_usage@PAGE
    add x0, x0, msg_usage@PAGEOFF
    bl _fputs
    mov w0, #2

main_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_fail:  .asciz "open failed: error %d\n"
msg_usage: .asciz "usage: syscalls FILE\n"

    .bss
    .p2align 4
buf: .space BUFSIZE
