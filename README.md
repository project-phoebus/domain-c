# DOMAIN C 6.9 compiler - reconstructed source

A reconstruction, in Domain Pascal (and the few C, Fortran and assembly
units), of Apollo's DOMAIN C compiler V.6.9 from the two executables on the
cartridge in `ctape/`:

- `ctape/install/ri.apollo.cc.v.6.9.m/cc.m68k`: the C compiler with the
  m68k back end (`lang/lang/source/cg_*`, `reg_*`, ...).
- `ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k`: the C compiler with the
  a88k (PRISM) back end (`lang2/source/be_com`, `isc`).  Both run on the 68K.

Each unit is one file under its original path, `//foo/bar/baz.pas`
becoming `./foo/bar/baz.pas` (the paths come from the binaries' .blocks
debug section).  The method is the one `../../domainos-archeology/source`
used for `com/bind`: the disassembly is the truth; names come from the
binaries (.blocks routine names, the transfer vector's externals, Apollo's
customer inserts); what the image does not decide is listed in each
routine's "Not known from the original" or a `TODO(pascal)` block.

**Fidelity: best effort** (decided 2026-11-10).  The binaries were built
by Pascal compiler Rev 8.89; dpc models SR10.2's Rev 7.x.  dpc's default
(best-effort) mode is used: each routine is written so that its code does
what the image's does, checked by reading dpc's output against the image,
but it is not byte-identical.  The Rev 8.89 forms met are collected in
`docs/rev889-patterns.md` for a later dpc profile.

## Layout

- `docs/survey.md`: the binaries, the units, the .blocks v4 format, open
  items, the pilot.  `docs/survey-tables.md`, `docs/routines-cc.*.md`:
  generated unit and routine tables (with each unit's inserts in the order
  opened).
