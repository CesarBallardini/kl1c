#!/bin/sh
# Install the newest klic + klic-doc packages present in this directory.
#
# Multiple builds accumulate here as the Debian revision is bumped
# (e.g. klic_3.003-gm1-4.1_i386.deb, then klic_3.003-gm1-4.1+kl1c1_i386.deb).
# This script selects the highest version of each package using Debian version
# comparison (dpkg --compare-versions) -- NOT filename sorting, which would
# mis-order '+kl1c1' vs the plain '_i386' suffix -- so the latest build always wins.
#
# Usage:  ./install-latest.sh          (run from anywhere; it cd's to its own dir)
set -e
cd "$(dirname "$0")"

# Print the highest-version .deb matching the glob in $1.
pick() {
  best=; bestv=
  for f in $1; do
    [ -e "$f" ] || continue
    v=$(dpkg-deb -f "$f" Version)
    if [ -z "$bestv" ] || dpkg --compare-versions "$v" gt "$bestv"; then
      bestv=$v; best=$f
    fi
  done
  [ -n "$best" ] || { echo "install-latest.sh: no .deb matching '$1' in $(pwd)" >&2; exit 1; }
  echo "$best"
}

klic=$(pick 'klic_*_i386.deb')
doc=$(pick 'klic-doc_*_all.deb')
echo "Installing $klic and $doc ..."
sudo dpkg -i "$klic" "$doc"
