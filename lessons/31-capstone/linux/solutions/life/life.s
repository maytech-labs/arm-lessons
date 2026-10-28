// life.s - Capstone project 4: Conway's Game of Life.
//
// Usage:  life [-a] FILE GENERATIONS
//
// FILE holds rows of '.' (dead) and '#' (alive). The width is the longest
// line; shorter lines are padded with dead cells. At most 200x200 cells.
// Edges wrap around (the grid is a torus).
//
// Without -a, for g = 0..GENERATIONS it prints "Generation g:", the grid,
// and a blank line. With -a it clears the screen ("\033[H\033[2J") before
// each generation, prints the same header and grid, and sleeps 0.1 s.
//
// Errors: bad usage -> "usage: life [-a] FILE GENERATIONS" on stderr, exit 2.
//         unopenable file -> "life: FILE: <reason>" on stderr, exit 1.
//
// Build:  make
// Run:    printf '.....\n..#..\n..#..\n..#..\n.....\n' > blinker.txt
//         ./life blinker.txt 1
// Output:
//     Generation 0:
//     .....
//     ..#..
//     ..#..
//     ..#..
//     .....
//
//     Generation 1:
//     .....
//     .....
//     .###.
//     .....
//     .....
//
// Cells are bytes, 0 or 1, in two fixed 200x200 arrays (row stride 200).
// step() reads one and writes the other, then main swaps the pointers.

    .equ MAX, 200               // maximum rows and columns, and the row stride

    .text
    .global main

// void step(const char *cur, char *next, long rows, long cols)
// One generation. For each cell, count the 8 neighbours with wraparound;
// next = (n == 3) || (alive && n == 2). A leaf: uses only scratch registers.
step:
    mov     x14, #MAX               // x14 = row stride
    mov     x4, #0                  // x4 = r
.Lrow:
    cmp     x4, x2
    b.hs    .Lstep_done
    sub     x12, x4, #1             // up = (r == 0) ? rows - 1 : r - 1
    sub     x13, x2, #1
    cmp     x4, #0
    csel    x12, x13, x12, eq
    madd    x6, x12, x14, x0        // x6 = &cur[up][0]
    madd    x7, x4, x14, x0         // x7 = &cur[r][0]
    add     x12, x4, #1             // down = (r + 1 == rows) ? 0 : r + 1
    cmp     x12, x2
    csel    x12, xzr, x12, eq
    madd    x8, x12, x14, x0        // x8 = &cur[down][0]
    madd    x16, x4, x14, x1        // x16 = &next[r][0]
    mov     x5, #0                  // x5 = c
.Lcol:
    cmp     x5, x3
    b.hs    .Lrow_next
    sub     x9, x5, #1              // left = (c == 0) ? cols - 1 : c - 1
    sub     x13, x3, #1
    cmp     x5, #0
    csel    x9, x13, x9, eq
    add     x10, x5, #1             // right = (c + 1 == cols) ? 0 : c + 1
    cmp     x10, x3
    csel    x10, xzr, x10, eq

    ldrb    w11, [x6, x9]           // n = sum of the 8 neighbours
    ldrb    w12, [x6, x5]
    add     w11, w11, w12
    ldrb    w12, [x6, x10]
    add     w11, w11, w12
    ldrb    w12, [x7, x9]
    add     w11, w11, w12
    ldrb    w12, [x7, x10]
    add     w11, w11, w12
    ldrb    w12, [x8, x9]
    add     w11, w11, w12
    ldrb    w12, [x8, x5]
    add     w11, w11, w12
    ldrb    w12, [x8, x10]
    add     w11, w11, w12

    ldrb    w13, [x7, x5]           // alive?
    cmp     w11, #3
    cset    w12, eq                 // w12 = (n == 3)
    cmp     w11, #2
    cset    w15, eq                 // w15 = (n == 2)
    and     w15, w15, w13           //       && alive
    orr     w12, w12, w15
    strb    w12, [x16, x5]
    add     x5, x5, #1
    b       .Lcol
.Lrow_next:
    add     x4, x4, #1
    b       .Lrow
.Lstep_done:
    ret

