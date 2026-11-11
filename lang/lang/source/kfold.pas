{ kfold - constant folding of an IL tree node: the operators of integer,
  set and real constants are evaluated (integers by their size and
  signedness, dfetch; reals under a clean-up handler that turns a
  floating fault into diagnostic 19), the address arithmetic of address
  constants and indexed nodes is folded, and algebraic identities with
  one constant operand (x + 0, x * 1, x * 0, x & 0, x | -1, shifts by 0,
  a mask over a left shift ...) are simplified; the result replaces
  the node, the use counts adjusted.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0ACD94  0x0AE774  report_failure_once
    0x0ACDC2  0x0AE7A2  dbl_to_real
    0x0ACE8C  0x0AE86C  dfetch
    0x0ACEE0  0x0AE8C0  assert_is_tree
    0x0ACEF8  0x0AE8D8  assert_is_shared_tree
    0x0ACF06  0x0AE8E6  assert_is_integer_constant
    0x0ACF48  0x0AE928  assert_is_integer_and
    0x0ACF70  0x0AE950  assert_is_left_shift
    0x0ACFA4  0x0AE984  assert_is_shift
    0x0ACFEC  0x0AE9CC  assert_and_over_left_shift_produces_zero
    0x0AD0A0  0x0AEA80  assert_is_shift_with_negative_count
    0x0AD1A0  0x0AEB80  kfold_$general
    0x0AD0DA  0x0AEABA  node_number
    0x0AF444  0x0B0E24  kfold
    A5 0x2C338C (cc.m68k), 0x4433FC (cc.a88k): dfetch's masks (+0x0)
    and the descriptor of an address sum (+0x10).

  kfold, kfold_$general, dbl_to_real and dfetch load A5; the others are
  internal (the assertions are leaf routines without a frame,
  docs/rev889-patterns.md 16); node_number is nested in kfold_$general.
  Tree nodes are read through the unit's kf_tree_t (c_objtype's
  c_tree_t, which kfold does not open), the others through il.ins.pas's
  views.

  Real arithmetic is the FPP emulator's (`jsr fpp_$' with operation
  words; docs/rev889-patterns.md 19): 0x0074 load a double, 0x0080
  store one, 0x00C4/0x01D8 load a signed/unsigned longword, 0x00D0
  convert to a longword (D0), 0x0154 0x0068 round to one, 0x00D4 store
  a single, 0x0084 add, 0x008C subtract, 0x009C multiply, 0x00A4
  divide, 0x00AC divide reversed, 0x006C negate, 0x0070 absolute value,
  0x0090/0x0098 subtract an immediate / from an immediate, 0x00B4
  compare, 0x00B8 compare with an immediate, 0xFF34 test, 0x00E0
  square root, 0x00E8 exponential, 0x00F0 natural logarithm, 0x00F8
  sine, 0x0100 cosine, 0x0110 arc tangent (read off the operators that
  use them).  dpc has no real arithmetic (docs/dpc-gaps.md 6, 7, 19).

  Not known from the original: the FPP operations 0x0178 and 0x0180 of
  the builtins 13 and 12 (written as Fortran's MOD and SIGN, a guess);
  where the image's x * 0.0 goes (a `beq' into the smcontk tail, A0 as
  fpp_$ leaves it; taken as the constant operand).

  dpc gaps (docs/dpc-gaps.md): 7 and 19 (dbl_to_real, the real
  conversions), 8 (`in' on the operator and kind sets), 25
  (kfold_$general exceeds dpc's virtual registers: its integer
  operators, its real operators and the cases after them are left out
  of the check, the real ones being gap 7 throughout).

  kfold and kfold_$general are declared here: no insert of the units
  that call kfold (c_syntax's call_kfold, the optimizer's) is known to
  hold the heading (docs/questions.md 64).
}
module kfold;

%include 'lang/lang/source/globals.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang2/source/ftn/source/const_op.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { A value's descriptor (an IL tree node's +20). }
  kf_desc_t = record
    size: integer32;                    { +0 }
    rlen: integer;                      { +4: the register class }
    w6: integer;                        { +6: the source's class, or the
                                          builtin's function }
    w8: integer;                        { +8: the condition code of a
                                          comparison }
    flags: packed record                { +10 }
      b7: boolean;
      signed: boolean;                  { .6 }
      b5, b4, b3: boolean;
      b2: boolean;                      { .2: cleared by the bit test }
      b1, b0: boolean;
      b11: 0..255;                      { +11 }
    end;
    unused_12: integer32;               { +12 }
  end;

  { An IL tree node (137 an operator, 143): as c_objtype's c_tree_t. }
  kf_tree_ptr_t = ^kf_tree_t;
  kf_tree_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    h4: packed record                   { +4 }
      b4_7_1: 0..127;
      reported: boolean;                { .0 (bit 24 of the longword):
                                          report_failure_once reported }
      b5: 0..255;                       { +5 }
    end;
    bits: packed record                 { +6 }
      b15, b14, b13: boolean;
      b12: boolean;                     { .4: keep the node (no
                                          simplification to a constant) }
      b11, b10, b9, b8: boolean;
      b7_0: 0..255;
    end;
    unused_8: integer32;                { +8 }
    unused_12: integer32;               { +12 }
    uses: integer;                      { +16: the use count }
    w18: integer;                       { +18 }
    desc: kf_desc_t;                    { +20 }
    op: integer;                        { +36 }
    count: integer;                     { +38 }
    opnd: array [1..64] of il_$node_ptr_t;  { +40 }
  end;

  { The 12 bytes from +4 a new node copies from the one it replaces. }
  kf_hdr_t = array [1..3] of integer32;
  kf_hdr_ptr_t = ^kf_hdr_t;

  { il_120: the IL's node table (from 1). }
  kf_nodes_t = array [1..16383] of il_$node_ptr_t;
  kf_nodes_ptr_t = ^kf_nodes_t;

var
  masks: array [1..4] of integer32 := [255, 65535, 0, -1];  { +0x0:
                                          dfetch's, by length }
  sum_desc: kf_desc_t := [0, 5, 0, 0, [false, true, false, false, false,
                          false, false, false, 0], 0];  { +0x10: an
                                          address sum's (operator 13):
                                          class 5, signed }

{ report_failure_once - report diagnostic code at il_d0 for the node n,
  once (the node's bit 24 of +4 marks it).

  0x0ACD94, 0x2E bytes, link #-4: `btst #24' of the longword, `bset #0'
  of its first byte.

  Not known from the original:
  - the names. }

