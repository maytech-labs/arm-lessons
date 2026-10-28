// bitfields_main.c - sets bit fields in C, reads and writes one from assembly.
#include <stdio.h>
#include <string.h>

struct perms { unsigned read : 1; unsigned write : 1; unsigned mode : 4; };

unsigned get_mode(const struct perms *p);
void set_mode(struct perms *p, unsigned mode);

static unsigned raw(const struct perms *p) { unsigned u; memcpy(&u, p, 4); return u; }

int main(void) {
    struct perms p = {0};
    p.read = 1; p.write = 0; p.mode = 5;
    printf("read %u, write %u, mode %u (raw 0x%x)\n", p.read, p.write, get_mode(&p), raw(&p));
    set_mode(&p, 9);
    printf("after set_mode(9): read %u, write %u, mode %u (raw 0x%x)\n",
           p.read, p.write, p.mode, raw(&p));
    return 0;
}
