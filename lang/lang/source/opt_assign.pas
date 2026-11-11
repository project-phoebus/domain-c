{ opt_assign - merging assignments to adjacent storage: from a run of
  assignment statements (140, the 188s between them skipped), an
  assignment of a constant folded into an earlier one that covers its
  storage (merge_assignments), and consecutive assignments to
  neighbouring storage (from neighbouring sources, or of constants
  whose bytes are laid out in a buffer and made into one constant)
  turned into one wider assignment or block move.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0D393C  0x2A0B2C  assert_merge_would_produce_misleading_aliasing
    0x0D3984  0x2A0B74  merge_assignments
    0x0D3BAC  0x2A0D9C  cpbyte (in assign_opt)
    0x0D3BC4  0x2A0DB4  cpword (in assign_opt)
    0x0D3BF2  0x2A0DE2  cplong (in assign_opt)
    0x0D3C22  0x2A0E12  var_is_ok (in assign_opt)
    0x0D3D6E  0x2A0F5E  ok_node (in assign_opt)
    0x0D3F62  0x2A1152  at_offset (in assign_opt)
    0x0D4046  0x2A1236  assign_opt
    A5 0x2D2E48 (cc.m68k), 0x4937F4 (cc.a88k): the unit has no data
    (opt_cse's block follows).

  assign_opt is global (g_opt.ins.pas) and loads A5; the two other
  module-level routines do not and are internal.  cpbyte (a leaf
  without a frame), cpword and cplong append to assign_opt's buffer
  (the static link in A1; cplong, called only from assign_opt, takes
  its frame from its dynamic link, docs/rev889-patterns.md 25).

  delay.pas's table of the bytes of each register class (cc.m68k
  0x169968, reached absolutely) is declared here as cg_fp.pas and
  outbin.pas declare it; kfold.pas's dbl_to_real likewise (no insert
  the unit opens holds it).

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind sets), 19
  (dbl_to_real's single result).
}
module opt_assign;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

var
  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, the bytes. }
  delay_378: extern array [0..15] of integer;

{ DBL_TO_REAL - kfold.pas 0x0ACDC2 (cc.a88k 0x0AE7A2): the real
  constant n as a single (line for a diagnostic). }
function dbl_to_real(
    n: il_$node_ptr_t;
    line: integer): real; options(val_param); extern;

define
  assign_opt;

