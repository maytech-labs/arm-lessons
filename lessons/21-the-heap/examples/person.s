// person.s - heap-allocated structs with a constructor and a destructor (lesson 21)
//
// Build: make person
// Run:   ./person
// Expected output:
//   Ada is 36
//   Linus is 28
//   Linus is 29

// struct Person { char *name; long age; };
    .equ PERSON_NAME, 0
    .equ PERSON_AGE,  8
    .equ PERSON_SIZE, 16

    .section .rodata
name_ada:
    .asciz "Ada"
name_linus:
    .asciz "Linus"
fmt:
    .asciz "%s is %ld\n"

    .text
    .p2align 2

// struct Person *person_new(const char *name, long age)
// Returns a new Person that owns its own copy of name, or NULL.
// The caller owns the result and must give it to person_free.
person_new:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = name, x20 = age
    stp x21, x22, [sp, #32]         // x21 = p, x22 = strlen(name) + 1
    mov x19, x0
    mov x20, x1

    mov  x0, #PERSON_SIZE           // p = malloc(sizeof(struct Person));
    bl   malloc
    cbz  x0, person_new_done        // return NULL
    mov  x21, x0

    mov  x0, x19                    // n = strlen(name) + 1;   +1 for the '\0'
    bl   strlen
    add  x22, x0, #1

    mov  x0, x22                    // p->name = malloc(n);
    bl   malloc
    cbz  x0, person_new_fail
    str  x0, [x21, #PERSON_NAME]

    mov  x1, x19                    // memcpy(p->name, name, n);   x0 is p->name
    mov  x2, x22
    bl   memcpy

    str  x20, [x21, #PERSON_AGE]    // p->age = age;
    mov  x0, x21                    // return p;
person_new_done:
    ldp  x21, x22, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #48
    ret
person_new_fail:
    mov  x0, x21                    // free(p); return NULL;   do not leak half an object
    bl   free
    mov  x0, #0
    b    person_new_done

// void person_free(struct Person *p): free what p owns, then p itself
person_free:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    cbz x0, person_free_done        // person_free(NULL) does nothing, like free
    mov x19, x0
    ldr  x0, [x19, #PERSON_NAME]    // free(p->name);   first the parts...
    bl   free
    mov  x0, x19                    // free(p);         ...then the whole
    bl   free
person_free_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

// void person_print(const struct Person *p)
person_print:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    ldr  x1, [x0, #PERSON_NAME]
    ldr  x2, [x0, #PERSON_AGE]
    adrp x0, fmt
    add  x0, x0, :lo12:fmt
    bl   printf
    ldp  x29, x30, [sp], #16
    ret

    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = a, x20 = b

    adrp x0, name_ada               // a = person_new("Ada", 36);
    add  x0, x0, :lo12:name_ada
    mov  x1, #36
    bl   person_new
    cbz  x0, main_fail
    mov  x19, x0

    adrp x0, name_linus             // b = person_new("Linus", 28);
    add  x0, x0, :lo12:name_linus
    mov  x1, #28
    bl   person_new
    cbz  x0, main_fail_b
    mov  x20, x0

    mov  x0, x19
    bl   person_print
    mov  x0, x20
    bl   person_print

    ldr  x0, [x20, #PERSON_AGE]     // b->age++;
    add  x0, x0, #1
    str  x0, [x20, #PERSON_AGE]
    mov  x0, x20
    bl   person_print

    mov  x0, x19                    // person_free(a);
    bl   person_free
    mov  x0, x20                    // person_free(b);
    bl   person_free
    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail_b:
    mov  x0, x19
    bl   person_free
main_fail:
    mov  w0, #1
    b    main_done
