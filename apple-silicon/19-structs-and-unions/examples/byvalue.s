// byvalue.s - passing and returning structs by value (with byvalue_main.c) (macOS).
//
//   struct pair { long a, b; };          16 bytes: passed and returned in registers
//   struct triple { long a, b, c; };     24 bytes: passed and returned in memory
//
//   struct pair   swap_pair(struct pair p);        p in x0:x1, result in x0:x1
//   long          sum_triple(struct triple t);     caller passes a POINTER to a copy, in x0
//   struct triple make_triple(long a, long b, long c);
//                                                  caller passes the result address in x8
//
// Build:  make
// Run:    ./byvalue
// Expected output:
//   swap_pair({1, 2}) = {2, 1}
//   sum_triple({10, 20, 30}) = 60
//   make_triple(7, 8, 9) = {7, 8, 9}

    .global _swap_pair
    .global _sum_triple
    .global _make_triple
    .text
    .p2align 2

// struct pair swap_pair(struct pair p): p.a in x0, p.b in x1
_swap_pair:
    mov x9, x0
    mov x0, x1                  // result.a = p.b
    mov x1, x9                  // result.b = p.a
    ret

// long sum_triple(struct triple t): too big for registers, so x0 = &copy
_sum_triple:
    ldp x9, x10, [x0]           // t.a, t.b
    ldr x11, [x0, #16]          // t.c
    add x0, x9, x10
    add x0, x0, x11
    ret

// struct triple make_triple(long a, long b, long c): x8 = where to write it
_make_triple:
    stp x0, x1, [x8]            // result->a, result->b
    str x2, [x8, #16]           // result->c
    ret
