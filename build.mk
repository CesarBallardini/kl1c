# Shared leaf rules (included by each leaf directory's Makefile).
#   make all   -> build every *.kl1 in this directory
#   make test  -> compile+run each *.kl1; if <name>.expected exists, compare stdout
#                 (unit test); otherwise just check it runs without crashing.
#   make clean -> remove generated files
KLIC ?= klic
SKIP ?=
SRCS := $(filter-out $(SKIP),$(wildcard *.kl1))
EXES := $(SRCS:.kl1=)
.PHONY: all test clean distclean
.ONESHELL:

all: $(EXES)

%: %.kl1
	$(KLIC) -o $@ $<

test:
	@rc=0
	for s in $(SRCS); do
	  n=$${s%.kl1}
	  if $(KLIC) -o "$$n" "$$s" >/tmp/klic-test.log 2>&1; then
	    got=$$(timeout 15 ./"$$n" </dev/null 2>&1); grc=$$?
	    if [ -f "$$n.expected" ]; then
	      if [ "$$got" = "$$(cat "$$n.expected")" ]; then echo "  PASS  $$n"; else echo "  FAIL  $$n  got=[$$got]  want=[$$(cat "$$n.expected")]"; rc=1; fi
	    elif [ "$$grc" -eq 0 ]; then echo "  RUN   $$n  -> $$got"
	    else echo "  CRASH $$n  (exit $$grc)"; rc=1; fi
	  else echo "  CFAIL $$n"; rc=1; fi
	  rm -f "$$n" *.c *.h *.o *.ext klic.db work* core 2>/dev/null
	done
	exit $$rc

clean distclean:
	@rm -f *.c *.h *.o *.ext klic.db work* core $(EXES) 2>/dev/null; true
