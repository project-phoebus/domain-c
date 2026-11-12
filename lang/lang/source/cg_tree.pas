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
    routines by builtin function (tree_math: 22 entries of a flag byte
    and a std_lib index, .rwdi), +0x58 the PEB's operand (peb_ads; .rwdi:
    f1 11, f2 and f3 31, f5 5), +0x70 the 68881's instructions by
    builtin function (tree_fn_inst, 24 words), +0xA0 emit's
    instructions by operator (tree_op_inst, 92 words), +0x158 the FPA's
    routines by builtin function (tree_fn_rtn, 24 words; the three
    tables' runs of equal words are .rwdi repeat records, read as zeros
    at first: docs/questions.md 238; .rwdi leaves each table's last two
    words out), +0x188 cg_zero_ads,
    +0x1A0 cg_null_ads (.rwdi: f2 and f3 31), +0x1B4 cg_tree_1b4, +0x1B8
    .. +0x230 the operands opw, opv (.rwdi: f1 10, f2 and f3 31, f5 4),
    opu, opt, ops, opr (24 bytes apart), +0x248 the statement for
    multi_assign_proc (tree_asn, cg_assign's cg_asn_t), +0x294
    tree_rlen.

  Global (A5 loaded): cg_tree_$needs_lib_support, movewlx,
  cg_tree_$is_decomposable_const_mul, walker, tree_walk; the other
  module-level routines do not load A5 and are internal (the
  assertions and assert_const_mul_candidate have no frame,
  docs/rev889-patterns.md 16).  The routines nested in do_const_mul,
  walker and tree_walk take their parent's frame from their dynamic
  link (docs/rev889-patterns.md 25), but const_mul and push, which
  take it in A1 (const_mul calls itself); of generate's, ldsqr,
  proto_set, switch, f_compare_proc and restore_alloc_temps use their
  parents' frames (switch generate's through f_compare_proc's), the
  others are given the tree.

  The nodes are read through cg.ins.pas's tree view (cg_tree_t) and
  il.ins.pas's views by offset.  emit's generic instructions as numbers
  (docs/questions.md 77, 83): 0 move, 1 add, 2 subtract, 3 and, 4 or, 5
  exclusive or, 7, 11 neg, 12 not, 13 a shift (x 3 left, 2 logical
  right, 0 arithmetic right), 14 bset, 17 btst, 18 cmp, 19 scc, 20 a
  conditional branch (x the condition), 21 branch, 22 lea, 28 dbcc, 32
  a label, 42..47, 49, 56, 60, 69 the 68881's (a conditional branch,
  add, subtract, multiply, divide, compare, negate, fintrz, fscale),
  64..66 the 68020's bit fields.

  generate's floating operators' arms (34 .. 42) are left out of the
  gate (docs/dpc-gaps.md 25: the routine needs more virtual registers
  than dpc numbers) and type-checked by tools/cc_typecheck.sh.

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

  { A double and its two longwords (generate's constant operand of a
    scale: the exponent's bits 30..20 of hi). }
  tree_dbl_t = record
    case integer of
      1: (d: double);
      2: (hi: integer32;                { +0 }
          lo: integer32);               { +4 }
  end;

var
  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, its width in bytes. }
  delay_378: extern array [0..15] of integer;

  { add_node.pas's swap_cc (cc.m68k 0x2C2080, absolute): a comparison's
    condition with its operands swapped. }
  swap_cc: extern array [0..15] of integer;

  tree_math: array [0..21] of tree_math_t := [
    [false, 115], [true, 115], [true, 117], [true, 119], [true, 127],
    [true, 129], [true, 125], [true, 121], [true, 123], [false, 115],
    [true, 145], [true, 145], [false, 115], [false, 115], [false, 115],
    [false, 115], [false, 115], [false, 115], [true, 135], [true, 137],
    [true, 139], [false, 115]];         { +0 }

  { The PEB's operand (+0x58: mode 11, size 5). }
  peb_ads: codegen_$uads_t := [11, 31, 31, 0, 5, 0, 0, 0];  { +0x58 }

  { The 68881's instruction of a builtin math function (+0x70, by
    desc.w6: 33 none). }
  tree_fn_inst: array [0..23] of integer := [50, 51, 52, 53, 54, 55, 57,
      58, 33, 59, 60, 33, 10 of 33, 2 of 0];  { +0x70 }

  { emit's generic instruction of an operator (+0xA0, by op: 1 add, 2
    subtract, 3 and, 4 or, 11 and 12 the unary ones; 33 none). }
  tree_op_inst: array [0..91] of integer := [33, 1, 2, 33, 3 of 33, 11,
      12, 3, 4, 33, 7 of 33, 3, 4, 3, 33, 67 of 33, 2 of 0];  { +0xA0 }

  { The FPA's routine of a builtin math function (+0x158, by desc.w6). }
  tree_fn_rtn: array [0..23] of integer := [104, 106, 108, 110, 112, 114,
      116, 118, 121, 125, 127, 129, 132, 137, 141, 143, 148, 5 of 148,
      2 of 0];
                                        { +0x158 }

  { The operands generate's routines build (+0x1B8 .. +0x230, 24 bytes
    apart): opr the tree's result (load_result's), ops its second
    operand; opv (+0x1D0) a branch's condition operand (.rwdi: mode 10,
    size 4). }
  opw: codegen_$uads_t;                 { +0x1B8 }
  opv: codegen_$uads_t := [10, 31, 31, 0, 4, 0, 0, 0];  { +0x1D0 }
  opu: codegen_$uads_t;                 { +0x1E8 }
  opt: codegen_$uads_t;                 { +0x200 }
  ops: codegen_$uads_t;                 { +0x218 }
  opr: codegen_$uads_t;                 { +0x230 }

  { The statement generate builds for multi_assign_proc (+0x248). }
  tree_asn: cg_asn_t;                   { +0x248 }

  { mul_proc's result class while it multiplies words (+0x294). }
  tree_rlen: integer;                   { +0x294 }

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

{ IS_SCALE_CANDIDATE - a real multiplication or division by a power of
  two (opt_loop.pas 0x0D63D4; g_opt.ins.pas declares it, which cg_tree
  does not open). }
function is_scale_candidate(
    t: univ_ptr): boolean; options(val_param); extern;

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

{ generate - the code of tree n (a 137 operator node, made a 138 value
  node): by its operator (jump table of 74), mostly through its nested
  routines; the operands' temporaries (152 nodes, wrapping the operand at
  +16) taken off first and put back after (restore_alloc_temps) on the
  last pass, else n's descriptor words restored; a value used again
  (w18 < 0) kept in a temporary (get_temp) on the last pass.

  0x10484E, 0x3B38 bytes, no A5 load (walker's): the operators by a jump
  table of 74 (0x104910; 5, 30..33, 51..62, 64, 67, 71 and the others
  cgerr 0); rlen in D7 (the arms read desc.rlen again); the arms end in
  shared tails (unlock and release of opr and ops, setresult of FP0 and
  FP1, fp_temp, fop_proc), written out in each arm; the floating units'
  test `andi.w #0x714' of the cpu word (FPA1 `btst #2' of 0x2C3670,
  MATHLIB #3; the 68881 `btst #6' of 0x2C3671, M020 #5, the 160 #4, PEB
  #3); the result's floating register tested with the longword mask
  0x00FF0000, the classes compared unsigned (`bhi', `bcs'); cg_assign's
  flags in the longword at +4 (`btst #13', `#14'); tree_op_inst by
  `lea (0,A5,D0.w)' of op * 2 and (160,A1).  The scales' constants by
  `jsr fpp_$' (0x0078 1.0 0x00A4 0x0080 the reciprocal; 0x0074 0xFF34 a
  sign test, then `bpl': docs/rev889-patterns.md 19); the `cmpi.w #88'
  of the constant before them is not tested (the moves of the double
  set the condition codes the `bne' takes: the low longword's).

  Not known from the original:
  - the names of the locals (generate's own and those its nested
    routines share: k, the operand put first, and the flags). }

procedure generate(
    n: cg_tree_ptr_t); options(val_param); internal;
var
  t2: il_$node_ptr_t;
  t1: il_$node_ptr_t;
  w8: integer;
  w6: integer;
  k: integer;
  inst: integer;
  save: integer;
  t: il_$node_ptr_t;
  dv: tree_dbl_t;
  e: integer32;
  sz: integer;
  r: integer;
  ea: integer;
  eb: integer;
  ec: integer;
  m: integer;
  inl: boolean;
  inreg: boolean;
  temps: boolean;
  rlen: integer;

  { bit_test_proc - element opnd[1] in the set opnd[2] (operator 11), its
    condition left in desc.w8 (negated when it was negative; reversed
    for 7) and, but for a 143 node, set into a byte register (emit 19,
    an `scc'): a set of up to 4 bytes by a `btst' (emit 17) of the bit
    (the sign bit's elements 7, 15, 31 by a test of the set, emit 18
    with cg_zero_ads; element 0 by a shift right of 1, emit 13's shift,
    when the set is not in a register); larger sets by the 68020's
    `bftst' (emit 66, cpu 3) or a `btst' of the byte (the set's address
    indexed by the bit's byte, for a variable element); with the range
    check (flags bit 10) an element outside the set branches past
    (emit 20 or 21, the label emit 32), the condition then 2 or 14.

    0x100660, 0x75C bytes: the size's word at +22; movewlx's constants'
    set (0x0FFE4C); the bounds compared unsigned (`bcc', `bhi', `bls');
    getphase's element 3 (`btst #3,D0'); a constant element's longword
    complemented (`not.l') for the bit field's offset, its quotient and
    remainder by 32 by `divs.w' (`swap', `ext.l') and `asr' with the
    rounding add; the size 31999 bits for a bit field offset as it is.

    Not known from the original:
    - why the bit field offset of a constant element is the set's last
      bit less its complement (the image's). }

  procedure bit_test_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    s: codegen_$uads_t;
    res: codegen_$uads_t;
    range: boolean;
    inst: integer;
    cc: integer;
    sz: integer;
    bits: integer;
    v: integer32;
    r: integer32;
    e: il_$node_ptr_t;
  begin
    range := false;
    cc := 6;
    inst := 17;
    sz := il_$node_ptr_t(n)^.xw[11];
    bits := il_$node_ptr_t(n)^.xw[11] * 8 - 1;
    if bits < 32 then begin
      e := n^.opnd[1];
      if e^.kind = 81 then begin
        v := e^.xl[2];
        if (v = 31) or (v = 15) or (v = 7) then begin
          sz := rshft(e^.xl[2] + 1, 3);
          opr := cg_zero_ads;
          inst := 18;
          cc := 11;
        end
        else if v = 0 then begin
          anyconst(0, 1, opr);
          if opr.f1 <> 1 then begin
            r := peek(n^.opnd[2], il_$node_ptr_t(n)^.xw[11]);
            if r = 31 then begin
              if bits > 8 then begin
                inst := 13;
                cc := 5;
              end;
            end
            else if weight(r) = 16000 then begin
              inst := 13;
              cc := 5;
            end;
          end;
        end
        else
          anyconst(e^.xl[2], 1, opr);
      end
      else begin
        load_operand(e, n^.desc.w6, opr);
        if (n^.desc.flags & 16#400) <> 0 then begin
          anyconst(bits, n^.desc.w6, ops);
          if ops.f1 = 3 then
            load_operand(smcontk(81, bits), n^.desc.w6, ops);
          emit(18, n^.desc.w6, ops, opr, 0);
          release(ops);
          address(templabel, 0, opt);
          emit(20, 5, opt, cg_null_ads, 5);
          cc := 2;
          range := true;
        end;
      end;
      if (bits <= 8) and (inst <> 13) then
        address(n^.opnd[2], il_$node_ptr_t(n)^.xw[11], ops)
      else if (inst = 18) and (peek(n^.opnd[2], il_$node_ptr_t(n)^.xw[11]) = 31) and
          (not (3 in getphase(n^.opnd[2])) or (sz = n^.desc.size)) then begin
        address(n^.opnd[2], sz, ops);
        if ops.f1 <> 1 then
          ops.y := ops.y + (n^.desc.size - sz);
      end
      else
        load_operand(n^.opnd[2], il_$node_ptr_t(n)^.xw[11], ops);
      release(opr);
      release(ops);
      if (ops.f1 = 1) and (ops.f2 > 7) then begin
        load_operand(n^.opnd[2], sz, ops);
        release(ops);
      end;
      if inst = 13 then begin
        shift(ops, 1, 1, 2);
        kill_register(ops.f2);
      end
      else
        emit(inst, sz, ops, opr, 0);
    end
    else begin
      if 3 in cargs_$options.cpu then begin
        address(n^.opnd[2], sz, s);
        e := n^.opnd[1];
        if e^.kind in [77..87, 101, 200] then begin
          if bits = 31999 then begin
            v := e^.xl[2];
            inst := v;
          end
          else begin
            v := ~e^.xl[2];
            inst := bits - v;
          end;
          r := inst;
          address(smcontk(81, r mod 32), 0, ops);
          s.y := s.y + (r div 32) * 4;
          if (n^.desc.flags & 16#400) <> 0 then
            if (v < 0) or (bits < v) then begin
              address(templabel, 0, opt);
              emit(21, 5, opt, cg_null_ads, 0);
              range := true;
            end;
        end
        else begin
          load_operand(e, n^.desc.w6, ops);
          if bits <> 31999 then begin
            if (n^.desc.flags & 16#400) <> 0 then begin
              anyconst(~bits, n^.desc.w6, opt);
              emit(18, n^.desc.w6, ops, opt, 0);
              unlock(opt);
              address(templabel, 0, opt);
              emit(20, 5, opt, cg_null_ads, 5);
              cc := 2;
              range := true;
            end;
            s.y := s.y + n^.desc.size;
          end;
        end;
        emit(66, sz, s, ops, 0);
        release(s);
      end
      else begin
        e := n^.opnd[1];
        if e^.kind in [77..87, 101, 200] then begin
          inst := rshft(bits - e^.xw[5], 3);
          anyconst(e^.xl[2], n^.desc.w6, ops);
        end
        else begin
          load_operand(smcontk(81, bits), n^.desc.w6, opr);
          load_operand(n^.opnd[1], n^.desc.w6, ops);
          emit(2, n^.desc.w6, opr, ops, 0);
          kill_register(opr.f2);
          if (n^.desc.flags & 16#400) <> 0 then begin
            address(templabel, 0, opt);
            emit(20, 5, opt, cg_null_ads, 5);
            cc := 14;
            range := true;
          end;
          shift(opr, n^.desc.w6, 3, 2);
        end;
        load_address(n^.opnd[2], s);
        if n^.desc.w8 < 0 then begin
          emit(18, n^.desc.w6, ops, cg_zero_ads, 0);
          cc := 2;
        end;
        if n^.opnd[1]^.kind in [77..87, 101, 200] then begin
          s.y := s.y + inst;
          s.f1 := 2;
        end
        else begin
          s.f1 := 4;
          s.f3 := opr.f2;
          if n^.desc.w6 = 4 then
            s.f5 := s.f5 ! 2
          else
            s.f5 := s.f5 & ~2;
          release(opr);
        end;
        emit(17, 1, s, ops, 0);
        s.f3 := 31;
        unlock(s);
        if range then
          kill_register(s.f2);
      end;
      release(ops);
    end;
    if n^.kind <> 143 then
      get_register(il_$node_ptr_t(n), 1, res);
    if range then begin
      emit(32, 5, opt, cg_null_ads, 0);
      release(opt);
    end;
    if abs(n^.desc.w8) = 7 then
      cc := reverse_cc(cc);
    if n^.desc.w8 < 0 then
      n^.desc.w8 := -cc
    else
      n^.desc.w8 := cc;
    if n^.kind <> 143 then begin
      emit(19, 1, res, cg_null_ads, cc);
      unlock(res);
    end;
  end;

  { bit_set_proc - bits set in a word (operator 25): with three operands
    the bits opnd[2] .. opnd[3] of opnd[1] set (a mask built in a
    register from 1 shifted by the bounds, constant bounds folded), the
    mask itself when opnd[1] is the constant 0, else or'ed (emit 4)
    into the result; with two, bit opnd[2] of opnd[1] set (emit 14, a
    `bset').

    0x100DBC, 0x41C bytes: movewlx's constants' set (0x0FFE4C); the 1 a
    constant node (smcontk 81); the constant mask by `lsl.l' of a frame
    copy of the count; shift's count and x pushed as one longword
    (0x00010003). }

  procedure bit_set_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    m2: codegen_$uads_t;
    m: codegen_$uads_t;
    b: codegen_$uads_t;
    res: codegen_$uads_t;
    sh: integer32;
    mask: integer32;
  begin
    if n^.count = 3 then begin
      if n^.opnd[3]^.kind in [77..87, 101, 200] then begin
        sh := n^.opnd[3]^.xl[2] + 1;
        mask := lshft(1, sh);
        load_operand(smcontk(81, 1), n^.desc.rlen, m);
        load_operand(n^.opnd[2], n^.desc.w6, b);
        emit(13, n^.desc.rlen, m, b, 3);
        release(b);
        kill_register(m.f2);
        emit(11, n^.desc.rlen, m, cg_null_ads, 0);
        if mask <> 0 then begin
          anyconst(mask, n^.desc.rlen, b);
          emit(1, n^.desc.rlen, m, b, 0);
          unlock(b);
        end;
      end
      else if n^.opnd[2]^.kind in [77..87, 101, 200] then begin
        mask := lshft(1, n^.opnd[2]^.xl[2]);
        load_operand(smcontk(81, 1), n^.desc.rlen, m);
        load_operand(n^.opnd[3], n^.desc.w6, b);
        emit(13, n^.desc.rlen, m, b, 3);
        shift(m, n^.desc.rlen, 1, 3);
        release(b);
        kill_register(m.f2);
        if mask <> 0 then begin
          anyconst(mask, n^.desc.rlen, b);
          emit(2, n^.desc.rlen, m, b, 0);
          unlock(b);
        end;
      end
      else begin
        load_operand(smcontk(81, 1), n^.desc.rlen, m);
        kill_register(m.f2);
        load_operand(n^.opnd[3], n^.desc.w6, b);
        emit(13, n^.desc.rlen, m, b, 3);
        shift(m, n^.desc.rlen, 1, 3);
        release(b);
        load_operand(smcontk(81, 1), n^.desc.rlen, m2);
        kill_register(m2.f2);
        load_operand(n^.opnd[2], n^.desc.w6, b);
        emit(13, n^.desc.rlen, m2, b, 3);
        release(b);
        emit(2, n^.desc.rlen, m, m2, 0);
        release(m2);
      end;
      if (n^.opnd[1]^.kind in [77..87, 101, 200]) and
          (n^.opnd[1]^.xl[2] = 0) then
        setresult(m.f2, il_$node_ptr_t(n), n^.desc.rlen)
      else begin
        load_result(il_$node_ptr_t(n), -1, res);
        emit(4, n^.desc.rlen, res, m, 0);
        unlock(res);
      end;
      unlock(m);
    end
    else begin
      load_result(il_$node_ptr_t(n), -1, res);
      load_operand(n^.opnd[2], n^.desc.w6, b);
      emit(14, n^.desc.rlen, res, b, 0);
      release(b);
      unlock(res);
    end;
  end;

  { unpack_proc - a bit field of opnd[1] (width desc.w8 at bit offset
    opnd[2]; flags bit 14 signed) as a value of class rlen: a constant
    offset beyond the first byte moved to the next byte; a byte at bit
    0 moved (cleared first unless signed, sign-extended when signed);
    with the 68020's bit fields (cpu 3) and an operand they take (not a
    register but D0..D7) a `bfexts' or `bfextu' (emit 64, 65; a variable
    offset in a register, mode 14); else the unit holding the field
    moved, masked (genmask: emit 3) and shifted right (shift, x 2), or,
    signed or at a variable offset, shifted left to the top (x 3, emit
    13) and right (x 0 arithmetic, x 2 logical; s_extend).

    0x1011D8, 0x3E6 bytes: movewlx's constants' set (0x0FFE4C); the
    offset the constant's word at +10; M020 bit 5 of 0x2C3671; the
    modes [1, 3, 8, 9] as the longword mask 0x30A, the data registers
    0xFF; the sums and classes compared unsigned (`bhi', `bls', `bcs').

    Not known from the original:
    - the bit field's size for a variable offset (the frame word at -64
      is not set on that path). }

  procedure unpack_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    c: codegen_$uads_t;
    t: codegen_$uads_t;
    bsz: integer;
    off: integer;
    rs: integer;
    bits: integer;
    hi: integer;
    sz: integer;
    cnst: boolean;
  begin
    if n^.opnd[2]^.kind in [77..87, 101, 200] then begin
      cnst := true;
      off := n^.opnd[2]^.xw[5];
    end
    else
      cnst := false;
    address(n^.opnd[1], 0, opr);
    get_register(il_$node_ptr_t(n), n^.desc.rlen, ops);
    if cnst then
      if (off >= 8) and (off + n^.desc.w8 <= 16) then begin
        off := off - 8;
        opr.y := opr.y + 1;
      end;
    if cnst and (off = 0) and (n^.desc.w8 = 8) then begin
      if ((n^.desc.flags & 16#4000) = 0) and (n^.desc.rlen > 1) then begin
        anyconst(0, n^.desc.rlen, c);
        emit(0, n^.desc.rlen, ops, c, 0);
        unlock(c);
      end;
      emit(0, 1, ops, opr, 0);
      if (n^.desc.flags & 16#4000) <> 0 then
        s_extend(ops, 1, n^.desc.rlen);
    end
    else if (3 in cargs_$options.cpu) and
        (not (opr.f1 in [1, 3, 8, 9]) or
         ((opr.f1 = 1) and (opr.f2 in [0..7]))) then begin
      opr.x := integer32(n);
      if cnst then begin
        if off + n^.desc.w8 > 16 then
          bsz := 4
        else
          bsz := 2;
      end
      else begin
        load_operand(n^.opnd[2], 4, t);
        ops.f3 := t.f2;
        ops.f1 := 14;
      end;
      if (n^.desc.flags & 16#4000) <> 0 then
        emit(64, bsz, ops, opr, 0)
      else
        emit(65, bsz, ops, opr, 0);
      if ops.f1 = 14 then begin
        release(t);
        ops.f1 := 1;
      end;
    end
    else begin
      if cnst then begin
        hi := off + n^.desc.w8;
        sz := 2;
        if hi > 16 then
          sz := 4
        else if hi <= 8 then
          sz := 1;
      end
      else
        sz := n^.desc.w6;
      bits := sz * 8;
      rs := sz;
      if n^.desc.rlen > sz then
        rs := n^.desc.rlen;
      if cnst and ((n^.desc.flags & 16#4000) = 0) then begin
        if (off <> 0) or (rs <> sz) then begin
          anyconst(genmask(off, hi, bits), rs, opt);
          emit(0, rs, ops, opt, 0);
          unlock(opt);
          emit(3, sz, ops, opr, 0);
        end
        else
          emit(0, sz, ops, opr, 0);
        shift(ops, rs, bits - hi, 2);
      end
      else begin
        if (n^.desc.flags & 16#4000) = 0 then begin
          anyconst(0, n^.desc.rlen, c);
          emit(0, n^.desc.rlen, ops, c, 0);
          unlock(c);
        end;
        emit(0, sz, ops, opr, 0);
        if cnst then
          shift(ops, sz, off, 3)
        else begin
          load_operand(n^.opnd[2], 1, t);
          emit(13, sz, ops, t, 3);
          release(t);
        end;
        if (n^.desc.flags & 16#4000) <> 0 then begin
          shift(ops, sz, bits - n^.desc.w8, 0);
          s_extend(ops, sz, n^.desc.rlen);
        end
        else
          shift(ops, sz, bits - n^.desc.w8, 2);
      end;
    end;
    release(opr);
    unlock(ops);
  end;

  { shift_proc - a shift tree (operators 27, 28, 49, 50: how, shift's
    and emit's x): by a constant count with shift, else by a count in a
    register (emit 13).

    0x1015BE, 0xB6 bytes: the constants' set after movewlx's code
    (0x0FFE4C: 77..87, 101, 200); the count's word at +10 of the
    constant. }

  procedure shift_proc(
      n: cg_tree_ptr_t;
      how: integer); options(val_param);
  begin
    load_result(il_$node_ptr_t(n), -1, opr);
    if n^.opnd[2]^.kind in [77..87, 101, 200] then
      shift(opr, n^.desc.rlen, n^.opnd[2]^.xw[5], how)
    else begin
      load_operand(n^.opnd[2], n^.desc.w8, ops);
      emit(13, n^.desc.rlen, opr, ops, how);
      release(ops);
    end;
    unlock(opr);
  end;

  { agg_compare_proc - an aggregate comparison (operator 24: a `cmp'
    (emit 18) unit by unit, the condition from desc.w8; 23: a test of
    the bits of opnd[1] not in opnd[2], the condition made 7) by bytes
    (an odd size, or opnd's that may be unaligned with the alignment
    check, flags bit 10), words or longwords; one unit by its operands,
    more through address registers post-incremented (mode 8, agg_opr's)
    in a loop (emit 28, a `dbne' on the count less 1: 2 units unrolled;
    more than 65535 an outer count in a long); the condition then set
    into a byte register (emit 19) but for a 143 node; desc.w8
    restored but on the last pass.

    0x101674, 0x5FA bytes: cg_addr_next_areg set to 8 meanwhile; the
    constants' set after the code (0x101C6E: 77..87, 92, 101, 156, 200,
    212); the counts compared unsigned (`bhi'); a count register a
    register variable lives in (cg_addr_cache's live, 0x354FBF) copied
    first through a partial copy of its operand (f1, f2, f5); the
    operands swapped through t (-104); the loop's head label (lab)
    reused for the branch of 2 units. }

  procedure agg_compare_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    tmp: codegen_$uads_t;
    lab2: codegen_$uads_t;
    res: codegen_$uads_t;
    t: codegen_$uads_t;
    lab: codegen_$uads_t;
    csz: integer;
    cnt: integer32;
    unit: integer;
    w8: integer;
    save: integer;
  begin
    save := cg_addr_next_areg;
    w8 := n^.desc.w8;
    cg_addr_next_areg := 8;
    cnt := n^.desc.size;
    unit := 2;
    if odd(cnt) then
      unit := 1
    else if (n^.op = 24) and ((n^.desc.flags & 16#400) <> 0) then
      if unaligned(n^.opnd[1]) or unaligned(n^.opnd[2]) then
        unit := 1;
    if unit = 2 then begin
      cnt := rshft(cnt, 1);
      if not odd(cnt) then begin
        cnt := rshft(cnt, 1);
        unit := 4;
      end;
    end;
    if cnt <= 65536 then begin
      cnt := cnt - 1;
      csz := 2;
    end
    else
      csz := 4;
    if cnt = 0 then begin
      if (n^.opnd[2]^.kind in [77..87, 92, 101, 156, 200, 212]) and
          not (n^.opnd[1]^.kind in [77..87, 92, 101, 156, 200, 212]) then
        address(n^.opnd[1], unit, opr)
      else
        load_operand(n^.opnd[1], unit, opr);
    end
    else begin
      load_address(n^.opnd[1], opr);
      opr.f1 := 8;
      kill_register(opr.f2);
    end;
    if n^.op <> 23 then begin
      if cnt = 0 then
        address(n^.opnd[2], unit, ops)
      else
        agg_opr(n^.opnd[2], ops);
      if (ops.f1 = 1) and (opr.f1 <> 1) then begin
        t := opr;
        opr := ops;
        ops := t;
        n^.desc.w8 := swap_cc[n^.desc.w8];
      end;
    end
    else begin
      if cnt = 0 then
        address(n^.opnd[2], unit, ops)
      else begin
        load_address(n^.opnd[2], ops);
        kill_register(ops.f2);
        ops.f1 := 8;
      end;
      if n^.desc.w8 = 12 then begin
        t := opr;
        opr := ops;
        ops := t;
      end;
      n^.desc.w8 := 7;
      get_register(nil, 4, t);
    end;
    if cnt <> 0 then begin
      load_operand(smcontk(81, cnt), csz, opt);
      if cg_addr_cache[opt.f2].live then begin
        tmp.f1 := opt.f1;
        tmp.f2 := opt.f2;
        tmp.f5 := opt.f5;
        get_register(smcontk(81, cnt), csz, opt);
        emit(0, csz, opt, tmp, 0);
        unlock(tmp);
      end;
      kill_register(opt.f2);
      address(templabel, 0, lab);
      emit(32, 5, lab, cg_null_ads, 0);
    end;
    if n^.op = 24 then
      emit(18, unit, opr, ops, 0)
    else begin
      emit(0, unit, t, ops, 0);
      emit(12, unit, t, cg_null_ads, 0);
      emit(3, unit, t, opr, 0);
      if cnt <> 1 then
        unlock(t);
    end;
    if cnt <> 0 then begin
      if cnt = 1 then begin
        address(templabel, 0, lab);
        emit(20, 5, lab, cg_null_ads, 6);
        if n^.op = 24 then
          emit(18, unit, opr, ops, 0)
        else begin
          emit(0, unit, t, ops, 0);
          emit(12, unit, t, cg_null_ads, 0);
          emit(3, unit, t, opr, 0);
          unlock(t);
        end;
        emit(32, 5, lab, cg_null_ads, 0);
      end
      else if cnt <= 65535 then
        emit(28, 2, lab, opt, 6)
      else begin
        address(templabel, 0, lab2);
        emit(20, 5, lab2, cg_null_ads, 6);
        address(smcontk(81, 1), 4, t);
        emit(2, 4, opt, t, 0);
        emit(20, 5, lab, cg_null_ads, 6);
        release(t);
        emit(32, 5, lab2, cg_null_ads, 0);
        release(lab2);
      end;
      release(opt);
      release(lab);
    end;
    unlock(ops);
    unlock(opr);
    if n^.kind <> 143 then begin
      get_register(il_$node_ptr_t(n), 1, res);
      emit(19, 1, res, cg_null_ads, n^.desc.w8);
      unlock(res);
    end;
    if not at_backend_506 then
      n^.desc.w8 := w8;
    cg_addr_next_areg := save;
  end;

  { mul_proc - an integer multiplication (operator 3): by a constant as
    shifts and adds (do_const_mul, opt_on 7); words to a word or a long
    by the 68000's `muls'/`mulu' (emit 6 signed, 7 unsigned; mdmcase
    of the classes w6, w8 and rlen, the operands swapped to put the
    word first); else by the routine k (std_lib_rtns: 0 signed word by
    long, 1 signed long, 2 unsigned word by long, 3 unsigned long), the
    PEB (cpu 1: the operands stored to its registers, 149 and 150,
    through fault_free_assign, an operand it holds kept), the 68020's
    or the 160's `mul' (cpu 2, 3) or a call (gen_call).  n's descriptor
    restored but on the last pass.

    0x101D38, 0x732 bytes: the classes by mdmcase's jump table of 8;
    tree_rlen (+0x294) the result's class meanwhile; cg_addr_regs's size
    (0x3550E2) set; the PEB's operations' set after the code (0x10246A:
    63, 83, 104, 149, 157, 159) tested with cg_fp_last_op; std_lib_rtns
    at 0x2D2B68.

    Not known from the original:
    - k for a signed long by long (mdmcase 3 or 5 with flags bit 14): the
      image leaves D2 as it was. }

  procedure mul_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    d: cg_desc_t;
    p: codegen_$uads_t;
    op: integer;
    k: integer;
    m: integer;
    t: il_$node_ptr_t;

    { mdmcase - the classes' case: 4 when a is a long, plus 2 when b is,
      plus 1 when c is.

      0x101C8A, 0x3E bytes. }

    function mdmcase(
        a: integer;
        b: integer;
        c: integer): integer; options(val_param);
    var
      r: integer;
    begin
      r := 0;
      if a = 4 then
        r := 4;
      if b = 4 then
        r := r + 2;
      if c = 4 then
        r := r + 1;
      mdmcase := r;
    end;

    { ldsqr - the second operand in ops: opr again (locked once more)
      when both operands are the same node, else addressed with size.

      0x101CC8, 0x70 bytes: mul_proc's frame from the dynamic link;
      cg_addr_locks (0x355098). }

    procedure ldsqr(
        size: integer); options(val_param);
    begin
      if n^.opnd[1] = n^.opnd[2] then begin
        ops := opr;
        cg_addr_locks[opr.f2] := cg_addr_locks[opr.f2] + 1;
      end
      else
        address(n^.opnd[2], size, ops);
    end;

  begin
    if cg_fp_count <> 0 then
      purge_fp;
    if (n^.opnd[2]^.kind in [77..87, 101, 200]) and
        (7 in cargs_$options.opt_on) then
      if do_const_mul(n, 0) then
        return;
    d := n^.desc;
    m := mdmcase(n^.desc.w6, n^.desc.w8, n^.desc.rlen);
    if (m = 3) or (m = 4) then begin
      n^.desc.w6 := n^.desc.w8;
      n^.desc.w8 := d.w6;
      t := n^.opnd[1];
      n^.opnd[1] := n^.opnd[2];
      n^.opnd[2] := t;
    end;
    op := 6;
    if (n^.desc.flags & 16#4000) = 0 then
      op := 7;
    case m of
      3, 5:
        if (n^.desc.flags & 16#4000) = 0 then
          k := 2;
      7: begin
        k := 1;
        if (n^.desc.flags & 16#4000) = 0 then
          k := 3;
      end;
      0, 1: begin
        tree_rlen := n^.desc.rlen;
        n^.desc.rlen := 2;
        load_result(il_$node_ptr_t(n), 2, opr);
        ldsqr(2);
        emit(op, 2, opr, ops, 0);
        cg_addr_regs[opr.f2].size := tree_rlen;
        n^.desc.rlen := tree_rlen;
        unlock(opr);
        release(ops);
        if not at_backend_506 then
          n^.desc := d;
        return;
      end;
      2, 4: begin
        n^.desc.rlen := 4;
        load_result(il_$node_ptr_t(n), -2, opr);
        address(n^.opnd[1], 2, ops);
        emit(7, 2, opr, ops, 0);
        n^.desc.rlen := 2;
        cg_addr_regs[opr.f2].size := 2;
        unlock(opr);
        release(ops);
        if not at_backend_506 then
          n^.desc := d;
        return;
      end;
      6: begin
        n^.desc.rlen := 4;
        load_result(il_$node_ptr_t(n), 2, opr);
        if n^.opnd[1] = n^.opnd[2] then begin
          ops := opr;
          cg_addr_locks[opr.f2] := cg_addr_locks[opr.f2] + 1;
        end
        else
          load_operand(n^.opnd[2], 4, ops);
        emit(7, 2, opr, ops, 0);
        n^.desc.rlen := 2;
        cg_addr_regs[opr.f2].size := 2;
        unlock(opr);
        release(ops);
        if not at_backend_506 then
          n^.desc := d;
        return;
      end;
      otherwise ;
    end;
    if 1 in cargs_$options.cpu then begin
      if ((n^.desc.flags & 16#4000) = 0) or (k = 1) then
        gen_call(il_$node_ptr_t(n), std_lib_rtns[k])
      else begin
        p := peb_ads;
        opr.f1 := 0;
        if not check_use(cg_fp_in_peb, n^.opnd[1]) then
          if check_use(cg_fp_in_peb, n^.opnd[2]) and
              not ((k = 2) or (k = 0)) then begin
            t := n^.opnd[1];
            n^.opnd[1] := n^.opnd[2];
            n^.opnd[2] := t;
          end
          else begin
            p.y := 149;
            address(n^.opnd[1], 4, opr);
            if not (cg_fp_last_op in [63, 83, 104, 149, 157, 159]) then
              test_peb_busy;
            cg_fp_last_op := 149;
            fault_free_assign(4, p, opr);
          end;
        opr.x := integer32(n^.opnd[1]);
        release(opr);
        if (k = 3) or (k = 1) then
          address(n^.opnd[2], 4, ops)
        else
          movewlx(n^.opnd[2], ops, (n^.desc.flags & 16#4000) <> 0, false);
        p.y := 150;
        if not (cg_fp_last_op in [63, 83, 104, 149, 157, 159]) then
          test_peb_busy;
        cg_fp_last_op := 150;
        fault_free_assign(4, p, ops);
        release(ops);
        cg_fp_in_peb := il_$node_ptr_t(n);
      end;
    end
    else if cargs_$options.cpu * [2, 3] <> [] then begin
      if k = 1 then begin
        load_result(il_$node_ptr_t(n), 2, opr);
        ldsqr(4);
        emit(op, 4, opr, ops, 0);
      end
      else if k = 3 then begin
        if 3 in cargs_$options.cpu then begin
          load_result(il_$node_ptr_t(n), 2, opr);
          ldsqr(4);
        end
        else begin
          inquire(n^.opnd[2], 4, ops);
          if ops.f1 = 0 then begin
            inquire(n^.opnd[1], 4, ops);
            if ops.f1 = 0 then
              load_operand(n^.opnd[2], 4, ops)
            else
              n^.opnd[1] := n^.opnd[2];
          end;
          load_result(il_$node_ptr_t(n), -1, opr);
        end;
        emit(op, 4, opr, ops, 0);
      end
      else if (k = 0) or (k = 2) then begin
        movewlx(n^.opnd[2], opr, (n^.desc.flags & 16#4000) <> 0, true);
        setresult(opr.f2, il_$node_ptr_t(n), 4);
        if (2 in cargs_$options.cpu) and ((n^.desc.flags & 16#4000) = 0) then
          load_operand(n^.opnd[1], 4, ops)
        else
          address(n^.opnd[1], 4, ops);
        emit(op, 4, opr, ops, 0);
      end
      else begin
        gen_call(il_$node_ptr_t(n), std_lib_rtns[k]);
        if not at_backend_506 then
          n^.desc := d;
        return;
      end;
      unlock(opr);
      release(ops);
    end
    else
      gen_call(il_$node_ptr_t(n), std_lib_rtns[k]);
    if not at_backend_506 then
      n^.desc := d;
  end;

  { div_proc - an integer division or remainder (operators 4, 6) by
    delay_$divide_attributes's strategy: by a power of 2 (how 1) a
    shift (signed: the value rounded toward zero first, emit 18 a test,
    20 a branch, 1 the add of 2^sh - 1; unsigned: masked to its class
    first); by the PEB (cpu 1, routines 4 and 5: the operands stored
    to its registers 149 and 151 or 152, an operand it holds kept) or
    the library (std_lib_rtns[rtn], the result extended); else the
    hardware's divide (emit's op and size from the strategy; the
    operands as longs or words, movewlx; a 68020 remainder (cpu 3,
    operator 6, how 4 or 8) by a `divsl' into a second register,
    mode 14), the result extended (extend_div_proc_result) and, with
    b27c_1 for a remainder, made positive (emit 1 of the divisor after
    a sign test).

    0x102556, 0x728 bytes: the attributes in the frame (-184 .. -226,
    passed by address); the PEB's operations' set after mul_proc
    (0x10246A); the classes compared unsigned (`bcc', `bcs'); the
    68020 test evaluated whole (`sne', `seq', `and.b'), the classes 2
    and 6 (0x44), 4 and 8 (0x110) as masks; cg_addr_cache's live and
    obj (0x354FB8); the bug_check message after the code (0x102C7E);
    b27c_1 bit 1 of cargs +0x27C. }

  procedure div_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    lab: codegen_$uads_t;
    rem: codegen_$uads_t;
    lab2: codegen_$uads_t;
    a: codegen_$uads_t;
    c: codegen_$uads_t;
    strategy: integer32;
    rsize: integer32;
    sh: integer32;
    lsize: integer32;
    rtn: integer;
    w70: integer;
    w66: integer;
    res: integer;
    how: integer;
    ext: integer;
    w34: integer;
    w26: integer;
    op: integer;
    size: integer;
    b58: boolean;
    b54: boolean;
    sz: integer;
    r: integer;
    pop: integer;
    t: il_$node_ptr_t;
    m020: boolean;

    { extend_div_proc_result - the quotient or remainder a of n extended
      as how says: 1 a word's (emit 29, `ext'), 2 the high word cleared
      (an and with 0xFFFF) for a long, 3 a word sign-extended to a long
      (emit 30), 4 a word to a long through a cleared high word (emit 3
      with cg_zero_ads) and 29, 5 both extensions; 0 none.

      0x10247E, 0xD8 bytes: a jump table of 6; the class compared
      unsigned (`bcs'). }

    procedure extend_div_proc_result(
        n: cg_tree_ptr_t;
        how: integer;
        in out a: codegen_$uads_t); options(val_param);
    var
      c: codegen_$uads_t;
    begin
      case how of
        0: ;
        1:
          emit(29, 2, a, cg_null_ads, 0);
        2:
          if n^.desc.rlen = 4 then begin
            anyconst(65535, 4, c);
            emit(3, 4, a, c, 0);
          end;
        3:
          if n^.desc.rlen = 4 then
            emit(30, 4, a, cg_null_ads, 0);
        4: begin
          if n^.desc.rlen >= 4 then
            emit(3, 2, a, cg_zero_ads, 0);
          emit(29, 2, a, cg_null_ads, 0);
        end;
        5: begin
          emit(29, 2, a, cg_null_ads, 0);
          if n^.desc.rlen = 4 then
            emit(30, 4, a, cg_null_ads, 0);
        end;
        otherwise ;
      end;
    end;

  begin
    if cg_fp_count <> 0 then
      purge_fp;
    delay_$divide_attributes(il_$node_ptr_t(n), false, strategy, op,
        lsize, w26, rsize, w34, how, ext, rtn, sh, b54, b58, size, w66,
        w70);
    if how = 1 then begin
      sz := n^.desc.rlen;
      n^.desc.rlen := n^.desc.w6;
      load_result(il_$node_ptr_t(n), -1, opr);
      n^.desc.rlen := sz;
      cg_addr_regs[opr.f2].size := n^.desc.rlen;
      if (n^.desc.flags & 16#4000) <> 0 then begin
        if n^.desc.w6 < n^.desc.rlen then
          emit(30, n^.desc.rlen, opr, cg_null_ads, 0)
        else
          sz := n^.desc.w6;
        address(smcontk(81, lshft(1, sh) - 1), 0, c);
        address(templabel, 0, lab);
        emit(18, sz, opr, cg_zero_ads, 0);
        emit(20, 5, lab, cg_null_ads, 10);
        emit(1, sz, opr, c, 0);
        emit(32, 5, lab, cg_null_ads, 0);
        shift(opr, sz, sh, 0);
        unlock(opr);
        release(c);
      end
      else begin
        sz := n^.desc.w6;
        if sz < n^.desc.rlen then begin
          if sz = 1 then
            anyconst(255, n^.desc.rlen, c)
          else if sz = 2 then
            anyconst(65535, n^.desc.rlen, c);
          emit(3, n^.desc.rlen, opr, c, 0);
        end;
        shift(opr, n^.desc.rlen, sh, 2);
        unlock(opr);
      end;
    end
    else if how = 0 then begin
      if (1 in cargs_$options.cpu) and ((rtn = 5) or (rtn = 4)) then begin
        opt := peb_ads;
        opr.f1 := 0;
        if check_use(cg_fp_in_peb, n^.opnd[1]) then
          pop := 151
        else if check_use(cg_fp_in_peb, n^.opnd[2]) and (rtn <> 4) then begin
          pop := 152;
          t := n^.opnd[1];
          n^.opnd[1] := n^.opnd[2];
          n^.opnd[2] := t;
        end
        else begin
          pop := 151;
          opt.y := 149;
          address(n^.opnd[1], 4, opr);
          if not (cg_fp_last_op in [63, 83, 104, 149, 157, 159]) then
            test_peb_busy;
          cg_fp_last_op := 149;
          fault_free_assign(4, opt, opr);
        end;
        opr.x := integer32(n^.opnd[1]);
        release(opr);
        cg_fp_in_peb := nil;
        if rtn <> 4 then
          address(n^.opnd[2], 4, c)
        else
          movewlx(n^.opnd[2], c, true, false);
        opt.y := pop;
        if not (cg_fp_last_op in [63, 83, 104, 149, 157, 159]) then
          test_peb_busy;
        cg_fp_last_op := pop;
        fault_free_assign(4, opt, c);
        release(c);
        cg_fp_in_peb := il_$node_ptr_t(n);
      end
      else begin
        gen_call(il_$node_ptr_t(n), std_lib_rtns[rtn]);
        if ext <> 0 then begin
          address(il_$node_ptr_t(n), n^.desc.rlen, opr);
          extend_div_proc_result(n, ext, opr);
          release(opr);
        end;
      end;
    end
    else begin
      setobjcache(n^.opnd[1], getobjcache(il_$node_ptr_t(n)));
      if (n^.desc.w6 > 2) or (lsize = 2) or (w26 = 0) then begin
        sz := n^.desc.rlen;
        n^.desc.rlen := n^.desc.w6;
        load_result(il_$node_ptr_t(n), -1, opr);
        n^.desc.rlen := sz;
      end
      else if w26 = 3 then
        movewlx(n^.opnd[1], opr, true, true)
      else
        movewlx(n^.opnd[1], opr, false, true);
      if (n^.desc.w8 > 2) or (rsize = 2) or (w34 = 0) then
        address(n^.opnd[2], n^.desc.w8, c)
      else if w34 = 3 then
        movewlx(n^.opnd[2], c, true, true)
      else if w34 = 2 then
        movewlx(n^.opnd[2], c, false, true);
      m020 := (3 in cargs_$options.cpu) and (n^.op = 6) and
          not (how in [2, 6]);
      if m020 then begin
        if not (how in [4, 8]) then
          bug_check('Inconsistent computation of long_m020_mod%.');
        if m020 then begin
          r := peek(n^.opnd[2], n^.desc.w8);
          if (n^.desc.w6 = 4) and (n^.desc.w8 = 4) and (r in [0..7]) and
              (not cg_addr_cache[r].live or (cg_addr_cache[r].obj = nil)) and
              not b58 then begin
            cg_addr_locks[r] := cg_addr_locks[r] + 1;
            address_reg(r, rem);
            rem.x := integer32(n^.opnd[2]);
          end
          else
            get_temp_register(il_$node_ptr_t(n), n^.desc.rlen, rem);
          opr.f1 := 14;
          opr.f3 := rem.f2;
        end;
      end;
      emit(op, size, opr, c, 0);
      if m020 then begin
        setresult(opr.f3, il_$node_ptr_t(n), n^.desc.rlen);
        kill_register(opr.f2);
        res := opr.f3;
      end
      else begin
        setresult(opr.f2, il_$node_ptr_t(n), n^.desc.rlen);
        kill_register(opr.f2);
        res := opr.f2;
      end;
      extend_div_proc_result(n, ext, opr);
      if cargs_$options.b27c_1 and (n^.op = 6) and b58 then begin
        address_reg(res, a);
        emit(18, n^.desc.rlen, a, cg_zero_ads, 0);
        address(templabel, 0, lab2);
        emit(20, 5, lab2, cg_null_ads, 12);
        emit(1, n^.desc.rlen, a, c, 0);
        emit(32, 5, lab2, cg_null_ads, 0);
        release(lab2);
      end;
      setresult(res, il_$node_ptr_t(n), n^.desc.rlen);
      release(c);
      unlock(opr);
    end;
  end;

  { copy_set_aggregate - a set of size bytes copied from src (nil: all
    zero, an immediate 0) to dst: through address registers
    post-incremented (mode 8) for more than 4 bytes, else d(An) (mode 2;
    a constant source as it is); longwords inline up to 3, else a loop,
    then a word and a byte.

    0x102CAA, 0x1EA bytes: cg_addr_next_areg (0x35526E) set to 8 (A0)
    meanwhile; the constants' set after movewlx's code (0x0FFE4C); the
    longwords' count a signed division (`asr' with the rounding add). }

  procedure copy_set_aggregate(
      src: il_$node_ptr_t;
      dst: il_$node_ptr_t;
      size: integer32); options(val_param);
  var
    d: codegen_$uads_t;
    s: codegen_$uads_t;
    lab: codegen_$uads_t;
    r: codegen_$uads_t;
    cnt: integer32;
    i: integer32;
    save: integer;
  begin
    save := cg_addr_next_areg;
    cg_addr_next_areg := 8;
    if src = nil then
      anyconst(0, 4, s);
    if size > 4 then begin
      if src <> nil then begin
        load_address(src, s);
        kill_register(s.f2);
        s.f1 := 8;
      end;
      load_address(dst, d);
      kill_register(d.f2);
      d.f1 := 8;
    end
    else begin
      if src <> nil then begin
        address(src, 5, s);
        if not (src^.kind in [77..87, 101, 200]) then
          s.f1 := 2;
      end;
      address(dst, 5, d);
      d.f1 := 2;
    end;
    cnt := size div 4;
    if cnt > 0 then
      if cnt <= 3 then
        for i := 1 to cnt do
          emit(0, 4, d, s, 0)
      else begin
        agg_loop_start(cnt - 1, r, lab);
        emit(0, 4, d, s, 0);
        agg_loop_end(cnt, r, lab);
      end;
    if (size & 2) <> 0 then
      emit(0, 2, d, s, 0);
    if (size & 1) <> 0 then
      emit(0, 1, d, s, 0);
    if size > 4 then
      unlock(d)
    else
      release(d);
    if (size > 4) and (src <> nil) then
      unlock(s)
    else
      release(s);
    cg_addr_next_areg := save;
  end;

  { set_range_in_set_proc - the range opnd[2] .. opnd[3] added to the set
    opnd[1] (operator 73), in n's temporary (get_childs_agg_temp, else
    the set copied there; an empty constant set as zeros): a loop
    (emit 28, a `dbf' on the range's length) setting bit by bit (emit
    14, a `bset' at the set's last byte less the bit's byte index,
    indexed); constant bounds clipped to the set (an empty or outside
    range: no code); with the range check (flags bit 10) a bound beyond
    the set clipped (emit 18, 20 a branch, 32 its label) and a negative
    length skipped.

    0x102E94, 0x54A bytes: movewlx's constants' set (0x0FFE4C) for the
    operands, 156 a set constant; load_modifiable's size 5 by address
    (a constant after the code, 0x1033DE); the bit's register shifted
    right by 3 (shift's x 2) and negated (emit 11); the index register's
    long flag (f5 bit 1) set for class 4 by `bset #1' of its low byte
    (docs/rev889-patterns.md 49). }

  procedure set_range_in_set_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    c: codegen_$uads_t;
    s: codegen_$uads_t;
    lab: codegen_$uads_t;
    lp: codegen_$uads_t;
    cnt: codegen_$uads_t;
    bit: codegen_$uads_t;
    idx: codegen_$uads_t;
    v: codegen_$uads_t;
    k: codegen_$uads_t;
    bits: integer32;
    hi: integer32;
    len: integer32;
    w: integer;
    set1: il_$node_ptr_t;
    range: boolean;
  begin
    range := false;
    bits := n^.desc.size * 8 - 1;
    w := n^.desc.w6;
    set1 := n^.opnd[1];
    if not get_childs_agg_temp(il_$node_ptr_t(n)) then begin
      if (set1^.kind in [77..87, 101, 200]) or (set1^.kind = 156) then
        if set_is_nil(set1) then
          set1 := nil;
      copy_set_aggregate(set1, n^.opnd[1], n^.desc.size);
    end;
    if (n^.opnd[3]^.kind in [77..87, 101, 200]) and
        (n^.opnd[2]^.kind in [77..87, 101, 200]) then begin
      hi := n^.opnd[3]^.xl[2];
      if hi > bits then
        hi := bits;
      len := hi - n^.opnd[2]^.xl[2];
      if (len < 0) or (n^.opnd[2]^.xl[2] > bits) or
          (n^.opnd[2]^.xl[2] < 0) then
        return;
      anyconst(hi, w, k);
      get_register(nil, w, bit);
      emit(0, w, bit, k, 0);
      kill_register(bit.f2);
      release(k);
      anyconst(len, w, c);
      get_register(nil, w, cnt);
      emit(0, w, cnt, c, 0);
      kill_register(cnt.f2);
      release(c);
      load_modifiable(n^.opnd[1], 5, s);
      kill_register(s.f2);
    end
    else begin
      address(n^.opnd[3], w, c);
      get_register(nil, w, cnt);
      emit(0, w, cnt, c, 0);
      kill_register(cnt.f2);
      release(c);
      get_register(nil, w, bit);
      emit(0, w, bit, cnt, 0);
      if (n^.desc.flags & 16#400) <> 0 then begin
        anyconst(bits, w, k);
        emit(18, w, bit, k, 0);
        address(templabel, 0, lab);
        emit(20, 5, lab, cg_null_ads, 3);
        emit(0, w, bit, k, 0);
        emit(0, w, cnt, k, 0);
        emit(32, 5, lab, cg_null_ads, 0);
        release(k);
        release(lab);
      end;
      load_modifiable(n^.opnd[1], 5, s);
      kill_register(s.f2);
      address(n^.opnd[2], w, v);
      emit(2, w, cnt, v, 0);
      release(v);
      if (n^.desc.flags & 16#400) <> 0 then begin
        range := true;
        address(templabel, 0, lab);
        emit(20, 5, lab, cg_null_ads, 5);
      end;
    end;
    address(templabel, 0, lp);
    emit(32, 5, lp, cg_null_ads, 0);
    get_register(nil, w, idx);
    emit(0, w, idx, bit, 0);
    kill_register(idx.f2);
    shift(idx, w, 3, 2);
    emit(11, w, idx, cg_null_ads, 0);
    s.y := s.y + n^.desc.size - 1;
    s.f1 := 4;
    s.f3 := idx.f2;
    if w = 4 then
      s.f5 := s.f5 ! 2
    else
      s.f5 := s.f5 & ~2;
    emit(14, 1, s, bit, 0);
    s.f3 := 31;
    unlock(idx);
    unlock(s);
    anyconst(1, w, c);
    emit(2, w, bit, c, 0);
    kill_register(bit.f2);
    unlock(c);
    unlock(bit);
    emit(28, 2, lp, cnt, 1);
    kill_register(cnt.f2);
    release(lp);
    unlock(cnt);
    if range then begin
      emit(32, 5, lab, cg_null_ads, 0);
      release(lab);
    end;
  end;

  { set_bit_in_set_proc - element opnd[2] added to the set opnd[1]
    (operator 72), in n's temporary as set_range_in_set_proc: a constant
    element by a `bset' (emit 14) of its bit in its byte (none outside
    the set with the range check), else the bit's number (the set's
    last bit less the element) in a register, its byte by a shift right
    of 3 as an index (with the range check a negative number branches
    past: emit 20, 32).

    0x1033E0, 0x298 bytes: movewlx's constants' set (0x0FFE4C); the
    byte's offset by `lsr' (rshft); the index register's long flag (f5
    bit 1) by `bset #1' of its low byte. }

  procedure set_bit_in_set_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    s: codegen_$uads_t;
    r: codegen_$uads_t;
    v: codegen_$uads_t;
    lab: codegen_$uads_t;
    c: codegen_$uads_t;
    bits: integer32;
    w: integer;
    set1: il_$node_ptr_t;
    range: boolean;
  begin
    range := false;
    bits := n^.desc.size * 8 - 1;
    w := n^.desc.w6;
    set1 := n^.opnd[1];
    if not get_childs_agg_temp(il_$node_ptr_t(n)) then begin
      if (set1^.kind in [77..87, 101, 200]) or (set1^.kind = 156) then
        if set_is_nil(set1) then
          set1 := nil;
      copy_set_aggregate(set1, n^.opnd[1], n^.desc.size);
    end;
    if n^.opnd[2]^.kind in [77..87, 101, 200] then begin
      bits := bits - n^.opnd[2]^.xl[2];
      if ((n^.desc.flags & 16#400) = 0) or (bits >= 0) then begin
        bits := rshft(bits, 3);
        anyconst(n^.opnd[2]^.xl[2], w, v);
        address(n^.opnd[1], 5, s);
        s.y := s.y + bits;
        s.f1 := 2;
        emit(14, 1, s, v, 0);
        release(v);
        release(s);
      end;
    end
    else begin
      anyconst(bits, w, c);
      get_register(nil, w, r);
      emit(0, w, r, c, 0);
      release(c);
      load_operand(n^.opnd[2], w, v);
      emit(2, w, r, v, 0);
      kill_register(r.f2);
      release(v);
      if (n^.desc.flags & 16#400) <> 0 then begin
        address(templabel, 0, lab);
        emit(20, 5, lab, cg_null_ads, 5);
        range := true;
      end;
      shift(r, w, 3, 2);
      load_address(n^.opnd[1], s);
      kill_register(s.f2);
      s.f1 := 4;
      s.f3 := r.f2;
      if w = 4 then
        s.f5 := s.f5 ! 2
      else
        s.f5 := s.f5 & ~2;
      emit(14, 1, s, v, 0);
      s.f3 := 31;
      release(r);
      unlock(s);
    end;
    if range then begin
      emit(32, 5, lab, cg_null_ads, 0);
      release(lab);
    end;
  end;

  { set_ops - a set operation (operators 19..21: and, or, and of the
    complement) of n's operands into n's temporary (get_agg_temp), a
    longword at a time (a loop of size div 4), then a word and a byte;
    through address registers post-incremented (mode 8).

    0x10370A, 0x164 bytes: cg_addr_next_areg set to 8 meanwhile; the
    count by `lsr' (rshft). }

  procedure set_ops(
      n: cg_tree_ptr_t); options(val_param);
  var
    dst: codegen_$uads_t;
    r: codegen_$uads_t;
    lab: codegen_$uads_t;
    cnt: integer32;
    save: integer;

    { proto_set - one unit of size: r := right; complemented for 21;
      r := left op r; dst := r.

      0x103678, 0x92 bytes: set_ops's frame from the dynamic link;
      the operator's instruction from tree_op_inst (+0xA0). }

    procedure proto_set(
        size: integer); options(val_param);
    begin
      emit(0, size, r, ops, 0);
      if n^.op = 21 then
        emit(12, size, r, cg_null_ads, 0);
      emit(tree_op_inst[n^.op], size, r, opr, 0);
      emit(0, size, dst, r, 0);
    end;

  begin
    save := cg_addr_next_areg;
    cg_addr_next_areg := 8;
    load_address(n^.opnd[1], opr);
    kill_register(opr.f2);
    load_address(n^.opnd[2], ops);
    kill_register(ops.f2);
    opr.f1 := 8;
    ops.f1 := 8;
    get_register(nil, 4, r);
    get_agg_temp(il_$node_ptr_t(n));
    load_address(n^.opnd[1], dst);
    kill_register(dst.f2);
    dst.f1 := 8;
    cnt := rshft(n^.desc.size, 2) - 1;
    if cnt >= 0 then begin
      if cnt > 0 then
        agg_loop_start(cnt, opt, lab);
      proto_set(4);
      if cnt > 0 then
        agg_loop_end(cnt, opt, lab);
    end;
    if (n^.desc.size & 2) <> 0 then
      proto_set(2);
    if (n^.desc.size & 1) <> 0 then
      proto_set(1);
    unlock(r);
    unlock(dst);
    unlock(opr);
    unlock(ops);
    cg_addr_next_areg := save;
  end;

  { compare_proc - an integer comparison (emit 18, a `cmp') of n's
    operands of class size: an operand a register variable's statement
    changes (register_tickle) loaded first; a constant kept on the right
    (the operands swapped, the condition by swap_cc), the left
    addressed with the class (4 or 5) a register holds it in; else the
    operand a register holds put on the left (inquire); a comparison
    with 0 by a `tst' (size 0, not for an address register) and its
    condition made a sign test (2, 3, 12, 13 to 6, 7, 10, 11); a word
    constant compared with an address register as a word.

    0x10386E, 0x572 bytes: two constants' sets after the code (0x103DE0:
    77..88, 101, 200; 0x103DFA: those and 195), movewlx's (0x0FFE4C)
    for the word constant; add_node.pas's swap_cc (0x2C2080, absolute);
    the register number compared unsigned (`bcc'); the sign tests by a
    jump table of 12 from 2; the operands swapped through opt. }

  procedure compare_proc(
      n: cg_tree_ptr_t;
      size: integer); options(val_param);
  var
    c: codegen_$uads_t;
    l: il_$node_ptr_t;
    r: il_$node_ptr_t;
  begin
    if register_tickle(n^.opnd[1], true) then begin
      load_operand(n^.opnd[1], size, opr);
      unlock(opr);
    end;
    if register_tickle(n^.opnd[2], true) then begin
      load_operand(n^.opnd[2], size, opr);
      unlock(opr);
    end;
    r := n^.opnd[2];
    l := n^.opnd[1];
    if r^.kind in [77..88, 101, 200] then begin
      if (l^.kind in [77..88, 101, 195, 200]) or (l^.kind = 93) or
          (l^.kind = 92) then
        load_operand(n^.opnd[1], size, opr)
      else begin
        if (size = 5) and (peek(l, 5) = 31) and
            (peek(n^.opnd[1], 4) <> 31) then
          size := 4
        else if (size = 4) and (peek(n^.opnd[1], 4) = 31) and
            (peek(n^.opnd[1], 5) <> 31) then
          size := 5;
        address(n^.opnd[1], size, opr);
      end;
    end
    else if l^.kind in [77..88, 101, 200] then begin
      n^.opnd[2] := l;
      n^.opnd[1] := r;
      n^.desc.w8 := swap_cc[n^.desc.w8];
      if n^.opnd[1]^.kind = 195 then
        load_operand(n^.opnd[1], size, opr)
      else if zero_check(n^.opnd[2]) and (size = 5) and
          (peek(n^.opnd[1], 5) = 31) and (peek(n^.opnd[1], 4) <> 31) then
        address(n^.opnd[1], 4, opr)
      else
        address(n^.opnd[1], size, opr);
    end
    else begin
      inquire(l, size, opr);
      if opr.f1 = 0 then begin
        if (size = 4) and (peek(n^.opnd[1], 5) <> 31) then begin
          size := 5;
          inquire(n^.opnd[1], size, opr);
        end
        else if (size = 5) and (peek(n^.opnd[1], 4) <> 31) then begin
          size := 4;
          inquire(n^.opnd[1], size, opr);
        end
        else begin
          inquire(n^.opnd[2], size, opr);
          if opr.f1 = 0 then
            if (size = 4) and (peek(n^.opnd[2], 5) <> 31) then begin
              size := 5;
              inquire(n^.opnd[2], size, opr);
            end
            else if (size = 5) and (peek(n^.opnd[2], 4) <> 31) then begin
              size := 4;
              inquire(n^.opnd[2], size, opr);
            end;
          if opr.f1 = 0 then
            load_operand(n^.opnd[1], size, opr)
          else begin
            l := n^.opnd[2];
            n^.opnd[2] := n^.opnd[1];
            n^.opnd[1] := l;
            n^.desc.w8 := swap_cc[n^.desc.w8];
          end;
        end;
      end;
    end;
    if zero_check(n^.opnd[2]) and not ((opr.f1 = 1) and (opr.f2 >= 8)) then
      address(n^.opnd[2], 0, ops)
    else if peek(n^.opnd[2], size) = 31 then begin
      if (size = 4) and (peek(n^.opnd[2], 5) <> 31) then
        address(n^.opnd[2], 5, ops)
      else if (size = 5) and (peek(n^.opnd[2], 4) <> 31) then
        address(n^.opnd[2], 4, ops)
      else
        address(n^.opnd[2], size, ops);
    end
    else
      address(n^.opnd[2], size, ops);
    if (opr.f1 <> 1) and (ops.f1 = 1) then begin
      opt := ops;
      ops := opr;
      opr := opt;
      n^.desc.w8 := swap_cc[n^.desc.w8];
    end;
    release(opr);
    release(ops);
    r := il_$node_ptr_t(ops.x);
    if (opr.f1 = 1) and (opr.f2 >= 8) and (ops.f1 = 3) and
        (r^.kind in [77..87, 101, 200]) and (r^.xl[2] <= 32767) and
        (r^.xl[2] >= -32768) then begin
      anyconst(r^.xl[2], 2, c);
      emit(18, 2, opr, c, 0);
      unlock(c);
    end
    else
      emit(18, size, opr, ops, 0);
    if zero_check(n^.opnd[2]) then
      case n^.desc.w6 of
        2: n^.desc.w6 := 6;
        3: n^.desc.w6 := 7;
        13: n^.desc.w6 := 11;
        12: n^.desc.w6 := 10;
        otherwise ;
      end;
  end;

  { round_fp_to_ieee - a value in a floating register (mode 13) rounded
    to its IEEE size by a store to memory and a load back: to n's own
    storage for a variable (109, 110), else to the temporary t (made
    when it is not one, allocate_temp); not for real constants (88,
    89).

    0x103E14, 0xD2 bytes: a, n and t by address; the class's width from
    delay.pas's table (0x169968). }

  procedure round_fp_to_ieee(
      in out a: codegen_$uads_t;
      in n: il_$node_ptr_t;
      in out t: il_$node_ptr_t;
      size: integer); options(val_param);
  var
    m: codegen_$uads_t;
  begin
    if (n^.kind <> 89) and (n^.kind <> 88) and (a.f1 = 13) then begin
      if (n^.kind = 110) or (n^.kind = 109) then
        address(n, 0, m)
      else begin
        if t^.kind <> 152 then
          t := allocate_temp(delay_378[size], true, n);
        address(t, size, m);
      end;
      emit(0, size, m, a, 0);
      emit(0, size, a, m, 0);
      unlock(m);
    end;
  end;

  { f_compare_proc - a floating comparison of n's operands (class w6, the
    condition w8): a constant left operand put on the right (switch);
    with a floating unit (cpu 2, 4, 8, 9, 10) and class 6 or 7 by
    emit_compare (FPA1) or the 68881's compare (emit 47), the operand
    a register variable's statement changes loaded first, a comparison
    with 0.0 a test (size 0), the operand a floating register holds put
    on the left; with -FRND (and not FPA1) both operands rounded to
    their IEEE size first (round_fp_to_ieee, the left one unless
    loaded); cg_fp_1000 set to n.  Else by the FPA (push_fpa_opr,
    emit_jsr 145 a test, 86 a compare) or the floating stack
    (stack_fp, the operand on the stack first; -FRND rounds the
    stacked value: 157 and 143), then purge_fp.  A comparison switched
    without its operands swapped (FPA1, classes 7, 13, 14) switched
    back after.

    0x103F8E, 0x6B2 bytes: generate's frame from the dynamic link (its
    -46, k, the operand put first); the constant tests evaluated whole
    (`seq', `or.b'); the comparisons with 0.0 by `jsr fpp_$' (0x0074
    0xFF34, then `bne': docs/rev889-patterns.md 19); the class compared
    unsigned (`bcs', `bls'); the operand by `move.l (0x24,A0,D2.w)' of
    k * 4; frnd the bit 6 of cargs +0x27F; cg_fp_result (0x356300)
    tested with check_use.

    Not known from the original:
    - what the 80 bytes of the frame above -84 held (not addressed). }

  procedure f_compare_proc(
      n: cg_tree_ptr_t); options(val_param);
  var
    tmp: il_$node_ptr_t;
    t: il_$node_ptr_t;
    sz: integer;
    swapped: boolean;
    loaded: boolean;

    { switch - n's operands swapped (the condition by swap_cc, generate's
      t1 and t2 with them), or, for FPA1 and classes 7, 13, 14, only
      noted; swapped toggled.

      0x103EE6, 0xA8 bytes: f_compare_proc's frame from the dynamic link
      and generate's from its; FPA1 (cpu 8) bit 2 of 0x2C3670. }

    procedure switch;
    begin
      if (8 in cargs_$options.cpu) and ((n^.desc.w6 = 7) or
          (n^.desc.w6 = 14) or (n^.desc.w6 = 13)) then
        swapped := not swapped
      else begin
        tmp := n^.opnd[1];
        n^.opnd[1] := n^.opnd[2];
        n^.opnd[2] := tmp;
        n^.desc.w8 := swap_cc[n^.desc.w8];
        tmp := t1;
        t1 := t2;
        t2 := tmp;
        swapped := not swapped;
      end;
    end;

  begin
    swapped := false;
    if not ((n^.opnd[2]^.kind = 198) or (n^.opnd[2]^.kind = 90) or
        (n^.opnd[2]^.kind = 89) or (n^.opnd[2]^.kind = 88)) then
      if (n^.opnd[1]^.kind = 88) or (n^.opnd[1]^.kind = 89) or
          (n^.opnd[1]^.kind = 198) or (n^.opnd[1]^.kind = 90) then
        switch;
    if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
        ((n^.desc.w6 = 7) or (n^.desc.w6 = 6)) then begin
      if cg_fp_count <> 0 then
        purge_fp;
      loaded := false;
      if register_tickle(n^.opnd[1], loaded) then begin
        load_operand(n^.opnd[1], n^.desc.w6, opr);
        loaded := true;
        address(n^.opnd[2], n^.desc.w6, ops);
      end
      else if register_tickle(n^.opnd[2], loaded) then begin
        switch;
        load_operand(n^.opnd[1], n^.desc.w6, opr);
        loaded := true;
        address(n^.opnd[2], n^.desc.w6, ops);
      end
      else if ((n^.opnd[2]^.kind = 89) or (n^.opnd[2]^.kind = 88)) and
          (n^.opnd[2]^.real_value = 0.0) then begin
        address(n^.opnd[1], n^.desc.w6, opr);
        address(n^.opnd[2], 0, ops);
      end
      else if 8 in cargs_$options.cpu then begin
        address(n^.opnd[1], n^.desc.w6, opr);
        address(n^.opnd[2], n^.desc.w6, ops);
      end
      else begin
        inquire(n^.opnd[1], n^.desc.w6, opr);
        if opr.f1 in [0, 1] then begin
          unlock(opr);
          inquire(n^.opnd[2], n^.desc.w6, opr);
          if opr.f1 in [0, 1] then begin
            unlock(opr);
            load_operand(n^.opnd[1], n^.desc.w6, opr);
            loaded := true;
          end
          else
            switch;
        end;
        address(n^.opnd[2], n^.desc.w6, ops);
      end;
      if cargs_$options.frnd and not (8 in cargs_$options.cpu) then begin
        t := il_$node_ptr_t(n);
        if not loaded then
          round_fp_to_ieee(opr, n^.opnd[1], t, n^.desc.w6);
        t := il_$node_ptr_t(n);
        round_fp_to_ieee(ops, n^.opnd[2], t, n^.desc.w6);
      end;
      if 8 in cargs_$options.cpu then
        emit_compare(n^.desc.w6, opr, ops, n^.desc.w8)
      else
        emit(47, n^.desc.w6, opr, ops, n^.desc.w6);
      cg_fp_1000 := il_$node_ptr_t(n);
      if (8 in cargs_$options.cpu) and swapped then begin
        unlock(opr);
        unlock(ops);
      end
      else begin
        release(opr);
        release(ops);
      end;
    end
    else begin
      if ((n^.opnd[2]^.kind = 89) or (n^.opnd[2]^.kind = 88)) and
          (n^.opnd[2]^.real_value = 0.0) then begin
        if 8 in cargs_$options.cpu then begin
          push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 16);
          emit_jsr(145, n^.desc.w6, 0);
          setresult(16, il_$node_ptr_t(n), n^.desc.w6);
          if n^.desc.w6 >= 8 then
            setresult(17, il_$node_ptr_t(n), n^.desc.w6);
        end
        else begin
          if not check_use(cg_fp_result, n^.opnd[1]) then
            stack_fp(1, n^.desc.w6, n^.opnd[1]);
          stack_fp(145, n^.desc.w6, nil);
        end;
      end
      else if 8 in cargs_$options.cpu then begin
        if peek(n^.opnd[2], n^.desc.w6) = 16 then begin
          k := 2;
          n^.desc.w8 := swap_cc[n^.desc.w8];
        end
        else
          k := 1;
        push_fpa_opr(n^.opnd[k], 1, n^.desc.w6, 16);
        if n^.desc.w6 > 7 then
          push_fpa_opr(n^.opnd[3 - k], 1, n^.desc.w6, 31)
        else
          push_fpa_opr(n^.opnd[3 - k], 1, n^.desc.w6, 17);
        emit_jsr(86, n^.desc.w6, n^.desc.w8);
        setresult(16, il_$node_ptr_t(n), n^.desc.w6);
        if n^.desc.w6 >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.w6);
      end
      else begin
        if check_use(cg_fp_result, n^.opnd[2]) then begin
          k := 2;
          n^.desc.w8 := swap_cc[n^.desc.w8];
        end
        else
          k := 1;
        if check_use(cg_fp_result, n^.opnd[k]) then begin
          if cargs_$options.frnd then
            if (n^.desc.w6 = 12) or (n^.desc.w6 = 8) then begin
              if n^.desc.w6 = 8 then
                sz := 6
              else
                sz := 7;
              stack_fp(157, sz, nil);
              stack_fp(143, sz, nil);
              stack_fp(157, sz, nil);
              stack_fp(143, sz, nil);
            end
            else
              stack_fp(157, n^.desc.w6, nil);
        end
        else
          stack_fp(1, n^.desc.w6, n^.opnd[k]);
        stack_fp(86, n^.desc.w6, n^.opnd[3 - k]);
      end;
      purge_fp;
    end;
    if swapped then begin
      switch;
      n^.desc.w8 := swap_cc[n^.desc.w8];
    end;
  end;

  { ld_addr - the address of n's operand (operator 26) in an address
    register: a common subexpression's (cg_addr_$load_addr_of_cse); a
    reference's (146, under a 164's +20) base pointer loaded (copied to
    another address register unless loaded into one) when no register
    holds it or its register may be taken (weight up to 15000, or 16000,
    and unlocked), x the reference; else a `lea' (emit 22) of the
    operand, of the constant kinds' sizes (81, 82, 84, 85 long; 80, 83
    word; others byte).

    0x104640, 0x18A bytes: the operand passed to addr_of_cse by a frame
    copy, n's slot to load_addr_of_cse; the weight compared unsigned
    (`bls'); the kinds by a jump table of 6 from 80. }

  procedure ld_addr(
      n: cg_tree_ptr_t;
      out a: codegen_$uads_t); options(val_param);
  var
    t: codegen_$uads_t;
    p: il_$node_ptr_t;
    cse: il_$node_ptr_t;
    w: integer;
    r: integer;
    ok: boolean;
  begin
    ok := false;
    p := n^.opnd[1];
    cse := p;
    if cg_addr_$addr_of_cse(cse) then
      cg_addr_$load_addr_of_cse(il_$node_ptr_t(n), a)
    else begin
      if p^.kind = 164 then
        p := p^.xp[5];
      if p^.kind = 146 then begin
        r := peek(p^.xp[6], 5);
        if r = 31 then
          ok := true
        else begin
          w := weight(r);
          if ((w <= 15000) or (w = 16000)) and (cg_addr_locks[r] = 0) then
            ok := true;
        end;
      end;
      if ok then begin
        load_operand(p^.xp[6], 5, a);
        if a.f1 <> 1 then begin
          t := a;
          get_register(nil, 5, a);
          emit(0, 5, a, t, 0);
        end;
        a.x := integer32(p);
      end
      else begin
        address(p, 0, t);
        release(t);
        get_register(il_$node_ptr_t(n), 5, a);
        case p^.kind of
          81, 82, 84, 85:
            emit(22, 4, a, t, 0);
          80, 83:
            emit(22, 2, a, t, 0);
          otherwise
            emit(22, 1, a, t, 0);
        end;
      end;
    end;
  end;

  { restore_alloc_temps - the operands' temporaries (152 nodes) put back
    in n, each wrapping its operand again (+16); temps cleared.

    0x1047CA, 0x84 bytes: generate's frame from the dynamic link. }

  procedure restore_alloc_temps;
  begin
    if t1 <> nil then
      if t1^.kind = 152 then begin
        t1^.xp[4] := n^.opnd[1];
        n^.opnd[1] := t1;
      end;
    if t2 <> nil then
      if t2^.kind = 152 then begin
        t2^.xp[4] := n^.opnd[2];
        n^.opnd[2] := t2;
      end;
    temps := false;
  end;

begin
  temps := false;
  rlen := n^.desc.rlen;
  w6 := n^.desc.w6;
  w8 := n^.desc.w8;
  t1 := nil;
  t2 := nil;
  if n^.count > 0 then begin
    t1 := n^.opnd[1];
    if t1 <> nil then
      if t1^.kind = 152 then begin
        temps := true;
        n^.opnd[1] := t1^.xp[4];
      end;
  end;
  if n^.count > 1 then begin
    t2 := n^.opnd[2];
    if t2 <> nil then
      if t2^.kind = 152 then begin
        temps := true;
        n^.opnd[2] := t2^.xp[4];
      end;
  end;
  case n^.op of

    { A value as it is (0, 17, 63): a floating one on the floating
      stack without a floating unit. }
    0, 17, 63:
      if (n^.desc.rlen = 7) or (n^.desc.rlen = 6) then begin
        if cargs_$options.cpu * [2, 4, 8, 9, 10] = [] then begin
          if not check_use(cg_fp_result, n^.opnd[1]) then
            stack_fp(1, n^.desc.rlen, n^.opnd[1]);
          fp_temp(il_$node_ptr_t(n), t1);
        end
        else begin
          load_fp_result(il_$node_ptr_t(n), -1, opr);
          unlock(opr);
        end;
      end
      else begin
        load_result(il_$node_ptr_t(n), -1, opr);
        unlock(opr);
      end;

    { Addition: an address and a long added in either order. }
    1: begin
      if cg_fp_count <> 0 then
        purge_fp;
      if (n^.desc.rlen = 5) and (peek(n^.opnd[2], 4) <> 31) then begin
        load_result(il_$node_ptr_t(n), -1, opr);
        address(n^.opnd[2], 4, ops);
      end
      else if (n^.desc.rlen = 5) and (peek(n^.opnd[1], 4) <> 31) then begin
        load_result(il_$node_ptr_t(n), -2, opr);
        address(n^.opnd[1], 4, ops);
      end
      else begin
        load_result(il_$node_ptr_t(n), 2, opr);
        if (n^.desc.rlen = 4) and (peek(n^.opnd[2], 5) <> 31) then
          address(n^.opnd[2], 5, ops)
        else if (n^.desc.rlen = 5) and (peek(n^.opnd[2], 4) <> 31) then
          address(n^.opnd[2], 4, ops)
        else
          address(n^.opnd[2], n^.desc.rlen, ops);
      end;
      emit(tree_op_inst[n^.op], n^.desc.rlen, opr, ops, 0);
      unlock(opr);
      release(ops);
    end;

    { Subtraction: when the right operand is the destination (cg_assign's
      flag, +6 bit 13) it is loaded, negated and the left added (the
      operands swapped back through t1 and t2). }
    2: begin
      if cg_fp_count <> 0 then
        purge_fp;
      inst := tree_op_inst[2];
      if ((il_$node_ptr_t(n)^.xw[3] & 16#2000) <> 0) and
          (n^.desc.rlen <> 5) then begin
        load_result(il_$node_ptr_t(n), -2, opr);
        n^.opnd[1] := t2;
        n^.opnd[2] := t1;
        inst := tree_op_inst[1];
        emit(11, n^.desc.rlen, opr, cg_null_ads, 0);
      end
      else
        load_result(il_$node_ptr_t(n), -1, opr);
      if (n^.desc.rlen = 5) and (peek(n^.opnd[2], 4) <> 31) then
        address(n^.opnd[2], 4, ops)
      else if (n^.desc.rlen = 4) and (peek(n^.opnd[2], 5) <> 31) then
        address(n^.opnd[2], 5, ops)
      else
        address(n^.opnd[2], n^.desc.rlen, ops);
      emit(inst, n^.desc.rlen, opr, ops, 0);
      unlock(opr);
      release(ops);
    end;

    3:
      mul_proc(n);
    4, 6:
      div_proc(n);

    { Negation, complement (7, 8). }
    7, 8: begin
      if cg_fp_count <> 0 then
        purge_fp;
      load_result(il_$node_ptr_t(n), -1, opr);
      emit(tree_op_inst[n^.op], n^.desc.rlen, opr, cg_null_ads, 0);
      unlock(opr);
    end;

    { And, or (9, 10): a long with a constant that fits a byte or a word
      (and: negative; or: positive) done as one. }
    9, 10: begin
      if cg_fp_count <> 0 then
        purge_fp;
      load_result(il_$node_ptr_t(n), 2, opr);
      tree_rlen := n^.desc.rlen;
      if n^.opnd[2]^.kind in [77..87, 101, 200] then
        if (n^.op = 9) and (n^.opnd[2]^.xl[2] < 0) and
            (tree_rlen = 4) then begin
          if n^.opnd[2]^.xl[2] >= -128 then
            tree_rlen := 1
          else if n^.opnd[2]^.xl[2] >= -32767 then
            tree_rlen := 2;
        end
        else if (n^.op = 10) and (n^.opnd[2]^.xl[2] > 0) and
            (tree_rlen = 4) then begin
          if n^.opnd[2]^.xl[2] <= 127 then
            tree_rlen := 1
          else if n^.opnd[2]^.xl[2] <= 32767 then
            tree_rlen := 2;
        end;
      address(n^.opnd[2], tree_rlen, ops);
      emit(tree_op_inst[n^.op], tree_rlen, opr, ops, 0);
      unlock(opr);
      release(ops);
    end;
    11:
      bit_test_proc(n);
    { A comparison (12) into a byte register (emit 19, an `scc') but for
      a 143 node. }
    12: begin
      compare_proc(n, n^.desc.w6);
      if n^.kind <> 143 then begin
        get_register(il_$node_ptr_t(n), 1, opt);
        emit(19, 1, opt, cg_null_ads, n^.desc.w8);
        unlock(opt);
      end;
    end;

    { An address indexed (13): by a constant an add, else a `lea' (emit
      22) of the base indexed by the operand's register. }
    13:
      if n^.opnd[2]^.kind in [77..87, 101, 200] then begin
        anyconst(n^.opnd[2]^.xl[2], 4, opr);
        load_result(il_$node_ptr_t(n), -1, ops);
        emit(1, 5, ops, opr, 0);
        unlock(opr);
        unlock(ops);
      end
      else begin
        load_operand(n^.opnd[2], n^.desc.w6, opr);
        load_operand(n^.opnd[1], 5, ops);
        release(ops);
        get_register(il_$node_ptr_t(n), 5, opt);
        ops.f1 := 4;
        ops.f3 := opr.f2;
        if n^.desc.w6 = 4 then
          ops.f5 := ops.f5 ! 2
        else
          ops.f5 := ops.f5 & ~2;
        emit(22, 5, opt, ops, 0);
        unlock(opt);
        release(opr);
      end;

    14:
      unpack_proc(n);

    { Calls (15, 16): the PEB's and the stored variable's records
      forgotten. }
    15, 16: begin
      if cg_fp_count <> 0 then
        purge_fp;
      gen_call(il_$node_ptr_t(n), nil);
      cg_fp_in_peb := nil;
      cg_fp_last_store := nil;
    end;

    { A conversion (18) from class w6 to rlen (by their widths, delay.pas's
      table): wider unsigned by a mask (the operand the destination,
      cg_assign's +6 bit 14) or a cleared register; wider signed by
      s_extend; narrower the operand as it is in the narrower class. }
    18:
      if delay_378[n^.desc.rlen] > delay_378[n^.desc.w6] then begin
        if (n^.desc.flags & 16#4000) = 0 then begin
          if (il_$node_ptr_t(n)^.xw[3] & 16#4000) <> 0 then begin
            tree_rlen := n^.desc.rlen;
            n^.desc.rlen := n^.desc.w6;
            load_result(il_$node_ptr_t(n), 1, opr);
            anyconst(rshft(-1, 32 - delay_378[n^.desc.rlen] * 8),
                tree_rlen, ops);
            emit(3, tree_rlen, opr, ops, 0);
            n^.desc.rlen := tree_rlen;
            cg_addr_regs[opr.f2].size := tree_rlen;
          end
          else begin
            address(n^.opnd[1], n^.desc.w6, ops);
            get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
            anyconst(0, n^.desc.rlen, opw);
            emit(0, n^.desc.rlen, opr, opw, 0);
            emit(0, n^.desc.w6, opr, ops, 0);
            unlock(opw);
          end;
          release(ops);
        end
        else begin
          tree_rlen := n^.desc.rlen;
          n^.desc.rlen := n^.desc.w6;
          load_result(il_$node_ptr_t(n), -1, opr);
          s_extend(opr, n^.desc.rlen, tree_rlen);
          n^.desc.rlen := tree_rlen;
          cg_addr_regs[opr.f2].size := tree_rlen;
        end;
        unlock(opr);
      end
      else begin
        tree_rlen := n^.desc.rlen;
        n^.desc.rlen := n^.desc.w6;
        load_result(il_$node_ptr_t(n), -1, opr);
        n^.desc.rlen := tree_rlen;
        cg_addr_regs[opr.f2].size := tree_rlen;
        unlock(opr);
      end;
    19, 20, 21:
      set_ops(n);
    { An aggregate converted to size w6 (22) in n's temporary by
      multi_assign_proc (tree_asn): the source cut down, or copied with
      the rest filled with zeros (fill), through cg_tree_1b4 (+16 1,
      +24 and +28 the aggregate, +32 the difference). }
    22: begin
      save := cg_addr_next_areg;
      cg_addr_next_areg := 8;
      tree_asn.right := n^.opnd[1];
      get_agg_temp(il_$node_ptr_t(n));
      tree_asn.left := n^.opnd[1];
      cg_tree_1b4^.xw[8] := 1;
      if n^.desc.w6 >= n^.desc.size then begin
        cg_tree_1b4^.xp[6] := tree_asn.right;
        cg_tree_1b4^.xp[7] := tree_asn.right;
        cg_tree_1b4^.xl[8] := n^.desc.w6 - n^.desc.size;
        tree_asn.right := cg_tree_1b4;
        tree_asn.desc.size := n^.desc.size;
      end
      else begin
        cg_tree_1b4^.xp[6] := tree_asn.left;
        cg_tree_1b4^.xp[7] := tree_asn.left;
        cg_tree_1b4^.xl[8] := n^.desc.size - n^.desc.w6;
        fill(tree_asn.left, 0, n^.desc.size - n^.desc.w6);
        tree_asn.left := cg_tree_1b4;
        tree_asn.desc.size := n^.desc.w6;
      end;
      multi_assign_proc(tree_asn);
      cg_addr_next_areg := save;
    end;

    23, 24:
      agg_compare_proc(n);
    25:
      bit_set_proc(n);

    { An address (26): of a variable or a reference as a long, by its
      d(An) operand added to the register (a `lea'-less add), else
      ld_addr's. }
    26: begin
      if cg_fp_count <> 0 then
        purge_fp;
      setobjcache(n^.opnd[1], getobjcache(il_$node_ptr_t(n)));
      if ((n^.opnd[1]^.kind = 109) or (n^.opnd[1]^.kind = 110) or
          (n^.opnd[1]^.kind = 147) or (n^.opnd[1]^.kind = 146)) and
          (n^.desc.rlen = 4) then begin
        address(n^.opnd[1], 5, ops);
        if ops.f1 <> 2 then begin
          unlock(ops);
          ld_addr(n, opr);
        end
        else begin
          get_temp_register(il_$node_ptr_t(n), 4, opr);
          if ops.y <> 0 then begin
            anyconst(ops.y, 4, opt);
            emit(0, 4, opr, opt, 0);
            unlock(opt);
            inst := 1;
          end
          else
            inst := 0;
          address_reg(ops.f2, opt);
          emit(inst, 4, opr, opt, 0);
          release(ops);
        end;
      end
      else
        ld_addr(n, opr);
      unlock(opr);
      setresult(opr.f2, il_$node_ptr_t(n), n^.desc.rlen);
    end;
    27:
      shift_proc(n, 3);
    28:
      shift_proc(n, 2);

    { The absolute value (29): negated when negative. }
    29: begin
      if cg_fp_count <> 0 then
        purge_fp;
      load_result(il_$node_ptr_t(n), -1, opr);
      emit(18, n^.desc.rlen, opr, cg_zero_ads, 0);
      address(templabel, 0, opt);
      emit(20, 5, opt, cg_null_ads, 10);
      emit(11, n^.desc.rlen, opr, cg_null_ads, 0);
      emit(32, 5, opt, cg_null_ads, 0);
      unlock(opr);
      release(opt);
    end;

    { Floating addition (34): inline (prefers_inline_float: the FPA1's
      emit_mul_add or the 68881's add, emit 43), else by the FPA
      (fpa_fop_proc, the result in FP0 and for 8 bytes and more FP1) or
      the floating stack (fop_proc). }
    34:
      if cg_tree_$prefers_inline_float(il_$node_ptr_t(n)) then begin
        load_fp_result(il_$node_ptr_t(n), 2, opr);
        tree_rlen := fp_rlen(n^.desc, 2);
        address(n^.opnd[2], tree_rlen, ops);
        if 8 in cargs_$options.cpu then
          emit_mul_add(43, n^.desc.rlen, opr, ops)
        else
          emit(43, n^.desc.rlen, opr, ops, tree_rlen);
        unlock(opr);
        release(ops);
      end
      else if 8 in cargs_$options.cpu then begin
        fpa_fop_proc(il_$node_ptr_t(n), 10, 10);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        if temps then
          restore_alloc_temps;
        fop_proc(il_$node_ptr_t(n), 10, 10);
      end;

    { Floating subtraction (35): as 34 (emit 44), the right operand the
      destination (cg_assign's +6 bit 13) loaded, negated (emit 49) and
      the left added. }
    35:
      if cg_tree_$prefers_inline_float(il_$node_ptr_t(n)) then begin
        opr.f2 := peek(n^.opnd[1], n^.desc.rlen);
        tree_rlen := fp_rlen(n^.desc, 2);
        ops.f2 := peek(n^.opnd[2], tree_rlen);
        inst := 44;
        if (il_$node_ptr_t(n)^.xw[3] & 16#2000) <> 0 then begin
          load_fp_result(il_$node_ptr_t(n), -2, opr);
          n^.opnd[1] := t2;
          n^.opnd[2] := t1;
          inst := 43;
          if 8 in cargs_$options.cpu then
            emit_neg(n^.desc.rlen, opr, opr)
          else
            emit(49, n^.desc.rlen, opr, opr, n^.desc.rlen);
        end
        else
          load_fp_result(il_$node_ptr_t(n), -1, opr);
        address(n^.opnd[2], tree_rlen, ops);
        if 8 in cargs_$options.cpu then begin
          if inst = 43 then
            emit_mul_add(inst, n^.desc.rlen, opr, ops)
          else
            emit_div_sub(inst, n^.desc.rlen, opr, ops);
        end
        else
          emit(inst, n^.desc.rlen, opr, ops, tree_rlen);
        unlock(opr);
        release(ops);
      end
      else if 8 in cargs_$options.cpu then begin
        fpa_fop_proc(il_$node_ptr_t(n), 19, 28);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        if temps then
          restore_alloc_temps;
        fop_proc(il_$node_ptr_t(n), 19, 28);
      end;

    { Floating multiplication (36): as 34 (emit 45); by a power of two
      (is_scale_candidate) a scale (emit 69, the 68881's `fscale') by
      its exponent (of the reciprocal for a fraction), negated first for
      a negative constant; with -FRND (not FPA1) the result rounded to
      its IEEE size. }
    36:
      if cg_tree_$prefers_inline_float(il_$node_ptr_t(n)) then begin
        load_fp_result(il_$node_ptr_t(n), 2, opr);
        tree_rlen := fp_rlen(n^.desc, 2);
        inst := 45;
        if is_scale_candidate(n) then begin
          dv.d := n^.opnd[2]^.real_value;
          if (dv.lo = 0) and ((dv.hi & 16#FFFFF) = 0) then
            e := rshft(dv.hi & 16#7FF00000, 20) - 1023
          else begin
            dv.d := 1.0 / dv.d;
            e := -(rshft(dv.hi & 16#7FF00000, 20) - 1023);
          end;
          if (e >= -128) and (e <= 127) then
            tree_rlen := 1
          else
            tree_rlen := 2;
          anyconst(e, tree_rlen, ops);
          inst := 69;
          if dv.d < 0.0 then
            emit(49, n^.desc.rlen, opr, opr, n^.desc.rlen);
        end
        else if n^.opnd[1] = n^.opnd[2] then begin
          ops := opr;
          cg_addr_locks[opr.f2] := cg_addr_locks[opr.f2] + 1;
        end
        else
          address(n^.opnd[2], tree_rlen, ops);
        if 8 in cargs_$options.cpu then
          emit_mul_add(inst, n^.desc.rlen, opr, ops)
        else
          emit(inst, n^.desc.rlen, opr, ops, tree_rlen);
        if cargs_$options.frnd and not (8 in cargs_$options.cpu) then begin
          t := il_$node_ptr_t(n);
          round_fp_to_ieee(opr, il_$node_ptr_t(n), t, n^.desc.rlen);
        end;
        release(ops);
        unlock(opr);
      end
      else if 8 in cargs_$options.cpu then begin
        fpa_fop_proc(il_$node_ptr_t(n), 37, 37);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        if temps then
          restore_alloc_temps;
        fop_proc(il_$node_ptr_t(n), 37, 37);
      end;

    { Floating division (37): as 36 (emit 46); by a power of two a
      multiplication by the reciprocal constant (cpu 5, 8, 9, 10:
      rlcontk, dpcontk) or a scale by the negated exponent. }
    37:
      if cg_tree_$prefers_inline_float(il_$node_ptr_t(n)) then begin
        load_fp_result(il_$node_ptr_t(n), -1, opr);
        tree_rlen := fp_rlen(n^.desc, 2);
        inst := 46;
        if is_scale_candidate(n) then begin
          dv.d := n^.opnd[2]^.real_value;
          if cargs_$options.cpu * [5, 8, 9, 10] <> [] then begin
            ops.f1 := 3;
            ops.f2 := 31;
            ops.x := integer32(n^.opnd[2]);
            if n^.opnd[2]^.kind = 88 then
              ops.x := integer32(rlcontk(1.0 / dv.d))
            else
              ops.x := integer32(dpcontk(1.0 / dv.d));
            inst := 45;
          end
          else begin
            if (dv.lo = 0) and ((dv.hi & 16#FFFFF) = 0) then
              e := -(rshft(dv.hi & 16#7FF00000, 20) - 1023)
            else begin
              dv.d := 1.0 / dv.d;
              e := rshft(dv.hi & 16#7FF00000, 20) - 1023;
            end;
            ops.x := integer32(smcontk(81, e));
            if (e >= -128) and (e <= 127) then
              tree_rlen := 1
            else
              tree_rlen := 2;
            anyconst(e, tree_rlen, ops);
            inst := 69;
            if dv.d < 0.0 then
              emit(49, n^.desc.rlen, opr, opr, n^.desc.rlen);
          end;
        end
        else
          address(n^.opnd[2], tree_rlen, ops);
        if 8 in cargs_$options.cpu then begin
          if inst = 45 then
            emit_mul_add(inst, n^.desc.rlen, opr, ops)
          else
            emit_div_sub(inst, n^.desc.rlen, opr, ops);
        end
        else
          emit(inst, n^.desc.rlen, opr, ops, tree_rlen);
        if cargs_$options.frnd and not (8 in cargs_$options.cpu) then begin
          t := il_$node_ptr_t(n);
          round_fp_to_ieee(opr, il_$node_ptr_t(n), t, n^.desc.rlen);
        end;
        release(ops);
        unlock(opr);
      end
      else if 8 in cargs_$options.cpu then begin
        fpa_fop_proc(il_$node_ptr_t(n), 46, 55);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        if temps then
          restore_alloc_temps;
        fop_proc(il_$node_ptr_t(n), 46, 55);
      end;

    { Floating negation (38): with a floating unit (classes 6, 7) inline
      (emit_neg, emit 49), from the operand's floating register when it
      is the destination's (cg_assign's +6 bit 14); the extended classes
      (8, 12) by the FPA's or the floating stack's 83 and the routine
      tree_fn_rtn[14]; else fpa_fop_proc or fop_proc (83). }
    38:
      if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
          ((n^.desc.rlen = 7) or (n^.desc.rlen = 6)) then begin
        if cg_fp_count <> 0 then
          purge_fp;
        tree_rlen := fp_rlen(n^.desc, 1);
        if ((il_$node_ptr_t(n)^.xw[3] & 16#4000) <> 0) and
            (peek(n^.opnd[1], n^.desc.rlen) in [16..23]) then begin
          load_fp_result(il_$node_ptr_t(n), -1, ops);
          opr := ops;
        end
        else begin
          address(n^.opnd[1], tree_rlen, ops);
          release(ops);
          get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
        end;
        if 8 in cargs_$options.cpu then
          emit_neg(n^.desc.rlen, opr, ops)
        else
          emit(49, n^.desc.rlen, opr, ops, tree_rlen);
        unlock(opr);
      end
      else if (n^.desc.rlen = 12) or (n^.desc.rlen = 8) then begin
        if 8 in cargs_$options.cpu then begin
          push_fpa_opr(n^.opnd[1], 1, n^.desc.rlen, 16);
          emit_jsr(83, n^.desc.rlen, 0);
          emit_jsr(tree_fn_rtn[14], n^.desc.rlen, 0);
          fpa_temp(il_$node_ptr_t(n), t1);
          setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
          if n^.desc.rlen >= 8 then
            setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
        end
        else begin
          if not check_use(cg_fp_result, n^.opnd[1]) then
            stack_fp(1, n^.desc.rlen, n^.opnd[1]);
          stack_fp(83, n^.desc.rlen, nil);
          stack_fp(tree_fn_rtn[14], n^.desc.rlen, nil);
          fp_temp(il_$node_ptr_t(n), t1);
        end;
      end
      else if 8 in cargs_$options.cpu then begin
        fpa_fop_proc(il_$node_ptr_t(n), 83, 83);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else begin
        if temps then
          restore_alloc_temps;
        fop_proc(il_$node_ptr_t(n), 83, 83);
      end;

    { A conversion to or from a floating class (39, from w6 to rlen): a
      pair of operands (a complex value) by the FPA or the floating
      stack (tree_fn_rtn[15]); a double or single to a long by the fast
      math library (cpu 9); an unsigned long to a floating value (155,
      156) and back (159, 160) by the FPA or the stack; with a floating
      unit (not the extended classes, nor an integer result with cpu 9
      or 10) inline: an integer to a floating register (emit 0 with the
      operand's class as x; the 68881 alone through `fintrz', emit 60,
      for an integer result), FPA1 by emit_extend, a double rounded to
      a single with -FRND (or -XANSI with -STD) on the 68881, a
      conversion of a single converted from a 110 variable's long taken
      from the variable; else the floating stack or the FPA (75 and 77
      from an integer, 71, 73, 79 to the class, 143 between the extended
      classes; emit_clr_fp1 for 79 on the FPA), the result in D0 up to
      4 bytes (purge_fp), else kept (fp_temp, fpa_temp).

      0x106E7E, 0xE2C bytes: the classes compared unsigned (`bhi',
      `bls', `bcc'); the conversions' routines by a jump table of 11 on
      rlen - 2 (the others leave D2 as it was); the classes' tests
      evaluated whole (`seq', `sne', `or.b'); xansi bit 5 of cargs
      +0x28B, std bit 2 of +0x27C; cg_addr_locks[16] (0x3550B8). }
    39:
      if n^.count > 1 then begin
        if 8 in cargs_$options.cpu then begin
          push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 16);
          emit_jsr(tree_fn_rtn[15], n^.desc.rlen, 0);
          push_fpa_opr(n^.opnd[2], 1, n^.desc.w6, 17);
          emit_jsr(tree_fn_rtn[15], n^.desc.rlen, 0);
          fpa_temp(il_$node_ptr_t(n), t1);
          setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
          if n^.desc.rlen >= 8 then
            setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
        end
        else begin
          if check_use(cg_fp_result, n^.opnd[1]) then begin
            stack_fp(tree_fn_rtn[15], n^.desc.rlen, nil);
            stack_fp(1, n^.desc.w6, n^.opnd[2]);
            stack_fp(tree_fn_rtn[15], n^.desc.rlen, nil);
          end
          else begin
            stack_fp(1, n^.desc.w6, n^.opnd[2]);
            stack_fp(tree_fn_rtn[15], n^.desc.rlen, nil);
            stack_fp(1, n^.desc.w6, n^.opnd[1]);
          end;
          fp_temp(il_$node_ptr_t(n), t1);
        end;
      end
      else if (9 in cargs_$options.cpu) and (n^.desc.rlen = 4) and
          ((n^.desc.w6 = 7) or (n^.desc.w6 = 6)) then
        cg_tree_$call_fast_math_lib(il_$node_ptr_t(n))
      else if ((n^.desc.flags & 16#4000) = 0) and (n^.desc.w6 = 4) and
          ((n^.desc.rlen = 7) or (n^.desc.rlen = 6)) then begin
        if 8 in cargs_$options.cpu then begin
          push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 0);
          if n^.desc.rlen = 7 then
            emit_jsr(156, n^.desc.w6, 0)
          else
            emit_jsr(155, n^.desc.w6, 0);
          fpa_temp(il_$node_ptr_t(n), t1);
          setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        end
        else begin
          if n^.desc.rlen = 7 then
            stack_fp(156, n^.desc.w6, n^.opnd[1])
          else
            stack_fp(155, n^.desc.w6, n^.opnd[1]);
          fp_temp(il_$node_ptr_t(n), t1);
        end;
      end
      else if ((n^.desc.flags & 16#4000) = 0) and
          ((n^.desc.w6 = 7) or (n^.desc.w6 = 6)) and
          (n^.desc.rlen = 4) then begin
        if 8 in cargs_$options.cpu then begin
          push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 16);
          if n^.desc.w6 = 7 then
            emit_jsr(160, n^.desc.w6, 0)
          else
            emit_jsr(159, n^.desc.w6, 0);
        end
        else begin
          if not check_use(cg_fp_result, n^.opnd[1]) then
            stack_fp(1, n^.desc.w6, n^.opnd[1]);
          stack_fp(159, n^.desc.w6, nil);
          if cg_fp_count <> 0 then
            purge_fp;
        end;
        setresult(0, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
          not ((n^.desc.rlen = 12) or (n^.desc.rlen = 8)) and
          not ((cargs_$options.cpu * [9, 10] <> []) and
               (n^.desc.rlen <= 4)) then begin
        if cg_fp_count <> 0 then
          purge_fp;
        if n^.desc.w6 <= 4 then begin
          if (n^.desc.rlen = 12) or (n^.desc.rlen = 8) then begin
            address_reg(16, opr);
            cg_addr_locks[16] := cg_addr_locks[16] + 1;
            if n^.desc.rlen = 8 then
              tree_rlen := 6
            else
              tree_rlen := 7;
          end
          else begin
            get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
            tree_rlen := n^.desc.rlen;
          end;
          address(n^.opnd[1], n^.desc.w6, ops);
          if (4 in cargs_$options.cpu) and
              (cargs_$options.cpu * [9, 10] = []) and
              (n^.desc.rlen <= 4) then begin
            release(ops);
            get_temp_register(n^.opnd[1], n^.desc.w6, opu);
            emit(60, tree_rlen, opu, ops, 0);
            emit(0, tree_rlen, opr, opu, n^.desc.w6);
            kill_register(opu.f2);
            unlock(opu);
          end
          else begin
            if 8 in cargs_$options.cpu then
              emit_extend(tree_rlen, opr, ops, n^.desc.w6)
            else
              emit(0, tree_rlen, opr, ops, n^.desc.w6);
            release(ops);
          end;
          unlock(opr);
        end
        else if n^.desc.rlen <= 4 then begin
          if n^.desc.w6 = 8 then
            tree_rlen := 6
          else
            tree_rlen := n^.desc.w6;
          if ((n^.desc.w6 = 12) or (n^.desc.w6 = 8)) and
              not (peek(n^.opnd[1], n^.desc.w6) in [16..23]) then begin
            address(n^.opnd[1], 0, opt);
            if n^.desc.w6 = 8 then begin
              get_register(nil, 6, ops);
              if 8 in cargs_$options.cpu then
                emit_extend(6, ops, opt, n^.desc.w6)
              else
                emit(0, 6, ops, opt, 6);
            end
            else begin
              get_register(nil, 7, ops);
              if 8 in cargs_$options.cpu then
                emit_extend(7, ops, opt, n^.desc.w6)
              else
                emit(0, 7, ops, opt, 7);
            end;
            release(opt);
          end
          else
            load_operand(n^.opnd[1], n^.desc.w6, ops);
          get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
          if (4 in cargs_$options.cpu) and
              not (10 in cargs_$options.cpu) then begin
            release(ops);
            get_temp_register(n^.opnd[1], tree_rlen, opu);
            emit(60, tree_rlen, opu, ops, 0);
            emit(0, tree_rlen, opr, opu, n^.desc.rlen);
            kill_register(opu.f2);
            unlock(opu);
          end
          else begin
            if 8 in cargs_$options.cpu then begin
              if n^.desc.w6 = 8 then
                emit_extend(n^.desc.rlen, opr, ops, 6)
              else
                emit_extend(n^.desc.rlen, opr, ops, n^.desc.w6);
            end
            else
              emit(0, tree_rlen, opr, ops, n^.desc.rlen);
            release(ops);
          end;
          unlock(opr);
        end
        else if ((n^.desc.w6 = 7) or (n^.desc.w6 = 6)) and
            (8 in cargs_$options.cpu) and (n^.desc.rlen < 8) then begin
          get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
          address(n^.opnd[1], n^.desc.w6, ops);
          emit_extend(n^.desc.rlen, opr, ops, n^.desc.w6);
          release(ops);
          unlock(opr);
        end
        else if (cargs_$options.frnd or
            (cargs_$options.xansi and cargs_$options.std)) and
            (4 in cargs_$options.cpu) and (n^.desc.rlen = 6) and
            (n^.desc.w6 = 7) then begin
          load_fp_result(il_$node_ptr_t(n), -1, opr);
          t := il_$node_ptr_t(n);
          round_fp_to_ieee(opr, il_$node_ptr_t(n), t, n^.desc.rlen);
          setresult(opr.f2, il_$node_ptr_t(n), n^.desc.rlen);
          unlock(opr);
        end
        else if (n^.desc.rlen = 12) or (n^.desc.rlen = 8) then begin
          if peek(n^.opnd[1], n^.desc.w6) <> 16 then begin
            address_reg(16, opr);
            address(n^.opnd[1], n^.desc.w6, ops);
            if 8 in cargs_$options.cpu then
              emit_extend(tree_rlen, opr, ops, n^.desc.w6)
            else
              emit(0, tree_rlen, opr, ops, n^.desc.w6);
            release(ops);
          end;
        end
        else begin
          t := n^.opnd[1];
          if (n^.desc.rlen = 7) and (n^.desc.w6 = 6) and
              ((t^.kind = 138) or (t^.kind = 137)) and
              (cg_tree_ptr_t(t)^.op = 39) and
              (cg_tree_ptr_t(t)^.opnd[1]^.kind = 110) and
              ((ord(cg_tree_ptr_t(t)^.opnd[1]^.xc[10]) & 15) = 6) and
              not (8 in cargs_$options.cpu) then begin
            address(cg_tree_ptr_t(t)^.opnd[1], 8, ops);
            get_register(t, 6, opr);
            emit(0, 6, opr, ops, 6);
            release(ops);
            unlock(opr);
          end;
          if n^.desc.w6 = 8 then
            n^.desc.w6 := 6
          else if n^.desc.w6 = 12 then
            n^.desc.w6 := 7;
          load_fp_result(il_$node_ptr_t(n), -1, opr);
          unlock(opr);
          if (8 in cargs_$options.cpu) and (n^.desc.rlen = 7) and
              (n^.desc.w6 = 6) then
            emit_extend(n^.desc.rlen, opr, opr, n^.desc.w6);
        end;
      end
      else begin
        if n^.desc.w6 <= 4 then begin
          if 8 in cargs_$options.cpu then begin
            push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 16);
            if n^.desc.rlen = 7 then
              emit_jsr(77, n^.desc.w6, 0)
            else
              emit_jsr(75, n^.desc.w6, 0);
          end
          else if n^.desc.rlen = 7 then
            stack_fp(77, n^.desc.w6, n^.opnd[1])
          else
            stack_fp(75, n^.desc.w6, n^.opnd[1]);
        end
        else begin
          if 8 in cargs_$options.cpu then
            push_fpa_opr(n^.opnd[1], 1, n^.desc.w6, 16)
          else if not check_use(cg_fp_result, n^.opnd[1]) then
            stack_fp(1, n^.desc.w6, n^.opnd[1]);
          case n^.desc.rlen of
            2: inst := 71;
            4: inst := 73;
            6, 7, 8, 12: inst := 79;
            otherwise ;
          end;
          if n^.desc.w6 = 8 then begin
            if n^.desc.rlen = 12 then begin
              if 8 in cargs_$options.cpu then begin
                emit_jsr(143, 6, 0);
                emit_jsr(79, 6, 0);
                emit_jsr(143, 7, 0);
                emit_jsr(79, 6, 0);
              end
              else begin
                stack_fp(143, 6, nil);
                stack_fp(79, 6, nil);
                stack_fp(143, 7, nil);
                stack_fp(79, 6, nil);
              end;
            end
            else if n^.desc.rlen <> 6 then begin
              if 8 in cargs_$options.cpu then begin
                if inst = 79 then
                  emit_clr_fp1(6)
                else
                  emit_jsr(inst, 6, 0);
              end
              else
                stack_fp(inst, 6, nil);
            end;
          end
          else if n^.desc.w6 = 12 then begin
            if n^.desc.rlen = 8 then begin
              if 8 in cargs_$options.cpu then begin
                emit_jsr(143, 7, 0);
                emit_jsr(79, 7, 0);
                emit_jsr(143, 7, 0);
                emit_jsr(79, 7, 0);
              end
              else begin
                stack_fp(143, 7, nil);
                stack_fp(79, 7, nil);
                stack_fp(143, 7, nil);
                stack_fp(79, 7, nil);
              end;
            end
            else if n^.desc.rlen <> 7 then begin
              if 8 in cargs_$options.cpu then
                emit_jsr(inst, 7, 0)
              else
                stack_fp(inst, 7, nil);
            end;
          end
          else if ((n^.desc.rlen <> 8) or (n^.desc.w6 <> 6)) and
              not ((n^.desc.rlen = 12) and (n^.desc.w6 = 7)) then begin
            if 8 in cargs_$options.cpu then begin
              if inst = 79 then
                emit_clr_fp1(n^.desc.w6)
              else
                emit_jsr(inst, n^.desc.w6, 0);
            end
            else
              stack_fp(inst, n^.desc.w6, nil);
          end;
        end;
        if ((n^.desc.rlen = 12) or (n^.desc.rlen = 8)) and
            not ((n^.desc.w6 = 12) or (n^.desc.w6 = 8)) then begin
          if 8 in cargs_$options.cpu then
            emit_clr_fp1(7)
          else
            stack_fp(79, n^.desc.rlen, nil);
        end;
        if n^.desc.rlen <= 4 then begin
          purge_fp;
          setresult(0, il_$node_ptr_t(n), n^.desc.rlen);
        end
        else if 8 in cargs_$options.cpu then
          fpa_temp(il_$node_ptr_t(n), t1)
        else
          fp_temp(il_$node_ptr_t(n), t1);
        if 8 in cargs_$options.cpu then begin
          setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
          if n^.desc.rlen >= 8 then
            setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
        end;
      end;

    { 40: a floating comparison (f_compare_proc) into a byte register
      (emit 19, or 48 when the 68881's condition is pending in
      cg_fp_1000; FPA1's conditions 7, 13, 14 as 5, the others 4) but
      for a 143 node. }
    40: begin
      cg_fp_1000 := nil;
      f_compare_proc(n);
      if n^.kind <> 143 then begin
        get_register(il_$node_ptr_t(n), 1, opt);
        if 8 in cargs_$options.cpu then begin
          if (n^.desc.w8 = 7) or (n^.desc.w8 = 14) or
              (n^.desc.w8 = 13) then
            emit(19, 1, opt, cg_null_ads, 5)
          else
            emit(19, 1, opt, cg_null_ads, 4);
        end
        else if check_use(cg_fp_1000, il_$node_ptr_t(n)) then
          emit(48, 1, opt, cg_null_ads, n^.desc.w8)
        else
          emit(19, 1, opt, cg_null_ads, n^.desc.w8);
        unlock(opt);
      end;
    end;

    { A builtin math function (41, w6 the function): with the 68881
      (cpu 4) or the 160 (2) for the functions they have, or FPA1 for 0,
      9, 12, 13, inline on classes 6 and 7 (the fast math library's
      routine first with -CPU MATHLIB: call_fast_math_lib): the 68881's
      instruction (tree_fn_inst; function 4 rounded to the nearest
      integer by hand: a compare with 0.5, emit 42 a branch, 44 an add
      of 1.0, 56); 12 and 13 a compare and a conditional move (emit 47,
      42; FPA1 emit_compare, emit_assign).  Else function 15 (the
      second half of an extended value: its operand's address plus the
      size, through a `lea' for an index out of a byte's reach without
      the 68020); 11 of up to 7 bytes with the 68881 alone by
      adjust_before_round and the 68881's `fintrz' (emit 60), the
      result in D0 up to 4 bytes; else by the FPA or the floating stack
      (tree_fn_rtn: 137 and 132 as both operations, the others with
      104; the operands' floating registers spilled first for class 7). }
    41: begin
      inl := ((4 in cargs_$options.cpu) and
          (n^.desc.w6 in [0..7, 9, 10, 12, 13])) or
          ((2 in cargs_$options.cpu) and
          (n^.desc.w6 in [0..4, 6, 7, 9, 10, 12, 13]));
      if not inl then
        inl := (8 in cargs_$options.cpu) and ((n^.desc.w6 = 0) or
            (n^.desc.w6 = 9) or (n^.desc.w6 = 13) or (n^.desc.w6 = 12));
      if inl then
        if not ((n^.desc.w6 = 0) or (n^.desc.w6 = 9) or
            (n^.desc.w6 = 12)) then
          inl := not (10 in cargs_$options.cpu) or (n^.desc.w6 = 13);
      if inl then
        inl := (n^.desc.rlen = 7) or (n^.desc.rlen = 6);
      if not inl then begin
        if (9 in cargs_$options.cpu) and tree_math[n^.desc.w6].ok then
          cg_tree_$call_fast_math_lib(il_$node_ptr_t(n))
        else if n^.desc.w6 = 15 then begin
          if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then begin
            if cg_fp_count <> 0 then
              purge_fp;
            if ((il_$node_ptr_t(n)^.xw[3] & 16#4000) <> 0) and
                (peek(n^.opnd[1], n^.desc.rlen) in [16..23]) then begin
              load_fp_result(il_$node_ptr_t(n), -1, ops);
              opr := ops;
            end
            else begin
              if n^.desc.rlen = 6 then
                address(n^.opnd[1], 8, ops)
              else
                address(n^.opnd[1], 12, ops);
              release(ops);
              get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
            end;
            if not (3 in cargs_$options.cpu) and (ops.f1 = 4) and
                ((ops.y + n^.desc.size > 127) or
                 (ops.y + n^.desc.size < -128)) then begin
              unlock(ops);
              get_temp_register(n^.opnd[1], 5, opt);
              emit(22, 4, opt, ops, 0);
              opt.f1 := 2;
              opt.y := ops.y + n^.desc.size;
              ops := opt;
            end
            else
              ops.y := ops.y + n^.desc.size;
            emit(0, n^.desc.rlen, opr, ops, n^.desc.rlen);
            unlock(opr);
          end
          else if 8 in cargs_$options.cpu then begin
            if n^.desc.rlen = 6 then
              push_fpa_opr(n^.opnd[1], 1, 8, 16)
            else
              push_fpa_opr(n^.opnd[1], 1, 12, 16);
            emit_jsr(tree_fn_rtn[15], n^.desc.rlen, 0);
            fpa_temp(il_$node_ptr_t(n), t1);
            setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
            if n^.desc.rlen >= 8 then
              setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
          end
          else begin
            if not check_use(cg_fp_result, n^.opnd[1]) then
              if n^.desc.rlen = 6 then
                stack_fp(1, 8, n^.opnd[1])
              else
                stack_fp(1, 12, n^.opnd[1]);
            stack_fp(tree_fn_rtn[15], n^.desc.rlen, nil);
            fp_temp(il_$node_ptr_t(n), t1);
          end;
        end
        else if (n^.desc.w6 = 11) and (n^.desc.rlen <= 7) and
            (4 in cargs_$options.cpu) and
            (cargs_$options.cpu * [5, 9, 10] = []) then begin
          sz := n^.desc.w8;
          cg_tree_$adjust_before_round(n^.opnd[1], sz, opr);
          if opr.f1 <> 13 then begin
            load_modifiable(n^.opnd[1], sz, opr);
            kill_register(opr.f2);
          end;
          emit(60, 6, opr, opr, 0);
          if n^.desc.rlen > 4 then begin
            setresult(opr.f2, il_$node_ptr_t(n), n^.desc.rlen);
            unlock(opr);
          end
          else begin
            kill_register(0);
            if cg_addr_locks[0] <> 0 then
              cg_addr_locks[0] := cg_addr_locks[0] - 1;
            address_reg(0, ops);
            cg_addr_locks[0] := cg_addr_locks[0] + 1;
            emit(0, sz, ops, opr, n^.desc.rlen);
            setresult(0, il_$node_ptr_t(n), n^.desc.rlen);
            unlock(opr);
            unlock(ops);
          end;
        end
        else if (tree_fn_rtn[n^.desc.w6] = 137) or
            (tree_fn_rtn[n^.desc.w6] = 132) then begin
          if 8 in cargs_$options.cpu then begin
            fpa_fop_proc(il_$node_ptr_t(n), tree_fn_rtn[n^.desc.w6],
                tree_fn_rtn[n^.desc.w6]);
            setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
            if n^.desc.rlen >= 8 then
              setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
          end
          else begin
            if temps then
              restore_alloc_temps;
            fop_proc(il_$node_ptr_t(n), tree_fn_rtn[n^.desc.w6],
                tree_fn_rtn[n^.desc.w6]);
          end;
        end
        else begin
          if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
              (n^.desc.rlen = 7) then
            for k := 1 to n^.count do
              cg_tree_$spill_fp_reg_contents_before_fpp(n^.opnd[k],
                  n^.desc.rlen);
          if 8 in cargs_$options.cpu then begin
            fpa_fop_proc(il_$node_ptr_t(n), tree_fn_rtn[n^.desc.w6], 104);
            if (n^.desc.w6 = 11) and (n^.desc.rlen <= 4) then
              setresult(0, il_$node_ptr_t(n), n^.desc.rlen)
            else
              setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
            if n^.desc.rlen >= 8 then
              setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
          end
          else begin
            if temps then
              restore_alloc_temps;
            fop_proc(il_$node_ptr_t(n), tree_fn_rtn[n^.desc.w6], 104);
            if n^.desc.w6 = 11 then
              purge_fp;
          end;
        end;
      end
      else begin
        if cg_fp_count <> 0 then
          purge_fp;
        case n^.desc.w6 of
          0, 1, 2, 3, 4, 5, 6, 7, 9, 10:
            if (9 in cargs_$options.cpu) and tree_math[n^.desc.w6].ok then
              cg_tree_$call_fast_math_lib(il_$node_ptr_t(n))
            else begin
              inreg := false;
              if ((il_$node_ptr_t(n)^.xw[3] & 16#4000) <> 0) and
                  (peek(n^.opnd[1], n^.desc.rlen) in [16..23]) then begin
                r := chk_assign(il_$node_ptr_t(n), n^.desc.rlen);
                inreg := (r = 31) or cg_addr_cache[r].live;
              end;
              if inreg then begin
                load_fp_result(il_$node_ptr_t(n), -1, ops);
                opr := ops;
              end
              else begin
                address(n^.opnd[1], n^.desc.rlen, ops);
                release(ops);
                get_register(il_$node_ptr_t(n), n^.desc.rlen, opr);
              end;
              if (n^.desc.w6 = 9) and (4 in cargs_$options.cpu) and
                  (ops.f1 = 13) and (ops.f2 <> opr.f2) and
                  not (5 in cargs_$options.cpu) then begin
                emit(0, n^.desc.rlen, opr, ops, 0);
                ops := opr;
              end;
              if (n^.desc.w6 = 4) and (4 in cargs_$options.cpu) and
                  not (5 in cargs_$options.cpu) then begin
                emit(0, n^.desc.rlen, opr, ops, 0);
                address(rlcontk(0.5), 6, opu);
                emit(47, n^.desc.rlen, opr, opu, 6);
                release(opu);
                address(templabel, 0, opu);
                emit(42, 5, opu, cg_null_ads, 12);
                emit(tree_fn_inst[n^.desc.w6], n^.desc.rlen, opr, opr,
                    n^.desc.rlen);
                address(templabel, 0, opt);
                emit(21, 5, opt, cg_null_ads, 0);
                emit(32, 5, opu, cg_null_ads, 0);
                address(rlcontk(1.0), 6, opu);
                emit(44, n^.desc.rlen, opr, opu, 6);
                release(opu);
                emit(56, n^.desc.rlen, opr, opr, n^.desc.rlen);
                emit(32, 5, opt, cg_null_ads, 0);
              end
              else if 8 in cargs_$options.cpu then
                emit_fmath_top(tree_fn_inst[n^.desc.w6], n^.desc.rlen, opr,
                    ops)
              else
                emit(tree_fn_inst[n^.desc.w6], n^.desc.rlen, opr, ops,
                    n^.desc.rlen);
              unlock(opr);
            end;
          12, 13: begin
            if n^.desc.w6 = 12 then
              inst := 12
            else
              inst := 15;
            n^.desc.w6 := 0;
            load_fp_result(il_$node_ptr_t(n), 2, opr);
            n^.desc.w6 := w6;
            address(n^.opnd[2], n^.desc.rlen, ops);
            if 8 in cargs_$options.cpu then
              emit_compare(n^.desc.rlen, opr, ops, inst)
            else
              emit(47, n^.desc.rlen, opr, ops, 0);
            address(templabel, 0, opt);
            if 8 in cargs_$options.cpu then begin
              emit(20, 5, opt, cg_null_ads, 4);
              emit_assign(n^.desc.rlen, opr, ops);
            end
            else begin
              emit(42, 5, opt, cg_null_ads, inst);
              emit(0, n^.desc.rlen, opr, ops, 0);
            end;
            emit(32, 5, opt, cg_null_ads, 0);
            unlock(opt);
            release(ops);
            unlock(opr);
          end;
          otherwise ;
        end;
      end;
    end;

    { A power (42): with FPA1 by its routine (fpa1_expon_inquire's: the
      exponent in its register), with -CPU MATHLIB the fast math
      library's, else on the floating stack (94, 96, 98, 100 by the
      classes). }
    42:
      if 8 in cargs_$options.cpu then begin
        push_fpa_opr(n^.opnd[1], 1, n^.desc.rlen, 16);
        cg_tree_$fpa1_expon_inquire(il_$node_ptr_t(n), ea, eb, ec);
        push_fpa_opr(n^.opnd[2], 1, n^.desc.w8, ea);
        emit_jsr(eb, n^.desc.w8, 0);
        fpa_temp(il_$node_ptr_t(n), t1);
        setresult(16, il_$node_ptr_t(n), n^.desc.rlen);
        if n^.desc.rlen >= 8 then
          setresult(17, il_$node_ptr_t(n), n^.desc.rlen);
      end
      else if 9 in cargs_$options.cpu then
        cg_tree_$call_fast_math_lib(il_$node_ptr_t(n))
      else begin
        if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
          cg_tree_$spill_fp_reg_contents_before_fpp(n^.opnd[2],
              n^.desc.rlen);
        if not check_use(cg_fp_result, n^.opnd[1]) then
          stack_fp(1, n^.desc.rlen, n^.opnd[1]);
        if n^.desc.rlen = 6 then begin
          if n^.desc.w8 <= 4 then
            eb := 94
          else
            eb := 96;
        end
        else if n^.desc.w8 <= 4 then
          eb := 98
        else
          eb := 100;
        stack_fp(eb, n^.desc.w8, n^.opnd[2]);
        fp_temp(il_$node_ptr_t(n), t1);
      end;

    { The library's routines 14 and 15 (43, a word's and a long's). }
    43:
      if n^.desc.rlen = 2 then
        gen_call(il_$node_ptr_t(n), std_lib_rtns[14])
      else
        gen_call(il_$node_ptr_t(n), std_lib_rtns[15]);

    { Exclusive or (44, emit 5): a constant or the operand a register
      holds on the right (the operands swapped by n's opnd[1]). }
    44: begin
      if cg_fp_count <> 0 then
        purge_fp;
      if register_tickle(n^.opnd[1], false) then begin
        load_operand(n^.opnd[1], n^.desc.rlen, opr);
        unlock(opr);
      end;
      if register_tickle(n^.opnd[2], false) then begin
        load_operand(n^.opnd[2], n^.desc.rlen, opr);
        unlock(opr);
      end;
      if n^.opnd[2]^.kind in [77..87, 101, 200] then begin
        address(n^.opnd[2], n^.desc.rlen, ops);
        load_result(il_$node_ptr_t(n), -1, opr);
      end
      else if n^.opnd[1]^.kind in [77..87, 101, 200] then begin
        address(n^.opnd[1], n^.desc.rlen, ops);
        n^.opnd[1] := n^.opnd[2];
        load_result(il_$node_ptr_t(n), -1, opr);
      end
      else begin
        inquire(n^.opnd[2], n^.desc.rlen, ops);
        if ops.f1 <> 0 then
          load_result(il_$node_ptr_t(n), -1, opr)
        else begin
          inquire(n^.opnd[1], n^.desc.rlen, ops);
          if ops.f1 <> 0 then begin
            n^.opnd[1] := n^.opnd[2];
            load_result(il_$node_ptr_t(n), -1, opr);
          end
          else begin
            load_result(il_$node_ptr_t(n), 2, opr);
            load_operand(n^.opnd[2], n^.desc.rlen, ops);
          end;
        end;
      end;
      emit(5, n^.desc.rlen, opr, ops, 0);
      unlock(opr);
      release(ops);
    end;

    { Minimum, maximum (45, 46): a compare (emit 18) and a conditional
      move over a branch (12 or 15; 2 or 3 unsigned under the routine's
      convention 1 or 6, the routine block's +377 bits 6..4). }
    45, 46: begin
      if cg_fp_count <> 0 then
        purge_fp;
      if n^.op = 45 then
        inst := 12
      else
        inst := 15;
      m := rshft(ord(il_180^.xc[377]) & 16#70, 4);
      if ((m = 1) or (m = 6)) and ((n^.desc.flags & 16#4000) = 0) then
        if inst = 12 then
          inst := 2
        else
          inst := 3;
      load_result(il_$node_ptr_t(n), 2, opr);
      address(n^.opnd[2], n^.desc.rlen, ops);
      emit(18, n^.desc.rlen, opr, ops, 0);
      address(templabel, 0, opt);
      emit(20, 5, opt, cg_null_ads, inst);
      emit(0, n^.desc.rlen, opr, ops, 0);
      emit(32, 5, opt, cg_null_ads, 0);
      unlock(opt);
      release(ops);
      unlock(opr);
    end;

    { The status register (47, through opv, mode 10): with one operand
      a constant and'ed (negative) or or'ed into it; with two its old
      value the result and the operand stored. }
    47:
      if n^.count = 1 then begin
        if n^.opnd[1]^.xl[2] < 0 then
          inst := 3
        else
          inst := 4;
        address(n^.opnd[1], 0, ops);
        emit(inst, 2, opv, ops, 0);
      end
      else begin
        get_register(il_$node_ptr_t(n), 2, opr);
        address(n^.opnd[1], 2, ops);
        emit(0, 2, opr, opv, 0);
        emit(0, 2, opv, ops, 0);
        setresult(opr.f2, il_$node_ptr_t(n), 2);
        unlock(opr);
        release(ops);
      end;

    { 48: a word's `chk'-like operation (emit 38) of the operands; for a
      long without the 68020 a compare and a branch around it with -1
      as a word. }
    48: begin
      if cg_fp_count <> 0 then
        purge_fp;
      load_result(il_$node_ptr_t(n), -1, opr);
      address(n^.opnd[2], n^.desc.rlen, ops);
      if (n^.desc.rlen = 2) or
          ((n^.desc.rlen = 4) and (3 in cargs_$options.cpu)) then
        emit(38, n^.desc.rlen, opr, ops, 0)
      else begin
        emit(18, n^.desc.rlen, opr, ops, 0);
        release(ops);
        address(templabel, 0, opt);
        emit(20, 5, opt, cg_null_ads, 3);
        anyconst(-1, 2, ops);
        emit(38, 2, opr, ops, 0);
        emit(32, 5, opt, cg_null_ads, 0);
        kill_register(ops.f2);
      end;
      unlock(opr);
      release(ops);
    end;

    49:
      shift_proc(n, 1);
    50:
      shift_proc(n, 0);

    { The stack pointer less opnd[1] (65, an alloca). }
    65: begin
      address_reg(15, opr);
      address(n^.opnd[1], n^.desc.w6, ops);
      emit(tree_op_inst[2], n^.desc.w6, opr, ops, 0);
      setresult(opr.f2, il_$node_ptr_t(n), 5);
      release(ops);
      unlock(opr);
    end;

    { The library's routine 147 (66). }
    66:
      gen_call(nil, std_lib_rtns[147]);

    { The string builtins (68 strcmp, 69 strlen, 70 strncmp). }
    68:
      cbuiltin_strcmp(il_$node_ptr_t(n));
    69:
      cbuiltin_strlen(il_$node_ptr_t(n));
    70:
      cbuiltin_strncmp(il_$node_ptr_t(n));
    72:
      set_bit_in_set_proc(n);
    73:
      set_range_in_set_proc(n);
    otherwise
      cgerr(0, cg_line, n);
  end;
  if not at_backend_506 then begin
    n^.desc.w6 := w6;
    n^.desc.w8 := w8;
    if n^.count > 0 then
      n^.opnd[1] := t1;
    if n^.count > 1 then
      n^.opnd[2] := t2;
  end
  else if temps then
    restore_alloc_temps;
  if n^.kind = 137 then begin
    n^.kind := 138;
    if at_backend_506 then
      if n^.w18 < 0 then
        if ((cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
            ((rlen = 7) or (rlen = 6)) and
            (peek(il_$node_ptr_t(n), rlen) in [16..23])) or
            (rlen <= 6) then
          get_temp(il_$node_ptr_t(n), true);
  end;
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
  generate(cg_tree_ptr_t(n));
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
