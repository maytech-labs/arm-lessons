// tail_call.s - a recursive call as the very last action can be a plain b.
//
// C:      unsigned long gcd(unsigned long a, unsigned long b) {
//             if (b == 0) return a;
//             return gcd(b, a % b);           // the call is the last thing
//         }
//         exit(gcd(1071, 462));
//
// Build:  make
// Run:    ./tail_call; echo $?
// Exit status (echo $?): 21

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #1071
    mov x1, #462
    bl gcd
    mov x8, #93
    svc #0

// unsigned long gcd(unsigned long a, unsigned long b)
//   The recursive call is a TAIL call: nothing happens after it. So instead
//   of bl (which needs a frame to save x30), set up the arguments and b.
//   gcd's eventual ret then returns straight to our original caller.
//   No frame, no stack growth, however deep the "recursion".
gcd:
    cbz x1, gcd_done
    udiv x2, x0, x1
    msub x2, x2, x1, x0         // x2 = a % b
    mov x0, x1                  // new a = b
    mov x1, x2                  // new b = a % b
    b gcd                       // tail call: jump, do not link
gcd_done:
    ret                         // x0 = a
