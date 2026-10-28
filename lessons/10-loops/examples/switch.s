// switch.s - a switch statement as a chain of compares.
//
// C:      long a = 12, b = 4, op = '*', r;
//         switch (op) {
//         case '+': r = a + b; break;
//         case '-': r = a - b; break;
//         case '*': r = a * b; break;
//         case '/': r = a / b; break;
//         default:  r = 0;     break;
//         }
//         return r;
// Build:  make
// Run:    ./switch; echo $?
// Expect: exit status 48. With op = '+': 16, '-': 8, '/': 3, '%': 0.

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #12                 // a = 12
    mov x2, #4                  // b = 4
    mov x3, #'*'                // op = '*'

    cmp x3, #'+'                // case '+' ?
    b.eq case_add               //   yes: go to its code
    cmp x3, #'-'                // case '-' ?
    b.eq case_sub               //   yes: go to its code
    cmp x3, #'*'                // case '*' ?
    b.eq case_mul               //   yes: go to its code
    cmp x3, #'/'                // case '/' ?
    b.eq case_div               //   yes: go to its code
    b case_default              // no case matched

case_add:
    add x0, x1, x2              // r = a + b
    b end_switch                // break
case_sub:
    sub x0, x1, x2              // r = a - b
    b end_switch                // break
case_mul:
    mul x0, x1, x2              // r = a * b
    b end_switch                // break
case_div:
    sdiv x0, x1, x2             // r = a / b
    b end_switch                // break
case_default:
    mov x0, #0                  // r = 0
end_switch:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(r)
