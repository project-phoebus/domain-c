{ cg_tree - the m68k code generator's expression trees: tree_walk and
  walker evaluate a statement's trees (common subexpressions loaded
  into or kept in their registers, operands in the order that keeps the
  destination's register, cg_assign's flags), generate the code of one
  tree node by its operator (jump tables on the node's kind and
  operator, per-operator routines: comparisons, multiplication by a
  constant as shifts and adds, division, bit tests and fields, sets,
  aggregates), and the floating library's calls (the fast math
  library, rounding).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0FEFD0  --------  assert_is_a_tree
    0x0FEFFC  --------  assert_is_f_math_op
    0x0FF034  --------  cg_tree_$fpa1_expon_inquire
    0x0FF0AA  --------  cg_tree_$needs_lib_support
    0x0FF3F4  --------  cg_tree_$prefers_inline_float
    0x0FF4EC  --------  cg_tree_$spill_fp_reg_contents_before_fpp
    0x0FF5B2  --------  cg_tree_$adjust_before_round
    0x0FF84C  --------  cg_tree_$call_fast_math_lib
    0x0FFC2A  --------  assert_const_mul_candidate
    0x0FFC56  --------  movewlx
    0x0FFE66  --------  stkinit (in do_const_mul)
    0x0FFEA2  --------  push (in do_const_mul)
    0x0FFEDA  --------  consecutivebits (in const_mul)
    0x0FFF22  --------  const_mul (in do_const_mul)
    0x10002A  --------  doshft (in genmul)
    0x100148  --------  genmul (in do_const_mul)
    0x1005AC  --------  do_const_mul
    0x10061E  --------  cg_tree_$is_decomposable_const_mul
    0x100660  --------  bit_test_proc (in generate)
    0x100DBC  --------  bit_set_proc (in generate)
    0x1011D8  --------  unpack_proc (in generate)
    0x1015BE  --------  shift_proc (in generate)
    0x101674  --------  agg_compare_proc (in generate)
    0x101C8A  --------  mdmcase (in mul_proc)
    0x101CC8  --------  ldsqr (in mul_proc)
    0x101D38  --------  mul_proc (in generate)
    0x10247E  --------  extend_div_proc_result (in div_proc)
    0x102556  --------  div_proc (in generate)
    0x102CAA  --------  copy_set_aggregate (in generate)
    0x102E94  --------  set_range_in_set_proc (in generate)
    0x1033E0  --------  set_bit_in_set_proc (in generate)
    0x103678  --------  proto_set (in set_ops)
    0x10370A  --------  set_ops (in generate)
    0x10386E  --------  compare_proc (in generate)
    0x103E14  --------  round_fp_to_ieee (in generate)
    0x103EE6  --------  switch (in f_compare_proc)
    0x103F8E  --------  f_compare_proc (in generate)
    0x104640  --------  ld_addr (in generate)
    0x1047CA  --------  restore_alloc_temps (in generate)
    0x10484E  --------  generate
    0x10838E  --------  evaluate_subtree (in walker)
    0x108484  --------  walker
    0x108524  --------  loadcse (in tree_walk)
    0x1085B4  --------  tree_walk
    A5 0x356460 (cc.m68k), 0x298 bytes: +0 the fast math library's
    routines by builtin function (22 entries of a flag byte and a
    std_lib index, .rwdi), +0x58 a PEB operand (.rwdi: f1 11, f2 and f3
    31, f5 5), +0x70 and +0x158 word tables (.rwdi), +0x188
    cg_zero_ads, +0x1A0 cg_null_ads (.rwdi: f2 and f3 31), +0x1B4
    cg_tree_1b4, +0x1B8 .. +0x230 operands (24 bytes apart), +0x248 a
    statement for multi_assign_proc (cg_assign's cg_asn_t), +0x294.

  Global (A5 loaded): cg_tree_$needs_lib_support, movewlx,
  cg_tree_$is_decomposable_const_mul, walker, tree_walk; the other
  module-level routines do not load A5 and are internal (the
  assertions and assert_const_mul_candidate have no frame,
  docs/rev889-patterns.md 16).  The routines nested in do_const_mul,
  walker and tree_walk take their parent's frame from their dynamic
  link (docs/rev889-patterns.md 25), but const_mul and push, which
  take it in A1 (const_mul calls itself).

  The nodes are read through cg.ins.pas's tree view (cg_tree_t) and
  il.ins.pas's views by offset.  emit's generic instructions as numbers
  (docs/questions.md 77, 83): 0 move, 1 add, 2 subtract, 7, 11 neg, 13
  a shift (x 3 left), 21 branch, 32 a label, 42..44 and 47 the 68881's
  (a conditional branch, add and subtract, compare).

  TODO(pascal) generate and the 21 routines nested in it (bit_test_proc
  .. restore_alloc_temps above, 0x100660..0x1047CA and 0x10484E,
  0x3B38 bytes) are not translated yet: generate is declared extern
  below so that walker compiles.  The module's tables at +0x58, +0x70
  and +0x158 and its operands from +0x1B8, which only generate's
  routines read, are not declared yet.

  Not known from the original: the names of the module's variables
  (cg.ins.pas's), the locals and the parameters; the IL nodes' fields
  (by offset). }
module cg_tree;

%include 'us/us/ins/ubase.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/delay.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { The fast math library's routine for a builtin function (+0): ok, its
    index in std_lib_rtns (the double's routine follows the single's). }
  tree_math_t = record
    ok: boolean;                        { +0 }
    rtn: integer;                       { +2 }
  end;

