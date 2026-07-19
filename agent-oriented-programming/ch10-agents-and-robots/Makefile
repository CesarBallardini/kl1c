# KL1/GDC examples from the Huntbach & Ringwood book -- one executable per *.kl1.
# Output via klicio+putt (see each .kl1's comments).
KLIC = klic
SOURCES := $(wildcard *.kl1)
EXES = $(SOURCES:%.kl1=%)

all: $(EXES)

%: %.kl1
	$(KLIC) -o $@ $<

clean:
	rm -f *.c *.ext *.h *.o work* *~ core klic.db

distclean: clean
	rm -f $(EXES)

.PHONY: all clean distclean
