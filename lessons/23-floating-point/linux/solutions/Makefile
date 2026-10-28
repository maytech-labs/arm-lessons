include ../../../../mk/linux.mk

# sqrt lives in the math library: link it with -lm.
ex6: ex6.s
	$(CC) $(ASFLAGS) -o $@ $< -lm
