// bitfields.s - reading and writing C bit fields (with bitfields_main.c) (macOS).
//
//   struct perms {                  // all three fields share one 32-bit unit
//       unsigned read  : 1;         // bit 0
//       unsigned write : 1;         // bit 1
//       unsigned mode  : 4;         // bits 2-5
//   };
//
//   unsigned get_mode(const struct perms *p);
//   void     set_mode(struct perms *p, unsigned mode);
//
// Build:  make
// Run:    ./bitfields
// Expected output:
//   read 1, write 0, mode 5 (raw 0x15)
//   after set_mode(9): read 1, write 0, mode 9 (raw 0x25)

    .global _get_mode
    .global _set_mode
    .text
    .p2align 2

// unsigned get_mode(const struct perms *p)
_get_mode:
    ldr w9, [x0]
    ubfx w0, w9, #2, #4         // bits 2-5
    ret

// void set_mode(struct perms *p, unsigned mode)
_set_mode:
    ldr w9, [x0]                // read the whole unit...
    bfi w9, w1, #2, #4          // ...replace bits 2-5 with the low 4 bits of mode...
    str w9, [x0]                // ...and write it back: the other fields are kept
    ret
