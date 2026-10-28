// wordfreq.s - Capstone project 3: count word frequencies with our own hash table.
//
// Usage:  wordfreq [N]          (N defaults to 10)
//
// Reads text from stdin. A word is a maximal run of ASCII letters, lowercased
// ("The" and "the" are the same word; "don't" is "don" and "t").
// Words are counted in an open-addressing hash table (linear probing,
// FNV-1a 64-bit hash, capacity a power of two starting at 16, doubled and
// rehashed when count*10 >= capacity*7). Keys are strdup'd.
// The entries are then sorted with qsort, by count descending and then
// word ascending (strcmp), and the first N are printed as "%7ld %s\n".
//
// Build:  make
// Run:    printf 'the cat and the hat and the bat\n' | ./wordfreq 2
// Output:
//       3 the
//       2 and
//
// The C this follows:
//
//     struct entry { char *key; long count; };      // 16 bytes
//     struct entry *table; long cap = 16, count;
//
//     struct entry *find_slot(struct entry *t, long cap, const char *key) {
//         unsigned long i = fnv1a(key) & (cap - 1);
//         while (t[i].key && strcmp(t[i].key, key) != 0)
//             i = (i + 1) & (cap - 1);
//         return &t[i];
//     }

    .equ MAXWORD, 4096          // longer words are cut to 4095 letters
    .equ ENTRY, 16              // sizeof(struct entry)

    .text
    .global main

// unsigned long fnv1a(const char *s)
// h = 0xcbf29ce484222325; for each byte: h ^= byte; h *= 0x100000001b3.
// A leaf function: no calls, so no frame.
fnv1a:
    movz    x1, #0x2325             // x1 = offset basis 0xcbf29ce484222325
    movk    x1, #0x8422, lsl #16
    movk    x1, #0x9ce4, lsl #32
    movk    x1, #0xcbf2, lsl #48
    movz    x2, #0x01b3             // x2 = FNV prime 0x100000001b3
    movk    x2, #0x0100, lsl #32
1:
    ldrb    w3, [x0], #1            // next byte, advance pointer
    cbz     w3, 2f                  // end of string
    eor     x1, x1, x3
    mul     x1, x1, x2
    b       1b
2:
    mov     x0, x1
    ret

// struct entry *find_slot(struct entry *t, long cap, const char *key)
// Returns the slot holding key, or the empty slot where it belongs.
find_slot:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    mov     x19, x0                 // x19 = table
    sub     x20, x1, #1             // x20 = mask = cap - 1
    mov     x21, x2                 // x21 = key
    mov     x0, x2
    bl      fnv1a
    and     x22, x0, x20            // x22 = i = hash & mask
.Lprobe:
    add     x0, x19, x22, lsl #4    // &t[i]
    ldr     x0, [x0]                // t[i].key
    cbz     x0, .Lslot              // empty: key belongs here
    mov     x1, x21
    bl      strcmp
    cbz     w0, .Lslot              // same key: found it
    add     x22, x22, #1            // linear probing: try the next slot
    and     x22, x22, x20           // wrap around
    b       .Lprobe
.Lslot:
    add     x0, x19, x22, lsl #4    // return &t[i]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// void grow(void) - double the table and re-insert every key.