- `docs/rev889-patterns.md`: Rev 8.89 code generation vs dpc.
- `docs/dpc-gaps.md`: constructs dpc refuses (bug reports for dpc).
- `tools/`: `coff_compare.py` (a patched copy of
  `source/domain_os/tools/coff_compare.py`, to merge back), `cc_survey.py`,
  `cc_dis.py` (disassemble a routine by name), `cc_check.sh` (the gate),
  `cc_gap_rewrites.txt` (scratch rewrites for dpc gaps), `cc_addrcheck.py`
  (the unit headers' address tables, run by the gate), `cc_globals.py`,
  `cc_data.py` (initial bytes of .data from .rwdi).
- `pilot/`: the first experiment (`get_rlen`).
- `docs/core-plan.md`: the common prelude (`lang/lang/source/globals.ins.pas`
  and the inserts it includes) and the order it is being reconstructed in.
- `docs/globals-cc.*.md`: shared global cells by owning unit
  (`tools/cc_globals.py`).
- `lang/`, `lang2/`, ...: the reconstructed source.

## Conventions

- A unit file: a header comment (purpose; image addresses in both binaries;
  A5; module data), `module <name>;` (the unit's .blocks module record
  name), the `%include`s **in the order the unit opened them**
  (`docs/routines-cc.*.md`; customer inserts as `/sys/ins/...`, others
  relative to this tree, `lang/common/source/...`), then each routine with
  its header comment (address, length, the instructions that decide each
  construct, "Not known from the original").
- Inserts (`*.ins.pas`) hold the constants, types and `extern` headings,
  each with evidence.  Rev 8.89 loads A5 in every global routine of a
  module with data, so a module-level routine that does not load A5 is
  `internal`.  Parameters read by value from the frame mean `val_param`
  (a 16-bit value takes a 2-byte slot).
- Calls to `M$...` arithmetic are ordinary `*`, `div`, `mod`; never call
  them.
- Comments are `{ }` and contain no braces.
- Gate: `tools/cc_check.sh [FILE.pas ...]` must show no dpc errors (set
  `DPC` to a current dpc; the default is the domain-pascal debug build).

## Status

| unit | routines | state |
|------|----------|-------|
| `lang/common/source/std.pas` | 11 | translated (best effort) |
| `lang/common/source/diag.pas` | 13 | translated (best effort; dpc gap 1) |
| `lang/common/source/ass.pas` | 14 | translated (best effort) |
| `lang/common/source/token.pas` | 8 | translated (best effort; dpc gap 2) |
| `lang/common/source/ecb.pas` | 1 | translated (best effort; st.ins.pas fields named by use) |
| `lang/common/source/mem.pas` | 19 | translated (best effort) |
| `lang/common/source/htm.pas` | 12 | translated (best effort; tables initialized) |
| `lang/common/source/bvs.pas` | 24 | translated (best effort) |
| `lang/common/source/spos.pas` | 31 | translated (best effort; regions' database a record addressed absolutely) |
| `lang/bind/source/objio.pas` | 34 | translated (best effort; the source repository's SR10.2 objio, changed where cc's differs; dpc gap 4) |
| `lang/bind/source/objutil.pas` | 18 | translated (best effort; the source repository's SR10.2 objutil, the same in cc) |
| `lang/common/source/pds.pas` | 124 | translated (best effort; records and buckets in pds.pvt.pas, the DST records in us/us/sys/ins/dst.ins.pas; dpc gaps 11, 12) |
| `lang/lang/source/gen_debug.pas` | 31 | translated (best effort; putobj declared in the unit, docs/questions.md 19) |
| `lang2/source/lt_utils/source/bug_check.pas` | 3 | translated (best effort) |
| `lang2/source/lt_utils/source/seg_size.pas` | 1 | translated (best effort) |
| `lang2/source/lt_utils/source/mrh.pas` | 15 | translated (best effort) |
| `lang2/source/lt_utils/source/arith.pas` | 2 | translated (best effort) |
| `lang/lang/source/gspace.pas` | 6 | translated (best effort) |
| `lang/lang/source/strings.pas` | 7 | translated (best effort) |
| `lang/lang/source/prtsub.pas` | 7 | translated (best effort) |
| `lang/lang/source/il.pas` | 1 | translated (best effort; IL globals named by offset) |
| `lang/lang/source/target_properties.pas` | 3 | translated (best effort; record fields named by offset, table initializer TODO) |
| `lang/c_compiler/source/c_get_rlen.pas` | 1 | translated (best effort) |
| `lang/c_compiler/source/frontend_cc_dummies.pas` | 4 | translated (best effort) |
| `lang/c_compiler/source/fe_cc_hooks_to_backend.pas` | 3 | translated (best effort) |
| `lang/c_compiler/source/c_general_utl.pas` | 10 | translated (best effort) |
| `lang/c_compiler/source/c_cond_read.pas` | 7 | translated (best effort) |
| `lang/c_compiler/source/c_error.pas` | 8 | translated (best effort; dpc gap 2) |
| `lang/c_compiler/source/c_macro_utl.pas` | 19 | translated (best effort; dpc gaps 3, 4, 5) |
| `lang/c_compiler/source/c_initdate.c` | 1 | reconstructed (C; not checked by the gate) |
| `lang/c_compiler/source/c_run_acpp.c` | 3 | reconstructed (C; not checked by the gate) |
| `lang/lang/source/inc_list.pas` | 5 | translated (best effort) |
| `lang/lang/source/error_listing.pas` | 6 | translated (best effort) |
| `lang/lang/source/token.pas` | 12 | translated (best effort; dpc gaps 7, 8) |
| `lang/lang/source/il_utils.pas` | 14 | translated (best effort; nodes by offset; dpc gaps 8, 9) |
| `lang/lang/source/gen_utils.pas` | 21 | translated (best effort; nodes by offset; dpc gap 8) |
| `lang/lang/source/time.pas` | 2 | translated (best effort) |
| `lang/lang/source/sortidntk.pas` | 3 | translated (best effort; dpc gap 10) |
| `lang/c_compiler/source/c_sym_map.pas` | 11 | translated (best effort; blocks by offset) |
| `lang/c_compiler/source/c_macro_read.pas` | 23 | translated (best effort) |
| `lang/c_compiler/source/c_lex_pp.pas` | 38 | translated (best effort; dpc gaps 2, 7, 8, 12, 13, 14) |
| `lang/c_compiler/source/c_main.pas` | 13 | translated (best effort; program cc; dpc gaps 1, 3, 15, 16) |
| `lang/lang/source/cargs.pas` | 24 | translated (best effort; the binaries' variants by `%if cc_a88k`; dpc gaps 3, 11) |
| `lang/lang/source/prfpkg.pas` | 11 | translated (best effort; dpc gaps 4, 7) |
| `lang/lang/source/target_68k_dummies.pas` | 8 | translated (cc.m68k only) |
| `ivory/volume_4/report/source/do_report.pas` | 1 | translated (best effort) |
| `lang/lang/source/iosub.pas` | 36 | translated (best effort; the binaries' variants by `%if cc_a88k`) |
| `lang/lang/source/prtobj.pas` | 4 | translated (best effort; nodes by offset; dpc gap 8) |
| `lang/lang/source/celpkg.pas` | 11 | translated (cc.m68k only; best effort; dpc gaps 4, 8) |
| `lang/lang/source/gen_exception.pas` | 8 | translated (best effort; frames and records by offset; dpc gap 4) |
| `lang/lang/source/unix_objmod.pas` | 46 | translated (best effort; nodes by offset; cells in unix_objmod.ins.pas, uobj_; dpc gaps 8, 9, 12, 19) |
| `lang/lang/source/coff_syms.pas` | 16 | translated (best effort; nodes by offset; unix_objmod's cells; dpc gap 8) |
| `lang/lang/source/runbackend.pas` | 24 | translated (best effort; nodes by offset; dpc gaps 2, 8) |
| `lang/lang/source/commit_top_node.pas` | 7 | translated (best effort; nodes by offset; dpc gaps 2, 8, 12) |
| `lang/c_compiler/source/c_expr_syn.pas` | 28 | translated (best effort; dpc gaps 7, 8, 20) |
| `lang/c_compiler/source/c_stmt_sem.pas` | 52 | translated (best effort; IL nodes through c_objtype views; dpc gaps 3, 7, 8, 12, 21) |
| `lang/lang/source/attributes.pas` | 19 | translated (best effort; nodes by offset; dpc gaps 8, 22) |
| `lang/lang/source/alias.pas` | 19 | translated (best effort; nodes by offset; tables initialized; dpc gaps 8, 23, 24) |
| `lang/lang/source/debug_sym_dmp.pas` | 56 | translated (best effort; nodes by offset; spos routine parameters, dpc gaps 3, 8, 12, 21) |
| `lang/c_compiler/source/c_def_sem.pas` | 59 | translated (best effort; IL nodes through c_objtype views and il.ins.pas's; dpc gap 8) |
| `lang/c_compiler/source/c_syntax.pas` | 59 | started: 12 of 59 (error, check, type_qualifiers, cc_walk_it, call_kfold, ...; dpc gap 8) |
| `lang/c_compiler/source/c_expr_sem.pas` | 43 | translated (best effort; tables initialized; dpc gaps 6, 7, 8, 14, 25) |
| `lang/lang/source/kfold.pas` | 14 | translated (best effort; nodes through kf_tree_t and il views; dpc gaps 7, 8, 19, 25) |
| `lang/lang/source/outbin.pas` | 70 | translated (cc.m68k only; best effort; nodes by offset, cells through codegen's variants; dpc gaps 3, 4, 8, 9, 19, 24, 26, 25) |
| `lang/lang/source/cg_fp.pas` | 9 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's tree view; dpc gap 8) |
| `lang/lang/source/cg_call.pas` | 10 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's views; dpc gaps 8, 22, 27) |
| core prelude (`lang/lang/source/globals.ins.pas` and its inserts) | | settled: headings, shared cells, types (docs/core-plan.md) |
