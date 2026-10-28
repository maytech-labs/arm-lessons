include ../../../../mk/apple.mk

# c11 is built from C, at -O2, so its disassembly is worth reading.
all: c11

c11: c11.c
	$(CC) -O2 -o $@ $<

clean: clean-c11

clean-c11:
	rm -f c11
	rm -rf c11.dSYM

.PHONY: clean-c11
