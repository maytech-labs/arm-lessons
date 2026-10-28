PARTS := stack
include ../../../../mk/linux.mk

ex4: ex4.s stack.s
	$(CC) $(ASFLAGS) -o $@ ex4.s stack.s
