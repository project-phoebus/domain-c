{ final - the m68k back end's final phase (cc.m68k only): the peephole
  optimizer over a routine's code cells (CELPKG's).  peepholer readies
  the cells (peepholer_init: the link's frame size, compares with 1,
  the label operands' reference cells), runs the optimizations
  (peepholer_ops) and then peepholer_cleanup (moveq for small moves,
  inline constants pooled at the end of each inner block, labels
  merged and cross-jumped, branches simplified: pcondjmp, puncondjmp,
  f_pcondjmp), again after instr_reorder, and puts nops before the
  68040's trapped instructions; finaldriver times jmp_br_resolve.  The
  helpers answer questions about the cells (registers used, killed or
  dead, the condition codes set and tested: cc_mod, cc_use, scancc,
  testcc; the same address: sameaddr) and edit them (detach, makejump,
  makecbr, moverefcell, movejump, reversecond, label_merge).

  TODO(pascal) final.pas is not finished: 99 of its 120 routines are
  translated.  Not yet translated (cc.m68k address, bytes):
    0x109BB6 0x8DA  final_$collapsed_index_calc
    0x10A492 0x7C4  final_$try_reducing_literal
    0x10C51C 0xB2   backov (in deltest)
    0x10C5CE 0x60C  deltest
    0x10CD7E 0x316  final_$redundant_lea
    0x10D28A 0x372  final_$cmp_branch_becomes_eor
    0x10D600 0x75A  opttest
    0x10DD5A 0x1DC  transform_ptr_in_d_use
    0x10DF52 0x7E2  optmove
    0x10E8EA 0x332  merge_add_sub
    0x10EF30 0x3BA  try_pre_dec
    0x10F30C 0x3B8  try_post_incr
    0x10F6C4 0x4C0  opta
    0x10FB84 0x3D4  floatop
    0x110CB4 0x242  try_loading_from_fp_reg (in peepholer_ops)
    0x110F14 0x21C  try_loading_monadic_src_here (in peepholer_ops)
    0x111130 0x322  try_long_extend_opts (in peepholer_ops)
    0x111452 0x214  try_reducing_fabs_op (in peepholer_ops)
    0x111666 0x1F0  try_removing_previous_clr (in peepholer_ops)
    0x111856 0xFA   try_widening_clr (in peepholer_ops)
    0x111950 0x638  peepholer_ops (in peepholer; an extern heading at
                    module level stands for it)
  peepholer_ops is the only caller of the others (opttest and optmove
  call some of them too), so nothing translated calls them.

  Image addresses (DOMAIN C 6.9; cc.m68k only: cc.a88k has no final):
    cc.m68k   cc.a88k
    0x10892C  --------  assert_is_lea
    0x10894C  --------  assert_modifies_object
    0x1089C4  --------  detref
    0x108A26  --------  final_$is_sole_label_consumer
    0x108A8C  --------  detach
    0x108B0E  --------  deltolab
    0x108B7C  --------  get_line
    0x108B9E  --------  prvcc
    0x108BEE  --------  nxtcc
    0x108C3E  --------  prvlcc
    0x108C88  --------  nxtlcc
    0x108CDA  --------  final_$in_15bit_range
    0x108CF4  --------  final_$sizeof
    0x108D94  --------  final_$is_call
    0x108DCA  --------  final_$is_branch
    0x108E12  --------  final_$is_call_or_branch
    0x108E40  --------  final_$sets_m881_codes_for_fp0
    0x108EB0  --------  assert_is_fp040_libname
    0x108F26  --------  final_$is_fp040_libcall
    0x108F9C  --------  assert_is_addr_con_ref
    0x108FBE  --------  assert_is_pic_routine_address_load
    0x109032  --------  assert_is_pic_fp040_libcall
    0x10905A  --------  final_$is_unmoveable_fp_inst
    0x1090B2  --------  final_$is_unmoveable_ftest
    0x109144  --------  has_untouchable_mem_attrs
    0x109170  --------  has_xcrement_addressing
    0x109188  --------  final_$is_int
    0x1091FE  --------  final_$is_int_load
    0x109304  --------  sameaddr
    0x1094E4  --------  final_$reg_is_simple_deferred
    0x10950E  --------  final_$reg_is_index
    0x109548  --------  involves
    0x10959E  --------  assert_is_direct_use_of_address_reg
    0x1095C8  --------  final_$reg_is_killed
    0x1096DA  --------  final_$fp_reg_is_killed
    0x1097DA  --------  final_$reg_is_used
    0x109874  --------  final_$reg_implicitly_used_by_inst
    0x109912  --------  final_$reg_is_dead_henceforth
    0x109A42  --------  adjacent_disps (in final_$contiguous_distinct_addresses)
    0x109A80  --------  final_$contiguous_distinct_addresses
    0x109BB6  --------  final_$collapsed_index_calc
    0x10A492  --------  final_$try_reducing_literal
    0x10AC58  --------  fpx_instruction
    0x10ACBC  --------  br_target
    0x10ACDA  --------  cc_change
    0x10AE26  --------  cc_use
    0x10AEC8  --------  scancc
    0x10AFD2  --------  testcc
    0x10B014  --------  label_merge
    0x10B12E  --------  setlabel
    0x10B17C  --------  lines_equiv
    0x10B22E  --------  makejump
    0x10B3DA  --------  makecbr
    0x10B466  --------  moverefcell
    0x10B4DC  --------  movejump
    0x10B514  --------  isbranch
    0x10B536  --------  eqlbitfield
    0x10B5D2  --------  crossjump
    0x10B7F8  --------  uncondjmpp
    0x10B810  --------  brimply
    0x10B890  --------  reversecond
    0x10B924  --------  change_br_value
    0x10B972  --------  pcondjmp
    0x10BBB2  --------  cc_mod
    0x10BCCC  --------  reg_mod
    0x10BD9E  --------  plab
    0x10BE5E  --------  correct_cc_set
    0x10BED4  --------  f_brimply
    0x10BF46  --------  f_pcondjmp
    0x10C0D2  --------  puncondjmp
    0x10C384  --------  assert_n_bit_is_modified
    0x10C3BA  --------  assert_bfextu_requires_test
    0x10C466  --------  bit_field_inst_which_obviates_test
    0x10C51C  --------  backov (in deltest)
    0x10C5CE  --------  deltest
    0x10CBDA  --------  opt_btst
    0x10CC98  --------  final_$redundant_compare
    0x10CD7E  --------  final_$redundant_lea
    0x10D094  --------  final_$redundant_movea
    0x10D174  --------  final_$unity_compare_and_branch
    0x10D28A  --------  final_$cmp_branch_becomes_eor
    0x10D600  --------  opttest
    0x10DD5A  --------  transform_ptr_in_d_use
    0x10DF52  --------  optmove
    0x10E734  --------  test_add_sub
    0x10E7EC  --------  is_stack_adjuster
    0x10E894  --------  final_$addr_adjust_value
    0x10E8EA  --------  merge_add_sub
    0x10EC22  --------  merge_move_sub
    0x10ECFA  --------  final_$merge_movea_adjust
    0x10EE1E  --------  merge_stack_adjusts
    0x10EF30  --------  try_pre_dec
    0x10F30C  --------  try_post_incr
    0x10F6C4  --------  opta
    0x10FB84  --------  floatop
    0x10FFA4  --------  final_$logicize_opts
    0x11010C  --------  final_$stack_is_altered
    0x11018A  --------  local_var_ref (in final_$local_var_refs)
    0x1101C0  --------  final_$local_var_refs
    0x11021E  --------  remove_sb_rel (in final_$remove_sb_rel)
    0x110252  --------  final_$remove_sb_rel
    0x11029A  --------  final_$try_to_suppress_stack_frame
    0x1103C0  --------  final_$link_opts
    0x1103D0  --------  backtrack (in final_$unlink_opts)
    0x110412  --------  final_$unlink_opts
    0x110584  --------  constcheck (in peepholer)
    0x110684  --------  fix_labeluse (in peepholer)
    0x110704  --------  peepholer_init (in peepholer)
    0x110982  --------  peepholer_cleanup (in peepholer)
    0x110CB4  --------  try_loading_from_fp_reg (in peepholer_ops)
    0x110F14  --------  try_loading_monadic_src_here (in peepholer_ops)
    0x111130  --------  try_long_extend_opts (in peepholer_ops)
    0x111452  --------  try_reducing_fabs_op (in peepholer_ops)
    0x111666  --------  try_removing_previous_clr (in peepholer_ops)
    0x111856  --------  try_widening_clr (in peepholer_ops)
    0x111950  --------  peepholer_ops (in peepholer)
    0x111FE4  --------  insert_integer_nop (in damn_the_040s_hide_anyway)
    0x112042  --------  damn_the_040s_hide_anyway (in peepholer)
    0x1120A0  --------  peepholer
    0x112116  --------  finaldriver
    A5 0x3566F8: the module's data (the last module's, to about
    +0x6AC), laid out as the variables below: +16 a descriptor, +28 the
    section, +32 scancc's chain, +36, +40 cc_change's set of codes, +42,
    +44 the change flag, then initialized tables (+0x30 the registers'
    bits, +0x88 the conditions' codes, +0xA8 and +0x250 brimply's and
    f_brimply's answers, +0x230 and +0x298 the complements); +0..+15,
    +36, +42, +0x60..+0x87 and the tables beyond +0x2A4 are used only by
    routines not yet translated.  Absolute: cargs's options
    (+0x280..+0x288), opinfo's tables (0x2CF4D8, 0x2CF5EC, 0x2CFDD8,
    0x2D01CE), cg_null_ads (0x356600), il_180.

  The code cells are read through codegen.ins.pas's codegen_$cell_t:
  the kind (+8), the operands' descriptors (ads1 +24, ads2 +36: f1 the
  addressing mode, f2 the register, 0..7 the data registers, 8..15 the
  address registers, 16.. the floating ones), the instruction (op,
  +48).  A label operand (mode 7) keeps its reference cell in the
  descriptor's y; the reference cell's owner is the label cell, whose
  refs list holds its references.  The kinds are tested as sets of
  0..47 or 0..63 (`btst' on constants after the routines;
  docs/dpc-gaps.md 8).

  Not known from the original: every name but the routines'; the
  module variables' names.
}
module final;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/pfm.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';

type
  { A routine's name (kind 159: its length at +8, its characters at
    +12) as assert_is_fp040_libname reads it: pas_$ctov of 61
    characters. }
  fn_chars_t = array [1..61] of char;
  fn_chars_ptr_t = ^fn_chars_t;

  { A section (il_10c's list) as far as final reads it: its head cell
    (+20). }
  fn_sect_ptr_t = ^fn_sect_t;
  fn_sect_t = record
    unused: array [0..4] of integer32;  { +0 }
    head: codegen_$cell_ptr_t;          { +20 }
  end;

  { A temporary label node (kind 144) as plab reads it: +41 set (a
    byte), a class in +72 bits 5..1. }
  fn_lnode_ptr_t = ^fn_lnode_t;
  fn_lnode_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..40] of char;    { +4 }
    b41: boolean;                       { +41 }
    unused_42: array [42..71] of char;  { +42 }
    x72: packed record
      hi: 0..3;                         { +72.7..6 }
      cls: 0..31;                       { +72.5..1 }
      lo: 0..1;                         { +72.0 }
    end;
  end;

  { An address descriptor's three longwords, as sameaddr compares two
    (`cmpm.l', `dbne' 2). }
  fn_ads_words_t = array [1..3] of integer32;

var
  { opinfo.pas's data (the unit without code; cc.m68k 0x2D01CE,
    absolute): each instruction's two operands' sizes ('B', 'W', 'L',
    'F', 'D', 'X'), indexed by the cell's +48. }
  opinfo_size: extern array [0..367] of packed array [1..2] of char;

  { opinfo.pas's data (cc.m68k 0x2CF5EC, 0x2CF4D8, absolute): each
    instruction's class for the condition codes, and each class's effect
    on the codes (0..5; 2 the code changed), cc_change's. }
  opinfo_cc_class: extern array [0..367] of integer;
  opinfo_cc: extern array [0..22] of array [0..5] of integer;

  { cg_tree.pas's empty operand (cc.m68k 0x356600, absolute; cg.ins.pas
    declares it, which final does not open). }
  cg_null_ads: extern codegen_$uads_t;

  { opinfo.pas's data (cc.m68k 0x2CFDD8, absolute): each instruction's
    two operands' access ('W' written), as instr_reorder.pas declares
    it. }
  opinfo_access: extern array [0..367] of packed array [1..2] of char;

  { The module's data (A5 0x3566F8). }
  fn_0: array [0..3] of integer32;      { +0 }
  fn_ads: codegen_$ads_t;               { +16 }
  fn_sect: fn_sect_ptr_t;               { +28: the section peepholer
                                          works on }
  fn_32: codegen_$cell_ptr_t;           { +32 }
  fn_36: codegen_$cell_ptr_t;           { +36 }
  fn_ccset: set of 0..15;               { +40: the condition codes
                                          cc_change asks about (0..5) }
  fn_42: char;                          { +42 }
  fn_changed: boolean;                  { +44: a cell was detached }
  fn_regmask: array [0..23] of 0..65535 := [
    1, 2, 4, 8, 16, 32, 64, 128,
    256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
    1, 2, 4, 8, 16, 32, 64, 128];       { +0x30: each register's bit in
                                          a movem's mask }
  fn_60: array [0..9] of integer32 := [
    255, 65535, 255, 65535, 1, 0, 3, 2, 1];  { +0x60: TODO(pascal) its
                                          users not translated yet }
  fn_cond_cc: array [0..15] of integer := [
    0, 0, 10, 10, 8, 8, 2, 2, 4, 4, 1, 1, 5, 5, 7, 7];  { +0x88: the
                                          codes each condition (T, F,
                                          HI, LS, CC, CS, NE, EQ, VC, VS,
                                          PL, MI, GE, LT, GT, LE) tests:
                                          1 N, 2 Z, 4 V, 8 C }
  fn_brimply: array [2..15] of array [2..15] of integer := [
    [2, 0, 1, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 2, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 2, 1, 1, 0, 2, 1, 0, 0, 0, 0, 0, 0, 2],
    [1, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2],
    [1, 0, 0, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2]];
                                        { +0xA8: brimply's answers by the
                                          two conditions (ops less 138);
                                          the entries .rwdi leaves unset
                                          given as 0 }
  fn_cbr_complement: array [140..153] of integer := [
    141, 140, 143, 142, 145, 144, 147, 146, 149, 148, 151, 150, 153,
    152];                               { +0x230: each condition's
                                          complement (pcondjmp) }
  fn_fbrimply: array [0..5] of array [0..5] of integer := [
    [2, 0, 1, 0, 0, 0],
    [0, 2, 1, 0, 0, 1],
    [1, 1, 2, 0, 1, 1],
    [1, 0, 0, 2, 0, 1],
    [1, 0, 1, 0, 2, 0],
    [1, 0, 0, 0, 0, 2]];                { +0x250: f_brimply's answers
                                          (ops less 436) }
  fn_fbr_complement: array [436..441] of integer := [
    437, 436, 439, 438, 441, 440];      { +0x298 }

  { celpkg.pas's empty descriptor (its +24, which the image copies from
    0x2CE68C): celpkg does not export it, so a copy here (as
    jmp_br_resolve.pas has). }
  fn_null_ads: codegen_$ads_t := [f1 := 0, f2 := 0, f3 := 0, f4 := 0,
      f5 := 0, f6 := 0, pad := 0, x := 0, y := 0];


{ DFETCH - v's low len bytes, sign-extended when sgn (kfold.pas; as
  cg_tree.pas declares it). }
