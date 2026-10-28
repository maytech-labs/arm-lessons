include ../../../../mk/linux.mk

CPROGS := $(basename $(wildcard *.c))
all: $(CPROGS)
%: %.c
	$(CC) -g -O2 -pthread -o $@ $<
clean: clean-c
clean-c:
	rm -f $(CPROGS)
