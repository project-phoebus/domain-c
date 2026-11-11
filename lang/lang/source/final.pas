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

var
  { opinfo.pas's data (the unit without code; cc.m68k 0x2D01CE,
    absolute): each instruction's two operands' sizes ('B', 'W', 'L',
    'F', 'D', 'X'), indexed by the cell's +48. }
  opinfo_size: extern array [0..367] of packed array [1..2] of char;

  { The module's data (A5 0x3566F8). }
  fn_0: array [0..3] of integer32;      { +0 }
  fn_ads: codegen_$ads_t;               { +16 }
  fn_head: codegen_$cell_ptr_t;         { +28 }
  fn_32: codegen_$cell_ptr_t;           { +32 }
  fn_36: codegen_$cell_ptr_t;           { +36 }
  fn_40: integer;                       { +40 }
  fn_42: char;                          { +42 }
  fn_changed: boolean;                  { +44: a cell was detached }


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
