# The PRISM back end (cc.a88k) - plan

cc.a88k has 51 units cc.m68k lacks (`docs/survey-tables.md`, "only in
cc.a88k").  The back end proper is `lang2/source/be_com/*.pas` (39
units) and `lang/common/source/exs.pas`; the ISC (`lang2/source/isc`,
and the generated `moon_unit/.../iscg_input/*`) comes later
(docs/questions.md 151 asks how to treat the generated part).  This
records how the back end's core was settled (translator MM, 2026-11-11)
and the order for the parallel translators, as `docs/core-plan.md` did
for the m68k side.

## The core (settled)

Nearly every be_com unit opens, after the lang prelude
(`lang/lang/source/globals.ins.pas`): (`at_base.ins.pas`),
`backend.ins.pas`, lt_utils `mrh.ins.pas`, lang `prtsub.ins.pas`,
`be_prism/target.ins.pas`, the opcode enumeration, (`utils.ins.pas`,
`call_conv.ins.pas`, ...); the order varies a little by unit: copy it
from `docs/routines-cc.a88k.md`.  `/sys/ins/vfmt.ins.pas` is the
customer insert (in dpc's root): no stand-in is needed.

| insert | what it declares | state |
|--------|------------------|-------|
| `idccclx/.../opcodes/opcode_enumeration.ins.pas` | opc$t, the 384 opcodes (OPC$UNDEFINED .. OPC$INIT_LB) | complete: names from isc_to_lir's Pascal identifier table (cc.a88k 0x209FEE), checked against the section instruction_mnemonic; `tools/cc_enumnames.py` lists every such table of a binary |
| `lang2/source/be_com/backend.ins.pas` | the enumerations from the image's string tables (operand$t, of$t, am$t, lsq$t, block$t, rrp$t / rrp$set_t), arg_loc_t, the instruction classes (class$..., attribute +7), the records (instr_attr_t, opnd_t, instr_t, bb_t, lts_t, lr_t, rtn_t, cell_t, at_switches_t), the named tables (instruction_attributes, instruction_mnemonic(_length), operand_forms_mask, of_string(_length), operand_string(_length)), the cells other units reach (at_backend +0x4FC..+0x502, lir_main +0xB40, +0xC40..+0xC8E, +0xDA4, lir's, asm's, dmp's, lst's, ra's, sched's), and the headings of 277 global routines other units call (every be_com unit's but utils', call_conv's, exs's and the private ones below) | settled: every cross-unit routine has a heading; records named by offset where unknown |
| `lang2/source/be_com/utils.ins.pas` | utils.pas's 40 cross-unit headings; utils_ins_$operands_instruction's body | settled |
| `lang2/source/be_com/call_conv.ins.pas` | get_rlen_and_size, at_call_conv | headings settled; records TODO |
| `lang/common/source/exs.ins.pas` | exs.pas's 14 cross-unit headings | drafts read off frames (exs.pas not translated) |
| `lang2/source/be_com/mmt.pvt.pas` | mmt's tokens, the memory model's views of bb_t, lts_t, lr_t and rtn_t (unit-local, by offset), mmt's cells mmt_utils reaches, the headings mmt/mmt_utils call across | settled with mmt and mmt_utils (translator PC2) |
| `lang2/source/be_com/iv.ins.pas`, `ra.pvt.pas` | the headings iv/oli, ra/ra_utils call across | headings only |
| `lang2/source/be_com/lir.pvt.pas` | lir, lir_main, lir_utils, ra_utils's private cells | stub |
| `lang2/source/be_prism/target.ins.pas`, `lang2/source/be_com/at_base.ins.pas` | | stubs: nothing the translated units need could only come from them |
| `lang2/source/isc/isc_lir.ins.pas`, `isc_attribute_records.ins.pas`, `isc_var_externs.ins.pas`, `moon_unit/.../isc_enumeration.ins.pas`, `isc_solution_fields.ins.pas` | | stubs (lir, lir_main, lir_utils, ra_utils, call_conv open them) |

`debug_sym_dmp.ins.pas`, `add_node.ins.pas` and `outbin.ins.pas` come
with the prelude and are the m68k side's, unchanged.

Conventions the translators should know:

- **Headings were read off frames** (`tools/cc_params.py` and the
  callers' pushes): a pointer univ_ptr, a longword integer32, a word
  integer, a byte boolean, p1..pn; a function only where a caller reads
  D0/A0.  Narrow them (type, name, mode) from the callee's body; grep
  the callers in the tree when you do (`git grep -n 'name('`).  A
  routine that takes the routine being compiled has `rtn: rtn_ptr_t`.
- Every phase's begin_compilation and end_compilation take nothing;
  init_for_routine, process_routine and end_routine take the routine
  (at_backend's table, A5 0x485830: 20 entries of 36 bytes: letter,
  number, the four entries, the name).
- `backend.ins.pas` is opened before the opcode enumeration: its
  records hold opcodes as opc$w_t (a word, 0..383); compare with the
  ordinal or `ord(opc$...)`.
- dpc lays a 0..255 field of an unpacked record out as a word: the
  records' byte fields are inside packed records (instr_t's h, opnd_t's
  h, cell_t's h, bb_t's f) or chars.  Packed records allocate from the
  high bit (bit 7 of the first byte first).
- dpc's set layout matches the image's masks (rrp$set_t: element k is
  bit k of the word).
- `utils_ins_$operands_instruction` is compiled into each unit that
  opens utils.ins.pas; the image has a copy only where it is called
  (questions 154).
- A function result the image drops: `discard(f(...))` (xtp).
- The cells are named `<owner>_<offset>` until their owner's
  translator names them; define them in the owner's unit (`define`).
- The gate: `tools/cc_check.sh FILE` compiles a cc.a88k-only unit with
  `-config cc_a88k` against cc.a88k only (cc.m68k is skipped: "no single
  unit"); `tools/cc_typecheck.sh` now does the same for these units.

## Translated with the core

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/target_at_dummies.pas` | 9 | the m68k code generator's entries, dummies |
| `lang2/source/be_com/jbr.pas` | 4 | empty phase |
| `lang2/source/be_com/dfa.pas` | 4 | the DFA phase |
| `lang2/source/be_com/sem_utils.pas` | 7 | low-order bits an operand needs |
| `lang2/source/be_com/xtp.pas` | 7 (+ utils_ins_) | the XTP phase, insert_ipccnop |
| `lang2/source/be_com/zzzzz.pas` | 9 | code cells, epilogue marks (dpc gap 2) |
| `lang2/source/be_com/lst.pas` | 33 | the assembler listing, classic and -PRASM (translator PB; dpc gaps 7, 8, 28) |
| `lang2/source/be_com/bin.pas` | 32 | the code's bytes, displacements, exception stubs, .lines and unwind scopes (translator PB; dpc gaps 7, 13, 22) |

exs.pas (27 routines, 4168 bytes, nested routines with uplevel
references) was not reached with the core; batch A translated it
(below).

Batch A (translator PA, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/bv.pas` | 32 | done: vectors as sets of 0..31 (bv_t), the blocks' data flow vectors (bb_t +86 .. +130), lir_main_c78 .. c84 named; bv headings narrowed |
| `lang/common/source/exs.pas` | 27 | done: exs.ins.pas checked against the bodies (IL nodes univ_ptr in the headings) |
| `lang2/source/be_com/utils.pas` | 54 | done: utils.ins.pas narrowed (utils_$birthpoint_t, utils_$pair_func_t); lts_t, lr_t, bb_t, rtn_t fields for the segment lists |
| call_conv, lir_utils, lir, lir_main, sym, df_utils, fg_utils, tm_utils, sanity, fga, hal, life, post | | not reached (docs/questions.md 167) |

## Order: leaves first by the call graph

Remaining: 34 units, 391,102 bytes of code, 1291 routines.  Levels by
the unit call graph (calls into at_backend, which are only its
bug-check reporters, ignored; a level's units call only lower levels
or each other):

| level | units (bytes) |
|-------|---------------|
| 0 | call_conv (8696), exs (4168), bv (4062) |
| 1 | one cycle: lir (20608), dmp (13336), lir_main (13156), lst (12704), fg_utils (11286), utils (11194), lir_utils (7972), bin (6958), sym (3488), df_utils (2698) |
| 2 | post (20856), asm (11360), dbg_life (7750), sched_utils (3708), tm_utils (2492) |
| 3 | ra + ra_utils (25086 + 14838, a cycle), tr_utils (21154), konst (5888), sanity (4158) |
| 4 | mmt + mmt_utils (12282 + 10124, a cycle), sched (17436), trans (11454), life (2788), hal (2656), fga (2084) |
| 5 | com (24270), at_backend (3744) |
| 6 | iv (28876) |
| 7 | oli (37772) |

With every cross-unit heading in the inserts, a cycle does not block:
its units can be done in any order.

## Batches for three translators

Each batch is in its own order (leaves first); sizes are routine
bytes.

**Batch A - the LIR and the flow graph (122,362 bytes, 16 units):**
bv, exs, call_conv; utils, lir_utils, lir, lir_main, sym, df_utils,
fg_utils; tm_utils, sanity; fga, hal, life; post.
Extends: backend.ins.pas (instr_t, opnd_t, bb_t, lr_t, lts_t, rtn_t
fields; lir's and lir_main's cells named; the headings of these units
narrowed), utils.ins.pas, lir.pvt.pas (lir/lir_main/lir_utils/ra_utils
cells: lir +0x3B80..+0x3C48, +0x41F0..+0x4216; lir_main +0x250..+0xAC0,
+0xDA0; ra_utils +0x10..+0x7C), exs.ins.pas (checked against the
bodies), call_conv.ins.pas (the conventions' records), the ISC inserts
lir opens (isc_lir, isc_enumeration, isc_attribute_records,
isc_solution_fields, isc_var_externs: isc_user_routines' +0x31C..+0x358),
and the generated initializers lir and tm_utils include
(opcodes/instr_attributes.init, instr_size.init,
backend.ins/of_string*.init, solution_kind.init, build_access.init,
move_opcode.init, lir.dir/build_*.init, operand_forms_mask.init, the
amse_*.init): reproduce them from the named sections and .rwdi
(`tools/cc_data.py`), as code_cell_size in zzzzz.pas.

**Batch B - output, register allocation, scheduling (122,808 bytes, 11
units):** lst, bin, dmp; asm, dbg_life, sched_utils; ra_utils, ra,
konst; sched; at_backend.
Extends: backend.ins.pas (lst's, dmp's, asm's and ra's cells; cell_t;
the instruction_assembly section), at_base.ins.pas (asm, at_backend,
bin, dmp, konst, lst open it), be_prism/target.ins.pas (the registers),
ra.pvt.pas, lir.pvt.pas (ra_utils), the initializers dmp, lst, asm and
sched include (backend.ins/am_string*, block_string*, lsq_string*,
rrp_string*, operand_letter, rrp_letter, register_letter, lsq_suffix,
operand_string*; opcodes/instr_mnemonic*, instr_assembly,
fp_registers_busy), us/us/ins objmod.ins.pas and a new coff_dst.ins.pas
(bin), unix_objmod's view of bin's cells (+0x30, +0x3C).  at_backend
defines at_backend_4fc .. at_backend_phase and the phase table; it
calls exs and call_conv (batch A): its headings are settled, so order
does not matter.

**Batch C - the optimizer (145,932 bytes, 7 units):** tr_utils; mmt_utils,
mmt; trans; com; iv; oli.
Extends: backend.ins.pas (the headings of these units narrowed;
instruction and live range fields the transformations use),
mmt.pvt.pas (mmt +0xC0..+0x1A8, which mmt_utils reaches), iv.ins.pas
(oli and iv; iv includes opcodes/instr_size.init after it).  oli
(37,772) is last in the graph and the largest: whoever finishes first
takes it.

## Reconciliation of batches A–C

Batches A (PA: bv, exs, utils), B (PB: lst, bin) and C (PC: tr_utils,
mmt_utils begun) each extended backend.ins.pas and utils.ins.pas from
the same base.  At the merge each offset of bb_t, lts_t, lr_t and
rtn_t got one field: a meaningful name over a positional one, batch
A's where both were meaningful (it owns the LIR and flow-graph units
that define these records), the other name kept in the field's
comment.  Batch B's records did not overlap.  utils.ins.pas is batch
A's (it wrote utils.pas, so its headings match the bodies).  Batch
C's code was moved to the names below; **continuing batch C (mmt_utils,
mmt, trans, com, iv, oli), use the right-hand column.**

| PC's name | Reconciled |
|---|---|
| `bb_edge_t`, `bb_edge_ptr_t` | `fg_edge_t`, `fg_edge_ptr_t` (source, target unchanged) |
| edge `next_out`, `next_in` | `next_succ`, `next_pred` |
| bb `w12: integer` | `order: 0..65535` (`clr.l; move.w`: unsigned) |
| bb `l22`, `l26` | `succs`, `preds` (fg_edge_ptr_t) |
| bb `l86`, `l90`, `l94` (univ_ptr) | `live_out`, `live_gen`, `live_in` (bv_ptr_t) |
| bb `l110` (univ_ptr) | `transparent` (bv_ptr_t) |
| bb `l98: bb_edge_ptr_t` | `l98: fg_edge_ptr_t` |
| bb `l146` | `mark146` |
| bb `f14`, `f20`, `l70`, `l82`, `l102`, `l106`, `f.b18_*` | unchanged |
| lts `f2.b2` | `f2.num` |
| lts `f2.b3_7`, `f2.b3_6`, `f2.b3_4` | `f2.exposed`, `f2.first_in_bb`, `f2.final` |
| lts `f2.b3_3`, `b3_2` (marked), `b3_1`, `b3_0` | unchanged |
| lts `def` | `refs` (the operands that refer to the segment, the definition first) |
| lts `l44: lts_ptr_t` | `l44: univ_ptr` (it also heads a join's inputs): `lts_ptr_t(l^.l44)^.bb` to dereference |
| lr `f2` (all bits) | unchanged (batch A's `w2 & 16#80` is `f2.b3_7`) |
| lr `w4: integer` | `id: 0..65535` (the complex id) |
| lr `w6` | `num` |
| lr `l16` | `mate` (batch A had `lr16`) |
| lr `l20: integer32` | `node20: univ_ptr` (compare with nil) |
| lr `l72`, `l76` (integer32) | `exposed`, `finals` (lts_ptr_t; clear with nil) |
| lr `l40` .. `l60` | unchanged |
| rtn `l180` | `marks` |
| rtn `lrs_last`, `f228` | unchanged |
| `utils_$excise_instruction_cleanly(p1; p2: boolean): integer32` | procedure `(instr: instr_ptr_t; cascade: boolean)` |
| `utils_$remove_reader_from_lts` (function) | procedure `(op: opnd_ptr_t; cascade: boolean)` |
| `utils_$excise_lts_cleanly(p1; p2: boolean)` | `(lts: lts_ptr_t; cascade: boolean)` |
| `utils_$move_definition(p1; p2; p3: boolean)` | `(lts, def: lts_ptr_t; relink: boolean)` |
| `utils_$find_last_lts_in_bb(lr, bb, out prev)` | `var prev` |
| `utils_$get_exposed_lts`, `_get_final_lts(lr, bb, out created)` | `var created` |
| `utils_$get_new_lts(..., 0)` | third parameter `at_end: boolean` |
| `utils_$apply_func_to_all_uses`'s function | `utils_$pair_func_t`: `function(a, b: lts_ptr_t): boolean` |
| `utils_$get_canonical_birthpoint`, `_complete_copied_instr`, `_add_birthpoint` | procedures (`utils_$birthpoint_t` in utils.ins.pas) |
| `bv_$subtract`, `bv_$make_live_range_complex` | procedures |
| bv_ headings (`p1`.. univ_ptr) | `bv_ptr_t` vectors, `lr: lr_ptr_t`, `rtn: rtn_ptr_t`, `n: linteger`; orders: `bv_$set_if_not_killed(not_killed, lr, v)`, `bv_$find_next_val(rtn, v, k): integer32`, `bv_$find_next(rtn, v, lr): lr_ptr_t`, `bv_$initialize_bit_vectors(rtn, n, nvectors, any_path)`, `bv_$propagate_lifetimes(n, rtn)`, `bv_$copy`/`_or`/`_and`/`_subtract(n, src, dst)`, `bv_$and_to(n, a, b, dst)` |

New fields from batch A that batch C may use: bb `l54`, `exposed`
(+62), `finals` (+66), `next114`, `avail_in`/`_out`/`_gen` (+122..);
lts `next_exposed` (+16), `next_final` (+20), `l24`, `l32`, `mark`
(+36); lr `exposed_hint`, `exposed_prev` (+64, +68), `final_hint`,
`final_prev` (+80, +84); rtn `lr_map` (+60), `bbs72`, `nbbs` (+184),
`l188`.

## The ISC

Not in these batches.  The hand-written units (lang2/source/isc:
isc_to_lir 15,164 bytes, isc_user_routines 39,392, isc_cse_handling
5,780, isc_call_handling 1,542, rewrite 9,296) are ordinary
translations once batch A has filled the ISC inserts.  The generated
units (isc_pass_1_main, isc_pass_2_main, isc_vars, isc_pattern_matcher,
isc_debug, isc_main: about 1.05 MB, some 1080 routines without names,
near-duplicate pattern actions) are probably better reconstructed as
the generator's input than translated routine by routine.
Decided (docs/questions.md 151, the owner, 2026-11-11): reconstruct
the generator's input (the pattern description) and a generator in
tools/ that emits Pascal of the image's shape, checked by the gate
against cc.a88k; do not hand-translate the ~1080 unnamed actions.
Scheduled after batch A has filled the ISC inserts.
