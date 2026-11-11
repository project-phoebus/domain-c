#!/bin/sh
# cc_check.sh - compile each translated unit with dpc (best effort) and
# compare it with its unit in cc.m68k and cc.a88k (tools/coff_compare.py).
#
#   tools/cc_check.sh [FILE.pas ...]     (default: every unit file in the tree)
#
# A unit file is a .pas that is not an insert (*.ins.pas, *.pvt.pas) under
# the tree's source roots.  A unit missing from a binary is skipped for it.
# dpc errors fail the check; best-effort warnings do not.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here" || exit 1
: "${DPC:=$HOME/src/domainos-archeology/domain-pascal/target/debug/dpc}"
export DPC
m68k=ctape/install/ri.apollo.cc.v.6.9.m/cc.m68k
a88k=ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k
if [ $# -eq 0 ]; then
  set -- $(find lang lang2 ivory us us1 moon_unit misc_server -name '*.pas' \
             ! -name '*.ins.pas' ! -name '*.pvt.pas' 2>/dev/null | sort)
fi
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
fail=0
for f in "$@"; do
  # dpc gaps (docs/dpc-gaps.md): compile a rewritten scratch copy, named
  # as the unit (coff_compare picks the binary's unit by the file name)
  src=$f
  rules=$(awk -F'\t' -v f="$f" '$1 == f { print $2 }' tools/cc_gap_rewrites.txt)
  if [ -n "$rules" ]; then
    src=$scratch/$(basename "$f")
    cp "$f" "$src"
    printf '%s\n' "$rules" | while IFS= read -r r; do perl -pi -e "$r" "$src"; done
  fi
  for bin in $m68k $a88k; do
    out=$(python3 tools/coff_compare.py --binary "$bin" "$src" -- -I "$here" 2>&1)
    rc=$?
    case "$out" in
      *"no single unit"*) continue ;;
    esac
    errs=$(printf '%s\n' "$out" | grep -c ': error:')
    warns=$(printf '%s\n' "$out" | grep -c 'best effort')
    summary=$(printf '%s\n' "$out" | grep 'routine(s):' | tail -1)
    printf '%-50s %-8s rc=%d errors=%d best-effort=%d  %s\n' \
      "$f" "$(basename "$bin")" "$rc" "$errs" "$warns" "$summary"
    if [ "$rc" -ne 0 ] || [ "$errs" -ne 0 ]; then
      printf '%s\n' "$out" | grep -A3 ': error:' | head -20
      fail=1
    fi
  done
done
python3 tools/cc_addrcheck.py "$@" || fail=1
exit $fail
