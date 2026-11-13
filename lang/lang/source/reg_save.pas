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

  Trees are read through cg.ins.pas's cg_tree_t, statements (the
  assignments, evaluations, branches) through g_opt.ins.pas's
  g_opt_stmt_t, other nodes by offset.

  Not known from the original: the parameters' and locals' names.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind sets), 24 (a
  call as the right operand of `or'), 30 (`in' on a set parameter).
}

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

{ registers_consumed_by_cc_call and registers_consumed_by_tree_operator
  call them before their bodies. }

function registers_consumed_by_object(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); forward;

function reg_save_$killed_by_routine(
    k: integer): reg_save_$regs_t; options(val_param); forward;

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
    assert_is_top_level_object := n^.kind in [eval_node..cbranch_node,
                                              label_node,
                                              block_entry_node..return_node,
                                              use_def_ob,
      reg_list_ob, case_node_range_check..case_node_no_range_check,
          exception_handler_entry..release_dynamic_space,
          insert_bit_field..bit_field_assign, spine_mark, pa_mmu_bip]
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
    if n^.kind = fortran_symbol then begin
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
    if n^.kind = ptr_node then begin
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
    assert_is_tree_node := (n^.kind = cmp_tree_node) or (n^.kind = tree_node)
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
    ok := (n^.kind = function_blk) or (n^.kind = procedure_blk);
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
    ok := (n^.kind = func__type) or (n^.kind = proc__type);
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
  if (n = nil) or (n^.kind <> pf_call) then
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
  if (n = nil) or (n^.kind <> cc_call) then
    bug_check('reg_save\registers_consumed_by_cc_call -- not a cc_call%$');
  if n^.xp[4] <> nil then
    if (n^.xp[4]^.kind = function_blk)
        or (n^.xp[4]^.kind = procedure_blk) then begin
      registers_consumed_by_cc_call := registers_consumed_by_object(n^.xp[4]);
      return;
    end;
  if not cargs_$options.xrs then
    registers_consumed_by_cc_call := [0..23]
  else
    registers_consumed_by_cc_call :=
      registers_consumed_by_object(n^.xp[4]) + [0, 1, 8, 9, 16, 17];
end;

