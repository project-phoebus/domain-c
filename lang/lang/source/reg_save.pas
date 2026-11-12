{ reg_save - which registers a statement or an object (a routine, a
  call, a tree, an assignment) consumes or preserves, for the register
  allocator and the optimizer's live register sets: a routine's by its
  options (-XRS, its block's or type's flags), the run-time library's
  by their nodes' +4, a statement's by the trees it evaluates; the
  extra temporaries an operator needs are the register set's bits
  24..30 (24..26 data, 27..29 address, 30 floating), resolved against
  the registers already counted.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0EBE4C  --------  assert_is_top_level_object
    0x0EBE90  --------  assert_is_fortran_routine
    0x0EBEB8  --------  assert_is_ptr_over_fortran_routine
    0x0EBEE2  --------  assert_is_tree_node
    0x0EBF04  --------  get_extra_regs_from_set
    0x0EBF4E  --------  tally_extra_temp_regs_needed
    0x0EBFBC  --------  get_extra_temp_regs
    0x0EC024  --------  resolve_temp_reg_consumption_overlap
    0x0EC07C  --------  registers_consumed_by_fortran_symbol
    0x0EC0F0  --------  registers_consumed_by_routine_block
    0x0EC1D2  --------  registers_consumed_by_routine_type
    0x0EC28C  --------  registers_consumed_by_pf_call
    0x0EC326  --------  registers_consumed_by_cc_call
    0x0EC3CE  --------  registers_consumed_by_tree_operator
    0x0ECB64  --------  registers_consumed_by_agg_aop
    0x0ECD06  --------  registers_consumed_by_assign_operator
    0x0ECEB6  --------  assert_tree_result_depends_on_operands
    0x0ECEFE  --------  registers_consumed_by_object
    0x0ED178  --------  registers_preserved_by_statement
    0x0ED398  --------  reg_save_$unaffected_by_routine
    0x0ED438  --------  reg_save_$killed_by_routine
    0x0ED458  --------  reg_save_$registers_preserved_by_statement
    0x0ED478  --------  reg_save
    A5 0x353194 (cc.m68k): no data of the unit's own is addressed (its
    A5 loads point at the next module's data).

  registers_consumed_by_object, the three reg_save_$ routines and
  reg_save load A5 (global; reg_save's heading is the prelude's,
  globals_from_backend.ins.pas); the others are internal (the asserts
  leaves without a frame, docs/rev889-patterns.md 16).  Register sets
  are globals_from_backend.ins.pas's reg_save_$regs_t; the masks met:
  [0..23] every register (16#FFFFFF), [0..17] all but FP2..FP7
  (16#3FFFF), [0, 1, 8, 9, 16, 17] the scratch registers D0, D1, A0,
  A1, FP0, FP1 (16#30303).

  Not known from the original: the parameters' and locals' names.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind set).
}

{ TODO(pascal) reg_save.pas is unfinished: six routines not written

  registers_consumed_by_tree_operator (0x0EC3CE, 0x6F0 bytes: a case of
  74 operators on the tree's +36, the extra temporaries each needs, the
  string builtins through cg_misc_$strcmp_can_use_longs, the constant
  multiplications through cg_tree_$is_decomposable_const_mul, the
  library routines through reg_save_$killed_by_routine),
  registers_consumed_by_agg_aop (0x0ECB64), registers_consumed_by_
  assign_operator (0x0ECD06: a case on the assignment's +76),
  assert_tree_result_depends_on_operands (0x0ECEB6),
  registers_consumed_by_object (0x0ECEFE: by the object's kind, a set
  of 0..207 at 0x0ED15E, 'NIL object' checked) and
  registers_preserved_by_statement (0x0ED178: a top-level statement's
  trees) are declared below and not translated yet. }

module reg_save;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/delay.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

var
  { opt_livevar.pas's data +0 (cc.m68k 0x2D2ED8), reached absolutely by
    opt_general, opt_main (assert_is_call_to_abnormal_routine) and
    registers_consumed_by_fortran_symbol: taken to be the node of the
    routine whose calls disturb every register but FP2..FP7.  Declared
    here until its owner is translated (docs/questions.md). }
  opt_abnormal_routine: extern il_$node_ptr_t;

{ The routines not translated yet (the TODO above). }

function registers_consumed_by_object(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); extern;

function registers_preserved_by_statement(
    s: il_$node_ptr_t;
    whole: boolean): reg_save_$regs_t; options(val_param); extern;

define
  reg_save_$unaffected_by_routine, reg_save_$killed_by_routine,
  reg_save_$registers_preserved_by_statement, reg_save;

{ assert_is_top_level_object - whether n is a top-level statement (its
  kind in the set at 0x0EBE72).

  0x0EBE4C, 0x26 bytes: no frame; a set of 0..239 tested without a range
  check (`move.w #239; sub.w; lsr.w #3; btst'); `sne'. }

function assert_is_top_level_object(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_top_level_object := n^.kind in [139..142, 144, 148..151, 188,
      191, 214..215, 223..225, 227..228, 231, 233]
  else
    assert_is_top_level_object := false;
end;

{ assert_is_fortran_routine - whether n is a Fortran routine (110 of
  class 1, +44's high nibble).

  0x0EBE90, 0x28 bytes: no frame; `seq'. }

function assert_is_fortran_routine(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    if n^.kind = 110 then begin
      assert_is_fortran_routine := rshft(ord(n^.xc[44]) & 16#F0, 4) = 1;
      return;
    end;
  assert_is_fortran_routine := false;
end;

{ assert_is_ptr_over_fortran_routine - whether n (146) refers to a
  Fortran routine (+24).

  0x0EBEB8, 0x2A bytes: assert_is_fortran_routine's D0 kept. }

function assert_is_ptr_over_fortran_routine(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    if n^.kind = 146 then begin
      assert_is_ptr_over_fortran_routine := assert_is_fortran_routine(n^.xp[6]);
      return;
    end;
  assert_is_ptr_over_fortran_routine := false;
end;

{ assert_is_tree_node - whether n is a tree (143 or 137).

  0x0EBEE2, 0x22 bytes: no frame; the kinds evaluated whole (`seq;
  seq; or.b', docs/rev889-patterns.md 29). }

function assert_is_tree_node(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_tree_node := (n^.kind = 143) or (n^.kind = 137)
  else
    assert_is_tree_node := false;
end;

{ get_extra_regs_from_set - up to n of the markers of s (24..30) not
  yet in regs added to it.

  0x0EBF04, 0x4A bytes: the loop entered at its test (`tst.w; ble;
  cmpi.w #30; bls'). }

procedure get_extra_regs_from_set(
    var regs: reg_save_$regs_t;
    n: integer;
    s: reg_save_$regs_t); options(val_param); internal;
var
  b: integer;
begin
  b := 24;
  while (n > 0) and (b <= 30) do begin
    if b in s then
      if not (b in regs) then begin
        regs := regs + [b];
        n := n - 1;
      end;
    b := b + 1;
  end;
end;

{ tally_extra_temp_regs_needed - the markers of s counted by class:
  address (27..29) a, data (24..26) d, floating (30) f.

  0x0EBF4E, 0x6E bytes: the three counts cleared first; a `dbf' of 7
  over 24..30, each class's mask tested `btst'. }

procedure tally_extra_temp_regs_needed(
    s: reg_save_$regs_t;
    var a: integer;
    var d: integer;
    var f: integer); options(val_param); internal;
var
  b: integer;
begin
  a := 0;
  d := 0;
  f := 0;
  if s <> [] then
    for b := 24 to 30 do
      if (b in s) and (b in [27..29]) then
        a := a + 1
      else if (b in s) and (b in [24..26]) then
        d := d + 1
      else if (b in s) and (b in [30]) then
        f := f + 1;
end;

{ get_extra_temp_regs - a address, d data and f floating markers more
  in regs.

  0x0EBFBC, 0x68 bytes: the counts by address, each tested `ble'. }

procedure get_extra_temp_regs(
    var regs: reg_save_$regs_t;
    in a: integer;
    in d: integer;
    in f: integer); internal;
begin
  if a > 0 then
    get_extra_regs_from_set(regs, a, [27..29]);
  if d > 0 then
    get_extra_regs_from_set(regs, d, [24..26]);
  if f > 0 then
    get_extra_regs_from_set(regs, f, [30]);
end;

{ resolve_temp_reg_consumption_overlap - s added to regs; the markers
  of s that regs already had become further markers (as many of each
  class again).

  0x0EC024, 0x58 bytes, link #-16: the overlap computed after the `or'
  (`and.l' with the new regs: s itself), tested against 24..30
  (`andi.l #0x7F000000'); the counts in frame words -14, -12, -10. }

procedure resolve_temp_reg_consumption_overlap(
    var regs: reg_save_$regs_t;
    s: reg_save_$regs_t); options(val_param); internal;
var
  ov: reg_save_$regs_t;
  a: integer;
  d: integer;
  f: integer;
begin
  if s <> [] then begin
    regs := regs + s;
    ov := s * regs;
    if ov <> [] then
      if ov * [24..30] <> [] then begin
        tally_extra_temp_regs_needed(ov, a, d, f);
        get_extra_temp_regs(regs, a, d, f);
      end;
  end;
end;

{ registers_consumed_by_fortran_symbol - the registers a reference to
  Fortran symbol n consumes: not a routine, an address marker (27) for
  the classes 6, 7, 8, 10 (+11's high nibble), else none; the abnormal
  routine [0..17]; a routine with +44 bit 3 or 2, or under -XRS, the
  scratch registers; else every register.

  0x0EC07C, 0x74 bytes: the classes `btst' in 0x05C0. }

function registers_consumed_by_fortran_symbol(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  cls: integer;
begin
  if not assert_is_fortran_routine(n) then begin
    cls := rshft(ord(n^.xc[11]) & 16#F0, 4);
    if cls in [6..8, 10] then
      registers_consumed_by_fortran_symbol := [27]
    else
      registers_consumed_by_fortran_symbol := [];
  end
  else if n = opt_abnormal_routine then
    registers_consumed_by_fortran_symbol := [0..17]
  else if ((ord(n^.xc[44]) & 8) <> 0) or ((ord(n^.xc[44]) & 4) <> 0) or
          cargs_$options.xrs then
    registers_consumed_by_fortran_symbol := [0, 1, 8, 9, 16, 17]
  else
    registers_consumed_by_fortran_symbol := [0..23];
end;

{ registers_consumed_by_routine_block - the registers a call of the
  routine whose block (108, 107) is n consumes: every register for a
  routine of +376's bits 8..7 equal to 2 and +294 equal to -2 outside
  -XRS, or with +375 bit 0; [0..17] with +376 bit 5; else the scratch
  registers.

  0x0EC0F0, 0x8C bytes: the kinds evaluated whole (`seq; seq; or.b;
  bmi'); bug_check of 'reg_save\registers_consumed_by_routine_block --
  not a procedure_blk or function_blk%$' otherwise; +294 a signed byte
  (`ext.w'). }

function registers_consumed_by_routine_block(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  ok: boolean;
begin
  ok := false;
  if n <> nil then
    ok := (n^.kind = 108) or (n^.kind = 107);
  if not ok then
    bug_check('reg_save\registers_consumed_by_routine_block -- not a procedure_blk or function_blk%$');
  if (rshft(n^.xw[188] & 16#180, 7) = 2) and (ord(n^.xc[294]) = 254) and
     not cargs_$options.xrs then
    registers_consumed_by_routine_block := [0..23]
  else if (ord(n^.xc[375]) & 1) <> 0 then
    registers_consumed_by_routine_block := [0..23]
  else if (ord(n^.xc[376]) & 16#20) <> 0 then
    registers_consumed_by_routine_block := [0..17]
  else
    registers_consumed_by_routine_block := [0, 1, 8, 9, 16, 17];
end;

{ registers_consumed_by_routine_type - the registers a call through a
  routine type n (174, 173) consumes: every register outside -XRS or
  with +78 bit 0; [0..17] with +79 bit 5; else the scratch registers.

  0x0EC1D2, 0x68 bytes: bug_check of 'reg_save\registers_consumed_by_
  routine_type -- not a proc__type or func__type%$' for another kind. }

function registers_consumed_by_routine_type(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  ok: boolean;
begin
  ok := false;
  if n <> nil then
    ok := (n^.kind = 174) or (n^.kind = 173);
  if not ok then
    bug_check('reg_save\registers_consumed_by_routine_type -- not a proc__type or func__type%$');
  if not cargs_$options.xrs or ((ord(n^.xc[78]) & 1) <> 0) then
    registers_consumed_by_routine_type := [0..23]
  else if (ord(n^.xc[79]) & 16#20) <> 0 then
    registers_consumed_by_routine_type := [0..17]
  else
    registers_consumed_by_routine_type := [0, 1, 8, 9, 16, 17];
end;

{ registers_consumed_by_pf_call - as registers_consumed_by_routine_type
  for the type (+20) of a call through a pointer (175).

  0x0EC28C, 0x60 bytes: bug_check of 'reg_save\registers_consumed_by_
  pf_call -- not a pf_call%$' for another kind; the type loaded only
  under -XRS. }

function registers_consumed_by_pf_call(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  t: il_$node_ptr_t;
begin
  if (n = nil) or (n^.kind <> 175) then
    bug_check('reg_save\registers_consumed_by_pf_call -- not a pf_call%$');
  if not cargs_$options.xrs then begin
    registers_consumed_by_pf_call := [0..23];
    return;
  end;
  t := n^.xp[5];
  if (ord(t^.xc[78]) & 1) <> 0 then
    registers_consumed_by_pf_call := [0..23]
  else if (ord(t^.xc[79]) & 16#20) <> 0 then
    registers_consumed_by_pf_call := [0..17]
  else
    registers_consumed_by_pf_call := [0, 1, 8, 9, 16, 17];
end;

{ registers_consumed_by_cc_call - the registers a call (171) of the
  routine +16 consumes: its block's (108, 107), else every register
  outside -XRS, else the routine's and the scratch registers.

  0x0EC326, 0x6E bytes: bug_check of 'reg_save\registers_consumed_by_
  cc_call -- not a cc_call%$' for another kind; the kinds compared 108
  then 107. }

function registers_consumed_by_cc_call(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
begin
  if (n = nil) or (n^.kind <> 171) then
    bug_check('reg_save\registers_consumed_by_cc_call -- not a cc_call%$');
  if n^.xp[4] <> nil then
    if (n^.xp[4]^.kind = 108) or (n^.xp[4]^.kind = 107) then begin
      registers_consumed_by_cc_call := registers_consumed_by_object(n^.xp[4]);
      return;
    end;
  if not cargs_$options.xrs then
    registers_consumed_by_cc_call := [0..23]
  else
    registers_consumed_by_cc_call :=
      registers_consumed_by_object(n^.xp[4]) + [0, 1, 8, 9, 16, 17];
end;

{ reg_save_$unaffected_by_routine - the registers run-time library
  routine k (std_lib_rtns[k]) leaves alone (its node's +4) with the
  markers, A0 not under -PIC (flags_286 element 7 clear).

  0x0ED398, 0x66 bytes: k below 176 (`cmpi.w #176; bcs'), else
  bug_check of 'reg_save_$unaffected_by_routine -- out-of-range
  routine%$' and the empty set; the markers `ori.l #0xFF000000'; A0
  `andi.l #-257'. }

function reg_save_$unaffected_by_routine(
    k: integer): reg_save_$regs_t; options(val_param);
var
  res: reg_save_$regs_t;
begin
  res := [];
  if k >= 176 then
    bug_check('reg_save_$unaffected_by_routine -- out-of-range routine%$')
  else
    res := reg_save_$regs_t(std_lib_rtns[k]^.xl[1]) + [24..31];
  if not (7 in cargs_$options.flags_286) then
    res := res - [8];
  reg_save_$unaffected_by_routine := res;
end;

{ reg_save_$killed_by_routine - the registers run-time library routine
  k disturbs.

  0x0ED438, 0x20 bytes: `not.l' of reg_save_$unaffected_by_routine's
  result. }

function reg_save_$killed_by_routine(
    k: integer): reg_save_$regs_t; options(val_param);
begin
  reg_save_$killed_by_routine := [0..31] - reg_save_$unaffected_by_routine(k);
end;

{ reg_save_$registers_preserved_by_statement - the registers statement
  s preserves, its trees taken whole.

  0x0ED458, 0x20 bytes: registers_preserved_by_statement(s, true), the
  boolean pushed `st -(SP)' after the pad. }

function reg_save_$registers_preserved_by_statement(
    s: il_$node_ptr_t): reg_save_$regs_t; options(val_param);
begin
  reg_save_$registers_preserved_by_statement :=
    registers_preserved_by_statement(s, true);
end;

{ reg_save - the registers statement or object n preserves: a
  top-level statement's (its trees not taken whole), else the
  registers the object does not consume; every register for nil.

  0x0ED478, 0x48 bytes: `not.l' of registers_consumed_by_object's
  result; nil `moveq #-1'. }

function reg_save;
begin
  if assert_is_top_level_object(n) then
    reg_save := registers_preserved_by_statement(n, false)
  else if n <> nil then
    reg_save := [0..31] - registers_consumed_by_object(n)
  else
    reg_save := [0..31];
end;
