SUBDIRS := $(sort $(dir $(wildcard */Makefile)))
.PHONY: all test clean distclean
.ONESHELL:
all test clean distclean:
	@rc=0
	for d in $(SUBDIRS); do echo "==== $$d :: $@ ===="; $(MAKE) --no-print-directory -C "$$d" $@ || rc=$$?; done
	exit $$rc