{ registers_consumed_by_tree_operator - the registers and extra
  temporaries tree n's operator (+36) needs, its operands not counted:
  the markers by operator (24..26 data, 27..29 address, 30 floating, 31
  an FPA1 register), D0 and A0 for the multiplications without a 32-bit
  multiply (-CPU 160, M020 not given), the library routine's registers
  for a division done by a call (delay_$divide_attributes) or a
  floating operation needing one (cg_tree_$needs_lib_support), a
  conversion to a floating value without a floating unit (routine 18);
  a call's (15, 16) for a routine not reached directly by its kind:
  every register outside -XRS, else the scratch registers, A0 when
  -PIC or a call through a variable, A1 for a routine (107, 167, 108)
  with +378 bit 6.

  0x0EC3CE, 0x6F0 bytes, link #-56: the operators by a jump table of 74
  (0x0EC40C; 5, 30..33, 51..62, 64..67, 71 and the others none); the
  result in D2 (cleared first); the arms needing a library routine end
  in one tail (0x0ECA9E `bsr reg_save_$killed_by_routine', its argument
  pushed by each arm, no pop); the constant kinds the set at 0x0ECB4A
  (0..207: [77..87, 101, 200], gap 8), the operands' kinds the sets at
  0x0ECB30 (references) and 0x0ECB16 (constants), the routine kinds
  at 0x0ECB00 (0..175); the cpu word (0x2C3670) masked whole (`andi.w
  #0x3FFC; lsr.w #2' then `andi.w #12' or `#0x714') or tested by its
  bits (`btst #5' of 0x2C3671 M020, `btst #2' of 0x2C3670 FPA1, `#4'
  MATHLIB_SR10); 41's sizes compared unsigned (`bhi'), its set of
  0..31 (0xF100) tested after `cmp.l #31' of the zero-extended word.
  delay_$divide_attributes' fields in frame words (-46 how, -44 the
  routine, -52 b58), the library routine's index at -30.

  Not known from the original: the names of the locals, the meaning of
  the operator codes. }

function registers_consumed_by_tree_operator(
    n: il_$node_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  strategy: integer32;
  rsize: integer32;
  sh: integer32;
  lsize: integer32;
  w70: integer;
  w66: integer;
  rtn: integer;
  w42: integer;
  w34: integer;
  w26: integer;
  w62: integer;
  w18: integer;
  drtn: integer;
  how: integer;
  b58: boolean;
  b54: boolean;
  t: cg_tree_ptr_t;
  r: reg_save_$regs_t;
begin
  if not assert_is_tree_node(n) then
    bug_check('reg_save\registers_consumed_by_tree_operator -- not a tree node%$');
  t := cg_tree_ptr_t(n);
  r := [];
  case t^.op of
    strlen_top:
      r := [24, 27];
    strcmp_top:
      if cg_misc_$strcmp_can_use_longs(n) then
        r := [24..28]
      else if t^.desc.w6 = 1 then
        r := [24, 27, 28]
      else
        r := [24, 25, 27, 28];
    strncmp_top:
      if t^.desc.w6 = 1 then
        r := [24, 25, 27..29]
      else
        r := [24..29];
    mul_top: begin
      r := [24, 25, 27, 28];
      if cg_tree_$is_decomposable_const_mul(n) then
        r := [24..28];
      if cargs_$options.cpu * [2, 3] = [] then
        if (t^.desc.w6 <> 2) or (t^.desc.w8 <> 2) then
          r := r + [0, 8];
    end;
    expon_top:
      r := [0, 8];
    div_top: begin
      r := [24, 25, 27, 28];
      if not (3 in cargs_$options.cpu) then
        r := [0, 8, 24, 25, 27, 28]
      else if t^.desc.w8 <> 4 then
        r := [24..28];
    end;
    mod_top: begin
      r := [24, 25];
      delay_$divide_attributes(n, false, strategy, w18, lsize, w26, rsize,
          w34, how, w42, drtn, sh, b54, b58, w62, w66, w70);
      if how in [4, 8] then begin
        if t^.desc.w8 <> 4 then
          r := [24..26]
        else if b58 then
          r := [24..26];
      end
      else if how = 0 then
        r := reg_save_$killed_by_routine(drtn);
    end;
    bit_set_top: begin
      r := [24, 25];
      if t^.count > 2 then
        if not ((t^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                      binteger_ob]) and
                (t^.opnd[3]^.kind in [blogical_ob..char_ob, char16_ob,
                                      binteger_ob])) then
          r := [24..26];
    end;
    neg_top, not_top:
      r := [24];
    sr_top:
      if t^.count <> 1 then
        r := [24];
    addr_top:
      r := [27];
    compare_top:
      if t^.desc.w6 = 5 then
        r := [24, 27]
      else
        r := [24];
    add_top, sub_top, and_top, or_top:
      if t^.desc.rlen = rlen_addr then
        r := [27]
      else
        r := [24];
    unpack_top: begin
      r := [24, 25, 27, 28];
      if not (t^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                   binteger_ob]) then
        r := [24..28];
    end;
    nop_top, abs_top, max_top, min_top, chk_top, align_top, set_bit_in_set_top:
      r := [24, 25, 27, 28];
    index_top: begin
      r := [27];
      if t^.desc.rlen = rlen_long then
        r := [24, 27];
    end;
    value_top: begin
      if (t^.desc.rlen = rlen_r8) or (t^.desc.rlen = rlen_r4) then
        if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
          r := [30]
        else
          r := reg_save_$killed_by_routine(18);
      if assert_is_tree_node(t^.opnd[1]) then begin
        if (t^.desc.rlen = rlen_byte) or (t^.desc.rlen = rlen_long) or
           (t^.desc.rlen = rlen_word) then
          r := r + [24]
        else if ((t^.desc.rlen = rlen_r8) or (t^.desc.rlen = rlen_r4)) and
                (cg_tree_ptr_t(t^.opnd[1])^.desc.rlen = rlen_addr) then
          r := r + [27]
        else if t^.desc.rlen = rlen_addr then
          r := r + [27]
        else if (t^.desc.rlen = rlen_r8) or (t^.desc.rlen = rlen_r4) then
          if (cg_tree_ptr_t(t^.opnd[1])^.desc.rlen = rlen_byte) or
             (cg_tree_ptr_t(t^.opnd[1])^.desc.rlen = rlen_long) or
             (cg_tree_ptr_t(t^.opnd[1])^.desc.rlen = rlen_word) then
            r := r + [27];
      end
      else if t^.opnd[1]^.kind in [var_name..fortran_symbol,
                                   dindex_node..disp_node, addr_con..cs_node,
                                   reloc_absolute_addr_con,
                                   sym_disp_node] then
        r := r + [24, 27]
      else if t^.opnd[1]^.kind in [blogical_ob..complex_ob,
                                   char_string_ob..char32_string_ob, char16_ob,
                                   set_con_ob, rec_const_ob, dpcomplex_ob,
                                   binteger_ob] then
        r := r + [24]
      else
        r := r + [24, 25, 27, 28];
    end;
    lshf_top, rshf_top, eor_top, alshf_top, arshf_top: begin
      r := [24];
      if not (t^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                   binteger_ob]) then
        r := [24, 25];
    end;
    set_compare_top, agg_compare_top, set_range_in_set_top:
      r := [24..28];
    set_extend_top:
      r := [24, 27, 28];
    bit_test_top:
      if not (t^.opnd[1]^.kind in [blogical_ob..char_ob, char16_ob,
                                   binteger_ob]) then
        if 3 in cargs_$options.cpu then
          r := [24, 25]
        else
          r := [24..28];
    call_top, func_call_top: begin
      if not (t^.opnd[1]^.kind in [procedure_blk..function_blk, fortran_symbol,
                                   lib_dsc, cc_call, proc__type..pf_call]) then
        if cargs_$options.xrs then
          r := [0, 1, 8, 9, 16, 17]
        else
          r := [0..23];
      if not (7 in cargs_$options.flags_286) or
         cg_call_$is_proc_var_call(t^.opnd[1]) then
        r := r + [8];
      if (t^.opnd[1]^.kind = procedure_blk) or (t^.opnd[1]^.kind = entry_blk)
          or
         (t^.opnd[1]^.kind = function_blk) then
        if (ord(t^.opnd[1]^.xc[378]) & 16#40) <> 0 then
          r := r + [9];
    end;
    set_and_top, set_or_top, set_diff_top:
      r := [24..29];
    extend_top:
      r := [24];
    f_add_top, f_sub_top, f_mul_top:
      if cg_tree_$needs_lib_support(n, rtn) then
        r := reg_save_$killed_by_routine(rtn)
      else
        r := [30];
    f_div_top, f_neg_top:
      if cg_tree_$needs_lib_support(n, rtn) then
        r := reg_save_$killed_by_routine(rtn)
      else begin
        r := [30];
        if 8 in cargs_$options.cpu then
          r := [30, 31];
      end;
    f_extend_top:
      if cg_tree_$needs_lib_support(n, rtn) then
        r := reg_save_$killed_by_routine(rtn)
      else begin
        r := [24, 25, 27, 28, 30];
        if 8 in cargs_$options.cpu then
          r := [24, 25, 27, 28, 30, 31];
      end;
    f_compare_top:
      if cg_tree_$needs_lib_support(n, rtn) then
        r := reg_save_$killed_by_routine(rtn)
      else begin
        r := [24, 25, 27, 28, 30];
        if 8 in cargs_$options.cpu then
          r := [24..28, 30, 31];
      end;
    f_math_top:
      if cg_tree_$needs_lib_support(n, rtn) then begin
        r := reg_save_$killed_by_routine(rtn);
        if (t^.desc.w6 = 11) and (t^.desc.rlen <= rlen_long) then
          r := r + [0];
        if 10 in cargs_$options.cpu then
          if t^.desc.w6 in [8, 12..15] then
            r := r + [17];
      end
      else begin
        r := [24, 25, 27, 28, 30];
        if 8 in cargs_$options.cpu then
          r := [24, 25, 27, 28, 30, 31];
      end;
    f_expon_top:
      if cg_tree_$needs_lib_support(n, rtn) then
        r := reg_save_$killed_by_routine(rtn)
      else
        r := [24, 25, 27, 28, 30];
    otherwise
      ;
  end;
  registers_consumed_by_tree_operator := r;
end;

{ registers_consumed_by_agg_aop - the extra temporaries of an aggregate
  assignment s (140, operator 6): moved by longwords (by bytes when
  +58 bit 2 and either side may be unaligned) count times (size less
  the varying length +56 for +52 = 9), with a remainder of rem bytes;
  a short move (no more than two units, or one and up to 2 bytes) a
  data register unless the source is a constant, and two more unless
  the destination is a variable (109, 110); a longer one a counter and
  two address registers (a data register more when the moves are
  better done in a loop, cg_asn_$inline_move_is_best), all four for a
  constant source; four more for a varying length.

  0x0ECB64, 0x160 bytes, link #-28: bug_check of 'reg_save\registers_
  consumed_by_agg_aop -- not an agg_aop assign%$'; the two unaligned
  tests evaluated whole (`or.b' of a frame byte); the size and the
  unit divided by M$OIS$LLL and M$DIS$LLL (signed); count - 1 kept
  (D2), count passed to inline_move_is_best (`addq.l #1'); the constant
  kinds the set at 0x0ECB16 (0..207).

  Not known from the original: the names of the locals. }

function registers_consumed_by_agg_aop(
    s: g_opt_stmt_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  unit: cg_count_t;
  size: integer32;
  n: integer32;
  rem: integer32;
  r: reg_save_$regs_t;
begin
  if (s = nil) or (s^.kind <> assign_node) or (s^.asg_op <> agg_aop) then
    bug_check('reg_save\registers_consumed_by_agg_aop -- not an agg_aop assign%$');
  unit := 4;
  if s^.asg_flags.chars then
    if unaligned(s^.asg_rhs) or unaligned(s^.asg_lhs) then
      unit := 1;
  if s^.asg_rlen = rlen_cs then
    size := s^.asg_size - s^.asg_w56
  else
    size := s^.asg_size;
  rem := size mod unit;
  n := size div unit - 1;
  if (n < 0) or ((n = 1) and (rem = 0)) or ((n = 0) and (rem <= 2)) then begin
    r := [];
    if not (s^.asg_rhs^.kind in [blogical_ob..complex_ob,
                                 char_string_ob..char32_string_ob, char16_ob,
                                 set_con_ob, rec_const_ob, dpcomplex_ob,
                                 binteger_ob]) then
      r := [24, 27];
    if (s^.asg_lhs^.kind <> fortran_symbol)
        and (s^.asg_lhs^.kind <> var_name) then
      r := r + [25, 28];
  end
  else if s^.asg_rhs^.kind in [blogical_ob..complex_ob,
                               char_string_ob..char32_string_ob, char16_ob,
                               set_con_ob, rec_const_ob, dpcomplex_ob,
                               binteger_ob] then
    r := [24, 25, 27, 28]
  else begin
    r := [27, 28];
    if not cg_asn_$inline_move_is_best(n + 1, unit) then
      r := [24, 27, 28];
  end;
  if (s^.asg_rlen = rlen_cs) and (s^.asg_w56 <> 0) then
    r := r + [24, 25, 27, 28];
  registers_consumed_by_agg_aop := r;
end;

{ registers_consumed_by_assign_operator - the extra temporaries the
  store of assignment s (140) needs by its operator (+76): an aggregate
  (6) registers_consumed_by_agg_aop's, the sets (7..9) five, a bit field
  (10) one or two (without -CPU M020), 12 two, the floating ones (19..22)
  a floating register (22 an FPA1 register too), the length aggregate
  (25) four or three (a constant source) and the string builtins
  (27..30) three or four; the others a data register for a source
  that is not a constant, three or four temporaries in their place for
  a store wider than a single (7 a double: two address registers).

  0x0ECD06, 0x16A bytes, link #-12: bug_check of 'reg_save\registers_
  consumed_by_assign_operator -- not an assign node%$'; a jump table
  of 25 from 6; the result in D0 (cleared first); the class compared
  unsigned (`bls'); the constant kinds the set at 0x0ECB16.

  Not known from the original: the meaning of the operator codes. }

function registers_consumed_by_assign_operator(
    s: g_opt_stmt_ptr_t): reg_save_$regs_t; options(val_param); internal;
var
  r: reg_save_$regs_t;
begin
  if (s = nil) or (s^.kind <> assign_node) then
    bug_check('reg_save\registers_consumed_by_assign_operator -- not an assign node%$');
  r := [];
  case s^.asg_op of
    strcpy_aop:
      r := [24, 27, 28];
    strncpy_aop:
      r := [24, 25, 27, 28];
    strcat_aop:
      r := [24, 27, 28];
    strncat_aop:
      r := [24, 25, 27, 28];
    set_and_to_aop, set_or_to_aop, set_diff_from_aop:
      r := [24..28];
    agg_aop:
      r := registers_consumed_by_agg_aop(s);
    agg_len_aop:
      if s^.asg_rhs^.kind in [blogical_ob..complex_ob,
                              char_string_ob..char32_string_ob, char16_ob,
                              set_con_ob, rec_const_ob, dpcomplex_ob,
                              binteger_ob] then
        r := [24, 25, 27, 28]
      else
        r := [24, 27, 28];
    f_add_to_aop, f_sub_from_aop, f_mul_to_aop:
      r := [30];
    f_div_by_aop: begin
      r := [30];
      if 8 in cargs_$options.cpu then
        r := [30, 31];
    end;
    pack_aop: begin
      r := [24];
      if not (3 in cargs_$options.cpu) then
        r := [24, 25];
    end;
    field_aop:
      r := [24, 25];
    otherwise begin
      if not (s^.asg_rhs^.kind in [blogical_ob..complex_ob,
                                   char_string_ob..char32_string_ob, char16_ob,
                                   set_con_ob, rec_const_ob, dpcomplex_ob,
                                   binteger_ob]) then
        r := [24];
      if s^.asg_rlen > rlen_r4 then
        if s^.asg_rlen = rlen_r8 then
          r := [27, 28]
        else
          r := [24, 25, 27, 28];
    end;
  end;
  registers_consumed_by_assign_operator := r;
end;

{ assert_tree_result_depends_on_operands - whether tree n's value is
  formed in its operands' registers: not for operators 17, 16, 15 and
  0 (a conversion, the calls, a value as it is), nor for a node that
  is not a tree.

  0x0ECEB6, 0x48 bytes, link #-8: the operators evaluated whole (`seq;
  or.b', docs/rev889-patterns.md 29), then `not.b'. }

function assert_tree_result_depends_on_operands(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_tree_node(n) then
    assert_tree_result_depends_on_operands :=
      not ((cg_tree_ptr_t(n)^.op = value_top) or (cg_tree_ptr_t(n)^.op = func_call_top) or
           (cg_tree_ptr_t(n)^.op = call_top) or (cg_tree_ptr_t(n)^.op = nop_top))
  else
    assert_tree_result_depends_on_operands := false;
end;

{ registers_consumed_by_object - the registers (and extra temporaries)
  that evaluating object n consumes: none for a constant (the kinds of
  the set at 0x0ED15E); a library routine's (159) all but those it
  leaves alone (+4); the display register (155) A1; a common
  subexpression (164) its two parts' and four temporaries; a routine,
  a routine type, a call through a pointer or a call by their
  routines; a tree (137, 143) its operator's with its operands' (taken
  over the operator's when its result depends on them,
  resolve_temp_reg_consumption_overlap); a variable (109) an address
  register for the classes 6, 7, 8, 10 (+72); a Fortran symbol by
  registers_consumed_by_fortran_symbol; a reference through a pointer
  (146) the scratch registers for a Fortran routine, else an address
  register, with its base's (+24); an indexed reference (145) its
  index's (+36) and two temporaries, with its base's; 147 and 205
  their base's; a cse use (190) its parent's (+4); others four
  temporaries.

  0x0ECEFE, 0x22A bytes, link #-32, A5 loaded: bug_check of 'reg_save\
  registers_consumed_by_object -- NIL object%$' for nil; the kinds by
  a compare chain (159, 155, 164, 108, 107, 174, 173, 175, 171, 137,
  143, 109, 110, 146, 145, 147, 205, 190); the operands counted by
  `dbf'; the classes `btst' in 0x05C0; the operands' consumption
  passed to the overlap through a frame temporary (-8). }

function registers_consumed_by_object;
var
  r: reg_save_$regs_t;
  a: reg_save_$regs_t;
  b: reg_save_$regs_t;
  s: reg_save_$regs_t;
  i: integer;
begin
  if n = nil then
    bug_check('reg_save\registers_consumed_by_object -- NIL object%$');
  r := [];
  if n^.kind in [blogical_ob..complex_ob, char_string_ob..char32_string_ob,
                 char16_ob, sb_register..db_register, set_con_ob, addr_con,
                 rec_const_ob, reloc_absolute_addr_con, dpcomplex_ob,
                 binteger_ob] then begin
    registers_consumed_by_object := r;
    return;
  end;
  case n^.kind of
    lib_dsc:
      r := [0..31] - reg_save_$regs_t(n^.xl[1]);
    display_register:
      r := [9];
    cs_node: begin
      a := r;
      b := a;
      if n^.xp[5] <> nil then
        a := registers_consumed_by_object(n^.xp[5]);
      if n^.xp[6] <> nil then
        b := registers_consumed_by_object(n^.xp[6]);
      r := b + a + [24, 25, 27, 28];
    end;
    function_blk, procedure_blk:
      r := registers_consumed_by_routine_block(n);
    func__type, proc__type:
      r := registers_consumed_by_routine_type(n);
    pf_call:
      r := registers_consumed_by_pf_call(n);
    cc_call:
      r := registers_consumed_by_cc_call(n);
    tree_node, cmp_tree_node: begin
      r := registers_consumed_by_tree_operator(n);
      a := [];
      for i := 1 to cg_tree_ptr_t(n)^.count do begin
        s := registers_consumed_by_object(cg_tree_ptr_t(n)^.opnd[i]);
        if assert_tree_result_depends_on_operands(n) then
          resolve_temp_reg_consumption_overlap(a, s)
        else
          a := a + s;
      end;
      r := r + a;
    end;
    var_name:
      if n^.xw[36] in [6..8, 10] then
        r := [27];
    fortran_symbol:
      r := registers_consumed_by_fortran_symbol(n);
    ptr_node: begin
      if assert_is_ptr_over_fortran_routine(n) then
        r := [0, 1, 8, 9, 16, 17]
      else
        r := [27];
      r := r + registers_consumed_by_object(n^.xp[6]);
    end;
    dindex_node: begin
      r := registers_consumed_by_object(n^.xp[9]) + [24, 27];
      r := r + registers_consumed_by_object(n^.xp[6]);
    end;
    disp_node:
      r := registers_consumed_by_object(n^.xp[6]);
    sym_disp_node:
      r := registers_consumed_by_object(n^.xp[6]);
    cse_parent_ob:
      r := registers_consumed_by_object(n^.xp[1]);
    otherwise
      r := [24, 25, 27, 28];
  end;
  registers_consumed_by_object := r;
end;

{ registers_preserved_by_statement - the registers top-level statement
  s preserves (every register, the markers included, unless shown): a
  label (144) reached by a computed or non-local goto (+74, +75) none
  of the markers; a call (148) of a routine that is not an inner block
  all but A0 and the address marker; an assignment (140), when whole,
  all but those its store and its trees consume (overlapping); an
  evaluation (139), when whole, all but those its operands consume; a
  conditional branch (142) all but its condition's; a non-local
  branch (150) not to a label name all but the address marker; a
  return (151), when whole, all but its value's.

  0x0ED178, 0x1DC bytes, link #-32: bug_check of 'reg_save\registers_
  preserved_by_statement -- not a top-level node%$'; the kinds by a
  compare chain (144, 148, 140, 139, 142, 150, 151, then 233, 231,
  215, 214, 223, 225, 224, 228, 227, 191, 188 to the end, as is every
  other kind); the label's flags `tst.b; bmi'; 140's store consumption
  computed before whole is tested and its three trees' passed to the
  overlap from frame longwords (-16 the result, -12, -24, -20); the
  removals `not.l; and.l' (one tail for 142 and 151). }

function registers_preserved_by_statement(
    s: g_opt_stmt_ptr_t;
    whole: boolean): reg_save_$regs_t; options(val_param); internal;
var
  c: reg_save_$regs_t;
  a: reg_save_$regs_t;
  x: reg_save_$regs_t;
  b: reg_save_$regs_t;
  r: reg_save_$regs_t;
  i: integer;
begin
  r := [0..31];
  if not assert_is_top_level_object(il_$node_ptr_t(s)) then
    bug_check('reg_save\registers_preserved_by_statement -- not a top-level node%$');
  case s^.kind of
    label_node:
      if (ord(il_$node_ptr_t(s)^.xc[74]) >= 128) or
         (ord(il_$node_ptr_t(s)^.xc[75]) >= 128) then
        r := [24..31];
    block_entry_node:
      if s^.x48^.kind <> inner_blk then
        r := [0..31] - [8, 27];
    assign_node: begin
      c := registers_consumed_by_assign_operator(s);
      if whole then begin
        a := registers_consumed_by_object(s^.asg_rhs);
        b := registers_consumed_by_object(s^.asg_lhs);
        if s^.asg_x = nil then
          x := []
        else
          x := registers_consumed_by_object(s^.asg_x);
        resolve_temp_reg_consumption_overlap(c, a);
        resolve_temp_reg_consumption_overlap(c, b);
        resolve_temp_reg_consumption_overlap(c, x);
        r := [0..31] - c;
      end;
    end;
    eval_node:
      if whole then
        for i := 1 to s^.eval_count do
          if s^.eval_opnd[i] <> nil then
            r := r - registers_consumed_by_object(s^.eval_opnd[i]);
    cbranch_node:
      if s^.br_cond <> nil then
        r := r - registers_consumed_by_object(s^.br_cond);
    nlbranch_node:
      if s^.br_target^.kind <> label_name then
        r := [0..31] - [27];
    return_node:
      if whole then
        if s^.x48 <> nil then
          r := r - registers_consumed_by_object(s^.x48);
    pa_mmu_bip, spine_mark, case_node_no_range_check, case_node_range_check,
        exception_handler_entry, release_dynamic_space, raise_exception,
        bit_field_assign, insert_bit_field, reg_list_ob, use_def_ob:
      ;
    otherwise
      ;
  end;
  registers_preserved_by_statement := r;
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

function reg_save_$killed_by_routine;
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
    registers_preserved_by_statement(g_opt_stmt_ptr_t(s), true);
end;

{ reg_save - the registers statement or object n preserves: a
  top-level statement's (its trees not taken whole), else the
  registers the object does not consume; every register for nil.

  0x0ED478, 0x48 bytes: `not.l' of registers_consumed_by_object's
  result; nil `moveq #-1'. }

function reg_save;
begin
  if assert_is_top_level_object(n) then
    reg_save := registers_preserved_by_statement(g_opt_stmt_ptr_t(n), false)
  else if n <> nil then
    reg_save := [0..31] - registers_consumed_by_object(n)
  else
    reg_save := [0..31];
end;
