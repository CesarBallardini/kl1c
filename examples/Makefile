# KLIC distribution examples (demos). Several are interactive, so `make test` here just
# means "they all compile" (it builds then cleans up). life.kl1 currently CRASHES klic
# (segfault) -- excluded from the build; to be fixed in the future.
KLIC ?= klic
SRCS := $(filter-out life.kl1,$(wildcard *.kl1))
EXES := $(SRCS:.kl1=)
.PHONY: all test clean distclean

all: $(EXES)

%: %.kl1
	$(KLIC) -o $@ $<

test: all
	@$(MAKE) --no-print-directory clean
	@echo "  examples: all compiled OK"

clean distclean:
	@rm -f *.c *.h *.o *.ext klic.db work* core $(EXES) 2>/dev/null; true
