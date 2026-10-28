// bf.s - Capstone project 5: a Brainfuck interpreter.
//
// Usage:  bf FILE
//
// Reads the whole program from FILE, keeps only the 8 commands  + - < > [ ] . ,
// and matches every bracket up front (a stack of '[' positions fills a jump
// array), then runs it on a tape of 30000 unsigned bytes (8-bit wraparound).
// The tape pointer starts at cell 0. ',' reads a byte with getchar (EOF stores
// 0); '.' writes one with putchar.
//
// Errors (on stderr):
//     usage: bf FILE                    exit 2
//     bf: FILE: <reason>                exit 1 (cannot open)
//     bf: unmatched [   / ]             exit 1
//     bf: tape pointer out of range     exit 1 (moved below 0 or past 29999)
//
// Build:  make
// Run:    printf '++++++++[>++++++++<-]>+.+.+.\n' > abc.bf
//         ./bf abc.bf
// Output: ABC                            (no newline)
//
// The C this follows:
//
//     for (pc = 0; pc < len; pc++)
//         switch (code[pc]) {
//         case '>': if (++p == 30000) die("tape pointer out of range"); break;
//         case '<': if (p-- == 0)     die("tape pointer out of range"); break;
//         case '+': tape[p]++; break;
//         case '-': tape[p]--; break;
//         case '.': putchar(tape[p]); break;
//         case ',': c = getchar(); tape[p] = (c == EOF) ? 0 : c; break;
//         case '[': if (tape[p] == 0) pc = jump[pc]; break;
//         case ']': if (tape[p] != 0) pc = jump[pc]; break;
//         }

    .equ TAPE, 30000

    .text
    .global main

// void die(const char *msg) - fputs(msg, stderr); exit(1).
die:
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]
    ldr     x1, [x1]
    bl      fputs
    mov     w0, #1
    bl      exit                    // flushes stdout first; never returns

