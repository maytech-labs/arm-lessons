# Shared build rules for the Linux AArch64 track.
#
# Usage, from a lesson's examples/ or solutions/ directory:
#     include ../../../../mk/linux.mk
#
# Every foo.s in the directory becomes an executable named foo, except files
# listed (without .s) in PARTS before the include: those are pieces of a
# multi-file program, built by the directory's own rules.
# A file that defines `_start:` is a freestanding program (no C library),
# so it is linked with -nostdlib -static. Anything else is linked against libc
# and must define `main`.

CC      ?= gcc
ASFLAGS ?= -g
SRCS    := $(wildcard *.s)
BINS    := $(filter-out $(PARTS),$(SRCS:.s=))

all: $(BINS)

%: %.s
	$(CC) $(ASFLAGS) $(if $(shell grep -l '^_start:' $<),-nostdlib -static) -o $@ $<

clean:
	rm -f $(BINS) *.o

.PHONY: all clean
