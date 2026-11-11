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
# dpc gaps in inserts: a rule whose file is an insert (*.ins.pas,
# *.pvt.pas) rewrites a scratch copy of it at its tree path under
# $scratch/inc, which every unit's compilation searches first: dpc looks
# an include up in its working directory, then in the -I directories in
# order, so coff_compare runs in $scratch/inc with the tree as -I.
inc=$scratch/inc
mkdir -p "$inc"
for ins in $(awk -F'\t' '$1 ~ /\.(ins|pvt)\.pas$/ { print $1 }' tools/cc_gap_rewrites.txt | sort -u); do
  mkdir -p "$inc/$(dirname "$ins")"
  cp "$ins" "$inc/$ins"
  awk -F'\t' -v f="$ins" '$1 == f { print $2 }' tools/cc_gap_rewrites.txt |
    while IFS= read -r r; do perl -pi -e "$r" "$inc/$ins"; done
done
for f in "$@"; do
  # dpc gaps (docs/dpc-gaps.md): compile a rewritten scratch copy, named
  # as the unit (coff_compare picks the binary's unit by the file name)
  src=$here/$f
  rules=$(awk -F'\t' -v f="$f" '$1 == f { print $2 }' tools/cc_gap_rewrites.txt)
  if [ -n "$rules" ]; then
    src=$scratch/$(basename "$f")
    cp "$f" "$src"
    printf '%s\n' "$rules" | while IFS= read -r r; do perl -pi -e "$r" "$src"; done
  fi
  for bin in $m68k $a88k; do
    # a unit whose source differs between the binaries tests the
    # conditional variable cc_a88k (%var cc_a88k; %if cc_a88k %then ...)
    config=
    [ "$bin" = "$a88k" ] && config="-config cc_a88k"
    out=$(cd "$inc" && python3 "$here/tools/coff_compare.py" --binary "$here/$bin" --unit "${f%.pas}" "$src" -- -I "$here" $config 2>&1)
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
