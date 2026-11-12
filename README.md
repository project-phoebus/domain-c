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
- `docs/audit-hexindex.md`: the audit of the early units for indexed
  displacements misread as decimal.
- `tools/`: `coff_compare.py` (a patched copy of
  `source/domain_os/tools/coff_compare.py`, to merge back), `cc_survey.py`,
  `cc_dis.py` (disassemble a routine by name), `cc_check.sh` (the gate),
  `cc_gap_rewrites.txt` (scratch rewrites for dpc gaps), `cc_addrcheck.py`
  (the unit headers' address tables, run by the gate), `cc_globals.py`,
  `cc_data.py` (initial bytes of .data from .rwdi), `cc_enumnames.py` (the
  Pascal enumeration identifier tables in a binary).
- `pilot/`: the first experiment (`get_rlen`).
- `docs/core-plan.md`: the common prelude (`lang/lang/source/globals.ins.pas`
  and the inserts it includes) and the order it is being reconstructed in.
- `docs/backend-plan.md`: cc.a88k's PRISM back end: its core inserts and
  the order and batches for the be_com units.
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
| `lang/c_compiler/source/c_expr_sem.pas` | 43 | translated (best effort; tables initialized; dpc gaps 6, 7, 8, 14, 25) |
| `lang/lang/source/kfold.pas` | 14 | translated (best effort; nodes through kf_tree_t and il views; dpc gaps 7, 8, 19, 25) |
| `lang/lang/source/outbin.pas` | 70 | translated (cc.m68k only; best effort; nodes by offset, cells through codegen's variants; dpc gaps 3, 4, 8, 9, 19, 24, 26, 25) |
| `lang/c_compiler/source/c_syntax.pas` | 59 | translated (best effort; IL nodes through c_objtype views; dpc gaps 7, 8, 20, 21, 27) |
| `lang/lang/source/cg_fp.pas` | 9 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's tree view; dpc gap 8) |
| `lang/lang/source/cg_call.pas` | 10 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's views; dpc gaps 8, 22, 28) |
| `lang/lang/source/add_node.pas` | 23 | translated (best effort; nodes through an_node_t, the kinds' names from the image; dpc gaps 4, 7, 8, 11, 15, 25) |
| `lang/lang/source/delay.pas` | 15 | translated (best effort; nodes through dl_node_t, tables initialized; dpc gaps 2, 8, 15) |
| `lang/lang/source/cg_misc.pas` | 24 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's tree view; dpc gaps 7, 8) |
| `lang/lang/source/cg_top.pas` | 18 | translated (cc.m68k only; best effort; nodes by offset, statements from their +4 through univ records; dpc gaps 8, 12) |
| `lang/lang/source/cg_addr.pas` | 50 | translated (cc.m68k only; best effort; nodes by offset and cg.ins.pas's tree view; cells defined in the image's layout; dpc gaps 2, 7, 8) |
| `lang/lang/source/cg_assign.pas` | 15 | translated (cc.m68k only; best effort; the statement through cg.ins.pas's cg_asn_t, nodes by offset; dpc gaps 7, 8, 24, 25) |
| `lang/lang/source/cg_tree.pas` | 44 | translated (cc.m68k only; best effort; generate and its 21 nested routines by translator DD; dpc gaps 2, 7, 8, 24, 25: generate's floating arms 34..42 left out of the gate, type-checked) |
| `lang/lang/source/opt_general.pas` | 9 | translated (best effort; nodes through g_opt.ins.pas's views; dpc gaps 7, 8) |
| `lang/lang/source/opt_select.pas` | 11 | translated (best effort; blocks through g_opt.ins.pas's views; dpc gaps 3, 15) |
| `lang/lang/source/opt_assign.pas` | 9 | translated (best effort; nodes through g_opt.ins.pas's views and il.ins.pas's by offset; dpc gaps 8, 12, 19, 23) |
| `lang/lang/source/opt_cse.pas` | 16 | translated (best effort; nodes through g_opt.ins.pas's views (cse's 189/190 nodes) and il.ins.pas's by offset; dpc gaps 2, 8, 24) |
| `lang/lang/source/list_tree.pas` | 42 | translated (best effort; nodes through lt_node_t views and by offset; dpc gaps 8, 9, 29) |
| `lang/lang/source/gen_unwind.pas` | 21 | translated (best effort; the unwind records as a packed record by kind; the scope's PA and a88k fields; prelude types declared in the unit, docs/questions.md 93) |
| `lang/lang/source/jmp_br_resolve.pas` | 21 | translated (cc.m68k only; best effort; code cells through jb_cell_t, sections through jb_sect_t; dpc gap 24 avoided; docs/questions.md 95) |
| `lang/lang/source/instr_reorder.pas` | 14 | translated (cc.m68k only; best effort; cells through codegen_$cell_t; dpc gaps 8, 24) |
| `lang/lang/source/opt_livevar.pas` | 19 | translated (best effort; statements through g_opt.ins.pas's views (opt_4009c's entries), other nodes by offset; dpc gaps 2, 8, 24) |
| `lang/lang/source/opt_loop.pas` | 12 | translated (best effort; statements and trees through g_opt.ins.pas's views, other nodes by offset; dpc gaps 2, 3, 7, 8) |
| `lang/lang/source/opt_vector.pas` | 20 | translated (best effort; statements and trees through the unit's views ov_stmt_t, ov_tree_t, other nodes by offset; dpc gaps 7, 8) |
| `lang/lang/source/reg_cost_68k.pas` | 3 | translated (cc.m68k only; best effort; ranges through reg_alloc.ins.pas's reg_range_t, statements through g_opt.ins.pas's views; dpc gaps 8, 25) |
| `lang/lang/source/reg_action.pas` | 11 | translated (cc.m68k only; best effort; the 191 statements through g_opt.ins.pas's acts; dpc gaps 2, 8) |
| `lang/lang/source/reg_vars.pas` | 13 | translated (cc.m68k only; best effort; the debugger's ranges through the unit's rv_lr_t, the 191 statements' actions through g_opt.ins.pas) |
| `lang/lang/source/opt_reachdef.pas` | 37 | translated (best effort; statements and trees through g_opt.ins.pas's views, other nodes by offset; dpc gaps 8, 12, 24, 25) |
| `lang/lang/source/opt_strength.pas` | 59 | translated (best effort; cc.a88k's 12 under `%if cc_a88k`; the module data, four variable sets and the lists, cc.m68k only; dpc gaps 2, 3, 8, 24) |
| `lang/lang/source/opt_main.pas` | 109 | translated (best effort; the module's data defined in the image's layout, statements, trees and blocks through g_opt.ins.pas's views, other nodes by offset; dpc gaps 2, 4, 7, 8, 29) |
| `lang/lang/source/reg_alloc.pas` | 15 | translated (cc.m68k only; best effort; statements and blocks through g_opt.ins.pas, variables and the routine block by offset; dpc gaps 4, 8) |
| `lang/lang/source/reg_color_68k.pas` | 16 | translated (cc.m68k only; best effort; ranges and conflicts through reg_alloc.ins.pas; dpc gap 21) |
| `lang/lang/source/reg_life.pas` | 17 | translated (cc.m68k only; best effort; statements, blocks and cses through g_opt.ins.pas, variables by offset) |
| `lang/lang/source/reg_save.pas` | 23 | translated (cc.m68k only; best effort; trees through cg.ins.pas's cg_tree_t, statements through g_opt.ins.pas's g_opt_stmt_t, other nodes by offset; dpc gaps 8, 24, 30) |
| `lang/lang/source/emit.pas` | 11 | translated (cc.m68k only; best effort; opinfo's instruction lists (insind) through final.ins.pas's opinfo_entry_t, cells through codegen.ins.pas, nodes by offset; dpc gaps 7, 8, 24) |
| `lang/lang/source/fpa.pas` | 20 | translated (cc.m68k only; best effort; descriptors through codegen_$uads_t, trees through cg_tree_t, the module's data initialized; dpc gaps 7, 8) |
| `lang/lang/source/banshee.pas` | 1 | translated (cc.m68k only; best effort; cells through codegen.ins.pas, the module's descriptors initialized; dpc gap 8) |
| `lang/lang/source/final.pas` | 120 | translated (best effort; translators GG, JJ; cc.m68k only; cells through codegen_$cell_t; peepholer_ops nested in peepholer; dpc gaps 2, 7, 8, 12, 15, 24, 26, 31) |
| `lang/lang/source/opt_inline.pas` | 62 | translated (best effort; translators KK, NN; both binaries one body; nodes by offset; dpc gaps 8, 15, 24) |
| `us1/us1/lib/dblib/loc/src/loc_build.c` | 33 | reconstructed (C; not checked by the gate: read against the disassembly, syntax-checked with a host C compiler; headers loc_private.h and loc_build.h, the others stubs) |
| `lang2/source/ftn/source/const_op.ftn` | 14 | reconstructed (FORTRAN 77; not checked by the gate: read against the disassembly; r8_math's operations 9, 11, 12 by guess, docs/questions.md 145) |
| `lang/c_compiler/source/c_data.asm` | 0 | reconstructed (assembly, GNU as syntax; not checked by the gate: assembled with m68k-elf-as, byte-identical to both binaries' 18384 bytes; c_globals.ins.pas's names kept) |
| `lang/lang/source/empty.pas` | 0 | translated (an empty module: no routines, no data in either binary; docs/questions.md 146) |
| `ivory/volume_3/.../std_lib.mac/hf398b043.001/std_lib.pas` | 0 | translated (data only: section libdsc's 176 descriptors as words, dpc's section byte-identical to the image; their table in the header; std_lib's pointers TODO, docs/questions.md 147) |
| `lang/lang/source/opinfo.pas` | 0 | translated (cc.m68k only; data only: the seven tables named by .blocks and the instruction lists, initialized from .rwdi, dpc's data byte-identical to the image; the tables declared in final.ins.pas under their original names, defined here; docs/questions.md 148) |
| `lang2/source/be_com/target_at_dummies.pas` | 9 | translated (cc.a88k only; the m68k code generator's entries as dummies) |
| `lang2/source/be_com/jbr.pas` | 4 | translated (cc.a88k only) |
| `lang2/source/be_com/dfa.pas` | 4 | translated (cc.a88k only; best effort; the routine through backend.ins.pas's rtn_t) |
| `lang2/source/be_com/sem_utils.pas` | 7 | translated (cc.a88k only; best effort; instructions and operands through backend.ins.pas) |
| `lang2/source/be_com/xtp.pas` | 7 | translated (cc.a88k only; best effort; instructions, operands and segments through backend.ins.pas) |
| `lang2/source/be_com/zzzzz.pas` | 9 | translated (cc.a88k only; best effort; code cells through backend.ins.pas's cell_t, code_cell_size initialized; dpc gap 2) |
| `lang2/source/be_com/tr_utils.pas` | 68 | translated (cc.a88k only; best effort, translator PC; instructions, operands, segments, live ranges and blocks through backend.ins.pas; validators as routine pointers; dpc gaps 8, 11, 12, 15, 24) |
| `lang2/source/be_com/mmt_utils.pas` | 37 | translated (cc.a88k only; best effort, translators PC and PC2; descriptors, tokens and MMT_SEQs; mmt's tokens and the views of blocks, segments, live ranges and the routine in mmt.pvt.pas; dpc gap 12) |
| `lang2/source/be_com/mmt.pas` | 39 | translated (cc.a88k only; best effort, translator PC2; tokens, relations, intra- and inter-block MMT_SEQs, segments for memory references; dpc gap 23) |
| `lang2/source/be_com/trans.pas` | 37 | translated (cc.a88k only; best effort, translators PC2 and PC3; branches on compares, compares made tests, the alpha and omega motions, silly extracts and XORs, special zero branches, copy elimination; the motions' view of blocks (+42, +122, +150); met dpc gaps 11, 23, which dpc 1240eb7 compiles) |
| `lang2/source/be_com/com.pas` | 63 | translated (cc.a88k only; best effort, translators PC3 and PC4; the CSE pass over the dominator tree (hash tables by opcode, canonical birthpoints), load and store elimination, do_not_delete stores, hoisting out of loops, invariant memory kept in registers across loops (MMT_SEQs at the entries and exits), instructions sunk into loop exits, sine/cosine calls merged into a88k_$cossin, zero valued live ranges; blocks +42/+142, the IL node +192 through views; dpc gap 30) |
| `lang2/source/be_com/oli.pas` | 120 | translated (cc.a88k only; best effort; translators PC6, PC7: the dependence tests and the modulo scheduler (PC6); the induction variables' adjustments, the copies' operands, the pipelined loop's blocks, jumps, tests and birthpoints, the reductions' sums, the recurrences' precedence and the phase's entry (PC7); dpc gap 7) |
| `lang2/source/be_com/iv.pas` | 127 | translated (cc.a88k only; best effort; translators PC4, PC5: the expressions and heaps; the induction records (iv.ins.pas: induction lts, address mode, expression, class, variable), the candidates (ivr_), the induction expressions (ixr_), the strength reduction (ixt_), the interval walk, recompute_for_oli and process_routine; opcodes/instr_size.init made) |
| `lang2/source/be_com/lst.pas` | 33 | translated (cc.a88k only; best effort; the classic and -PRASM listings; the sections initialized from instr_mnemonic*.init; dpc gaps 7, 8, 28) |
| `lang2/source/be_com/bin.pas` | 32 | translated (cc.a88k only; best effort; defines unix_objmod's emit_108 at +0x30; records by offset; dpc gaps 7, 13, 22) |
| `lang2/source/be_com/asm.pas` | 21 | translated (cc.a88k only; best effort; the PRISM encoder and literal pools, translator PB2; instr_assembly.init, operand_string*.init; docs/prism-isa.md; dpc gaps 22, 25, 32) |
| `lang2/source/be_com/dmp.pas` | 27 | translated (cc.a88k only; best effort; the phases' dumps of blocks, instructions, live ranges, the interference graph and MRH, translator PB3; am/block/lsq/rrp_string*.init, operand_letter.init, rrp_letter.init; dpc gaps 4, 33, 34) |
| `lang2/source/be_com/dbg_life.pas` | 24 | translated (cc.a88k only; best effort, translator PB4; the DBG_LIFE phase: variables' pc ranges in registers and spill slots, their debug records; lr_t, rtn_t and the IL variable nodes through views; dpc gap 30) |
| `lang2/source/be_com/sched_utils.pas` | 15 | translated (cc.a88k only; best effort, translator PB4; operand delays from the opcode tables (KODIAK's floating latencies), precedence heights, snuggle moves; dpc gap 35 worked around) |
| `lang2/source/be_com/ra_utils.pas` | 45 | translated (cc.a88k only; best effort, translator PB5; XTP's pass-through spilling around hammocks, rematerialization, the spill code (reloads, stores, loops broken from spill victims); lr_t, lts_t, bb_t, rtn_t, the hammocks and the instruction counts through views; ra_utils_10 defined (was post_6b8); dpc gaps 7, 21, 25, 28) |
| `lang2/source/be_com/ra.pas` | 62 | translated (cc.a88k only; best effort, translator PB6; the graph-colouring allocator: conflict bit matrices, aversions and preferences, the protection pipe, Chaitin's spill choice, registers opened from the conventions, the frame's layout; batch A's records through views (docs/questions.md 231); dpc gaps 7, 28, 37, 38, 39, 40) |
| `lang2/source/be_com/konst.pas` | 32 | translated (cc.a88k only; best effort, translator PB6; the KONST phase: sparse conditional constant propagation with hashed definition descriptors, executable edges, join birthpoints verified by walks back, constants turned into immediate operands, the flow graph pruned; batch A's records through views (docs/questions.md 232); dpc gaps 4, 7) |
| `lang2/source/be_com/at_backend.pas` | 15 | translated (cc.a88k only; best effort, translator PB6; the back end's driver: the phase table (initialized with the phases' routine addresses), run_phase/end_phase, the routine records, the statement map, the phase and instruction bug checks; defines at_backend_4fc, _switches, _phase, _506; the ISC's four entry points declared in the unit) |
| `lang2/source/be_com/sched.pas` | 50 | translated (cc.a88k only; best effort, translator PB7; the SCHED phase: a list scheduler, pass 1 placing each block's instructions backwards for their precedence heights under lock bits (call protocol, condition code chains, final calls, trap drivers), pass 2 issuing cycle by cycle (integer and floating slots, MUL+ADD fused into the five-operand forms, LOADS/STORES paired as LOADSE/LOADSO, the floating register traffic limit, a 16-cycle ring of pending values, stall counts); fp_registers_busy.init; batch A's records through views (docs/questions.md 247); dpc gaps 29, 38) |
| `lang2/source/be_com/bv.pas` | 32 | translated (cc.a88k only; translator PA; best effort; vectors as sets of 0..31 (backend.ins.pas bv_t), the masks initialized) |
| `lang/common/source/exs.pas` | 27 | translated (cc.a88k only; translator PA; best effort; IL nodes through the unit's views (exs_frame_t, exs_handler_t, ...); headings narrowed in exs.ins.pas) |
| `lang2/source/be_com/utils.pas` | 54 | translated (cc.a88k only; translator PA; best effort; instructions, operands, segments and live ranges through backend.ins.pas (fields named by role), join inputs and statement lists through the unit's views; utils.ins.pas narrowed; dpc gap 12) |
| `lang2/source/be_com/df_utils.pas` | 17 | translated (cc.a88k only; translator PA2; best effort; the global data flow walk: segment lists made canonical, the work queue, the exposed and final lists rebuilt; rtn_t's +80, +100, +108, +140, +144 and bb_t's +134 named) |
| `lang2/source/be_com/fga.pas` | 11 | translated (cc.a88k only; translator PA2; best effort; the FGA phase: blocks forwarded, the AP read taken out of the RETURN, asynchronous paths after setjmp; the prelude's cells through views of its own) |
| `lang2/source/be_com/hal.pas` | 19 | translated (cc.a88k only; translator PA2; best effort; the HAL phase: loop headers and tails, the hammocks and their tree; bb_t's dominator tree fields named) |
| `lang2/source/be_com/life.pas` | 14 | translated (cc.a88k only; translator PA2; best effort; the LIFE phase: memory modifies, live ranges split by equivalence classes of segments (union-find through the segments' fields), intend_to_modify marks) |
| `lang2/source/be_com/sanity.pas` | 6 | translated (cc.a88k only; translators PA2 and PA3; best effort; the segment properties repaired, check_lts, the whole routine checked (sanity_$check_entire_routine: instructions, operands, address modes against the amse_ sections, the exposed and final lists), the two lir_utils_ entries) |
| `lang2/source/be_com/call_conv.pas` | 9 | translated (cc.a88k only; translator PA3; best effort; the calling conventions: call_conv.ins.pas's records (the conventions, the argument descriptors, the presets), the arguments' places and registers by prototype; IL nodes through il.ins.pas's views and a block view; dpc gaps 22, 25) |
| `lang2/source/be_com/lir_utils.pas` | 15 | translated (cc.a88k only; translators PA3 and PA4; best effort; instructions excised, preference moves, moves around physical segments (trans_insert_move), segments added, memory homes and spill ids, the operands of new loads and stores (solutions, lir.pvt.pas's section spill_instr_forms, defined here), the asynchronous paths' live ranges, the store-through live ranges; move_opcode.init; dpc gaps 7, 21, 25, 32, 35) |
| `lang2/source/be_com/tm_utils.pas` | 14 | translated (cc.a88k only; translator PA4; best effort; immediates by operand form, the amse_ ranges, base register modification, scales, the pipeline's interaction distances; operand_forms_mask.init and the amse_*.init from the sections' bytes; instr_attr_t's interaction (+0 bits 3..0, +1 bit 7); dpc gap 32) |
| `lang2/source/be_com/sym.pas` | 19 | translated (cc.a88k only; translator PA4; best effort; labels of the spine's label nodes, local symbols initialized (common members' copies for their live ranges, the uplevel lists rtn +4/+8/+12), qualified routine names, print names, displacements, sizes, static allocation, literals as lit_t; IL nodes through il.ins.pas's views; sym headings named, isc_$get_il_live_range's heading in backend.ins.pas) |
| `lang2/source/be_com/lir_main.pas` | 25 | translated (cc.a88k only; translator PA5; best effort; the ENTRY and RETURN instructions and the formals moved to and from their homes, second entries and handler re-entries, silly register candidates, the frame laid out and the preserved registers saved and restored; the whole module data defined in address order (dpc gap 37 for its byte cells), the section lir_main_readonly_tables) |
| `lang2/source/be_com/fg_utils.pas` | 53 | translated (cc.a88k only; translator PA5; best effort; blocks dropped and forwarded, successor lists ordered, depth-first numbering, intervals and loop headers made unconditional, empty blocks and senseless loops, dominators and postdominators (Lengauer-Tarjan) with the availability vectors, join birthpoints (the SSA form of a live range) inserted, dropped and recomputed, live range lifetimes) |
| `lang2/source/be_com/lir.pas` | 63 | translated (cc.a88k only; translators PA6 and PA7; best effort; the build area and the instruction allocators, blocks, labels, edges, segments and live ranges, the operand builder (the build_ tables by build kind), instruction completion (segments, condition codes, memory and exception operands, edges), the instruction kinds' entries, calls' argument and serialized registers, the routine's reinitialization; the whole module data defined in address order with the build_*.init and build_access.init initializers; the section lir_readonly_tables; dpc gap 4) |
| `lang2/source/be_com/post.pas` | 66 | translated (cc.a88k only; translator PA6; best effort; the POST phase: physical registers written into the operands, LOADSE/STORESE pairs combined, IPCCNOPs and call and branch shadows filled, stalling loads moved, MFNEXTCC for conditional moves, FPQUIESCEs, NOPs and SHIFTNOPs against three hardware bugs, the flow graph tidied) |
| core prelude (`lang/lang/source/globals.ins.pas` and its inserts) | | settled: headings, shared cells, types (docs/core-plan.md) |
| `lang2/source/isc/isc_call_handling.pas` | 6 | translated (cc.a88k only; translator PD; best effort; the ISC's call trees: pass 1 begins the LIR call and finds the inputs', routine's, hidden temporary's and outputs' solutions, pass 2 emits the call between them; dpc gap 4) |
| `lang2/source/isc/isc_cse_handling.pas` | 57 | translated (cc.a88k only; translator PD; best effort; a CSE's solution chosen (literal, address mode, register; cheapest), preserved in its parent, generated in its statement and moved when a use came first; the 50 field accessors; dpc gap 4) |
| `lang2/source/isc/rewrite.pas` | 16 | translated (cc.a88k only; translator PD; best effort; calls and run-time operators into ISC call trees from the calling conventions, multiplies by constants (m32_prism_and_pa.pas, m16_prism.pas: the tables, included in their declarations), case statements, the entry's rws_$alloc_temp, ISC_AGG; module data byte for byte; dpc gaps 25, 28) |
| `lang2/source/isc/isc_to_lir.pas` | 30 | translated (cc.a88k only; translator PD; best effort; the debug_lir_ wrappers: traced, deferred per statement and replayed through the lir_ routines by end_statement, which first drops redundant preference moves; the phase's traces; dpc gap 4) |
| `lang2/source/isc/isc_user_routines.pas` | 138 | translated (cc.a88k only; translator PD2; best effort; the routines the generated patterns call: symbols' home solutions and register candidacy, alignments, bits known and trusted, precisions and arithmetic of IL nodes, literal bit patterns, evaluation orders, the choice among candidate solutions, solution constructors, well-known registers and literals, temporaries, pattern_match_error, the traces' printers; the module data defined in address order (isc_var_externs.ins.pas); dpc gaps 4, 6, 7) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_debug.pas` | 4 | translated (cc.a88k only; translator PE; best effort; the ISC's printers: an IL node's static attributes by kind and the inherited attributes, a solution's attributes, a set of solution kinds; the generator's parts in `iscg: begin/end` regions (docs/iscg-design.md 10); dpc gaps 4, 46) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_main.pas` | 18 | translated (cc.a88k only; translator PD2; best effort; the ISC's driver: solutions and inherited attributes allocated, duplicated and preserved (the generator's table of rules with fields), the solution lists, each statement through pass 1, the choice and pass 2, the phase's entry points and their metering; dpc gaps 4, 43) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_main.pas` | 186 | generated (cc.a88k only; translators GD, GD2; tools/iscg_gen.py and tools/iscg_pass1.py from the operator declarations, 24 routines fixed text in tools/iscg_text.py P1_ROUTINES, docs/iscg-design.md 10.5; best effort; all 186 routines; module data byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_01_address_modes.pas` | 24 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 24 differs, mean similarity 0.43; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_02_assignments.pas` | 33 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 33 differs, mean similarity 0.38; the cost tables byte for byte; the tables past 32 KB laid out as Rev 8.89 does (translator GF, pattern 380); dpc gaps 4, 25 (153, 157, 158, 169, 170)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_03_single_float.pas` | 18 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 18 differs, mean similarity 0.39; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_04_integer_arithmetic.pas` | 53 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 53 differs, mean similarity 0.50; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_05_calls.pas` | 9 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 9 differs, mean similarity 0.39; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_06_double_float.pas` | 44 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 44 differs, mean similarity 0.43; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_07_constants.pas` | 11 | generated (cc.a88k only; translator GF; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7, 10.8; compared by tools/cc_isc_check.py; 11 differs, mean similarity 0.38; rules 9 and 10 written by hand; the cost tables byte for byte; dpc gaps 4, 7 (rules 9, 10)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_08_cses.pas` | 14 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 14 differs, mean similarity 0.51; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_09_addresses_and_fields.pas` | 54 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 54 differs, mean similarity 0.43; the cost tables byte for byte; dpc gaps 4, 25 (445, 450, 474)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_10_extends.pas` | 31 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 31 differs, mean similarity 0.43; the cost tables byte for byte; dpc gaps 4, 25 (423)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_11_flow.pas` | 14 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 14 differs, mean similarity 0.42; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_12_leaves.pas` | 22 | generated (cc.a88k only; translator GF; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7, 10.8; compared by tools/cc_isc_check.py; 22 differs, mean similarity 0.39; no cost tables; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_13_logical.pas` | 16 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 16 differs, mean similarity 0.49; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_14_chains.pas` | 26 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 26 differs, mean similarity 0.42; the cost tables byte for byte; dpc gaps 4, 25 (384)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_15_processor_registers.pas` | 12 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 12 differs, mean similarity 0.46; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_16_sets.pas` | 18 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 18 differs, mean similarity 0.49; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_17_set_assignments.pas` | 6 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 6 differs, mean similarity 0.50; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_18_shifts.pas` | 26 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 26 differs, mean similarity 0.46; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_19_strings.pas` | 3 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 3 differs, mean similarity 0.49; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_20_variables.pas` | 28 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 28 differs, mean similarity 0.38; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_21_proper_subtrees.pas` | 13 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 13 differs, mean similarity 0.34; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_22_use_def.pas` | 1 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 1 differs, mean similarity 0.35; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_23_aggregate_assignments.pas` | 21 | generated (cc.a88k only; translator GF; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7, 10.8; compared by tools/cc_isc_check.py; 21 differs, mean similarity 0.47; the cost tables byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_24_operator_assignments.pas` | 27 | generated (cc.a88k only; translator GF; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7, 10.8; compared by tools/cc_isc_check.py; 27 differs, mean similarity 0.43; the cost tables byte for byte, those past 32 KB laid out as Rev 8.89 does (pattern 380); dpc gaps 4, 25 (177, 180, 181, 186)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_25_compares.pas` | 39 | generated (cc.a88k only; translator GE; tools/iscg_gen.py from the rule file's pass_1 clauses, lifted by tools/iscg_p1lift.py, docs/iscg-design.md 10.7; compared by tools/cc_isc_check.py; 39 differs, mean similarity 0.50; the cost tables byte for byte; dpc gaps 4, 25 (120, 121)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_main.pas` | 1 | generated (cc.a88k only; translator GB; tools/iscg_gen.py from the rule file, docs/iscg-design.md; best effort; pass_2 and the pass-2 action table (the actions: the 25 pass-2 modules below); module data byte for byte; dpc gap 4) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_01_address_modes.pas` | 24 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 24 differs, mean similarity 0.47) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_02_assignments.pas` | 33 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 1 same, 32 differs, mean similarity 0.49; dpc gaps 25 (153, 157, 169, 170)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_03_single_float.pas` | 18 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 1 same, 17 differs, mean similarity 0.68; dpc gaps 7) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_04_integer_arithmetic.pas` | 53 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 8 same, 45 differs, mean similarity 0.55; dpc gaps 7) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_05_calls.pas` | 9 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 2 same, 7 differs, mean similarity 0.39) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_06_double_float.pas` | 44 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 44 differs, mean similarity 0.61; dpc gaps 7) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_07_constants.pas` | 11 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 11 differs, mean similarity 0.47) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_08_cses.pas` | 14 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 14 differs, mean similarity 0.66) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_09_addresses_and_fields.pas` | 54 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 4 same, 50 differs, mean similarity 0.54; dpc gaps 25 (445, 448, 450, 474)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_10_extends.pas` | 31 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 31 differs, mean similarity 0.58; dpc gaps 7) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_11_flow.pas` | 14 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 2 same, 12 differs, mean similarity 0.52) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_12_leaves.pas` | 22 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 3 same, 19 differs, mean similarity 0.50) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_13_logical.pas` | 16 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 16 differs, mean similarity 0.56) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_14_chains.pas` | 26 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 26 differs, mean similarity 0.53; dpc gaps 25 (384)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_15_processor_registers.pas` | 12 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 12 differs, mean similarity 0.60) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_16_sets.pas` | 18 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 18 differs, mean similarity 0.60) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_17_set_assignments.pas` | 6 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 6 differs, mean similarity 0.60) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_18_shifts.pas` | 26 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 3 same, 23 differs, mean similarity 0.55) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_19_strings.pas` | 3 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 3 differs, mean similarity 0.58) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_20_variables.pas` | 28 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 28 differs, mean similarity 0.57) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_21_proper_subtrees.pas` | 13 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 13 same) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_22_use_def.pas` | 1 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 1 same) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_23_aggregate_assignments.pas` | 21 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 4 same, 17 differs, mean similarity 0.58) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_24_operator_assignments.pas` | 27 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 1 same, 26 differs, mean similarity 0.52; dpc gaps 7, 25 (178, 180, 181, 186)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_25_compares.pas` | 39 | generated (cc.a88k only; translator GC; tools/iscg_gen.py from the rule file's pass_2 bodies, lifted by tools/iscg_p2lift.py, docs/iscg-design.md 10.6; compared by tools/cc_isc_check.py; 1 same, 38 differs, mean similarity 0.56; dpc gaps 25 (120, 123)) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pattern_matcher.pas` | 2 | generated (cc.a88k only; translator GB; tools/iscg_gen.py from the rule file; best effort; hard_work and pattern_matcher (683 tries by kind and il$t), the pass-1 action table and the per-rule flags; module data byte for byte; dpc gaps 4, 25) |
| `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_vars.pas` | 0 | generated (cc.a88k only; translator GB; tools/iscg_gen.py; no code: defines isc_tool_generated_readonly_tables and isc_readonly_tables, byte for byte; dpc gap 32) |
| PRISM back-end core (`lang2/source/be_com/backend.ins.pas`, `utils.ins.pas`, the opcode enumeration, ...) | | settled: headings of every cross-unit routine, shared cells, the records the leaf units use (docs/backend-plan.md) |
