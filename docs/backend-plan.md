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
| `lang2/source/be_com/asm.pas` | 21 | the encoder (pass 2), the layout and pipeline NOPs (pass 1), the literal pools, case tables (translator PB2; dpc gaps 22, 25, 32; the .init files by `define`, questions 161) |
| `lang2/source/be_com/dmp.pas` | 27 | the phases' dumps: blocks, instructions, live ranges, interference graph, MRH (translator PB3; batch A's record fields read through views, their meanings in its comments; phase$ constants in backend.ins.pas; dpc gaps 4, 33, 34) |
| `lang2/source/be_com/dbg_life.pas` | 24 | the DBG_LIFE phase: spill slots numbered after the complex live ranges, its own seven vectors a block, the pc ranges of each variable's register and slot homes, the debug records chained from the IL nodes (+68 / +54) (translator PB4; dpc gap 30) |
| `lang2/source/be_com/sched_utils.pas` | 15 | the scheduler's utilities: operand delays, precedence heights (+28 a word during SCHED), snuggle moves next to physical registers' writers and readers (translator PB4; headings narrowed, sched_utils_$flags_t) |
| `lang2/source/be_com/ra_utils.pas` | 45 | the allocator's utilities: XTP's pass-through spilling around hammocks (nine bit vectors, hal's records' +24..+36), rematerialization, the spill code (reloads, stores, loops broken from spill victims, readers linked to one reload) (translator PB5; ra.pvt.pas headings narrowed, ra_650; backend.ins.pas ra_utils_10 (was post_6b8), lir_main_c88/_c89 bytes; dpc gaps 7, 21, 25, 28) |
| `lang2/source/be_com/ra.pas` | 62 | the allocator (translator PB6): ra.pvt.pas ra_classes_t, ra_$clean_bb_and_init_bit_vectors and ra_$build_conflict_graph narrowed (classes; first, count_only); ra_654/ra_658 defined; the 'ISD' letters at +0x65C (question 300); batch A fields read through views (question 302); dpc gaps 7, 28, 38, 39, 40 |
| `lang2/source/be_com/konst.pas` | 32 | KONST (translator PB6): definition descriptors (ko_dd_t, kinds 0..5), the edges' and join inputs' followed marks in their pointers' low bits; runs only at debug level 1 or more (at_backend_switches.level); dpc gaps 4, 7 |

exs.pas (27 routines, 4168 bytes, nested routines with uplevel
references) was not reached with the core; batch A translated it
(below).

