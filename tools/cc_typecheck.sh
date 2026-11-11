#!/bin/sh
# cc_typecheck.sh - type-check units as written, gap regions included.
#
#   tools/cc_typecheck.sh FILE.pas ...
#
# The gate (cc_check.sh) compiles scratch copies with the dpc-gap rewrites
# of tools/cc_gap_rewrites.txt applied, so the regions those rewrites
# replace are never checked.  This runs `dpc --check-only' (which stops
# before code generation) on each unit as it is in the tree, with only the
# inserts' rewrites applied (a shared insert's gap would otherwise stop
# the check before the unit is reached), and prints every error.  Errors
# that are not the logged gaps' messages are real mistakes.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here" || exit 1
: "${DPC:=$HOME/src/domainos-archeology/domain-pascal/target/debug/dpc}"
root=$HOME/src/domainos-archeology/source/tmp/coff_compare/root
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
for ins in $(awk -F'\t' '$1 ~ /\.(ins|pvt)\.pas$/ { print $1 }' tools/cc_gap_rewrites.txt | sort -u); do
  mkdir -p "$scratch/$(dirname "$ins")"
  cp "$ins" "$scratch/$ins"
  awk -F'\t' -v f="$ins" '$1 == f { print $2 }' tools/cc_gap_rewrites.txt |
    while IFS= read -r r; do perl -pi -e "$r" "$scratch/$ins"; done
done
for f in "$@"; do
  echo "== $f"
  (cd "$scratch" && "$DPC" --check-only --root "$root" -I "$here" "$here/$f" 2>&1) |
    grep -a 'error:' | sed "s|$here/||"
  for cfg in cc_a88k; do
    if grep -q "%var cc_a88k" "$f"; then
      echo "== $f (-config $cfg)"
      (cd "$scratch" && "$DPC" --check-only --root "$root" -I "$here" -config $cfg "$here/$f" 2>&1) |
        grep -a 'error:' | sed "s|$here/||"
    fi
  done
done
