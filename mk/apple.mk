# Shared build rules for the Apple Silicon (macOS arm64) track.
#
# Usage, from a lesson's examples/ or solutions/ directory:
#     include ../../../mk/apple.mk
#
# Every foo.s in the directory becomes an executable named foo, except files
# listed (without .s) in PARTS before the include: those are pieces of a
# multi-file program, built by the directory's own rules.
# macOS always links against libSystem, so every program defines `_main`.

CC      := clang
ASFLAGS ?= -g -arch arm64
SRCS    := $(wildcard *.s)
BINS    := $(filter-out $(PARTS),$(SRCS:.s=))

all: $(BINS)

%: %.s
	$(CC) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(BINS) *.o
	rm -rf *.dSYM

.PHONY: all clean
