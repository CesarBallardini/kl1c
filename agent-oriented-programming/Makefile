SUBDIRS := $(sort $(dir $(wildcard ch*/Makefile)))
.PHONY: all test clean distclean
# One shell command (backslash-continued), not .ONESHELL: -- Trusty's GNU Make 3.81
# ignores .ONESHELL, which would drop the exit-code aggregation across lines.
all test clean distclean:
	@rc=0; \
	for d in $(SUBDIRS); do echo "==== $$d :: $@ ===="; $(MAKE) --no-print-directory -C "$$d" $@ || rc=$$?; done; \
	exit $$rc
