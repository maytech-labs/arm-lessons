// ex9_main.c - Exercise 16.9: calls print_table() from ex9.s.
void print_table(const char *title, const int *values, int n);

int main(void) {
    int primes[] = {2, 3, 5, 7};
    int temps[] = {-3, 0, 12};
    print_table("Primes", primes, 4);
    print_table("Temperatures", temps, 3);
    return 0;
}
