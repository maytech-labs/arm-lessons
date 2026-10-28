include ../../../../mk/apple.mk

# ex8.s has no _main: link it with its C driver, compiled with -O2.
ex8: ex8.s ex8_main.c
	$(CC) $(ASFLAGS) -O2 -o $@ $^
