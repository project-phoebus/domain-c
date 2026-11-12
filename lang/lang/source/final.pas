{ final - the m68k back end's final phase (cc.m68k only): the peephole
  optimizer over a routine's code cells (CELPKG's).

  TODO(pascal) final.pas is not finished; the routines not yet
  translated are listed below the address table.

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
    A5 0x3566F8: the module's data (the last module's), laid out as the
    variables below.  Absolute: cargs's options (+0x282..+0x288).

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
