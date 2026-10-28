include ../../../../mk/linux.mk

# sqrt, pow and floor live in the math library: link it with -lm.
math_lib: math_lib.s
	$(CC) $(ASFLAGS) -o $@ $< -lm
