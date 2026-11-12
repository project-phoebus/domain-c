{ lir - the LIR builder (cc.a88k only): the ISC's solutions made into
  instructions, operands, live ranges, lifetime segments, labels,
  basic blocks and flow graph edges; the allocators the other phases
  use for them (lir_$new_*, lir_$optimizer_new_*), the calls'
  argument registers, the routine's reinitialization and its end.

  Translated by translators PA6 (0x242820 .. 0x242ED4) and PA7
  (begin_instruction 0x242EF4 .. lir_$strip_may_gen_exception 0x248A60,
  and the module's data), in address order.  The module's data (A5
  0x487180, 0x422C bytes) is declared extern (backend.ins.pas's,
  lir.pvt.pas's and the unit's own cells) and defined in address order
  after solution_string_length.init (every cell at its image offset);
  the build_ tables lie in the reverse of their include order
  (build_properties +0x000 .. build_action +0x3A0, by build kind 0..29
  or by solution kind and form) and their .init files give their values
  with second define statements (docs/questions.md 161's scheme); the
  messages build_message points to are laid out before A5 in the image
  and after the cells here.  The section lir_readonly_tables (0x2BDA2C,
  0x694 bytes): instr_size.init (+0, 384 words), solution_kind.init
  (+0x300), solution_string.init (+0x340), solution_string_length.init
  (+0x660).

  dpc gaps (docs/dpc-gaps.md): 4 (lir_$build_operand's dump to the
  output file).

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

  { The register sets a call's instruction keeps after its operand
    slots (+44 + 12 nopnds; the conventions' pointer follows): s0 the
    floating registers 32..63 it clobbers, s4 0..31, s8 the integer
    registers. }
  lir_regs_ptr_t = ^lir_regs_t;
  lir_regs_t = record
    s0: bv_word_t;                      { +0 }
    s4: bv_word_t;                      { +4 }
    s8: bv_word_t;                      { +8 }
  end;

  { The exception information operand (operand kind 28) as
    lir_$complete_instruction fills it from exs_$start_exception_
    handler_enquiry: +4 the handler, +8 a word, +10 a flag, +11 the
    predefined exception (exs_$map_to_predefined_exception). }
  lir_exc_opnd_ptr_t = ^lir_exc_opnd_t;
  lir_exc_opnd_t = record
    h: opnd_hdr_t;                      { +0 }
    handler: univ_ptr;                  { +4 }
    word: integer;                      { +8 }
    flag: boolean;                      { +10 }
    predef: char;                       { +11 }
  end;

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
  lir_3b78: extern array [1..2] of lir_label_ptr_t;  { +0x3B78: the
                                          labels a flags bit 17
                                          instruction may reach (lir_41c0
                                          of them) }
  lir_4190: extern instr_attr_opnd_t;   { +0x4190 .. +0x419C: operand
                                          forms (initialized: +0x4190 an
                                          access of 3, +0x4194 form 7,
                                          +0x4198 18, of$ip_reg) }
  lir_4194: extern instr_attr_opnd_t;
  lir_4198: extern instr_attr_opnd_t;
  lir_419c: extern instr_attr_opnd_t;
  lir_41a0: extern integer32;           { +0x41A0: the highest argument
                                          block offset in lir_f38 }
  lir_41a4: extern lir_count_t;         { +0x41A4: the build area's size }
  lir_41a8: extern integer32;           { +0x41A8 }
  lir_41ac: extern univ_ptr;            { +0x41AC: SF's node }
  lir_41b0: extern solution_ptr_t;      { +0x41B0: the frame register's
                                          own solution while SF's stands
                                          in lir_3e60 (lir_$reinitialize) }
  lir_41b4: extern mrh_$mark_t;         { +0x41B4: lir_3c00's mark }
  lir_41b8: extern integer32;           { +0x41B8: the last line put in a
                                          block }
  lir_41bc: extern lir_count_t;         { +0x41BC: the labels made }
  lir_41c0: extern integer32;           { +0x41C0: lir_3b78's labels }
  lir_41c4: extern mrh_$mark_t;         { +0x41C4: lir_e90's mark }
  lir_41c8: extern mrh_$mark_t;         { +0x41C8: lir_ea8's mark }
  lir_41cc: extern mrh_$mark_t;         { +0x41CC: lir_ec0's mark }
  lir_41d0: extern mrh_$mark_t;         { +0x41D0: lir_ed8's mark }
  lir_41d4: extern lr_ptr_t;            { +0x41D4: the memory a load
                                          reads (inscrutable_memory) }
  lir_41d8: extern lr_ptr_t;            { +0x41D8: the memory a store
                                          writes }
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
  lir_4210: extern integer;             { +0x4210: the block's count at
                                          the last sets_cc }
  lir_4212: extern integer;             { +0x4212: at the last fp_ccs }
  lir_4214: extern integer;             { +0x4214: the instructions in the
                                          current block }
  lir_4218: extern boolean;             { +0x4218: the argument block's
                                          memory was written }
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
  { cargs.pas's data +0x258 (cargs_$options' flags; bit 7 read by
    lir_$disjoint_lhs_and_rhs_tokens). }
  cargs_258: extern char;
  { The messages build_message points to (build_message.init gives
    their text; the image lays them out before lir's A5, 0x486D98 ..,
    the last kind's first). }
  build_message_5: extern packed array [1..63] of char;
  build_message_6: extern packed array [1..65] of char;
  build_message_7: extern packed array [1..65] of char;
  build_message_8: extern packed array [1..59] of char;
  build_message_9: extern packed array [1..59] of char;
  build_message_10: extern packed array [1..60] of char;
  build_message_11: extern packed array [1..60] of char;
  build_message_12: extern packed array [1..61] of char;
  build_message_13: extern packed array [1..57] of char;
  build_message_14: extern packed array [1..57] of char;
  build_message_15: extern packed array [1..58] of char;
  build_message_16: extern packed array [1..58] of char;
  build_message_17: extern packed array [1..58] of char;
  build_message_18: extern packed array [1..66] of char;
  build_message_19: extern packed array [1..67] of char;
  build_message_26: extern packed array [1..57] of char;
  { The spans of the module's data no instruction addresses (the
    heaps' fourth longwords, the tables' ends). }
  lir_unused_3c: extern integer32;      { +0x03C }
  lir_unused_16c: extern integer32;     { +0x16C }
  lir_unused_29c: extern integer32;     { +0x29C }
  lir_unused_2dc: extern integer32;     { +0x2DC }
  lir_unused_394: extern integer32;     { +0x394 }
  lir_unused_c06: extern integer;       { +0xC06 }
  lir_unused_ea4: extern integer32;     { +0xEA4 }
  lir_unused_ebc: extern integer32;     { +0xEBC }
  lir_unused_ed4: extern integer32;     { +0xED4 }
  lir_unused_eec: extern integer32;     { +0xEEC }
  lir_unused_f04: extern integer32;     { +0xF04 }
  lir_unused_f1c: extern integer32;     { +0xF1C }
  lir_unused_f34: extern integer32;     { +0xF34 }
  lir_unused_2f54: extern integer32;    { +0x2F54 }
  lir_unused_3c14: extern integer32;    { +0x3C14 }
  lir_unused_3c2c: extern integer32;    { +0x3C2C }
  lir_unused_3c44: extern integer32;    { +0x3C44 }
  lir_unused_3c5c: extern integer32;    { +0x3C5C }
  lir_unused_3f64: extern array [0..4] of integer32;  { +0x3F64: the rest
                                          of the heap lir_3f60 (declared a
                                          longword in backend.ins.pas,
                                          which mrh.ins.pas follows) }
  lir_unused_3f7c: extern array [0..4] of integer32;  { +0x3F7C }

{ The module's data (A5 0x487180, 0x422C bytes) in address order (dpc
  lays defined cells out in define-list order; the unit has no own
  variables): the build_ tables (their .init files, included below, give
  them their values with second define statements), lir's cells, the
  messages last (the image's are before A5).  dpc gives each byte cell
  two bytes (docs/dpc-gaps.md 37), which is the image's spacing for
  +0x4218 .. +0x422A.  lir_3f94, lir_3f98 and lir_3f9c (backend.ins.pas,
  com's) are lir_3f90's elements 1..3: not defined here
  (docs/questions.md 351). }
define
  build_properties, lir_unused_3c, build_physical_ltss, build_physical_lrs,
  build_physical, lir_unused_16c, build_message, build_low_bound,
  build_like_kind, lir_unused_29c, build_kind, lir_unused_2dc,
  build_high_bound, build_arg_loc, lir_unused_394, build_access,
  build_action, lir_unused_c06,
  lir_c08, lir_d08, lir_d88, lir_de0, lir_e38,
  lir_e90, lir_unused_ea4, lir_ea8, lir_unused_ebc, lir_ec0, lir_unused_ed4,
  lir_ed8, lir_unused_eec, lir_ef0, lir_unused_f04, lir_f08, lir_unused_f1c,
  lir_f20, lir_unused_f34, lir_f38, lir_2f40, lir_unused_2f54, lir_2f58,
  lir_3b78, lir_3b80, lir_3ba8,
  lir_3c00, lir_unused_3c14, lir_3c18, lir_unused_3c2c, lir_3c30,
  lir_unused_3c44, lir_3c48, lir_unused_3c5c,
  lir_3c60, lir_3d60, lir_3e60, lir_3f60, lir_unused_3f64, lir_3f78,
  lir_unused_3f7c, lir_3f90, lir_4090,
  lir_4190, lir_4194, lir_4198, lir_419c,
  lir_41a0, lir_41a4, lir_41a8, lir_41ac, lir_41b0, lir_41b4, lir_41b8,
  lir_41bc, lir_41c0, lir_41c4, lir_41c8, lir_41cc, lir_41d0, lir_41d4,
  lir_41d8, lir_41dc, lir_41e0, lir_41e4, lir_41e8, lir_41ec, lir_41f0,
  lir_41f4, lir_41f8, lir_41fc, lir_4200, lir_4204, lir_4208, lir_420c,
  lir_4210, lir_4212, lir_4214, lir_4216, lir_4218, lir_421a, lir_421c,
  lir_421e, lir_4220, lir_4222, lir_4224, lir_4226, lir_4228, lir_422a,
  build_message_5,
  build_message_6,
  build_message_7,
  build_message_8,
  build_message_9,
  build_message_10,
  build_message_11,
  build_message_12,
  build_message_13,
  build_message_14,
  build_message_15,
  build_message_16,
  build_message_17,
  build_message_18,
  build_message_19,
  build_message_26;

{ +0x4190 .. +0x419F: the operand forms the image initializes (an
  access of 3; of$ip_reg_or_s_immed8 (7); of$ip_reg (18); none). }
define lir_4190 := [0, 0, 16#C0, 0];
define lir_4194 := [7, 0, 0, 0];
define lir_4198 := [18, 0, 0, 0];
define lir_419c := [0, 0, 0, 0];

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
  lir_41b0 := nil;
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

{ note_entry_to_handler_from_runtime - the handler (an exception
  handler's node) may be entered from the run-time: its +68 set, its
  label (+60) noted a target of asynchronous flow (its block's edge
  from the entry block) once.

  0x245710, 0x36 bytes, internal. }

procedure note_entry_to_handler_from_runtime(
    handler: univ_ptr); options(val_param, internal);
type
  handler_v_ptr_t = ^handler_v_t;
  handler_v_t = record
    space0: array [0..59] of char;      { +0 }
    lab: lir_label_ptr_t;               { +60 }
    space64: array [64..67] of char;    { +64 }
    b68: boolean;                       { +68 }
  end;
var
  h: handler_v_ptr_t;
  lab: lir_label_ptr_t;
begin
  h := handler;
  h^.b68 := true;
  lab := h^.lab;
  if lab <> nil then
    if not lab^.f10.async_target then begin
      lab^.f10.async_target := true;
      lir_$note_target_of_asynchronous_flow(lab^.bb);
    end;
end;

{ no_associated_modify_operand - whether no operand of instr after op
  modifies op's live range.

  0x245746, 0x56 bytes, internal. }

function no_associated_modify_operand(
    instr: instr_ptr_t;
    op: lir_pre_opnd_ptr_t): boolean; options(val_param, internal);
var
  k: integer32;
  n: integer32;
begin
  k := op^.h.num;
  n := instr^.h.nopnds;
  while k < n do begin
    k := k + 1;
    if instr^.opnds[k].h.modify then
      if lir_pre_opnd_ptr_t(addr(instr^.opnds[k]))^.lr = op^.lr then begin
        no_associated_modify_operand := false;
        return;
      end;
  end;
  no_associated_modify_operand := true;
end;

{ create_associated_modify_operand - instr's operand k made op's copy
  that modifies op's live range (read and intend_to_modify replaced by
  modify).

  0x24579C, 0x58 bytes, internal. }

procedure create_associated_modify_operand(
    instr: instr_ptr_t;
    op: lir_pre_opnd_ptr_t;
    k: integer32); options(val_param, internal);
var
  q: lir_pre_opnd_ptr_t;
begin
  q := addr(instr^.opnds[k]);
  q^.h := op^.h;
  q^.h.num := k;
  opnd_bytes_ptr_t(q)^.rrp := (opnd_bytes_ptr_t(q)^.rrp & 16#CF) ! 4;
  q^.rrp := (op^.rrp - [rrp$read, rrp$intend_to_modify]) + [rrp$modify];
  q^.lr := op^.lr;
end;

{ LIR_$COMPLETE_INSTRUCTION - instr (from lir_$get_new_instruction..,
  its operands built) put in the current block: deferred to the
  inherited attributes' l20's list when its flags' bit 15 asks; first
  the instructions attached to it (+24), then, unless the call's
  properties' b35, an instruction 202 reading the argument block
  offsets' memory live ranges they marked (lir_f38); the block broken
  at a new exception frame; the condition codes' register operand
  (lir_4226); the addressing mode (flags bits 4, 5: post- and premodify)
  and load/store qualifiers (bits 7, 8, 9: lsq 3, 1, 2; 9 ends the
  atomic sequence) checked and set; intend_to_modify operands given
  their modify copies and pairs their odd halves' operands; the
  register operands' segments made; the condition codes' operands
  (sets_cc, fp_ccs from the opcode or the call's properties, flags bits
  3..0); the memory operands (the argument block's lir_e38, lir_f38's
  by offset, or lir_41d4/lir_41d8); then the header stored, the line
  from the inherited attributes, lir_main_c44's chain (bit 25), the
  block (bit 20 pfm_cleanup), the labels' hidden edges (bit 17:
  lir_3b78, bit 16: the routine's l8), the exception information
  operand (target_properties +0xC1: exs_ enquiry), the edges a trap or
  CALL to the exit block takes, and the block ended after a transfer
  (bits 9, 16, 17, 19; a branch falls through).

  0x2457F4, 0xDCE bytes: the 'set CCs request' message names the build
  area's opcode (lir_2f58), not instr's; the combined pre- and
  postmodify test's first arm is dead (`btst #4' after `btst #4; bne').
  The image leaves D0 as it is: written as a procedure (lir_main
  discarded the value). }

procedure lir_$complete_instruction(
    instr_p: univ_ptr);
type
  defer_v_ptr_t = ^defer_v_t;
  defer_v_t = record
    space0: array [0..23] of char;      { +0 }
    l24: instr_ptr_t;                   { +24 }
  end;
  props_ptr_t = ^call_conv_$ptr_t;
var
  i: instr_ptr_t;
  flags: integer32;
  a2: instr_ptr_t;
  props: call_conv_$ptr_t;
  ni: instr_ptr_t;
  cnt: integer32;
  j: integer32;
  k: integer32;
  lr: lr_ptr_t;
  a: instr_attr_ptr_t;
  hw: lir_ihdr_t;
  src: lir_inherited_ptr_t;
  cls: integer;
  nres: integer32;
  slot: integer32;
  op: lir_pre_opnd_ptr_t;
  q: lir_pre_opnd_ptr_t;
  s: lts_ptr_t;
  d2: integer;
  d4: integer;
  memw: boolean;
  flag: boolean;
  mkind: integer;
  keep: integer;
  off: integer32;
  bb: bb_ptr_t;
  lab: lir_label_ptr_t;
  isbr: boolean;
  handled: boolean;
  handled2: boolean;
  exc: univ_ptr;
  h: univ_ptr;
  xop: opnd_ptr_t;
  xb: ^opnd_bytes_t;
begin
  i := instr_p;
  flags := i^.l28;
  if (flags & 16#8000) <> 0 then begin
    flags := flags & (~16#8000);
    i^.l28 := flags;
    i^.next := defer_v_ptr_t(lir_41ec)^.l24;
    defer_v_ptr_t(lir_41ec)^.l24 := i;
    return;
  end;
  a2 := instr_ptr_t(i^.l24);
  if a2 <> nil then begin
    i^.l24 := 0;
    lir_41a0 := 0;
    repeat
      lir_$complete_instruction(a2);
      a2 := a2^.next;
    until a2 = nil;
    if instruction_attributes[i^.opc].class = class$call then
      props := props_ptr_t(addr(i^.opnds[i^.h.nopnds + 1]))^
    else
      props := nil;
    if (props = nil) or not props^.no_arg_block_read then
      if lir_41a0 <> 0 then begin
        cnt := 0;
        for k := lir_41a0 downto 1 do
          if lir_f38[k] <> nil then
            if lir_f38[k]^.f2.b3_4 then
              cnt := cnt + 1;
        if cnt <> 0 then begin
          ni := lir_$get_new_instruction_no_exceptions(nil, 202, 0, nil,
                                                       cnt + 2);
          k := lir_41a0;
          j := cnt;
          repeat
            lr := lir_f38[k];
            if lr <> nil then
              if lr^.f2.b3_4 then begin
                lr^.f2.b3_4 := false;
                build_non_register_reference(addr(ni^.opnds[j]), 9, j,
                                             [rrp$read], lr);
                j := j - 1;
              end;
            k := k - 1;
          until k = 0;
          ni^.h.b2_2 := true;
          lir_$complete_instruction(ni);
        end;
      end;
  end;
  if i^.opc = 0 then
    bug_check('LIR_$COMPLETE_INSTRUCTION -- opcode is missing/undefined%$');
  a := addr(instruction_attributes[i^.opc]);
  hw.h := i^.h;
  src := lir_inherited_ptr_t(i^.l32);
  if src <> nil then
    if src^.l4 <> lir_41e4 then begin
      cls := a^.class;
      if not ((cls in [class$branch, class$fp_branch])
              and (ord(i^.opnds[1].h.kind) in [15, 16])) then
        if not (cls in [4, 6, 10, 14, 18, 19, 24, 26]) then begin
          if not ((i^.opc = ord(opc$call)) and odd(hw.h.lsq)) then
            lir_421c := true;
          lir_41e4 := src^.l4;
          lir_4222 := true;
        end;
    end;
  if lir_4226 then begin
    k := 1;
    while ord(i^.opnds[k].h.kind) <> 0 do
      k := k + 1;
    lir_4198.num := k;
    lir_$build_operand(addr(i^.opnds[k]), lir_3e60[1], lir_4198);
  end;
  if (flags & 944) <> 0 then begin
    if not (a^.class in [class$load, class$store]) then
      bug_check('LIR_$COMPLETE_INSTRUCTION -- request requires address mode: %a%$',
                instruction_mnemonic[i^.opc], 12);
    if (flags & 48) <> 0 then
      if (flags & 16) = 0 then begin
        if not (a^.amse in [1, 3, 4, 5, 6]) then
          bug_check('LIR_$COMPLETE_INSTRUCTION -- postmodify addressing not supported: %a%$',
                    instruction_mnemonic[i^.opc], 12);
        hw.h.modify := 1;
      end
      else if (flags & 32) = 0 then begin
        if not (a^.amse in [1, 2, 3, 4, 5, 6]) then
          bug_check('LIR_$COMPLETE_INSTRUCTION -- premodify addressing not supported: %a%$',
                    instruction_mnemonic[i^.opc], 12);
        hw.h.modify := 2;
      end
      else if (flags & 16) = 0 then
        hw.h.modify := 1
      else
        bug_check('LIR_$COMPLETE_INSTRUCTION -- both pre & post-modify: %a%$',
                  instruction_mnemonic[i^.opc], 12);
    if (flags & 896) <> 0 then
      if (flags & 640) = 0 then
        hw.h.lsq := 1
      else if (flags & 384) = 0 then begin
        lir_4228 := false;
        lir_4226 := false;
        hw.h.lsq := 2;
        if a^.class = class$load then begin
          lir_41fc^.last^.h.grouped := true;
          lir_41fc^.last^.h.quad_aligned := true;
        end;
      end
      else if (flags & 768) = 0 then
        hw.h.lsq := 3
      else
        bug_check('LIR_$COMPLETE_INSTRUCTION -- mutliple conflicting qualifiers: %a%$',
                  instruction_mnemonic[i^.opc], 12);
  end;
  nres := a^.nresults;
  if a^.class in [class$call, class$svc] then
    while ord(i^.opnds[nres + 1].h.kind) <> 0 do
      nres := nres + 1;
  slot := nres + 1;
  for k := 1 to nres do begin
    op := addr(i^.opnds[k]);
    if op^.h.intend_to_modify then
      if no_associated_modify_operand(i, op) then begin
        slot := utils_$find_unused_operand_slot(i, slot);
        create_associated_modify_operand(i, op, slot);
      end;
    if op^.h.kind = operand$fp_reg_pair then begin
      slot := utils_$find_unused_operand_slot(i, slot);
      q := addr(i^.opnds[slot]);
      q^.h := op^.h;
      q^.h.num := slot;
      q^.h.fp_reg_even_only := false;
      q^.h.fp_reg_odd_only := true;
      q^.rrp := (op^.rrp - [rrp$fp_reg_even_only]) + [rrp$fp_reg_odd_only];
      q^.lr := op^.lr^.mate;
      q^.lr^.rrp := rrp$set_t(integer(q^.lr^.rrp) ! lir_4216);
      op^.h.fp_reg_even_only := true;
      op^.rrp := op^.rrp + [rrp$fp_reg_even_only];
      if q^.h.intend_to_modify then
        if no_associated_modify_operand(i, q) then begin
          slot := utils_$find_unused_operand_slot(i, slot);
          create_associated_modify_operand(i, q, slot);
        end;
    end;
  end;
  for k := 1 to hw.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if ord(op^.h.kind) in [1, 2, 3, 4, 5, 6] then begin
      s := get_lts_in_current_bb(op^.lr, op^.rrp);
      if s^.l40 = 0 then
        s^.refs := univ_ptr(op)
      else
        opnd_ptr_t(s^.l40)^.link := univ_ptr(op);
      s^.l40 := integer32(op);
      opnd_ptr_t(op)^.lts := s;
      opnd_ptr_t(op)^.link := nil;
    end;
  end;
  if a^.class = class$call then begin
    props := props_ptr_t(addr(i^.opnds[hw.h.nopnds + 1]))^;
    hw.h.fp_ccs := not props^.no_fp_cc_write;
    hw.h.sets_cc := not props^.no_ip_cc_write;
  end
  else begin
    props := nil;
    hw.h.fp_ccs := (a^.w18 & 16#100) <> 0;
    hw.h.sets_cc := (a^.w18 & 16#200) <> 0;
  end;
  if (flags & 15) <> 0 then begin
    if not a^.b14_0 then
      bug_check('LIR_$COMPLETE_INSTRUCTION -- set CCs request on %a%$',
                instruction_mnemonic[lir_2f58.opc], 12);
    if (a^.w18 & 16#80) <> 0 then
      hw.h.fp_ccs := true
    else
      hw.h.sets_cc := true;
    hw.h.preference := false;
  end;
  if hw.h.preference then
    if i^.opnds[1].lts^.lr^.f2.physical then
      if i^.opnds[2].lts^.lr^.f2.physical then
        hw.h.preference := false;
  if (a^.w18 & 16#40) <> 0 then begin
    d2 := hw.h.nopnds;
    if a^.b14_0 or hw.h.sets_cc then
      d2 := d2 - 1;
    if (a^.w18 & 16#80) <> 0 then
      build_non_register_reference(addr(i^.opnds[d2]), 8, d2, [rrp$read],
                                   addr(lir_de0))
    else
      build_non_register_reference(addr(i^.opnds[d2]), 7, d2, [rrp$read],
                                   addr(lir_d88));
  end;
  if hw.h.fp_ccs then begin
    lir_4212 := lir_4214;
    build_non_register_reference(addr(i^.opnds[hw.h.nopnds]), 8,
                                 hw.h.nopnds, [rrp$write], addr(lir_de0));
  end;
  if hw.h.sets_cc then begin
    lir_4210 := lir_4214;
    d2 := hw.h.nopnds;
    if hw.h.fp_ccs then
      d2 := d2 - 1;
    build_non_register_reference(addr(i^.opnds[d2]), 7, d2, [rrp$write],
                                 addr(lir_d88));
  end;
  if ((a^.w18 & 16#100) <> 0) and ((a^.w18 & 16#200) <> 0) then begin
    hw.h.fp_ccs := false;
    hw.h.sets_cc := false;
  end;
  if (a^.class in [2, 4, 7, 14, 15, 16, 20, 21, 22, 23, 24, 27])
     and ((flags & 16#1000) = 0) then begin
    utils_$strip_may_gen_exception(i);
    hw.h.may_generate_an_exception := i^.h.may_generate_an_exception;
    if (i^.opc = 202) and (ord(i^.opnds[1].h.kind) = 0) then begin
      build_non_register_reference(addr(i^.opnds[1]), 9, 1, [rrp$read],
          lir_pre_opnd_ptr_t(addr(i^.opnds[1]))^.lr);
      build_non_register_reference(addr(i^.opnds[2]), 9, 2, [rrp$write],
          lir_pre_opnd_ptr_t(addr(i^.opnds[2]))^.lr);
      lir_4218 := true;
    end;
    d4 := hw.h.nopnds;
    if a^.b14_0 then
      d4 := d4 - 1
    else if ord(i^.opnds[hw.h.nopnds].h.kind) <> 0 then
      if ord(i^.opnds[hw.h.nopnds - 1].h.kind) <> 0 then
        d4 := d4 - 2
      else
        d4 := d4 - 1;
    memw := false;
    if (a^.class in [2, 4, 7, 12, 14, 20, 21, 23, 24])
       or ((a^.class in [class$load_pair, class$mfpr])
           and ((flags & 16#800) <> 0)) then begin
      d4 := d4 - 1;
      memw := true;
      if utils_$instr_is_ref_to_argument_block(i) then begin
        lr := addr(lir_e38);
        mkind := 9;
      end
      else if not i^.h.b2_2 then begin
        lr := lir_41d8;
        mkind := 10;
      end
      else if (a^.class = class$store) or (i^.opc = 202) then begin
        lr := addr(lir_e38);
        mkind := 9;
      end
      else begin
        lr := lir_41d8;
        mkind := 10;
      end;
    end
    else if utils_$instr_is_ref_to_argument_block(i) then begin
      lr := addr(lir_e38);
      mkind := 9;
    end
    else begin
      lr := lir_41d4;
      mkind := 10;
    end;
    keep := d4;
    if (props = nil) or not props^.no_memory_read or props^.b29 then
      build_non_register_reference(addr(i^.opnds[d4]), mkind, d4, [rrp$read],
                                   lr);
    if memw then begin
      if i^.h.b2_2 and (mkind = 9) and (a^.class = class$store) then begin
        if i^.opnds[2].h.kind <> operand$immediate then
          bug_check('LIR_$COMPLETE_INSTRUCTION -- non-immediate arg block offset%$');
        off := i^.opnds[2].value;
        if off < 2048 then begin
          if off > lir_41a0 then
            lir_41a0 := off;
          lr := lir_f38[off];
          if lr = nil then begin
            lr := lir_$new_live_range;
            lir_f38[off] := lr;
          end;
        end;
        lr^.f2.b3_4 := true;
      end
      else if mkind = 9 then
        lr := addr(lir_e38)
      else
        lr := lir_41d8;
      if (props = nil) or not props^.no_memory_write or props^.b29 then begin
        if lr = addr(lir_e38) then
          lir_4218 := true;
        d4 := d4 + 1;
        build_non_register_reference(addr(i^.opnds[d4]), mkind, d4,
                                     [rrp$write], lr);
      end;
    end;
    flag := false;
    d2 := keep - 1;
    if i^.opc = 197 then begin
      memw := false;
      flag := true;
    end
    else if a^.class = class$svc then begin
      memw := true;
      flag := true;
    end
    else if props <> nil then
      if not props^.no_arg_block_read or lir_4218
         or not props^.no_arg_block_write then begin
        memw := true;
        flag := true;
      end;
    if flag then begin
      if memw then
        build_non_register_reference(addr(i^.opnds[d2 - 1]), 9, d2 - 1,
                                     [rrp$read], addr(lir_e38));
      build_non_register_reference(addr(i^.opnds[d2]), 9, d2, [rrp$write],
                                   addr(lir_e38));
      lir_4218 := false;
    end;
  end;
  i^.h := hw.h;
  src := lir_inherited_ptr_t(i^.l32);
  if src <> nil then begin
    lir_ipos_ptr_t(i)^.line := src^.w34;
    lir_ipos_ptr_t(i)^.w34 := 0;
  end;
  if (flags & 16#2000000) <> 0 then begin
    i^.l32 := integer32(lir_main_c44);
    lir_main_c44 := i;
  end;
  bb := get_basic_block;
  add_instruction_to_basic_block(i, bb);
  if (flags & 16#100000) <> 0 then
    bb^.f.pfm_cleanup := true;
  if (flags & 16#20000) <> 0 then
    if lir_41c0 <> 0 then begin
      for k := 1 to lir_41c0 do
        add_fge_to_labeled_basic_block(nil, lir_3b78[k]);
      if a^.class in [class$call, class$svc] then
        i^.h.lsq := i^.h.lsq ! 2;
    end;
  if (flags & 16#10000) <> 0 then begin
    lab := lir_41e0^.l8;
    while lab <> nil do begin
      add_fge_to_labeled_basic_block(nil, lab);
      lab := lab^.next;
    end;
    if a^.class in [class$call, class$svc] then
      i^.h.lsq := i^.h.lsq ! 2;
  end;
  isbr := a^.class = class$call;
  if ord(target_properties.p_bf[2]) >= 128 then
    if isbr or hw.h.may_generate_an_exception then begin
      k := utils_$find_unused_operand_slot(i, 1);
      xop := addr(i^.opnds[k]);
      xb := univ_ptr(xop);
      xb^.b3 := (xb^.b3 & 16#E0) ! 28;
      xop^.h.num := k;
      exs_$start_exception_handler_enquiry(univ_ptr(src^.l4), true_il(src),
          isbr, false, handled, exc, lir_exc_opnd_ptr_t(xop)^.handler,
          lir_exc_opnd_ptr_t(xop)^.flag, lir_exc_opnd_ptr_t(xop)^.word);
      if exc <> nil then
        lir_exc_opnd_ptr_t(xop)^.predef :=
            chr(exs_$map_to_predefined_exception(exc));
      if a^.class <> class$call then begin
        h := exs_$next_exception_handler;
        if h <> nil then
          note_entry_to_handler_from_runtime(h);
        exs_$end_exception_handler_enquiry(handled);
      end
      else begin
        repeat
          h := exs_$next_exception_handler;
          if h <> nil then
            note_entry_to_handler_from_runtime(h);
        until h = nil;
        exs_$end_exception_handler_enquiry(handled2);
      end;
    end;
  if ((i^.opc = ord(opc$call)) and odd(hw.h.lsq))
     or (a^.class = class$trap) then begin
    bb^.f.hidden_successor_edges := true;
    discard(lir_$add_flow_graph_edge(bb, lir_41f8));
    lir_4224 := false;
    lir_421c := false;
    lir_4222 := true;
  end
  else if ((flags & 16#10200) <> 0)
          or (((flags & 16#20000) <> 0) and (lir_41c0 > 0))
          or ((flags & 16#80000) <> 0) then begin
    if ((flags & 16#10200) = 0)
       and not (((flags & 16#20000) <> 0) and (lir_41c0 > 0)) then
      lir_421e := true;
    lir_4224 := false;
    lir_421c := true;
    lir_4222 := true;
  end
  else if a^.class in [1, 5, 6, 24] then
    if a^.class in [class$branch, class$fp_branch] then begin
      lir_4224 := true;
      lir_421c := true;
    end
    else begin
      lir_4224 := false;
      lir_421c := false;
      lir_4222 := true;
    end;
  if lir_421a then
    dmp_$instruction(i);
end;

{ LIR_$DISPATCH_INSTRUCTION - a JUMP (opcode 70, DISPATCH, asked for)
  through the solution sol, its edges to every label it may reach: the
  routine's l4 labels (flags bit 18; none: an edge to the exit block),
  or the case table lir_41e8 (bit 23: its entries made their labels'
  instructions); 'unknown context' otherwise.

  0x2467B6, 0x108 bytes: lir_$get_new_instruction called with three
  arguments (pattern 132); the operand's form JUMP's first. }

procedure lir_$dispatch_instruction(
    attrs: univ_ptr;
    sol: solution_ptr_t;
    opc: integer;
    flags: integer32);
type
  table_v_ptr_t = ^table_v_t;
  table_v_t = record
    space0: array [0..11] of char;      { +0 }
    n: integer32;                       { +12: the entries }
    space16: array [16..19] of char;    { +16 }
    ent: array [0..65535] of univ_ptr;  { +20: labels, made
                                          instructions }
  end;
var
  i: instr_ptr_t;
  lab: lir_label_ptr_t;
  bb: bb_ptr_t;
  t: table_v_ptr_t;
  k: integer32;
begin
  if opc <> ord(opc$dispatch) then
    bug_check('LIR_$DISPATCH_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  i := lir_$get_new_instruction(attrs, ord(opc$jump), flags, nil, 0);
  lir_$build_operand(addr(i^.opnds[1]), sol,
      instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$jump)]))^.opnds[1]);
  if (flags & 16#40000) <> 0 then begin
    lab := lir_41e0^.l4;
    if lab = nil then begin
      bb := get_basic_block;
      bb^.f.hidden_successor_edges := true;
      discard(lir_$add_flow_graph_edge(bb, lir_41f8));
    end
    else
      while lab <> nil do begin
        add_fge_to_labeled_basic_block(nil, lab);
        lab := lab^.next;
      end;
  end
  else if (flags & 16#800000) <> 0 then begin
    t := univ_ptr(lir_41e8);
    for k := t^.n - 1 downto 0 do begin
      lab := t^.ent[k];
      t^.ent[k] := lab^.instr;
      add_fge_to_labeled_basic_block(nil, lab);
    end;
  end
  else
    bug_check('LIR_$DISPATCH_INSTRUCTION -- unknown context%$');
  lir_41e8 := 0;
  lir_$complete_instruction(i);
end;

{ LIR_$BRANCH_INSTRUCTION - a branch (a class 1, 5 or 6 opcode of one
  operand) to the label.

  0x24691E, 0xA6 bytes. }

procedure lir_$branch_instruction(
    attrs: univ_ptr;
    label_p: univ_ptr;
    opc: integer;
    flags: integer32);
var
  a: instr_attr_ptr_t;
  i: instr_ptr_t;
begin
  a := addr(instruction_attributes[opc]);
  if not ((a^.class in [1, 5, 6]) and (a^.nresults = 1)) then
    bug_check('LIR_$BRANCH_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  begin_instruction(attrs, opc, flags, nil, 0);
  i := copy_build_instruction;
  i^.opnds[1].h.num := 1;
  add_fge_to_labeled_basic_block(addr(i^.opnds[1]), label_p);
  lir_$complete_instruction(i);
end;

{ LIR_$OPERATE_AND_BRANCH_INSTRUCTION - a compare-and-branch (class 1,
  5 or 6, three operands) of sol1 and sol2 to the label.

  0x2469F4, 0xCE bytes. }

procedure lir_$operate_and_branch_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol1: solution_ptr_t;
    sol2: solution_ptr_t;
    label_p: univ_ptr);
var
  a: instr_attr_view_ptr_t;
  i: instr_ptr_t;
begin
  a := addr(instruction_attributes[opc]);
  if not ((instruction_attributes[opc].class in [1, 5, 6])
          and (instruction_attributes[opc].nresults = 3)) then
    bug_check('LIR_$OPERATE_AND_BRANCH_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  begin_instruction(attrs, opc, flags, nil, 0);
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol1, a^.opnds[1]);
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol2, a^.opnds[2]);
  i := copy_build_instruction;
  i^.opnds[3].h.num := 3;
  add_fge_to_labeled_basic_block(addr(i^.opnds[3]), label_p);
  lir_$complete_instruction(i);
end;

{ prolog_label_for_specific_exception - the label of handler's (a
  handler node, kind 223) prologue for the exception exc: from its list
  (+56: 12-byte records from lir_3c30, next, label, exception), made
  the first time.

  0x246AFE, 0x78 bytes, internal; its message names 'LIR_
  \PROLOG_LABEL_FOR_SPECIFIC_EXCEPTION' (the bytes). }

function prolog_label_for_specific_exception(
    handler: il_$node_ptr_t;
    exc: univ_ptr): univ_ptr; options(val_param, internal);
type
  plab_ptr_t = ^plab_t;
  plab_t = record
    next: plab_ptr_t;                   { +0 }
    lab: univ_ptr;                      { +4 }
    exc: univ_ptr;                      { +8 }
  end;
var
  p: plab_ptr_t;
begin
  if handler^.kind <> 223 then
    bug_check('LIR_ \PROLOG_LABEL_FOR_SPECIFIC_EXCEPTION -- handler argument has wrong .kind%$');
  p := univ_ptr(handler^.xp[14]);
  while p <> nil do begin
    if p^.exc = exc then begin
      prolog_label_for_specific_exception := p^.lab;
      return;
    end;
    p := p^.next;
  end;
  p := mrh_$alloc(lir_3c30, 12);
  p^.exc := exc;
  p^.next := univ_ptr(handler^.xp[14]);
  handler^.xp[14] := univ_ptr(p);
  p^.lab := lir_$new_label;
  prolog_label_for_specific_exception := p^.lab;
end;

{ LIR_$USE_TRAP_FOR_EXCEPTION_RAISE - whether an exception raised at
  site in frame is handled (or is a predefined exception) so that a
  trap is used.

  0x246BC6, 0x62 bytes. }

function lir_$use_trap_for_exception_raise(
    frame: univ_ptr;
    site: univ_ptr): boolean;
var
  handled: boolean;
  exc: univ_ptr;
  handler: univ_ptr;
begin
  exs_$exception_raise_strategy(frame, site, handled, exc, handler);
  if handled then
    lir_$use_trap_for_exception_raise := true
  else if exc <> nil then
    lir_$use_trap_for_exception_raise :=
        exs_$map_to_predefined_exception(exc) <> 7
  else
    lir_$use_trap_for_exception_raise := false;
end;

{ LIR_$TRAP_INSTRUCTION - a trap (class 14 or 27) of sol: a branch to
  the handler's prologue for the exception (TRAP a JUMP, a conditional
  trap its branch: opcode - 40 for a double's, - 20 otherwise) when the
  exception is handled here, else the trap (a pair's operand one more
  operand's room).

  0x246C28, 0x13A bytes: begin_instruction called with three arguments
  and copy_build_instruction with one (patterns 132, 136). }

procedure lir_$trap_instruction(
    attrs: lir_inherited_ptr_t;
    opc: integer;
    flags: integer32;
    sol: solution_ptr_t);
var
  a: instr_attr_view_ptr_t;
  handled: boolean;
  exc: univ_ptr;
  handler: univ_ptr;
  lab: univ_ptr;
  nopc: integer;
begin
  a := addr(instruction_attributes[opc]);
  if not (instruction_attributes[opc].class in [class$trap, class$trap_cond]) then
    bug_check('LIR_$TRAP_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  lir_$complete_top_level_node_inherited_attrs(attrs);
  exs_$exception_raise_strategy(univ_ptr(attrs^.l4), true_il(attrs), handled,
                                exc, handler);
  if handled then begin
    lab := prolog_label_for_specific_exception(handler, exc);
    if opc = ord(opc$trap) then
      nopc := ord(opc$jump)
    else if instruction_attributes[opc].b4 = 4 then
      nopc := opc - 40
    else
      nopc := opc - 20;
    lir_$branch_instruction(attrs, lab, nopc, flags);
  end
  else begin
    begin_instruction(attrs, opc, flags, nil, 0);
    if instruction_attributes[opc].nresults <> 0 then begin
      lir_$build_operand(addr(lir_2f58.opnds[1]), sol, a^.opnds[1]);
      if lir_2f58.opnds[1].h.kind = operand$fp_reg_pair then
        lir_41a4.l := lir_41a4.l + 24;
    end;
    lir_$complete_instruction(copy_build_instruction);
  end;
end;

{ LIR_$SIMPLE_INSTRUCTION - an instruction of up to four operands from
  the solutions sol1..sol4 (a CMP with zero made a TST of sol2; a trap
  passed to lir_$trap_instruction; a move of a register to itself
  dropped; a move between operands of one kind with no count marked a
  preference).

  0x246D90, 0x1EE bytes: the opcode's class set constants; `btst d1,
  (6,A2)' with the class set in D1 (bit 0: pattern 148);
  begin_instruction with three arguments, copy_build_instruction with
  one (patterns 132, 136). }

procedure lir_$simple_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol1: solution_ptr_t;
    sol2: solution_ptr_t;
    sol3: solution_ptr_t;
    sol4: solution_ptr_t);
label
  99;
var
  a: instr_attr_view_ptr_t;
  n: integer;
begin
  if opc = ord(opc$cmp) then
    if ((sol1^.kind = 14) and (sol1^.disp = 0))
       or ((sol1^.f78.reg = 31) and (sol1^.kind = 11)
           and sol1^.f78.physical) then begin
      opc := ord(opc$tst);
      sol1 := sol2;
    end;
  a := addr(instruction_attributes[opc]);
  if not (instruction_attributes[opc].class in [0, 3, 7, 8, 12, 13, 14, 17, 27])
     or odd(instruction_attributes[opc].b14_7_1) then
    bug_check('LIR_$SIMPLE_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  if instruction_attributes[opc].class in [class$trap, class$trap_cond] then begin
    lir_$trap_instruction(attrs, opc, flags, sol1);
    goto 99;
  end;
  if instruction_attributes[opc].b6_0 then
    if (sol1^.kind = sol2^.kind) and (sol1^.f78.shift = sol2^.f78.shift)
       and (sol1^.f78.physical = sol2^.f78.physical) then
      if sol1^.f78.physical then begin
        if sol1^.f78.reg = sol2^.f78.reg then
          goto 99;
      end
      else if sol2^.lr <> nil then
        if sol2^.lr = sol1^.lr then
          goto 99;
  begin_instruction(attrs, opc, flags, nil, 0);
  n := instruction_attributes[opc].nresults;
  if n <> 0 then begin
    lir_$build_operand(addr(lir_2f58.opnds[1]), sol1, a^.opnds[1]);
    if n > 1 then begin
      lir_$build_operand(addr(lir_2f58.opnds[2]), sol2, a^.opnds[2]);
      if n > 2 then begin
        lir_$build_operand(addr(lir_2f58.opnds[3]), sol3, a^.opnds[3]);
        if n > 3 then
          lir_$build_operand(addr(lir_2f58.opnds[4]), sol4, a^.opnds[4]);
      end
      else if instruction_attributes[opc].b6_0 then
        if lir_2f58.opnds[1].h.kind = lir_2f58.opnds[2].h.kind then
          if lir_2f58.opnds[1].h.count = 0 then
            lir_2f58.h.preference := true;
    end;
  end;
  lir_$complete_instruction(copy_build_instruction);
99:
end;

{ LIR_$FIELD_INSTRUCTION - an insert or extract (the opcode's b14 bit
  1) of width 1..32 bits, three operands.

  0x246FAE, 0xDC bytes. }

procedure lir_$field_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    width: integer32;
    sol1: solution_ptr_t;
    sol2: solution_ptr_t;
    sol3: solution_ptr_t);
var
  a: instr_attr_view_ptr_t;
begin
  a := addr(instruction_attributes[opc]);
  if not odd(instruction_attributes[opc].b14_7_1) then
    bug_check('LIR_$FIELD_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  begin_instruction(attrs, opc, flags, nil, 0);
  if (width <= 0) or (width > 32) then
    bug_check('LIR_$FIELD_INSTRUCTION -- illegal field width: %D%$', width);
  lir_2f58.h.width := width;
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol1, a^.opnds[1]);
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol2, a^.opnds[2]);
  lir_$build_operand(addr(lir_2f58.opnds[3]), sol3, a^.opnds[3]);
  lir_$complete_instruction(copy_build_instruction);
end;

{ LIR_$LOAD_INSTRUCTION - a load (class 16) of the address sol_a
  (+ sol_b) into sol_c: flags bit 8 begins a locked sequence (an AND
  of the frame's -4 into register 1 first, unless the routine's +374
  bit 5); home (a memory home: its alias descriptor, offset by the
  advance and disp); a negative literal through the DB register
  raises no exception; bit 6 an advancing address mode (sol_a its own
  base, by the access size; bit 5 through the frame solution
  lir_main_760); bits 7..9 a qualified access (lir_4194's form); bits
  4, 5 a modified base.  bits: the address's known low bits (+3 bits
  3..1).

  0x2470EC, 0x274 bytes: the AND made with three arguments (pattern
  132). }

procedure lir_$load_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol_a: solution_ptr_t;
    sol_b: solution_ptr_t;
    sol_c: solution_ptr_t;
    home: univ_ptr;
    disp: integer32;
    bits: integer32;
    p10: integer32);
var
  a: instr_attr_view_ptr_t;
  sz: integer32;
  adv: integer32;
  save: integer32;
  d: integer32;
  f: instr_attr_opnd_t;
begin
  a := addr(instruction_attributes[opc]);
  if instruction_attributes[opc].class <> class$load then
    bug_check('LIR_$LOAD_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  if (flags & 16#100) <> 0 then begin
    lir_4228 := true;
    lir_4222 := true;
    lir_421c := true;
    if (ord(il_180^.xc[374]) & 16#20) = 0 then begin
      begin_instruction(attrs, ord(opc$and), 0, nil, 0);
      lir_main_760.disp := -4;
      lir_$build_operand(addr(lir_2f58.opnds[1]), addr(lir_main_760),
          instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$and)]))^.opnds[1]);
      lir_$build_operand(addr(lir_2f58.opnds[2]), isc_user_routines_330,
          instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$and)]))^.opnds[2]);
      lir_$build_operand(addr(lir_2f58.opnds[3]), lir_3e60[1],
          instr_attr_view_ptr_t(addr(instruction_attributes[ord(opc$and)]))^.opnds[3]);
      lir_$complete_instruction(copy_build_instruction);
      lir_4226 := true;
    end;
  end;
  if home <> nil then
    flags := flags ! 16#2000;
  if sol_a^.kind = 14 then
    if sol_a^.disp < 0 then
      if sol_b^.lr = isc_user_routines_338^.lr then begin
        flags := flags ! 16#1000;
        flags := flags & (~16#2000);
      end;
  if (flags & 16#40) <> 0 then begin
    if sol_b <> nil then
      bug_check('LIR_$LOAD_INSTRUCTION -- advancing_address_mode but B operand is not NIL%$');
    sol_b := sol_a;
    sz := lshft(1, instruction_attributes[opc].w18 & 7);
    adv := sol_a^.l28;
    save := adv;
    bits := bits + adv;
    adv := adv + sz;
    if (flags & 16#20) <> 0 then begin
      sol_a^.l28 := adv;
      lir_main_760.disp := sz;
      sol_a := addr(lir_main_760);
    end;
    if sol_b^.kind = 5 then
      sol_b := solution_ptr_t(sol_b^.l4);
  end
  else
    save := 0;
  begin_instruction(attrs, opc, flags, home, 0);
  if lir_2f58.h.b2_7 then begin
    d := save + disp;
    if d <> 0 then
      lir_2f58.h.b2_7 := alias_$add_disp(lir_2f40, d);
  end;
  lir_2f58.h.low_bits := bits & 7;
  if (flags & 896) = 0 then
    f := a^.opnds[1]
  else begin
    lir_4194.num := 1;
    f := lir_4194;
  end;
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol_a, f);
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol_b, a^.opnds[2]);
  lir_$build_operand(addr(lir_2f58.opnds[3]), sol_c, a^.opnds[3]);
  if (flags & 48) <> 0 then
    convert_to_intend_to_modify(univ_ptr(addr(lir_2f58.opnds[2])))
  else if (flags & 16#40) <> 0 then
    sol_a^.l28 := adv;
  lir_$complete_instruction(copy_build_instruction);
end;

{ LIR_$MFPR_INSTRUCTION - an MFPR (opcode 115) of three operands, home
  its memory home.

  0x2473D8, 0xC8 bytes. }

procedure lir_$mfpr_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol1: solution_ptr_t;
    sol2: solution_ptr_t;
    sol3: solution_ptr_t;
    home: univ_ptr);
var
  a: instr_attr_view_ptr_t;
begin
  a := addr(instruction_attributes[opc]);
  if opc <> ord(opc$mfpr) then
    bug_check('LIR_$MFPR_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  if home <> nil then
    flags := flags ! 16#2000;
  begin_instruction(attrs, opc, flags, home, 0);
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol1, a^.opnds[1]);
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol2, a^.opnds[2]);
  lir_$build_operand(addr(lir_2f58.opnds[3]), sol3, a^.opnds[3]);
  lir_$complete_instruction(copy_build_instruction);
end;

{ LIR_$COMMON_LHS_RHS_TOKEN - the loads and stores since a
  lir_$disjoint_lhs_and_rhs_tokens back to one memory: an MMT_SEQ
  reading the stores' memory live range (lir_41d8) and the memory
  (lir_3ba8) again for both.  Both must have been read and written
  ('MMT_SEQ was pointless').

  0x2474CE, 0xA0 bytes: lir_$get_new_instruction with its five
  arguments (3 operands). }

procedure lir_$common_lhs_rhs_token(
    attrs: univ_ptr);
var
  m: lr_ptr_t;
  i: instr_ptr_t;
begin
  m := addr(lir_3ba8);
  if (lir_41d4 = m) and (lir_41d8 = m) then
    return;
  if not (rrp$read in lir_41d8^.rrp) or not (rrp$read in lir_41d4^.rrp) then
    bug_check('LIR_$COMMON_LHS_RHS_TOKEN -- MMT_SEQ was pointless -- no consumers%$');
  i := lir_$get_new_instruction(attrs, ord(opc$mmt_seq), 0, nil, 3);
  build_non_register_reference(addr(i^.opnds[1]), 10, 1, [rrp$read], lir_41d8);
  lir_41d8 := m;
  lir_41d4 := m;
  lir_$complete_instruction(i);
end;

{ LIR_$DISJOINT_LHS_AND_RHS_TOKENS - unless lhs and rhs (IL nodes) may
  overlap (a class 16 descriptor of lhs, class 0 or 11 of rhs, or
  related unless cargs +0x258's flag): an MMT_SEQ from the memory to
  two new memory live ranges, the loads' (lir_41d4) and the stores'
  (lir_41d8).  Not nested.

  0x2475B2, 0x124 bytes. }

procedure lir_$disjoint_lhs_and_rhs_tokens(
    attrs: univ_ptr;
    lhs: univ_ptr;
    rhs: univ_ptr);
var
  dl: alias_$desc_t;
  dr: alias_$desc_t;
  okl: boolean;
  m: lr_ptr_t;
  i: instr_ptr_t;
  rd: lr_ptr_t;
  wr: lr_ptr_t;
begin
  okl := alias_$get_alias_desc(lhs, 1, dl);
  if okl and (dl.class = 16) then
    return;
  if alias_$get_alias_desc(rhs, 1, dr) then begin
    dl.inexact := true;
    dr.inexact := true;
    if dr.class in [0, 11] then
      return;
    if okl then
      if not (ord(cargs_258) >= 128) then
        if not alias_$related(dl, dr) then
          return;
  end;
  m := addr(lir_3ba8);
  if (lir_41d8 <> m) or (lir_41d4 <> m) then
    bug_check('LIR_$DISJOINT_LHS_AND_RHS_TOKENS -- nested disjoint tokens unsupported%$');
  i := lir_$get_new_instruction(attrs, ord(opc$mmt_seq), 0, nil, 4);
  rd := lir_$new_live_range;
  build_non_register_reference(addr(i^.opnds[1]), 10, 1, [rrp$write], rd);
  wr := lir_$new_live_range;
  build_non_register_reference(addr(i^.opnds[2]), 10, 2, [rrp$write], wr);
  lir_$complete_instruction(i);
  lir_41d8 := wr;
  lir_41d4 := rd;
end;

{ LIR_$STORE_INSTRUCTION - a store (class 21) of sol_a to the address
  sol_b (+ sol_c), as lir_$load_instruction's: a home whose solution's
  symbol is a kind 204 node defers the store (flags bit 15); bit 9 a
  qualified access (lir_4194's form for operand 2); bit 15 marks the
  instruction's b2_2.

  0x24771E, 0x1D0 bytes. }

procedure lir_$store_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol_a: solution_ptr_t;
    sol_b: solution_ptr_t;
    sol_c: solution_ptr_t;
    home: univ_ptr;
    disp: integer32;
    bits: integer32;
    p10: integer32);
type
  sym_v_ptr_t = ^sym_v_t;
  sym_v_t = record
    w0: integer;
    kind: integer;
  end;
var
  a: instr_attr_view_ptr_t;
  sz: integer32;
  adv: integer32;
  save: integer32;
  d: integer32;
  f: instr_attr_opnd_t;
begin
  a := addr(instruction_attributes[opc]);
  if instruction_attributes[opc].class <> class$store then
    bug_check('LIR_$STORE_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  if home <> nil then
    flags := flags ! 16#2000;
  if sol_b^.sym <> nil then
    if sym_v_ptr_t(sol_b^.sym)^.kind = 204 then
      flags := flags ! 16#8000;
  if (flags & 16#40) <> 0 then begin
    if sol_c <> nil then
      bug_check('LIR_$STORE_INSTRUCTION -- advancing_address_mode but B operand is not NIL%$');
    sol_c := sol_b;
    sz := lshft(1, instruction_attributes[opc].w18 & 7);
    adv := sol_b^.l28;
    save := adv;
    bits := bits + adv;
    adv := adv + sz;
    if (flags & 16#20) <> 0 then begin
      sol_b^.l28 := adv;
      lir_main_760.disp := sz;
      sol_b := addr(lir_main_760);
    end;
    if sol_c^.kind = 5 then
      sol_c := solution_ptr_t(sol_c^.l4);
  end
  else
    save := 0;
  begin_instruction(attrs, opc, flags, home, 0);
  if lir_2f58.h.b2_7 then begin
    d := save + disp;
    if d <> 0 then
      lir_2f58.h.b2_7 := alias_$add_disp(lir_2f40, d);
  end;
  lir_2f58.h.low_bits := bits & 7;
  if (flags & 16#8000) <> 0 then
    lir_2f58.h.b2_2 := true;
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol_a, a^.opnds[1]);
  if (flags & 16#200) = 0 then
    f := a^.opnds[2]
  else begin
    lir_4194.num := 2;
    f := lir_4194;
  end;
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol_b, f);
  lir_$build_operand(addr(lir_2f58.opnds[3]), sol_c, a^.opnds[3]);
  if (flags & 48) <> 0 then
    convert_to_intend_to_modify(univ_ptr(addr(lir_2f58.opnds[3])))
  else if (flags & 16#40) <> 0 then
    sol_b^.l28 := adv;
  lir_$complete_instruction(copy_build_instruction);
end;

{ LIR_$MTPR_INSTRUCTION - an MTPR (opcode 125), as the MFPR.

  0x247968, 0xC8 bytes. }

procedure lir_$mtpr_instruction(
    attrs: univ_ptr;
    opc: integer;
    flags: integer32;
    sol1: solution_ptr_t;
    sol2: solution_ptr_t;
    sol3: solution_ptr_t;
    home: univ_ptr);
var
  a: instr_attr_view_ptr_t;
begin
  a := addr(instruction_attributes[opc]);
  if opc <> 125 then
    bug_check('LIR_$MTPR_INSTRUCTION -- illegal opcode: %a%$',
              instruction_mnemonic[opc], 12);
  if home <> nil then
    flags := flags ! 16#2000;
  begin_instruction(attrs, opc, flags, home, 0);
  lir_$build_operand(addr(lir_2f58.opnds[1]), sol1, a^.opnds[1]);
  lir_$build_operand(addr(lir_2f58.opnds[2]), sol2, a^.opnds[2]);
  lir_$build_operand(addr(lir_2f58.opnds[3]), sol3, a^.opnds[3]);
  lir_$complete_instruction(copy_build_instruction);
end;

{ LIR_$BEGIN_FORTRAN_IO_SEQUENCE - the labels a FORTRAN I/O statement
  (kind 137 of call 67, at most 3 entries) may reach (its entries'
  label symbols: kind 110 of class 6 without +45 bit 4), their LABEL
  instructions' +3 bit 7 set, kept in lir_3b78 (lir_41c0 of them) for
  the call's hidden edges.

  0x247A5E, 0xBA bytes: a dbf loop over the entries. }

procedure lir_$begin_fortran_io_sequence(
    node_p: univ_ptr);
var
  node: il_$node_ptr_t;
  cnt: integer32;
  k: integer32;
  e: il_$node_ptr_t;
  lab: lir_label_ptr_t;
begin
  node := node_p;
  if not ((node^.kind = 137) and (node^.xw[18] = 67)
          and (node^.xw[19] <= 3)) then
    bug_check('LIR_$BEGIN_FORTRAN_IO_SEQUENCE -- bad argument.%$');
  cnt := 0;
  for k := 0 to node^.xw[19] - 2 do begin
    e := node^.xp[11 + k];
    if e <> nil then begin
      if (e^.kind <> 110) or (rshft(ord(e^.xc[44]) & 16#F0, 4) <> 6)
         or ((ord(e^.xc[45]) & 16#10) <> 0) then
        bug_check('LIR_$BEGIN_FORTRAN_IO_SEQUENCE -- unexpected symbol.%$');
      cnt := cnt + 1;
      lab := isc_$get_label(e^.xp[12]);
      lab^.instr^.h.modify := lab^.instr^.h.modify ! 2;
      lir_3b78[cnt] := lab;
    end;
  end;
  lir_41c0 := cnt;
end;

{ LIR_$BEGIN_CALL_OR_SVC - a CALL or SVC of opcode opc with nargs
  operands more than its own and two for each serialized register
  (lir_41f4), one for the exception information when the target asks
  (target_properties +0xC1), made with lir_3b80's attributes; its +36
  the previous call (lir_main_c60).

  0x247B80, 0x5C bytes: p2 not read. }

function lir_$begin_call_or_svc(
    opc: integer;
    p2: integer32;
    nargs: integer32): univ_ptr;
var
  i: instr_ptr_t;
begin
  begin_instruction(addr(lir_3b80), opc, 0, nil, 2 * lir_41f4 + nargs);
  if ord(target_properties.p_bf[2]) >= 128 then begin
    lir_2f58.h.nopnds := lir_2f58.h.nopnds + 1;
    lir_41a4.l := lir_41a4.l + 12;
  end;
  i := copy_build_instruction;
  i^.l36 := integer32(lir_main_c60);
  lir_$begin_call_or_svc := i;
end;

{ call_or_svc_argument_register - the solution of register reg of kind
  kind (0 integer: of$ip_reg, 1 floating: of$fp_reg, else a pair:
  of$fp_reg_pair) as the call's next operand (cnt counted up): a read's
  form lir_419c, a write's lir_4190, the register then taken out of the
  call's clobbered sets (regs: +8 the integer registers, +4 and +0 the
  floating ones 0..31 and 32..63).

  0x247BDC, 0x172 bytes, internal: the floating registers' sets are
  updated as the image does it, `regs.s4 := regs.s8 - [r2]' for 0..31
  and `regs.s0 := regs.s4 - [r2]' for 32..63 (r2 the pair's odd
  register): an eight-byte set difference stored from its second
  longword, the register's own bit computed and never used
  (docs/questions.md 350). }

function call_or_svc_argument_register(
    reg: integer32;
    kind: integer;
    is_read: boolean;
    var cnt: lir_count_t;
    var regs: lir_regs_t): solution_ptr_t; options(val_param, internal);
var
  sol: solution_ptr_t;
  f: integer;
  r2: integer32;
begin
  if kind = 0 then begin
    sol := lir_3e60[reg];
    f := 18;
  end
  else if kind = 1 then begin
    sol := lir_3d60[reg];
    f := 19;
  end
  else begin
    sol := lir_3c60[reg];
    f := 4;
  end;
  cnt.l := cnt.l + 1;
  if is_read then begin
    lir_419c.form := f;
    lir_419c.num := cnt.l & 255;
  end
  else begin
    lir_4190.form := f;
    lir_4190.num := cnt.l & 255;
    if kind = 0 then
      regs.s8 := regs.s8 - [reg & 31]
    else begin
      r2 := reg ! ord(kind = 2);
      if reg < 32 then
        regs.s4 := regs.s8 - [r2 & 31]
      else
        regs.s0 := regs.s4 - [r2 & 31];
    end;
  end;
  call_or_svc_argument_register := sol;
end;

{ add_serialized_lr_operands - for each register base + k (k in mask)
  of kind kind, a read and a write operand of instr (the serialized
  registers a call keeps live).

  0x247D4E, 0xAE bytes, internal. }

procedure add_serialized_lr_operands(
    instr: instr_ptr_t;
    mask: bv_word_t;
    kind: integer;
    base: integer32;
    var cnt: lir_count_t;
    var regs: lir_regs_t); options(val_param, internal);
var
  k: integer32;
  sol: solution_ptr_t;
begin
  for k := 0 to 31 do
    if (k & 31) in mask then begin
      sol := call_or_svc_argument_register(base + k, kind, true, cnt, regs);
      lir_$build_operand(addr(instr^.opnds[cnt.lo]), sol, lir_419c);
      sol := call_or_svc_argument_register(base + k, kind, false, cnt, regs);
      lir_$build_operand(addr(instr^.opnds[cnt.lo]), sol, lir_4190);
    end;
end;

{ LIR_$EMIT_CALL_OR_SVC - the call instr (lir_$begin_call_or_svc's) of
  the IL call node completed: its target and second operand, for a CALL
  its conventions (the pointer after the operands and the register sets
  before it: the clobbered registers, from the conventions when the
  call is serialized (+36 30, 31 or 32), else all but the preserved
  ones; the stack register kept; the floating registers counted at
  +41), the argument registers it reads (the input spine's kind 203
  locations), the result register (+36 31: +10 its kind, +11 its
  register, a pair's other half), the output spine's registers, the
  serialized registers (lir_41f4: lir_420c, lir_4204, lir_4208).

  0x247DFC, 0x42C bytes. }

procedure lir_$emit_call_or_svc(
    attrs: univ_ptr;
    call_p: univ_ptr;
    instr_p: univ_ptr;
    flags: integer32;
    target: solution_ptr_t;
    sol2: solution_ptr_t);
type
  props_ptr_t = ^call_conv_$ptr_t;
var
  call: il_$node_ptr_t;
  instr: instr_ptr_t;
  ser: boolean;
  regs: lir_regs_ptr_t;
  a: instr_attr_view_ptr_t;
  n: lir_count_t;
  conv: call_conv_$ptr_t;
  sp: bv_word_t;
  r: integer32;
  cntf: integer32;
  arg: il_$node_ptr_t;
  loc: il_$node_ptr_t;
  sol: solution_ptr_t;
  lr: lr_ptr_t;
  v: integer32;
begin
  call := call_p;
  instr := instr_p;
  lir_2f58.opc := instr^.opc;
  instr^.l32 := integer32(attrs);
  instr^.l28 := instr^.l28 ! flags;
  ser := (call^.xw[18] = 30) or (call^.xw[18] = 31) or (call^.xw[18] = 32);
  regs := addr(instr^.opnds[instr^.h.nopnds + 1]);
  a := addr(instruction_attributes[instr^.opc]);
  n.l := instruction_attributes[instr^.opc].nresults;
  if target^.kind = 5 then
    target := solution_ptr_t(target^.l4);
  lir_$build_operand(addr(instr^.opnds[1]), target, a^.opnds[1]);
  lir_$build_operand(addr(instr^.opnds[2]), sol2, a^.opnds[2]);
  if instr^.opc = ord(opc$call) then begin
    conv := univ_ptr(call^.xp[13]);
    props_ptr_t(addr(instr^.opnds[instr^.h.nopnds + 2]))^ := conv;
    instr^.h.lsq := (instr^.h.lsq & 2) ! ord(conv^.b29);
    if conv^.w24 = 1 then begin
      instr^.h.b3_1 := true;
      instr^.h.b3_0 := false;
    end
    else if conv^.w24 = 2 then begin
      instr^.h.b3_1 := false;
      instr^.h.b3_0 := true;
    end;
    sp := [conv^.w20 & 31];
    if ser then begin
      regs^.s0 := bv_word_t(conv^.fp_clobbered[0]);
      regs^.s4 := bv_word_t(conv^.fp_clobbered[1]);
      regs^.s8 := bv_word_t(conv^.ip_clobbered) - sp;
      if conv^.no_ip_cc_write then
        regs^.s8 := regs^.s8 - [30]
      else
        regs^.s8 := regs^.s8 + [30];
      if conv^.no_fp_cc_write then
        regs^.s8 := regs^.s8 - [31]
      else
        regs^.s8 := regs^.s8 + [31];
    end
    else begin
      v := 16#FFFFF;
      regs^.s0 := bv_word_t(v);
      v := 16#FFFFFF0F;
      regs^.s4 := bv_word_t(v);
      v := 16#C003FF;
      regs^.s8 := (bv_word_t(v) - sp) + [30, 31];
    end;
    lr := lir_pre_opnd_ptr_t(addr(instr^.opnds[2]))^.lr;
    regs^.s8 := regs^.s8 - [lr^.f2.reg & 31];
    cntf := 0;
    for r := 31 downto 0 do begin
      if r in regs^.s0 then
        cntf := cntf + 1;
      if r in regs^.s4 then
        cntf := cntf + 1;
    end;
    instr^.b41 := chr(cntf);
  end;
  if ser then begin
    arg := call^.xp[11];
    while arg <> nil do begin
      if arg^.kind <> 140 then
        bug_check('LIR_$EMIT_CALL_OR_SVC -- input spine has a non-assign_node.%$');
      loc := arg^.xp[16];
      if loc^.kind = 203 then begin
        sol := call_or_svc_argument_register(loc^.xw[3], loc^.xw[2], true, n,
                                             regs^);
        lir_$build_operand(addr(instr^.opnds[n.l]), sol, lir_419c);
      end;
      arg := arg^.xp[2];
    end;
  end;
  if call^.xw[18] = 31 then begin
    sol := call_or_svc_argument_register(ord(call^.xc[11]), ord(call^.xc[10]),
                                         false, n, regs^);
    lir_$build_operand(addr(instr^.opnds[n.l]), sol, lir_4190);
    if ord(call^.xc[10]) = 3 then begin
      sol := call_or_svc_argument_register(ord(call^.xc[11]) + 2,
                                           ord(call^.xc[10]), false, n, regs^);
      lir_$build_operand(addr(instr^.opnds[n.l]), sol, lir_4190);
    end;
  end;
  if ser then begin
    arg := call^.xp[12];
    while arg <> nil do begin
      loc := arg^.xp[17];
      if arg^.kind <> 140 then
        bug_check('LIR_$EMIT_CALL_OR_SVC -- output spine has a non-assign_node.%$');
      if loc^.kind = 203 then begin
        sol := call_or_svc_argument_register(loc^.xw[3], loc^.xw[2], false, n,
                                             regs^);
        lir_$build_operand(addr(instr^.opnds[n.l]), sol, lir_4190);
      end;
      arg := arg^.xp[2];
    end;
  end;
  if lir_41f4 > 0 then begin
    add_serialized_lr_operands(instr, regs^.s8 * bv_word_t(lir_420c), 0, 0, n,
                               regs^);
    add_serialized_lr_operands(instr, regs^.s4 * bv_word_t(lir_4204), 1, 0, n,
                               regs^);
    add_serialized_lr_operands(instr, regs^.s0 * bv_word_t(lir_4208), 1, 32, n,
                               regs^);
  end;
  lir_$complete_instruction(instr);
end;

{ LIR_$END_CALL_OR_SVC - the call's previous call (+36) made current
  again (lir_main_c60), lir_main_c58 cleared.

  0x2482A4, 0x2A bytes: p1 not read. }

procedure lir_$end_call_or_svc(
    p1: integer32;
    instr_p: univ_ptr);
var
  instr: instr_ptr_t;
begin
  instr := instr_p;
  lir_main_c60 := univ_ptr(instr^.l36);
  lir_main_c58 := nil;
  instr^.l36 := 0;
end;

{ LIR_$REINITIALIZE - the LIR's state for the routine rtn: lir_main's
  cells +0xC40..+0xD67 cleared, the instruction heap made the routine
  heap, the flags, the condition codes' (registers 30, 31), memory's
  and argument block's live ranges, the physical registers' tables;
  the entry block (made current) and the exit block; rtn's special
  live ranges (bb80 the exit block, the condition codes', the memory's,
  the argument block's); the frame register (the conventions' w20)
  kept, internal_db; lir_3b80 from the routine's statement; the
  physical registers (lir_main_$reinit_physical_regs); the literal
  pool's (target_properties +0x18/+0x1A) and the zero register's
  (+0x14/+0x16) segments; the live ranges of AP, the return address,
  LB, RPC, the frame (SF, its solution replacing the register's in
  lir_3e60, the old one kept in lir_41b0), DB and the w12 register; the
  registers the program declares (il_134's list) serialized; lir_4090's
  30 and 31 the condition codes'.

  0x2482CE, 0x6DC bytes: the declared registers' sets built in a frame
  longword (`bset' with the computed byte). }

procedure lir_$reinitialize(
    rtn: rtn_ptr_t);
type
  decl_list_ptr_t = ^decl_list_t;
  decl_list_t = record
    next: decl_list_ptr_t;              { +0 }
    decl: il_$node_ptr_t;               { +4 }
  end;
var
  m: lr_ptr_t;
  conv: call_conv_$ptr_t;
  node: il_$node_ptr_t;
  stmt: il_$node_ptr_t;
  lr: lr_ptr_t;
  r: integer32;
  p: decl_list_ptr_t;
  q: il_$node_ptr_t;
  e: il_$node_ptr_t;
  hi: integer;
  mask: ^bv_word_t;
  sol: solution_ptr_t;
  reg: integer32;
begin
  lir_41e0 := rtn;
  zero(addr(lir_main_c40), 16#128);
  lir_main_heap := addr(lir_ef0);
  lir_4228 := false;
  lir_4226 := false;
  lir_41fc := nil;
  lir_41e4 := 0;
  lir_41dc := nil;
  lir_4224 := false;
  m := addr(lir_3ba8);
  lir_41d8 := m;
  lir_41d4 := m;
  asm_658 := 0;
  lir_4220 := true;
  lir_421e := false;
  lir_421c := false;
  lir_41bc.l := 0;
  lir_41f4 := 0;
  lir_41b8 := 0;
  lir_4214 := 0;
  lir_4212 := 0;
  lir_4210 := 0;
  lir_422a := false;
  zero(addr(lir_de0), 88);
  zero(addr(lir_d88), 88);
  zero(addr(lir_3ba8), 88);
  zero(addr(lir_e38), 88);
  zero(addr(lir_3b80), 40);
  zero(addr(lir_4090), 256);
  zero(addr(lir_3f90), 256);
  zero(addr(lir_d08), 128);
  zero(addr(lir_c08), 256);
  lir_41a0 := 0;
  zero(addr(lir_f38), 16#2004);
  lir_d88.f2.physical := true;
  lir_d88.f2.reg := 30;
  lir_de0.f2.physical := true;
  lir_de0.f2.reg := 31;
  lir_4222 := true;
  lir_41f0 := get_basic_block;
  lir_41f0^.f14.kind := 1;
  lir_4222 := true;
  lir_41f8 := mrh_$alloc_fixed(lir_f20);
  lir_41f8^.f14.kind := 2;
  lir_41f8^.f14.path_to := 2;
  rtn^.bb80 := lir_41f8;
  rtn^.ip_cc_lr := addr(lir_d88);
  rtn^.fp_cc_lr := addr(lir_de0);
  rtn^.lr140 := m;
  rtn^.memory_lr := m;
  rtn^.argblock_lr := addr(lir_e38);
  lir_4218 := false;
  conv := rtn^.conv;
  rtn^.w208 := conv^.w20;
  conv^.ip76 := integer32(bv_word_t(conv^.ip76) + [conv^.w20 & 31]);
  node := rtn^.node;
  rtn^.f226.internal_db := ((ord(node^.xc[379]) & 16#40) = 0) and conv^.nested;
  zero(addr(lir_3b80), 40);
  stmt := node^.xp[25];
  lir_3b80.l4 := integer32(stmt^.xp[3]);
  lir_3b80.w34 := (ord(stmt^.xc[43]) * 256) ! ord(stmt^.xc[44]);
  lir_main_$reinit_physical_regs(rtn, conv, 0);
  lir_main_$reinit_physical_regs(rtn, conv, 1);
  lir_main_$reinit_physical_regs(rtn, conv, -1);
  lir_41a8 := 0;
  if target_properties.p_14[1] >= 0 then begin
    lir_41a8 := integer32(mrh_$alloc_fixed(lir_3c00));
    lr := lir_4090[target_properties.p_14[1] & 16#FFFF];
    lts_ptr_t(lir_41a8)^.rrp := [rrp$safe_base_address, rrp$ip_reg];
    lr^.rrp := lr^.rrp + [rrp$safe_base_address, rrp$ip_reg];
    lts_ptr_t(lir_41a8)^.lr := lr;
  end;
  lir_main_c48 := lts_ptr_t(lir_41a8);
  isc_user_routines_320 := nil;
  lir_4200 := 0;
  if target_properties.p_14[0] >= 0 then begin
    isc_user_routines_320 := lir_3e60[target_properties.p_14[0] & 16#FFFF];
    isc_user_routines_31c := isc_user_routines_320;
    lir_4200 := integer32(mrh_$alloc_fixed(lir_3c00));
    lts_ptr_t(lir_4200)^.lr := lir_4090[31];
    lts_ptr_t(lir_4200)^.rrp := [rrp$unique_value, rrp$ip_reg];
    lir_4090[30]^.rrp := lir_4090[30]^.rrp + [rrp$unique_value];
  end;
  lir_main_c4c := lir_4200;
  rtn^.ap_lr := lir_main_$add_live_range(isc_user_routines_33c, -1);
  rtn^.ap_lr^.memory_home := rtn^.ap_lr^.node20;
  node^.xp[12] := rtn^.ap_lr^.node20;
  rtn^.l124 := lir_main_$add_live_range(isc_user_routines_328, -1);
  rtn^.l124^.memory_home := rtn^.l124^.node20;
  node^.xp[16] := rtn^.l124^.node20;
  rtn^.l128 := lir_main_$add_live_range(isc_user_routines_334, -1);
  rtn^.l128^.memory_home := rtn^.l128^.node20;
  node^.xp[17] := rtn^.l128^.node20;
  rtn^.l112 := lts_ptr_t(lir_main_$add_live_range(lir_main_da0, -1));
  lr_ptr_t(rtn^.l112)^.memory_home := lr_ptr_t(rtn^.l112)^.node20;
  if lir_41b0 <> nil then begin
    r := lir_41b0^.f78.reg;
    lir_41b0^.lr := lir_4090[r];
    lir_41b0^.lr^.node20 := lir_main_ac0[r];
    lir_41b0^.node := lir_main_ac0[r];
    lir_3e60[r] := lir_41b0;
    lir_41b0 := nil;
  end;
  lir_420c := 0;
  lir_4208 := 0;
  lir_4204 := 0;
  p := univ_ptr(il_134);
  while p <> nil do begin
    q := p^.decl;
    e := node;
    while e <> nil do begin
      if q^.xp[5] = e then begin
        hi := q^.xw[28];
        reg := q^.xw[29];
        if hi = 0 then begin
          lr := lir_4090[reg];
          sol := lir_3e60[reg];
          mask := addr(lir_420c);
        end
        else begin
          lr := lir_3f90[reg];
          sol := lir_3d60[reg];
          if reg >= 32 then
            mask := addr(lir_4208)
          else
            mask := addr(lir_4204);
        end;
        if not lr^.f2.no_modify then begin
          lr^.f2.serialize := true;
          sol^.f78.serialize := true;
          mask^ := mask^ + [reg & 31];
          lir_41f4 := lir_41f4 + 1;
          lr^.node20 := q;
        end;
        if hi = 2 then
          if not lir_3f90[reg + 1]^.f2.no_modify then begin
            lir_3f90[reg + 1]^.f2.serialize := true;
            lir_3d60[reg + 1]^.f78.serialize := true;
            lir_3c60[reg]^.f78.serialize := true;
            mask^ := mask^ + [(reg + 1) & 31];
            lir_41f4 := lir_41f4 + 1;
          end;
        exit;
      end;
      e := e^.xp[2];
    end;
    p := p^.next;
  end;
  isc_user_routines_340^.node := lir_41ac;
  rtn^.frame_lr := lir_main_$add_ip_reg_physical_lr(isc_user_routines_340,
                                                    conv^.w20);
  lr := rtn^.frame_lr;
  node^.xp[14] := lr^.node20;
  isc_user_routines_340^.f78.no_modify := lr^.f2.no_modify;
  isc_user_routines_340^.f78.serialize := lr^.f2.serialize;
  isc_user_routines_340^.f78.reg := lr^.f2.reg;
  lir_41b0 := lir_3e60[conv^.w20];
  lir_3e60[conv^.w20] := isc_user_routines_340;
  if lir_4090[conv^.w16]^.f2.no_modify then
    lr := lir_main_$add_ip_reg_physical_lr(isc_user_routines_338, conv^.w16)
  else
    lr := lir_main_$add_live_range(isc_user_routines_338, -1);
  rtn^.db_lr := lr;
  node^.xp[13] := lr^.node20;
  isc_user_routines_338^.f78.physical := lr^.f2.physical;
  isc_user_routines_338^.f78.no_modify := lr^.f2.no_modify;
  if conv^.b30 then
    isc_user_routines_32c^.lr := isc_user_routines_33c^.lr
  else
    isc_user_routines_32c^.lr := lir_main_$add_live_range(isc_user_routines_32c, -1);
  rtn^.l120 := isc_user_routines_32c^.lr;
  node^.xp[15] := isc_user_routines_32c^.lr^.node20;
  lir_4090[30] := addr(lir_d88);
  lir_4090[31] := addr(lir_de0);
end;

{ LIR_$END_ROUTINE - the routine's map and heaps released (the segment
  and live range heaps to their marks).

  0x2489AA, 0xB6 bytes: the routine passed is the one kept (lir_41e0),
  not a parameter (at_backend passes none: pattern 132; the heading
  keeps rtn). }

procedure lir_$end_routine(
    rtn: rtn_ptr_t);
begin
  bv_$release_lr_map(lir_41e0);
  mrh_$release_to_mark(lir_3c00, lir_41b4);
  mrh_$release_to_mark(lir_ea8, lir_41c8);
  mrh_$release_to_mark(lir_e90, lir_41c4);
  mrh_$release_to_mark(lir_ed8, lir_41d0);
  mrh_$release_to_mark(lir_ec0, lir_41cc);
  mrh_$release_all(lir_f20);
  mrh_$release_all(lir_f08);
  mrh_$release_all(lir_ef0);
  mrh_$release_all(lir_3c48);
  mrh_$release_all(lir_3c30);
  mrh_$release_all(lir_3c18);
end;

{ LIR_$STRIP_MAY_GEN_EXCEPTION - utils_$strip_may_gen_exception of
  instr (for the units that open no utils.ins.pas).

  0x248A60, 0x1E bytes. }

procedure lir_$strip_may_gen_exception(
    instr: instr_ptr_t);
begin
  utils_$strip_may_gen_exception(instr);
end;
