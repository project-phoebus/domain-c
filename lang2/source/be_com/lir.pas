{ lir - the LIR builder (cc.a88k only): the ISC's solutions made into
  instructions, operands, live ranges, lifetime segments, labels,
  basic blocks and flow graph edges; the allocators the other phases
  use for them (lir_$new_*, lir_$optimizer_new_*), the calls'
  argument registers, the routine's reinitialization and its end.

  TODO(pascal) lir.pas: begun by translator PA6 (7 routines, 0x242820 ..
  0x242ED4) and continued by PA7 in address order through
  lir_$build_operand (0x24409A): 37 of 63.  The other 26
  (note_entry_to_handler_from_runtime 0x245710 .. lir_$strip_may_gen_
  exception 0x248A60) remain, with the module's data: lir's own cells are
  declared extern below (lir_<offset>, the build_ tables by their .init
  files' names), and must be defined in address order with the data
  (as lir_main.pas does) when the unit is complete; the lir.dir/
  build_*.init and build_access.init files are stubs.  Their tables
  (read by lir_$build_operand; PA7) lie in the module data in the
  reverse of their include order: build_properties +0x000 (30 rrp
  words, by build kind 0..29), build_physical_ltss +0x040,
  build_physical_lrs +0x0B8 (30 pointers each), build_physical +0x130
  (30 two-byte), build_message +0x170 (30 pointers to the messages laid
  out before A5, 0x486D98 ..), build_low_bound +0x1E8 (30 longwords),
  build_like_kind +0x260, build_kind +0x2A0 (30 two-byte each),
  build_high_bound +0x2E0, build_arg_loc +0x358 (30 two-byte),
  build_access +0x398 (4 words), build_action +0x3A0 (25 solution kinds
  x 43 forms, two-byte).  The section lir_readonly_tables (0x2BDA2C,
  0x694 bytes) is complete: instr_size.init (+0, 384 words),
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

  { A longword counter whose low word is read on its own (lir_41a4, the
    build area's size, passed to mrh_$alloc; lir_41bc, the labels'
    count, a label's and a block's number). }
  lir_count_t = record
    case integer of
      1: (l: integer32);
      2: (hi: integer;
          lo: integer);
  end;

  { An instruction's first longword, built in a frame longword (pattern
    115). }
  lir_ihdr_t = record
    case integer of
      1: (h: instr_hdr_t);
      2: (l: integer32);
  end;

  { A set of properties as its two bytes (an operand's +1 is the low
    byte). }
  lir_set_bytes_t = record
    case integer of
      1: (s: rrp$set_t);
      2: (hi: 0..255;
          lo: 0..255);
  end;

  { An instruction's +32 as words: the line add_instruction_to_basic_block
    keeps (the inherited attributes' w34 an instruction is made with). }
  lir_ipos_ptr_t = ^lir_ipos_t;
  lir_ipos_t = record
    space0: array [0..31] of char;      { +0 }
    line: 0..65535;                     { +32 }
    w34: integer;                       { +34 }
  end;

  lir_desc_ptr_t = ^alias_$desc_t;

  { A label (lir_$new_label: 16 bytes from lir_3c30; sym.pas's
    sym_label_t, lir_main's lm_label_t): +4 its LABEL instruction, num
    its number, +10 bit 6 a target of asynchronous flow, bit 5 placed;
    +12 the forward references to it (label operands chained at their
    link, each holding its block at +8) until it is placed, then its
    block. }
  lir_label_ptr_t = ^lir_label_t;
  lir_label_t = record
    next: lir_label_ptr_t;              { +0 }
    instr: instr_ptr_t;                 { +4 }
    num: integer;                       { +8 }
    f10: packed record                  { +10 }
      required: boolean;                { .7 }
      async_target: boolean;            { .6 }
      in_bb: boolean;                   { .5 }
      b4_0: 0..31;
      b11: 0..255;                      { +11 }
      end;
    case integer of                     { +12 }
      1: (refs: opnd_ptr_t);
      2: (bb: bb_ptr_t);
  end;

  { An operand as lir_$build_operand leaves a register operand before
    lir_$complete_instruction makes its segment: +4 its properties, +8
    its live range (lir_main's lm_opw_t). }
  lir_pre_opnd_ptr_t = ^lir_pre_opnd_t;
  lir_pre_opnd_t = record
    h: opnd_hdr_t;                      { +0 }
    rrp: rrp$set_t;                     { +4 }
    w6: integer;                        { +6 }
    lr: lr_ptr_t;                       { +8 }
  end;

  { A table's element of a byte-sized value laid out in two bytes, the
    value first (pattern 154). }
  lir_b2_t = packed record
    v: 0..255;
    b1: 0..255;
  end;

  { The physical registers' segments and live ranges by register. }
  lir_lts_tab_ptr_t = ^lir_lts_tab_t;
  lir_lts_tab_t = array [0..63] of lts_ptr_t;
  lir_lr_tab_ptr_t = ^lir_lr_tab_t;
  lir_lr_tab_t = array [0..63] of lr_ptr_t;

  lir_msg_ptr_t = ^bug_check_$string_t;

var
  { lir.pas's own cells (A5 0x487180 + offset), to be defined with the
    module's data. }
  build_properties: extern array [0..29] of rrp$set_t;     { +0x000 }
  build_physical_ltss: extern array [0..29] of lir_lts_tab_ptr_t;  { +0x040 }
  build_physical_lrs: extern array [0..29] of lir_lr_tab_ptr_t;    { +0x0B8 }
  build_physical: extern array [0..29] of lir_b2_t;        { +0x130 }
  build_message: extern array [0..29] of lir_msg_ptr_t;    { +0x170 }
  build_low_bound: extern array [0..29] of integer32;      { +0x1E8 }
  build_like_kind: extern array [0..29] of lir_b2_t;       { +0x260 }
  build_kind: extern array [0..29] of lir_b2_t;            { +0x2A0 }
  build_high_bound: extern array [0..29] of integer32;     { +0x2E0 }
  build_arg_loc: extern array [0..29] of lir_b2_t;         { +0x358 }
  build_access: extern array [0..3] of rrp$set_t;          { +0x398 }
  build_action: extern array [0..24, 0..42] of lir_b2_t;   { +0x3A0 }
  lir_c08: extern lir_lts_tab_t;        { +0xC08: by floating register,
                                          its physical segment }
  lir_d08: extern array [0..31] of lts_ptr_t;   { +0xD08: by integer
                                          register }
  lir_d88: extern lr_t;                 { +0xD88: the integer condition
                                          codes' live range }
  lir_de0: extern lr_t;                 { +0xDE0: the floating condition
                                          codes' }
  lir_e38: extern lr_t;                 { +0xE38: the argument block
                                          memory's }
  lir_e90: extern mrh_$heap_t;          { +0xE90: 'lir IP LR heap' }
  lir_ea8: extern mrh_$heap_t;          { +0xEA8: 'lir generic LR heap' }
  lir_ec0: extern mrh_$heap_t;          { +0xEC0: 'lir FP pair LR heap' }
  lir_ed8: extern mrh_$heap_t;          { +0xED8: 'lir FP LR heap' }
  lir_ef0: extern mrh_$heap_t;          { +0xEF0: 'lir instruction heap' }
  lir_f08: extern mrh_$heap_t;          { +0xF08: 'lir flow graph edge
                                          heap' (16 bytes, not cleared) }
  lir_f20: extern mrh_$heap_t;          { +0xF20: 'lir basic block heap'
                                          (156 bytes) }
  lir_f38: extern array [0..2049] of lr_ptr_t;  { +0xF38: by argument
                                          block offset, its memory's live
                                          range }
  lir_2f40: extern alias_$desc_t;       { +0x2F40: the build area's alias
                                          descriptor }
  lir_2f58: extern instr_t;             { +0x2F58: the build area, the
                                          instruction begin_instruction
                                          begins (0xC20 bytes) }
  lir_41a0: extern integer32;           { +0x41A0: the highest argument
                                          block offset in lir_f38 }
  lir_41a4: extern lir_count_t;         { +0x41A4: the build area's size }
  lir_41a8: extern integer32;           { +0x41A8 }
  lir_41ac: extern univ_ptr;            { +0x41AC: SF's node }
  lir_41b0: extern integer32;           { +0x41B0 }
  lir_41b4: extern mrh_$mark_t;         { +0x41B4: lir_3c00's mark }
  lir_41b8: extern integer32;           { +0x41B8: the last line put in a
                                          block }
  lir_41bc: extern lir_count_t;         { +0x41BC: the labels made }
  lir_41c4: extern mrh_$mark_t;         { +0x41C4: lir_e90's mark }
  lir_41c8: extern mrh_$mark_t;         { +0x41C8: lir_ea8's mark }
  lir_41cc: extern mrh_$mark_t;         { +0x41CC: lir_ec0's mark }
  lir_41d0: extern mrh_$mark_t;         { +0x41D0: lir_ed8's mark }
  lir_41dc: extern lts_ptr_t;           { +0x41DC: the free segments,
                                          chained at next }
  lir_41e0: extern rtn_ptr_t;           { +0x41E0: the routine }
  lir_41e4: extern integer32;           { +0x41E4: the exception frame of
                                          new blocks }
  lir_41e8: extern integer32;           { +0x41E8: the last case jump
                                          base's node }
  lir_41ec: extern integer32;           { +0x41EC: the inherited
                                          attributes' l20 }
  lir_4200: extern integer32;           { +0x4200 }
  lir_4214: extern integer;             { +0x4214: the instructions in the
                                          current block }
  lir_421a: extern boolean;             { +0x421A: cargs +0x251 bit 3: the
                                          trace }
  lir_421c: extern boolean;             { +0x421C: the current block falls
                                          through to the next }
  lir_421e: extern boolean;             { +0x421E: the next block is a
                                          target of asynchronous flow }
  lir_4220: extern boolean;             { +0x4220: more than 1000
                                          instructions in the block }
  lir_4222: extern boolean;             { +0x4222: the next instruction
                                          starts a block }
  lir_4224: extern boolean;             { +0x4224 }
  lir_4226: extern boolean;             { +0x4226 }
  lir_4228: extern boolean;             { +0x4228: in an atomic sequence }
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
  lir_41e0 := nil;
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

{ begin_instruction - the instruction of opcode opc for the inherited
  attributes attrs (nil for none) begun in the build area (lir_2f58,
  its alias descriptor lir_2f40 in front of it): the previous one's
  bytes cleared, the header made from the opcode's attributes, the
  flags and the statement's line, the operands counted (the opcode's
  own; nopnds more for a call, an entry, a limit, an svc, a return or
  an immediate's list; one for the exception information when it may
  raise one, one for a load pair's or mfpr's exception register), its
  size kept (lir_41a4).  flags: bit 11 may raise an exception, 12
  none (the operand dropped), 13 home given (its alias descriptor
  made), 21 the atomic sequence begins, 22 a volatile location, 24 the
  descriptor inexact, 27 do not delete (lir$do_not_delete: stores
  only).  A new statement (attrs' w34) after more than 1000
  instructions in the block, or the atomic sequence's start, ends the
  block (lir_4222, lir_421c).

  0x242EF4, 0x2BA bytes, internal: the header built in a frame
  longword (-24) field by field (pattern 115); the opcode's class sets
  as constants (`btst' of a register); the operands' count compared
  `cmpil #255; ble' before the bug check with it by address.
  Not known from the original: the flags' names but lir$do_not_delete
  (its message's). }

procedure begin_instruction(
    attrs: lir_inherited_ptr_t;
    opc: integer;
    flags: integer32;
    home: univ_ptr;
    nopnds: integer32); options(val_param, internal);
var
  a: instr_attr_ptr_t;
  line: integer32;
  cls: integer;
  size: integer32;
  n: integer32;
  hw: lir_ihdr_t;
  k: integer32;
begin
  if (opc = 0) or (opc > 211) then
    bug_check('LIR_ BEGIN_INSTRUCTION -- opcode not support in target ISP%$');
  if (flags & 16#200000) <> 0 then
    if not lir_4228 then begin
      lir_4228 := true;
      lir_4222 := true;
      lir_421c := true;
    end;
  zero(addr(lir_2f58), lir_41a4.l);
  a := addr(instruction_attributes[opc]);
  lir_2f58.opc := opc;
  lir_2f58.l32 := integer32(attrs);
  if attrs = nil then begin
    lir_41ec := 0;
    line := 0;
  end
  else begin
    lir_$complete_top_level_node_inherited_attrs(attrs);
    lir_41ec := attrs^.l20;
    line := attrs^.w34;
  end;
  cls := a^.class;
  lir_2f58.class := chr(cls);
  if not (cls in [class$branch, class$fp_branch]) then
    if lir_4224 then
      lir_4222 := true
    else if (line <> 0) and lir_4220 and (line <> lir_41b8) then begin
      lir_4222 := true;
      lir_421c := true;
    end;
  size := instr_size[opc];
  n := a^.nopnds;
  hw.l := 0;
  hw.h.atomic_update := lir_4228;
  hw.h.may_generate_an_exception := a^.b11_7;
  hw.h.volatile_location := (flags & 16#400000) <> 0;
  hw.h.do_not_delete := hw.h.volatile_location;
  if (flags & 16#8000000) <> 0 then begin
    hw.h.do_not_delete := true;
    if cls <> class$store then
      bug_check('LIR_$BEGIN_INSTRUCTION -- lir$do_not_delete only permitted on stores%$');
  end;
  if cls in [class$branch, class$fp_branch] then
    hw.h.modify := 2;
  if cls = class$trap then
    hw.h.lsq := 1;
  if cls in [2, 4, 7, 14, 15, 16, 20, 21, 22, 23, 24, 27] then
    if (flags & 16#2000) <> 0 then begin
      if is_volatile_location(home) then begin
        hw.h.volatile_location := true;
        hw.h.do_not_delete := true;
      end;
      if not alias_$get_alias_desc(home, lshft(1, a^.w18 & 7), lir_2f40) then
        flags := flags & (~16#2000)
      else begin
        if (flags & 16#1000000) <> 0 then
          lir_2f40.inexact := true;
        if not alias_$ref_may_generate_exception(lir_2f40) then
          hw.h.may_generate_an_exception := false;
        if lir_2f40.class in [0, 11] then begin
          flags := flags & (~16#2000);
          if cls in [2, 4, 7, 12, 14, 20, 21, 23, 24] then
            hw.h.b2_7 := true
          else begin
            flags := flags ! 16#1000;
            hw.h.may_generate_an_exception := false;
            size := size - 12;
            n := n - 1;
          end;
        end
        else
          hw.h.b2_7 := true;
      end;
    end
    else if (flags & 16#1000) <> 0 then begin
      hw.h.may_generate_an_exception := false;
      size := size - 12;
      n := n - 1;
    end;
  if cls in [2, 4, 8, 11, 20, 24] then begin
    n := n + nopnds;
    size := size + 12 * nopnds;
  end;
  if lir_4226 then begin
    size := size + 12;
    n := n + 1;
  end;
  if (flags & 16#800) <> 0 then begin
    hw.h.may_generate_an_exception := true;
    if cls in [class$load_pair, class$mfpr] then begin
      size := size + 12;
      n := n + 1;
    end;
  end;
  if n > 255 then begin
    k := n;
    bug_check('LIR_$BEGIN_INSTRUCTION -- %ld operands requested; only 255 are supported%$', k);
  end;
  hw.h.nopnds := n;
  lir_41a4.l := size;
  lir_2f58.h := hw.h;
  lir_2f58.l28 := flags;
end;

{ copy_build_instruction - the instruction built in lir_2f58 copied to
  the routine's heap: one operand more for its exception information
  when it may raise one (none past 255), its alias descriptor (20
  bytes) in front of it (24 allocated) when it has one and its class
  takes one.

  0x24327C, 0xBA bytes, internal: the copy a longword at a time while
  the size (lir_41a4) is positive; the descriptor's five longwords.
  The message's routine name is 'LIR_\COPY_BUILD_INSTRUCTION' (the
  bytes). }

function copy_build_instruction: instr_ptr_t; options(internal);
type
  longs_t = array [1..776] of integer32;
var
  p: univ_ptr;
  i: instr_ptr_t;
  s: ^longs_t;
  d: ^longs_t;
  n: integer32;
  k: integer32;
begin
  if lir_2f58.h.may_generate_an_exception then begin
    if lir_2f58.h.nopnds = 255 then
      bug_check('LIR_\COPY_BUILD_INSTRUCTION -- instruction has 255 operands; no room for exception information%$');
    lir_41a4.l := lir_41a4.l + 12;
    lir_2f58.h.nopnds := lir_2f58.h.nopnds + 1;
  end;
  if lir_2f58.h.b2_7
     and (instruction_attributes[lir_2f58.opc].class in
          [2, 4, 7, 14, 15, 16, 20, 21, 22, 23, 24, 27]) then begin
    p := mrh_$alloc(lir_heap_ptr_t(lir_main_heap)^, lir_41a4.lo + 24);
    lir_desc_ptr_t(p)^ := lir_2f40;
    i := instr_ptr_t(integer32(p) + 24);
  end
  else
    i := mrh_$alloc(lir_heap_ptr_t(lir_main_heap)^, lir_41a4.lo);
  s := addr(lir_2f58);
  d := univ_ptr(i);
  n := lir_41a4.l;
  k := 0;
  while n > 0 do begin
    k := k + 1;
    d^[k] := s^[k];
    n := n - 4;
  end;
  copy_build_instruction := i;
end;

{ LIR_$GET_NEW_INSTRUCTION - begin_instruction's instruction copied to
  the heap.

  0x243398, 0x2A bytes, internal (no A5). }

function lir_$get_new_instruction(
    attrs: lir_inherited_ptr_t;
    opc: integer;
    flags: integer32;
    home: univ_ptr;
    nopnds: integer32): instr_ptr_t; options(val_param, internal);
begin
  begin_instruction(attrs, opc, flags, home, nopnds);
  lir_$get_new_instruction := copy_build_instruction;
end;

{ LIR_$GET_NEW_INSTRUCTION_NO_EXCEPTIONS - likewise, with its
  may_generate_an_exception and +32 cleared.

  0x2433C2, 0x40 bytes. }

function lir_$get_new_instruction_no_exceptions(
    node: univ_ptr;
    opc: integer;
    flags: integer32;
    home: univ_ptr;
    nopnds: integer32): instr_ptr_t;
var
  i: instr_ptr_t;
begin
  begin_instruction(node, opc, flags, home, nopnds);
  i := copy_build_instruction;
  i^.h.may_generate_an_exception := false;
  i^.l32 := 0;
  lir_$get_new_instruction_no_exceptions := i;
end;

{ LIR_$ADD_FLOW_GRAPH_EDGE - the edge from source to target (made, from
  lir_f08, and put at the head of source's successors and target's
  predecessors unless one exists).

  0x243402, 0x68 bytes. }

function lir_$add_flow_graph_edge(
    source_p: univ_ptr;
    target_p: univ_ptr): univ_ptr;
var
  source: bb_ptr_t;
  target: bb_ptr_t;
  e: fg_edge_ptr_t;
begin
  source := source_p;
  target := target_p;
  e := source^.succs;
  while e <> nil do begin
    if e^.target = target then begin
      lir_$add_flow_graph_edge := e;
      return;
    end;
    e := e^.next_succ;
  end;
  e := mrh_$alloc_fixed(lir_f08);
  e^.source := source;
  e^.target := target;
  e^.next_succ := source^.succs;
  e^.next_pred := target^.preds;
  source^.succs := e;
  target^.preds := e;
  lir_$add_flow_graph_edge := e;
end;

{ add_instruction_to_basic_block - instr appended to bb, numbered in
  the block (lir_4214: more than 1000 make the next statement start a
  block); its line kept (lir_41b8), or its +32 copied from the
  previous instruction's when it has none (unless that one is
  lir_main_c44).

  0x24346A, 0x74 bytes, internal: the line the word at +32
  (zero-extended); `bnes' on the store of the previous instruction
  (pattern 111). }

procedure add_instruction_to_basic_block(
    instr: instr_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  last: instr_ptr_t;
begin
  if lir_ipos_ptr_t(instr)^.line <> 0 then
    lir_41b8 := lir_ipos_ptr_t(instr)^.line;
  lir_4214 := lir_4214 + 1;
  if lir_4214 > 1000 then
    lir_4220 := true;
  instr^.num := lir_4214;
  last := bb^.last;
  instr^.bb := bb;
  instr^.prev := last;
  if last = nil then
    bb^.first := instr
  else begin
    last^.next := instr;
    if (instr^.l32 = 0) and (univ_ptr(last) <> lir_main_c44) then
      instr^.l32 := last^.l32;
  end;
  bb^.last := instr;
end;

{ LIR_$NEW_BASIC_BLOCK - a new block (lir_f20) of the routine
  (lir_41e0), numbered (its l188's low word) and in the exception
  frame lir_41e4; 'too many basic blocks' past 65535.

  0x2434DE, 0x7E bytes. }

function lir_$new_basic_block: univ_ptr;
var
  bb: bb_ptr_t;
begin
  bb := mrh_$alloc_fixed(lir_f20);
  lir_41e0^.nbbs := lir_41e0^.nbbs + 1;
  if lir_41e0^.nbbs > 65535 then
    cgerr_no_source(24, integer32(idntk(76, 'too many basic blocks', 21)));
  lir_41e0^.l188 := lir_41e0^.l188 + 1;
  bb^.num := lir_41e0^.l188;
  bb^.f14.kind := 0;
  bb^.f14.path_to := 0;
  bb^.l42 := lir_41e4;
  lir_$new_basic_block := bb;
end;

{ LIR_$NOTE_TARGET_OF_ASYNCHRONOUS_FLOW - bb may be entered
  asynchronously: the routine's asynchronous_return and the block's
  set, an edge from the entry block (lir_41f0) to it.

  0x243572, 0x38 bytes. }

procedure lir_$note_target_of_asynchronous_flow(
    bb: bb_ptr_t);
begin
  lir_41e0^.f226.asynchronous_return := true;
  bb^.f.asynchronous_return := true;
  discard(lir_$add_flow_graph_edge(lir_41f0, bb));
end;

{ get_basic_block - the block the next instruction goes into: the
  current one (lir_41fc), or, when one was asked for (lir_4222), a new
  one after it (the routine's first, or the current one's next and
  l134), with a JUMP to it from the current one when that falls
  through (lir_421c; the target noted as asynchronous when lir_421e
  asks); a CALL ending the old block gets its +3 bit 3; the new block's
  atomic flag from lir_4228, its w8 the last label number (lir_41bc's
  low word); the trace prints it (lir_421a).  The build area's opcode
  is cleared either way.

  0x2435AA, 0x11E bytes, internal: the JUMP made with three arguments
  (pattern 132); its operand 1 a flow graph edge set field by field. }

function get_basic_block: bb_ptr_t; options(internal);
var
  cur: bb_ptr_t;
  bb: bb_ptr_t;
  j: instr_ptr_t;
begin
  cur := lir_41fc;
  if lir_4222 then begin
    if cur <> nil then
      if cur^.last <> nil then
        if cur^.last^.opc = ord(opc$call) then
          cur^.last^.h.b3_3 := true;
    lir_4224 := false;
    lir_4222 := false;
    lir_4220 := false;
    lir_4214 := 0;
    bb := lir_$new_basic_block;
    bb^.f.atomic := lir_4228;
    if cur = nil then
      lir_41e0^.bbs := bb
    else begin
      cur^.l134 := bb;
      cur^.next := bb;
      if lir_421c then begin
        lir_421c := false;
        j := lir_$get_new_instruction_no_exceptions(nil, ord(opc$jump), 0,
                                                    nil, 0);
        j^.opnds[1].h.kind := operand$flow_graph_edge;
        j^.opnds[1].h.num := 1;
        j^.opnds[1].link := nil;
        j^.opnds[1].ptr := lir_$add_flow_graph_edge(cur, bb);
        add_instruction_to_basic_block(j, cur);
        if lir_421e then begin
          lir_421e := false;
          lir_$note_target_of_asynchronous_flow(bb);
        end;
      end;
    end;
    bb^.w8 := lir_41bc.lo;
    lir_41fc := bb;
    cur := bb;
    if lir_421a then
      vfmt_$write('%/ --- BB#%3ZWD ---%.', bb^.num);
  end;
  lir_2f58.opc := 0;
  get_basic_block := cur;
end;

{ add_fge_to_labeled_basic_block - an edge from the current block to
  the label's: at once when the label is placed (op nil: the block's
  hidden_successor_edges set), else op (a new label operand from
  lir_3c48 when nil, the block's hidden_successor_edges set) made a
  forward label reference (its block the current one) on the label's
  list, or, the label placed, a flow graph edge operand.

  0x2436DE, 0xA6 bytes, internal. }

procedure add_fge_to_labeled_basic_block(
    op: opnd_ptr_t;
    lab: lir_label_ptr_t); options(val_param, internal);
var
  bb: bb_ptr_t;
begin
  bb := get_basic_block;
  if not lab^.f10.in_bb then begin
    if op = nil then begin
      bb^.f.hidden_successor_edges := true;
      op := mrh_$alloc_fixed(lir_3c48);
    end;
    op^.h.kind := operand$forward_label_reference;
    op^.ptr := bb;
    op^.link := lab^.refs;
    lab^.refs := op;
  end
  else if op = nil then begin
    bb^.f.hidden_successor_edges := true;
    discard(lir_$add_flow_graph_edge(bb, lab^.bb));
  end
  else begin
    op^.h.kind := operand$flow_graph_edge;
    op^.link := nil;
    op^.ptr := lir_$add_flow_graph_edge(bb, lab^.bb);
  end;
end;

{ LIR_$NEW_LABEL - a new label (lir_3c30), numbered (lir_41bc, its low
  word).

  0x243784, 0x28 bytes. }

function lir_$new_label: univ_ptr;
var
  lab: lir_label_ptr_t;
begin
  lab := mrh_$alloc_fixed(lir_3c30);
  lir_41bc.l := lir_41bc.l + 1;
  lab^.num := lir_41bc.lo;
  lir_$new_label := lab;
end;

{ LIR_$LABEL - the label placed: a new block unless the current one
  holds only labels (then the fall through jump is still asked for);
  the forward references made edges to it, its instruction put in it;
  the trace notes it (dmp_$note_label).

  0x2437AC, 0xF4 bytes. }

procedure lir_$label(
    label_p: univ_ptr);
var
  lab: lir_label_ptr_t;
  i: instr_ptr_t;
  bb: bb_ptr_t;
  op: opnd_ptr_t;
  next: opnd_ptr_t;
  src: bb_ptr_t;
begin
  lab := label_p;
  if not lir_4222 and (lir_41fc <> nil) then begin
    lir_421c := true;
    i := lir_41fc^.first;
    while i <> nil do begin
      if i^.opc <> ord(opc$label) then begin
        lir_4224 := false;
        lir_4222 := true;
        exit;
      end;
      i := i^.next;
    end;
  end;
  bb := get_basic_block;
  if lab^.f10.async_target then
    lir_$note_target_of_asynchronous_flow(bb);
  op := lab^.refs;
  while op <> nil do begin
    next := op^.link;
    src := op^.ptr;
    if src = nil then
      bug_check('LIR_$LABEL -- instruction has no basic block%$');
    op^.ptr := lir_$add_flow_graph_edge(src, bb);
    op^.h.kind := operand$flow_graph_edge;
    op^.link := nil;
    op := next;
  end;
  if lab^.instr <> nil then
    add_instruction_to_basic_block(lab^.instr, bb);
  lab^.bb := bb;
  lab^.f10.in_bb := true;
  if lir_421a then
    dmp_$note_label(lab^.num);
end;

{ LIR_$FREE_LIFETIME_SEGMENT - lts put on the free list (lir_41dc,
  chained at next) unless it is a physical register's; freed twice is
  a bug check.

  0x2438CE, 0x7E bytes: the number for %2ZLD a longword copy. }

procedure lir_$free_lifetime_segment(
    lts_p: univ_ptr);
var
  lts: lts_ptr_t;
  n: integer32;
begin
  lts := lts_p;
  if lts^.f2.freed then
    if lts^.lr = nil then
      bug_check('LIR_$FREE_LIFETIME_SEGMENT -- LTS freed twice%$')
    else begin
      n := lts^.f2.num;
      bug_check('LIR_$FREE_LIFETIME_SEGMENT -- LTS %3ZWD.%2ZLD freed twice%$',
                lts^.lr^.num, n);
    end;
  if (lts^.lr = nil) or not lts^.lr^.f2.physical then begin
    lts^.f2.freed := true;
    lts^.next := lir_41dc;
    lir_41dc := lts;
  end;
end;

{ LIR_$NEW_LIFETIME_SEGMENT - a segment of lr (from the free list,
  cleared, or lir_3c00), its register properties lr's, numbered by
  lr's count.

  0x2439B8, 0x66 bytes. }

function lir_$new_lifetime_segment(
    lr_p: univ_ptr): univ_ptr;
var
  lr: lr_ptr_t;
  s: lts_ptr_t;
begin
  lr := lr_p;
  s := lir_41dc;
  if s <> nil then begin
    lir_41dc := s^.next;
    zero(s, 52);
  end
  else
    s := mrh_$alloc_fixed(lir_3c00);
  s^.lr := lr;
  s^.rrp := lr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only, rrp$fp_reg,
                       rrp$ip_reg];
  lr^.w56 := lr^.w56 + 1;
  s^.f2.num := lr^.w56;
  lir_$new_lifetime_segment := s;
end;

{ LIR_$ALLOC_LIVE_RANGE - a live range from heap, on the routine's list
  (lir_41e0's lrs .. lrs_last) and numbered (its l200; 'too many LRs'
  past 65535), b3_3 set.

  0x243A1E, 0x84 bytes, internal: the number the counter's low word
  (pattern 129). }

function lir_$alloc_live_range(
    var heap: mrh_$heap_t): lr_ptr_t; options(internal);
var
  lr: lr_ptr_t;
  r: rtn_ptr_t;
begin
  lr := mrh_$alloc_fixed(heap);
  r := lir_41e0;
  if r <> nil then begin
    if r^.lrs_last = nil then
      r^.lrs := lr
    else
      r^.lrs_last^.next := lr;
    r^.lrs_last := lr;
    r^.l200 := r^.l200 + 1;
    if r^.l200 > 65535 then
      cgerr_no_source(24, integer32(idntk(76, 'too many LRs', 12)));
    lr^.num := r^.l200;
    lr^.f2.b3_3 := true;
  end;
  lir_$alloc_live_range := lr;
end;

{ LIR_$NEW_LIVE_RANGE - a live range of no register class (lir_ea8).

  0x243AB0, 0x1C bytes. }

function lir_$new_live_range: univ_ptr;
begin
  lir_$new_live_range := lir_$alloc_live_range(lir_ea8);
end;

{ LIR_$NEW_LIVE_RANGE_IP_REG - an integer register's (lir_e90).

  0x243ACC, 0x20 bytes. }

function lir_$new_live_range_ip_reg: univ_ptr;
var
  lr: lr_ptr_t;
begin
  lr := lir_$alloc_live_range(lir_e90);
  lr^.rrp := [rrp$ip_reg];
  lir_$new_live_range_ip_reg := lr;
end;

{ LIR_$NEW_LIVE_RANGE_FP_REG - a floating register's (lir_ed8).

  0x243AEC, 0x20 bytes. }

function lir_$new_live_range_fp_reg: univ_ptr;
var
  lr: lr_ptr_t;
begin
  lr := lir_$alloc_live_range(lir_ed8);
  lr^.rrp := [rrp$fp_reg];
  lir_$new_live_range_fp_reg := lr;
end;

{ LIR_$NEW_LIVE_RANGE_FP_REG_PAIR - a floating pair's two halves
  (lir_ec0), mates, the even one returned.

  0x243B0C, 0x40 bytes. }

function lir_$new_live_range_fp_reg_pair: univ_ptr;
var
  even: lr_ptr_t;
  odd: lr_ptr_t;
begin
  even := lir_$alloc_live_range(lir_ec0);
  odd := lir_$alloc_live_range(lir_ec0);
  even^.mate := odd;
  even^.rrp := [rrp$fp_reg_even_only, rrp$fp_reg];
  odd^.mate := even;
  odd^.rrp := [rrp$fp_reg_odd_only, rrp$fp_reg];
  lir_$new_live_range_fp_reg_pair := even;
end;

{ LIR_$NEW_LIVE_RANGE_FOR_KIND - a live range for an operand kind
  (operand$ip_reg 1, fp_reg 2, fp_reg_pair 3; another kind's of no
  class).

  0x243B4C, 0x42 bytes. }

function lir_$new_live_range_for_kind(
    kind: integer): univ_ptr;
begin
  case kind of
    2: lir_$new_live_range_for_kind := lir_$new_live_range_fp_reg;
    3: lir_$new_live_range_for_kind := lir_$new_live_range_fp_reg_pair;
    1: lir_$new_live_range_for_kind := lir_$new_live_range_ip_reg;
    otherwise
      lir_$new_live_range_for_kind := lir_$new_live_range;
  end;
end;

{ LIR_$NEW_INSTRUCTION - a bare instruction of opcode opc, of its
  default size (from the routine's heap): its operand count and opcode
  only.

  0x243B8E, 0x5A bytes. }

function lir_$new_instruction(
    opc: integer): univ_ptr;
var
  i: instr_ptr_t;
begin
  i := mrh_$alloc(lir_heap_ptr_t(lir_main_heap)^, instr_size[opc]);
  i^.h.nopnds := instruction_attributes[opc].nopnds;
  i^.opc := opc;
  lir_$new_instruction := i;
end;

{ LIR_$BREAK_BASIC_BLOCK - the next instruction starts a block, the
  current one falling through to it.

  0x243BE8, 0x26 bytes. }

procedure lir_$break_basic_block;
begin
  if not lir_4222 then begin
    lir_4222 := true;
    lir_421c := true;
  end;
end;

{ LIR_$OPT_NEW_INSTRUCTION - a new instruction of opcode opc, of its
  default size (default_size) or with n operands (255 at most), put
  after anchor (after) or before it in anchor's block: its class, the
  operand count, b2_6 set, preference from the opcode's b6_0,
  may_generate_an_exception from its b11_7, b0_1 and +32 (the source
  position) from anchor; numbered after the block's last (lir_4214).

  0x243C0E, 0x184 bytes, internal: the header from the constant
  16#4000 in a frame longword; the bug check's mnemonic length 12 a
  constant by address (pattern 116). }

function lir_$opt_new_instruction(
    anchor: instr_ptr_t;
    opc: integer;
    after: boolean;
    n: integer32;
    default_size: boolean): instr_ptr_t; options(val_param, internal);
var
  size: integer32;
  i: instr_ptr_t;
  a: instr_attr_ptr_t;
  hw: lir_ihdr_t;
begin
  if default_size then
    size := instr_size[opc]
  else begin
    if n > 255 then
      bug_check('LIR_$OPT_NEW_INSTRUCTION -- %a with %ld operands (255 is max)%$',
                instruction_mnemonic[opc], 12, n);
    size := 12 * n + 44;
  end;
  i := mrh_$alloc(lir_heap_ptr_t(lir_main_heap)^, size);
  i^.opc := opc;
  a := addr(instruction_attributes[opc]);
  i^.class := chr(a^.class);
  hw.l := 16#4000;
  if default_size then
    hw.h.nopnds := a^.nopnds
  else
    hw.h.nopnds := n;
  hw.h.preference := a^.b6_0;
  hw.h.may_generate_an_exception := a^.b11_7;
  hw.h.b0_1 := anchor^.h.b0_1;
  i^.h := hw.h;
  i^.l32 := anchor^.l32;
  lir_4214 := lir_4214 + 1;
  i^.num := lir_4214;
  i^.bb := anchor^.bb;
  if after then begin
    i^.prev := anchor;
    i^.next := anchor^.next;
    anchor^.next := i;
    if i^.next <> nil then
      i^.next^.prev := i
    else
      anchor^.bb^.last := i;
  end
  else begin
    i^.next := anchor;
    i^.prev := anchor^.prev;
    anchor^.prev := i;
    if i^.prev <> nil then
      i^.prev^.next := i
    else
      anchor^.bb^.first := i;
  end;
  lir_$opt_new_instruction := i;
end;

{ LIR_$OPTIMIZER_NEW_N_OPR_INSTR - with n operands.

  0x243DD8, 0x2C bytes. }

function lir_$optimizer_new_n_opr_instr(
    anchor: instr_ptr_t;
    opc: integer;
    after: boolean;
    n: integer32): instr_ptr_t;
begin
  lir_$optimizer_new_n_opr_instr :=
      lir_$opt_new_instruction(anchor, opc, after, n, false);
end;

{ LIR_$OPTIMIZER_NEW_INSTRUCTION - of the opcode's default size.

  0x243E04, 0x2A bytes. }

function lir_$optimizer_new_instruction(
    anchor: instr_ptr_t;
    opc: integer;
    after: boolean): instr_ptr_t;
begin
  lir_$optimizer_new_instruction :=
      lir_$opt_new_instruction(anchor, opc, after, 0, true);
end;

{ get_lts_in_current_bb - lr's segment in the current block for a
  reference with properties rrp: for a read, the one already there at
  the head of lr's list, else a new exposed one (lr made complex, the
  routine's complex count raised: 'too many complex IDs' past 65535);
  for a write a new one; a register's from lir_3c00, another from
  lir_3c18; on lr's list, numbered; rrp added to both.

  0x243E2E, 0xE0 bytes, internal. }

function get_lts_in_current_bb(
    lr: lr_ptr_t;
    rrp: rrp$set_t): lts_ptr_t; options(val_param, internal);
var
  bb: bb_ptr_t;
  s: lts_ptr_t;
begin
  bb := get_basic_block;
  if not (rrp$read in rrp) then begin
    if rrp * [rrp$fp_reg, rrp$ip_reg] <> [] then
      s := mrh_$alloc_fixed(lir_3c00)
    else
      s := mrh_$alloc_fixed(lir_3c18);
  end
  else begin
    s := lr^.ltss;
    if s <> nil then
      if s^.bb = bb then begin
        lr^.rrp := lr^.rrp + rrp;
        s^.rrp := s^.rrp + rrp;
        get_lts_in_current_bb := s;
        return;
      end;
    if not lr^.f2.b3_4 then begin
      lr^.f2.b3_4 := true;
      lir_41e0^.l192 := lir_41e0^.l192 + 1;
      if lir_41e0^.l192 > 65535 then
        cgerr_no_source(24, integer32(idntk(76, 'too many complex IDs', 20)));
    end;
    if rrp * [rrp$fp_reg, rrp$ip_reg] <> [] then
      s := mrh_$alloc_fixed(lir_3c00)
    else
      s := mrh_$alloc_fixed(lir_3c18);
    s^.f2.exposed := true;
  end;
  s^.next := lr^.ltss;
  lr^.ltss := s;
  lr^.w56 := lr^.w56 + 1;
  s^.f2.num := lr^.w56;
  s^.lr := lr;
  s^.bb := bb;
  lr^.rrp := lr^.rrp + rrp;
  s^.rrp := s^.rrp + rrp;
  get_lts_in_current_bb := s;
end;

{ build_non_register_reference - op (empty, else a bug check) made an
  operand of kind kind and number num referring to lr (put on the
  routine's list first if it is not yet: alloc_live_range's steps
  inline) with properties rrp: its segment in the current block, op
  appended to the segment's references (refs .. l40).

  0x243F24, 0x10A bytes, internal. }

procedure build_non_register_reference(
    op: opnd_ptr_t;
    kind: integer;
    num: integer;
    rrp: rrp$set_t;
    lr: lr_ptr_t); options(val_param, internal);
var
  n: integer32;
  r: rtn_ptr_t;
  s: lts_ptr_t;
  sb: lir_set_bytes_t;
begin
  if ord(op^.h.kind) <> 0 then begin
    n := op^.h.num;
    bug_check('LIR: BUILD_NON_REGISTER_REFERENCE -- operand slot %ld is already in use.%$', n);
  end;
  op^.h.kind := operand$t(kind);
  op^.h.num := num;
  if not lr^.f2.b3_3 then begin
    r := lir_41e0;
    if r^.lrs_last = nil then
      r^.lrs := lr
    else
      r^.lrs_last^.next := lr;
    lir_41e0^.lrs_last := lr;
    lir_41e0^.l200 := lir_41e0^.l200 + 1;
    if lir_41e0^.l200 > 65535 then
      cgerr_no_source(24, integer32(idntk(76, 'too many LRs', 12)));
    lr^.num := lir_41e0^.l200;
    lr^.f2.b3_3 := true;
  end;
  s := get_lts_in_current_bb(lr, rrp);
  sb.s := rrp;
  opnd_bytes_ptr_t(op)^.rrp := opnd_bytes_ptr_t(op)^.rrp ! sb.lo;
  op^.lts := s;
  op^.link := nil;
  if s^.l40 <> 0 then
    opnd_ptr_t(s^.l40)^.link := op
  else
    s^.refs := op;
  s^.l40 := integer32(op);
end;

{ convert_to_intend_to_modify - op's properties (its +1 byte and the
  word at +4 an operand holds before its segment is made) lose write
  and modify and get read and intend_to_modify.

  0x244078, 0x22 bytes, no frame. }

procedure convert_to_intend_to_modify(
    op: lir_pre_opnd_ptr_t); options(val_param, internal);
begin
  opnd_bytes_ptr_t(op)^.rrp := (opnd_bytes_ptr_t(op)^.rrp & 16#F3) ! 16#30;
  op^.rrp := (op^.rrp - [rrp$write, rrp$modify]) +
             [rrp$read, rrp$intend_to_modify];
end;

{ LIR_$BUILD_OPERAND - op (empty, else a bug check) made from the
  solution sol as an operand of form form (form.num its number,
  form.b2 bits 7..6 its access: build_access).  The build kind
  (build_action by the solution's kind and the form; 0 none: a
  constant's literal row, 5 or 29 by the form, an integer register
  through sol's l8 (scaled or not), else a case jump base from
  isc_user_routines_258 (17) or the zero register isc_user_routines_31c;
  1 and 3 a constant whose value decides 7, 12, 17 or 2, 2 an immediate
  that is 0 (the zero register's solution, 21), or 11, or 6) chooses,
  through the build_ tables, the operand's kind (build_kind, or its
  physical register's build_physical), properties (build_properties
  and the access), the bounds of a displacement or immediate
  (build_low_bound .. build_high_bound, build_message's text when out
  of range) and how the operand is filled: 5 a literal pool or frame
  displacement, 6..18 an immediate of the object (sym_$object_with_
  immediate_disp) checked against operand_forms_mask's alignment, 19
  a zero displacement, 20..23 a register (a new live range for a write
  without one; a pair's halves made mates), 24 a case jump base, 25 the
  PC or the zero register, 26..28 a physical register (its segment from
  build_physical_ltss for a no_modify register; a write to a
  serialized one reads it too, or modifies the earlier operand that
  reads it).  A physical register's attributes that differ between the
  solution and its live range are written to the output (gap 4) and
  copied.

  0x24409A, 0xF58 bytes: the build kinds' jump table (5..28); the form
  sets constants after the routine (pattern 102); the bug checks'
  mnemonic length a constant by address (pattern 116); the IL kinds an
  immediate's own object is taken for a constant set (elements 207..0);
  `btst d4,(83,A1)' with the set 16#E00000 in D4 (bit 0: pattern 148);
  the scale factor messages pass the byte's address to %wd; the
  register's properties a word (D4) whose low byte is stored at +1.
  Not known from the original: the build kinds' names. }

procedure lir_$build_operand(
    op: opnd_ptr_t;
    sol: solution_ptr_t;
    form: instr_attr_opnd_t);
label
  10, 20, 30, 40, 50, 60, 70, 71, 72, 75, 80, 85, 90, 99;
type
  node_v_ptr_t = ^node_v_t;
  node_v_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    w4: integer;                        { +4 }
    w6: integer;                        { +6 }
    space8: array [8..10] of char;      { +8 }
    b11: char;                          { +11: bits 7..4 a FORTRAN
                                          symbol's storage class }
    l12: integer32;                     { +12 }
    space16: array [16..23] of char;    { +16 }
    l24: integer32;                     { +24 }
    space28: array [28..31] of char;    { +28 }
    l32: integer32;                     { +32 }
    space36: array [36..55] of char;    { +36 }
    l56: integer32;                     { +56 }
    space60: array [60..71] of char;    { +60 }
    w72: integer;                       { +72: a variable's storage
                                          class }
  end;
  stmt_v_ptr_t = ^stmt_v_t;
  stmt_v_t = record
    space0: array [0..31] of char;      { +0 }
    line: integer;                      { +32 }
  end;
var
  action: integer;
  n: integer32;
  rrp: rrp$set_t;
  sb: lir_set_bytes_t;
  access: integer;
  disp: integer32;
  mask: integer32;
  al: integer;
  nd: node_v_ptr_t;
  flags: integer32;
  lr: lr_ptr_t;
  m: lr_ptr_t;
  pre: lir_pre_opnd_ptr_t;
  lts: lts_ptr_t;
  reg: integer32;
  k: integer32;
  readmod: boolean;
  half: rrp$set_t;
  v1, v2, v3: integer32;
begin
  if ord(op^.h.kind) <> 0 then begin
    n := form.num;
    bug_check('LIR_$BUILD_OPERAND -- operand slot %ld is already in use: %a%$',
              n, instruction_mnemonic[lir_2f58.opc], 12);
  end;
  op^.h.num := form.num;
  action := build_action[sol^.kind, form.form].v;
  if action = 0 then begin
    if sol^.f84.b84_6 then begin
      if not sol^.f78.b82_7 then
        action := build_action[14, form.form].v
      else if form.form in [8, 10, 11, 21, 24, 25, 26, 27, 28, 29, 30, 31,
                            36, 37, 39, 40, 42] then
        action := 5
      else
        action := 29;
    end
    else if sol^.f84.b84_5 then begin
      if not (form.form in [6, 7, 9, 10, 11, 12, 14, 16, 18, 21, 23, 26, 27,
                            28, 29, 30, 31, 33, 34, 36, 39, 42]) then begin
        n := form.num;
        bug_check('LIR_$BUILD_OPERAND -- %a cannot take IP register as operand #%ld%$',
                  instruction_mnemonic[lir_2f58.opc], 12, n);
      end;
      sol := solution_ptr_t(sol^.l8);
      if sol^.f78.shift = 0 then
        action := build_action[11, form.form].v
      else if form.form in [3, 7, 10, 21, 33, 34, 36, 37, 39, 42] then
        action := build_action[13, form.form].v
      else begin
        n := form.num;
        bug_check('LIR_$BUILD_OPERAND -- %a cannot take any scaled IP register as operand #%ld%$',
                  instruction_mnemonic[lir_2f58.opc], 12, n);
      end;
    end
    else if form.form in [3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 20, 21,
                          23, 24, 25, 26, 27, 28, 29, 30, 31, 33, 34, 35, 36,
                          37, 38, 39, 40, 42] then begin
      sol := addr(isc_user_routines_258);
      action := 17;
    end
    else begin
      sol := isc_user_routines_31c;
      action := build_action[11, form.form].v;
    end;
  end
  else begin
    if action = 3 then begin
      if (sol^.disp < 0) and ((sol^.disp & 16#FFFF) <> 0) then
        action := 17
      else
        action := 2;
    end
    else if action = 1 then begin
      if ((~sol^.disp) & 16#FFFF) = 0 then
        action := 7
      else if ((~sol^.disp) & 16#FFFF0000) = 0 then
        action := 12
      else
        action := 2;
    end;
    if action = 2 then
      if sol^.disp = 0 then begin
        sol := isc_user_routines_320;
        action := 21;
      end
      else if (sol^.disp & 16#FFFF) <> 0 then
        action := 11
      else
        action := 6;
  end;
  if sol^.f78.shift <> 0 then
    if action <> 20 then
      bug_check('LIR_$BUILD_OPERAND -- unexpected non-zero scale factor: %wd, %a%$',
                sol^.f78.shift, instruction_mnemonic[lir_2f58.opc], 12)
    else if sol^.f78.shift > 3 then
      bug_check('LIR_$BUILD_OPERAND -- scale factor greater than 3: %wd, %a%$',
                sol^.f78.shift, instruction_mnemonic[lir_2f58.opc], 12);
  if action in [21, 22, 23] then
    if sol^.lr <> nil then
      if sol^.f78.physical or sol^.lr^.f2.physical then
        if (sol^.f78.reg <> sol^.lr^.f2.reg)
           or (sol^.f78.serialize <> sol^.lr^.f2.serialize)
           or (sol^.f78.physical <> sol^.lr^.f2.physical)
           or (sol^.f78.no_modify <> sol^.lr^.f2.no_modify) then begin
          writeln('* * * * Physical register attributes are different');
          if sol^.l104 <> nil then begin
            writeln('at source line ', stmt_v_ptr_t(sol^.l104)^.line:1, '.');
          end;
          writeln('                                     sol^.    sol^.live_range^.');
          writeln('---------------------------------------------------------------');
          writeln('physical_register                    ', sol^.f78.physical:5, '   ', sol^.lr^.f2.physical:5);
          writeln('physical_register_is_no_modify       ', sol^.f78.no_modify:5, '   ', sol^.lr^.f2.no_modify:5);
          writeln('physical_register_user_declared      ', sol^.f78.serialize:5, '   ', sol^.lr^.f2.serialize:5);
          v1 := sol^.f78.reg;
          v2 := sol^.lr^.f2.reg;
          writeln('physical_register_number             ', v1:5, '   ', v2:5);
          writeln('solution_kind                        ', sol^.kind);
          writeln;
          sol^.f78.physical := sol^.lr^.f2.physical;
          sol^.f78.no_modify := sol^.lr^.f2.no_modify;
          sol^.f78.serialize := sol^.lr^.f2.serialize;
          sol^.f78.reg := sol^.lr^.f2.reg;
        end;
  if action in [21, 22, 23] then
    if sol^.lr <> nil then begin
      lr := sol^.lr;
      if ((action = 21) and (rrp$fp_reg in lr^.rrp))
         or ((action <> 21) and (rrp$ip_reg in lr^.rrp)) then begin
        n := form.num;
        bug_check('LIR_$BUILD_OPERAND -- properties of LR %wd conflict with requirements of %a operand %ld%$',
                  lr^.num, instruction_mnemonic[lir_2f58.opc], 12, n);
      end;
      if lr^.f2.physical then
        if (sol^.f78.reg <> lr^.f2.reg)
           or (sol^.f78.serialize <> lr^.f2.serialize)
           or (sol^.f78.no_modify <> lr^.f2.no_modify)
           or not sol^.f78.physical then
          bug_check('LIR_$BUILD_OPERAND -- assigned LR properties not propagated to solution%$');
    end;
  if sol^.f78.physical then
    action := build_physical[action].v;
  opnd_bytes_ptr_t(op)^.b3 := (opnd_bytes_ptr_t(op)^.b3 & 16#E0) ! build_kind[action].v;
  rrp := build_properties[action];
  access := rshft(form.b2 & 16#C0, 6);
  rrp := rrp + build_access[access];
  disp := sol^.disp + sol^.l28;
  readmod := false;
  case action of
    5: goto 50;
    6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18: goto 10;
    19: goto 60;
    24: goto 71;
    25: goto 72;
    26: goto 70;
    27, 28: goto 20;
    20, 21, 22, 23: goto 75;
    otherwise goto 85;
  end;
50:
      if (disp < target_properties.p_60) or (disp > target_properties.p_5c) then
        goto 90;
      if sym_$reformat_literal_operand(sol^.node, sol^.w56, disp, op) then begin
        if op^.h.kind <> operand$displacement_literal_pool then
          bug_check('LIR_$BUILD_OPERAND -- improper literal pool operand%$');
      end
      else begin
        nd := sol^.node;
        if nd^.kind = 109 then begin
          if nd^.w72 in [1, 3, 4, 7, 8, 10, 11] then begin
            disp := disp + nd^.l56;
            action := build_action[14, form.form].v;
            opnd_bytes_ptr_t(op)^.b3 := (opnd_bytes_ptr_t(op)^.b3 & 16#E0) ! build_kind[action].v;
            goto 10;
          end;
          flags := nd^.l32;
          if (flags & 16#400) = 0 then
            flags := flags ! 16#10000000;
          nd^.l32 := flags;
        end
        else if nd^.kind = 110 then begin
          if rshft(ord(nd^.b11) & 16#F0, 4) in [1, 3, 4, 7, 8, 10, 11] then begin
            disp := disp + nd^.l12;
            action := build_action[14, form.form].v;
            opnd_bytes_ptr_t(op)^.b3 := (opnd_bytes_ptr_t(op)^.b3 & 16#E0) ! build_kind[action].v;
            goto 10;
          end;
          flags := nd^.l24;
          if (flags & 16#400) = 0 then
            flags := flags ! 16#10000000;
          nd^.l24 := flags;
        end
        else
          flags := 0;
        op^.link := sol^.node;
        if ((flags & 16#400) <> 0) and ((flags & 16#40000000) = 0) then
          op^.h.kind := operand$displacement_arg_block
        else
          op^.h.kind := operand$displacement_stack_frame;
      end;
      al := alignment_from_il_node(sol^.node);
      mask := ord(operand_forms_mask[form.form]);
      if ((disp ! lshft(-1, al)) & mask) <> 0 then begin
        v1 := disp & mask;
        v2 := mask + 1;
        n := form.num;
        bug_check('LIR_$BUILD_OPERAND -- (known-low-bits ! offset) is %ld MOD %ld for operand %ld of %a%$',
                  v1, v2, n, instruction_mnemonic[lir_2f58.opc], 12);
      end;
      op^.value := disp;
      goto 80;
10:
      mask := ord(operand_forms_mask[form.form]);
      if (disp & mask) <> 0 then begin
        v1 := disp & mask;
        v2 := mask + 1;
        n := form.num;
        bug_check('LIR_$BUILD_OPERAND -- displacement is %ld MOD %ld for operand %ld of %a%$',
                  v1, v2, n, instruction_mnemonic[lir_2f58.opc], 12);
      end;
      if (disp < build_low_bound[action]) or (disp > build_high_bound[action]) then
        goto 90;
      nd := sol^.node;
      if nd = nil then
        nd := sol^.sym
      else if not (nd^.kind in [77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88,
                                89, 90, 92, 93, 101, 109, 110, 156, 163, 176,
                                198, 200]) then
        nd := sol^.sym;
      op^.link := sym_$object_with_immediate_disp(nd);
      op^.value := disp;
      goto 80;
60:
      if disp <> 0 then
        goto 90;
      op^.link := sol^.node;
      op^.value := disp;
      goto 80;
70:
      disp := sol^.f78.reg;
      if disp = 30 then
        goto 90;
      if disp = 31 then
        op^.h.count := 0
      else
        op^.h.count := sol^.f78.shift;
      if disp > 31 then
        goto 90;
      goto 20;
71:
      lir_41e8 := sol^.l12;
      op^.link := univ_ptr(sol^.l12);
      op^.value := lir_41a8;
      goto 80;
72:
      if sol^.f78.reg < 30 then
        goto 20;
      if sol^.f78.reg = 30 then begin
        op^.value := lir_41a8;
        op^.h.kind := operand$ip_reg_like;
      end
      else if form.form in [3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 20, 21,
                            23, 24, 25, 26, 27, 28, 29, 30, 31, 33, 34, 35,
                            36, 37, 38, 39, 40, 42] then
        op^.h.kind := operand$immediate
      else begin
        op^.value := lir_4200;
        op^.h.kind := operand$ip_reg_like;
      end;
      goto 80;
20:
      reg := sol^.f78.reg;
      lr := build_physical_lrs[action]^[reg];
      if sol^.lr = nil then
        sol^.lr := lr
      else if lir_422a then
        lr := sol^.lr
      else if sol^.lr <> lr then
        bug_check('LIR_$BUILD_OPERAND -- multiple physical live_ranges!%$');
      if lr^.f2.no_modify then begin
        opnd_bytes_ptr_t(op)^.b3 := (opnd_bytes_ptr_t(op)^.b3 & 16#E0) ! build_like_kind[action].v;
        lts := build_physical_ltss[action]^[lr^.f2.reg];
        if lts = nil then begin
          lts := mrh_$alloc_fixed(lir_3c00);
          lts^.lr := lr;
          build_physical_ltss[action]^[lr^.f2.reg] := lts;
          if lr^.f2.reg = lir_41e0^.w208 then
            asm_658 := integer32(lts);
        end;
        lr^.rrp := lr^.rrp + rrp;
        lts^.rrp := lts^.rrp + rrp;
        op^.lts := lts;
        goto 80;
      end;
      lr^.rrp := rrp$set_t(integer(lr^.rrp) ! lir_4216);
      if not (rrp$write in rrp) then
        goto 30;
      if not (instruction_attributes[lir_2f58.opc].class in
              [0, 3, 8, 12, 15, 16, 17, 21, 22, 23]) then
        goto 30;
      nd := sol^.sym;
      if nd <> nil then
        if nd^.kind = 203 then
          if ((build_arg_loc[action].v = nd^.w4) and (sol^.f78.reg = nd^.w6))
             or ((nd^.w6 = (sol^.f78.reg & 16#FE)) and (action = 27)
                 and (nd^.w4 = 2)) then begin
            lir_2f58.l28 := lir_2f58.l28 ! 16#8000;
            goto 30;
          end;
      if not lr^.f2.serialize then
        goto 30;
      rrp := rrp - [rrp$write];
      k := form.num - 1;
      while k > 0 do begin
        if (lir_2f58.opnds[k].h.kind = op^.h.kind)
           and (lir_pre_opnd_ptr_t(addr(lir_2f58.opnds[k]))^.lr = lr)
           and lir_2f58.opnds[k].h.read then begin
          convert_to_intend_to_modify(addr(lir_2f58.opnds[k]));
          rrp := rrp + [rrp$modify];
          goto 30;
        end;
        k := k - 1;
      end;
      rrp := rrp + [rrp$read];
      readmod := true;
      goto 30;
75:
      if action = 20 then
        op^.h.count := sol^.f78.shift;
      lr := sol^.lr;
      if lr <> nil then
        goto 40;
      if not (rrp$write in rrp) then
        bug_check('LIR_$BUILD_OPERAND -- read (or modify) solution lacks live_range: %a%$',
                  instruction_mnemonic[lir_2f58.opc], 12);
      lr := lir_$new_live_range_for_kind(ord(op^.h.kind));
30:
      sol^.lr := lr;
40:
      if sol^.kind in [2, 3, 9] then begin
        if lr^.mate = nil then begin
          m := lir_$new_live_range_for_kind(ord(op^.h.kind));
          m^.node20 := lr^.node20;
          m^.mate := lr;
          lr^.mate := m;
        end;
        if sol^.kind = 3 then begin
          rrp := rrp + [rrp$fp_reg_odd_only];
          half := [rrp$fp_reg_even_only];
        end
        else begin
          rrp := rrp + [rrp$fp_reg_even_only];
          half := [rrp$fp_reg_odd_only];
        end;
        if lr^.rrp * half <> [] then
          lr := lr^.mate;
        lr^.mate^.rrp := lr^.mate^.rrp + half + [rrp$fp_reg];
        lr^.rrp := lr^.rrp + rrp;
      end;
      rrp := rrp + lr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only];
      pre := univ_ptr(op);
      pre^.lr := lr;
      pre^.rrp := rrp;
      if readmod then begin
        sb.s := rrp;
        opnd_bytes_ptr_t(op)^.rrp := sb.lo;
        if access = 3 then begin
          lir_41a4.l := lir_41a4.l + 12;
          lir_2f58.h.nopnds := lir_2f58.h.nopnds + 1;
        end;
        convert_to_intend_to_modify(pre);
        goto 99;
      end;
      goto 80;
85:
      bug_check('LIR_$BUILD_OPERAND -- no action: %a, %a, %a%$',
                solution_string[sol^.kind], solution_string_length[sol^.kind],
                of_string[form.form], of_string_length[form.form],
                instruction_mnemonic[lir_2f58.opc], 12);
80:
  sb.s := rrp;
  opnd_bytes_ptr_t(op)^.rrp := sb.lo;
  goto 99;
90:
  v3 := disp;
  bug_check(build_message[action]^, v3, instruction_mnemonic[lir_2f58.opc], 12);
99:
end;
