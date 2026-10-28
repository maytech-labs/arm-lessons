// greet_main.c - calls greet() from greet.s.
// Build: make greet

void greet(const char *name, int times);

int main(void) {
    greet("world", 1);
    greet("Ada", 2);
    return 0;
}
