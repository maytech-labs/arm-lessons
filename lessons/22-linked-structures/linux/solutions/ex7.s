// ex7.s - count the nodes of a BST and find its smallest and largest keys (lesson 22, exercise 22.7)
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//   count: 8
//   min: 20
//   max: 80

// struct tree { long key; struct tree *left; struct tree *right; };
    .equ TREE_KEY,   0
    .equ TREE_LEFT,  8
    .equ TREE_RIGHT, 16
    .equ TREE_SIZE,  24

    .equ NKEYS, 8               // how many entries the keys table has

    .text
    .global main
    .p2align 2

// struct tree *bst_insert(struct tree *t, long key)     (same as examples/bst.s)
bst_insert:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov x20, x1
    cbnz x19, bst_insert_descend
    mov x0, #TREE_SIZE
    bl malloc
    cbz x0, out_of_memory
    str x20, [x0, #TREE_KEY]
    str xzr, [x0, #TREE_LEFT]
    str xzr, [x0, #TREE_RIGHT]
    b bst_insert_done
bst_insert_descend:
    ldr x9, [x19, #TREE_KEY]
    cmp x20, x9
    b.lt bst_insert_left
    b.gt bst_insert_right
    mov x0, x19
    b bst_insert_done
bst_insert_left:
    ldr x0, [x19, #TREE_LEFT]
    mov x1, x20
    bl bst_insert
    str x0, [x19, #TREE_LEFT]
    mov x0, x19
    b bst_insert_done
bst_insert_right:
    ldr x0, [x19, #TREE_RIGHT]
    mov x1, x20
    bl bst_insert
    str x0, [x19, #TREE_RIGHT]
    mov x0, x19
bst_insert_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void bst_free(struct tree *t)
bst_free:
    cbz x0, bst_free_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_free
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_free
    mov x0, x19
    bl free
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
bst_free_done:
    ret

out_of_memory:
    adrp x0, msg_oom
    add x0, x0, :lo12:msg_oom
    bl puts
    mov w0, #1
    bl exit

// struct tree *build_tree(void): insert every key from the keys table
build_tree:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, #0
    adrp x21, keys
    add x21, x21, :lo12:keys
    mov x20, #0
build_tree_loop:
    mov x0, x19
    ldr x1, [x21, x20, lsl #3]
    bl bst_insert
    mov x19, x0
    add x20, x20, #1
    cmp x20, #NKEYS
    b.lo build_tree_loop
    mov x0, x19
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// long bst_count(struct tree *t)
//     if (t == NULL) return 0;
//     return 1 + bst_count(t->left) + bst_count(t->right);
bst_count:
    cbz x0, bst_count_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_count
    mov x20, x0                 // left count, safe in x20
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_count
    add x0, x0, x20
    add x0, x0, #1
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
bst_count_done:
    ret

// long bst_min(struct tree *t)     (t != NULL): keep going left
bst_min:
    ldr x9, [x0, #TREE_LEFT]
    cbz x9, bst_min_done
    mov x0, x9
    b bst_min
bst_min_done:
    ldr x0, [x0, #TREE_KEY]
    ret

// long bst_max(struct tree *t)     (t != NULL): keep going right
bst_max:
    ldr x9, [x0, #TREE_RIGHT]
    cbz x9, bst_max_done
    mov x0, x9
    b bst_max
bst_max_done:
    ldr x0, [x0, #TREE_KEY]
    ret

main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    bl build_tree
    mov x19, x0

    bl bst_count
    mov x1, x0
    adrp x0, fmt_count
    add x0, x0, :lo12:fmt_count
    bl printf

    mov x0, x19
    bl bst_min
    mov x1, x0
    adrp x0, fmt_min
    add x0, x0, :lo12:fmt_min
    bl printf

    mov x0, x19
    bl bst_max
    mov x1, x0
    adrp x0, fmt_max
    add x0, x0, :lo12:fmt_max
    bl printf

    mov x0, x19
    bl bst_free
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section .rodata
    .p2align 3
keys:      .quad 50, 30, 70, 20, 40, 60, 80, 35
fmt_count: .asciz "count: %ld\n"
fmt_min:   .asciz "min: %ld\n"
fmt_max:   .asciz "max: %ld\n"
msg_oom:   .asciz "out of memory"
