include ../../../mk/linux.mk

# Every program in this directory starts threads, so link them all with
# -pthread. This rule replaces the shared %: %.s rule from linux.mk.
%: %.s
	$(CC) $(ASFLAGS) -pthread -o $@ $<

# c11 is built from C, at -O2, so its disassembly is worth reading.
all: c11

c11: c11.c
	$(CC) -O2 -pthread -o $@ $<

clean: clean-c11

clean-c11:
	rm -f c11

.PHONY: clean-c11
