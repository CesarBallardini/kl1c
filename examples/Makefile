# Makefile
#

# Para construir un ejecutable, hacer:
#
# make turtles     # construye el ejecutable para turtles.kl1
# ./turtles        # ejecuta el programa
# make clean       # elimina los archivos auxiliares, deja los ejecutables
# make distclean   # elimina hasta los ejecutables

KLIC=klic

SOURCES=atomfunc.kl1 client.kl1 cmac.kl1 deriv.kl1 fact.kl1 hanoi.kl1 iotest.kl1 kkqueen.kl1 life.kl1 \
        mastermind.kl1 merge.kl1 parsetest.kl1 pascal.kl1 pp.kl1 primes.kl1 primesp.kl1 prio.kl1 \
        puzzle.kl1 qlay.kl1 qsort.kl1 server.kl1 turtles.kl1 vecstr.kl1 wave.kl1

EXES = $(SOURCES:%.kl1=%)


%: %.kl1
	$(KLIC) -o $@ $<

clean:
	rm -f *.c *.ext *.h *.o work* *~ core klic.db

distclean: clean
	rm -f $(EXES)

realclean: distclean