Batch A (translator PA, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/bv.pas` | 32 | done: vectors as sets of 0..31 (bv_t), the blocks' data flow vectors (bb_t +86 .. +130), lir_main_c78 .. c84 named; bv headings narrowed |
| `lang/common/source/exs.pas` | 27 | done: exs.ins.pas checked against the bodies (IL nodes univ_ptr in the headings) |
| `lang2/source/be_com/utils.pas` | 54 | done: utils.ins.pas narrowed (utils_$birthpoint_t, utils_$pair_func_t); lts_t, lr_t, bb_t, rtn_t fields for the segment lists |
| call_conv, lir_utils, lir, lir_main, sym, df_utils, fg_utils, tm_utils, sanity, fga, hal, life, post | | not reached by PA (docs/questions.md 167); continued by PA2 below |

Batch A continued (translator PA2, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/df_utils.pas` | 17 | done: the global data flow walk; df_utils_$global_walk(_with_async_protection) named (rtn, nlrs, how, level); rtn_t bb80, lr100, lr108, lr140, memory_lr and bb_t l134 named (rtn +112 is a live range here, kept l112: lts_ptr_t for zzzzz) |
| `lang2/source/be_com/fga.pas` | 11 | done: the FGA phase; rtn_t return_instr (+96), ap_lr (+100, was lr100), f226 (+226, +227 bits) named; bb_t l134 univ_ptr (fga walks blocks through it); fg_utils_$forward_this_block named (rtn, bb, jump); opnd_t's +4 of an immediate or XSB displacement is its node |
| `lang2/source/be_com/hal.pas` | 19 | done: the HAL phase; bb_t l46, l50 (dominator tree), l58 (candidate hammock ends), l74, l78, l150 named, l54/next114/l98/avail_out uses documented; fg_utils_$separate_loop_header_edges named (bb, head, p3: boolean): fg_edge_ptr_t |
| `lang2/source/be_com/life.pas` | 14 | done: the LIFE phase; rtn_t l200 named; lts_t's lr/mark and lr_t's l52 serve life's union-find (cast there, documented in life.pas) |
| `lang2/source/be_com/sanity.pas` | 6 | begun, 5 of 6: sanity_$check_entire_routine (0x2721B4, 0xD76) remains (extern in the unit meanwhile); lir_utils_$repair_lts_properties named (rtn) |

Batch A continued (translator PA3, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/sanity.pas` | 6 | done: sanity_$check_entire_routine (five walks: instructions, operands, address modes against the amse_ sections, exposed and final lists, the live ranges' segments); backend.ins.pas instr_attr_t amse (+1 bits 6..4), instr_hdr_t +3 as modify/lsq/b3_3, opnd_hdr_t bytes, lr_t f2.reg, the amse_ sections declared |
| `lang2/source/be_com/call_conv.pas` | 9 | done: call_conv.ins.pas's records (call_conv_$t, call_conv_$arg_t, call_conv_$preset_t; question 171); rtn_t ip_clobbered, fp_clobbered and the memory properties at +227/+228 (question 169); isc_lir.ins.pas make_expression_temporary; dpc gaps 22, 25 (parts 3, 4's aggregates and 5 of at_call_conv left out of the check) |
| `lang2/source/be_com/lir_utils.pas` | 15 | begun, 12 of 15: trans_insert_move (0x912), flesh_out_new_load_or_store (0x288) and fix_store_through_lrs (0xC8E, with new_db_lts) TODO; lr_t memory_home (+24, the original's name), home_lr (+32), physical (+3 bit 7); rtn_t spills (+196); move_opcode.init; lir.pvt.pas lir_3c00; headings narrowed |

Batch A continued (translator PA4, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/lir_utils.pas` | 15 | done: trans_insert_move, flesh_out_new_load_or_store, fix_store_through_lrs (with new_db_lts); backend.ins.pas solution_t (lir_$build_operand's solution; post_6b8, now ra_utils_10), lir_$build_operand (op, sol, form: instr_attr_opnd_t), lir_$get_new_instruction_no_exceptions named; lir.pvt.pas spill_desc_t, the section spill_instr_forms (defined in lir_utils.pas), lir_3b80, lir_3ba8, lir_main_250, lir_main_760, flesh_out's heading (moved from backend.ins.pas: only lir_utils and ra_utils call it); isc_var_externs.ins.pas isc_user_routines_330/_340 |
| `lang2/source/be_com/tm_utils.pas` | 14 | done: operand_forms_mask.init and the four amse_*.init (the sections' bytes, PB2's define scheme); instr_attr_t interaction (+0 bits 3..0 and +1 bit 7, was b0 and b1_7); the headings named; can_increase_scale_by declared in the unit (no caller) |
| `lang2/source/be_com/sym.pas` | 19 | done: rtn_t l4, l8 (label lists), l12 (the uplevel-referenced variables); the sym headings named (nodes univ_ptr), sym_$fully_qualified_routine_name a procedure with top: boolean (bin, com follow); isc_$get_il_live_range's heading in backend.ins.pas (sym opens no ISC insert: isc_lir.ins.pas must not declare it again) |
| core | | flags named by dmp's printout (instr_hdr_t atomic_update .. do_not_delete, bb_flags_t depth .. executable, f14 kind/path_to, rtn f226 save_sl .. shares_frame, lr no_modify/serialize), rtn db_lr (+108), bb l42, next142; lir_$can_encode_as_immediate_operand's k |

Remaining in batch A after PA4: lir_main, fg_utils, post, lir (lir includes instr_attributes.init, of_string*.init, PC4's instr_size.init to confirm, and the lir.dir/build_*.init).  Notes for whoever continues: lir_$build_operand takes (op, sol: solution_ptr_t, form: instr_attr_opnd_t), lir_$get_new_instruction_no_exceptions (node, opc, flags, home, p5) though lir_utils pushes fewer (questions 198); lir.pvt.pas declares lir_main_250/_760, lir_3b80/_3ba8 for lir_main and lir to define; ra_utils defines ra_utils_10 (backend.ins.pas; PA4 named it post_6b8, but 0x48FB04 is ra_utils +0x10); lir_main_c4c is the zero register's segment (PC4); rtn db_lr is the DB register's live range, lir_3ba8 the memory's.

Remaining in batch B after PB5 (ra_utils done): ra, konst, sched, at_backend.  Readings for whoever continues (translator PB5, read but not translated):
- ra (0x266C58..0x26DF22, 62 routines, data A5 0x48F488, 0x66C bytes): +0 three initialized dump titles ('IP REGISTERS:%.', ...), +0x590 the bit masks 1..0x80, +0x598 three initialized words (13, 13, 18); +0x5AC/+0x5B0 and +0x5B4 the reserved floating and integer registers, +0x5C0/+0x5C4 and +0x5C8 the unallocatable ones (complements; the 64-bit sets stored low longword first), +0x5D0 and +0x5D4 maxima, +0x5DC the simple-id counter, +0x5E0 the live ranges' serial numbers (lr +58), +0x5EC/+0x5F0 the zero registers from target_properties, +0x614..+0x61C the calls' clobbers, +0x628/+0x62C the blocks holding opcode 132 and the ENTRY, +0x648 the stack frame's objects (chained at a VAR_NAME's +76, a FORTRAN symbol's +66), +0x64C the live ranges initialized this pass (chained at +12), +0x650 the debug level (ra.pvt.pas ra_650), +0x660 the register class (1, 2, 3), +0x668 the frame-allocation flag; +1176.. the aversion/preference records' fixed heaps, +1364/+1388/+1412 the three conflict bit matrices (complex x complex triangular by ra_$calc_canonical_desc_bit, complex x simple, simple x simple; records of ra_$init_descriptor: bits, words, size, vector).  The spill costs are single reals through fpp_$/fpp_$eslv (docs/dpc-gaps.md 7); docs/prism-isa.md "The spill model" has the rest.
- at_backend (0x221A60..0x222B3A, 15 routines, data A5 0x485830): the phase table (+0, 20 entries of 36 bytes, initialized from .rwdi): the debug switch letter (+0: i f m d k h t l c v o x s r p j a g z b), +1 and +2 two flags (+2: the phase is turned off at low optimization (lir_main_da4: cargs -OPT 3 or less, or +0x282 bits 16..15 = 3); +1: it then still runs: MMT, TRANS, LIFE, COM, SCHED, POST have both, KONST, IV, OLI only +2), +4 a mask of targets (target_properties +0x12) the phase is skipped for (0 in every entry), +6 the prfpkg phase number (22..40), the four routines (+8 begin_compilation, +12 process_routine (ISC's is isc_$begin_routine), +16 end_routine, +20 end_compilation; nil where absent: DBG_LIFE's first and last, ZZZZZ's last two, BIN's last three) and the name (+24, 12 characters).  +720/+722 the routine's qualified name (a varying string), +984 the name -DBG queries for, +1248 the routine heap, +0x4FC the routine record get_calling_conventions makes (an rtn_t: +0 the node, +16 the conventions, +148/+152 their clobbers, +226 bit 1 needs_db): **docs/questions.md 188 is answered, at_backend_4fc is the routine being compiled**.  codegen runs phases 0..18 forward (run_phase: dumps before and after with the switches' bits 3 and 4, perfstart/perfstop, lir_main_$begin_routine before ISC and lir_main_$build_initial_epilog after it), then their end_routine in reverse, then lir_$end_routine with no argument (pattern 132).

Question 174 is answered: these units open the prelude (fga, hal, life and sanity now do).

Remaining in batch A after PA3: lir_utils' three routines; lir, lir_main, sym, fg_utils, tm_utils, post.  Translator PA2's remaining list read: sanity_$check_entire_routine; call_conv (question 167), lir_utils, lir, lir_main, sym, fg_utils, tm_utils, post.  Notes for whoever continues: sym, tm_utils (and fga, hal, life, sanity) open backend.ins.pas without the lang prelude: backend.ins.pas must not use the prelude's types (rtn_t.node is univ_ptr for that reason), and a unit that needs il_180, cargs_$options or idntk declares them through views of its own (fga.pas; docs/questions.md 174).  sym calls isc_$get_il_live_range without opening an ISC insert.  tm_utils includes the named sections' initializers (operand_forms_mask.init, the amse_*.init), which question 161 has not settled.

Batch A continued (translator PA5, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/lir_main.pas` | 25 | done: the module's data (0xDB8 bytes) every cell extern and defined in address order (byte cells shifted: dpc gap 37, questions 219), the section lir_main_readonly_tables; solution_t 432 bytes (lr2, shift, sym named); rtn_t conv (+16), frame_size (+48), saved_ip/saved_fp (+160..), l172, l176, save_end (+204), w218, w222, w224; lir_3b80 a record (lir_inherited_t); lir_3e60/3f90/4090 typed; lir_main_b40 an array, lir_main_c48 lts_ptr_t; lir_main_$ headings named; ISC: isc_user_routines_328..358, isc_$is_a_register_candidate, isc_$get_home_solution, rewrite_$entry |

| `lang2/source/be_com/fg_utils.pas` | 53 | done: rtn_t l84 (the blocks without an interval head), dfs_first/dfs_last (+64, +68), bb_t members (+138); the headings named (drop_this_block, generate/insert_join_birthpoint, add_jbi, dominators' ssa, recompute_postnum, recompute_dominators_and_dfs_lists' how, compute_lr_lifetime, recompute_ssa_form_for_lr); its walks keep state in bb +20 bits 6..3 (f20), l134, next142, mark146, l150, members (documented in the unit) |

Remaining in batch A after PA5: post, lir (see PA4's notes; instr_size.init still to confirm, questions 221).  post_6b8 is ra_utils_10 (PB5): post defines none of the solutions.

Batch C (translators PC, PC2, PC3, PC4, PC5, 2026-11-11):

| unit | routines | notes |
|------|----------|-------|
| `lang2/source/be_com/tr_utils.pas` | 68 | done (PC): the transformations' utilities |
| `lang2/source/be_com/mmt_utils.pas` | 37 | done (PC, PC2): descriptors, tokens, MMT_SEQs |
| `lang2/source/be_com/mmt.pas` | 39 | done (PC2): the memory model; mmt.pvt.pas's views of lr_t, rtn_t |
| `lang2/source/be_com/trans.pas` | 37 | done (PC2, PC3): the alpha and omega motions, branches, copy elimination; bb_t +42, +122, +150 through trans_bb_v_t |
| `lang2/source/be_com/com.pas` | 63 | done (PC3, PC4): the CSE pass over the dominator tree, load/store elimination, loop hoisting, memory kept in registers across loops, sinking into loop exits, a88k_$cossin; bb_t +42 and +142 (com's block lists), the IL node's +192 and an address constant's +16 through views; com_$compute_cses narrowed (rtn, level); rtn_t lr108 read as the DB register's live range, lir_main_c4c as the zero register's segment; dpc gap 30 (a local set in a register) |
| `lang2/source/be_com/iv.pas` | 127 | done (PC4, PC5): the heaps and the expressions (PC4); the induction records in iv.ins.pas (iv_lts_t, iv_addr_t, iv_iexpr_t, iv_class_t, iv_var_t), the operands made from elaborated expressions, loop invariance, the candidates' propagation and verification (ivr_), the induction expressions' recognition (ixr_; an instantiation, iv_inst_t, returned as a record) and strength reduction (ixt_), the interval walk (routines passed as `in` routine pointers, constants by address), recompute_for_oli, process_routine (PC5); iv_utils_$live_range_from_elaborated_expression and _compare_address_expressions narrowed; bb +138/+142, lts +24, lir_main +0xC48 through views or casts (reported to batch A); opcodes/instr_size.init reconstructed from iv's .rwdi (lir includes it too; 212 of the image's 384 words, as iv_opc_kind) |
| `lang2/source/be_com/oli.pas` | 120 | begun (PC6): 80 of 120, 0x257D60 .. 0x25CECA in address order (callees first) and three leaves after it: the schedule's tables and the queue, the prologue's zero registers, the loop walk, size_and_shape_ok, the reductions (kind 5 records at a segment's l24), the induction addresses, the dependence tests (simple, gcd, slope, Banerjee's, recurrence), oli_$compare_memory_references, the five-operand candidates, iteration_interval, the modulo scheduler (enable counts, find_open_slot, schedule_instr, data flow constraints, schedule), register pressure, materialized values, the memory fans (mmt_seq), the copies' sequence, the columns' live ranges, link_lrs; the 40 left (get_induction_variable_adjustment 0x25CFE2 .. oli_$end_routine 0x2612A0) listed in the unit's header with notes; the module's data at its offsets (oli_red_kind and oli_add_opc from .rwdi); batch A fields through views (bb l70/l74/l78 as interval links, lts l24 as iv's or oli's record, lts +34 and instr +28/+30/+42 as scheduler words); dpc gap 7 (0.0 passed to dpcontk/rlcontk: one rewrite rule) |

Remaining in batch A after PA2: sanity_$check_entire_routine; call_conv (question 167), lir_utils, lir, lir_main, sym, fg_utils, tm_utils, post.  Notes for whoever continues: sym, tm_utils (and fga, hal, life, sanity) open backend.ins.pas without the lang prelude: backend.ins.pas must not use the prelude's types (rtn_t.node is univ_ptr for that reason), and a unit that needs il_180, cargs_$options or idntk declares them through views of its own (fga.pas; docs/questions.md 174).  sym calls isc_$get_il_live_range without opening an ISC insert.  tm_utils includes the named sections' initializers (operand_forms_mask.init, the amse_*.init), which question 161 has not settled.

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
