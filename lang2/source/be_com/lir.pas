{ lir - the LIR builder (cc.a88k only): the ISC's solutions made into
  instructions, operands, live ranges, lifetime segments, labels,
  basic blocks and flow graph edges; the allocators the other phases
  use for them (lir_$new_*, lir_$optimizer_new_*), the calls'
  argument registers, the routine's reinitialization and its end.

  TODO(pascal) lir.pas: begun by translator PA6 (7 of 63 routines,
  0x242820 .. 0x242ED4 in address order: lir_$isc_bugcheck, true_il,
  zero, initialize_physical_solutions, lir_$begin_compilation,
  is_volatile_location, lir_$complete_top_level_node_inherited_attrs).
  The other 56 (begin_instruction 0x242EF4 .. lir_$strip_may_gen_
  exception 0x248A60) remain, with the module's data: lir's own cells
  are declared extern below as they are met (lir_<offset>), and must be
  defined in address order with the data (as lir_main.pas does) when
  the unit is complete; the lir.dir/build_*.init and build_access.init
  files are stubs (their tables are among the module data's
  initialized ranges, +0x28 .. +0xC06 and +0x4190; docs/backend-plan.md,
  PA6's notes).  The section lir_readonly_tables (0x2BDA2C, 0x694
  bytes) is complete: instr_size.init (+0, 384 words),
  solution_kind.init (+0x300), solution_string.init (+0x340),
  solution_string_length.init (+0x660).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x242820  lir_$isc_bugcheck
    --------  0x242854  true_il (internal)
    --------  0x242868  zero (internal)
    --------  0x242880  initialize_physical_solutions (internal)
    --------  0x242994  lir_$begin_compilation
    --------  0x242E0C  is_volatile_location (internal)
    --------  0x242E7E  lir_$complete_top_level_node_inherited_attrs
    --------  0x242EF4  begin_instruction (internal)
    --------  0x24327C  copy_build_instruction (internal)
    --------  0x243398  lir_$get_new_instruction (internal)
    --------  0x2433C2  lir_$get_new_instruction_no_exceptions
    --------  0x243402  lir_$add_flow_graph_edge
    --------  0x24346A  add_instruction_to_basic_block (internal)
    --------  0x2434DE  lir_$new_basic_block
    --------  0x243572  lir_$note_target_of_asynchronous_flow
    --------  0x2435AA  get_basic_block (internal)
    --------  0x2436DE  add_fge_to_labeled_basic_block (internal)
    --------  0x243784  lir_$new_label
    --------  0x2437AC  lir_$label
    --------  0x2438CE  lir_$free_lifetime_segment
    --------  0x2439B8  lir_$new_lifetime_segment
    --------  0x243A1E  lir_$alloc_live_range (internal)
    --------  0x243AB0  lir_$new_live_range (internal)
    --------  0x243ACC  lir_$new_live_range_ip_reg
    --------  0x243AEC  lir_$new_live_range_fp_reg
    --------  0x243B0C  lir_$new_live_range_fp_reg_pair
    --------  0x243B4C  lir_$new_live_range_for_kind
    --------  0x243B8E  lir_$new_instruction
    --------  0x243BE8  lir_$break_basic_block
    --------  0x243C0E  lir_$opt_new_instruction (internal)
    --------  0x243DD8  lir_$optimizer_new_n_opr_instr
    --------  0x243E04  lir_$optimizer_new_instruction
    --------  0x243E2E  get_lts_in_current_bb (internal)
    --------  0x243F24  build_non_register_reference (internal)
    --------  0x244078  convert_to_intend_to_modify (internal)
    --------  0x24409A  lir_$build_operand
    --------  0x245710  note_entry_to_handler_from_runtime (internal)
    --------  0x245746  no_associated_modify_operand (internal)
    --------  0x24579C  create_associated_modify_operand (internal)
    --------  0x2457F4  lir_$complete_instruction
    --------  0x2467B6  lir_$dispatch_instruction
    --------  0x24691E  lir_$branch_instruction
    --------  0x2469F4  lir_$operate_and_branch_instruction
    --------  0x246AFE  prolog_label_for_specific_exception (internal)
    --------  0x246BC6  lir_$use_trap_for_exception_raise
    --------  0x246C28  lir_$trap_instruction
    --------  0x246D90  lir_$simple_instruction
    --------  0x246FAE  lir_$field_instruction
    --------  0x2470EC  lir_$load_instruction
    --------  0x2473D8  lir_$mfpr_instruction
    --------  0x2474CE  lir_$common_lhs_rhs_token
    --------  0x2475B2  lir_$disjoint_lhs_and_rhs_tokens
    --------  0x24771E  lir_$store_instruction
    --------  0x247968  lir_$mtpr_instruction
    --------  0x247A5E  lir_$begin_fortran_io_sequence
    --------  0x247B80  lir_$begin_call_or_svc
    --------  0x247BDC  call_or_svc_argument_register (internal)
    --------  0x247D4E  add_serialized_lr_operands (internal)
    --------  0x247DFC  lir_$emit_call_or_svc
    --------  0x2482A4  lir_$end_call_or_svc
    --------  0x2482CE  lir_$reinitialize
    --------  0x2489AA  lir_$end_routine
    --------  0x248A60  lir_$strip_may_gen_exception
    A5 0x487180: the module's data, 0x422C bytes (backend.ins.pas's and
    lir.pvt.pas's lir_ cells, the unit's own; most of +0x28 .. +0xC06
    initialized from .rwdi).

  Not known from the original: every local, parameter and cell name. }