{ assert_merge_would_produce_misleading_aliasing - with target
  property +0x7F, the left sides of a and b point into different
  storage (alias_$ind_for_captured_lvalue).

  0x0D393C, 0x48 bytes: the first result kept in a frame temporary;
  the second call's argument not popped before the compare. }

function assert_merge_would_produce_misleading_aliasing(
    a: g_opt_stmt_ptr_t;
    b: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
begin
  if target_properties.p_7f then
    assert_merge_would_produce_misleading_aliasing :=
        alias_$ind_for_captured_lvalue(a^.asg_lhs) <>
        alias_$ind_for_captured_lvalue(b^.asg_lhs)
  else
    assert_merge_would_produce_misleading_aliasing := false;
end;

{ merge_assignments - fold assignment t of a constant, off bytes into
  the storage of the wider assignment s of a constant, into s's
  constant: t's part of s's value (shifted down by the difference of
  their widths, from delay's table) combined with t's constant by t's
  operator, and put back in place.

  0x0D3984, 0x1E2 bytes, link #-40.  An off outside 0..3 and an
  operator without an entry in the jump table (0x0D3A2C: 0 store, 1
  add, 2 subtract, 3 and, 4 or, 5 exclusive or, 10 a bit field, 13
  not, 14 negate, 15 shift left) are reported (cgerr_no_source(28,
  strtk(...)), the strings after the routine).  t's constant is read
  for the operators in [0..5, 10, 15] (`btst' on 0x843F), else left
  unset (D4).  The shifts are logical (`lsr.l').  The new constant has
  s's constant's kind.

  Not known from the original:
  - the locals' names; whether the repeated size test of the insertion
    was the source's. }

procedure merge_assignments(
    s: g_opt_stmt_ptr_t;
    t: g_opt_stmt_ptr_t;
    off: integer32); options(val_param); internal;
var
  w: integer32;
  v: integer32;
  ssize: integer32;
  tsize: integer32;
  shift: integer32;
  bits: integer32;
  pos: integer32;
  full: integer32;
  m: integer32;
begin
  if (off < 0) or (off > 3) then
    cgerr_no_source(28, integer32(strtk('invalid offset in merge_assignments', 35)));
  if t^.asg_op in [0..5, 10, 15] then
    w := t^.asg_rhs^.int_value;
  v := s^.asg_rhs^.int_value;
  ssize := delay_378[s^.asg_rlen];
  tsize := delay_378[t^.asg_rlen];
  shift := (ssize - tsize - off) * 8;
  v := rshft(v, shift);
  case t^.asg_op of
    0:
      v := w;
    1:
      v := v + w;
    2:
      v := v - w;
    3:
      v := v & w;
    4:
      v := v ! w;
    5:
      v := xor(v, w);
    15:
      v := lshft(v, w);
    10: begin
      bits := tsize * 8;
      pos := bits - t^.asg_w56 - t^.asg_w54;
      if tsize = 4 then
        full := -1
      else
        full := lshft(1, bits) - 1;
      m := lshft(rshft(rshft(lshft(-1, t^.asg_w54) & full, t^.asg_w54),
                       pos), pos);
      v := (v & ~m) ! (lshft(w, pos) & full & m);
    end;
    13:
      v := ~v;
    14:
      v := -v;
    otherwise
      cgerr_no_source(28, integer32(strtk('unknown aop in merge_assignments', 32)));
  end;
  if tsize <> 4 then begin
    bits := tsize * 8;
    full := lshft(1, bits) - 1;
    v := lshft(v & full, shift);
    if tsize = 4 then
      m := -1
    else
      m := full;
    m := lshft(rshft(rshft(m & lshft(-1, off * 8), off * 8), shift), shift);
    v := v ! (~m & s^.asg_rhs^.int_value);
  end;
  s^.asg_rhs := smcontk(s^.asg_rhs^.kind, v);
end;

{ assign_opt - from statement start (and the assignments just before
  it), merge each run of assignments to adjacent storage into one.

  0x0D4046, 0x6E8 bytes, link #-4208; only when the optimization
  opt_on element 8 is on (cargs +0x282 bit 1).  The statements are
  walked from the first assignment of the run: 188s are skipped; a
  statement ok_node refuses ends the run (the next one starts another
  when it is a 140 or 188).  Within a run, an assignment t following
  prev with both constant (prev a plain store) is first folded into
  prev when prev's storage covers it (at_offset 2, merge_assignments;
  t marked deleted, its left side's use given back, unlinked).
  Otherwise t joins cur's group when it lies just after (1) or just
  before (-1) the group's storage, always on the same side, from
  storage likewise adjacent to the group's source (or both constant,
  at most 2048 bytes), and the descriptors of the group's source and
  destination are not related in a way that makes it unsafe (an
  inexact one, a class other than through a parameter pointer or a
  random pointer, different displacements).  A statement joining
  before is moved before its predecessor, which ends the group.

  A group of two or more becomes cur: of a constant, the constants'
  bytes (a set's words, a string's characters padded with blanks to
  a block move's size, an integer by the stored width, a single
  through dbl_to_real, a double, a pair or a double complex's
  longwords) laid out in the buffer and made into an integer constant
  (2 or 4 bytes of a numeric class: rlen in [2, 4..8], `btst' on
  0x1F4), a set constant (setcontk) or a string (strtk); the size is
  the group's, the class 4, 2 or 11 (a block move, operator 6, its
  characters flag set when not numeric); the other statements of the
  group are marked deleted, their uses given back, and cut out.

  The node kind sets are 26-byte constants (the constants, 0x0D472E:
  77..90, 92, 93, 101, 156, 176, 198, 200; the integer constants,
  0x0D3F48: 77..87, 101, 200; docs/dpc-gaps.md 8); the constants'
  kinds are a compare chain in the order of the case's labels.

  Not known from the original:
  - the locals' names; how the loops were written (the image jumps
    between three points: taken as gotos); the buffer's length (4096
    taken: the frame holds 4096 bytes from -4144). }

procedure assign_opt(
    start: g_opt_stmt_ptr_t);
label
  10, 20, 30;
type
  buf_t = record
    case integer of
      1: (c: array [1..4096] of char);
      2: (l: integer32);
  end;
  real_bits_t = record
    case integer of
      1: (r: real);
      2: (l: integer32);
  end;
var
  da: alias_$desc_t;
  db: alias_$desc_t;
  buf: buf_t;
  rv: real_bits_t;
  cur: g_opt_stmt_ptr_t;
  t: g_opt_stmt_ptr_t;
  prev: g_opt_stmt_ptr_t;
  p: g_opt_stmt_ptr_t;
  q: g_opt_stmt_ptr_t;
  x: il_$node_ptr_t;
  src: il_$node_ptr_t;
  size: integer32;
  size_a: integer32;
  tsize: integer32;
  total: integer32;
  diff: integer32;
  n: integer;
  buflen: integer;
  dir: integer;
  k: integer;
  i: integer;
  j: integer;
  both: boolean;
  isnum: boolean;

  { cpbyte - append c to the buffer.

    0x0D3BAC, 0x18 bytes, no frame: the parent's frame from A1; the
    length at -4190, the buffer from -4144. }

  procedure cpbyte(
      c: char); options(val_param);
  begin
    buflen := buflen + 1;
    buf.c[buflen] := c;
  end;

  { cpword - append w's two bytes, high first.

    0x0D3BC4, 0x2E bytes: `lsr.w #8' for the high byte; A1 passed on. }

  procedure cpword(
      w: integer); options(val_param);
  begin
    cpbyte(chr(rshft(w, 8) & 16#FF));
    cpbyte(chr(w & 16#FF));
  end;

  { cplong - append l's four bytes, high first.

    0x0D3BF2, 0x30 bytes: the parent's frame from the dynamic link
    (`movea.l (A6),A2'), passed to cpword in A1; `clr.w; swap' for the
    high word. }

  procedure cplong(
      l: integer32); options(val_param);
  begin
    cpword(rshft(l, 16));
    cpword(l & 16#FFFF);
  end;

  { var_is_ok - variable v (or any other node) may be merged: a 109
    not of a routine (+28's kind 107) nor flagged (+32 & 0x201001)
    only when of a 5-class parameter's (+72 5, its type a 121), ranged
    or a 123, 134 or 130 type, and then of one of the classes 3, 4, 7
    or 8, or 1 outside a block of kind 105 (`btst' on 0x19A); a 110
    of storage kind 3 (+44 bits 7..4), or 1 with +44 bit 3 and +45
    bits 5..3 1, only when nothing points into it (+32 nil, or of
    class 5 by +11 bits 7..4), +28 and +58 are nil, +11's class is not
    3, 4 or 8 (`btst' on 0x118) and +24 has none of 0x201001.

    0x0D3C22, 0x14C bytes, link #-36: type_exp(v) to a frame record at
    -32 (its type at +0, ranged +25 bit 6); the result in D0 from `st'.

    Not known from the original:
    - what the variable fields are; why +32 is tested for nil twice. }

  function var_is_ok(
      v: il_$node_ptr_t): boolean; options(val_param);
  type
    texp_t = record
      base: il_$node_ptr_t;             { +0 }
      unused_4: array [1..5] of integer32;  { +4..+23 }
      flags: packed record              { +24 }
        b24: 0..255;
        b25_7: boolean;                 { +25 }
        ranged: boolean;                { .6 }
        b25_rest: 0..63;
      end;
    end;
  var
    te: texp_t;
    k: integer;
    f: integer;
  begin
    var_is_ok := true;
    k := v^.kind;
    if (k = 110) or (k = 109) then
      if (k = 109) and (v^.xp[7]^.kind <> 107) and
         ((v^.xl[8] & 16#201001) = 0) then begin
        type_exp(v, addr(te));
        if ((v^.xw[36] = 5) and (v^.xp[7]^.kind = 121)) or te.flags.ranged or
           (te.base^.kind = 123) or (te.base^.kind = 134) or
           (te.base^.kind = 130) then begin
          if (v^.xw[36] = 1) and (il_180^.kind = 105) then
            var_is_ok := false
          else if v^.xw[36] in [1, 3, 4, 7, 8] then
            var_is_ok := true
          else
            var_is_ok := false;
        end
        else
          var_is_ok := true;
      end
      else if k = 110 then begin
        f := rshft(ord(v^.xc[44]) & 16#F0, 4);
        if (f = 3) or
           (((ord(v^.xc[44]) & 16#08) <> 0) and (f = 1) and
            (rshft(ord(v^.xc[45]) & 16#38, 3) = 1)) then
          if (v^.xp[8] = nil) or
             ((v^.xp[8] <> nil) and
              (rshft(ord(v^.xc[11]) & 16#F0, 4) = 5)) then
            if v^.xp[7] = nil then
              if v^.xp2[14] = nil then
                begin
                  f := rshft(ord(v^.xc[11]) & 16#F0, 4);
                  if not (f in [3, 4, 8]) then
                    if (v^.xl[6] & 16#201001) = 0 then
                      var_is_ok := false;
                end;
      end;
  end;

  { ok_node - statement t may take part in a merge: an assignment not
    to a strength reduction temporary, of an operator outside 27..30,
    neither deleted nor kept (+41 bits 1..0), not in a block of kind 2
    (il_180's +377 bits 6..4) under opt_on element 18, its left side's
    variable not flagged (bit 21 of a 110's +24, a 109's +32), neither
    side with getphase elements 1 or 2, not a 164 or a string in a
    block of kind 2, both sides' variables var_is_ok; then true for a
    store of other than one byte (or under target property +0x84), an
    operator 11, a block move (6) of other than characters (or under
    +0x84), and with consts for 14, 13 and the operators in [0..5, 10,
    15] of an integer constant.

    0x0D3D6E, 0x1DA bytes, link #-12: the result in D2 from `clr.b',
    every refusal a branch to the end. }

  function ok_node(
      t: g_opt_stmt_ptr_t;
      consts: boolean): boolean; options(val_param);
  var
    lhs: il_$node_ptr_t;
    rhs: il_$node_ptr_t;
  begin
    ok_node := false;
    if t^.kind <> 140 then
      return;
    if il_utils_$is_strength_reduction_temp(t^.asg_lhs) then
      return;
    if t^.asg_op in [27..30] then
      return;
    if t^.hdr.no_prune or t^.hdr.deleted then
      return;
    if (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2) and
       (18 in cargs_$options.opt_on) then
      return;
    lhs := t^.asg_lhs;
    if lhs^.kind = 110 then
      if (lhs^.xl[6] & 16#200000) <> 0 then
        return;
    if lhs^.kind = 109 then
      if (lhs^.xl[8] & 16#200000) <> 0 then
        return;
    if (getphase(t^.asg_rhs) + getphase(t^.asg_lhs)) * [1, 2] <> [] then
      return;
    if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
      if (t^.asg_rhs^.kind = 164) or (t^.asg_rhs^.kind = 92) then
        return;
    rhs := t^.asg_rhs;
    if (rhs^.kind = 110) or (rhs^.kind = 109) then
      if not var_is_ok(rhs) then
        return;
    lhs := t^.asg_lhs;
    if (lhs^.kind = 110) or (lhs^.kind = 109) then
      if not var_is_ok(lhs) then
        return;
    if t^.asg_op = 0 then
      if target_properties.p_84 or (t^.asg_rlen <> 1) then begin
        ok_node := true;
        return;
      end;
    if t^.asg_op = 11 then begin
      ok_node := true;
      return;
    end;
    if t^.asg_op = 6 then
      if target_properties.p_84 or not t^.asg_flags.chars then begin
        ok_node := true;
        return;
      end;
    if consts then
      if (t^.asg_op = 14) or (t^.asg_op = 13) then
        ok_node := true
      else if t^.asg_op in [0..5, 10, 15] then
        if t^.asg_rhs^.kind in [77..87, 101, 200] then
          ok_node := true;
  end;

  { at_offset - where storage b of size_b bytes lies relative to
    storage a of size_a: through displacements (147: +32 to +24's
    base) to the same base (the same node, or 145s with the same +24,
    +36 and +40, their +32 added, or 146s with the same +24 and +28
    outside a block of kind 3 or 4): -1 b just after a, 1 just before,
    2 b within a, else 0; diff the displacement of b from a.

    0x0D3F62, 0x0E4 bytes, link #-16: the result a word in D0 from
    `clr.w'; the extents compared signed. }

  function at_offset(
      a: il_$node_ptr_t;
      size_a: integer32;
      b: il_$node_ptr_t;
      size_b: integer32;
      var diff: integer32): integer; options(val_param);
  var
    da: integer32;
    db: integer32;
    end_a: integer32;
    end_b: integer32;
    f: integer;
  begin
    at_offset := 0;
    da := 0;
    while a^.kind = 147 do begin
      da := da + a^.xl[8];
      a := a^.xp[6];
    end;
    db := 0;
    while b^.kind = 147 do begin
      db := db + b^.xl[8];
      b := b^.xp[6];
    end;
    if a^.kind <> b^.kind then
      return;
    if a <> b then
      case a^.kind of
        145:
          if (a^.xp[6] = b^.xp[6]) and (a^.xp[9] = b^.xp[9]) and
             (a^.xw[20] = b^.xw[20]) then begin
            da := da + a^.xl[8];
            db := db + b^.xl[8];
          end
          else
            return;
        146: begin
          f := rshft(ord(il_180^.xc[377]) & 16#70, 4);
          if (a^.xp[6] <> b^.xp[6]) or (a^.xp[7] <> b^.xp[7]) or
             (f in [3, 4]) then
            return;
        end;
        otherwise
          return;
      end;
    diff := db - da;
    end_a := size_a + da;
    if end_a = db then
      at_offset := -1
    else begin
      end_b := size_b + db;
      if end_b = da then
        at_offset := 1
      else if (end_a >= end_b) and (da <= db) then
        at_offset := 2;
    end;
  end;

begin
  if not (8 in cargs_$options.opt_on) then
    return;
  cur := start;
  while (cur^.prev^.kind = 140) or (cur^.prev^.kind = 188) do
    cur := cur^.prev;
10:
  while cur^.kind = 188 do
    cur := cur^.next;
  if not ok_node(cur, false) then begin
    cur := cur^.next;
    if cur = nil then
      return;
    if (cur^.kind = 140) or (cur^.kind = 188) then
      goto 10;
    return;
  end;
  if cur^.asg_rhs^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
    src := nil
  else
    src := cur^.asg_rhs;
  if (cur^.asg_op = 25) or (cur^.asg_op = 6) then
    size := cur^.asg_size
  else
    size := delay_378[cur^.asg_rlen];
  n := 1;
  t := cur^.next;
  prev := cur;
  size_a := size;
20:
  while t^.kind = 188 do
    t := t^.next;
  both := (prev^.asg_op = 0) and
          (prev^.asg_rhs^.kind in [77..87, 101, 200]);
  if t^.kind = 140 then begin
    if t^.asg_rhs = nil then
      both := false
    else if not (t^.asg_rhs^.kind in [77..87, 101, 200]) then
      both := false;
  end
  else
    both := false;
  if not ok_node(t, both) then
    goto 30;
  if (t^.asg_op = 25) or (t^.asg_op = 6) then
    tsize := t^.asg_size
  else
    tsize := delay_378[t^.asg_rlen];
  if both and (t^.asg_op in [0..5, 10, 13..15]) then begin
    if not assert_merge_would_produce_misleading_aliasing(prev, t) then
      if at_offset(prev^.asg_lhs, size_a, t^.asg_lhs, tsize, diff) = 2 then begin
        merge_assignments(prev, t, diff);
        adjust_uc(t^.asg_lhs, -1);
        t^.hdr.deleted := true;
        t^.prev^.next := t^.next;
        t^.next^.prev := t^.prev;
        t := t^.next;
        goto 20;
      end;
    if t^.asg_op <> 0 then
      goto 30;
    if not ok_node(t, false) then
      goto 30;
  end;
  k := at_offset(cur^.asg_lhs, size, t^.asg_lhs, tsize, diff);
  if (k <> 1) and (k <> -1) then
    goto 30;
  if n = 1 then
    dir := k
  else if k <> dir then
    goto 30;
  if src = nil then begin
    if not (t^.asg_rhs^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200]) then
      goto 30;
    if size + tsize > 2048 then
      goto 30;
  end
  else if at_offset(src, size, t^.asg_rhs, tsize, diff) <> k then
    goto 30;
  total := size + tsize;
  alias_$alias_desc_with_size(cur^.asg_rhs, total, da);
  alias_$alias_desc_with_size(cur^.asg_lhs, total, db);
  if alias_$related(da, db) then begin
    if db.inexact then
      goto 30;
    if da.inexact then
      goto 30;
    if not (da.class in [alias_ref_thru_param_ptr, alias_random_pointer]) then
      goto 30;
    if da.disp <> db.disp then
      goto 30;
  end;
  if assert_merge_would_produce_misleading_aliasing(cur, t) then
    goto 30;
  n := n + 1;
  size := total;
  if k = 1 then begin
    q := t^.prev;
    q^.next := t^.next;
    t^.next^.prev := q;
    t^.next := q;
    t^.prev := q^.prev;
    q^.prev := t;
    t^.prev^.next := t;
    if q = cur then
      cur := t;
    t := q^.next;
    goto 30;
  end;
  prev := t;
  size_a := tsize;
  t := t^.next;
  goto 20;
30:
  if n > 1 then begin
    isnum := cur^.asg_rlen in [2, 4..8];
    if src = nil then begin
      p := cur;
      buflen := 0;
      for j := 1 to n do begin
        x := p^.asg_rhs;
        case x^.kind of
          156, 212:
            for i := 1 to x^.set_len div 2 do
              cpword(x^.set_words[i]);
          92: begin
            for i := 1 to x^.str_len do
              cpbyte(x^.str_chars[i]);
            if p^.asg_op = 6 then
              for i := x^.str_len + 1 to p^.asg_size do
                cpbyte(' ');
          end;
          87, 79, 78, 77, 85, 84, 83, 86, 82, 80, 200, 81:
            if p^.asg_rlen = 1 then
              cpbyte(x^.xc[11])
            else if p^.asg_rlen = 2 then
              cpword(x^.xw[5])
            else
              cplong(x^.int_value);
          89: begin
            cplong(x^.bits[1]);
            cplong(x^.bits[2]);
          end;
          88: begin
            rv.r := dbl_to_real(x, p^.line);
            cplong(rv.l);
          end;
          90: begin
            cplong(x^.pair_a);
            cplong(x^.pair_b);
          end;
          198: begin
            cplong(x^.bits[1]);
            cplong(x^.bits[2]);
            cplong(x^.bits[3]);
            cplong(x^.bits[4]);
          end;
          otherwise ;
        end;
        repeat
          p := p^.next;
        until p^.kind <> 188;
      end;
      if (buflen = 4) or (buflen = 2) then
        if isnum then
          x := smcontk(81, buf.l)
        else
          x := strtk(buf.c, buflen)
      else if isnum then
        x := setcontk(buf.c, 0, buflen)
      else
        x := strtk(buf.c, buflen);
      cur^.asg_rhs := x;
    end;
    cur^.asg_size := size;
    if not isnum then
      cur^.asg_rlen := 11
    else if size = 4 then
      cur^.asg_rlen := 4
    else if size = 2 then
      cur^.asg_rlen := 2
    else
      cur^.asg_rlen := 11;
    if cur^.asg_rlen = 11 then begin
      cur^.asg_op := 6;
      cur^.asg_flags.chars := not isnum;
    end;
    q := cur^.next;
    for j := 1 to n - 1 do begin
      while q^.kind = 188 do
        q := q^.next;
      adjust_uc(q^.asg_rhs, -1);
      adjust_uc(q^.asg_lhs, -1);
      q^.hdr.deleted := true;
      q := q^.next;
    end;
    if t^.prev^.kind = 188 then
      while t^.prev^.kind = 188 do
        t := t^.prev;
    cur^.next := t;
    t^.prev := cur;
  end;
  cur := t;
  goto 10;
end;
