include ../../../../mk/linux.mk

# This lesson's programs are C files with inline assembly, built with -O2 so
# you see how asm statements interact with the optimiser.
CPROGS := $(basename $(wildcard *.c))
all: $(CPROGS)
%: %.c
	$(CC) -g -O2 -o $@ $<
clean: clean-c
clean-c:
	rm -f $(CPROGS)