module lir;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/common/source/exs.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_attributes.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/of_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/of_string_length.init';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';
%include 'lang2/source/be_com/lir.pvt.pas';
var (lir_readonly_tables)
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_size.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/solution_kind.init';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/solution_string.init';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/solution_string_length.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_action.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/build_access.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_arg_loc.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_high_bound.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_kind.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_like_kind.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_low_bound.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_message.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical_lrs.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical_ltss.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_properties.init';
%include 'lang2/source/be_com/utils.ins.pas';

type
  lir_name_t = packed array [1..4] of char;

  { A solution's bytes, for the flags set by offset (+82 bit 7, +84 bit
    6: not named yet). }
  lir_sol_bytes_ptr_t = ^lir_sol_bytes_t;
  lir_sol_bytes_t = packed array [0..431] of 0..255;

  lir_heap_ptr_t = ^mrh_$heap_t;

var
  { lir.pas's own cells met so far (A5 0x487180 + offset), to be
    defined with the module's data. }
  lir_e90: extern mrh_$heap_t;          { +0xE90: 'lir IP LR heap' }
  lir_ea8: extern mrh_$heap_t;          { +0xEA8: 'lir generic LR heap' }
  lir_ec0: extern mrh_$heap_t;          { +0xEC0: 'lir FP pair LR heap' }
  lir_ed8: extern mrh_$heap_t;          { +0xED8: 'lir FP LR heap' }
  lir_ef0: extern mrh_$heap_t;          { +0xEF0: 'lir instruction heap' }
  lir_f08: extern mrh_$heap_t;          { +0xF08: 'lir flow graph edge
                                          heap' (16 bytes, not cleared) }
  lir_f20: extern mrh_$heap_t;          { +0xF20: 'lir basic block heap'
                                          (156 bytes) }
  lir_2f58: extern array [0..3103] of char;  { +0x2F58: 0xC20 bytes
                                          lir_$begin_compilation clears }
  lir_41ac: extern univ_ptr;            { +0x41AC: SF's node }
  lir_41b0: extern integer32;           { +0x41B0 }
  lir_41b4: extern mrh_$mark_t;         { +0x41B4: lir_3c00's mark }
  lir_41c4: extern mrh_$mark_t;         { +0x41C4: lir_e90's mark }
  lir_41c8: extern mrh_$mark_t;         { +0x41C8: lir_ea8's mark }
  lir_41cc: extern mrh_$mark_t;         { +0x41CC: lir_ec0's mark }
  lir_41d0: extern mrh_$mark_t;         { +0x41D0: lir_ed8's mark }
  lir_41e0: extern integer32;           { +0x41E0 }
  lir_421a: extern boolean;             { +0x421A: cargs +0x251 bit 3 }
  { cargs.pas's data (A5 0x443570) +0x251, as a byte (cargs_$options'
    flags: bit 3 read here). }
  cargs_251: extern char;

{ LIR_$ISC_BUGCHECK - 'ISC pass 2 failure'.

  0x242820, 0x1E bytes. }

procedure lir_$isc_bugcheck;
begin
  bug_check('ISC pass 2 failure%$');
end;

{ true_il - the IL statement an inherited attributes record stands for:
  its node, or (the node's +0 bit 7) its +12.

  0x242854, 0x14 bytes, no frame. }

function true_il(
    attrs: univ_ptr): univ_ptr; options(val_param, internal);
type
  flag_ptr_t = ^packed record
      b7: boolean;
    end;
var
  p: ^lir_inherited_t;
begin
  p := attrs;
  if flag_ptr_t(p^.node)^.b7 then
    true_il := univ_ptr(p^.l12)
  else
    true_il := p^.node;
end;

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0).

  0x242868, 0x18 bytes, no frame (pattern 100). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param, internal);
type
  longs_t = array [1..65536] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to (n + 3) div 4 do
      q^[k] := 0;
  end;
end;

{ initialize_physical_solutions - the physical registers' solutions made
  by the ISC under their names (Rn, Fn, Xn, PC for register 30): which
  0 the integer registers 0..31 (lir_3e60, their nodes in
  lir_main_ac0), above 0 the floating registers 0..63 (lir_3d60,
  lir_main_b40), below 0 the even floating registers' pairs (lir_3c60;
  the odd ones nil; the pair's node the register's).

  0x242880, 0x10E bytes, no A5: the name a local longword set to four
  blanks, the number's digits from k div 10 (m$dis$llw); the three
  tables stepped by pointers. }

procedure initialize_physical_solutions(
    which: integer32); options(val_param, internal);
type
  node_ptr_t = ^univ_ptr;
var
  name: lir_name_t;
  k: integer32;
  q: integer;
  sol: solution_ptr_t;
begin
  name := '    ';
  for k := 0 to 63 do begin
    q := k div 10;
    if q = 0 then
      name[2] := chr(48 + k)
    else begin
      name[2] := chr(48 + q);
      name[3] := chr(48 + k - q * 10);
    end;
    if which = 0 then begin
      if k <= 31 then begin
        if k = 30 then
          lir_3e60[k] := isc_$init_well_known_ip_reg('PC  ', k)
        else begin
          name[1] := 'R';
          lir_3e60[k] := isc_$init_well_known_ip_reg(name, k);
        end;
        lir_main_ac0[k] := lir_3e60[k]^.node;
      end;
    end
    else if which > 0 then begin
      name[1] := 'F';
      lir_3d60[k] := isc_$init_well_known_fp_reg(name, k);
      lir_main_b40[k] := lir_3d60[k]^.node;
    end
    else if odd(k) then
      lir_3c60[k] := nil
    else begin
      name[1] := 'X';
      lir_3c60[k] := isc_$init_well_known_fp_reg_pair(name, k);
      lir_3c60[k]^.node := lir_main_b40[k];
    end;
  end;
end;

{ LIR_$BEGIN_COMPILATION - the LIR's state for the compilation: the
  ISC's well-known types, the builder's fixed solutions (lir_main's
  five and ra_utils' cleared; lir_main_910 of kind 3, lir_main_760 of
  14, lir_main_250 of 5 with two flags, lir_main_5b0 physical), the
  heaps, the physical registers' solutions, the ISC's register
  solutions (registers 30 and 31; the well-known AP, DB, RPC, SL, ER, LB
  and SF) and the heaps' marks.

  0x242994, 0x344 bytes: the solutions cleared 0x1B0 bytes each (zero);
  the heaps' flags and default sizes one longword each (pattern 105);
  `bset #14' and `bset #15' on bytes (bits 6 and 7). }

procedure lir_$begin_compilation;
begin
  isc_$init_well_known_types(isc_user_routines_344, isc_user_routines_348,
                             isc_user_routines_34c);
  lir_41e0 := 0;
  lir_421a := (ord(cargs_251) & 8) <> 0;
  zero(addr(lir_main_910), 16#1B0);
  lir_main_910.kind := 3;
  zero(addr(lir_main_760), 16#1B0);
  lir_main_760.kind := 14;
  zero(addr(lir_main_5b0), 16#1B0);
  lir_main_5b0.f78.physical := true;
  zero(addr(ra_utils_10), 16#1B0);
  zero(addr(lir_main_400), 16#1B0);
  zero(addr(lir_main_250), 16#1B0);
  lir_main_250.kind := 5;
  lir_sol_bytes_ptr_t(addr(lir_main_250))^[84] :=
      lir_sol_bytes_ptr_t(addr(lir_main_250))^[84] ! 16#40;
  lir_sol_bytes_ptr_t(addr(lir_main_250))^[82] :=
      lir_sol_bytes_ptr_t(addr(lir_main_250))^[82] ! 16#80;
  zero(addr(lir_2f58), 16#C20);
  mrh_$initialize(lir_f20, 1, 156, 'lir basic block heap%');
  mrh_$initialize(lir_f08, 0, 16, 'lir flow graph edge heap%');
  mrh_$initialize(lir_ef0, 1, 0, 'lir instruction heap%');
  mrh_$initialize(lir_3c48, 1, 12, 'lir label operand heap%');
  mrh_$initialize(lir_3c30, 1, 16, 'lir label heap%');
  mrh_$initialize(lir_ea8, 1, 88, 'lir generic LR heap%');
  mrh_$initialize(lir_e90, 1, 88, 'lir IP LR heap%');
  mrh_$initialize(lir_ed8, 1, 88, 'lir FP LR heap%');
  mrh_$initialize(lir_ec0, 1, 88, 'lir FP pair LR heap%');
  mrh_$initialize(lir_3c18, 1, 52, 'lir non-register LTS heap%');
  mrh_$initialize(lir_3c00, 1, 52, 'lir register LTS heap%');
  mrh_$initialize(lir_heap_ptr_t(addr(lir_3f78))^, 1, 0,
                  'at_call_conv descriptor heap%');
  mrh_$initialize(lir_heap_ptr_t(addr(lir_3f60))^, 1, 0,
                  'isc rewrite heap%');
  initialize_physical_solutions(0);
  initialize_physical_solutions(1);
  initialize_physical_solutions(-1);
  isc_user_routines_330 := lir_3e60[30];
  isc_user_routines_320 := lir_3e60[31];
  isc_user_routines_31c := isc_user_routines_320;
  isc_user_routines_33c := isc_$init_well_known_ip_reg('AP  ', -1);
  isc_user_routines_338 := isc_$init_well_known_ip_reg('DB  ', -1);
  lir_main_da0 := isc_$init_well_known_ip_reg('RPC ', -1);
  isc_user_routines_32c := isc_$init_well_known_ip_reg('SL  ', -1);
  isc_user_routines_328 := isc_$init_well_known_ip_reg('ER  ', -1);
  isc_user_routines_334 := isc_$init_well_known_ip_reg('LB  ', -1);
  isc_user_routines_340 := isc_$init_well_known_ip_reg('SF  ', -1);
  lir_41ac := isc_user_routines_340^.node;
  lir_41b0 := 0;
  lir_41b4 := mrh_$mark(lir_3c00);
  lir_41c8 := mrh_$mark(lir_ea8);
  lir_41c4 := mrh_$mark(lir_e90);
  lir_41d0 := mrh_$mark(lir_ed8);
  lir_41cc := mrh_$mark(lir_ec0);
end;

{ is_volatile_location - whether the IL node is a volatile location (nil
  is): by its kind (+2), a reference (one of eleven kinds) whose +4
  flags have 16#10019, a variable (109) or common member (110) whose
  flags (+32, +24) have 27.

  0x242E0C, 0x58 bytes, no frame: the kinds a constant set after the
  routine (`btst' of 0x242E64, the elements 207..0: pattern 102). }

function is_volatile_location(
    node: univ_ptr): boolean; options(val_param, internal);
type
  node_v_ptr_t = ^node_v_t;
  node_v_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    l4: integer32;                      { +4 }
    space8: array [8..23] of char;      { +8 }
    l24: integer32;                     { +24 }
    l28: integer32;                     { +28 }
    l32: integer32;                     { +32 }
  end;
var
  n: node_v_ptr_t;
begin
  n := node;
  if n = nil then
    is_volatile_location := true
  else if n^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189,
                      205] then
    is_volatile_location := (n^.l4 & 16#10019) <> 0
  else if n^.kind = 109 then
    is_volatile_location := (n^.l32 & 27) <> 0
  else if n^.kind = 110 then
    is_volatile_location := (n^.l24 & 27) <> 0
  else
    is_volatile_location := false;
end;

{ LIR_$COMPLETE_TOP_LEVEL_NODE_INHERITED_ATTRS - for a statement of one
  of twenty kinds, attrs' l4 the statement's +12, w34 its +43..+44
  word, w32 its +20 word.

  0x242E7E, 0x58 bytes: the kinds a constant set after the routine
  (`btst' of 0x242ED6, the elements 239..0). }

procedure lir_$complete_top_level_node_inherited_attrs(
    attrs: univ_ptr);
type
  stmt_v_ptr_t = ^stmt_v_t;
  stmt_v_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    space4: array [4..11] of char;      { +4 }
    l12: integer32;                     { +12 }
    space16: array [16..19] of char;    { +16 }
    w20: integer;                       { +20 }
    space22: array [22..41] of char;    { +22 }
    l42: integer32;                     { +42 }
  end;
var
  p: ^lir_inherited_t;
  s: stmt_v_ptr_t;
begin
  p := attrs;
  s := true_il(attrs);
  if s^.kind in [139, 140, 141, 142, 144, 148, 149, 150, 151, 188, 191,
                 214, 215, 223, 224, 225, 227, 228, 231, 233] then begin
    p^.l4 := s^.l12;
    p^.w34 := rshft(s^.l42 & 16#FFFF00, 8);
    p^.w32 := s^.w20;
  end;
end;
