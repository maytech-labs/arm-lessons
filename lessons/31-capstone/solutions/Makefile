# Each capstone project lives in its own directory with its own Makefile.
# `make` and `make clean` here run the same target in every one of them.

PROJECTS := wc rpn wordfreq life bf

all clean:
	for p in $(PROJECTS); do $(MAKE) -C $$p $@ || exit 1; done

.PHONY: all clean