var
  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, its width in bytes. }
  delay_378: extern array [0..15] of integer;

  tree_math: array [0..21] of tree_math_t := [
    [false, 115], [true, 115], [true, 117], [true, 119], [true, 127],
    [true, 129], [true, 125], [true, 121], [true, 123], [false, 115],
    [true, 145], [true, 145], [false, 115], [false, 115], [false, 115],
    [false, 115], [false, 115], [false, 115], [true, 135], [true, 137],
    [true, 139], [false, 115]];         { +0 }

define
  cg_zero_ads;                          { +0x188 }
  cg_null_ads := [0, 31, 31, 0, 0, 0, 0, 0];  { +0x1A0 }
  cg_tree_1b4;                          { +0x1B4 }
  cg_tree_$needs_lib_support, cg_tree_$is_decomposable_const_mul, walker,
  tree_walk;

{ DFETCH - v's low len bytes, sign-extended when sgn (kfold.pas; delay.pas
  declares it the same way). }
function dfetch(
    v: integer32;
    len: integer;
    sgn: boolean): integer32; options(val_param); extern;

{ TODO(pascal) generate is not translated yet (cg_tree 0x10484E, internal:
  no A5 load; walker its only caller). }
procedure generate(
    n: il_$node_ptr_t); options(val_param); extern;


{ assert_is_a_tree - n is a tree node (143, 138, 137).

  0x0FEFD0, 0x2C bytes, no frame: n at (4,SP). }

