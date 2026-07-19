# Recursive builder: delegates to each chapter's Makefile (ch*/).
#   make            build all examples of all chapters
#   make -C ch03-metamorphosis qsort   build a single one
CHAPTERS := $(sort $(dir $(wildcard ch*/Makefile)))

all clean distclean:
	@for d in $(CHAPTERS); do echo "== $$d =="; $(MAKE) -C $$d $@ || exit $$?; done

.PHONY: all clean distclean