grow:
    stp     x29, x30, [sp, #-64]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    adrp    x0, table
    ldr     x19, [x0, :lo12:table]  // x19 = old table
    adrp    x0, cap
    ldr     x20, [x0, :lo12:cap]    // x20 = old cap
    lsl     x21, x20, #1            // x21 = new cap
    mov     x0, x21
    mov     x1, #ENTRY
    bl      calloc                  // all-zero: every key NULL
    mov     x22, x0                 // x22 = new table
    mov     x23, x19                // x23 = old entry pointer
    add     x24, x19, x20, lsl #4   // x24 = end of old table
.Lgrow_loop:
    cmp     x23, x24
    b.hs    .Lgrow_done
    ldr     x2, [x23]               // old key
    cbz     x2, .Lgrow_next         // empty slot: nothing to move
    mov     x0, x22
    mov     x1, x21
    bl      find_slot               // where it goes in the new table
    ldp     x1, x2, [x23]           // copy key and count
    stp     x1, x2, [x0]
.Lgrow_next:
    add     x23, x23, #ENTRY
    b       .Lgrow_loop
.Lgrow_done:
    mov     x0, x19
    bl      free                    // the old array (keys were moved, not copied)
    adrp    x0, table
    str     x22, [x0, :lo12:table]
    adrp    x0, cap
    str     x21, [x0, :lo12:cap]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #64
    ret

// void add_word(const char *word) - count one occurrence.
add_word:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    mov     x19, x0                 // x19 = word (in the reusable buffer)
    adrp    x9, count               // grow first if count*10 >= cap*7
    ldr     x10, [x9, :lo12:count]
    adrp    x11, cap
    ldr     x12, [x11, :lo12:cap]
    mov     x13, #10
    mul     x10, x10, x13
    mov     x13, #7
    mul     x12, x12, x13
    cmp     x10, x12
    b.lo    1f
    bl      grow
1:
    adrp    x0, table
    ldr     x0, [x0, :lo12:table]
    adrp    x1, cap
    ldr     x1, [x1, :lo12:cap]
    mov     x2, x19
    bl      find_slot
    mov     x20, x0                 // x20 = slot
    ldr     x1, [x20]
    cbnz    x1, 2f                  // already present
    mov     x0, x19                 // new word: keep our own copy of it
    bl      strdup
    str     x0, [x20]               // slot->key = strdup(word); count is 0
    adrp    x9, count
    ldr     x10, [x9, :lo12:count]
    add     x10, x10, #1
    str     x10, [x9, :lo12:count]
2:
    ldr     x1, [x20, #8]           // slot->count++
    add     x1, x1, #1
    str     x1, [x20, #8]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

// int compare(const void *a, const void *b) - qsort comparator.
// Bigger count first; equal counts in strcmp order.
compare:
    ldr     x2, [x0, #8]            // a->count
    ldr     x3, [x1, #8]            // b->count
    cmp     x2, x3
    b.eq    1f
    mov     w0, #1                  // a after b ...
    mov     w4, #-1
    csel    w0, w4, w0, gt          // ... unless a->count > b->count
    ret
1:
    ldr     x0, [x0]                // a->key
    ldr     x1, [x1]                // b->key
    b       strcmp                  // tail call: strcmp's result is ours

// int main(int argc, char **argv)
main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    mov     x19, #10                // x19 = N, default 10
    cmp     w0, #2
    b.lt    1f
    ldr     x0, [x1, #8]            // argv[1]
    bl      atol
    mov     x19, x0
1:
    mov     x0, #16                 // table = calloc(16, sizeof(struct entry))
    mov     x1, #ENTRY
    bl      calloc
    adrp    x1, table
    str     x0, [x1, :lo12:table]
    mov     x0, #16
    adrp    x1, cap
    str     x0, [x1, :lo12:cap]

    // Read characters, collecting letters into wordbuf.
    adrp    x21, wordbuf
    add     x21, x21, :lo12:wordbuf // x21 = wordbuf
    mov     x20, #0                 // x20 = length of the current word
.Lread:
    bl      getchar
    mov     w22, w0                 // w22 = c (kept to test for EOF later)
    sub     w1, w0, #'A'            // 'A'..'Z' -> lowercase
    cmp     w1, #25
    b.hi    2f
    orr     w0, w0, #0x20
2:
    sub     w1, w0, #'a'
    cmp     w1, #25
    b.hi    .Lnot_letter            // unsigned compare: also catches EOF (-1)
    cmp     x20, #MAXWORD - 1
    b.hs    .Lread                  // word too long: drop extra letters
    strb    w0, [x21, x20]
    add     x20, x20, #1
    b       .Lread
.Lnot_letter:
    cbz     x20, 3f                 // no word in progress
    strb    wzr, [x21, x20]         // terminate it and count it
    mov     x0, x21
    bl      add_word
    mov     x20, #0
3:
    cmn     w22, #1                 // was it EOF?
    b.ne    .Lread

    // Squeeze the used slots to the front of the table.
    adrp    x0, table
    ldr     x21, [x0, :lo12:table]  // x21 = table
    adrp    x0, cap
    ldr     x1, [x0, :lo12:cap]
    add     x1, x21, x1, lsl #4     // x1 = end
    mov     x2, x21                 // x2 = read pointer
    mov     x3, x21                 // x3 = write pointer
.Lsqueeze:
    cmp     x2, x1
    b.hs    .Lsorted
    ldp     x4, x5, [x2], #ENTRY
    cbz     x4, .Lsqueeze
    stp     x4, x5, [x3], #ENTRY
    b       .Lsqueeze
.Lsorted:
    adrp    x0, count
    ldr     x22, [x0, :lo12:count]  // x22 = number of distinct words
    mov     x0, x21
    mov     x1, x22
    mov     x2, #ENTRY
    adrp    x3, compare
    add     x3, x3, :lo12:compare
    bl      qsort                   // qsort(table, count, 16, compare)

    cmp     x19, x22                // print min(N, count) lines
    csel    x19, x19, x22, lt
    mov     x20, #0                 // x20 = i
.Lprint:
    cmp     x20, x19
    b.ge    .Ldone                  // signed: a negative N prints nothing
    add     x9, x21, x20, lsl #4
    adrp    x0, fmt
    add     x0, x0, :lo12:fmt
    ldr     x1, [x9, #8]            // count
    ldr     x2, [x9]                // word
    bl      printf
    add     x20, x20, #1
    b       .Lprint
.Ldone:
    mov     w0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .section .rodata
fmt:
    .asciz  "%7ld %s\n"

    .data
    .p2align 3
table:  .quad 0                     // struct entry *
cap:    .quad 0
count:  .quad 0

    .bss
wordbuf:
    .space  MAXWORD