procedure report_failure_once(
    n: il_$node_ptr_t;
    code: integer); options(val_param); internal;
begin
  if not kf_tree_ptr_t(n)^.h4.reported then begin
    kf_tree_ptr_t(n)^.h4.reported := true;
    cgerr(code, il_d0, nil);
  end;
end;

{ dbl_to_real - the double constant n's value as a single, converted
  under a clean-up handler: a floating fault (subsystem 5 or 0) is
  diagnostic 19 at line with the fault's text, and 0.

  0x0ACDC2, 0xBA bytes, link #-76: the conversion `jsr fpp_$' 0x0074
  0x00D4 0xFF3E into -76, copied to the result at -72 (returned in D0,
  docs/dpc-gaps.md 19); error_$print_format(status, 2, '?', 'compiler',
  8, '%$').

  Not known from the original:
  - the names. }

function dbl_to_real(
    n: il_$node_ptr_t;
    line: integer): real; options(val_param);
var
  crec: pfm_$cleanup_rec;               { -64 }
  status: status_$t;                    { -68 }
  res: real;                            { -72 }
  r: real;                              { -76 }
begin
  status := pfm_$cleanup(crec);
  if status.all <> pfm_$cleanup_set then
    if (status.subsys = 5) or (status.subsys = 0) then begin
      pfm_$enable;
      cgerr(19, line, n);
      error_$print_format(status, 2, '?', 'compiler', 8, '%$');
      res := 0.0;
      dbl_to_real := res;
      return;
    end
    else
      pfm_$signal(status);
  r := n^.real_value;
  res := r;
  pfm_$rls_cleanup(crec, status);
  dbl_to_real := res;
end;

{ dfetch - v as a value of len bytes (masked, sign-extended when sgn);
  v itself for a length above 4.

  0x0ACE8C, 0x54 bytes, link #-8: the length compared unsigned (`bls');
  the mask masks[len] (`and.l (-4,A5,D3.w)'); the extension `lsl.l;
  asr.l' by 32 - 8 len.

  Not known from the original:
  - the names. }

function dfetch(
    v: integer32;
    len: integer;
    sgn: boolean): integer32; options(val_param);
var
  s: integer;
begin
  if (len < 0) or (len > 4) then
    dfetch := v
  else begin
    v := v & masks[len];
    if sgn then begin
      s := 32 - len * 8;
      v := arshft(lshft(v, s), s);
    end;
    dfetch := v;
  end;
end;

{ The assertions of kfold_$general's simplifications (leaf routines,
  the argument at (4,SP), the result in D0). }

{ assert_is_tree - n is a tree node (137).  0x0ACEE0, 0x18 bytes. }

