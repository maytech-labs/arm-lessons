// ex9.s - delete keys from a BST: leaf, one child, two children (lesson 22, exercise 22.9, macOS)
//
// Build: make ex9
// Run:   ./ex9
// Expected output:
//   start: 20 30 35 40 50 60 70 80
//   delete 20: 30 35 40 50 60 70 80
//   delete 30: 35 40 50 60 70 80
//   delete 50: 35 40 60 70 80
//   delete 99: 35 40 60 70 80

// struct tree { long key; struct tree *left; struct tree *right; };
    .equ TREE_KEY,   0
    .equ TREE_LEFT,  8
    .equ TREE_RIGHT, 16
    .equ TREE_SIZE,  24

    .equ NKEYS, 8               // how many entries the keys table has

    .text
    .global _main
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
    bl _malloc
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
    bl _free
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
bst_free_done:
    ret

out_of_memory:
    adrp x0, msg_oom@PAGE
    add x0, x0, msg_oom@PAGEOFF
    bl _puts
    mov w0, #1
    bl _exit

// struct tree *build_tree(void): insert every key from the keys table
build_tree:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, #0
    adrp x21, keys@PAGE
    add x21, x21, keys@PAGEOFF
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

// struct tree *bst_delete(struct tree *t, long key)
//     if (t == NULL) return NULL;
//     if (key < t->key)      t->left  = bst_delete(t->left, key);
//     else if (key > t->key) t->right = bst_delete(t->right, key);
//     else if (t->left == NULL)  { r = t->right; free(t); return r; }
//     else if (t->right == NULL) { l = t->left;  free(t); return l; }
//     else {
//         s = t->right; while (s->left) s = s->left;   // smallest key on the right
//         t->key = s->key;                              // copy it up
//         t->right = bst_delete(t->right, s->key);      // and delete it below
//     }
//     return t;
bst_delete:
    cbz x0, bst_delete_ret      // empty tree: return NULL
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                 // t
    mov x20, x1                 // key
    ldr x9, [x19, #TREE_KEY]
    cmp x20, x9
    b.lt bst_delete_left
    b.gt bst_delete_right
    // found it
    ldr x9, [x19, #TREE_LEFT]
    ldr x10, [x19, #TREE_RIGHT]
    cbz x9, bst_delete_replace_right
    cbz x10, bst_delete_replace_left
    mov x11, x10                // two children: s = t->right
bst_delete_succ:
    ldr x12, [x11, #TREE_LEFT]
    cbz x12, bst_delete_copy
    mov x11, x12
    b bst_delete_succ
bst_delete_copy:
    ldr x1, [x11, #TREE_KEY]
    str x1, [x19, #TREE_KEY]    // t->key = s->key
    mov x0, x10
    bl bst_delete               // bst_delete(t->right, s->key)
    str x0, [x19, #TREE_RIGHT]
    b bst_delete_keep
bst_delete_replace_right:
    mov x20, x10                // r = t->right (x20 survives free)
    b bst_delete_free
bst_delete_replace_left:
    mov x20, x9                 // l = t->left
bst_delete_free:
    mov x0, x19
    bl _free                    // free(t)
    mov x0, x20                 // return the child that takes its place
    b bst_delete_done
bst_delete_left:
    ldr x0, [x19, #TREE_LEFT]
    mov x1, x20
    bl bst_delete
    str x0, [x19, #TREE_LEFT]
    b bst_delete_keep
bst_delete_right:
    ldr x0, [x19, #TREE_RIGHT]
    mov x1, x20
    bl bst_delete
    str x0, [x19, #TREE_RIGHT]
bst_delete_keep:
    mov x0, x19                 // return t
bst_delete_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
bst_delete_ret:
    ret

// void bst_print(struct tree *t)       in-order
bst_print:
    cbz x0, bst_print_done
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
    ldr x0, [x19, #TREE_LEFT]
    bl bst_print
    adrp x0, fmt_item@PAGE
    add x0, x0, fmt_item@PAGEOFF
    sub sp, sp, #16
    ldr x9, [x19, #TREE_KEY]
    str x9, [sp]                // variadic argument goes on the stack
    bl _printf
    add sp, sp, #16
    ldr x0, [x19, #TREE_RIGHT]
    bl bst_print
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
bst_print_done:
    ret

// struct tree *delete_and_show(struct tree *t, long key)
delete_and_show:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x20, x1
    bl bst_delete
    mov x19, x0                 // the new root
    adrp x0, fmt_delete@PAGE
    add x0, x0, fmt_delete@PAGEOFF
    sub sp, sp, #16
    str x20, [sp]               // variadic argument goes on the stack
    bl _printf                  // printf("delete %ld:", key)
    add sp, sp, #16
    mov x0, x19
    bl bst_print
    mov w0, #10
    bl _putchar
    mov x0, x19
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    bl build_tree
    mov x19, x0

    adrp x0, msg_start@PAGE
    add x0, x0, msg_start@PAGEOFF
    bl _printf
    mov x0, x19
    bl bst_print
    mov w0, #10
    bl _putchar

    mov x0, x19
    mov x1, #20                 // a leaf
    bl delete_and_show
    mov x1, #30                 // now has one child (40)
    bl delete_and_show
    mov x1, #50                 // the root, two children
    bl delete_and_show
    mov x1, #99                 // not in the tree
    bl delete_and_show
    mov x19, x0

    mov x0, x19
    bl bst_free
    mov w0, #0
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .section __TEXT,__const
    .p2align 3
keys:       .quad 50, 30, 70, 20, 40, 60, 80, 35
    .section __TEXT,__cstring
fmt_item:   .asciz " %ld"
fmt_delete: .asciz "delete %ld:"
msg_start:  .asciz "start:"
msg_oom:    .asciz "out of memory"