function dfetch(
    v: integer32;
    len: integer;
    sgn: boolean): integer32; options(val_param); extern;


{ assert_is_lea - c is a lea (kind 4, op 12).

  0x10892C, 0x20 bytes, no frame: c at (4,SP). }

function assert_is_lea(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if c = nil then
    assert_is_lea := false
  else if c^.kind <> a_instyp then
    assert_is_lea := false
  else
    assert_is_lea := c^.op = 12;
end;

{ assert_modifies_object - c writes (its kind in a set of 0..63, its
  destination a mode other than 0) the storage that n's address points
  into (alias_$ind_for_captured_lvalue of the destination's x and of
  n).

  0x10894C, 0x70 bytes, no A5 load: the first result kept at -12. }

function assert_modifies_object(
    c: codegen_$cell_ptr_t;
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  t: il_$node_ptr_t;
begin
  if (c <> nil) and
     (c^.kind in [1..5, 7..8, 12, 14..15, 19, 42..43, 46..47, 52]) and
     (c^.ads2.f1 <> 0) and (n <> nil) and (c^.ads2.x <> 0) then begin
    t := alias_$ind_for_captured_lvalue(il_$node_ptr_t(c^.ads2.x));
    assert_modifies_object := alias_$ind_for_captured_lvalue(n) = t;
  end
  else
    assert_modifies_object := false;
end;

{ detref - descriptor a's reference cell (y) taken off its label's list
  (the label's refs moved on when it was the first, cleared when it was
  the only one).

  0x1089C4, 0x62 bytes, A5 loaded (global; detach its only caller): a
  by address. }

procedure detref(
    in a: codegen_$ads_t);
var
  r: codegen_$cell_ptr_t;
  first: codegen_$cell_ptr_t;
begin
  r := codegen_$cell_ptr_t(a.y);
  if r <> nil then begin
    first := r^.owner^.refs;
    if first = r then
      first := r^.next;
    delink(r);
    r^.next := nil;
    r^.prev := nil;
    if first = r then
      r^.owner^.refs := nil
    else
      r^.owner^.refs := first;
  end;
end;

{ final_$is_sole_label_consumer - an operand of c (a label, mode 7) is
  the only reference to label cell lab.

  0x108A26, 0x66 bytes, no A5 load. }

function final_$is_sole_label_consumer(
    c: codegen_$cell_ptr_t;
    lab: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  p: codegen_$cell_ptr_t;
begin
  r := false;
  if (c^.ads1.f1 = 7) and (c^.ads1.y <> 0) then begin
    p := codegen_$cell_ptr_t(c^.ads1.y);
    if (p^.owner = lab) and (p^.next = p) then
      r := true;
  end;
  if not r then
    if (c^.ads2.f1 = 7) and (c^.ads2.y <> 0) then begin
      p := codegen_$cell_ptr_t(c^.ads2.y);
      if (p^.owner = lab) and (p^.next = p) then
        r := true;
    end;
  final_$is_sole_label_consumer := r;
end;

{ detach - code cell c taken off its list: not a block's start or end
  (32, 33); a label (0) or a line (24) only delinked; an instruction's
  label operands' references removed (detref), its links cleared, the
  change flag (+44) set.

  0x108A8C, 0x82 bytes, A5 loaded. }

procedure detach;
begin
  if (c^.kind <> block_end_instyp) and (c^.kind <> block_start_instyp) then begin
    delink(c);
    if (c^.kind <> line_no_instyp) and (c^.kind <> def_lbl_instyp) then begin
      if c^.ads1.f1 = 7 then
        detref(c^.ads1);
      if c^.ads2.f1 = 7 then
        detref(c^.ads2);
      c^.next := nil;
      c^.prev := nil;
      fn_changed := true;
    end;
  end;
end;

{ deltolab - the cells from c up to the next label, case jump (30) or
  block end (33) of another block than a routine's (its node's kind
  not 172) detached, but for lines and block marks; the cell where it
  stopped.

  0x108B0E, 0x6E bytes, no A5 load (the flag at +44 set again after
  each detach). }

function deltolab(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  1;
var
  p: codegen_$cell_ptr_t;
  nx: codegen_$cell_ptr_t;
  k: integer;
begin
  p := c;
  while p^.kind <> def_lbl_instyp do begin
    k := p^.kind;
    if k = casejmp_instyp then
      goto 1;
    if k = block_end_instyp then
      if p^.blk^.kind <> 172 then
        goto 1;
    nx := p^.next;
    if not ((k = block_end_instyp) or (k = block_start_instyp) or
            (k = line_no_instyp)) then begin
      detach(p);
      fn_changed := true;
    end;
    p := nx;
  end;
1:
  deltolab := p;
end;

{ get_line - the line number cell (24) or block start (32) at or before
  c.

  0x108B7C, 0x22 bytes, no frame: c at (4,SP), the cell in A0. }

function get_line(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  p: codegen_$cell_ptr_t;
begin
  p := c;
  while not ((p^.kind = block_start_instyp) or (p^.kind = line_no_instyp)) do
    p := p^.prev;
  get_line := p;
end;

{ prvcc - the instruction before c: labels, lines and block marks
  passed (a set of 0..47); an empty list an internal error (3).

  0x108B9E, 0x4A bytes, no A5 load: the set at 0x108BE8 (nxtcc uses it
  too). }

function prvcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  p: codegen_$cell_ptr_t;
begin
  p := c^.prev;
  if p = c then
    cgerr_no_source(3, 0);
  while p^.kind in [0, 24, 32..33] do
    p := p^.prev;
  prvcc := p;
end;

{ nxtcc - the instruction after c (as prvcc).

  0x108BEE, 0x50 bytes, A5 loaded. }

function nxtcc;
var
  p: codegen_$cell_ptr_t;
begin
  p := c^.next;
  if p = c then
    cgerr_no_source(3, 0);
  while p^.kind in [0, 24, 32..33] do
    p := p^.next;
  nxtcc := p;
end;

{ prvlcc - the label or instruction before c: lines and block marks
  passed (24, 33, 32 compared in turn).

  0x108C3E, 0x4A bytes, no A5 load. }

function prvlcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  p: codegen_$cell_ptr_t;
begin
  p := c^.prev;
  if p = c then
    cgerr_no_source(3, 0);
  while (p^.kind = line_no_instyp) or (p^.kind = block_end_instyp) or
        (p^.kind = block_start_instyp) do
    p := p^.prev;
  prvlcc := p;
end;

{ nxtlcc - the label or instruction after c (as prvlcc).

  0x108C88, 0x52 bytes, A5 loaded. }

function nxtlcc;
var
  p: codegen_$cell_ptr_t;
begin
  p := c^.next;
  if p = c then
    cgerr_no_source(3, 0);
  while (p^.kind = line_no_instyp) or (p^.kind = block_end_instyp) or
        (p^.kind = block_start_instyp) do
    p := p^.next;
  nxtlcc := p;
end;

{ final_$in_15bit_range - v fits a signed word.

  0x108CDA, 0x1A bytes, no frame. }

function final_$in_15bit_range(
    v: integer32): boolean; options(val_param); internal;
begin
  final_$in_15bit_range := (v <= 32767) and (v >= -32768);
end;

{ final_$sizeof - the size in bytes of operand which (1 or 2) of c, from
  opinfo's size letters: B 1, W 2, L and F 4, D 8 (4 for an FPA
  instruction, kinds 54..58, a set of 0..63), X 12; anything else 0.

  0x108CF4, 0x98 bytes, no A5 load: the letters compared in turn. }

function final_$sizeof(
    c: codegen_$cell_ptr_t;
    which: integer): integer; options(val_param); internal;
var
  r: integer;
begin
  r := 0;
  if (which = 2) or (which = 1) then
    case opinfo_size[c^.op][which] of
      'B': r := 1;
      'W': r := 2;
      'L': r := 4;
      'F': r := 4;
      'D':
        if c^.kind in [54..58] then
          r := 4
        else
          r := 8;
      'X': r := 12;
      otherwise
        r := 0;
    end;
  final_$sizeof := r;
end;

{ final_$is_call - c is a call: a bsr (31), or a jsr or the like (kind
  16, ops 116, 117, 119, 118).

  0x108D94, 0x36 bytes, no frame. }

function final_$is_call(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if c^.kind = bsr_instyp then
    r := true
  else if c^.kind = dest1_instyp then
    if (c^.op = 116) or (c^.op = 117) or (c^.op = 119) or (c^.op = 118) then
      r := true;
  final_$is_call := r;
end;

{ final_$is_branch - c is a branch (17, 18, 22, 23, 29, 39: a set of
  0..47) or a jmp (kind 16, ops 123, 121).

  0x108DCA, 0x42 bytes, no A5 load. }

function final_$is_branch(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if c^.kind in [17..18, 22..23, 29, 39] then
    r := true
  else if c^.kind = dest1_instyp then
    if (c^.op = 123) or (c^.op = 121) then
      r := true;
  final_$is_branch := r;
end;

{ final_$is_call_or_branch - final_$is_call or final_$is_branch.

  0x108E12, 0x2E bytes, no A5 load. }

function final_$is_call_or_branch(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  final_$is_call_or_branch := final_$is_call(c) or final_$is_branch(c);
end;

{ final_$sets_m881_codes_for_fp0 - c writes FP0 (destination mode 13,
  register 16) and sets the 68881's condition codes: its op not 304..309
  (a set of 0..319; an op beyond the set counts as setting them, `sle').

  0x108E40, 0x48 bytes, no frame. }

function final_$sets_m881_codes_for_fp0(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if c = nil then
    final_$sets_m881_codes_for_fp0 := false
  else if (c^.ads2.f1 = 13) and (c^.ads2.f2 = 16) then
    final_$sets_m881_codes_for_fp0 := not (c^.op in [304..309])
  else
    final_$sets_m881_codes_for_fp0 := false;
end;

{ assert_is_fp040_libname - n is a routine's name (kind 159) of more
  than 7 characters beginning `fp040_$'.

  0x108EB0, 0x6C bytes, no A5 load: pas_$ctov of the 61 characters at
  +12, pas_$substr of 1 to 7, pas_$str_compare with the varying
  constant at 0x108F1C; the length compared unsigned (`bls'). }

function assert_is_fp040_libname(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_fp040_libname := false
  else if (n^.kind = 159) and (n^.xw[4] > 7) then
    assert_is_fp040_libname :=
        substr(fn_chars_ptr_t(addr(n^.xc[12]))^, 1, 7) = 'fp040_$'
  else
    assert_is_fp040_libname := false;
end;

{ final_$is_fp040_libcall - c calls an FP040 library routine: its
  target (the destination's x) a node 192 whose name (+8) begins
  fp040_$, or, without -ABS or -AC (flags_286 7, `btst #2' of +0x287),
  the target itself such a name.

  0x108F26, 0x76 bytes, A5 loaded (global; only final calls it). }

function final_$is_fp040_libcall(
    c: codegen_$cell_ptr_t): boolean; options(val_param);
var
  r: boolean;
  n: il_$node_ptr_t;
begin
  r := false;
  if final_$is_call(c) and (c^.ads2.x <> 0) then begin
    n := il_$node_ptr_t(c^.ads2.x);
    if (n^.kind = 192) and (n^.xp[2] <> nil) then
      if assert_is_fp040_libname(n^.xp[2]) then
        r := true;
    if not (7 in cargs_$options.flags_286) then
      if assert_is_fp040_libname(il_$node_ptr_t(c^.ads2.x)) then
        r := true;
  end;
  final_$is_fp040_libcall := r;
end;

{ assert_is_addr_con_ref - n is an address constant (195 or 163).

  0x108F9C, 0x22 bytes, no frame. }

function assert_is_addr_con_ref(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_addr_con_ref := false
  else
    assert_is_addr_con_ref := (n^.kind = 195) or (n^.kind = 163);
end;

{ assert_is_pic_routine_address_load - without -ABS or -AC, c loads A0
  (destination mode 1, register 8) with the address of an FP040 library
  routine (kind 4, op 5, the source an address constant whose +8 is
  such a name).

  0x108FBE, 0x74 bytes, no A5 load. }

function assert_is_pic_routine_address_load(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if not (7 in cargs_$options.flags_286) and (c <> nil) and
     (c^.kind = a_instyp) and (c^.op = 5) and
     assert_is_addr_con_ref(il_$node_ptr_t(c^.ads1.x)) and
     assert_is_fp040_libname(il_$node_ptr_t(c^.ads1.x)^.xp[2]) then
    assert_is_pic_routine_address_load :=
        (c^.ads2.f1 = 1) and (c^.ads2.f2 = 8)
  else
    assert_is_pic_routine_address_load := false;
end;

{ assert_is_pic_fp040_libcall - c loads an FP040 routine's address
  (assert_is_pic_routine_address_load) for the call after it.

  0x109032, 0x28 bytes, no A5 load. }

function assert_is_pic_fp040_libcall(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_pic_routine_address_load(c) then
    assert_is_pic_fp040_libcall := final_$is_fp040_libcall(nxtlcc(c))
  else
    assert_is_pic_fp040_libcall := false;
end;

{ final_$is_unmoveable_fp_inst - with -CPU MATHLIB (cpu 9, `btst #3' of
  +0x284), c sets the 68881's codes for FP0 and an FP040 library call
  (or the load of its address) follows.

  0x10905A, 0x58 bytes, A5 loaded. }

function final_$is_unmoveable_fp_inst;
begin
  if (9 in cargs_$options.cpu) and final_$sets_m881_codes_for_fp0(c) then
    final_$is_unmoveable_fp_inst := final_$is_fp040_libcall(nxtlcc(c)) or
        assert_is_pic_fp040_libcall(nxtlcc(c))
  else
    final_$is_unmoveable_fp_inst := false;
end;

{ final_$is_unmoveable_ftest - with -CPU MATHLIB, c is an ftst (op 298)
  of FP0 just before an FP040 library call that the cell before c is
  not, and that cell does not set the codes for FP0.

  0x1090B2, 0x92 bytes, no A5 load: the next and previous cells kept
  at -12 and -8. }

function final_$is_unmoveable_ftest(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  nx: codegen_$cell_ptr_t;
  pv: codegen_$cell_ptr_t;
begin
  r := false;
  if (9 in cargs_$options.cpu) and (c^.op = 298) and (c^.ads2.f1 = 13) and
     (c^.ads2.f2 = 16) then begin
    nx := nxtlcc(c);
    pv := prvlcc(c);
    if final_$is_fp040_libcall(nx) and not final_$is_fp040_libcall(pv) and
       not final_$sets_m881_codes_for_fp0(pv) then
      r := true;
  end;
  final_$is_unmoveable_ftest := r;
end;

{ has_untouchable_mem_attrs - a addresses memory (not modes 0, 1, 13:
  `btst' in #0x2003) with attributes +2 bits 6 or 4 (f5 & 5).

  0x109144, 0x2C bytes, no frame: a by address. }

function has_untouchable_mem_attrs(
    in a: codegen_$ads_t): boolean; internal;
begin
  if a.f1 in [0, 1, 13] then
    has_untouchable_mem_attrs := false
  else
    has_untouchable_mem_attrs := (a.f5 & 5) <> 0;
end;

{ has_xcrement_addressing - a is a postincrement or predecrement (modes
  8, 9: `btst' in #0x300).

  0x109170, 0x18 bytes, no frame. }

function has_xcrement_addressing(
    in a: codegen_$ads_t): boolean; internal;
begin
  has_xcrement_addressing := a.f1 in [8, 9];
end;

{ final_$is_int - a is the immediate (mode 3) integer constant v (its x
  a constant node, kinds 77..87, 101, 200: a set of 0..207).

  0x109188, 0x5C bytes, no A5 load: a by address. }

function final_$is_int(
    in a: codegen_$ads_t;
    v: integer32): boolean; options(val_param); internal;
var
  r: boolean;
  n: il_$node_ptr_t;
begin
  r := false;
  if (a.f1 = 3) and (a.x <> 0) then begin
    n := il_$node_ptr_t(a.x);
    if n^.kind in [77..87, 101, 200] then
      if n^.int_value = v then
        r := true;
  end;
  final_$is_int := r;
end;

{ final_$is_int_load - c loads the integer v into a data register
  (destination mode 1): a clr (kind 3, ops 9..11) or kind 19 op 125 for
  0, kind 19 op 124 for 255, a moveq (kind 2, op 3), kind 4 ops 4..5 or
  a move (kind 1, ops 0..2) of the immediate v.

  0x1091FE, 0x106 bytes, no A5 load: the op ranges compared unsigned
  (`bhi'). }

function final_$is_int_load(
    c: codegen_$cell_ptr_t;
    v: integer32): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if c^.ads2.f1 = 1 then
    if (v = 0) and (c^.kind = dest1_sz_instyp) and (c^.op in [9..11]) then
      r := true
    else if (v = 0) and (c^.kind = logicize_instyp) and (c^.op = 125) then
      r := true
    else if (v = 255) and (c^.kind = logicize_instyp) and (c^.op = 124) then
      r := true
    else if (c^.kind = moveq_instyp) and (c^.op = 3) and
            final_$is_int(c^.ads1, v) then
      r := true
    else if (c^.kind = a_instyp) and (c^.op in [4..5]) and
            final_$is_int(c^.ads1, v) then
      r := true
    else if (c^.kind = move_instyp) and (c^.op <= 2) and
            final_$is_int(c^.ads1, v) then
      r := true;
  final_$is_int_load := r;
end;

{ sameaddr - descriptors a and b address the same place: equal
  descriptors, or the same mode and attributes (f5) and, by the mode,
  the same register (1, 8, 9, 13), register and displacement (2),
  constant (3: the same node, or a node 184 and a node 157 whose +8 is
  it), register, index register, displacement and f4 (4, 6),
  displacement (5, 11), label (7: the reference cells' owners), node
  (12), register and index register (14), node and displacement (15);
  modes 0 and 10 always.

  0x109304, 0x1E0 bytes, A5 loaded: the descriptors compared as three
  longwords (`cmpm.l', `dbne'); a `case' of the mode through a table of
  16 (`bcc' over 16). }

function sameaddr;
var
  r: boolean;
  wa: ^fn_ads_words_t;
  wb: ^fn_ads_words_t;
  na: il_$node_ptr_t;
  nb: il_$node_ptr_t;
begin
  r := false;
  wa := addr(a);
  wb := addr(b);
  if (wa^[1] = wb^[1]) and (wa^[2] = wb^[2]) and (wa^[3] = wb^[3]) then
    r := true
  else if (a.f1 = b.f1) and (a.f5 = b.f5) and (a.f1 < 16) then
    case a.f1 of
      0, 10:
        r := true;
      1, 8, 9, 13:
        r := a.f2 = b.f2;
      2:
        r := (a.f2 = b.f2) and (a.y = b.y);
      3: begin
        na := il_$node_ptr_t(a.x);
        if na = il_$node_ptr_t(b.x) then
          r := true
        else if na^.kind = 184 then begin
          nb := il_$node_ptr_t(b.x);
          if nb^.kind = 157 then
            r := nb^.xp[2] = na;
        end
        else if na^.kind = 157 then begin
          nb := il_$node_ptr_t(b.x);
          if nb^.kind = 184 then
            r := na^.xp[2] = nb;
        end;
      end;
      4, 6:
        r := (a.f2 = b.f2) and (a.f3 = b.f3) and (a.y = b.y) and
             (a.f4 = b.f4);
      5, 11:
        r := a.y = b.y;
      7:
        if (a.y <> 0) and (b.y <> 0) then
          r := codegen_$cell_ptr_t(a.y)^.owner =
               codegen_$cell_ptr_t(b.y)^.owner;
      12:
        r := a.x = b.x;
      14:
        r := (a.f2 = b.f2) and (a.f3 = b.f3);
      15:
        r := (a.y = b.y) and (a.x = b.x);
    end;
  sameaddr := r;
end;

{ final_$reg_is_simple_deferred - a is register reg indirect (mode 2).

  0x1094E4, 0x2A bytes, no frame: a by address, reg a word. }

function final_$reg_is_simple_deferred(
    in a: codegen_$ads_t;
    reg: integer): boolean; options(val_param); internal;
begin
  if a.f1 = 2 then
    final_$reg_is_simple_deferred := a.f2 = reg
  else
    final_$reg_is_simple_deferred := false;
end;

{ final_$reg_is_index - a is indexed (modes 4, 6, 14: `btst' in
  #0x4050) by register reg (f3).

  0x10950E, 0x3A bytes, no A5 load. }

function final_$reg_is_index(
    in a: codegen_$ads_t;
    reg: integer): boolean; options(val_param); internal;
begin
  if a.f1 in [4, 6, 14] then
    final_$reg_is_index := a.f3 = reg
  else
    final_$reg_is_index := false;
end;

{ involves - a uses register reg: a mode with a register (not 0, 3, 5,
  7, 11, 12, 15: `btst' in #0x98A9) whose register or index register
  is reg.

  0x109548, 0x56 bytes, A5 loaded. }

function involves;
var
  r: boolean;
begin
  r := false;
  if not (a.f1 in [0, 3, 5, 7, 11, 12, 15]) then
    if a.f2 = reg then
      r := true
    else if final_$reg_is_index(a, reg) then
      r := true;
  involves := r;
end;

{ assert_is_direct_use_of_address_reg - a is an address register
  (mode 1, registers 8..15: `btst' in #0xFF00).

  0x10959E, 0x2A bytes, no frame. }

function assert_is_direct_use_of_address_reg(
    in a: codegen_$ads_t): boolean; internal;
begin
  if a.f1 = 1 then
    assert_is_direct_use_of_address_reg := a.f2 in [8..15]
  else
    assert_is_direct_use_of_address_reg := false;
end;

{ final_$reg_is_killed - c destroys register reg: its source a
  postincrement or predecrement of it (`btst' in #0x300), its
  destination involving it in modes 1, 8, 9, 14 (`btst' in #0x4302;
  not an instruction of kind 6, ops 102..104, on the register itself),
  a movem from memory (kind 26, ops 207, 206) of an immediate integer
  mask (node 81) with the register's bit (fn_regmask, +0x30), a bsr, a
  jsr (kind 16, op 119).

  0x1095C8, 0x112 bytes, no A5 load: the mask tested by `m$dis$lll'
  and bit 0 (odd); reg in 0..15 tested in #0xFFFF. }

function final_$reg_is_killed(
    c: codegen_$cell_ptr_t;
    reg: integer): boolean; options(val_param); internal;
var
  r: boolean;
  n: il_$node_ptr_t;
begin
  if involves(c^.ads1, reg) and (c^.ads1.f1 in [8, 9]) then
    r := true
  else if involves(c^.ads2, reg) and (c^.ads2.f1 in [1, 8, 9, 14]) and
          ((c^.ads2.f1 <> 1) or (c^.kind <> src2_sz_instyp) or
           not (c^.op in [102..104])) then
    r := true
  else begin
    n := il_$node_ptr_t(c^.ads2.x);
    if (c^.kind = moverm_instyp) and ((c^.op = 207) or (c^.op = 206)) and
       (c^.ads2.f1 = 3) and (n^.kind = 81) and (reg in [0..15]) and
       odd(n^.int_value div fn_regmask[reg]) then
      r := true
    else if c^.kind = bsr_instyp then
      r := true
    else if (c^.kind = dest1_instyp) and (c^.op = 119) then
      r := true
    else
      r := false;
  end;
  final_$reg_is_killed := r;
end;

{ final_$fp_reg_is_killed - c destroys floating register reg (16..23,
  `btst' in #0xFF0000): its destination the register (mode 13, `btst'
  in #0x2000), a floating movem (kind 51, or ops 358..363, a set of
  0..367) of an immediate integer mask with the register's bit, a bsr,
  a jsr.

  0x1096DA, 0xD2 bytes, no A5 load. }

function final_$fp_reg_is_killed(
    c: codegen_$cell_ptr_t;
    reg: integer): boolean; options(val_param); internal;
var
  r: boolean;
  n: il_$node_ptr_t;
begin
  if not (reg in [16..23]) then
    r := false
  else begin
    n := il_$node_ptr_t(c^.ads2.x);
    if involves(c^.ads2, reg) and (c^.ads2.f1 = 13) then
      r := true
    else if ((c^.kind = m881_moverm_instyp) or (c^.op in [358..363])) and
            (c^.ads2.f1 = 3) and (n^.kind = 81) and
            odd(n^.int_value div fn_regmask[reg]) then
      r := true
    else if c^.kind = bsr_instyp then
      r := true
    else if (c^.kind = dest1_instyp) and (c^.op = 119) then
      r := true
    else
      r := false;
  end;
  final_$fp_reg_is_killed := r;
end;

{ final_$reg_is_used - how c uses register reg: 1 its source, 2 its
  destination, 3 both; a use the register of modes 1, 2, 4, 6, 8, 9, 14
  (`btst' in #0x4356) or the index register of modes 4, 6, 14.

  0x1097DA, 0x9A bytes, no A5 load: a word in D0. }

function final_$reg_is_used(
    c: codegen_$cell_ptr_t;
    reg: integer): integer; options(val_param); internal;
var
  r: integer;
begin
  r := 0;
  if (c^.ads1.f1 in [1, 2, 4, 6, 8, 9, 14]) and (c^.ads1.f2 = reg) then
    r := 1
  else if (c^.ads1.f1 in [4, 6, 14]) and (c^.ads1.f3 = reg) then
    r := 1;
  if (c^.ads2.f1 in [1, 2, 4, 6, 8, 9, 14]) and (c^.ads2.f2 = reg) then
    r := r + 2
  else if (c^.ads2.f1 in [4, 6, 14]) and (c^.ads2.f3 = reg) then
    r := r + 2;
  final_$reg_is_used := r;
end;

{ final_$reg_implicitly_used_by_inst - c, an instruction (not a label,
  line or block mark), names register reg as its destination
  (final_$reg_is_used 2 or 3, `btst' in #12) and also reads it: its op
  not one that only writes (a set of 0..463; an op beyond it counts as
  reading, `sle').

  0x109874, 0x64 bytes, no A5 load: final_$reg_is_used called before
  c is tested for nil. }

function final_$reg_implicitly_used_by_inst(
    c: codegen_$cell_ptr_t;
    reg: integer): boolean; options(val_param); internal;
var
  u: integer;
begin
  u := final_$reg_is_used(c, reg);
  if (c <> nil) and not (c^.kind in [0, 24, 32..33]) and (u in [2, 3]) then
    final_$reg_implicitly_used_by_inst :=
        not (c^.op in [0..5, 9..11, 124..139, 206..207, 224..230, 448..453])
  else
    final_$reg_implicitly_used_by_inst := false;
end;

{ final_$reg_is_dead_henceforth - register reg's value is not needed
  after c: the cells from c on, until the section's head (fn_sect, +28)
  or an answer, lines and block marks passed (the answer false if the
  head is reached after them); a label or a branch (17, 18, 23, 29, 39:
  a set of 0..47) false; a call true for D0, D1, A0, A1 (`btst' in
  #0x303) unless it is an FP040 library call; ops 210..212 true but for
  D0 and A0 (#0x101); a use of the register false when it is read (its
  source not a postincrement or predecrement, or implicitly), else
  whether the instruction kills it.

  0x109912, 0x12A bytes, no A5 load: the iteration's done flag in D2
  (set at the loop's top), the answer in D4. }

function final_$reg_is_dead_henceforth(
    c: codegen_$cell_ptr_t;
    reg: integer): boolean; options(val_param); internal;
var
  p: codegen_$cell_ptr_t;
  k: integer;
  done: boolean;
  r: boolean;
begin
  p := c;
  repeat
    k := p^.kind;
    done := true;
    if (k = line_no_instyp) or (k = block_end_instyp) or
       (k = block_start_instyp) then begin
      r := false;
      p := p^.next;
      done := false;
    end
    else if k = def_lbl_instyp then
      r := false
    else if k in [17..18, 23, 29, 39] then
      r := false
    else if final_$is_call(p) then begin
      if final_$is_fp040_libcall(p) then
        r := false
      else if reg in [0, 1, 8, 9] then
        r := true
      else
        r := false;
    end
    else if (p^.op = 210) or (p^.op = 212) or (p^.op = 211) then
      r := not (reg in [0, 8])
    else if final_$reg_is_used(p, reg) <> 0 then begin
      if (final_$reg_is_used(p, reg) in [1, 3]) and
         not (p^.ads1.f1 in [8, 9]) then
        r := false
      else if final_$reg_implicitly_used_by_inst(p, reg) then
        r := false
      else
        r := final_$reg_is_killed(p, reg);
    end
    else begin
      p := p^.next;
      done := false;
    end;
  until done or (p = fn_sect^.head);
  final_$reg_is_dead_henceforth := r;
end;

{ final_$contiguous_distinct_addresses - descriptors a (la bytes) and
  b (lb bytes) address adjacent storage: the same mode and, by the
  mode, the same register (2), node (15) or nothing more (5), with
  displacements (y) that meet (adjacent_disps); the same register
  postincremented or predecremented (8, 9).  lo the lower of the two
  (a, or b when its displacement is the lower).

  0x109A80, 0x136 bytes, no A5 load: a `case' of the mode through a
  table of 14 from 2; adjacent_disps's result left in D0 as the
  routine's. }

function final_$contiguous_distinct_addresses(
    in a: codegen_$ads_t;
    la: integer;
    in b: codegen_$ads_t;
    lb: integer;
    out lo: codegen_$ads_t): boolean; options(val_param); internal;
var
  r: boolean;

  { adjacent_disps - a block of la bytes at da and one of lb at db meet.

    0x109A42, 0x3E bytes, no A5 load. }

  function adjacent_disps(
      da: integer32;
      la: integer32;
      db: integer32;
      lb: integer32): boolean; options(val_param);
  begin
    if da + la = db then
      adjacent_disps := true
    else
      adjacent_disps := db + lb = da;
  end;

begin
  r := false;
  if a.f1 = b.f1 then begin
    lo := a;
    case a.f1 of
      8, 9:
        r := a.f2 = b.f2;
      2: begin
        if a.f2 = b.f2 then
          r := adjacent_disps(a.y, la, b.y, lb);
        if a.y > b.y then
          lo := b;
      end;
      15: begin
        if a.x = b.x then
          r := adjacent_disps(a.y, la, b.y, lb);
        if a.y > b.y then
          lo := b;
      end;
      5: begin
        r := adjacent_disps(a.y, la, b.y, lb);
        if a.y > b.y then
          lo := b;
      end;
      otherwise
        ;
    end;
  end;
  final_$contiguous_distinct_addresses := r;
end;

{ fpx_instruction - c is an FPX instruction: kinds 41 and 44, and kinds
  40 (its source) and 42, 50 (its destination) whose operand is not an
  extended real ('X' in opinfo's sizes).

  0x10AC58, 0x64 bytes, no frame: a `case' of the kind through a table
  of 11 from 40. }

function fpx_instruction(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  case c^.kind of
    41, 44:
      r := true;
    40:
      r := opinfo_size[c^.op][1] <> 'X';
    42, 50:
      r := opinfo_size[c^.op][2] <> 'X';
    otherwise
      ;
  end;
  fpx_instruction := r;
end;

{ br_target - the instruction a branch c goes to: after its label (the
  owner of the destination's reference cell).

  0x10ACBC, 0x1E bytes, no A5 load: nxtcc's A0 returned. }

function br_target(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
begin
  br_target := nxtcc(codegen_$cell_ptr_t(c^.ads2.y)^.owner);
end;

{ cc_change - c changes one of the condition codes in fn_ccset (+40):
  its op's class (opinfo_cc_class) marks the code 2 in opinfo_cc; under
  -CPU FPX an FPX instruction's class is op 1's.  Codes 4 and 5 are
  asked about first.

  0x10ACDA, 0x14C bytes, no A5 load: the set's elements by `btst' of
  +41. }

function cc_change(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
label
  1;
var
  r: boolean;
  op: integer;
begin
  r := true;
  op := c^.op;
  if (4 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][4] = 2) then
    goto 1;
  if (5 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][5] = 2) then
    goto 1;
  if 5 in cargs_$options.cpu then
    if fpx_instruction(c) then
      op := 1;
  if (0 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][0] = 2) then
    goto 1;
  if (1 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][1] = 2) then
    goto 1;
  if (2 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][2] = 2) then
    goto 1;
  if (3 in fn_ccset) and (opinfo_cc[opinfo_cc_class[op]][3] = 2) then
    goto 1;
  r := false;
1:
  cc_change := r;
end;

{ cc_use - the condition codes c tests (fn_cond_cc, +0x88, by its
  condition): a conditional branch (18; ops 140..153 from 138, the
  others from 152), an scc (19, from 124), a dbcc (23, from 182); a
  floating branch or set (39, 43): 32 for ops 449, 448, 436, 437, else
  48; anything else 0.

  0x10AE26, 0xA2 bytes, no frame: the table indexed from A5 (`lea
  (0,A5,D1.w)' and +136, -112, -228). }

function cc_use(
    c: codegen_$cell_ptr_t): integer; options(val_param); internal;
var
  r: integer;
  base: integer;
begin
  case c^.kind of
    cbr_instyp: begin
      if c^.op in [140..153] then
        base := 138
      else
        base := 152;
      r := fn_cond_cc[c^.op - base];
    end;
    logicize_instyp:
      r := fn_cond_cc[c^.op - 124];
    dbcc_instyp:
      r := fn_cond_cc[c^.op - 182];
    fbr_instyp, m68881_set_byte_instyp:
      if (c^.op = 449) or (c^.op = 448) or (c^.op = 436) or (c^.op = 437) then
        r := 32
      else
        r := 48;
    otherwise
      r := 0;
  end;
  cc_use := r;
end;

function cc_mod(
    c: codegen_$cell_ptr_t): integer; options(val_param); internal; forward;

{ scancc - the condition codes in mask are tested from c on before
  they are set: each cell marked visited (+20, chained from fn_32, +32;
  a visited cell answers false); a use of them true; by what the cell
  does to them (cc_mod): 0 nothing (a bra followed, an rts false, a
  conditional branch both ways), 1 and 2 the integer codes or Z (mask
  & ~15, ~2) set and 3 the floating ones (~48), false when none is
  left, 4 all of them (false); the section's head true.

  0x10AEC8, 0x10A bytes, no A5 load: a `case' of cc_mod through a table
  of 5. }

function scancc(
    c: codegen_$cell_ptr_t;
    mask: integer): boolean; options(val_param); internal;
label
  1, 9;
var
  r: boolean;
begin
1:
  if c^.visit <> nil then begin
    r := false;
    goto 9;
  end;
  c^.visit := fn_32;
  fn_32 := c;
  while c <> fn_sect^.head do begin
    if (cc_use(c) & mask) <> 0 then begin
      r := true;
      goto 9;
    end;
    case cc_mod(c) of
      0:
        case c^.kind of
          br_instyp: begin
            c := br_target(c);
            goto 1;
          end;
          rts_instyp: begin
            r := false;
            goto 9;
          end;
          cbr_instyp, fbr_instyp: begin
            if scancc(nxtcc(c), mask) then begin
              r := true;
              goto 9;
            end;
            c := br_target(c);
            goto 1;
          end;
          otherwise
            c := nxtcc(c);
        end;
      1: begin
        if (mask & ~15) = 0 then begin
          r := false;
          goto 9;
        end;
        mask := mask & ~15;
        c := nxtcc(c);
      end;
      2: begin
        if (mask & ~2) = 0 then begin
          r := false;
          goto 9;
        end;
        mask := mask & ~2;
        c := nxtcc(c);
      end;
      3: begin
        if (mask & ~48) = 0 then begin
          r := false;
          goto 9;
        end;
        mask := mask & ~48;
        c := nxtcc(c);
      end;
      4: begin
        r := false;
        goto 9;
      end;
      otherwise
        ;
    end;
  end;
  r := true;
9:
  scancc := r;
end;

{ testcc - scancc from c, then the visited marks cleared.

  0x10AFD2, 0x42 bytes, A5 loaded: the chain's head (+32) cleared
  first. }

function testcc;
var
  r: boolean;
  p: codegen_$cell_ptr_t;
  q: codegen_$cell_ptr_t;
begin
  fn_32 := nil;
  r := scancc(c, mask);
  p := fn_32;
  while p <> nil do begin
    q := p^.visit;
    p^.visit := nil;
    p := q;
  end;
  testcc := r;
end;

{ label_merge - the labels after label cell lab (alignments passed)
  merged into it: their attributes (the destination's f5) or-ed into
  lab's, their references moved to lab (a temporary label node, 144, of
  a referring operand given lab's node, and its +80 lab when it was the
  merged label), their lists joined to lab's, the labels delinked.

  0x10B014, 0x11A bytes, no A5 load (the flag at +44 set when
  references move). }

procedure label_merge(
    lab: codegen_$cell_ptr_t); options(val_param); internal;
var
  l: codegen_$cell_ptr_t;
  r: codegen_$cell_ptr_t;
  first: codegen_$cell_ptr_t;
  c: codegen_$cell_ptr_t;
  n: il_$node_ptr_t;
begin
  l := nxtlcc(lab);
  while l^.kind = align_instyp do
    l := nxtlcc(l);
  while l^.kind = def_lbl_instyp do begin
    lab^.ads2.f5 := lab^.ads2.f5 ! l^.ads2.f5;
    r := l^.refs;
    if r <> nil then begin
      first := r;
      repeat
        c := codegen_$cell_ptr_t(r^.target);
        if (c^.ads1.f1 = 7) and (c^.ads1.x <> 0) then begin
          n := il_$node_ptr_t(c^.ads1.x);
          if n^.kind = 144 then begin
            if n^.xp[20] = il_$node_ptr_t(l) then
              n^.xp[20] := il_$node_ptr_t(lab);
            c^.ads1.x := lab^.ads2.x;
          end;
        end;
        c := codegen_$cell_ptr_t(r^.target);
        if (c^.ads2.f1 = 7) and (c^.ads2.x <> 0) then begin
          n := il_$node_ptr_t(c^.ads2.x);
          if n^.kind = 144 then begin
            if n^.xp[20] = il_$node_ptr_t(l) then
              n^.xp[20] := il_$node_ptr_t(lab);
            c^.ads2.x := lab^.ads2.x;
          end;
        end;
        r^.owner := lab;
        r := r^.next;
      until r = first;
      join(lab^.refs, r);
      fn_changed := true;
      l^.refs := nil;
    end;
    delink(l);
    l := nxtlcc(lab);
  end;
end;

{ setlabel - a label cell at c: c itself, the label before it, or a new
  label put before it (after the cell before it).

  0x10B12E, 0x4E bytes, no A5 load: the cell in A0. }

function setlabel(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  p: codegen_$cell_ptr_t;
  l: codegen_$cell_ptr_t;
begin
  if c^.kind = def_lbl_instyp then
    setlabel := c
  else begin
    p := prvlcc(c);
    if p^.kind = def_lbl_instyp then
      setlabel := p
    else begin
      l := getlabcell(nil);
      after(p, l);
      setlabel := l;
    end;
  end;
end;

{ lines_equiv - line number cell b's line, and the lines equivalent to
  it, entered on line number cell a's list of equivalent lines (6-byte
  elements from gspace: the next, the line), each once and not a's own
  line; b's list taken over.

  0x10B17C, 0xB2 bytes, no A5 load. }

procedure lines_equiv(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t); options(val_param); internal;
type
  line_ptr_t = ^line_t;
  line_t = record
    next: line_ptr_t;                   { +0 }
    line: integer;                      { +4 }
  end;
label
  1, 2;
var
  ln: integer;
  e: line_ptr_t;
  prev: line_ptr_t;
  nx: line_ptr_t;
  q: line_ptr_t;
begin
  if (a^.kind = line_no_instyp) and (b^.kind = line_no_instyp) then begin
    if b^.line <> a^.line then begin
      ln := b^.line;
      prev := nil;
      e := line_ptr_t(a^.blk);
      while e <> nil do begin
        if e^.line = ln then
          goto 1;
        prev := e;
        e := e^.next;
      end;
      e := gspace(6);
      e^.next := nil;
      e^.line := ln;
      if prev = nil then
        a^.blk := il_$node_ptr_t(e)
      else
        prev^.next := e;
    end;
    e := line_ptr_t(b^.blk);
    b^.blk := nil;
    while e <> nil do begin
      nx := e^.next;
      if e^.line <> a^.line then begin
        q := line_ptr_t(a^.blk);
        while q <> nil do begin
          if q^.line = e^.line then
            goto 2;
          q := q^.next;
        end;
      2:
        if q = nil then begin
          e^.next := line_ptr_t(a^.blk);
          a^.blk := il_$node_ptr_t(e);
        end;
      end;
      e := nx;
    end;
  end;
1:
end;

{ makejump - a bra to target put after c (fnl_slct op 21, size 5, its
  destination a label operand, mode 7, from cg_null_ads: the label
  setlabel gives target, a reference cell to it), then the cells after
  it up to a label, a case jump or the end of a block other than a
  routine's detached (but for lines and block marks); while they match
  the cells from target on kind for kind, their lines are entered as
  equivalent to target's (lines_equiv).  The cell where it stopped.

  0x10B22E, 0x1A6 bytes, A5 loaded: the change flag (+44) set first;
  the match flag in D2, the lines' flag in D3, the two line cells at
  -32 and -28; a set of 0..47 at 0x10B3D4 (the cells that end the
  matching of lines). }

function makejump;
label
  1;
var
  lab: codegen_$cell_ptr_t;
  u: codegen_$uads_t;
  j: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  t: codegen_$cell_ptr_t;
  nx: codegen_$cell_ptr_t;
  la: codegen_$cell_ptr_t;
  lb: codegen_$cell_ptr_t;
  k: integer;
  match: boolean;
  lines: boolean;
begin
  fn_changed := true;
  lab := setlabel(target);
  u := cg_null_ads;
  u.f1 := 7;
  j := fnl_slct(21, 5, 0, u, cg_null_ads);
  j^.ads2.y := integer32(getrefcell(integer32(j), lab));
  j^.ads2.x := lab^.ads2.x;
  after(c, j);
  p := j^.next;
  t := target;
  la := get_line(p);
  lb := get_line(t);
  lines := true;
  match := lines;
  while p^.kind = line_no_instyp do begin
    la := p;
    p := p^.next;
  end;
  while p^.kind <> def_lbl_instyp do begin
    k := p^.kind;
    if k = casejmp_instyp then
      goto 1;
    if k = block_end_instyp then
      if p^.blk^.kind <> 172 then
        goto 1;
    if lines and match then
      if not (k in [17..18, 22, 30, 32..34, 39]) then begin
        lines_equiv(lb, la);
        lines := false;
      end;
    nx := p^.next;
    if not ((p^.kind = block_end_instyp) or (p^.kind = block_start_instyp) or
            (p^.kind = line_no_instyp)) then begin
      if p = t then
        t := t^.prev;
      detach(p);
    end;
    p := nx;
    while p^.kind = line_no_instyp do begin
      la := p;
      p := p^.next;
      lines := true;
    end;
    if match then
      if not ((p^.kind = block_end_instyp) or
              (p^.kind = block_start_instyp)) then begin
        t := t^.next;
        while t^.kind in [0, 24, 32..33] do begin
          if t^.kind = line_no_instyp then begin
            lb := t;
            lines := true;
          end;
          t := t^.next;
        end;
      end;
    match := p^.kind = t^.kind;
  end;
1:
  makejump := p;
end;

{ makecbr - a conditional branch to target put after c (fnl_slct op
  20, size 5, x 2, its destination a label operand to the label setlabel
  gives target); the branch.

  0x10B3DA, 0x8C bytes, no A5 load (the flag at +44 set). }

function makecbr(
    c: codegen_$cell_ptr_t;
    target: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  lab: codegen_$cell_ptr_t;
  u: codegen_$uads_t;
  j: codegen_$cell_ptr_t;
begin
  fn_changed := true;
  lab := setlabel(target);
  u := cg_null_ads;
  u.f1 := 7;
  j := fnl_slct(20, 5, 2, u, cg_null_ads);
  j^.ads2.y := integer32(getrefcell(integer32(j), lab));
  j^.ads2.x := lab^.ads2.x;
  after(c, j);
  makecbr := j;
end;

{ moverefcell - reference cell ref moved from its label's list to that
  of the label setlabel gives lab (its first, or after the first).

  0x10B466, 0x76 bytes, A5 loaded (the flag at +44 set). }

procedure moverefcell;
var
  o: codegen_$cell_ptr_t;
  l: codegen_$cell_ptr_t;
begin
  fn_changed := true;
  o := ref^.owner;
  if o^.refs = ref then
    o^.refs := ref^.next;
  delink(ref);
  if o^.refs = ref then
    o^.refs := nil;
  l := setlabel(lab);
  ref^.owner := l;
  if l^.refs = nil then
    l^.refs := ref
  else
    after(l^.refs, ref);
end;

{ movejump - label operand a made to refer to b's label: a's reference
  cell moved (moverefcell) to the label of b's, b's node taken.

  0x10B4DC, 0x38 bytes, no A5 load: both by address; b's label kept at
  -8. }

procedure movejump(
    in out a: codegen_$ads_t;
    in b: codegen_$ads_t); internal;
var
  l: codegen_$cell_ptr_t;
begin
  l := codegen_$cell_ptr_t(b.y)^.owner;
  moverefcell(codegen_$cell_ptr_t(a.y), l);
  a.x := b.x;
end;

{ isbranch - c is a conditional branch, a bra or a floating branch (18,
  17, 39).

  0x10B514, 0x22 bytes, no frame. }

function isbranch(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  isbranch := (c^.kind = cbr_instyp) or (c^.kind = br_instyp) or
              (c^.kind = fbr_instyp);
end;

{ eqlbitfield - bit field nodes a and b are the same: of one kind; a
  140 the same +64, +54 and +56; a 138 the same node, or the same +36,
  the four longwords at +20 and the +38 pointers from +40; another kind
  the same node.

  0x10B536, 0x9C bytes, no A5 load: the longwords compared by `cmpm.l',
  `dbne' 3. }

function eqlbitfield(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); internal;
label
  1;
var
  r: boolean;
  i: integer;
begin
  r := false;
  if a^.kind = b^.kind then
    if a^.kind = 140 then begin
      if (a^.xp[16] = b^.xp[16]) and (a^.xw[27] = b^.xw[27]) and
         (a^.xw[28] = b^.xw[28]) then
        r := true;
    end
    else if a^.kind = 138 then begin
      if a = b then
        r := true
      else if (a^.xw[18] = b^.xw[18]) and (a^.xl[5] = b^.xl[5]) and
              (a^.xl[6] = b^.xl[6]) and (a^.xl[7] = b^.xl[7]) and
              (a^.xl[8] = b^.xl[8]) then begin
        r := true;
        for i := 1 to a^.xw[19] do
          if a^.xp[9 + i] <> b^.xp[9 + i] then begin
            r := false;
            goto 1;
          end;
      end;
    end
    else
      r := a = b;
1:
  eqlbitfield := r;
end;

function uncondjmpp(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal; forward;

{ crossjump - the code before a (to the label before it) and before b
  (instructions) is the same over at least two instructions: walking
  back from both while the kinds, ops, bit fields (eqlbitfield, kinds
  45..47 of ops 213..216) and operands (sameaddr) agree, stopping at a
  label or an unconditional jump before a; a pair of branches to
  different labels matching when they cross-jump themselves to the same
  places.  pa and pb where the common code starts (lines, kinds 27, 28
  passed); not when pb is b or the label just before it.  Only under
  -OPT's optimization 5 (`btst #6' of +0x283) and without -VARARGS
  (flags_286 5, bit 0 of +0x287).

  0x10B5D2, 0x226 bytes, no A5 load: recursive, the inner results at
  -12 and -8; the count in D3, b's side's start in D5. }

function crossjump(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t;
    out pa: codegen_$cell_ptr_t;
    out pb: codegen_$cell_ptr_t): boolean; options(val_param); internal;
label
  1, 9;
var
  r: boolean;
  x: codegen_$cell_ptr_t;
  y: codegen_$cell_ptr_t;
  sb: codegen_$cell_ptr_t;
  n: integer;
  xa: codegen_$cell_ptr_t;
  xb: codegen_$cell_ptr_t;
begin
  r := false;
  if not (5 in cargs_$options.opt_on) or (5 in cargs_$options.flags_286) then
    goto 9;
  x := prvlcc(a);
  if x^.kind = def_lbl_instyp then
    goto 9;
  sb := b;
  y := prvcc(b);
  n := 0;
  repeat
    if (x^.kind <> y^.kind) or (x^.op <> y^.op) then
      goto 1;
    case x^.kind of
      m020_dest2_instyp:
        if y^.op = 213 then
          if not eqlbitfield(il_$node_ptr_t(x^.ads2.x),
                             il_$node_ptr_t(y^.ads2.x)) then
            goto 1;
      m020_src2_instyp:
        if (y^.op = 214) or (y^.op = 215) then
          if not eqlbitfield(il_$node_ptr_t(x^.ads1.x),
                             il_$node_ptr_t(y^.ads1.x)) then
            goto 1;
      m020_dest1_instyp:
        if y^.op = 216 then
          if not eqlbitfield(il_$node_ptr_t(x^.ads2.x),
                             il_$node_ptr_t(y^.ads2.x)) then
            goto 1;
      otherwise
        ;
    end;
    if not sameaddr(x^.ads1, y^.ads1) then
      goto 1;
    if not sameaddr(x^.ads2, y^.ads2) then begin
      if (x^.ads2.f1 <> y^.ads2.f1) or (x^.ads2.f1 <> 7) then
        goto 1;
      if not ((y^.kind = br_instyp) or (y^.kind = dbcc_instyp) or
              (y^.kind = cbr_instyp)) then
        goto 1;
      if crossjump(x, y, xa, xb) then
        if br_target(y) = xb then
          if br_target(x) = nxtlcc(xa) then begin
            pa := xa;
            pb := xb;
            r := true;
            goto 9;
          end;
      goto 1;
    end;
    sb := y;
    x := prvlcc(x);
    n := n + 1;
    if x^.kind = def_lbl_instyp then
      goto 1;
    if uncondjmpp(x) then
      goto 1;
    y := prvcc(y);
  until false;
1:
  while (sb^.kind = fop_instyp) or (sb^.kind = inline_instyp) do
    sb := nxtlcc(sb);
  while x^.next^.kind = line_no_instyp do
    x := x^.next;
  y := nxtlcc(x);
  while (y^.kind = inline_instyp) or (y^.kind = fop_instyp) do begin
    x := y;
    y := nxtlcc(y);
  end;
  if sb = b then
    goto 9;
  if n < 2 then
    goto 9;
  if sb^.kind = def_lbl_instyp then
    if nxtcc(sb) = b then
      goto 9;
  pa := x;
  pb := sb;
  r := true;
9:
  crossjump := r;
end;

{ uncondjmpp - c is a case jump or a bra (30, 17).

  0x10B7F8, 0x18 bytes, no frame. }

function uncondjmpp;
begin
  uncondjmpp := (c^.kind = casejmp_instyp) or (c^.kind = br_instyp);
end;

{ brimply - what branch a's going implies about branch b's (fn_brimply,
  +0xA8, by the two conditions: the ops from 138, those beyond 153 less
  14 more): 2 when b is unconditional, 1 when a is or the kinds differ.

  0x10B810, 0x80 bytes, no A5 load: the table's row of 28 bytes. }

function brimply(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t): integer; options(val_param); internal;
var
  r: integer;
  i: integer;
  j: integer;
begin
  if uncondjmpp(b) then
    r := 2
  else begin
    r := 1;
    if not uncondjmpp(a) then
      if a^.kind = b^.kind then begin
        i := a^.op - 138;
        if i > 15 then
          i := i - 14;
        j := b^.op - 138;
        if j > 15 then
          j := j - 14;
        r := fn_brimply[i][j];
      end;
  end;
  brimply := r;
end;

{ reversecond - conditional branch, scc or dbcc c's condition reversed
  (op bit 0 flipped: ops 140..153, 154..167, 436..441, 124..139,
  448..453, 182..197); any other op an internal error (5).

  0x10B890, 0x94 bytes, A5 loaded: the ranges compared unsigned. }

procedure reversecond;
begin
  if (c^.op in [140..153]) or (c^.op in [154..167]) or
     (c^.op in [436..441]) or (c^.op in [124..139]) or
     (c^.op in [448..453]) or (c^.op in [182..197]) then
    c^.op := xor(c^.op, 1)
  else
    cgerr_no_source(5, 0);
end;

{ change_br_value - conditional branch op's signed condition for its
  unsigned one (140 144, 141 145, 150 148, 151 149); other ops as they
  are.

  0x10B924, 0x4E bytes, no frame: a `case' of op less 140 through a
  table of 12. }

function change_br_value(
    op: integer): integer; options(val_param); internal;
begin
  case op of
    140: change_br_value := 144;
    141: change_br_value := 145;
    150: change_br_value := 148;
    151: change_br_value := 149;
    otherwise
      change_br_value := op;
  end;
end;

{ pcondjmp - conditional branch c simplified; the cell after it (or
  after what it removed).  Not under -DBA (cargs's db 3: bits 16..15 of
  the longword at +0x282).  When it tests C or V (cc_use & 12) and the
  instruction that set the codes (before it, passing the classes 18
  and 0 of opinfo_cc_class, not a label) leaves C (V) clear (its
  opinfo_cc 3 (2) is 0), the condition becomes the signed one
  (change_br_value).  A branch to itself is left; one to the next
  instruction removed; one to a branch: by brimply 0 retargeted past
  it, 2 given its target (movejump); a conditional branch after it: by
  brimply 0 made a bra (kind 17, op 120) when its condition is c's
  complement (fn_cbr_complement, +0x230), 2 removed when it is the
  same; an unconditional jump after it to c's target's place: c
  reversed and given its target, the jump removed, or c removed when
  both go to one place.

  0x10B972, 0x240 bytes, no A5 load: the result in D4, the target in
  D3, brimply's answer in D2. }

function pcondjmp(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  1, 9;
var
  nx: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  t: codegen_$cell_ptr_t;
  q: codegen_$cell_ptr_t;
  u: integer;
  ok: boolean;
begin
  nx := nxtlcc(c);
  if cargs_$options.db = 3 then
    goto 9;
  p := prvlcc(c);
  u := cc_use(c);
  if (p^.kind <> def_lbl_instyp) and ((u & 12) <> 0) then begin
    ok := true;
    while (opinfo_cc_class[p^.op] = 18) or (opinfo_cc_class[p^.op] = 0) do begin
      p := prvlcc(p);
      if p^.kind = def_lbl_instyp then begin
        ok := false;
        goto 1;
      end;
    end;
    if ok then begin
      if ((u & 8) <> 0) and (opinfo_cc[opinfo_cc_class[p^.op]][3] = 0) then
        c^.op := change_br_value(c^.op);
      if ((u & 4) <> 0) and (opinfo_cc[opinfo_cc_class[p^.op]][2] = 0) then
        c^.op := change_br_value(c^.op);
    end;
  end;
1:
  t := br_target(c);
  if t = c then
    goto 9;
  if nxtcc(c) = t then begin
    detach(c);
    goto 9;
  end;
  if isbranch(t) and (br_target(t) <> t) then
    case brimply(c, t) of
      0:
        moverefcell(codegen_$cell_ptr_t(c^.ads2.y), nxtlcc(t));
      1:
        ;
      2: begin
        movejump(c^.ads2, t^.ads2);
        goto 9;
      end;
      otherwise
        ;
    end;
  q := nxtlcc(c);
  if q^.kind = cbr_instyp then
    case brimply(c, q) of
      0:
        if fn_cbr_complement[q^.op] = c^.op then begin
          q^.kind := br_instyp;
          q^.op := 120;
        end;
      2:
        if q^.op = c^.op then begin
          detach(q);
          q := nxtlcc(c);
          nx := q;
        end;
      otherwise
        ;
    end;
  if uncondjmpp(q) then
    if nxtcc(q) = t then begin
      reversecond(c);
      movejump(c^.ads2, q^.ads2);
      nx := nxtlcc(q);
      detach(q);
    end
    else if br_target(q) = t then
      detach(c);
9:
  pcondjmp := nx;
end;

{ cc_mod - what c does to the condition codes: 0 nothing, 1 sets the
  integer codes, 2 sets Z, 3 sets the floating codes, 4 clobbers them
  (an FPX instruction under -CPU FPX, a bsr, a jsr); by the kind (lea
  ops 105, 106 1, a move to an address register 0, kind 16's op 13 0
  and op 119 4).

  0x10BBB2, 0x11A bytes, no A5 load: a `case' of the kind through a
  table of 51. }

function cc_mod;
var
  r: integer;
begin
  if (5 in cargs_$options.cpu) and fpx_instruction(c) then
    r := 4
  else
    case c^.kind of
      a_instyp:
        if (c^.op = 105) or (c^.op = 106) then
          r := 1
        else
          r := 0;
      0, 17, 18, 19, 20, 21, 23, 24, 26, 28, 29, 30, 32, 33, 34, 39, 43:
        r := 0;
      q_instyp:
        if (c^.ads2.f1 = 1) and (c^.ads2.f2 >= 8) then
          r := 0
        else
          r := 1;
      i_w_instyp, dest2_instyp:
        r := 2;
      dest1_instyp:
        if c^.op = 13 then
          r := 0
        else if c^.op = 119 then
          r := 4
        else
          r := 1;
      bsr_instyp:
        r := 4;
      3, 6, 7, 9, 25, 45, 46, 47:
        r := 1;
      36, 37, 38, 40, 41, 42, 44, 48, 50:
        r := 3;
      otherwise
        r := 1;
    end;
  cc_mod := r;
end;

{ reg_mod - c changes register reg: a postincrement or predecrement of
  it, or it as a register operand (mode 1) that opinfo marks written
  ('W').

  0x10BCCC, 0xD2 bytes, no A5 load. }

function reg_mod(
    c: codegen_$cell_ptr_t;
    reg: integer): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if has_xcrement_addressing(c^.ads1) and (c^.ads1.f2 = reg) then
    r := true
  else if has_xcrement_addressing(c^.ads2) and (c^.ads2.f2 = reg) then
    r := true
  else if (c^.ads1.f1 = 1) and (opinfo_access[c^.op][1] = 'W') and
          (c^.ads1.f2 = reg) then
    r := true
  else if (c^.ads2.f1 = 1) and (opinfo_access[c^.op][2] = 'W') and
          (c^.ads2.f2 = reg) then
    r := true;
  reg_mod := r;
end;

{ plab - label cell c tidied (its node a temporary label, 144, not of
  class 13 (+72 bits 5..1) unless +41 is set): removed when nothing
  refers to it; else the labels after it merged into it (label_merge)
  and, under -OPT's optimization 5 without -VARARGS, each bra to it
  whose code before matches the code before the label cross-jumped
  (crossjump, makejump).  The cell after it.

  0x10BD9E, 0xC0 bytes, no A5 load: the references walked from the
  label's list (+32) until it comes round or empties, stopping when
  makejump removed the next one; the crossjump results at -24, -8. }

function plab(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  1, 9;
var
  nx: codegen_$cell_ptr_t;
  n: fn_lnode_ptr_t;
  r: codegen_$cell_ptr_t;
  r2: codegen_$cell_ptr_t;
  j: codegen_$cell_ptr_t;
  pa: codegen_$cell_ptr_t;
  pb: codegen_$cell_ptr_t;
begin
  nx := c^.next;
  n := fn_lnode_ptr_t(c^.ads2.x);
  if n = nil then
    goto 9;
  if n^.kind <> 144 then
    goto 9;
  if (n^.x72.cls = 13) and not n^.b41 then
    goto 9;
  if c^.refs = nil then begin
    detach(c);
    goto 9;
  end;
  label_merge(c);
  if not (5 in cargs_$options.opt_on) or (5 in cargs_$options.flags_286) then begin
    nx := c^.next;
    goto 9;
  end;
  r := c^.refs;
  repeat
    r2 := r^.next;
    j := codegen_$cell_ptr_t(r^.target);
    if j^.kind = br_instyp then
      if crossjump(j, c, pa, pb) then begin
        nx := makejump(pa, pb);
        if r2^.next = nil then
          goto 1;
      end;
    r := r2;
  until (r = c^.refs) or (c^.refs = nil);
1:
  nx := c^.next;
9:
  plab := nx;
end;

{ correct_cc_set - whether conditional branch c is taken when the codes
  are known (s: 1 N set, 2 Z set; C and V clear), by its condition
  (ops 140..153); another op answers N.

  0x10BE5E, 0x76 bytes, no A5 load: a `case' of op less 140 through a
  table of 14. }

function correct_cc_set(
    c: codegen_$cell_ptr_t;
    s: integer): boolean; options(val_param); internal;
var
  n: boolean;
  z: boolean;
  r: boolean;
begin
  n := (s & 1) <> 0;
  z := (s & 2) <> 0;
  r := n;
  case c^.op of
    140, 144: r := not z;
    141, 145: r := z;
    142, 146: r := true;
    143, 147: r := false;
    148, 150: r := not n;
    149, 151: r := n;
    152: r := not (n or z);
    153: r := n or z;
    otherwise
      ;
  end;
  correct_cc_set := r;
end;

{ f_brimply - brimply for floating branches (fn_fbrimply, +0x250, by
  the two ops less 436).

  0x10BED4, 0x72 bytes, no A5 load. }

function f_brimply(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t): integer; options(val_param); internal;
var
  r: integer;
begin
  if uncondjmpp(b) then
    r := 2
  else begin
    r := 1;
    if not uncondjmpp(a) then
      if a^.kind = b^.kind then
        r := fn_fbrimply[a^.op - 436][b^.op - 436];
  end;
  f_brimply := r;
end;

{ f_pcondjmp - pcondjmp for a floating branch c (kind 39, f_brimply,
  the complements fn_fbr_complement at +0x298 for ops 436..441).

  0x10BF46, 0x18C bytes, no A5 load. }

function f_pcondjmp(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  9;
var
  nx: codegen_$cell_ptr_t;
  t: codegen_$cell_ptr_t;
  q: codegen_$cell_ptr_t;
begin
  nx := nxtlcc(c);
  if cargs_$options.db = 3 then
    goto 9;
  t := br_target(c);
  if t = c then
    goto 9;
  if nxtcc(c) = t then begin
    detach(c);
    goto 9;
  end;
  if isbranch(t) and (br_target(t) <> t) then
    case f_brimply(c, t) of
      0:
        moverefcell(codegen_$cell_ptr_t(c^.ads2.y), nxtlcc(t));
      1:
        ;
      2: begin
        movejump(c^.ads2, t^.ads2);
        goto 9;
      end;
      otherwise
        ;
    end;
  q := nxtlcc(c);
  if q^.kind = fbr_instyp then
    case f_brimply(c, q) of
      0:
        if fn_fbr_complement[q^.op] = c^.op then begin
          q^.kind := br_instyp;
          q^.op := 120;
        end;
      2:
        if q^.op = c^.op then begin
          detach(q);
          q := nxtlcc(c);
          nx := q;
        end;
      otherwise
        ;
    end;
  if uncondjmpp(q) then
    if nxtcc(q) = t then begin
      if c^.op in [436..441] then begin
        c^.op := fn_fbr_complement[c^.op];
        movejump(c^.ads2, q^.ads2);
        nx := nxtlcc(q);
        detach(q);
      end;
    end
    else if br_target(q) = t then
      detach(c);
9:
  f_pcondjmp := nx;
end;

{ puncondjmp - unconditional jump c simplified; the cell after the
  dead code removed after it (deltolab).  Not under -DBA.  A bra to
  the next instruction removed; a jump to jumps retargeted along them
  (movejump) until one goes to itself or back to c; a bra to a
  conditional branch that skips the instruction after c becomes that
  branch reversed (to the instruction after the branch's target); a bra
  to a conditional branch whose codes the instruction before c sets
  from a constant (a moveq, clr or move of an immediate: the value by
  its op, dfetch of 1 or 2 bytes signed, an address constant 1) goes
  straight to where that branch goes (correct_cc_set); else, under
  -OPT's optimization 5 without -VARARGS, the other references to c's
  label cross-jumped (crossjump, makejump).

  0x10C0D2, 0x2B2 bytes, no A5 load: a `case' of the constant's op
  through a table of 12; the crossjump results at -20, -16. }

function puncondjmp(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  1, 2, 9;
var
  nx: codegen_$cell_ptr_t;
  t: codegen_$cell_ptr_t;
  q: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  r: codegen_$cell_ptr_t;
  first: codegen_$cell_ptr_t;
  j: codegen_$cell_ptr_t;
  pa: codegen_$cell_ptr_t;
  pb: codegen_$cell_ptr_t;
  n: il_$node_ptr_t;
  u: integer;
  v: integer32;
  s: integer;
begin
  nx := deltolab(c^.next);
  if cargs_$options.db = 3 then
    goto 9;
  t := br_target(c);
  if (c^.kind <> casejmp_instyp) and (nxtcc(c) = t) then begin
    detach(c);
    goto 9;
  end;
  while uncondjmpp(t) do begin
    if t = c then
      goto 9;
    if br_target(t) = t then
      goto 1;
    movejump(c^.ads2, t^.ads2);
    t := br_target(c);
  end;
1:
  if c^.kind = casejmp_instyp then
    goto 9;
  q := nxtcc(c);
  if (t^.kind = cbr_instyp) and (br_target(t) = q) then begin
    c^.kind := cbr_instyp;
    c^.op := t^.op;
    reversecond(c);
    moverefcell(codegen_$cell_ptr_t(c^.ads2.y), nxtlcc(t));
    nx := c;
    goto 9;
  end;
  p := prvlcc(c);
  if t^.kind = cbr_instyp then
    if (p^.kind = dest1_sz_instyp) or
       ((p^.ads1.f1 = 3) and ((p^.kind = move_instyp) or
        (p^.kind = i_instyp) or (p^.kind = moveq_instyp))) then begin
      u := cc_use(t);
      if ((u & 4) <> 0) and (opinfo_cc[opinfo_cc_class[p^.op]][2] <> 0) then
        goto 2;
      if ((u & 8) <> 0) and (opinfo_cc[opinfo_cc_class[p^.op]][3] <> 0) then
        goto 2;
      n := il_$node_ptr_t(p^.ads1.x);
      case p^.op of
        9, 10, 11:
          v := 0;
        0, 3:
          v := dfetch(n^.int_value, 1, true);
        1:
          v := dfetch(n^.int_value, 2, true);
        2:
          if (n^.kind = 163) or (n^.kind = 182) or (n^.kind = 195) or
             (n^.kind = 183) then
            v := 1
          else
            v := n^.int_value;
        otherwise
          goto 2;
      end;
      s := 0;
      if v < 0 then
        s := 1
      else if v = 0 then
        s := 2;
      if s <> 0 then begin
        if correct_cc_set(t, s) then
          q := br_target(t)
        else
          q := nxtcc(t);
        moverefcell(codegen_$cell_ptr_t(c^.ads2.y), q);
        nx := c;
        goto 9;
      end;
    end;
2:
  if (5 in cargs_$options.opt_on) and not (5 in cargs_$options.flags_286) then begin
    r := codegen_$cell_ptr_t(c^.ads2.y);
    q := r^.next;
    first := r^.owner^.refs;
    if first <> q then
      repeat
        j := codegen_$cell_ptr_t(q^.target);
        if j^.kind = c^.kind then
          if crossjump(c, j, pa, pb) then begin
            nx := makejump(pa, pb);
            goto 9;
          end;
        q := q^.next;
      until q = first;
  end;
9:
  puncondjmp := nx;
end;

{ assert_n_bit_is_modified - c's op's class does not leave N alone
  (opinfo_cc 0 not 1).

  0x10C384, 0x36 bytes, no frame. }

function assert_n_bit_is_modified(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if c = nil then
    assert_n_bit_is_modified := false
  else
    assert_n_bit_is_modified := opinfo_cc[opinfo_cc_class[c^.op]][0] <> 1;
end;

{ assert_bfextu_requires_test - the instructions after c up to the
  section's head scanned until one tests N (a branch or set, kinds 17,
  18, 19, 23, 29 in #0x208E0000, of an op in a set of 0..207), or is a
  label, call or branch, or changes N; the answer is true whatever
  ended the scan.

  0x10C3BA, 0x92 bytes, no A5 load: the scan's flag in D2, D0 set
  (`st') at the end. }

function assert_bfextu_requires_test(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
label
  1;
var
  p: codegen_$cell_ptr_t;
  done: boolean;
  k: integer;
begin
  p := nxtlcc(c);
  done := false;
  while p <> fn_sect^.head do begin
    k := p^.kind;
    if (k in [17, 18, 19, 23, 29]) and
       (p^.op in [120..123, 134..139, 148..153, 162..167, 176..181, 192..197]) then
      done := true
    else if k = def_lbl_instyp then
      done := true
    else if final_$is_call_or_branch(p) then
      done := true
    else
      done := assert_n_bit_is_modified(p);
    p := nxtlcc(p);
    if done then
      goto 1;
  end;
1:
  assert_bfextu_requires_test := true;
end;

{ bit_field_inst_which_obviates_test - bit field instruction c (kind 45,
  not op 214) on a field node (138) of 2 operands, or of 3 whose
  constant bounds (81) span no more than the bits of nx's source
  (final_$sizeof), sets the codes as the test nx would; a bfextu (op
  215) only when assert_bfextu_requires_test is false.

  0x10C466, 0xB6 bytes, no A5 load: the bounds' low words subtracted. }

function bit_field_inst_which_obviates_test(
    c: codegen_$cell_ptr_t;
    nx: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  n: il_$node_ptr_t;
  lo: il_$node_ptr_t;
  hi: il_$node_ptr_t;
  w: integer;
begin
  r := false;
  if (c^.kind = m020_src2_instyp) and
     ((c^.op = 215) or (c^.op <> 214)) and (c^.ads1.x <> 0) then begin
    n := il_$node_ptr_t(c^.ads1.x);
    if n^.kind = 138 then
      if n^.xw[19] = 2 then
        r := true
      else if (n^.xw[19] = 3) and (n^.xp[11] <> nil) then begin
        lo := n^.xp[11];
        if (lo^.kind = 81) and (n^.xp[12] <> nil) then begin
          hi := n^.xp[12];
          if hi^.kind = 81 then begin
            w := hi^.xw[5] - lo^.xw[5] + 1;
            if w <= final_$sizeof(nx, 1) * 8 then
              r := true;
          end;
        end;
      end;
  end;
  if r and (c^.op = 215) then
    r := not assert_bfextu_requires_test(nx);
  bit_field_inst_which_obviates_test := r;
end;

{ opt_btst - a btst c, a beq or bne (ops 145, 144) after it and the
  same btst again after that: the second removed when its op is the
  first's reflected (72 or 74 plus 77, less c's op), which c takes.  Not
  under -DBA or with untouchable memory.  The cell after c.

  0x10CBDA, 0xBE bytes, no A5 load. }

function opt_btst(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  9;
var
  b: codegen_$cell_ptr_t;
  c2: codegen_$cell_ptr_t;
  d: integer;
begin
  b := nxtlcc(c);
  if cargs_$options.db = 3 then
    goto 9;
  if has_untouchable_mem_attrs(c^.ads2) then
    goto 9;
  if b^.kind <> cbr_instyp then
    goto 9;
  c2 := nxtlcc(b);
  if (c2^.kind = c^.kind) and sameaddr(c^.ads1, c2^.ads1) and
     sameaddr(c^.ads2, c2^.ads2) then begin
    if b^.op = 145 then
      d := 72
    else if b^.op = 144 then
      d := 74
    else
      goto 9;
    d := d + 77 - c^.op;
    if c2^.op = d then begin
      c^.op := d;
      detach(c2);
    end;
  end;
9:
  opt_btst := b;
end;

{ final_$redundant_compare - compare c repeats the compare two cells
  before it (the same kind, op and operands, no untouchable memory, no
  postincrement or predecrement), with branches of one kind (18 or 39)
  after each.

  0x10CC98, 0xE6 bytes, no A5 load. }

function final_$redundant_compare(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  nx: codegen_$cell_ptr_t;
  pv: codegen_$cell_ptr_t;
  pv2: codegen_$cell_ptr_t;
begin
  r := false;
  if not has_untouchable_mem_attrs(c^.ads1) and
     not has_untouchable_mem_attrs(c^.ads2) and
     not has_xcrement_addressing(c^.ads1) and
     not has_xcrement_addressing(c^.ads2) then begin
    nx := nxtlcc(c);
    pv := prvlcc(c);
    pv2 := prvlcc(pv);
    if ((nx^.kind = fbr_instyp) or (nx^.kind = cbr_instyp)) and
       ((pv^.kind = fbr_instyp) or (pv^.kind = cbr_instyp)) and
       (pv^.kind = nx^.kind) and (pv2^.kind = c^.kind) and
       (pv2^.op = c^.op) and sameaddr(pv2^.ads1, c^.ads1) and
       sameaddr(pv2^.ads2, c^.ads2) then
      r := true;
  end;
  final_$redundant_compare := r;
end;

{ final_$redundant_movea - movea c (kind 4, op 5) of a label or node
  address (modes 12, 15: `btst' in #0x9000) is already done by an
  earlier identical movea, looking back past instructions that do not
  change its register or write its source, up to a label, a call or
  branch, or the section's head.

  0x10D094, 0xE0 bytes, no A5 load: the stop flag in D2, the answer in
  D3. }

function final_$redundant_movea(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  stop: boolean;
  p: codegen_$cell_ptr_t;
begin
  r := false;
  stop := false;
  p := c;
  if (c^.kind = a_instyp) and (c^.op = 5) and (c^.ads1.f1 in [12, 15]) then
    repeat
      p := prvlcc(p);
      if (p^.kind = a_instyp) and (p^.op = 5) and
         sameaddr(p^.ads1, c^.ads1) and sameaddr(p^.ads2, c^.ads2) then
        r := true
      else begin
        if (p^.kind = def_lbl_instyp) or final_$is_call_or_branch(p) or
           final_$reg_is_killed(p, c^.ads2.f2) then
          stop := true
        else
          stop := sameaddr(p^.ads2, c^.ads1);
      end;
      stop := stop or (p = fn_sect^.head);
    until stop or r;
  final_$redundant_movea := r;
end;

{ final_$unity_compare_and_branch - c compares a data register with
  itself (ops 102..104, mode 1, sameaddr), and the conditional branch
  after it (a condition in a set of 0..175) depends on nothing the
  compare leaves (testcc of the codes after the branch and at its
  target): the branch becomes a bra (17, op 121) when the condition
  holds for equal operands (a second set), else is removed.

  0x10D174, 0xEA bytes, no A5 load: the sets at 0x10D25E and
  0x10D274. }

function final_$unity_compare_and_branch(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  b: codegen_$cell_ptr_t;
begin
  r := false;
  b := nxtlcc(c);
  if (c^.op in [102..104]) and (c^.ads1.f1 = 1) and
     sameaddr(c^.ads1, c^.ads2) and (b^.kind = cbr_instyp) and
     (b^.op in [142..153, 156..167]) and not testcc(nxtlcc(b), 15) and
     not testcc(br_target(b), 15) then begin
    r := true;
    if b^.op in [142, 145..146, 148, 150, 153, 156, 159..160, 162, 164, 167] then begin
      b^.kind := br_instyp;
      b^.op := 121;
    end
    else
      detach(b);
  end;
  final_$unity_compare_and_branch := r;
end;

{ test_add_sub - c adds (ops 17..24: '+') or subtracts (28..35: '-') an
  immediate integer constant (kinds 8, 5, 4); ch the sign.

  0x10E734, 0xB8 bytes, no A5 load: a `case' of op less 17 through a
  table of 19 (25..27 neither); ch by address. }

function test_add_sub(
    c: codegen_$cell_ptr_t;
    out ch: char): boolean; options(val_param); internal;
var
  r: boolean;
  n: il_$node_ptr_t;
begin
  r := false;
  if ((c^.kind = i_instyp) or (c^.kind = q_instyp) or (c^.kind = a_instyp)) and
     (c^.ads1.f1 = 3) then begin
    n := il_$node_ptr_t(c^.ads1.x);
    if n^.kind in [77..87, 101, 200] then
      case c^.op of
      17, 18, 19, 20, 21, 22, 23, 24: begin
        ch := '+';
        r := true;
      end;
        28, 29, 30, 31, 32, 33, 34, 35: begin
          ch := '-';
          r := true;
        end;
        otherwise
          ;
      end;
  end;
  test_add_sub := r;
end;

{ is_stack_adjuster - c adjusts SP (its destination register 15): ops
  22..24, 31..33 (a set of 0..47), ops 17, 18, 35, 34 of an immediate,
  or a lea (op 12) from (SP).

  0x10E7EC, 0xA2 bytes, no A5 load. }

function is_stack_adjuster(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if (c^.ads2.f1 = 1) and (c^.ads2.f2 = 15) then
    if c^.op in [22..24, 31..33] then
      r := true
    else if ((c^.op = 17) or (c^.op = 18) or (c^.op = 35) or (c^.op = 34)) and
            (c^.ads1.f1 = 3) then
      r := true
    else if (c^.op = 12) and (c^.ads1.f1 = 2) and (c^.ads1.f2 = 15) then
      r := true;
  is_stack_adjuster := r;
end;

{ final_$addr_adjust_value - what stack adjuster c adds to SP: the
  constant for ops 17, 18, 22..24 (`btst' in #0x1C60000), its negation
  for 31..35 (a set of 0..47), a lea's displacement; else 0.

  0x10E894, 0x50 bytes, no frame. }

function final_$addr_adjust_value(
    c: codegen_$cell_ptr_t): integer32; options(val_param); internal;
begin
  if c^.op in [17, 18, 22, 23, 24] then
    final_$addr_adjust_value := il_$node_ptr_t(c^.ads1.x)^.int_value
  else if c^.op in [31..35] then
    final_$addr_adjust_value := -il_$node_ptr_t(c^.ads1.x)^.int_value
  else if c^.op = 12 then
    final_$addr_adjust_value := c^.ads1.y
  else
    final_$addr_adjust_value := 0;
end;

{ merge_move_sub - a move.l of an immediate to a data register (op 2)
  followed by a subtract of an immediate from it (c, op 33): the move
  given the difference (smcontk), c removed and replaced by the move.

  0x10EC22, 0xD8 bytes, no A5 load: c by address; the difference at -8;
  the answer is not read by its caller. }

function merge_move_sub(
    in out c: codegen_$cell_ptr_t): boolean; internal;
var
  r: boolean;
  s: codegen_$cell_ptr_t;
  m: codegen_$cell_ptr_t;
  v: integer32;
begin
  r := false;
  s := c;
  if (s^.op = 33) and (s^.ads2.f1 = 1) and (s^.ads2.f2 <= 7) and
     (s^.ads1.f1 = 3) then begin
    m := prvlcc(s);
    if (m^.op = 2) and (m^.ads2.f1 = 1) and (m^.ads2.f2 = s^.ads2.f2) and
       (m^.ads1.f1 = 3) then begin
      r := true;
      v := il_$node_ptr_t(m^.ads1.x)^.int_value -
           il_$node_ptr_t(s^.ads1.x)^.int_value;
      m^.ads1.x := integer32(smcontk(81, v));
      detach(c);
      c := m;
    end;
  end;
  merge_move_sub := r;
end;

{ final_$merge_movea_adjust - a movea between address registers (kind
  4, op 5) followed by an add or subtract quick (c, kind 5, ops 22..24,
  31..33) to its destination, the codes not tested after: c made a lea
  (kind 4, op 12) from the movea's source with the adjustment as its
  displacement (final_$addr_adjust_value), the movea removed.

  0x10ECFA, 0x124 bytes, no A5 load: the registers' tests in #0xFF00. }

function final_$merge_movea_adjust(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  p: codegen_$cell_ptr_t;
  v: integer32;
begin
  r := false;
  p := prvlcc(c);
  if (c^.kind = q_instyp) and (c^.op in [22..24, 31..33]) and
     (p^.kind = a_instyp) and (p^.op = 5) and (p^.ads1.f1 = 1) and
     (p^.ads1.f2 in [8..15]) and (c^.ads2.f1 = 1) and
     (c^.ads2.f2 in [8..15]) and sameaddr(c^.ads2, p^.ads2) and
     not testcc(nxtlcc(c), 15) then begin
    r := true;
    v := final_$addr_adjust_value(c);
    c^.kind := a_instyp;
    c^.op := 12;
    c^.ads1.f1 := 2;
    c^.ads1.f2 := p^.ads1.f2;
    c^.ads1.y := v;
    c^.size := ilength(c);
    detach(p);
  end;
  final_$merge_movea_adjust := r;
end;

{ merge_stack_adjusts - two stack adjusters in a row (c and the next)
  merged into c: both removed when they cancel (c then the cell before
  it), an addq or subq (kind 5, op 24 or 33) of up to 8, else a lea
  (kind 4, op 12) from (SP) of the sum's magnitude (as the image has
  it: the sign is lost); the second removed.

  0x10EE1E, 0x112 bytes, no A5 load: c by address; the magnitude
  compared unsigned (`bhi'). }

procedure merge_stack_adjusts(
    in out c: codegen_$cell_ptr_t); internal;
var
  n: codegen_$cell_ptr_t;
  pv: codegen_$cell_ptr_t;
  s: integer32;
  a: integer32;
begin
  n := nxtlcc(c);
  if n <> fn_sect^.head then
    if is_stack_adjuster(c) and is_stack_adjuster(n) then begin
      s := final_$addr_adjust_value(c);
      s := final_$addr_adjust_value(n) + s;
      if s = 0 then begin
        pv := prvlcc(c);
        detach(c);
        c := pv;
      end
      else begin
        a := s;
        if a < 0 then
          a := -a;
        if a <= 8 then begin
          c^.kind := q_instyp;
          c^.ads1.f1 := 3;
          if s < 0 then
            c^.op := 33
          else
            c^.op := 24;
          c^.ads1.x := integer32(smcontk(81, a));
        end
        else begin
          c^.kind := a_instyp;
          c^.op := 12;
          c^.ads1.f1 := 2;
          c^.ads1.f2 := 15;
          c^.ads1.y := a;
          c^.ads1.x := 0;
        end;
      end;
      detach(n);
    end;
end;

{ final_$logicize_opts - scc c (ops 124..139) followed by two
  instructions of ops 58 and 8 (not labels, lines or block marks)
  replaced by one instruction (kind 8, op 41) of the immediate 1 (f6 2)
  on the first's destination; or followed by an instruction of kind 3,
  op 61, on c's destination (no untouchable memory, the codes not
  tested after): that instruction removed and c's condition reversed.
  The cell after c.

  0x10FFA4, 0x168 bytes, no A5 load. }

function final_$logicize_opts(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
var
  n1: codegen_$cell_ptr_t;
  n2: codegen_$cell_ptr_t;
  k: codegen_$cell_ptr_t;
begin
  n1 := nxtlcc(c);
  n2 := nxtlcc(n1);
  if (c^.op in [124..139]) and not (n1^.kind in [0, 24, 32..33]) and
     (n1^.op = 58) and not (n2^.kind in [0, 24, 32..33]) and
     (n2^.op = 8) then begin
    k := getcodecell(i_instyp);
    k^.op := 41;
    k^.ads1.f1 := 3;
    k^.ads1.x := integer32(smcontk(81, 1));
    k^.ads1.f6 := 2;
    k^.ads2 := n1^.ads2;
    k^.size := ilength(k);
    detach(n1);
    detach(n2);
    after(c, k);
  end
  else if (n1^.kind = dest1_sz_instyp) and (n1^.op = 61) and
          sameaddr(c^.ads2, n1^.ads2) and
          not has_untouchable_mem_attrs(c^.ads2) and
          not testcc(nxtcc(c), 15) then begin
    detach(n1);
    reversecond(c);
  end;
  final_$logicize_opts := c^.next;
end;

{ final_$stack_is_altered - between link c and its unlk (21) the code
  calls, uses op 13, or changes SP (15) or A6 (14).

  0x11010C, 0x7E bytes, no A5 load: the flag's complement and-ed with
  the head test, then the unlk tested. }

function final_$stack_is_altered(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  p: codegen_$cell_ptr_t;
begin
  r := false;
  p := nxtlcc(c);
  while (not r and (p <> fn_sect^.head)) and (p^.kind <> unlk_instyp) do
    if final_$is_call(p) or (p^.op = 13) or final_$reg_is_killed(p, 15) or
       final_$reg_is_killed(p, 14) then
      r := true
    else
      p := nxtlcc(p);
  final_$stack_is_altered := r;
end;

{ final_$local_var_refs - between link c and its unlk the code refers to
  a local (an operand through A6 at a displacement not above 0).

  0x1101C0, 0x5E bytes, no A5 load: both operands tested (the first's
  answer kept at -12 and or-ed). }

function final_$local_var_refs(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
label
  9;
var
  r: boolean;
  p: codegen_$cell_ptr_t;
  b: boolean;

  { local_var_ref - a is A6-relative at a displacement not above 0.

    0x11018A, 0x36 bytes, no A5 load. }

  function local_var_ref(
      in a: codegen_$ads_t): boolean;
  var
    r: boolean;
  begin
    r := false;
    if involves(a, 14) and (a.y <= 0) then
      r := true;
    local_var_ref := r;
  end;

begin
  r := true;
  p := nxtlcc(c);
  while p^.kind <> unlk_instyp do begin
    if final_$reg_is_used(p, 14) <> 0 then begin
      b := local_var_ref(p^.ads1);
      if b or local_var_ref(p^.ads2) then
        goto 9;
    end;
    p := nxtlcc(p);
  end;
  r := false;
9:
  final_$local_var_refs := r;
end;

{ final_$remove_sb_rel - between link c and its unlk, the operands
  through A6 made SP-relative (register 15, the displacement less 4).

  0x110252, 0x48 bytes, no A5 load. }

procedure final_$remove_sb_rel(
    c: codegen_$cell_ptr_t); options(val_param); internal;
var
  p: codegen_$cell_ptr_t;

  { remove_sb_rel - a through A6 made through SP, 4 lower.

    0x11021E, 0x34 bytes, no A5 load. }

  procedure remove_sb_rel(
      in out a: codegen_$ads_t);
  begin
    if involves(a, 14) then begin
      a.f2 := 15;
      a.y := a.y - 4;
    end;
  end;

begin
  p := nxtlcc(c);
  while p^.kind <> unlk_instyp do begin
    if final_$reg_is_used(p, 14) <> 0 then begin
      remove_sb_rel(p^.ads1);
      remove_sb_rel(p^.ads2);
    end;
    p := nxtlcc(p);
  end;
end;

{ final_$try_to_suppress_stack_frame - under -OPT's optimization 29
  (`btst #6' of +0x280), link c and its unlk removed when nothing
  between them changes the stack or refers to a local: A6-relative
  operands made SP-relative, the routine's block (il_180) no longer
  marked as having a frame (+378 bit 4 cleared) and its parameters'
  offsets 4 lower (a node 110's +12, a node 109's +56; the parameters
  from the table at +12 when +377 bits 6..4 are 2, else found by name
  on the block's chain at +16 from the list at +12).  The cell after the
  unlk (c's next when nothing changes).

  0x11029A, 0x126 bytes, no A5 load: the count of parameters the byte
  at +293. }

function final_$try_to_suppress_stack_frame(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
type
  parm_t = record
    n: il_$node_ptr_t;                  { +0 }
    x: integer32;                       { +4 }
    y: integer32;                       { +8 }
  end;
  parm_tab_ptr_t = ^parm_tab_t;
  parm_tab_t = array [0..255] of parm_t;
label
  1;
var
  nx: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  rtn: il_$node_ptr_t;
  l: il_$node_ptr_t;
  n: il_$node_ptr_t;
  v: il_$node_ptr_t;
  i: integer;
begin
  p := c^.next;
  nx := p;
  if (29 in cargs_$options.opt_on) and not final_$stack_is_altered(c) and
     not final_$local_var_refs(c) then begin
    final_$remove_sb_rel(c);
    detach(c);
    while p^.kind <> unlk_instyp do
      p := nxtlcc(p);
    nx := p^.next;
    detach(p);
    rtn := il_180;
    rtn^.xc[378] := chr(ord(rtn^.xc[378]) & 16#EF);
    l := nil;
    if rshft(ord(rtn^.xc[377]) & 112, 4) <> 2 then
      l := rtn^.xp[3];
    for i := 1 to ord(rtn^.xc[293]) do begin
      if rshft(ord(il_180^.xc[377]) & 112, 4) = 2 then
        v := parm_tab_ptr_t(il_180^.xp[3])^[i].n
      else begin
        n := il_180^.xp[4];
        v := nil;
        while n <> nil do begin
          if (n^.kind = 109) and (n^.xp[1] = l^.xp[2]) then begin
            v := n;
            goto 1;
          end;
          n := n^.xp[4];
        end;
      1:
        l := l^.xp[1];
      end;
      if v <> nil then
        if v^.kind = 110 then
          v^.xl[3] := v^.xl[3] - 4
        else if v^.kind = 109 then
          v^.xl[14] := v^.xl[14] - 4;
    end;
  end;
  final_$try_to_suppress_stack_frame := nx;
end;

{ final_$link_opts - link c: final_$try_to_suppress_stack_frame.

  0x1103C0, 0x10 bytes, no A5 load: its A0 returned. }

function final_$link_opts(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
begin
  final_$link_opts := final_$try_to_suppress_stack_frame(c);
end;

{ final_$unlink_opts - before unlk c, back to a label (and from the
  bra's to it: backtrack), instructions that only adjust SP removed (a
  lea from (SP), ops 24, 23, 17, 18, writing SP); stopping at branches,
  calls (ops 13, 119, 123), the end of an inner block, and any other use
  of SP.  The cell after c.

  0x110412, 0x172 bytes, no A5 load: a `case' of the kind through a
  table of 40; SP's tests in #0x409 (modes 0, 3, 10 do not use it). }

function final_$unlink_opts(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); internal;
label
  1, 9;
var
  nx: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  q: codegen_$cell_ptr_t;
  op: integer;
  m: integer;
  reg: integer;

  { backtrack - from each bra (17) to label lab, final_$unlink_opts.

    0x1103D0, 0x42 bytes, no A5 load. }

  procedure backtrack(
      lab: codegen_$cell_ptr_t); options(val_param);
  var
    r: codegen_$cell_ptr_t;
    first: codegen_$cell_ptr_t;
    j: codegen_$cell_ptr_t;
  begin
    r := lab^.refs;
    if r <> nil then begin
      first := r;
      repeat
        j := codegen_$cell_ptr_t(r^.target);
        r := r^.next;
        if j^.kind = br_instyp then
          j := final_$unlink_opts(j);
      until r = first;
    end;
  end;

begin
  nx := c^.next;
  p := prvlcc(c);
  repeat
    case p^.kind of
      0:
        backtrack(p);
      32, 33:
        if p^.blk^.kind <> 172 then
          goto 9;
      17, 18, 23, 27, 29, 30, 31, 39:
        goto 9;
      24, 28:
        ;
      otherwise begin
        op := p^.op;
        if (op = 13) or (op = 119) or (op = 123) then
          goto 9;
        m := p^.ads1.f1;
        reg := p^.ads1.f2;
        if ((op = 12) and (m = 2) and (reg = 15)) or (op = 24) or
           (op = 23) or (op = 17) or (op = 18) then
          if (p^.ads2.f1 = 1) and (p^.ads2.f2 = 15) then begin
            q := p^.next;
            detach(p);
            p := q;
            goto 1;
          end;
        if not (m in [0, 3, 10]) and (reg = 15) then
          goto 9;
        if not (p^.ads2.f1 in [0, 3, 10]) and (p^.ads2.f2 = 15) then
          goto 9;
      end;
    end;
  1:
    p := p^.prev;
  until p = fn_sect^.head;
9:
  final_$unlink_opts := nx;
end;

{ TODO(pascal) peepholer_ops (0x111950, 0x638 bytes) and the six
  routines nested in it (try_loading_from_fp_reg 0x110CB4,
  try_loading_monadic_src_here 0x110F14, try_long_extend_opts
  0x111130, try_reducing_fabs_op 0x111452, try_removing_previous_clr
  0x111666, try_widening_clr 0x111856) are not translated yet: in the
  image peepholer_ops is nested in peepholer (it runs on peepholer's
  frame: its first cell, +12), declared here at module level until it
  is written. }

procedure peepholer_ops; extern;

{ DOBANSHEEFPX - the FPX instructions of a routine's code cells, from
  first to the section's head, scheduled (banshee.pas 0x0EE84C, not
  translated: a pointer by address and one by value, read off its
  frame). }

procedure dobansheefpx(
    first: univ_ptr;
    head: codegen_$cell_ptr_t); options(val_param); extern;

{ peepholer - the peephole pass over a routine's code cells in section
  sect from first: peepholer_init; under -OPT's optimization 27 (`btst
  #4' of +0x280) peepholer_ops; peepholer_cleanup; under optimization
  14 (bit 7 of +0x282) instr_reorder and those two again; then
  damn_the_040s_hide_anyway and dobansheefpx.

  0x1120A0, 0x76 bytes, A5 loaded: the section kept at +28 (fn_sect).
  Its frame holds what the nested routines share: -4 the link's frame
  size (peepholer_init), -8 and -12 a branch's reference cell and label
  (peepholer_cleanup), -20 and -24 the inline constants of sizes a
  multiple of 4 and the others (constcheck). }

procedure peepholer;
var
  size: integer32;
  ref: codegen_$cell_ptr_t;
  lab: codegen_$cell_ptr_t;
  consts4: codegen_$cell_ptr_t;
  consts2: codegen_$cell_ptr_t;

  { constcheck - an immediate operand a of a constant (f6 3) not yet in
    the section's pool made an inline constant: a code cell (kind 28,
    op 506) holding the operand, on consts4 or consts2 by its length,
    and a node 184 (12 bytes from gspace: the section, the cell) that
    the constant's +8 and a's x then point to; a constant already
    pooled in this section reused.

    0x110584, 0xFE bytes, no A5 load: peepholer's frame in A1. }

  procedure constcheck(
      in out a: codegen_$ads_t);
  var
    n: il_$node_ptr_t;
    m: il_$node_ptr_t;
    k: codegen_$cell_ptr_t;
  begin
    if (a.f1 = 3) and (a.f6 = 3) then begin
      n := il_$node_ptr_t(a.x);
      if n^.kind <> 184 then
        if (n^.xp[2] <> nil) and (n^.xp[2]^.xp[1] = il_$node_ptr_t(fn_sect)) then
          a.x := integer32(n^.xp[2])
        else begin
          k := getcodecell(inline_instyp);
          k^.op := 506;
          k^.ads2 := a;
          k^.size := ilength(k);
          m := gspace(12);
          m^.kind := 184;
          m^.xp[1] := il_$node_ptr_t(fn_sect);
          m^.xp[2] := il_$node_ptr_t(k);
          n^.xp[2] := m;
          a.x := integer32(m);
          if (k^.size & 3) = 0 then
            if consts4 = nil then
              consts4 := k
            else
              after(consts4, k)
          else if consts2 = nil then
            consts2 := k
          else
            after(consts2, k);
        end;
    end;
  end;

  { fix_labeluse - a label operand a (mode 7) of cell c given its label
    cell (the temporary label's +80, made by fnl_slct op 32 the first
    time, +72 bit 7 then cleared) and a reference cell from c.

    0x110684, 0x80 bytes, no A5 load: c by address. }

  procedure fix_labeluse(
      in out a: codegen_$ads_t;
      in c: codegen_$cell_ptr_t);
  var
    n: il_$node_ptr_t;
    u: codegen_$uads_t;
  begin
    if a.f1 = 7 then begin
      n := il_$node_ptr_t(a.x);
      if n^.xp[20] = nil then begin
        unpack_ads(a, u);
        n^.xp[20] := il_$node_ptr_t(fnl_slct(32, 5, 0, u, cg_null_ads));
        n^.xc[72] := chr(ord(n^.xc[72]) & 16#7F);
      end;
      a.y := integer32(getrefcell(integer32(c), codegen_$cell_ptr_t(n^.xp[20])));
    end;
  end;

  { peepholer_init - the cells made ready: a link's frame size an
    integer constant (the routine's +112, less its +176 with -CPU M020),
    a link.l (op 204, 6 bytes) when it is below -32768 under -CPU M020,
    else a word; a compare (kind 8, ops 107..109) of 1 or -1 before a
    conditional branch made a subtract (kind 3, op + 6) with the branch's
    condition shifted (142 144, 143 145, 150 152, 151 153; for -1, 152
    148, 153 149); other instructions' label operands set up
    (fix_labeluse), and a move.b of a constant to -(SP) (op 0, mode 9,
    SP) made a move.w (op 1, f6 1) of it shifted left 8.

    0x110704, 0x27E bytes, no A5 load: peepholer's frame by its dynamic
    link; the cell kept at -8 for fix_labeluse; a `case' of the branch's
    op less 142 through a table of 10. }

  procedure peepholer_init;
  label
    1;
  var
    p: codegen_$cell_ptr_t;
    q: codegen_$cell_ptr_t;
    c: codegen_$cell_ptr_t;
    n: il_$node_ptr_t;
    v: integer32;
  begin
    p := first;
    while p <> fn_sect^.head do begin
      case p^.kind of
        link_instyp: begin
          n := il_$node_ptr_t(p^.ads2.x);
          if 3 in cargs_$options.cpu then
            size := n^.xl[28] - n^.xl[44]
          else
            size := n^.xl[28];
          p^.ads2.x := integer32(smcontk(81, size));
          p^.ads2.f1 := 3;
          if (3 in cargs_$options.cpu) and (size < -32768) then begin
            p^.ads2.f6 := 2;
            p^.op := 204;
            p^.size := 6;
          end
          else
            p^.ads2.f6 := 1;
        end;
        block_end_instyp, block_start_instyp, line_no_instyp, def_lbl_instyp:
          ;
        i_instyp: begin
          q := nxtlcc(p);
          if (p^.op in [107..109]) and (q^.kind = cbr_instyp) then begin
            v := il_$node_ptr_t(p^.ads1.x)^.int_value;
            if v = 1 then
              case q^.op of
                142: q^.op := 144;
                143: q^.op := 145;
                150: q^.op := 152;
                151: q^.op := 153;
                otherwise
                  goto 1;
              end
            else if v = -1 then
              if q^.op = 152 then
                q^.op := 148
              else if q^.op = 153 then
                q^.op := 149
              else
                goto 1
            else
              goto 1;
            p^.op := p^.op + 6;
            p^.kind := dest1_sz_instyp;
          end;
        end;
        otherwise begin
          c := p;
          fix_labeluse(p^.ads1, c);
          p := c;
          fix_labeluse(p^.ads2, c);
          p := c;
          if (p^.op = 0) and (p^.ads1.f1 = 3) then begin
            n := il_$node_ptr_t(p^.ads1.x);
            if (n^.kind in [77..87, 101, 200]) and
               ((n^.int_value & 255) <> 255) and (p^.ads2.f1 = 9) and
               (p^.ads2.f2 = 15) then begin
              p^.op := 1;
              p^.ads1.f6 := 1;
              p^.ads1.x := integer32(smcontk(81, lshft(n^.int_value, 8)));
            end;
          end;
        end;
      end;
    1:
      p := p^.next;
    end;
  end;

  { peepholer_cleanup - the cells' lengths and locations set (the
    labels' +12 the location; plab on each label): a move of a byte
    constant to a data register made a moveq (kind 2, op 3), immediate
    operands pooled (constcheck, not for FPX instructions under -CPU
    FPX); under -DBA nothing more but for block marks and lines;
    otherwise the inline constants put after the end of each inner
    block (the others first, then, under -ALIGN after an alignment
    cell, the multiples of 4), and the branches simplified (pcondjmp,
    puncondjmp, f_pcondjmp) after, under -ALIGN, an alignment cell put
    before a label up to 256 bytes back that has none.

    0x110982, 0x32A bytes, no A5 load: peepholer's frame by its dynamic
    link; the location in D2; a set of 0..47 at 0x110CAC (the cells
    that are not instructions). }

  procedure peepholer_cleanup;
  var
    p: codegen_$cell_ptr_t;
    k: codegen_$cell_ptr_t;
    last: codegen_$cell_ptr_t;
    n: il_$node_ptr_t;
    pc: integer32;
    kind: integer;
  begin
    consts2 := nil;
    consts4 := nil;
    pc := 0;
    p := first;
    while p <> fn_sect^.head do begin
      kind := p^.kind;
      if not (kind in [0, 24, 28, 32..33]) then begin
        if (kind = move_instyp) and (p^.ads2.f1 = 1) and (p^.ads1.f1 = 3) then begin
          n := il_$node_ptr_t(p^.ads1.x);
          if (n^.kind in [77..87, 101, 200]) and (n^.int_value >= -128) and
             (n^.int_value <= 127) then begin
            p^.kind := moveq_instyp;
            p^.op := 3;
            p^.size := ilength(p);
          end;
        end;
        if not ((5 in cargs_$options.cpu) and fpx_instruction(p)) then begin
          constcheck(p^.ads1);
          constcheck(p^.ads2);
        end;
        p^.size := ilength(p);
        pc := pc + p^.size;
      end
      else if kind = inline_instyp then begin
        p^.size := ilength(p);
        pc := pc + p^.size;
      end;
      if (cargs_$options.db = 3) and
         not ((p^.kind = block_end_instyp) or (p^.kind = block_start_instyp) or
              (p^.kind = line_no_instyp)) then
        p := p^.next
      else
        case p^.kind of
          block_end_instyp: begin
            if p^.blk^.kind <> 172 then begin
              if consts2 <> nil then begin
                last := consts2^.prev;
                join(p, consts2);
                p := last;
              end;
              if consts4 <> nil then begin
                if 4 in cargs_$options.flags_286 then begin
                  k := getcodecell(align_instyp);
                  k^.op := 208;
                  k^.ads1 := fn_null_ads;
                  k^.ads2 := fn_null_ads;
                  k^.size := ilength(k);
                  after(p, k);
                  p := k;
                end;
                last := consts4^.prev;
                join(p, consts4);
                p := last;
              end;
            end;
            p := p^.next;
          end;
          def_lbl_instyp: begin
            p^.addr := pc;
            p := plab(p);
          end;
          fbr_instyp, cbr_instyp, br_instyp, dbcc_instyp: begin
            ref := codegen_$cell_ptr_t(p^.ads2.y);
            lab := ref^.owner;
            if (4 in cargs_$options.flags_286) and
               (lab^.prev^.kind <> align_instyp) and (lab^.addr - pc > -256) and
               (lab^.addr <> 0) and (lab^.addr - pc < 0) then begin
              k := getcodecell(align_instyp);
              k^.op := 208;
              k^.ads1 := fn_null_ads;
              k^.ads2 := fn_null_ads;
              k^.size := ilength(k);
              after(lab^.prev, k);
            end;
            if p^.kind = cbr_instyp then
              p := pcondjmp(p)
            else if p^.kind = br_instyp then
              p := puncondjmp(p)
            else if p^.kind = fbr_instyp then
              p := f_pcondjmp(p)
            else
              p := p^.next;
          end;
          otherwise
            p := p^.next;
        end;
    end;
  end;

  { damn_the_040s_hide_anyway - a nop (insert_integer_nop) put before
    each 68881 instruction of ops 448..453 (not a label, line or block
    mark).

    0x112042, 0x5E bytes, no A5 load: peepholer's first by its dynamic
    link. }

  procedure damn_the_040s_hide_anyway;
  var
    p: codegen_$cell_ptr_t;

    { insert_integer_nop - a nop (kind 35, op 208, empty operands) put
      after c.

      0x111FE4, 0x5C bytes, no A5 load. }

    procedure insert_integer_nop(
        c: codegen_$cell_ptr_t); options(val_param);
    var
      n: codegen_$cell_ptr_t;
    begin
      n := getcodecell(nop_instyp);
      n^.op := 208;
      n^.ads1 := fn_null_ads;
      n^.ads2 := fn_null_ads;
      n^.size := ilength(n);
      after(c, n);
    end;

  begin
    p := first;
    while p <> fn_sect^.head do begin
      if not (p^.kind in [0, 24, 32..33]) and (p^.op in [448..453]) then
        insert_integer_nop(prvlcc(p));
      p := p^.next;
    end;
  end;

begin
  fn_sect := sect;
  peepholer_init;
  if 27 in cargs_$options.opt_on then
    peepholer_ops;
  peepholer_cleanup;
  if 14 in cargs_$options.opt_on then begin
    instr_reorder(first, sect);
    if 27 in cargs_$options.opt_on then
      peepholer_ops;
    peepholer_cleanup;
  end;
  damn_the_040s_hide_anyway;
  dobansheefpx(first, fn_sect^.head);
end;

{ finaldriver - the final phase's branch resolution, timed as phase 21
  (perfstart, jmp_br_resolve, perfstop).

  0x112116, 0x34 bytes, A5 loaded. }

procedure finaldriver;
begin
  perfstart(21);
  jmp_br_resolve;
  perfstop(21);
end;