// int main(int argc, char **argv)
// x19 = code, x20 = len, x21 = jump[], x22 = tape, x23 = p (cell index),
// x24 = pc, x25 = FILE * / capacity / stack, x26 = file name, x27 = scratch
main:
    stp     x29, x30, [sp, #-96]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]
    str     x27, [sp, #80]

    cmp     w0, #2
    b.ne    .Lusage
    ldr     x26, [x1, #8]           // x26 = FILE
    mov     x0, x26
    adrp    x1, mode_r
    add     x1, x1, :lo12:mode_r
    bl      fopen
    cbz     x0, .Lopen_failed
    mov     x25, x0                 // x25 = FILE *

    // Read the program, keeping only command characters.
    mov     x27, #4096              // x27 = capacity
    mov     x0, x27
    bl      malloc
    mov     x19, x0                 // x19 = code
    mov     x20, #0                 // x20 = len
.Lread:
    mov     x0, x25
    bl      getc
    cmn     w0, #1
    b.eq    .Lread_done
    cbz     w0, .Lread              // a NUL byte is not a command
    mov     w24, w0                 // keep c (x24 is free until we run)
    mov     w1, w0
    adrp    x0, commands
    add     x0, x0, :lo12:commands
    bl      strchr                  // is c one of "+-<>[].," ?
    cbz     x0, .Lread
    cmp     x20, x27
    b.lo    1f
    lsl     x27, x27, #1            // full: double the buffer
    mov     x0, x19
    mov     x1, x27
    bl      realloc
    mov     x19, x0
1:
    strb    w24, [x19, x20]
    add     x20, x20, #1
    b       .Lread
.Lread_done:
    mov     x0, x25
    bl      fclose

    // Match brackets. jump[i] (8 bytes each) holds the partner of a bracket.
    lsl     x0, x20, #3
    add     x0, x0, #8              // +8 so an empty program still mallocs
    bl      malloc
    mov     x21, x0                 // x21 = jump
    lsl     x0, x20, #3
    add     x0, x0, #8
    bl      malloc
    mov     x25, x0                 // x25 = stack of '[' positions
    mov     x9, #0                  // x9 = depth
    mov     x10, #0                 // x10 = i
.Lmatch:
    cmp     x10, x20
    b.hs    .Lmatch_done
    ldrb    w11, [x19, x10]
    cmp     w11, #'['
    b.ne    2f
    str     x10, [x25, x9, lsl #3]  // push i
    add     x9, x9, #1
    b       3f
2:
    cmp     w11, #']'
    b.ne    3f
    cbz     x9, .Lunmatched_close   // ']' with nothing open
    sub     x9, x9, #1
    ldr     x12, [x25, x9, lsl #3]  // pop j
    str     x12, [x21, x10, lsl #3] // jump[i] = j
    str     x10, [x21, x12, lsl #3] // jump[j] = i
3:
    add     x10, x10, #1
    b       .Lmatch
.Lmatch_done:
    cbnz    x9, .Lunmatched_open    // a '[' was never closed
    mov     x0, x25
    bl      free

    // Run.
    mov     x0, #TAPE
    mov     x1, #1
    bl      calloc
    mov     x22, x0                 // x22 = tape, all zero
    mov     x23, #0                 // x23 = p
    mov     x24, #0                 // x24 = pc
    mov     x27, #TAPE - 1          // x27 = last valid cell
.Lrun:
    cmp     x24, x20
    b.hs    .Lfinished
    ldrb    w0, [x19, x24]          // the command
    cmp     w0, #'>'
    b.eq    .Lright
    cmp     w0, #'<'
    b.eq    .Lleft
    cmp     w0, #'+'
    b.eq    .Lplus
    cmp     w0, #'-'
    b.eq    .Lminus
    cmp     w0, #'.'
    b.eq    .Lout
    cmp     w0, #','
    b.eq    .Lin
    cmp     w0, #'['
    b.eq    .Lopen
    // otherwise it is ']'
    ldrb    w1, [x22, x23]
    cbz     w1, .Lnext
    ldr     x24, [x21, x24, lsl #3] // jump back to the matching '['
    b       .Lnext
.Lopen:
    ldrb    w1, [x22, x23]
    cbnz    w1, .Lnext
    ldr     x24, [x21, x24, lsl #3] // skip forward to the matching ']'
    b       .Lnext
.Lright:
    cmp     x23, x27
    b.hs    .Lrange
    add     x23, x23, #1
    b       .Lnext
.Lleft:
    cbz     x23, .Lrange
    sub     x23, x23, #1
    b       .Lnext
.Lplus:
    ldrb    w1, [x22, x23]
    add     w1, w1, #1              // strb keeps the low 8 bits: wraps at 256
    strb    w1, [x22, x23]
    b       .Lnext
.Lminus:
    ldrb    w1, [x22, x23]
    sub     w1, w1, #1
    strb    w1, [x22, x23]
    b       .Lnext
.Lout:
    ldrb    w0, [x22, x23]
    bl      putchar
    b       .Lnext
.Lin:
    bl      getchar
    cmn     w0, #1
    csel    w0, wzr, w0, eq         // EOF -> 0
    strb    w0, [x22, x23]
.Lnext:
    add     x24, x24, #1
    b       .Lrun

.Lfinished:
    mov     w0, #0
    ldr     x27, [sp, #80]
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #96
    ret

.Lusage:
    adrp    x0, usage_msg
    add     x0, x0, :lo12:usage_msg
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]
    ldr     x1, [x1]
    bl      fputs
    mov     w0, #2
    bl      exit

.Lopen_failed:
    bl      __errno_location        // fprintf(stderr, "bf: %s: %s\n",
    ldr     w0, [x0]                //         name, strerror(errno))
    bl      strerror
    mov     x3, x0
    mov     x2, x26
    adrp    x1, open_msg
    add     x1, x1, :lo12:open_msg
    adrp    x0, :got:stderr
    ldr     x0, [x0, :got_lo12:stderr]
    ldr     x0, [x0]
    bl      fprintf
    mov     w0, #1
    bl      exit

.Lunmatched_open:
    adrp    x0, open_br_msg
    add     x0, x0, :lo12:open_br_msg
    bl      die
.Lunmatched_close:
    adrp    x0, close_br_msg
    add     x0, x0, :lo12:close_br_msg
    bl      die
.Lrange:
    adrp    x0, range_msg
    add     x0, x0, :lo12:range_msg
    bl      die

    .section .rodata
commands:     .asciz "+-<>[].,"
mode_r:       .asciz "r"
usage_msg:    .asciz "usage: bf FILE\n"
open_msg:     .asciz "bf: %s: %s\n"
open_br_msg:  .asciz "bf: unmatched [\n"
close_br_msg: .asciz "bf: unmatched ]\n"
range_msg:    .asciz "bf: tape pointer out of range\n"
