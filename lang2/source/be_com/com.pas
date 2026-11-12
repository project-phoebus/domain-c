{ com - the PRISM back end's common subexpression phase (COM): the
  blocks' instructions optimized (cses, loads and stores eliminated,
  instructions hoisted out of loops, memory references in loops kept
  in registers), the memory model analyzed, then the motions (trans),
  life and copy elimination.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x225DF4  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x225E16  clean_up_this_mess_right_now_young_man (internal)
    --------  0x225E48  operand_reg_like_kind
    --------  0x22C02A  com_$begin_compilation
    --------  0x22C064  com_$end_compilation
    --------  0x22C080  com_$end_routine
    A5 0x485E60: the module's data: com_heap (+0), com_name (+24, a
    varying string: the routine's fully qualified name), +284 (set to
    100), com_rtn (+288), com_level (+296), +304 and +308 (booleans),
    +306, +312, +316.

  Not known from the original: every local, parameter and cell name. }

{ TODO(pascal) com: 6 of the image's 63 routines.  Remaining, in
  address order: local_replace_output (0x225E82, 0x612 bytes),
  find_exit_writer (0x226514), make_entering_lts (0x22670C),
  find_calls_snuggle_move (0x22676E), com_$replace_oprs_value
  (0x226898), no_reg_like_kinds (0x226E38), build_loads (0x226E62),
  build_stores (0x22723E), replace_mem_instrs (0x2274D0),
  ip_mem_reference (0x227A0A), analyze_candidates (0x227A8C),
  add_lr_to_list (0x227C1A), add_lr_to_list_uniquely (0x227C6A),
  add_lrs_to_ssa_list (0x227CB8), is_invariant (0x227D9C),
  loop_invariant_addr (0x227E04), consider_mem_dependents (0x227EDE),
  partition_memory (0x2282B8), is_join_bp (0x2283A8, global),
  worth_hoisting (0x2283DC), find_loop_memory_hoist_candidates
  (0x22841A), lr_unconsumed_in_loop (0x22876C),
  lr_value_same_on_loop_exit (0x228836), suck_instrs_from_loop
  (0x228968), collect_exit_blocks (0x228D58), collect_loop_contents
  (0x228DF2), entry_blocks_safe (0x228F50), exit_blocks_safe
  (0x228F8A), loop_memory_analysis (0x229074), cvt_short_load_to_32_bits
  (0x22915E), eliminate_load (0x22930C), attempt_load_elimination
  (0x22960E), excise_a_store (0x2297D2), simple_mmt_seq_input
  (0x2298D2) with get_the_right_instr (0x229968, nested),
  ltss_on_stores_to_same_addr (0x2299CA, global), store_is_redundant
  (0x229A9E, global), get_mem_birthpoint (0x229B3A, global),
  safe_to_ignore_do_not_delete (0x229BB2), convert_store_to_seq
  (0x229C96), attempt_store_elimination (0x229D86),
  attempt_do_not_delete_removal (0x22A03C), move_is_zero (0x22A0B2),
  replace_zero_valued_lrs (0x22A19A), calc_last_legal_dom_bb
  (0x22A224), def_dominates_use (0x22A276), bb_postdominates
  (0x22A2B8), maybe_hoist_instr_from_loop (0x22A2F6), connect_physical
  (0x22A6B4), call_cossin (0x22A760: lir_3f94 .. lir_3f9c), safe_cc_write
  (0x22AEFC), operand_is_trapcc_input (0x22AFB0), destroy_instr
  (0x22AFF0), process_instruction (0x22B46C, 0x888 bytes),
  optimize_block (0x22BEAA), com_$compute_cses (0x22BFD2: sets com_rtn
  and com_level, clears +308 and +304, optimize_block(rtn^.bbs, nil)
  between mrh_$mark and mrh_$release_to_mark of com_heap),
  com_$process_routine (0x22C082: the name, the level, +284 := 100,
  sanity check; unless switches 15 (and cargs +0x4437D4) the snuggle
  moves and lts properties, a dump with switch 3; unless switches 15 or
  14: compute_cses, clean_up_this_mess..., unless switch 12 the memory
  analysis (unless switch 9 mmt_utils_$analyze_blocks), then
  loop_memory_analysis and compute_cses again while +304; with +308
  attempt_do_not_delete_removal; the global walk, the motions,
  replace_zero_valued_lrs, life, copy elimination, each with the
  level's messages and dumps). }
module com;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang/lang/source/at_lib_dsc.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

var
  com_heap: mrh_$heap_t;                { +0: the hash table's heap }
  com_20: integer32;                    { +20 }
  com_name: varying [256] of char;      { +24: the routine's name }
  com_284: integer32;                   { +284 (set to 100) }
  com_rtn: rtn_ptr_t;                   { +288 }
  com_292: integer32;                   { +292 }
  com_level: integer32;                 { +296: the switches' level }
  com_300: integer32;                   { +300 }
  com_304: boolean;                     { +304 }
  com_306: integer;                     { +306 }
  com_308: boolean;                     { +308 }
  com_312: integer32;                   { +312 }
  com_316: integer32;                   { +316 }

{ clean_up_this_mess_right_now_young_man - rtn's instructions numbered
  again from 1 in code order.  0x225E16, 0x32 bytes, no frame: the
  count a longword stored as a word. }

procedure clean_up_this_mess_right_now_young_man(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  n: integer32;
  b: bb_ptr_t;
  i: instr_ptr_t;
begin
  n := 1;
  b := rtn^.bbs;
  while b <> nil do begin
    i := b^.first;
    while i <> nil do begin
      i^.num := n;
      n := n + 1;
      i := i^.next;
    end;
    b := b^.next;
  end;
end;

{ operand_reg_like_kind - the like kind of a register kind (ip_reg,
  fp_reg, fp_reg_pair), any other kind itself.  0x225E48, 0x3A bytes
  (loads A5: global, though no other unit calls it): k by address. }

function operand_reg_like_kind(
    in k: operand$t): operand$t;
var
  r: operand$t;
begin
  r := k;
  case k of
    operand$ip_reg:
      r := operand$ip_reg_like;
    operand$fp_reg:
      r := operand$fp_reg_like;
    operand$fp_reg_pair:
      r := operand$fp_reg_pair_like;
  end;
  operand_reg_like_kind := r;
end;

{ com_$begin_compilation - com_heap made (flags 1, items of 8 bytes).
  0x22C02A, 0x26 bytes: the flags and size pushed as one longword
  (pattern 105). }

procedure com_$begin_compilation;
begin
  mrh_$initialize(com_heap, 1, 8, 'COM hash table heap%');
end;

{ com_$end_compilation - com_heap released.  0x22C064, 0x1C bytes. }

procedure com_$end_compilation;
begin
  mrh_$release_all(com_heap);
end;

{ com_$end_routine - nothing.  0x22C080, 2 bytes. }

procedure com_$end_routine(
    rtn: rtn_ptr_t);
begin
end;