function assert_is_a_tree(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_a_tree := false
  else
    assert_is_a_tree := (n^.kind = 143) or (n^.kind = 138) or
        (n^.kind = 137);
end;

{ assert_is_f_math_op - n is a builtin math function (operator 41) of
  function fn (desc.w6).

  0x0FEFFC, 0x38 bytes. }

function assert_is_f_math_op(
    n: il_$node_ptr_t;
    fn: integer): boolean; options(val_param); internal;
begin
  if assert_is_a_tree(n) and (cg_tree_ptr_t(n)^.op = 41) then
    assert_is_f_math_op := cg_tree_ptr_t(n)^.desc.w6 = fn
  else
    assert_is_f_math_op := false;
end;

{ cg_tree_$fpa1_expon_inquire - the FPA1 routines of a power (operator
  42) of a single or double (desc.rlen 6 or 7) to an exponent of up to
  4 bytes (desc.w8) or wider: a (0 or 17, the exponent's register), b
  and c.

  0x0FF034, 0x76 bytes, no A5 load: the class compared unsigned
  (`bhi').

  Not known from the original:
  - what b and c are (needs_lib_support takes c as the library
    routine). }

procedure cg_tree_$fpa1_expon_inquire(
    n: il_$node_ptr_t;
    out a: integer;
    out b: integer;
    out c: integer); options(val_param); internal;
begin
  if cg_tree_ptr_t(n)^.desc.rlen = 6 then begin
    if cg_tree_ptr_t(n)^.desc.w8 <= 4 then begin
      a := 0;
      b := 94;
      c := 97;
    end
    else begin
      a := 17;
      b := 96;
      c := 96;
    end;
  end
  else if cg_tree_ptr_t(n)^.desc.w8 <= 4 then begin
    a := 0;
    b := 98;
    c := 98;
  end
  else begin
    a := 17;
    b := 100;
    c := 99;
  end;
end;

{ cg_tree_$needs_lib_support - whether floating tree t needs a library
  routine, rtn its index in std_lib_rtns (176 none): 21 the extended
  ones (classes 8 and 12, function 15, conversions of them), 18 the
  general floating routine; with -CPU MATHLIB (cpu 9) the fast math
  library's (tree_math, the double's next), 143 and 144 a conversion
  to a long, 131..134 a power; with FPA1 fpa1_expon_inquire's.

  0x0FF0AA, 0x340 bytes: the conversions' and arithmetic's operator
  set after the code (0x0FF3EC: 34..42, 51..53, 57) tested without a
  floating unit (cpu 2, 4, 8, 9, 10: `andi.w #0x714' of the cpu word);
  the functions' sets as longword masks (0x003FFFFF the table's
  entries, 0x36FF [0..7, 9, 10, 12, 13] those inline, 0x36DF the
  160's); cpu 1 (PEB), 2, 8 (FPA1), 10 bits of 0x2C3670 and 0x2C3671;
  the result `rtn <> 176'. }

function cg_tree_$needs_lib_support;
var
  n: cg_tree_ptr_t;
  fn: integer;
  a: integer;
  b: integer;
begin
  n := cg_tree_ptr_t(t);
  rtn := 176;
  if (n^.desc.rlen = 12) or (n^.desc.rlen = 8) or
      assert_is_f_math_op(t, 15) then
    rtn := 21
  else if (n^.op = 39) and ((n^.desc.w6 = 12) or (n^.desc.w6 = 8)) then
    rtn := 21
  else if (n^.op = 40) and ((n^.desc.w6 = 12) or (n^.desc.w6 = 8)) then
    rtn := 21
  else if (cargs_$options.cpu * [2, 4, 8, 9, 10] = []) and
      (n^.op in [34..42, 51..53, 57]) then
    rtn := 18
  else if 9 in cargs_$options.cpu then begin
    fn := n^.desc.w6;
    if n^.op = 41 then begin
      if not ((fn = 13) or (fn = 12) or (fn = 9) or (fn = 0)) and
          (fn in [0..21]) and tree_math[fn].ok then begin
        rtn := tree_math[fn].rtn;
        if n^.desc.rlen = 7 then
          if not ((fn = 11) or (fn = 10)) then
            rtn := rtn + 1;
      end
      else if not (fn in [0..7, 9, 10, 12, 13]) then
        rtn := 18;
    end
    else if n^.op = 39 then begin
      if n^.desc.rlen = 4 then begin
        if (n^.desc.flags & 16#4000) <> 0 then
          rtn := 143
        else
          rtn := 144;
      end
      else if ((n^.desc.flags & 16#4000) = 0) and (fn = 4) and
          ((n^.desc.rlen = 7) or (n^.desc.rlen = 6)) then
        rtn := 18
      else if n^.desc.rlen < 4 then
        rtn := 18;
    end
    else if n^.op = 42 then begin
      if n^.desc.rlen = 6 then begin
        if n^.desc.w8 <= 4 then
          rtn := 131
        else
          rtn := 132;
      end
      else if n^.desc.w8 <= 4 then
        rtn := 133
      else
        rtn := 134;
    end;
  end
  else if n^.op = 42 then begin
    if 8 in cargs_$options.cpu then
      cg_tree_$fpa1_expon_inquire(t, a, b, rtn)
    else
      rtn := 18;
  end
  else begin
    fn := n^.desc.w6;
    if ((n^.op = 39) and ((n^.desc.flags & 16#4000) = 0) and (fn = 4)) or
        (((fn = 7) or (fn = 6)) and
         ((n^.desc.rlen = 4) or (n^.desc.rlen = 2))) then
      rtn := 18
    else if (n^.op = 39) and (10 in cargs_$options.cpu) and
        ((n^.desc.rlen = 4) or (n^.desc.rlen = 2)) then
      rtn := 18
    else if n^.op = 41 then begin
      if 10 in cargs_$options.cpu then
        rtn := 18
      else if (1 in cargs_$options.cpu) and (fn <> 0) then
        rtn := 18
      else if (8 in cargs_$options.cpu) and
          not ((fn = 13) or (fn = 12) or (fn = 9) or (fn = 0)) then
        rtn := 18
      else if (2 in cargs_$options.cpu) and
          not (fn in [0..4, 6, 7, 9, 10, 12, 13]) then
        rtn := 18
      else if not (fn in [0..7, 9, 10, 12, 13]) then
        rtn := 18;
    end;
  end;
  cg_tree_$needs_lib_support := rtn <> 176;
end;

{ cg_tree_$prefers_inline_float - whether the floating arithmetic tree
  n (operators 34..37 of class 6 or 7) is done inline by a floating
  unit (cpu 2, 4, 8, 9, 10): not when, without FPA1 or MATHLIB (cpu 8,
  9), an operand tree needs the general library routine (18); the
  floating stack purged first when inline.

  0x0FF3F4, 0xF8 bytes, no A5 load: the operands from the last
  (`dbf'); needs_lib_support given a frame copy of the operand. }

function cg_tree_$prefers_inline_float(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  lib: boolean;
  i: integer;
  m: il_$node_ptr_t;
  rtn: integer;
begin
  r := false;
  if ((n^.kind = 138) or (n^.kind = 137)) and
      ((cg_tree_ptr_t(n)^.op = 34) or (cg_tree_ptr_t(n)^.op = 35) or
       (cg_tree_ptr_t(n)^.op = 37) or (cg_tree_ptr_t(n)^.op = 36)) then
    if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
      if (cg_tree_ptr_t(n)^.desc.rlen = 7) or
          (cg_tree_ptr_t(n)^.desc.rlen = 6) then begin
        lib := r;
        r := true;
        if cargs_$options.cpu * [8, 9] = [] then begin
          for i := cg_tree_ptr_t(n)^.count downto 1 do begin
            m := cg_tree_ptr_t(n)^.opnd[i];
            if (m^.kind = 138) or (m^.kind = 137) then
              if (cg_tree_ptr_t(m)^.desc.rlen = 7) or
                  (cg_tree_ptr_t(m)^.desc.rlen = 6) then
                if cg_tree_$needs_lib_support(m, rtn) then
                  if rtn = 18 then begin
                    lib := true;
                    exit;
                  end;
          end;
          if lib then
            r := false;
        end;
      end;
  if r and (cg_fp_count <> 0) then
    purge_fp;
  cg_tree_$prefers_inline_float := r;
end;

{ cg_tree_$spill_fp_reg_contents_before_fpp - n's value of class size,
  when a floating register is its home and holds it, stored to n's
  memory (not for constants).

  0x0FF4EC, 0xAC bytes, no A5 load: the constants' kinds' set after
  the code (0x0FF598: 77..90, 92, 93, 101, 156, 176, 198, 200). }

procedure cg_tree_$spill_fp_reg_contents_before_fpp(
    n: il_$node_ptr_t;
    size: integer); options(val_param); internal;
var
  v: codegen_$uads_t;
  m: codegen_$uads_t;
  r: integer;
begin
  r := chk_assign(n, size);
  if not (n^.kind in [77..90, 92..93, 101, 156, 176, 198, 200]) then
    if r in [16..23] then
      if peek(n, size) = r then begin
        address(n, size, v);
        address(n, 0, m);
        emit(0, size, m, v, 0);
        unlock(v);
      end;
end;

{ cg_tree_$adjust_before_round - real n (by address) rounded to the
  nearest integer's way (0.5 added away from zero) before a conversion
  that truncates, of class size, its operand in a: a constant folded
  (rlcontk, dpcontk), else with the 68881 (cpu 4: bug_check without)
  a compare with 0.0 and a branch to an add or a subtract of 0.5.

  0x0FF5B2, 0x254 bytes, no A5 load: the constant's arithmetic by `jsr
  fpp_$' (0x0074 0xFF34 a test, 0x0088 add and 0x0090 subtract the
  double 0.5, 0x0080 the store: docs/rev889-patterns.md 19); the
  constants 0.0 and 0.5 after the code (0x0FF83C, 0x0FF844) passed to
  rlcontk; the 68881's instructions (47 compare, 42 a branch, x 12; 44
  add, 43 subtract, x 6) pushed with their size as one longword.

  Not known from the original:
  - the 68881's instructions' and condition's names. }

procedure cg_tree_$adjust_before_round(
    in out n: il_$node_ptr_t;
    size: integer;
    out a: codegen_$uads_t); options(val_param); internal;
var
  d: double;
  zero: codegen_$uads_t;
  l2: codegen_$uads_t;
  l1: codegen_$uads_t;
  half: codegen_$uads_t;
begin
  if not (4 in cargs_$options.cpu) then
    bug_check('cg_tree_$adjust_before_round needs m881_hw support!%.');
  if (n^.kind = 89) or (n^.kind = 88) then begin
    d := n^.real_value;
    if d >= 0.0 then
      d := d + 0.5
    else
      d := d - 0.5;
    if n^.kind = 88 then
      n := rlcontk(d)
    else
      n := dpcontk(d);
    address(n, size, a);
  end
  else begin
    address(rlcontk(0.0), 6, zero);
    load_modifiable(n, size, a);
    kill_register(a.f2);
    address(rlcontk(0.5), 6, half);
    emit(47, 6, a, zero, 6);
    release(zero);
    address(templabel, 0, l1);
    emit(42, 5, l1, cg_null_ads, 12);
    emit(44, 6, a, half, 6);
    address(templabel, 0, l2);
    emit(21, 5, l2, cg_null_ads, 0);
    emit(32, 5, l1, cg_null_ads, 0);
    release(l1);
    emit(43, 6, a, half, 6);
    release(half);
    emit(32, 5, l2, cg_null_ads, 0);
    release(l2);
  end;
end;

{ cg_tree_$call_fast_math_lib - floating tree n by its library routine
  (needs_lib_support): the operand (opnd[1], rounded first for function
  11) in FP0 (16), a second operand (function 8, a power) in D0 or FP1
  (17), the call (gen_call of std_lib_rtns), the result in D0 for
  function 11 of up to 4 bytes or a conversion (39), else in FP0, moved
  to n's home register when it has one.

  0x0FF84C, 0x3DE bytes, no A5 load: needs_lib_support's result not
  used; n's slot passed by address; cg_addr_locks[0] (0x355098) counted
  up when D0 holds the second operand; an operand already in FP0
  compared with 0.0 (0x0FF83C) for the condition codes. }

procedure cg_tree_$call_fast_math_lib(
    n: il_$node_ptr_t); options(val_param); internal;
var
  z: codegen_$uads_t;
  r2: codegen_$uads_t;
  a: codegen_$uads_t;
  rtn: integer;
  sz2: integer;
  sz1: integer;
  t: cg_tree_ptr_t;
  two: boolean;
  reg: integer;
  home: integer;
begin
  t := cg_tree_ptr_t(n);
  if cg_fp_count <> 0 then
    purge_fp;
  discard(cg_tree_$needs_lib_support(n, rtn));
  if assert_is_f_math_op(n, 8) then
    two := true
  else if t^.op = 42 then
    two := true
  else
    two := false;
  if (t^.op = 42) or (t^.op = 39) then
    sz1 := t^.desc.w6
  else if assert_is_f_math_op(n, 11) then
    sz1 := t^.desc.w8
  else
    sz1 := t^.desc.rlen;
  if two then
    if t^.op = 42 then
      sz2 := t^.desc.w8
    else
      sz2 := t^.desc.rlen;
  home := chk_assign(n, t^.desc.rlen);
  r2 := cg_null_ads;
  if two then begin
    if (rtn = 133) or (rtn = 131) then
      reg := 0
    else
      reg := 17;
    if peek(t^.opnd[2], sz2) <> reg then begin
      address(t^.opnd[2], sz2, a);
      kill_register(reg);
      address_reg(reg, r2);
      emit(0, sz2, r2, a, 0);
      unlock(a);
      if reg = 0 then
        cg_addr_locks[0] := cg_addr_locks[0] + 1;
    end;
  end;
  if assert_is_f_math_op(n, 11) then
    cg_tree_$adjust_before_round(t^.opnd[1], sz1, a)
  else
    address(t^.opnd[1], sz1, a);
  if two then
    if (rtn = 133) or (rtn = 131) then
      unlock(r2);
  if (a.f1 = 13) and (a.f2 = 16) then begin
    address(rlcontk(0.0), 6, z);
    emit(47, 6, a, z, 6);
    release(z);
  end
  else begin
    address_reg(16, r2);
    emit(0, sz1, r2, a, 0);
  end;
  unlock(a);
  gen_call(nil, std_lib_rtns[rtn]);
  if assert_is_f_math_op(n, 11) and (t^.desc.rlen <= 4) then begin
    kill_register(0);
    address_reg(16, a);
    address_reg(0, r2);
    emit(0, 7, r2, a, t^.desc.rlen);
    setresult(0, n, t^.desc.rlen);
    setobjcache(n, 0);
  end
  else if t^.op = 39 then begin
    if home = 31 then begin
      setresult(0, n, 4);
      setobjcache(n, 0);
    end
    else begin
      kill_register(0);
      address_reg(0, a);
      address_reg(home, r2);
      emit(0, t^.desc.rlen, r2, a, 0);
      setresult(home, n, 4);
      setobjcache(n, home);
    end;
  end
  else if home = 31 then begin
    setresult(16, n, t^.desc.rlen);
    setobjcache(n, 16);
  end
  else begin
    kill_register(16);
    address_reg(16, a);
    address_reg(home, r2);
    emit(0, t^.desc.rlen, r2, a, 0);
    setresult(home, n, t^.desc.rlen);
    setobjcache(n, home);
  end;
end;

{ assert_const_mul_candidate - whether constant c may be multiplied by
  as shifts and adds (neg: by its negation).

  0x0FFC2A, 0x2C bytes, no frame: c and neg by address at (4,SP) and
  (8,SP).  For a negative c the negation is formed but c itself is
  tested again (`tst.l (A0); bpl'), which fails: negative constants
  are never candidates (kept as the image has it). }

function assert_const_mul_candidate(
    in out c: integer32;
    out neg: boolean): boolean; internal;
var
  ok: boolean;
  m: integer32;
begin
  ok := true;
  neg := false;
  if c > 0 then
    neg := false
  else if c < 0 then begin
    m := -c;
    if c >= 0 then begin
      neg := ok;
      c := m;
    end
    else
      ok := false;
  end
  else
    ok := false;
  assert_const_mul_candidate := ok;
end;

{ movewlx - operand a: node n's word as a long in a register (signed:
  sign-extended, else zero-extended through a cleared register); a
  constant's value as a long (re-made by dfetch when out of a word's
  range), loaded when load, else immediate.

  0x0FFC56, 0x1F6 bytes: the constant kinds' set after the code
  (0x0FFE4C: 77..87, 101, 200); a signed operand's registers relocked
  (up to 12, `bhi') across get_temp_register; the sign extension by
  s_extend(a, 2, 4) pushed as one longword. }

procedure movewlx(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t;
    signed: boolean;
    load: boolean); options(val_param);
var
  t: codegen_$uads_t;
  z: codegen_$uads_t;
  v: integer32;
begin
  if n^.kind in [77..87, 101, 200] then begin
    v := n^.xl[2];
    if signed then begin
      if (v < -32768) or (v > 32767) then
        n := smcontk(80, dfetch(v, 2, true));
    end
    else if (v < 0) or (v > 65535) then
      n := smcontk(83, dfetch(v, 2, false));
    if load then
      load_operand(n, 4, a)
    else
      anyconst(n^.xl[2], 4, a);
  end
  else begin
    address(n, 2, t);
    if signed then begin
      unlock(t);
      get_temp_register(n, 4, a);
      if t.f2 <= 12 then
        cg_addr_locks[t.f2] := cg_addr_locks[t.f2] + 1;
      if t.f3 <= 12 then
        cg_addr_locks[t.f3] := cg_addr_locks[t.f3] + 1;
    end
    else
      get_temp_register(n, 4, a);
    release(t);
    kill_register(a.f2);
    a.x := 0;
    if signed then begin
      emit(0, 2, a, t, 0);
      s_extend(a, 2, 4);
    end
    else begin
      anyconst(0, 4, z);
      emit(0, 4, a, z, 0);
      emit(0, 2, a, t, 0);
      unlock(z);
    end;
    setresult(a.f2, n, 2);
  end;
end;

{ do_const_mul - whether tree n's multiplication by its constant
  operand (opnd[2]) is done by shifts and adds of no more than 40
  bytes, and its code generated unless test is 1: const_mul
  decomposes the constant into a stack of shifts (1) and adds (0, flag
  a subtraction) that genmul costs (gen false) and emits unless test.

  0x1005AC, 0x72 bytes, no A5 load: the stack of 50 entries from -408
  (8 bytes: the operation, the value, the flag), its top at -464, the
  cost at -466, neg at -468, the constant at -460; two operands at -432
  and -456 (24 bytes apart).

  Not known from the original:
  - test's type (a word: 1 from is_decomposable, 0 from mul_proc). }

function do_const_mul(
    n: cg_tree_ptr_t;
    test: integer): boolean; options(val_param); internal;
type
  ent_t = record
    op: integer;                        { +0 }
    val: integer32;                     { +2 }
    flag: boolean;                      { +6 }
  end;
var
  stack: array [0..49] of ent_t;
  t: codegen_$uads_t;
  acc: codegen_$uads_t;
  c: integer32;
  save: integer;
  sp: integer;
  cost: integer;
  neg: boolean;

  { stkinit - the stack emptied: every entry an add (2) without its
    flag; no cost.

    0x0FFE66, 0x3C bytes: the parent's frame from the dynamic link; a
    `for' of 50 (`dbf'). }

  procedure stkinit;
  var
    k: integer;
  begin
    for k := 0 to 49 do begin
      stack[k].flag := false;
      stack[k].op := 2;
    end;
    sp := -1;
    cost := 0;
  end;

  { push - operation op of value val pushed.

    0x0FFEA2, 0x38 bytes: the parent's frame in A1. }

  procedure push(
      op: integer;
      val: integer32); options(val_param);
  begin
    sp := sp + 1;
    stack[sp].op := op;
    stack[sp].val := val;
    stack[sp].flag := false;
  end;

  { const_mul - c decomposed: 1 an add; else a shift to its highest bit
    (hb) and the rest, or, for a run of ones at the top (at least two
    below hb, consecutivebits), a shift to hb + 1 less the rest
    (the rest's entries' flags reversed: subtractions).

    0x0FFF22, 0x108 bytes: the parent's frame in A1, passed on; the
    highest bit by a `for' from 31 down (`dbf'). }

  procedure const_mul(
      c: integer32); options(val_param);
  var
    hb: integer32;
    i: integer;
    rest: integer32;
    s: integer;
    k: integer;

    { consecutivebits - bits n - 1 and n - 2 of v are set (n at least 2).

      0x0FFEDA, 0x48 bytes. }

    function consecutivebits(
        v: integer32;
        n: integer32): boolean; options(val_param);
    begin
      if n >= 2 then
        if (lshft(1, n - 1) & v) > 0 then
          if (lshft(1, n - 2) & v) > 0 then begin
            consecutivebits := true;
            return;
          end;
      consecutivebits := false;
    end;

  begin
    if c = 1 then
      push(0, c)
    else begin
      hb := 0;
      for i := 31 downto 0 do
        if (lshft(1, i) & c) <> 0 then begin
          hb := i;
          exit;
        end;
      if hb <> 0 then
        if ((lshft(1, hb - 1) & c) <> 0) and (hb <= 30) and
            consecutivebits(c, hb) then begin
          rest := lshft(1, hb + 1) - c;
          if c = rest then begin
            push(1, hb);
            const_mul(c - lshft(1, hb));
          end
          else begin
            push(1, hb + 1);
            s := sp;
            const_mul(rest);
            for k := s + 1 to sp do
              stack[k].flag := not stack[k].flag;
          end;
        end
        else begin
          c := c - lshft(1, hb);
          push(1, hb);
          const_mul(c);
        end;
    end;
  end;

  { genmul - the stack's code on n's first operand (gen), or its cost
    (3 a move, add or negate, 3 a shift of 1, 4 a shift of up to 8):
    acc the product (the operand as a long, movewlx, or load_result),
    t the operand kept for the adds (a register already holding it when
    it is one shift and one add, inquire's).

    0x100148, 0x464 bytes: the parent's frame from the dynamic link; the
    entries from the top down, their operation by a compare chain;
    emit's 11 a negation. }

  procedure genmul(
      n: cg_tree_ptr_t;
      gen: boolean); options(val_param);
  var
    same: boolean;
    prev: integer;
    i: integer;
    sh: integer;

    { doshft - a shifted left by n bits in steps of up to 8 (a register
      holding the count: at once), or the cost.

      0x10002A, 0x11E bytes: a copied (a value parameter); genmul's
      frame from the dynamic link, do_const_mul's from it; a shift of 1
      as an add of the register to itself (`move.l (SP),-(SP)' for the
      second operand, docs/rev889-patterns.md 69); t's register
      forgotten when a is it. }

    procedure doshft(
        a: codegen_$uads_t;
        n: integer32;
        size: integer); options(val_param);
    var
      cnt: codegen_$uads_t;
    begin
      while n > 0 do begin
        if n = 1 then begin
          if gen then begin
            emit(1, size, a, a, 0);
            if a.f2 = t.f2 then
              kill_register(a.f2);
          end
          else
            cost := cost + 3;
          exit;
        end;
        if gen then begin
          anyconst(n, 1, cnt);
          if cnt.f1 = 1 then
            n := 0
          else if n >= 8 then
            anyconst(8, 1, cnt)
          else
            anyconst(n, 1, cnt);
          emit(13, size, a, cnt, 3);
          if a.f2 = t.f2 then
            kill_register(a.f2);
          unlock(cnt);
        end
        else
          cost := cost + 4;
        if n <= 8 then
          exit;
        n := n - 8;
      end;
    end;

  begin
    same := false;
    prev := 0;
    if gen then begin
      if n^.desc.w6 < n^.desc.rlen then begin
        movewlx(n^.opnd[1], acc, (n^.desc.flags & 16#4000) <> 0, true);
        setresult(acc.f2, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        save := n^.desc.rlen;
        n^.desc.rlen := n^.desc.w6;
        load_result(il_$node_ptr_t(n), -1, acc);
        n^.desc.rlen := save;
      end;
      cg_addr_regs[acc.f2].size := n^.desc.rlen;
      if (sp = 1) and (stack[1].op = 0) and (stack[0].op = 1) then begin
        inquire(n^.opnd[1], n^.desc.rlen, t);
        if t.f1 <> 0 then
          same := true
        else
          get_temp_register(n^.opnd[1], n^.desc.rlen, t);
      end
      else if (sp = 0) and (stack[0].op = 1) then
        t := cg_null_ads
      else
        get_temp_register(n^.opnd[1], n^.desc.rlen, t);
    end;

    i := sp;
    while i >= 0 do begin
      case stack[i].op of
        0:
          if i = sp then begin
            if gen then begin
              if (t.f2 <> 31) and not same then begin
                emit(0, n^.desc.rlen, t, acc, 0);
                kill_register(t.f2);
              end;
            end
            else
              cost := cost + 3;
            if (i = 1) and stack[i].flag and (stack[i - 1].op = 1) then begin
              i := i - 1;
              doshft(acc, stack[i].val, n^.desc.rlen);
              if gen then
                emit(2, n^.desc.rlen, acc, t, 0)
              else
                cost := cost + 3;
            end
            else if same then begin
              i := i - 1;
              doshft(acc, stack[i].val, n^.desc.rlen);
              if gen then
                emit(1, n^.desc.rlen, acc, t, 0)
              else
                cost := cost + 3;
            end
            else if stack[i].flag then begin
              if gen then
                emit(11, n^.desc.rlen, acc, cg_null_ads, 0)
              else
                cost := cost + 3;
            end;
          end;
        1:
          if i = sp then begin
            if gen then begin
              same := false;
              if (sp >= 1) and (stack[sp].op = 1) and
                  (stack[sp - 1].op = 1) then
                same := true
              else if sp = 0 then
                same := true
              else
                emit(0, n^.desc.rlen, t, acc, 0);
            end
            else
              cost := cost + 3;
            if same then
              doshft(acc, stack[i].val, n^.desc.rlen)
            else
              doshft(t, stack[i].val, n^.desc.rlen);
            if gen then begin
              if t.f2 <> 31 then
                if same then begin
                  emit(0, n^.desc.rlen, t, acc, 0);
                  kill_register(t.f2);
                end
                else
                  emit(0, n^.desc.rlen, acc, t, 0);
            end
            else
              cost := cost + 3;
            if stack[i].flag then
              if gen then
                emit(11, n^.desc.rlen, acc, cg_null_ads, 0)
              else
                cost := cost + 3;
          end
          else begin
            if stack[prev].op = 1 then
              sh := stack[i].val - stack[prev].val
            else
              sh := stack[i].val;
            doshft(t, sh, n^.desc.rlen);
            if gen then begin
              if stack[i].flag then
                emit(2, n^.desc.rlen, acc, t, 0)
              else
                emit(1, n^.desc.rlen, acc, t, 0);
            end
            else
              cost := cost + 3;
          end;
        otherwise ;
      end;
      prev := i;
      i := i - 1;
    end;
    if neg then
      if gen then
        emit(11, n^.desc.rlen, acc, cg_null_ads, 0)
      else
        cost := cost + 3;
    if gen then begin
      unlock(acc);
      unlock(t);
    end;
  end;

begin
  c := n^.opnd[2]^.xl[2];
  if not assert_const_mul_candidate(c, neg) then begin
    do_const_mul := false;
    return;
  end;
  stkinit;
  const_mul(c);
  genmul(n, false);
  if cost > 40 then begin
    do_const_mul := false;
    return;
  end;
  if test = 0 then
    genmul(n, true);
  do_const_mul := true;
end;

{ cg_tree_$is_decomposable_const_mul - n is a multiplication (operator
  3) do_const_mul would do by shifts and adds.

  0x10061E, 0x42 bytes. }

function cg_tree_$is_decomposable_const_mul;
begin
  if assert_is_a_tree(n) and (cg_tree_ptr_t(n)^.op = 3) then
    cg_tree_$is_decomposable_const_mul := do_const_mul(cg_tree_ptr_t(n), 1)
  else
    cg_tree_$is_decomposable_const_mul := false;
end;

{ walker - tree n's operands evaluated (in reverse for the operators of
  the set: the right one first), then its own code (generate), and the
  register stamp counted up.  Not for operators 15, 16.

  0x108484, 0x9A bytes: the operators' set after the code (0x10851E:
  2, 4..6, 11, 15, 16, 21, 35, 37); the flag first (-4) passed by
  address; cg_addr_2ba (0x355272) counted up. }

procedure walker;
var
  first: boolean;
  i: integer;

  { evaluate_subtree - operand i of t: down through its references
    (146, 147; the first operand's cached in the register its parent
    is, setobjcache), on the first pass cached in t's register when it
    holds the destination (cg_assign's flags: +6 bit 13 the right
    operand, bit 14 the left; else the first operand evaluated), then
    walked: a tree by walker, the others by tree_walk.

    0x10838E, 0xF6 bytes: t and first passed (no frame link); the cache
    tested again to clear first when the register took the operand. }

  procedure evaluate_subtree(
      t: il_$node_ptr_t;
      i: integer;
      in out first: boolean); options(val_param);
  var
    p: il_$node_ptr_t;
    r: integer;
  begin
    p := cg_tree_ptr_t(t)^.opnd[i];
    if p = nil then
      return;
    r := getobjcache(t);
    while (p^.kind = 146) or (p^.kind = 147) do begin
      if i = 1 then
        setobjcache(p, r);
      p := p^.xp[6];
      r := getobjcache(p);
    end;
    if cg_pass = 1 then begin
      if (t^.xw[3] & 16#2000) <> 0 then begin
        if i = 2 then
          setobjcache(p, r);
      end
      else if (t^.xw[3] & 16#4000) <> 0 then begin
        if i = 1 then
          setobjcache(p, r);
      end
      else if first then
        setobjcache(p, r);
      if getobjcache(p) = r then
        first := false;
    end;
    case p^.kind of
      137:
        walker(p);
      164, 145, 189, 190, 152:
        tree_walk(p);
      otherwise ;
    end;
  end;

begin
  if (cg_tree_ptr_t(n)^.op <> 15) and (cg_tree_ptr_t(n)^.op <> 16) then begin
    first := true;
    if cg_tree_ptr_t(n)^.op in [2, 4..6, 11, 15..16, 21, 35, 37] then
      for i := cg_tree_ptr_t(n)^.count downto 1 do
        evaluate_subtree(n, i, first)
    else
      for i := 1 to cg_tree_ptr_t(n)^.count do
        evaluate_subtree(n, i, first);
  end;
  generate(n);
  cg_addr_2ba := cg_addr_2ba + 1;
end;

{ tree_walk - tree n's code: down through its references (146, 147),
  then by kind: trees by walker; an address constant of a static
  variable (195 with +20 4, 163 with +20's byte 4) of a 110 whose class
  (+44 bits 7..4) is 1 replaced by its +40; an indexing (145) or 164
  node's two operands; a temporary's (152) node; a common
  subexpression (190: its tree, 189: its use) evaluated once into its
  register (loadcse) or a temporary (allocate_temp), else found in the
  register (cgerr 3 when it is not).

  0x1085B4, 0x376 bytes: cg_addr_2ba counted up first; the size at -54
  for loadcse; the statement's word at +43 (`andi.l #0xFFFF00' of the
  longword at +42) and at_backend_506 (0x35645C); the class table
  0x169968 (delay_378) for the temporary's size.

  Not known from the original:
  - the statement's field at +43, a 189's tree's +18 flag. }

procedure tree_walk;
var
  p: il_$node_ptr_t;
  t: il_$node_ptr_t;
  m: il_$node_ptr_t;
  r: integer;
  size: integer;

  { loadcse - register r loaded with n's value (of tree_walk's size) and
    made to hold it.

    0x108524, 0x90 bytes: tree_walk's frame from the dynamic link. }

  procedure loadcse(
      r: integer;
      n: il_$node_ptr_t); options(val_param);
  var
    ra: codegen_$uads_t;
    a: codegen_$uads_t;
  begin
    if cg_fp_count <> 0 then
      purge_fp;
    address_reg(r, ra);
    kill_register(r);
    address(n, size, a);
    unlock(a);
    emit(0, size, ra, a, size);
    setresult(r, n, size);
  end;

begin
  cg_addr_2ba := cg_addr_2ba + 1;
  p := n;
  while (p^.kind = 146) or (p^.kind = 147) do
    p := p^.xp[6];
  case p^.kind of
    143, 137:
      walker(p);
    195:
      if p^.xw[10] = 4 then begin
        m := p^.xp[3];
        if m^.kind = 110 then
          if rshft(ord(m^.xc[44]) & 16#F0, 4) = 1 then
            if m^.xp[10] <> nil then
              p^.xp[3] := m^.xp[10];
      end;
    163:
      if ord(p^.xc[20]) = 4 then begin
        m := p^.xp[2];
        if m^.kind = 110 then
          if rshft(ord(m^.xc[44]) & 16#F0, 4) = 1 then
            if m^.xp[10] <> nil then
              p^.xp[2] := m^.xp[10];
      end;
    145: begin
      tree_walk(p^.xp[6]);
      tree_walk(p^.xp[9]);
    end;
    164: begin
      tree_walk(p^.xp[5]);
      tree_walk(p^.xp[6]);
    end;
    152:
      tree_walk(p^.xp[4]);
    190: begin
      t := p^.xp[1];
      size := t^.xw[12];
      r := chk_assign(p^.xp[1], size);
      if t^.kind = 138 then begin
        if r = 31 then
          tree_walk(t)
        else if peek(t, size) = r then
          cg_addr_cache[r].live := true
        else if not cg_addr_cache[r].live then
          cgerr(3, cg_line, p);
      end
      else if (t^.xp[3] = cg_stmt) or
          ((rshft(cg_stmt^.xl2[10] & 16#FFFF00, 8) = 0) and
           (t^.xp[3] <> nil)) then begin
        tree_walk(t);
        if r <> 31 then begin
          if peek(p^.xp[1], size) <> r then
            loadcse(r, p^.xp[1]);
          cg_addr_cache[r].live := true;
        end;
      end
      else if r = 31 then
        if t^.xp[10]^.kind <> 152 then
          t^.xp[10] := allocate_temp(delay_378[size], true, t^.xp[10]);
    end;
    189: begin
      t := p^.xp[5];
      size := t^.xw[12];
      r := chk_assign(t, size);
      if t^.kind = 138 then begin
        if r <> 31 then
          if (peek(t, size) <> r) or not cg_addr_cache[r].live then
            cgerr(3, cg_line, p);
      end
      else begin
        if (r = 31) or (t^.xw[9] < 0) then
          if t^.xp[10]^.kind <> 152 then
            if at_backend_506 then
              if t^.xw[9] < 0 then
                t^.xp[10] := allocate_temp(delay_378[size], true,
                    t^.xp[10]);
        if r = 31 then begin
          if t^.xp[3] = p^.xp[6] then
            tree_walk(t);
        end
        else if t^.xp[3] <> p^.xp[6] then begin
          if cg_addr_cache[r].live then
            setresult(r, t, size)
          else
            cgerr(3, cg_line, p);
        end
        else begin
          tree_walk(t);
          if peek(t, size) <> r then
            loadcse(r, t);
          cg_addr_cache[r].live := true;
        end;
      end;
    end;
    otherwise ;
  end;
end;