// void show(const char *grid, long rows, long cols, long g)
// Prints "Generation g:" and the grid, one puts() per row.
show:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    str     x23, [sp, #48]
    mov     x19, x0                 // x19 = grid
    mov     x20, x1                 // x20 = rows
    mov     x21, x2                 // x21 = cols
    adrp    x0, header
    add     x0, x0, :lo12:header
    mov     x1, x3
    bl      printf                  // printf("Generation %ld:\n", g)
    adrp    x22, line
    add     x22, x22, :lo12:line    // x22 = line buffer
    mov     x23, #0                 // x23 = r
.Lshow_row:
    cmp     x23, x20
    b.hs    .Lshow_done
    mov     x9, #MAX
    madd    x9, x23, x9, x19        // x9 = &grid[r][0]
    mov     x10, #0                 // x10 = c
    mov     w11, #'.'
    mov     w12, #'#'
.Lshow_col:
    cmp     x10, x21
    b.hs    .Lshow_put
    ldrb    w13, [x9, x10]
    cmp     w13, #0
    csel    w13, w11, w12, eq       // dead -> '.', alive -> '#'
    strb    w13, [x22, x10]
    add     x10, x10, #1
    b       .Lshow_col
.Lshow_put:
    strb    wzr, [x22, x21]         // terminate; puts adds the newline
    mov     x0, x22
    bl      puts
    add     x23, x23, #1
    b       .Lshow_row
.Lshow_done:
    ldr     x23, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// load(FILE *f, char *grid) -> x0 = rows, x1 = cols; x0 = -1 if too large.
// The grid is zero (dead) to begin with, so only '#' needs storing.
load:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    mov     x19, x0                 // x19 = f
    mov     x20, x1                 // x20 = grid
    mov     x21, #0                 // x21 = r
    mov     x22, #0                 // x22 = c
    adrp    x9, width               // width = 0 (kept in memory: it is
    str     xzr, [x9, :lo12:width]  //   live across getc calls)
.Lload_loop:
    mov     x0, x19
    bl      getc
    cmn     w0, #1
    b.eq    .Lload_eof
    cmp     w0, #'\n'
    b.eq    .Lload_newline
    cmp     w0, #'\r'               // tolerate Windows line endings
    b.eq    .Lload_loop
    cmp     x21, #MAX               // a cell on row 200 or column 200?
    b.hs    .Lload_big
    cmp     x22, #MAX
    b.hs    .Lload_big
    cmp     w0, #'#'
    cset    w1, eq                  // '#' -> 1, anything else -> 0
    mov     x2, #MAX
    madd    x2, x21, x2, x20
    strb    w1, [x2, x22]
    add     x22, x22, #1
    adrp    x9, width               // width = max(width, c)
    ldr     x10, [x9, :lo12:width]
    cmp     x22, x10
    csel    x10, x22, x10, hi
    str     x10, [x9, :lo12:width]
    b       .Lload_loop
.Lload_newline:
    add     x21, x21, #1
    mov     x22, #0
    b       .Lload_loop
.Lload_eof:
    cbz     x22, 1f                 // last line had no '\n': still a row
    add     x21, x21, #1
1:
    cmp     x21, #MAX
    b.hi    .Lload_big
    mov     x0, x21
    adrp    x9, width
    ldr     x1, [x9, :lo12:width]
    b       .Lload_ret
.Lload_big:
    mov     x0, #-1
.Lload_ret:
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// Print "usage: ..." on stderr and exit(2).
usage:
    adrp    x0, usage_msg
    add     x0, x0, :lo12:usage_msg
    adrp    x1, :got:stderr
    ldr     x1, [x1, :got_lo12:stderr]
    ldr     x1, [x1]
    bl      fputs
    mov     w0, #2
    bl      exit

// int main(int argc, char **argv)
// x19 = animate, x20 = generations, x21 = g, x22 = cur, x23 = next,
// x24 = rows, x25 = cols, x26 = file name, x27 = FILE * / scratch.
main:
    stp     x29, x30, [sp, #-96]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]
    stp     x27, x28, [sp, #80]

    mov     x19, #0                 // animate = 0
    mov     w27, w0                 // argc
    add     x28, x1, #8             // x28 = &argv[1]
    cmp     w27, #2
    b.lt    usage
    ldr     x0, [x28]
    adrp    x1, dash_a
    add     x1, x1, :lo12:dash_a
    bl      strcmp
    cbnz    w0, 1f
    mov     x19, #1                 // "-a": animate, skip it
    add     x28, x28, #8
    sub     w27, w27, #1
1:
    cmp     w27, #3                 // exactly FILE and GENERATIONS left
    b.ne    usage
    ldr     x26, [x28]              // x26 = FILE
    ldr     x0, [x28, #8]           // GENERATIONS = strtol(s, &end, 10)
    sub     sp, sp, #16             // a 16-byte stack slot for `end`
    mov     x1, sp
    mov     w2, #10
    bl      strtol
    ldr     x1, [sp]                // end
    add     sp, sp, #16
    ldr     x2, [x28, #8]
    cmp     x1, x2                  // no digits at all?
    b.eq    usage
    ldrb    w1, [x1]                // trailing junk?
    cbnz    w1, usage
    tbnz    x0, #63, usage          // negative?
    mov     x20, x0                 // x20 = generations

    mov     x0, x26
    adrp    x1, mode_r
    add     x1, x1, :lo12:mode_r
    bl      fopen
    cbz     x0, .Lopen_failed
    mov     x27, x0                 // x27 = FILE *
    adrp    x22, grid_a
    add     x22, x22, :lo12:grid_a  // x22 = cur
    adrp    x23, grid_b
    add     x23, x23, :lo12:grid_b  // x23 = next
    mov     x0, x27
    mov     x1, x22
    bl      load
    mov     x24, x0                 // rows
    mov     x25, x1                 // cols
    mov     x0, x27
    bl      fclose
    tbnz    x24, #63, .Ltoo_big

    mov     x21, #0                 // g = 0
.Lgen:
    cbz     x19, 2f
    adrp    x0, clear               // -a: clear the screen first
    add     x0, x0, :lo12:clear
    bl      printf
2:
    mov     x0, x22
    mov     x1, x24
    mov     x2, x25
    mov     x3, x21
    bl      show
    cbnz    x19, 3f
    mov     w0, #'\n'               // no -a: blank line between generations
    bl      putchar
    b       4f
3:
    mov     x0, #0                  // fflush(NULL): flush every stream
    bl      fflush
    movz    w0, #0x86a0             // usleep(100000)
    movk    w0, #0x1, lsl #16
    bl      usleep
4:
    cmp     x21, x20
    b.hs    .Lfinished
    mov     x0, x22
    mov     x1, x23
    mov     x2, x24
    mov     x3, x25
    bl      step
    mov     x9, x22                 // swap cur and next
    mov     x22, x23
    mov     x23, x9
    add     x21, x21, #1
    b       .Lgen

.Lfinished:
    mov     w0, #0
    b       .Lreturn

.Lopen_failed:
    bl      __errno_location        // fprintf(stderr, "life: %s: %s\n",
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
    b       .Lreturn

.Ltoo_big:
    mov     x2, x26
    adrp    x1, big_msg
    add     x1, x1, :lo12:big_msg
    adrp    x0, :got:stderr
    ldr     x0, [x0, :got_lo12:stderr]
    ldr     x0, [x0]
    bl      fprintf
    mov     w0, #1

.Lreturn:
    ldp     x27, x28, [sp, #80]
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #96
    ret

    .section .rodata
header:     .asciz "Generation %ld:\n"
clear:      .asciz "\033[H\033[2J"
dash_a:     .asciz "-a"
mode_r:     .asciz "r"
usage_msg:  .asciz "usage: life [-a] FILE GENERATIONS\n"
open_msg:   .asciz "life: %s: %s\n"
big_msg:    .asciz "life: %s: pattern too large (max 200x200)\n"

    .data
    .p2align 3
width:      .quad 0                 // widest line seen by load()

    .bss
grid_a:     .space MAX * MAX
grid_b:     .space MAX * MAX
line:       .space MAX + 1
