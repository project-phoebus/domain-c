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
| `lang/lang/source/cg_tree.pas` | 44 | done: 44 of 44 (generate and its 21 nested routines by translator DD; cc.m68k only; dpc gaps 2, 7, 8, 24, 25: generate's floating arms 34..42 left out of the gate, type-checked) |
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
| `lang/lang/source/opt_strength.pas` | 59 | done (59 of 59; cc.a88k's 12 under `%if cc_a88k`; the module data, four variable sets and the lists, cc.m68k only; dpc gaps 2, 3, 8, 24) |
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
| `lang2/source/be_com/iv.pas` | 127 | begun: 43 of 127 (cc.a88k only; translator PC4; the heaps, the expressions (iv.ins.pas iv_expr_t): canonical forms, duplication and comparison, the register files chosen (elaborate, propagate_down_type); the induction records, ivr_, ixr_, ixt_ and process_routine listed in the file's TODO; opcodes/instr_size.init made) |
| `lang2/source/be_com/lst.pas` | 33 | translated (cc.a88k only; best effort; the classic and -PRASM listings; the section initializers of instr_mnemonic*.init TODO; dpc gaps 7, 8, 28) |
| `lang2/source/be_com/bin.pas` | 32 | translated (cc.a88k only; best effort; defines unix_objmod's emit_108 at +0x30; records by offset; dpc gaps 7, 13, 22) |
| `lang2/source/be_com/asm.pas` | 21 | translated (cc.a88k only; best effort; the PRISM encoder and literal pools, translator PB2; instr_assembly.init, operand_string*.init; docs/prism-isa.md; dpc gaps 22, 25, 32) |
| `lang2/source/be_com/dmp.pas` | 27 | translated (cc.a88k only; best effort; the phases' dumps of blocks, instructions, live ranges, the interference graph and MRH, translator PB3; am/block/lsq/rrp_string*.init, operand_letter.init, rrp_letter.init; dpc gaps 4, 33, 34) |
| `lang2/source/be_com/dbg_life.pas` | 24 | translated (cc.a88k only; best effort, translator PB4; the DBG_LIFE phase: variables' pc ranges in registers and spill slots, their debug records; lr_t, rtn_t and the IL variable nodes through views; dpc gap 30) |
| `lang2/source/be_com/sched_utils.pas` | 15 | translated (cc.a88k only; best effort, translator PB4; operand delays from the opcode tables (KODIAK's floating latencies), precedence heights, snuggle moves; dpc gap 35 worked around) |
| `lang2/source/be_com/ra_utils.pas` | 45 | translated (cc.a88k only; best effort, translator PB5; XTP's pass-through spilling around hammocks, rematerialization, the spill code (reloads, stores, loops broken from spill victims); lr_t, lts_t, bb_t, rtn_t, the hammocks and the instruction counts through views; ra_utils_10 defined (was post_6b8); dpc gaps 7, 21, 25, 28) |
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
| core prelude (`lang/lang/source/globals.ins.pas` and its inserts) | | settled: headings, shared cells, types (docs/core-plan.md) |
| PRISM back-end core (`lang2/source/be_com/backend.ins.pas`, `utils.ins.pas`, the opcode enumeration, ...) | | settled: headings of every cross-unit routine, shared cells, the records the leaf units use (docs/backend-plan.md) |
