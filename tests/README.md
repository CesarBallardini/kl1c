# KL1 / KLIC primitive tests

Unit tests that verify the **primitives** (builtins, methods and messages) of the `klic` built in
this repo behave according to the **reference manual** `biblio/KLIC.info.txt` (the texinfo manual
from the `klic-doc` package, "Predicate Index").

Motivation: porting `klic` to a modern toolchain (gcc 14, see `Dockerfile`) risks subtle regressions.
These tests already uncovered one: `builtin:print/1` crashed on compound terms (gcc 14 `-O2`
miscompiled `klic_fprintf`'s "fake varargs"); it was fixed in source with `debian/patch6.print-varargs`
(case `io/print`).

## Two-pass strategy

- **Pass 1 (done):** one case per primitive; the deterministic ones got a locked `.expected` → PASS.
- **Pass 2 (done):** the failing ones were resolved by fixing the API usage (file streams, unix,
  timer, module/predicate objects), and the ones that are not hermetically testable were **excluded**
  (see below). The runner marks a `.kl1` without an `.expected` as PENDING (does not fail the suite);
  currently none remain.

Current state: **75 PASS · 0 FAIL · 0 PENDING** (75 cases, 17 categories), including edge cases.

## How to run

Inside the `kl1c` container, with the repo mounted at `/work`:

```bash
# Linux/macOS/WSL
docker run --rm -v "$PWD":/work kl1c bash -c 'cd /work/tests && sh run.sh'
# Windows Git Bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c bash -c 'cd /work/tests && sh run.sh'

# Only some categories:              ... sh run.sh comparison float
# Adjust the per-case timeout (sec): ... TIMEOUT=15 sh run.sh
```

`run.sh` exits 0 when there is no FAIL (PENDING does not count as failure). Each case runs under a
`timeout` so it can't hang on primitives that wait for a tty/process/socket (unix, sockets, `wait`).

## Structure

Folders by **category**. Each `<category>/<case>.kl1` has its `<category>/<case>.expected` (reference
output derived from the manual). No `.expected` ⇒ PENDING. Tests print with `klicio` + `putt`. Guards
(comparison, types) are tested through the clause that commits; object methods (vectors, strings,
floats, timer) are invoked as `generic:METHOD(OBJ, ...)` in the body.

### Categories and PASS coverage (55 core + 20 more)

- `arithmetic/` — `:=` (`+ - * / mod`, unary, negatives, precedence), bitwise (`/\ \/ xor << >>`),
  integer comparison (`> >= =:= =\= =< <`), edge cases.
- `comparison/` — `@< @=< @> @>=`, `\=`, `=`, `compare/3` (incl. identical terms), `hash/2`.
- `types/` — `atom integer float list atomic`; edges: `list([])` is false (`[]` is a special nil);
  floats/strings/vectors are NOT atomic.
- `unification/` — `=/2`, `putt`, `unbound/2`.
- `functors/` — `functor/3` (atom/number/list → arity 0, list is `'.'/2`), `arg/3`, `setarg/4`,
  `=../2`, `new_functor/3`.
- `float/` — `add subtract multiply divide sqrt pow sin cos tan asin acos atan sinh cosh tanh exp log
  floor ceil`, comparison (`less_than equal greater_than not_*`), `$` operators, `int()` conversion.
- `aggregates/` — vectors (`{..}`, `element size set_element new_vector vector_element split join`,
  empty, nested) and strings (`".."`, `string_element element_size set_element new_string split join
  search_character string_less_than string_not_less_than`, empty).
- `atoms/` — `make_atom get_atom_string get_atom_name intern atom_number`.
- `io/` — `putt puttq putc nl fwrite fflush`, `builtin:print` (compound/nested — patch6 regression),
  quoted atoms, `[]`, negatives, mixed structures.
- `streams/` — file I/O with the message-difference-list stream model: `write_open/read_open/
  append_open`, `gett getwt getc ungetc fread linecount` (round-trip: write to `/tmp`, close with
  `fclose`+`wait`, read back).
- `unix/` — `unix:unix([...])`: `system` (raw wait() status), `access`, `cd`, `unlink` (deterministic
  status codes; the tests create their own files).
- `timer/` — `timer:add/sub/compare` over `time/3` with fixed values.
- `meta/` — module object (`generic:new(module,_,main)` + `name`), predicate object
  (`predicate#(main:o/1)` + `arity`/`name`), `generic:apply`.
- `merge/ random/ status/ sync/` — `merge:new`, `random_numbers:new`, `current_priority current_node`,
  `wait` (minimal cases).

## Primitives NOT tested (non-hermetic / non-deterministic)

Excluded on purpose because their result depends on the environment, the clock, external processes,
or has side effects not observable deterministically:

- **Unix with external state:** `getenv`/`putenv` (environment), `mktemp` (random name), `argc`/`argv`
  (invocation), `fork`/`fork_with_pipes`/`kill`/`system` with effects, `bind`/`connect`/`accept`
  (sockets), `signal_stream`, `chmod`/`umask`, `stdin`.
- **Timer with real clock:** `get_time_of_day`, `instantiate_at`/`after`/`every`.
- **System control:** `gc` (free memory — non-deterministic), `postmortem`.
- **Non-deterministic:** `random_numbers` (beyond "it creates"), variable `wrap`/`unwrap`.
- **Operator streams:** `addop`/`rmop` (per-stream operator tables).
- **C-like I/O duplicates:** `putc/getc/fwrite/fread/fseek/ftell/feof/fflush/fclose/sync` on C-like
  streams are equivalent to their Prolog-like versions already covered in `streams/`.

See the "Predicate Index" of `biblio/KLIC.info.txt` for the complete list.

## Semantics notes (confirmed against the manual)

- `compare/3` and `@<` over **atoms** use the internal atom number (creation order), not alphabetical
  order → the cases use **integers** for determinism.
- No implicit int/float conversion (they are separate types).
- Integer division truncates toward zero (`-7/2 = -3`); `mod` follows the dividend's sign.
- `putt` and `puttq` currently behave the same (both quote; the manual warns about this).
- `unbound/2` returns `{X}` when the top is bound; otherwise `{ADDR1,ADDR2,X}` (non-deterministic).
- **Confirmed edge cases:** `int(F)` truncates toward zero; `atomic/1` is true only for integers and
  atoms; `list([])` is false; `functor` of an atom/number has arity 0 and lists are `'.'/2`; `=..[N]`
  with numeric N returns N; integer overflow is ignored (wraps).
- **klic bug found (documented in `types/atomic_kinds.kl1`):** applying a type guard to a **literal**
  float/string/vector (e.g. `atomic(1.5)`, `atomic({a})`) **crashes** the `kl1cmp` compiler. The
  workaround is to pass the value via a variable. (Separate from the already-fixed `builtin:print`
  bug on compound terms, `patch6`.)
