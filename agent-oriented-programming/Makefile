# Makefile
#
KLIC=klic

SOURCES=not.kl1 qsort.kl1

EXES = $(SOURCES:%.kl1=%)


%: %.kl1
        $(KLIC) -o $@ $<

clean:
	rm -f *.c *.ext *.h *.o work* *~ core klic.db

distclean: clean
        rm -f $(EXES)

realclean: distclean

