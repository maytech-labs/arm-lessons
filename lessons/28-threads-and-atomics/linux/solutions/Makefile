include ../../../../mk/linux.mk

# Every solution starts threads, so link them all with -pthread.
# This rule replaces the shared %: %.s rule from linux.mk.
%: %.s
	$(CC) $(ASFLAGS) -pthread -o $@ $<
