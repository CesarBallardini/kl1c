# KL1/GDC examples from Huntbach & Ringwood's book

KL1 programs transcribed and adapted from the book:

> Matthew M. Huntbach, Graem A. Ringwood,
> *Agent-Oriented Programming: From Prolog to Guarded Definite Clauses*,
> Springer LNAI 1630, 1999.
> (Full text converted to Markdown in `../biblio/Agent-Oriented-Programming-*.md`.)

## Organization by chapter

One directory per chapter with code listings (chapters 1-2 are conceptual):

| Folder                                         | Chapter                                 |
|------------------------------------------------|-----------------------------------------|
| `ch03-metamorphosis/`                          | 3. Metamorphosis (Prolog → GDC)         |
| `ch04-event-driven-condition-synchronization/` | 4. Event Driven Condition Synchronization |
| `ch05-actors-and-agents/`                      | 5. Actors and Agents                    |
| `ch06-concurrent-search/`                      | 6. Concurrent Search                    |
| `ch07-distributed-constraint-solving/`         | 7. Distributed Constraint Solving       |
| `ch08-meta-interpretation/`                    | 8. Meta-interpretation                  |
| `ch09-partial-evaluation/`                     | 9. Partial Evaluation                   |
| `ch10-agents-and-robots/`                      | 10. Agents and Robots                   |

## How to compile and run

Same as `../examples/` (see `../examples/README.md` for the Vagrant / Docker details). The root
`Makefile` is recursive; each chapter has its own (auto-discovers `*.kl1`):

```bash
make                                  # build ALL chapters
make -C ch04-event-driven-condition-synchronization primes_sieve
./ch04-event-driven-condition-synchronization/primes_sieve   # -> [2,3,5,7,11,13,17,19,23,29]
make clean        # remove intermediates (keeps executables)
make distclean    # also remove the executables
```

## Transcription conventions

- **Faithful + runnable** (chosen style): each `.kl1` runs under `klic` and carries in its header
  comment the **verbatim book listing** (GDC and/or Prolog) with the **page citation** (printed and
  PDF), plus the adaptations made.
- **GDC → klic KL1 dialect translation:** the book writes guards with the instance operator `«`
  (pattern in the *guard*), e.g. `qsort(U,S) :- []«U | S=[].`. klic has no `«`: the matching goes in
  the *head*. Arithmetic is also adjusted (`:=`, `mod`, `=\=`).
- **Output via `klicio` + `putt`** (the method documented in `KLIC.info`, used by the KLIC
  distribution examples). Historical note: `builtin:print`/`print` crashed on compound terms (lists,
  functors) due to a gcc 14 `-O2` miscompilation; it is **now fixed** in source with
  `debian/patch6.print-varargs` (see `../2026-07-18-estado-build-docker.md`, risk 6, and `../tests/`).
  The examples keep using `putt` as the canonical method. `io:outstream` is NOT a documented KLIC
  builtin (it does not appear in `KLIC.info`).

## Examples present

| File                                                | What it is                               | Book citation       |
|-----------------------------------------------------|------------------------------------------|---------------------|
| `ch03-metamorphosis/not.kl1`                        | NOT gate (committed choice)              | §3.10               |
| `ch03-metamorphosis/qsort.kl1`                      | naive quicksort (with `append`/`conc`)   | §3.10, pp. 88-91    |
| `ch04-.../qsort_dl.kl1`                             | difference-list quicksort                | §4.7, pp. 121-122   |
| `ch04-.../bank_account.kl1`                         | bank account (object/server)             | §4.8, p. 122        |
| `ch04-.../primes_sieve.kl1`                         | Sieve of Eratosthenes (streams)          | §4.1, pp. 104-105   |

(Growing: listings from the remaining chapters will keep being added.)
