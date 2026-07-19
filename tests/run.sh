#!/bin/sh
# Runner for the KL1/KLIC primitive tests.
#
# Runs INSIDE the kl1c container, with the repo mounted at /work:
#   MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/work kl1c bash -c 'cd /work/tests && sh run.sh'
#
# Tests are grouped in folders by CATEGORY (arithmetic/, comparison/, float/, ...).
# For each <category>/<case>.kl1:
#   - if <case>.expected exists: compile+run and compare stdout  -> PASS / FAIL.
#   - if NO .expected exists: run it anyway and CLASSIFY the output -> PENDING
#     (OK = clean output, a candidate to lock as expected; BAD = crash/suspend/empty).
#     This supports the "first pass": one test per primitive to see the landscape.
# Optional category filter:   sh run.sh comparison float
set -u
cd "$(dirname "$0")" || exit 2
TIMEOUT=${TIMEOUT:-10}   # seconds per case (avoids hangs: wait/fork/sockets/tty)
pass=0; fail=0; pend_ok=0; pend_bad=0; failed=""

haveto=$(command -v timeout >/dev/null 2>&1 && echo yes || echo no)
# Run ./NAME with a hard wall-clock limit so a suspending primitive (tty/proc/socket)
# can't hang the whole suite. Use coreutils `timeout` if present; otherwise a portable
# background watchdog that kills the child after $TIMEOUT.
runexe() {
  if [ "$haveto" = yes ]; then
    timeout "$TIMEOUT" ./"$1" </dev/null 2>&1
  else
    ./"$1" </dev/null >/tmp/klic-run.$$ 2>&1 & rp=$!
    ( sleep "$TIMEOUT"; kill -9 "$rp" 2>/dev/null ) & wp=$!
    wait "$rp" 2>/dev/null; rr=$?
    kill "$wp" 2>/dev/null; wait "$wp" 2>/dev/null
    cat /tmp/klic-run.$$; rm -f /tmp/klic-run.$$
    return "$rr"
  fi
}
clean() { rm -f -- *.c *.h *.o *.ext klic.db work* core 2>/dev/null; rm -f -- "$1" 2>/dev/null; }

if [ "$#" -gt 0 ]; then cats="$*"; else cats=$(for d in */; do [ -n "$(ls "$d"*.kl1 2>/dev/null)" ] && echo "${d%/}"; done); fi

for cat in $cats; do
  [ -d "$cat" ] || { echo "?? no such category: $cat"; continue; }
  echo "== $cat =="
  for src in "$cat"/*.kl1; do
    [ -e "$src" ] || continue
    name=$(basename "$src" .kl1); exp="$cat/$name.expected"
    if ! ( cd "$cat" && klic -o "$name" "$name.kl1" ) >/tmp/klic-$name.log 2>&1; then
      ( cd "$cat" && clean "$name" )
      if [ -f "$exp" ]; then echo "  COMPILE-FAIL  $name"; fail=$((fail+1)); failed="$failed $cat/$name"
      else echo "  PENDING-BAD   $name  [compile-fail]"; pend_bad=$((pend_bad+1)); fi
      continue; fi
    got=$( cd "$cat" && runexe "$name" ); rc=$?
    ( cd "$cat" && clean "$name" )
    if [ -f "$exp" ]; then
      want=$(cat "$exp")
      if [ "$got" = "$want" ]; then echo "  PASS          $name"; pass=$((pass+1))
      else echo "  FAIL          $name  got=[$got]  want=[$want]"; fail=$((fail+1)); failed="$failed $cat/$name"; fi
    else
      # PENDING: no expected yet. Classify by REAL klic failure signatures
      # (not just any "error" in the output, which could be a legitimate atom).
      bad=no
      [ "$rc" -ne 0 ] && bad=yes
      case "$got" in *"Fatal Error"*|*suspending*|*"core dumped"*|*Segmentation*|"") bad=yes;; esac
      if [ "$bad" = no ]; then echo "  PENDING-OK    $name  got=[$got]"; pend_ok=$((pend_ok+1))
      else echo "  PENDING-BAD   $name  [${got%%|*}]"; pend_bad=$((pend_bad+1)); fi
    fi
  done
done
echo "-----------------------------------------------------------"
echo "PASS=$pass  FAIL=$fail  PENDING(ok=$pend_ok bad=$pend_bad)"
[ -n "$failed" ] && echo "failed:$failed"
[ "$fail" -eq 0 ]