function assert_is_tree(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_tree := n^.kind = 137
  else
    assert_is_tree := false;
end;

{ assert_is_shared_tree - n is used more than once.  0x0ACEF8, 0xE
  bytes: `sgt' of the use count (+16) against 1. }

function assert_is_shared_tree(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  assert_is_shared_tree := kf_tree_ptr_t(n)^.uses > 1;
end;

{ assert_is_integer_constant - n is an integer constant (80..86, 200).
  0x0ACF06, 0x28 bytes: `btst' on a 26-byte set (docs/dpc-gaps.md 8). }

function assert_is_integer_constant(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n <> nil then
    assert_is_integer_constant := n^.kind in [80..86, 200]
  else
    assert_is_integer_constant := false;
end;

{ assert_is_integer_and - n is an and (9).  0x0ACF48, 0x28 bytes, link
  #-4. }

function assert_is_integer_and(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_tree(n) then
    assert_is_integer_and := kf_tree_ptr_t(n)^.op = 9
  else
    assert_is_integer_and := false;
end;

{ assert_is_left_shift - n is a left shift (49, 27).  0x0ACF70, 0x34
  bytes, link #-8. }

function assert_is_left_shift(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_tree(n) then
    assert_is_left_shift := (kf_tree_ptr_t(n)^.op = 49) or
                            (kf_tree_ptr_t(n)^.op = 27)
  else
    assert_is_left_shift := false;
end;

{ assert_is_shift - n is a shift (50, 49, 28, 27).  0x0ACFA4, 0x48
  bytes, link #-8. }

function assert_is_shift(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_tree(n) then
    assert_is_shift := (kf_tree_ptr_t(n)^.op = 50) or
                       (kf_tree_ptr_t(n)^.op = 49) or
                       (kf_tree_ptr_t(n)^.op = 28) or
                       (kf_tree_ptr_t(n)^.op = 27)
  else
    assert_is_shift := false;
end;

{ assert_and_over_left_shift_produces_zero - n is `(x << s) & m' with
  m 255 and s at least 8, or m 65535 and s at least 16, neither node
  shared: zero.

  0x0ACFEC, 0xB4 bytes, link #-24: the shift count compared unsigned
  (`bcs').

  Not known from the original:
  - the names. }

function assert_and_over_left_shift_produces_zero(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  m, s: integer32;
  l: il_$node_ptr_t;
begin
  r := false;
  if assert_is_integer_and(n) then
    if assert_is_integer_constant(kf_tree_ptr_t(n)^.opnd[2]) then
      if assert_is_left_shift(kf_tree_ptr_t(n)^.opnd[1]) then
        if assert_is_integer_constant(
             kf_tree_ptr_t(kf_tree_ptr_t(n)^.opnd[1])^.opnd[2]) then begin
          l := kf_tree_ptr_t(n)^.opnd[1];
          m := kf_tree_ptr_t(n)^.opnd[2]^.int_value;
          s := kf_tree_ptr_t(l)^.opnd[2]^.int_value;
          if not assert_is_shared_tree(n) and
             not assert_is_shared_tree(l) then
            if (m = 255) or (m = 65535) then
              if not ((m = 255) and (s >= 0) and (s < 8)) then
                if not ((m = 65535) and (s >= 0) and (s < 16)) then
                  r := true;
        end;
  assert_and_over_left_shift_produces_zero := r;
end;

{ assert_is_shift_with_negative_count - n shifts by a negative
  constant.  0x0AD0A0, 0x3A bytes, link #-8. }

function assert_is_shift_with_negative_count(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_shift(n) and
     assert_is_integer_constant(kf_tree_ptr_t(n)^.opnd[2]) then
    assert_is_shift_with_negative_count :=
        kf_tree_ptr_t(n)^.opnd[2]^.int_value < 0
  else
    assert_is_shift_with_negative_count := false;
end;

{ kfold_$general - fold the tree n (stmt the statement it belongs to,
  addr_ok whether address arithmetic may be folded into the address
  constants and indexed nodes); only under -XANSI or with optimization
  2 on.  A string or indexed character (164) of constant index becomes
  a string constant; one-character strings become integer constants
  first; a commutative operator's constant first operand is moved
  second; then the operators of FOLD_OPS (integers), the real ones
  (34..38, 40..42) and a few others (25 a bit range, 11 a bit test, 26
  an address, 13 and 18) are folded or simplified (the cases below).
  The result is normalized to the node's class (dfetch; a one-byte
  result of a non-C routine a one-character string), the use counts
  moved to it and, for a constant, its node number (+10) set from the
  statement (node_number); it replaces n.

  0x0AD1A0, 0x223C bytes, link #-684: the operator sets are `btst' on
  6- and 8-byte constants (0..47, 0..63), the kinds' on 26-byte ones
  (docs/dpc-gaps.md 8); the integer operators a jump table on op - 1
  (`cmpi.w #57'), the comparisons on the condition code - 2 (`cmpi.w
  #14'), the real ones on op - 34 (`cmpi.w #9'); the real conversions
  and operations `jsr fpp_$' (see the unit's header); a division by
  zero is reported once (54), a domain error 55, overflow 56, underflow
  57, a negative base to a non-integer power 58, a negative shift 60
  (report_failure_once); unsigned multiplication, division and
  remainder M$MIU$LLL, M$DIU$LLL, M$OIU$LLL when the node is unsigned.
  The result kept in A2; the exit 0x0AF3D2.

  Not known from the original:
  - the names; what operators 25, 11, 13, 18 and the builtins 12, 13
    are in the IL's own terms. }

procedure kfold(
    var stmt: il_$node_ptr_t;
    var n: il_$node_ptr_t); forward;

procedure kfold_$general(
    stmt: il_$node_ptr_t;
    var n: il_$node_ptr_t;
    addr_ok: boolean); options(val_param);
label
  50, 60, 70, 80, 90;
var
  d: kf_desc_t;                         { -16 }
  ops: array [1..2] of il_$node_ptr_t;  { -272 }
  words: array [1..64] of integer;      { -400 }
  crec: pfm_$cleanup_rec;               { -464 }
  dd: double;                           { -472 }
  c: double;                            { -480 }
  b: double;                            { -488 }
  a: double;                            { -496 }
  status: status_$t;                    { -512 }
  v1: integer32;                        { -528 }
  s1: il_$node_ptr_t;                   { -544 }
  kind: integer;                        { -558 }
  k1, k2: integer;                      { -562, -560 }
  sgn: boolean;                         { -572 }
  r: double;                            { -672 }
  r2: double;                           { -680 }
  e: integer32;                         { -684 }
  t: kf_tree_ptr_t;
  res: il_$node_ptr_t;
  x, y, o, s2, l: il_$node_ptr_t;
  v2, m, lo, hi: integer32;
  uv1, uv2: linteger;
  i, j, cnt: integer;
  setres: boolean;

{ node_number - the IL node number of stmt within its block's range
  (opt_main's table, entry by the statement's +43 word, or for a
  constant its +12 node's), 0 when it is not there.

  0x0AD0DA, 0xAC bytes, link #-16: the word from `and.l #0xFFFF00;
  lsr.l #8' of the longword at +42; the range's words compared
  unsigned; the table il_120 (from 1).

  Not known from the original:
  - the names. }

function node_number(
    s: il_$node_ptr_t): integer; options(val_param);
label
  1;
var
  k: integer;
  w: integer32;
  i, j: integer;
  rg: g_opt_range_ptr_t;
begin
  k := 0;
  w := 0;
  if s^.kind in [80..86, 200] then begin
    if s^.xp[3] <> nil then
      w := rshft(s^.xp[3]^.xl2[10] & 16#FFFF00, 8);
  end
  else
    w := rshft(s^.xl2[10] & 16#FFFF00, 8);
  if w <> 0 then begin
    rg := opt_4009c[w]^.range;
    if rg^.last >= rg^.first then begin
      j := rg^.first;
      for i := 0 to rg^.last - rg^.first do begin
        if kf_nodes_ptr_t(il_120)^[j] = s then begin
          k := j;
          goto 1;
        end;
        j := j + 1;
      end;
    end;
  end;
1:
  node_number := k;
end;

begin { kfold_$general }
  if not cargs_$options.xansi and not (2 in cargs_$options.opt_on) then
    goto 90;
  x := n;
  if x^.kind = 145 then
    goto 90;

  { A string's character of constant index. }
  if x^.kind = 164 then begin
    y := x^.xp[6];
    if not (y^.kind in [77..87, 101, 200]) then
      goto 90;
    o := x^.xp[5];
    if o^.kind = 92 then
      n := strtk(o^.xc[18], y^.xw[5])
    else if (o^.kind = 87) or (o^.kind = 81) then
      n := strtk(o^.xc[11], y^.xw[5])
    else if o^.kind = 200 then
      n := strtk(o^.xc[8], y^.xw[5]);
    goto 90;
  end;
  if (x^.kind <> 137) and (x^.kind <> 143) then
    goto 90;
  t := kf_tree_ptr_t(x);

  { One-character strings to integers; a constant first operand of a
    commutative operator second. }
  if not (t^.op in [15, 16, 17, 26, 47]) then
    for i := 1 to t^.count do begin
      o := t^.opnd[i];
      if (o^.kind = 92) and (o^.str_len = 1) then
        t^.opnd[i] := smcontk(81, ord(o^.str_chars[1]));
    end;
  if t^.op in [1, 3, 9, 10, 19, 20, 34, 36, 44, 45, 46] then
    if t^.opnd[1]^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then begin
      s1 := t^.opnd[1];
      t^.opnd[1] := t^.opnd[2];
      t^.opnd[2] := s1;
      if t^.op = 3 then begin
        i := t^.desc.w6;
        t^.desc.w6 := t^.desc.w8;
        t^.desc.w8 := i;
      end;
    end;

  if t^.op in [1..4, 6..10, 12, 19..21, 27..29, 39, 44..46, 49..53, 57] then begin
    { The real part of a double complex constant. }
    if (t^.op = 39) and (t^.desc.rlen = 7) and (t^.desc.w6 = 12) and
       (t^.count = 1) and (t^.opnd[1]^.kind = 198) then begin
      dd := t^.opnd[1]^.dcx_re;
      res := dpcontk(dd);
      goto 80;
    end;

    { Address arithmetic: an address plus or minus a constant. }
    if (t^.op = 2) or (t^.op = 1) then
      if t^.opnd[2]^.kind in [77..87, 101, 200] then begin
        x := t^.opnd[1];
        y := t^.opnd[2];
        if addr_ok and (x^.kind = 137) and (kf_tree_ptr_t(x)^.op = 26) and
           (y^.kind in [80..86, 200]) and
           (y^.int_value <= target_properties.p_5c) and
           (y^.int_value >= target_properties.p_60) then begin
          if (1 < kf_tree_ptr_t(x)^.uses) or (1 < t^.uses) then begin
            d := kf_tree_ptr_t(x)^.desc;
            x := buildtreenode(26, addr(d), addr(kf_tree_ptr_t(x)^.opnd[1]), 1);
            kf_tree_ptr_t(x)^.uses := 0;
            kf_tree_ptr_t(x)^.w18 := t^.w18;
            kf_hdr_ptr_t(addr(kf_tree_ptr_t(x)^.h4))^ := kf_hdr_ptr_t(addr(t^.h4))^;
          end;
          v1 := y^.int_value;
          if t^.op = 2 then
            v1 := -v1;
          o := kf_tree_ptr_t(x)^.opnd[1];
          if (o^.kind = 147) and (kf_tree_ptr_t(o)^.uses <= 1) then begin
            o^.xl[8] := o^.xl[8] + v1;
            res := x;
            goto 80;
          end;
          kf_tree_ptr_t(x)^.opnd[1] := add_disp_node(o, o, v1, false);
          res := x;
          if t^.opnd[1] = x then
            adjust_uc(kf_tree_ptr_t(x)^.opnd[1], 1);
          goto 80;
        end;
        if x^.kind = 163 then begin
          v1 := y^.int_value;
          if t^.op = 2 then
            v1 := -v1;
          v1 := v1 + x^.xl[3];
          if x^.xc[20] = chr(0) then begin
            res := make_xdynm_ptr(il_180, v1);
            goto 80;
          end;
          o := find_ac_dsect(x);
          if o <> nil then begin
            res := make_new_addr_con(ord(x^.xc[20]), x^.xp[2], v1, o, false);
            goto 80;
          end;
        end;
        if (x^.kind = 195) and (y^.kind in [80..86, 200]) then begin
          v1 := y^.int_value;
          if t^.op = 2 then
            v1 := -v1;
          v1 := v1 + x^.xl[4];
          res := make_abs_addr_con(x^.xw[10], x^.xp[3], v1);
          goto 80;
        end;
        if y^.int_value < 0 then begin
          if t^.op = 1 then
            t^.op := 2
          else
            t^.op := 1;
          t^.opnd[2] := smcontk(81, -y^.int_value);
        end;
      end;

    { (a << k) + (b << k) to (a + b) << k. }
    if t^.op = 1 then begin
      x := t^.opnd[1];
      y := t^.opnd[2];
      if (x^.kind = 137) and (t^.desc.rlen >= 0) and (t^.desc.rlen <= 4) and
         (kf_tree_ptr_t(x)^.op = 27) and (y^.kind = 137) and
         (kf_tree_ptr_t(y)^.op = 27) and
         (kf_tree_ptr_t(x)^.opnd[2] = kf_tree_ptr_t(y)^.opnd[2]) and
         (kf_tree_ptr_t(x)^.opnd[1] <> kf_tree_ptr_t(y)^.opnd[1]) then begin
        d := t^.desc;
        ops[1] := kf_tree_ptr_t(x)^.opnd[1];
        ops[2] := kf_tree_ptr_t(y)^.opnd[1];
        o := buildtreenode(1, addr(d), addr(ops), 2);
        kf_tree_ptr_t(o)^.uses := 0;
        kf_tree_ptr_t(o)^.w18 := 0;
        kf_hdr_ptr_t(addr(kf_tree_ptr_t(o)^.h4))^ :=
            kf_hdr_ptr_t(addr(kf_tree_ptr_t(t^.opnd[1])^.h4))^;
        d := kf_tree_ptr_t(t^.opnd[1])^.desc;
        ops[1] := o;
        ops[2] := kf_tree_ptr_t(t^.opnd[1])^.opnd[2];
        res := buildtreenode(27, addr(d), addr(ops), 2);
        kf_tree_ptr_t(res)^.uses := 0;
        kf_tree_ptr_t(res)^.w18 := t^.w18;
        kf_hdr_ptr_t(addr(kf_tree_ptr_t(res)^.h4))^ := kf_hdr_ptr_t(addr(t^.h4))^;
        adjust_uc(t^.opnd[1], -1);
        adjust_uc(t^.opnd[2], -1);
        goto 80;
      end;
    end;

    if assert_and_over_left_shift_produces_zero(il_$node_ptr_t(t)) then begin
      res := smcontk(81, 0);
      goto 80;
    end;
    if assert_is_shift_with_negative_count(n) then begin
      report_failure_once(n, 60);
      goto 90;
    end;

    { A conversion to an integer of a constant. }
    if (t^.op = 39) and (t^.desc.rlen >= 0) and (t^.desc.rlen <= 4) then begin
      x := t^.opnd[1];
      if x^.kind in [77..87, 101, 200] then begin
        res := smcontk(81, dfetch(x^.int_value, t^.desc.rlen,
                                  t^.desc.flags.signed));
        goto 80;
      end;
      if (x^.kind <> 89) and (x^.kind <> 88) then
        goto 90;
      status := pfm_$cleanup(crec);
      if status.all <> pfm_$cleanup_set then
        if (status.subsys = 5) or (status.subsys = 0) then begin
          pfm_$enable;
          cgerr(49, il_d0, t^.opnd[1]);
          v1 := 0;
          res := smcontk(81, v1);
          goto 80;
        end
        else
          pfm_$signal(status);
      x := t^.opnd[1];
      if t^.desc.flags.signed then
        v1 := trunc(x^.real_value)
      else if x^.real_value <= 2147483647.0 then
        v1 := trunc(x^.real_value)
      else
        v1 := trunc(x^.real_value - 2147483647.0 - 1.0) - 16#80000000;
      pfm_$rls_cleanup(crec, status);
      res := smcontk(81, dfetch(v1, t^.desc.rlen, t^.desc.flags.signed));
      goto 80;
    end;

    { Between the real classes. }
    if (t^.op = 39) and ((t^.desc.rlen = 7) or (t^.desc.rlen = 6)) and
       ((t^.desc.w6 = 7) or (t^.desc.w6 = 6)) and
       ((t^.opnd[1]^.kind = 89) or (t^.opnd[1]^.kind = 88)) then begin
      if t^.desc.rlen = t^.desc.w6 then begin
        res := t^.opnd[1];
        goto 80;
      end;
      if t^.desc.rlen = 6 then
        res := rlcontk(t^.opnd[1]^.real_value)
      else
        res := dpcontk(t^.opnd[1]^.real_value);
      goto 80;
    end;

    { The integer and set constants' operators. }
    k2 := 81;
    k1 := 81;
    for i := 1 to t^.count do begin
      o := t^.opnd[i];
      if o^.kind in [77..87, 101, 200] then
        if i = 1 then begin
          v1 := o^.int_value;
          k1 := o^.kind;
        end
        else begin
          v2 := o^.int_value;
          k2 := o^.kind;
        end
      else if o^.kind = 156 then
        if i = 1 then
          s1 := o
        else
          s2 := o
      else
        goto 70;
    end;
    setres := false;
    sgn := t^.desc.flags.signed;
    case t^.op of
      1: v1 := v1 + v2;
      2: v1 := v1 - v2;
      9: v1 := v1 & v2;
      10: v1 := v1 ! v2;
      7: v1 := -v1;
      8: v1 := ~v1;
      3: begin
        v1 := dfetch(v1, t^.desc.w6, sgn);
        v2 := dfetch(v2, t^.desc.w8, sgn);
        if sgn then
          v1 := v1 * v2
        else begin
          uv1 := v1;
          uv2 := v2;
          v1 := uv1 * uv2;
        end;
      end;
      4, 6: begin
        v1 := dfetch(v1, t^.desc.w6, sgn);
        v2 := dfetch(v2, t^.desc.w8, sgn);
        if v2 = 0 then begin
          report_failure_once(n, 54);
          goto 90;
        end;
        if not sgn then begin
          uv1 := v1;
          uv2 := v2;
          if t^.op = 4 then
            v1 := uv1 div uv2
          else
            v1 := uv1 mod uv2;
        end
        else if t^.op = 4 then
          v1 := v1 div v2
        else begin
          v1 := v1 mod v2;
          if cargs_$options.b27c_1 and (v1 < 0) then
            v1 := v1 + v2;
        end;
      end;
      44: v1 := xor(v1, v2);
      29:
        if v1 < 0 then
          v1 := -v1;
      46:
        if v2 <= v1 then
          v1 := v1
        else
          v1 := v2;
      45:
        if v2 >= v1 then
          v1 := v1
        else
          v1 := v2;
      27, 49: v1 := lshft(dfetch(v1, t^.desc.rlen, setres), v2);
      28: v1 := rshft(dfetch(v1, t^.desc.rlen, setres), v2);
      50: v1 := arshft(dfetch(v1, t^.desc.rlen, true), v2);
      53:
        if (v1 = 0) or (v2 = 0) then
          v1 := 0
        else
          v1 := 1;
      52:
        if (v1 = 0) and (v2 = 0) then
          v1 := 0
        else
          v1 := 1;
      57:
        if v1 <> 0 then
          v1 := 0
        else
          v1 := 1;
      51:
        if (t^.opnd[1]^.kind in [77..87, 101, 200]) and
           (t^.opnd[2]^.kind in [77..87, 101, 200]) and
           (t^.opnd[3]^.kind in [77..87, 101, 200]) then
          if t^.opnd[1]^.int_value <> 0 then
            v1 := t^.opnd[2]^.int_value
          else
            v1 := t^.opnd[3]^.int_value;
      39: begin
        if (t^.desc.w6 < 0) or (t^.desc.w6 > 4) then
          goto 90;
        v1 := dfetch(v1, t^.desc.w6, t^.desc.flags.signed);
        if sgn then r := v1 else if v1 < 0 then r := v1 + 4294967296.0 else r := v1;
        a := r;
        if t^.desc.rlen = 7 then begin
          res := dpcontk(a);
          goto 80;
        end;
        if t^.desc.rlen <> 6 then
          goto 70;
        res := rlcontk(a);
        goto 80;
      end;
      12: begin
        sgn := (t^.desc.w8 >= 0) and (t^.desc.w8 <= 31) and
               (t^.desc.w8 in [6, 7, 12..15]);
        v1 := dfetch(v1, t^.desc.w6, sgn);
        v2 := dfetch(v2, t^.desc.w6, sgn);
        uv1 := v1;
        uv2 := v2;
        case t^.desc.w8 of
          7: if v1 = v2 then v1 := 255 else v1 := 0;
          6: if v1 <> v2 then v1 := 255 else v1 := 0;
          13: if v1 < v2 then v1 := 255 else v1 := 0;
          14: if v1 > v2 then v1 := 255 else v1 := 0;
          15: if v1 <= v2 then v1 := 255 else v1 := 0;
          12: if v1 >= v2 then v1 := 255 else v1 := 0;
          2: if uv1 > uv2 then v1 := 255 else v1 := 0;
          3: if uv1 <= uv2 then v1 := 255 else v1 := 0;
          4: if uv1 >= uv2 then v1 := 255 else v1 := 0;
          5: if uv1 < uv2 then v1 := 255 else v1 := 0;
          otherwise ;
        end;
      end;
      19: begin
        setres := true;
        for i := 1 to s1^.set_len div 2 do
          words[i] := s1^.set_words[i] & s2^.set_words[i];
      end;
      20: begin
        setres := true;
        for i := 1 to s1^.set_len div 2 do
          words[i] := s1^.set_words[i] ! s2^.set_words[i];
      end;
      21: begin
        setres := true;
        for i := 1 to s1^.set_len div 2 do
          words[i] := ~s2^.set_words[i] & s1^.set_words[i];
      end;
      otherwise
        goto 90;
    end;
    if setres then begin
      res := setcontk(words, 0, s1^.set_len);
      goto 80;
    end;
    if k2 > k1 then
      k1 := k2;
    if (v1 < -32768) or (v1 > 32767) then
      k1 := 82;
    res := smcontk(k1, v1);
    goto 80;

    { Not all constants: identities with a constant operand. }
70:
    if (t^.op = 21) and (t^.opnd[2]^.kind = 156) then begin
      t^.op := 19;
      for i := 1 to t^.opnd[2]^.set_len div 2 do
        words[i] := ~t^.opnd[2]^.set_words[i];
      t^.opnd[2] := setcontk(words, 0, t^.opnd[2]^.set_len);
      res := il_$node_ptr_t(t);
      goto 80;
    end;
    if t^.op = 12 then begin
      i := t^.desc.w8;
      if (i = 2) or (i = 3) or (i = 5) or (i = 4) then
        if (t^.opnd[2]^.kind in [77..87, 101, 200]) and
           (t^.opnd[2]^.int_value = 0) then begin
          if i = 3 then
            t^.desc.w8 := 7
          else if i = 2 then
            t^.desc.w8 := 6;
        end
        else if (t^.opnd[1]^.kind in [77..87, 101, 200]) and
                (t^.opnd[1]^.int_value = 0) then begin
          if i = 4 then
            t^.desc.w8 := 7
          else if i = 5 then
            t^.desc.w8 := 6;
        end;
    end;
    l := t^.opnd[t^.count];
    if not (l^.kind in [77..87, 101, 200]) then
      goto 90;
    v1 := l^.int_value;
    case t^.op of
      3: begin
        v1 := dfetch(v1, t^.desc.w8, t^.desc.flags.signed);
        if v1 = 1 then begin
          if t^.desc.rlen = t^.desc.w6 then
            res := t^.opnd[1]
          else begin
            t^.op := 18;
            t^.desc.w8 := 0;
            t^.desc.size := t^.desc.rlen;
            res := il_$node_ptr_t(t);
          end;
          goto 80;
        end;
        if (v1 <> 0) or t^.bits.b12 then
          goto 90;
        res := smcontk(81, 0);
        goto 80;
      end;
      4: begin
        v1 := dfetch(v1, t^.desc.w8, t^.desc.flags.signed);
        if v1 = 1 then begin
          if t^.desc.rlen <> t^.desc.w6 then begin
            t^.op := 18;
            t^.desc.w8 := 0;
            t^.desc.size := t^.desc.rlen;
            res := il_$node_ptr_t(t);
          end
          else
            res := t^.opnd[1];
          goto 80;
        end;
        if t^.desc.w6 = 1 then begin
          if (v1 < 256) and (v1 >= -128) then
            goto 90;
        end
        else if t^.desc.w6 = 2 then begin
          if (v1 < 65536) and (v1 >= -32768) then
            goto 90;
        end
        else
          goto 90;
        res := smcontk(81, 0);
        goto 80;
      end;
      9: begin
        if v1 = 0 then
          if not t^.bits.b12 then begin
            res := l;
            goto 80;
          end;
        if (v1 <> -1) and
           (rshft(-1, (4 - t^.desc.rlen) * 8) <> v1) then
          goto 90;
        res := t^.opnd[1];
        goto 80;
      end;
      10: begin
        if rshft(-1, (4 - t^.desc.rlen) * 8) = v1 then
          if not t^.bits.b12 then begin
            res := l;
            goto 80;
          end;
        if v1 <> 0 then
          goto 90;
        res := t^.opnd[1];
        goto 80;
      end;
      28, 27, 50, 49, 2, 44, 1: begin
        if v1 <> 0 then
          goto 90;
        res := t^.opnd[1];
        goto 80;
      end;
      otherwise
        goto 90;
    end;
  end;

  { The real operators. }
  if t^.op in [34..38, 40..42] then begin
    if (t^.op = 41) and (t^.desc.rlen = 7) and (t^.desc.w6 = 15) and
       (t^.count = 1) and (t^.opnd[1]^.kind = 198) then begin
      dd := t^.opnd[1]^.dcx_im;
      res := dpcontk(dd);
      goto 80;
    end;
    for i := 1 to t^.count do begin
      o := t^.opnd[i];
      if (o^.kind <> 89) and (o^.kind <> 88) then
        if (t^.op <> 42) or not (o^.kind in [77..87, 101, 200]) or
           (i <> t^.count) then
          goto 60;
      if o^.kind in [77..87, 101, 200] then begin
        r := o^.int_value;
        b := r;
      end
      else if i = 1 then
        a := o^.real_value
      else
        b := o^.real_value;
    end;
    if t^.op = 41 then
      if not ((t^.desc.w6 >= 0) and (t^.desc.w6 <= 31) and
              (t^.desc.w6 in [0..7, 9..13])) then
        goto 60;
    status := pfm_$cleanup(crec);
    if status.all <> pfm_$cleanup_set then
      if (status.subsys = 5) or (status.subsys = 0) then begin
        pfm_$enable;
        error_$print_format(status, 2, '?', 'compiler', 8, '%$');
        cgerr(19, il_d0, t^.opnd[1]);
        goto 90;
      end
      else
        pfm_$signal(status);
    case t^.op of
      34: a := a + b;
      35: a := a - b;
      36: a := a * b;
      37: begin
        if b = 0.0 then begin
          report_failure_once(n, 54);
          goto 50;
        end;
        a := a / b;
      end;
      38: a := -a;
      40:
        case t^.desc.w8 of
          7: if a = b then v1 := 255 else v1 := 0;
          6: if a <> b then v1 := 255 else v1 := 0;
          5, 13: if a < b then v1 := 255 else v1 := 0;
          2, 14: if a > b then v1 := 255 else v1 := 0;
          3, 15: if a <= b then v1 := 255 else v1 := 0;
          4, 12: if a >= b then v1 := 255 else v1 := 0;
          otherwise ;
        end;
      41:
        case t^.desc.w6 of
          0: a := abs(a);
          11: begin
            if t^.desc.rlen >= 6 then
              goto 50;
            v1 := round(a);
          end;
          10: begin
            if t^.desc.rlen >= 6 then
              goto 50;
            v1 := trunc(a);
          end;
          16, 17: begin
            if (a < -1.0) or (a > 1.0) then begin
              report_failure_once(n, 55);
              goto 50;
            end;
            if t^.desc.w6 = 17 then
              a := arctan(a / sqrt(1.0 - a * a))
            else
              a := 1.5707963267948966 - arctan(a / sqrt(1.0 - a * a));
          end;
          7: a := arctan(a);
          2: a := cos(a);
          5, 4: begin
            if a <= 0.0 then begin
              report_failure_once(n, 55);
              goto 50;
            end;
            if t^.desc.w6 = 4 then
              r := ln(a)
            else
              ftn_$dlog10(r, a);
            a := r;
          end;
          12: a := abs(a) * b / abs(b);
          13: a := a - trunc(a / b) * b;
          1: a := sin(a);
          9: begin
            if a < 0.0 then begin
              report_failure_once(n, 55);
              goto 50;
            end;
            a := sqrt(a);
          end;
          3: begin
            r := cos(a);
            if r = 0.0 then begin
              report_failure_once(n, 55);
              goto 50;
            end;
            a := sin(a) / r;
          end;
          6: begin
            if (a > 88.72283905206835) and (t^.desc.rlen = 6) or
               (a > 709.782712893384) and (t^.desc.rlen = 7) then begin
              report_failure_once(n, 56);
              goto 50;
            end;
            if (a < -744.0) and (t^.desc.rlen = 7) or
               (a < -103.3) and (t^.desc.rlen = 6) then begin
              report_failure_once(n, 57);
              goto 50;
            end;
            a := exp(a);
          end;
          otherwise
            goto 50;
        end;
      42: begin
        if a = 0.0 then begin
          if t^.opnd[2]^.kind in [77..87, 101, 200] then begin
            e := trunc(b);
            r8i4_expon(r2, a, e);
          end
          else
            r8_expon(r2, a, b);
          a := r2;
        end
        else begin
          c := ln(abs(a)) * b;
          if a < 0.0 then
            if not (t^.opnd[2]^.kind in [77..87, 101, 200]) then
              if trunc(b) <> b then begin
                report_failure_once(n, 58);
                goto 50;
              end;
          if (c > 88.72283905206835) and (t^.desc.rlen = 6) or
             (c > 709.782712893384) and (t^.desc.rlen = 7) then begin
            report_failure_once(n, 56);
            goto 50;
          end;
          if (c < -103.3) and (t^.desc.rlen = 6) or
             (c < -744.0) and (t^.desc.rlen = 7) then begin
            report_failure_once(n, 57);
            goto 50;
          end;
          if t^.opnd[2]^.kind in [77..87, 101, 200] then begin
            e := trunc(b);
            r8i4_expon(r2, a, e);
          end
          else
            r8_expon(r2, a, b);
          a := r2;
        end;
      end;
      otherwise
        goto 50;
    end;
    if (t^.op = 40) or
       ((t^.op = 41) and ((t^.desc.w6 = 11) or (t^.desc.w6 = 10))) then
      res := smcontk(81, v1)
    else if t^.desc.rlen = 7 then
      res := dpcontk(a)
    else
      res := rlcontk(a);
    pfm_$rls_cleanup(crec, status);
    goto 80;
50:
    pfm_$rls_cleanup(crec, status);
    goto 90;

    { Not all constants: identities with a real constant. }
60:
    l := t^.opnd[t^.count];
    if (l^.kind <> 89) and (l^.kind <> 88) then
      goto 90;
    a := l^.real_value;
    case t^.op of
      34, 35:
        if a = 0.0 then begin
          res := t^.opnd[1];
          goto 80;
        end;
      36:
        if a = 0.0 then begin
          res := l;
          goto 80;
        end
        else if a = 1.0 then begin
          res := t^.opnd[1];
          goto 80;
        end;
      37:
        if a = 1.0 then begin
          res := t^.opnd[1];
          goto 80;
        end;
      otherwise ;
    end;
    goto 90;
  end;

  { A bit range [lo..hi] as a mask, or-ed in. }
  if t^.op = 25 then begin
    if not (t^.opnd[2]^.kind in [77..87, 101, 200]) then
      goto 90;
    v1 := t^.opnd[2]^.int_value;
    if t^.count = 2 then
      hi := v1
    else begin
      if not (t^.opnd[3]^.kind in [77..87, 101, 200]) then
        goto 90;
      hi := t^.opnd[3]^.int_value;
    end;
    t^.opnd[2] := smcontk(81, lshft(1, hi + 1) - lshft(1, v1));
    t^.op := 10;
    t^.count := 2;
    t^.desc.rlen := t^.desc.size;
    kfold(stmt, n);
    goto 90;
  end;

  { A bit test of a constant bit number. }
  if t^.op = 11 then begin
    if not (t^.opnd[1]^.kind in [77..87, 101, 200]) then
      goto 90;
    e := t^.opnd[1]^.int_value;
    if (3 in cargs_$options.cpu) and (t^.desc.size <> 4000) and
       (t^.desc.size * 8 > 32) then
      e := ~e;
    t^.desc.flags.b2 := false;
    if t^.desc.w8 < 0 then
      t^.desc.w8 := -t^.desc.w8;
    if (t^.desc.size * 8 - 1 < e) or (e < 0) then begin
      if t^.desc.w8 = 7 then
        res := smcontk(81, 255)
      else
        res := smcontk(81, 0);
      goto 80;
    end;
    o := t^.opnd[2];
    if o^.kind = 156 then begin
      v1 := o^.set_len div 2 - e div 16;
      m := lshft(1, e mod 16) & o^.set_words[v1];
    end
    else if o^.kind in [77..87, 101, 200] then
      m := lshft(1, e) & o^.int_value
    else
      goto 90;
    if (m <> 0) = (t^.desc.w8 = 6) then
      res := smcontk(81, 255)
    else
      res := smcontk(81, 0);
    goto 80;
  end;

  { An address of a dereference or of an indexed node. }
  if t^.op = 26 then begin
    x := t^.opnd[1];
    if x^.kind = 146 then begin
      res := x^.xp[6];
      goto 80;
    end;
    if (x^.kind <> 145) and (x^.kind <> 147) then
      goto 90;
    if not addr_ok then
      goto 90;
    v2 := 0;
    while x^.kind = 147 do begin
      v2 := v2 + x^.xl[8];
      x := x^.xp[6];
    end;
    if x^.kind <> 145 then
      goto 90;
    if x^.xl[8] <> 0 then
      bug_check('kfold: dindex.disp <> 0%.');
    y := x^.xp[8];
    if y^.kind in [77..87, 101, 200] then begin
      if (v2 = 0) and (y^.int_value = 0) then begin
        res := x^.xp[6];
        goto 80;
      end;
      ops[1] := x^.xp[6];
      ops[2] := smcontk(81, lshft(dfetch(y^.int_value, x^.xw[21], true),
                                  x^.xw[20]) + v2);
      res := buildtreenode(13, addr(sum_desc), addr(ops), 2);
      kf_tree_ptr_t(res)^.uses := 0;
    end
    else begin
      if (v2 <> 0) or (x^.xw[20] <> 0) or not target_properties.p_7f then
        goto 90;
      ops[1] := x^.xp[6];
      ops[2] := y;
      res := buildtreenode(13, addr(sum_desc), addr(ops), 2);
      kf_tree_ptr_t(res)^.uses := 0;
    end;
    kf_tree_ptr_t(res)^.w18 := t^.w18;
    kf_hdr_ptr_t(addr(kf_tree_ptr_t(res)^.h4))^ := kf_hdr_ptr_t(addr(t^.h4))^;
    goto 80;
  end;

  if t^.op = 13 then
    if t^.opnd[2]^.kind in [77..87, 101, 200] then begin
      if t^.opnd[2]^.int_value <> 0 then
        goto 90;
      res := t^.opnd[1];
      goto 80;
    end;

  { An integral conversion of a constant. }
  if t^.op <> 18 then
    goto 90;
  if not (t^.opnd[1]^.kind in [77..87, 101, 200]) then
    goto 90;
  v1 := t^.opnd[1]^.int_value;
  if t^.desc.flags.signed then begin
    if t^.desc.w6 = 1 then
      v1 := arshft(lshft(v1, 24), 24)
    else if t^.desc.w6 = 2 then
      v1 := arshft(lshft(v1, 16), 16)
    else if t^.desc.w6 <> 4 then
      goto 90;
  end
  else if t^.desc.w6 = 1 then
    v1 := v1 & 255
  else if t^.desc.w6 = 2 then
    v1 := v1 & 65535
  else if t^.desc.w6 <> 4 then
    goto 90;
  case t^.desc.rlen of
    1: if t^.desc.flags.signed then kind := 200 else kind := 86;
    2: if t^.desc.flags.signed then kind := 80 else kind := 83;
    4: if t^.desc.flags.signed then kind := 82 else kind := 85;
    otherwise
      if t^.desc.flags.signed then kind := 81 else kind := 84;
  end;
  res := smcontk(kind, v1);

  { The result, normalized to the node's class. }
80:
  if res^.kind in [77..87, 101, 200] then
    if ((res^.kind = 80) or (res^.kind = 81) or (res^.kind = 200) or
        (res^.kind = 82)) and (t^.desc.rlen = 1) and
       (rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 3) then
      res := strtk(res^.xc[11], 1)
    else begin
      kind := res^.kind;
      if kind = 81 then
        case t^.desc.rlen of
          1: if t^.desc.flags.signed then kind := 200 else kind := 86;
          2: if t^.desc.flags.signed then kind := 80 else kind := 83;
          4: if t^.desc.flags.signed then kind := 82 else kind := 85;
          otherwise
            if t^.desc.flags.signed then kind := 81 else kind := 84;
        end;
      res := smcontk(kind, dfetch(res^.int_value, t^.desc.rlen,
                                  t^.desc.flags.signed));
    end;
  if res <> n then begin
    adjust_uc(n, -1);
    adjust_uc(res, 1);
  end;
  if (res^.kind in [80..86, 200]) and (stmt <> nil) then begin
    x := kf_nodes_ptr_t(il_120)^[res^.xw[5]];
    if (x^.kind = 143) or (x^.kind = 137) or (x^.kind = 145) or
       (x^.kind = 147) or (x^.kind = 205) or (x^.kind = 146) then
      if kf_tree_ptr_t(x)^.uses = 0 then
        res^.xw[5] := node_number(stmt);
  end;
  n := res;
90:
end;

{ kfold - fold the tree n of the statement stmt (address arithmetic
  not folded).  0x0AF444, 0x34 bytes, link #0: stmt by address, its
  value passed on. }

procedure kfold;
begin
  kfold_$general(stmt, n, false);
end;
