# Top-level convenience targets. Run inside the kl1c container (repo mounted at /work).
#   make all   -> recursively build every KL1 program (examples + book examples).
#   make test  -> recursively run every test/example (tests/ compares .expected).
# Recurses into each subdir and runs the same target there.
SUBDIRS := examples agent-oriented-programming tests
.PHONY: all test clean distclean
.ONESHELL:
all test clean distclean:
	@rc=0
	for d in $(SUBDIRS); do echo "#### $$d :: $@ ####"; $(MAKE) --no-print-directory -C "$$d" $@ || rc=$$?; done
	exit $$rc
