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
# units only cc.a88k has (docs/survey-tables.md's "only in cc.a88k"
# line: the PRISM back end, the ISC, exs) are checked with -config
# cc_a88k only, as the gate compiles them (the prelude's inserts test
# cc_a88k: cargs.ins.pas's options differ)
a88k_only=$(grep -a '^only in cc.a88k:' docs/survey-tables.md)
for f in "$@"; do
  case "$a88k_only" in
    *"\`$f\`"*)
      echo "== $f (cc.a88k only: -config cc_a88k)"
      (cd "$scratch" && "$DPC" --check-only --root "$root" -I "$here" -config cc_a88k -- "$here/$f" 2>&1) |
        grep -a 'error:' | sed "s|$here/||"
      continue ;;
  esac
  echo "== $f"
  (cd "$scratch" && "$DPC" --check-only --root "$root" -I "$here" "$here/$f" 2>&1) |
    grep -a 'error:' | sed "s|$here/||"
  for cfg in cc_a88k; do
    if grep -q "%var cc_a88k" "$f"; then
      echo "== $f (-config $cfg)"
      (cd "$scratch" && "$DPC" --check-only --root "$root" -I "$here" -config $cfg -- "$here/$f" 2>&1) |
        grep -a 'error:' | sed "s|$here/||"
    fi
  done
done
