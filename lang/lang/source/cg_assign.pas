{ cg_assign - the m68k code generator's assignments: assign_proc keeps
  a register variable's value in its register (the destination's home,
  chk_assign) or stores to memory, with the assignment operators done
  in place (and, or, exclusive or with constant masks as byte or word
  stores, single bits by bset/bclr/bchg, shifts, the floating
  operators through the FPA, the PEB or the 68881), aggregates moved
  inline or by a loop (agg_assign_proc, cg_asn_$block_move), sets
  (set_aops), bit fields (pack_assign_proc) and the string builtins;
  target and tleftright look for the destination in the source's tree
  to evaluate that operand first.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0F3068  --------  cg_asn_$block_move_body_size
    0x0F30AE  --------  cg_asn_$inline_move_is_best
    0x0F30FA  --------  cg_asn_$block_move
    0x0F31B8  --------  target
    0x0F34D8  --------  tleftright
    0x0F36F4  --------  fault_free_assign
    0x0F3740  --------  agg_len_assign_proc
    0x0F3816  --------  remove_postincrement (in agg_assign_proc)
    0x0F3826  --------  agg_assign_proc
    0x0F3F28  --------  multi_assign_proc
    0x0F3FBC  --------  set_aops
    0x0F4166  --------  gen_clr_set
    0x0F4290  --------  pack_assign_proc
    0x0F467E  --------  cspe (in assign_proc)
    0x0F469E  --------  assign_proc
    A5 0x355274 (cc.m68k), 0x84 bytes: +0 and +24 two operands (opa,
    opb: 20 bytes each), +0x30 the generic instructions of the
    assignment operators (25 words, .rwdi: 0 1 2 3 4 5 0 3 4 3 0 0 0
    12 11 13 13 14 0 43 44 45 46 0 0), +0x7C the destination target
    looks for; +0x14, +0x2C and +0x62..+0x7B, +0x80 are not addressed.

  cg_asn_$inline_move_is_best, cg_asn_$block_move, fault_free_assign,
  multi_assign_proc and assign_proc load A5 and are global; the others
  do not and are internal (they run on their callers' A5).
  remove_postincrement and cspe are nested and take no frame
  (docs/rev889-patterns.md 16).

  The statement is read through cg.ins.pas's cg_asn_t (from the node's
  +4, as codegen passes it); the other nodes by offset (il.ins.pas's
  views).  emit's generic instructions as numbers (docs/questions.md
  77, 83): 0 move, 1 add, 2 subtract, 3 and, 4 or, 12 not, 13 a shift
  (x its kind: 2 logical right, 3 left), 16 bchg, 63 bfins; operand
  modes (f1) 1 a register, 2 d(An), 8 (An)+, 13 a floating register.
  delay.pas's word table at 0x169968 (delay_378: a class's width in
  bytes) as cg_fp.pas declares it.

  Not known from the original: the names of the module's variables, the
  locals and the parameters; the IL nodes' fields (by offset). }
module cg_assign;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';

type
  { A register list statement (kind 191) as assign_proc reads it
    (cg_top.pas's top_reg_list_t): count entries from +52, each an
    object, its register and +10 (32 for the entries assign_proc
    considers). }
  asn_reg_ent_t = record
    obj: il_$node_ptr_t;                { +0 }
    reg: integer;                       { +4 }
    size: integer;                      { +6 }
    flags: integer;                     { +8 }
    w10: integer;                       { +10 }
  end;
  asn_reg_list_ptr_t = ^asn_reg_list_t;
  asn_reg_list_t = record
    unused_0: array [0..24] of integer; { +0 }
    count: integer;                     { +50 }
    ents: array [1..64] of asn_reg_ent_t;  { +52 }
  end;

  { agg_assign_proc's copy of a constant source's bytes (16 at most),
    read as longwords, words or bytes from 1. }
  asn_bytes_t = record
    case integer of
      1: (l: array [1..4] of integer32);
      2: (w: array [1..8] of integer);
      3: (c: array [1..16] of char);
  end;

var
  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, its width in bytes. }
  delay_378: extern array [0..15] of integer;

  opa: codegen_$uads_t;                 { +0 }
  opb: codegen_$uads_t;                 { +24 }
  asn_ops: array [0..24] of integer := [0, 1, 2, 3, 4, 5, 0, 3, 4, 3, 0,
      0, 0, 12, 11, 13, 13, 14, 0, 43, 44, 45, 46, 0, 0];  { +0x30 }
  asn_target: il_$node_ptr_t;           { +0x7C }

define
  cg_asn_$inline_move_is_best, cg_asn_$block_move, fault_free_assign,
  multi_assign_proc, assign_proc;


{ cg_asn_$block_move_body_size - the moves in a block move loop's body
  for count units: 4 when count is a multiple of 4, 3 of 3, else 2.

  0x0F3068, 0x46 bytes: M$OIS$WLW for both remainders; the result a
  word that the callers zero-extend. }

function cg_asn_$block_move_body_size(
    count: integer32): cg_count_t; options(val_param); internal;
begin
  if count mod 4 = 0 then
    cg_asn_$block_move_body_size := 4
  else if count mod 3 = 0 then
    cg_asn_$block_move_body_size := 3
  else
    cg_asn_$block_move_body_size := 2;
end;

{ cg_asn_$inline_move_is_best - count moves inline (2 bytes each) are
  best when they take no more than half again the loop's bytes (its
  body's moves and 8 more).

  0x0F30AE, 0x4C bytes: the result cleared in the frame (-10), then
  `jsr fpp_$' of the two values (count * 2, body * 2 + 8) with the
  operation words 0x002C, the single 1.5 (0x3FC00000) and 0x0048
  (docs/rev889-patterns.md 19), and `bmi' over the `st'.

  Not known from the original:
  - the comparison: the FPP words are not decoded; taken as `<=' from
    the result's use (docs/dpc-gaps.md 7);
  - the unit size, which is passed (as reg_save's call passes it) but
    not read. }

function cg_asn_$inline_move_is_best;
var
  best: boolean;
begin
  best := false;
  if count * 2 <= (cg_asn_$block_move_body_size(count) * 2 + 8) * 1.5 then
    best := true;
  cg_asn_$inline_move_is_best := best;
end;

{ cg_asn_$block_move - count units of size moved from src to dst by a
  loop whose body holds body_size moves (its counter and label r1, r2,
  agg_loop_start's), then the remaining move.

  0x0F30FA, 0xBE bytes: M$DIS$LLL and M$OIS$LLL of count by the body
  size; the moves a `for' counted by `dbf'. }

procedure cg_asn_$block_move;
var
  n: cg_count_t;
  iter: integer32;
  rem: integer;
  i: integer32;
begin
  n := cg_asn_$block_move_body_size(count);
  iter := count div n - 1;
  rem := count mod n;
  agg_loop_start(iter, r1, r2);
  for i := 1 to n do
    emit(0, size, dst, src, 0);
  agg_loop_end(iter, r1, r2);
  if rem <> 0 then
    emit(0, size, dst, src, 0);
end;

{ target - whether tree n holds asn_target (an assignment's destination
  object), marking the trees on the way: +6 bit 14 the left operand
  holds it, bit 13 the right; a commutative operator (1, 2 or 34, 35)
  whose right operand only holds it and whose left operand is a tree of
  the same family is rotated so that the destination is reached
  first.  A tree whose flags are already set holds it.

  0x0F31B8, 0x306 bytes, no A5 load: the kinds' set after the code
  (0x0F34BE: 137, 138, 143, 145..147, 164, 171, 175, 189, 205); the
  flags as `andi.l #0x6000' of the longword at +4 and `bset #6' / `bset
  #5' of the byte at +6; the rotation swaps the descriptors (16 bytes
  through a frame copy), operators and right operands of n and its left
  operand, and tests n again; more than two operands counted (`dbf').

  Not known from the original:
  - the flags' names. }

function target(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  k: integer;
  i: integer;
  m: il_$node_ptr_t;
  d: cg_desc_t;
  op: integer;
  p: il_$node_ptr_t;
begin
  r := true;
  if n <> asn_target then
    if (n^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205]) and
        ((n^.xl[1] & 16#6000) <> 0) then
      r := true
    else
      case n^.kind of
        190:
          r := target(n^.xp[1]);
        175, 171:
          if target(n^.xp[4]) then
            n^.xw[3] := n^.xw[3] ! 16#4000
          else
            r := false;
        164: begin
          if target(n^.xp[5]) then
            n^.xw[3] := n^.xw[3] ! 16#4000;
          if target(n^.xp[6]) then
            n^.xw[3] := n^.xw[3] ! 16#2000;
          r := (n^.xl[1] & 16#6000) <> 0;
        end;
        147, 146:
          if target(n^.xp[6]) then begin
            if n^.xw[8] = 1 then
              n^.xw[3] := n^.xw[3] ! 16#4000;
          end
          else
            r := false;
        145: begin
          r := false;
          if target(n^.xp[6]) then begin
            if n^.xw[8] = 1 then
              n^.xw[3] := n^.xw[3] ! 16#4000;
            r := true;
          end;
          if target(n^.xp[9]) then begin
            if n^.xw[8] = 1 then
              n^.xw[3] := n^.xw[3] ! 16#2000;
            r := true;
          end;
        end;
        189:
          if asn_target = n^.xp[5] then
            n^.xw[3] := n^.xw[3] ! 16#4000
          else
            r := false;
        143, 137:
          case cg_tree_ptr_t(n)^.count of
            1:
              if target(cg_tree_ptr_t(n)^.opnd[1]) then
                n^.xw[3] := n^.xw[3] ! 16#4000
              else
                r := false;
            2: begin
              if target(cg_tree_ptr_t(n)^.opnd[1]) then
                n^.xw[3] := n^.xw[3] ! 16#4000;
              if target(cg_tree_ptr_t(n)^.opnd[2]) then
                n^.xw[3] := n^.xw[3] ! 16#2000;
              if (n^.xl[1] & 16#6000) = 0 then
                r := false
              else if ((n^.xw[3] & 16#2000) <> 0) and
                  ((n^.xw[3] & 16#4000) = 0) then begin
                m := cg_tree_ptr_t(n)^.opnd[1];
                if m^.kind = 137 then
                  if (((cg_tree_ptr_t(n)^.op = 2) or
                       (cg_tree_ptr_t(n)^.op = 1)) and
                      ((cg_tree_ptr_t(m)^.op = 2) or
                       (cg_tree_ptr_t(m)^.op = 1))) or
                     (((cg_tree_ptr_t(n)^.op = 35) or
                       (cg_tree_ptr_t(n)^.op = 34)) and
                      ((cg_tree_ptr_t(m)^.op = 35) or
                       (cg_tree_ptr_t(m)^.op = 34))) then begin
                    d := cg_tree_ptr_t(n)^.desc;
                    op := cg_tree_ptr_t(n)^.op;
                    p := cg_tree_ptr_t(n)^.opnd[2];
                    cg_tree_ptr_t(n)^.desc := cg_tree_ptr_t(m)^.desc;
                    cg_tree_ptr_t(n)^.op := cg_tree_ptr_t(m)^.op;
                    cg_tree_ptr_t(n)^.opnd[2] := cg_tree_ptr_t(m)^.opnd[2];
                    cg_tree_ptr_t(m)^.desc := d;
                    cg_tree_ptr_t(m)^.op := op;
                    cg_tree_ptr_t(m)^.opnd[2] := p;
                    n^.xw[3] := n^.xw[3] & ~16#2000;
                    r := target(n);
                  end;
              end;
            end;
            otherwise begin
              k := 0;
              for i := 1 to cg_tree_ptr_t(n)^.count do
                if target(cg_tree_ptr_t(n)^.opnd[i]) then
                  k := k + 1;
              r := k > 0;
              if k > 1 then
                n^.xl[1] := n^.xl[1] ! 16#6000;
            end;
          end;
        otherwise
          r := false;
      end;
  target := r;
end;

{ tleftright - target's flags kept along the path to the destination
  (keep: n's own flags may stay when both are set) and cleared
  elsewhere; a commutative operator (1, 3, 9, 10, 34, 36, 44) whose
  right operand holds the destination has its operands (and their
  classes, desc.w6 and w8) swapped so that it comes first.

  0x0F34D8, 0x216 bytes, no A5 load: target's kinds' set (0x0F34BE);
  the operators' set after the code (0x0F36EE); the clearing `andi.l
  #0xFFFF9FFF'; the swap `andi.w #0xDFFF; ori.w #0x4000' of the word
  at +6. }

procedure tleftright(
    n: il_$node_ptr_t;
    keep: boolean); options(val_param); internal;
var
  i: integer;
  w: integer;
  p: il_$node_ptr_t;
begin
  if n^.kind = 190 then
    tleftright(n^.xp[1], keep)
  else if n^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205] then
  begin
    if not keep or ((n^.xl[1] & 16#6000) <> 16#6000) then
      n^.xl[1] := n^.xl[1] & ~16#6000;
    case n^.kind of
      143, 137:
        case cg_tree_ptr_t(n)^.count of
          1:
            tleftright(cg_tree_ptr_t(n)^.opnd[1], (n^.xw[3] & 16#4000) <> 0);
          2: begin
            tleftright(cg_tree_ptr_t(n)^.opnd[1], (n^.xw[3] & 16#4000) <> 0);
            tleftright(cg_tree_ptr_t(n)^.opnd[2], (n^.xw[3] & 16#2000) <> 0);
            if (cg_tree_ptr_t(n)^.op in [1, 3, 9, 10, 34, 36, 44]) and
                ((n^.xw[3] & 16#2000) <> 0) then begin
              n^.xw[3] := (n^.xw[3] & ~16#2000) ! 16#4000;
              w := cg_tree_ptr_t(n)^.desc.w6;
              cg_tree_ptr_t(n)^.desc.w6 := cg_tree_ptr_t(n)^.desc.w8;
              cg_tree_ptr_t(n)^.desc.w8 := w;
              p := cg_tree_ptr_t(n)^.opnd[1];
              cg_tree_ptr_t(n)^.opnd[1] := cg_tree_ptr_t(n)^.opnd[2];
              cg_tree_ptr_t(n)^.opnd[2] := p;
            end;
          end;
          otherwise
            for i := 1 to cg_tree_ptr_t(n)^.count do
              tleftright(cg_tree_ptr_t(n)^.opnd[i], false);
        end;
      171:
        tleftright(n^.xp[4], (n^.xw[3] & 16#4000) <> 0);
      175:
        tleftright(n^.xp[4], (n^.xw[3] & 16#4000) <> 0);
      147, 146:
        tleftright(n^.xp[6], (n^.xw[3] & 16#4000) <> 0);
      145: begin
        tleftright(n^.xp[6], (n^.xw[3] & 16#4000) <> 0);
        tleftright(n^.xp[9], (n^.xw[3] & 16#2000) <> 0);
      end;
      164: begin
        tleftright(n^.xp[5], (n^.xw[3] & 16#4000) <> 0);
        tleftright(n^.xp[6], (n^.xw[3] & 16#2000) <> 0);
      end;
      otherwise ;
    end;
  end;
end;

{ fault_free_assign - a move of size bytes from src to dst.

  0x0F36F4, 0x4C bytes: src copied to a frame temporary (five `move.l')
  and the copy passed to emit (docs/rev889-patterns.md 64).

  Not known from the original:
  - what fault the name refers to. }

procedure fault_free_assign;
var
  t: codegen_$uads_t;
begin
  t := src;
  emit(0, size, dst, t, 0);
end;

{ agg_len_assign_proc - an aggregate whose length is a word at its
  start (operator 25): a loop of longword moves from (An)+ to (An)+
  counted by the length (agg_len_loop_start) with A0 as the first
  address register tried.

  0x0F3740, 0xD6 bytes, no A5 load. }

procedure agg_len_assign_proc(
    in out s: cg_asn_t); internal;
var
  lab: codegen_$uads_t;
  r: codegen_$uads_t;
  save: integer;
begin
  save := cg_addr_next_areg;
  cg_addr_next_areg := 8;
  load_address(s.right, opb);
  kill_register(opb.f2);
  load_address(s.left, opa);
  kill_register(opa.f2);
  opa.f1 := 8;
  agg_len_loop_start(opb, r, lab);
  opb.f1 := 8;
  emit(0, 4, opa, opb, 0);
  agg_loop_end(1, r, lab);
  unlock(opb);
  opa.x := integer32(s.left);
  invalidate(opa, s.desc.size);
  unlock(opa);
  cg_addr_next_areg := save;
end;

{ agg_assign_proc - an aggregate of s.desc.size bytes (less a string's
  padding, w8, for class 9) moved in units of 4 (1 when the descriptor
  says it may be unaligned, +58 bit 2, and either operand is): by
  cg_asn_$block_move's loop unless the moves inline are best; inline
  each unit from the source (a constant's bytes as immediates, a
  register's value by displacements of cg_tree_1b4, else agg_opr's
  (An)+), then a word and a byte; a string's padding filled with
  blanks.

  0x0F3826, 0x6E8 bytes, no A5 load: A0 made the first address register
  tried (cg_addr_next_areg) and restored; the constants' kinds' set
  after the code (0x0F3F0E: 77..90, 92, 93, 101, 156, 176, 198, 200),
  then a compare chain on the kind (the integers' value at +8, the
  reals' at +12 and +16, a string's or set's first 8 bytes from +18,
  198's 16 bytes from +12); the unit loop `while count >= 0'; M$MIS$LLW
  for the offset of the last unit (an immediate displacement up to 127
  keeps d(An)); cgerr 28 with il_d0 as its line.

  Not known from the original:
  - the flags' names; whether the constant kinds 176 and 212 have a
    value here (176 falls to the cgerr, 212 is copied as a string). }

procedure agg_assign_proc(
    in out s: cg_asn_t); internal;
var
  buf: asn_bytes_t;
  r2: codegen_$uads_t;
  r1: codegen_$uads_t;
  count1: integer32;
  save: integer;
  rem: cg_count_t;
  by_opr: boolean;
  is_const: boolean;
  unit: integer;
  idx: integer;
  len: integer32;
  cnt: integer32;
  off: cg_count_t;
  pad: integer32;
  rem2: integer;
  v: integer32;
  k: integer;
  n: il_$node_ptr_t;

  { remove_postincrement - a's (An)+ made (An) for the last move.

    0x0F3816, 0x10 bytes, no frame: a by address at (4,SP). }

  procedure remove_postincrement(
      in out a: codegen_$uads_t);
  begin
    if a.f1 = 8 then
      a.f1 := 2;
  end;

begin
  save := cg_addr_next_areg;
  cg_addr_next_areg := 8;
  is_const := false;
  by_opr := true;
  idx := 0;
  unit := 4;
  if (s.desc.flags & 16#400) <> 0 then
    if unaligned(s.right) or unaligned(s.left) then
      unit := 1;
  if s.desc.rlen = 9 then
    len := s.desc.size - s.desc.w8
  else
    len := s.desc.size;
  rem := len mod unit;
  cnt := len div unit - 1;
  opb := cg_null_ads;
  count1 := cnt + 1;
  n := s.right;
  if n^.kind in [77..90, 92..93, 101, 156, 176, 198, 200] then begin
    case n^.kind of
      87, 79, 78, 77, 85, 82, 83, 80, 84, 81, 86, 200:
        buf.l[1] := n^.xl[2];
      90, 89, 88: begin
        buf.l[1] := n^.xl[3];
        buf.l[2] := n^.xl[4];
      end;
      92, 212, 156:
        for k := 1 to 4 do
          buf.w[k] := n^.xw[8 + k];
      198: begin
        buf.l[1] := n^.xl[3];
        buf.l[2] := n^.xl[4];
        buf.l[3] := n^.xl[5];
        buf.l[4] := n^.xl[6];
      end;
      otherwise
        cgerr(28, il_d0, nil);
    end;
    if (cnt < 0) or ((cnt = 1) and (rem = 0)) or
        ((cnt = 0) and (rem <= 2)) then begin
      is_const := true;
      by_opr := false;
    end
    else
      agg_opr(s.right, opb);
  end
  else if (cnt <= 0) and (s.desc.w6 = 0) then begin
    address(n, idx, opb);
    by_opr := false;
  end
  else
    agg_opr(n, opb);

  if not cg_asn_$inline_move_is_best(count1, unit) then begin
    load_address(s.left, opa);
    kill_register(opa.f2);
    opa.f1 := 8;
    cg_asn_$block_move(count1, unit, opb, opa, r1, r2);
  end
  else begin
    if ((s.desc.rlen = 9) and (s.desc.w8 <> 0)) or
        (s.left^.kind = 145) then begin
      load_address(s.left, opa);
      kill_register(opa.f2);
      opa.f1 := 8;
    end
    else if ((cnt = 0) and (rem <= 2)) or ((cnt = 1) and (rem = 0)) or
        (cnt < 0) then begin
      address(s.left, 0, opa);
      if cnt * unit + opa.y > 127 then begin
        unlock(opa);
        load_address(s.left, opa);
        kill_register(opa.f2);
        opa.f1 := 8;
      end;
    end
    else begin
      load_address(s.left, opa);
      kill_register(opa.f2);
      opa.f1 := 8;
    end;
    while cnt >= 0 do begin
      idx := idx + 1;
      if is_const then begin
        case unit of
          4: v := buf.l[idx];
          2: v := buf.w[idx];
          1: v := ord(buf.c[idx]);
          otherwise
            cgerr(28, il_d0, nil);
        end;
        unlock(opb);
        anyconst(v, unit, opb);
      end;
      if (cnt = 0) and (rem = 0) and (s.desc.rlen <> 9) then begin
        remove_postincrement(opb);
        remove_postincrement(opa);
      end;
      emit(0, unit, opa, opb, 0);
      if not by_opr and not is_const then
        if opb.f1 = 1 then begin
          cg_tree_1b4^.xw[8] := 1;
          cg_tree_1b4^.xp[6] := s.right;
          cg_tree_1b4^.xp[7] := s.right;
          cg_tree_1b4^.xl[8] := unit;
          unlock(opb);
          address(cg_tree_1b4, 0, opb);
        end
        else
          opb.y := opb.y + unit;
      if opa.f1 <> 8 then
        opa.y := opa.y + unit;
      cnt := cnt - 1;
    end;
  end;

  off := idx * unit;
  if rem >= 2 then begin
    if is_const then begin
      unlock(opb);
      anyconst(buf.w[(off + 2) div 2], 2, opb);
    end;
    if (rem = 2) and (s.desc.rlen <> 9) then begin
      remove_postincrement(opb);
      remove_postincrement(opa);
    end;
    emit(0, 2, opa, opb, 0);
    off := off + 2;
    if not by_opr and not is_const then
      if opb.f1 = 1 then begin
        cg_tree_1b4^.xw[8] := 1;
        cg_tree_1b4^.xp[6] := s.right;
        cg_tree_1b4^.xp[7] := s.right;
        cg_tree_1b4^.xl[8] := off;
        unlock(opb);
        address(cg_tree_1b4, 0, opb);
      end
      else
        opb.y := opb.y + 2;
    if opa.f1 <> 8 then
      opa.y := opa.y + 2;
  end;
  if odd(rem) then begin
    if is_const then begin
      unlock(opb);
      anyconst(ord(buf.c[off + 1]), 1, opb);
    end;
    if s.desc.rlen <> 9 then begin
      remove_postincrement(opb);
      remove_postincrement(opa);
    end;
    emit(0, 1, opa, opb, 0);
  end;
  if by_opr then
    unlock(opb)
  else
    release(opb);

  if (s.desc.rlen = 9) and (s.desc.w8 <> 0) then begin
    pad := s.desc.w8;
    if (unit = 1) or (pad = 1) then
      load_operand(smcontk(81, 16#20), unit, opb)
    else
      load_operand(smcontk(81, 16#20202020), unit, opb);
    if odd(rem) then begin
      pad := pad - 1;
      emit(0, 1, opa, opb, 0);
    end;
    rem2 := pad mod unit;
    cnt := pad div unit - 1;
    if cnt > 3 then begin
      cnt := cnt + 1;
      count1 := cnt;
      cg_asn_$block_move(cnt, unit, opb, opa, r1, r2);
    end
    else
      while cnt >= 0 do begin
        emit(0, unit, opa, opb, 0);
        cnt := cnt - 1;
      end;
    if rem2 >= 2 then
      emit(0, 2, opa, opb, 0);
    if odd(rem2) then
      emit(0, 1, opa, opb, 0);
    unlock(opb);
  end;
  opa.x := integer32(s.left);
  invalidate(opa, s.desc.size);
  unlock(opa);
  cg_addr_next_areg := save;
end;

{ multi_assign_proc - s's source stored to its destination: past 4
  bytes by agg_assign_proc, else one move of the size's bytes.

  0x0F3F28, 0x94 bytes: `cmpi.l #4; bls' (the size unsigned); the
  size's low word as address's class. }

procedure multi_assign_proc;
var
  size: integer;
begin
  if s.desc.size > 4 then
    agg_assign_proc(s)
  else begin
    size := s.desc.size;
    address(s.right, size, opb);
    address(s.left, 0, opa);
    emit(0, size, opa, opb, 0);
    invalidate(opa, s.desc.size);
    release(opb);
    release(opa);
  end;
end;

{ set_aops - a set operation in place (operators 7..9: the generic
  instruction from asn_ops, 9 the complement first): longwords from
  (An)+ through a data register, by a loop past one, then a word.

  0x0F3FBC, 0x1AA bytes, no A5 load: the longwords `lsr.l #2' of the
  size; agg_loop_start and agg_loop_end around the body when more than
  one; cg_addr_next_areg 8 while it runs. }

procedure set_aops(
    in out s: cg_asn_t); internal;
var
  reg: codegen_$uads_t;
  lab: codegen_$uads_t;
  r: codegen_$uads_t;
  save: integer;
  cnt: integer32;
begin
  save := cg_addr_next_areg;
  cg_addr_next_areg := 8;
  load_address(s.right, opb);
  kill_register(opb.f2);
  load_address(s.left, opa);
  kill_register(opa.f2);
  opb.f1 := 8;
  opa.f1 := 8;
  get_register(nil, 4, reg);
  cnt := rshft(s.desc.size, 2) - 1;
  if cnt > 0 then
    agg_loop_start(cnt, r, lab);
  if cnt >= 0 then begin
    emit(0, 4, reg, opb, 0);
    if s.asnop = 9 then
      emit(12, 4, reg, cg_null_ads, 0);
    emit(asn_ops[s.asnop], 4, opa, reg, 0);
    if cnt > 0 then
      agg_loop_end(cnt, r, lab);
  end;
  if (s.desc.size & 3) = 2 then begin
    emit(0, 2, reg, opb, 0);
    if s.asnop = 9 then
      emit(12, 2, reg, cg_null_ads, 0);
    emit(asn_ops[s.asnop], 2, opa, reg, 0);
  end;
  unlock(opb);
  unlock(opa);
  unlock(reg);
  cg_addr_next_areg := save;
end;

{ gen_clr_set - a single bit (the lowest set in mask) of s's
  destination set (op 14) or cleared (15): a bit instruction on a
  register or on the byte that holds it, else an and or or of the
  constant (s's source) of the destination's width.

  0x0F4166, 0x12A bytes, no A5 load: the bit found by a `for' of 32
  (`dbf', its register reused for the result: the bit is not set on
  the path that does not find one); the byte `(width * 8 - 1 - bit) div
  8' (`asr.l #3' after adding 7 to a negative); the width from delay's
  table; `divs.w #8' for the bit in a byte. }

procedure gen_clr_set(
    mask: integer32;
    in out s: cg_asn_t;
    op: integer); options(val_param); internal;
var
  bit: integer32;
  pos: integer;
  i: integer;
  width: integer;
  byte: integer;
begin
  bit := 1;
  for i := 0 to 31 do begin
    if (bit & mask) <> 0 then begin
      pos := i;
      exit;
    end;
    bit := lshft(bit, 1);
  end;
  width := delay_378[s.desc.rlen];
  byte := (width * 8 - 1 - pos) div 8;
  address(s.left, 0, opa);
  if opa.f1 = 2 then begin
    pos := pos mod 8;
    opa.y := opa.y + byte;
    width := 1;
  end;
  if (opa.f1 in [1, 2]) or (byte = 0) then begin
    anyconst(pos, 1, opb);
    emit(op, width, opa, opb, 0);
  end
  else begin
    anyconst(s.right^.xl[2], width, opb);
    if op = 14 then
      emit(4, width, opa, opb, 0)
    else
      emit(3, width, opa, opb, 0);
  end;
  invalidate(opa, s.desc.size);
  release(opa);
  unlock(opb);
end;

{ pack_assign_proc - a bit field store (operators 10, 12): a whole byte
  at a byte boundary by a move; with -CPU M020 (cpu 3) and operator 10
  a bfins of the statement; else the value shifted to the field (a
  constant's shifted and masked at compile time), masked when it may
  have other bits, or-ed into a cleared register and merged into the
  destination with and and or of the field's mask.

  0x0F4290, 0x3D2 bytes, no A5 load: the field's offset and width
  (desc.w6, w8) compared unsigned (`bcs', `bhi'); the operand modes'
  set 0x8B74 (2, 4..6, 8, 9, 11, 15: memory) for a byte's offset in a
  word or long source; the constant kinds' set (0x0F4664); the
  register's 4 a by-address constant (0x0F4662); cgerr 28 with il_d0
  as its line.

  Not known from the original:
  - the operators' meanings (10 a plain store, 12 one that masks). }

procedure pack_assign_proc(
    in out s: cg_asn_t); internal;
var
  r: codegen_$uads_t;
  t: codegen_$uads_t;
  mask: integer32;
  zero: il_$node_ptr_t;
  off: integer;
  hi: integer;
  size: integer;
  bits: integer;
  v: integer32;
  reg: integer;
begin
  off := s.desc.w6;
  address(s.left, 0, opb);
  if (off >= 8) and (off + s.desc.w8 <= 16) and (opb.f1 <> 1) then begin
    off := off - 8;
    opb.y := opb.y + 1;
  end;
  if (off = 0) and (s.desc.w8 = 8) then begin
    address(s.right, s.desc.rlen, opa);
    if opa.f1 in [2, 4..6, 8, 9, 11, 15] then
      case s.desc.rlen of
        2: opa.y := opa.y + 1;
        4: opa.y := opa.y + 3;
        1: ;
        otherwise
          cgerr(28, il_d0, nil);
      end;
    fault_free_assign(1, opb, opa);
    size := 1;
  end
  else if (3 in cargs_$options.cpu) and (s.asnop = 10) then begin
    opb.x := integer32(cg_stmt);
    if off + s.desc.w8 > 16 then
      size := 4
    else
      size := 2;
    load_operand(s.right, s.desc.rlen, opa);
    emit(63, size, opb, opa, 0);
  end
  else begin
    hi := off + s.desc.w8;
    if hi <= 8 then
      size := 1
    else if hi <= 16 then
      size := 2
    else
      size := 4;
    bits := size * 8;
    mask := genmask(off, hi, bits);
    zero := smcontk(81, 0);
    load_modifiable(zero, 4, r);
    if s.right^.kind in [77..87, 101, 200] then begin
      v := s.right^.xl[2];
      if bits - hi > 0 then
        v := lshft(v, bits - hi);
      anyconst(v & mask, s.desc.rlen, opa);
    end
    else begin
      reg := peek(s.right, s.desc.rlen);
      if (reg <> 31) and cg_addr_cache[reg].live then begin
        address(s.right, s.desc.rlen, t);
        get_register(nil, s.desc.rlen, opa);
        emit(0, s.desc.rlen, opa, t, 0);
        unlock(t);
      end
      else
        load_operand(s.right, s.desc.rlen, opa);
      if (s.asnop = 10) and (bits - hi > 0) then begin
        shift(opa, size, bits - hi, 3);
        kill_register(opa.f2);
      end;
      if lshft(1, bits) - 1 <> mask then
        if (s.asnop = 12) or
            (((s.desc.flags & 16#4000) <> 0) and (off <> 0)) then begin
          anyconst(mask, size, t);
          emit(3, size, opa, t, 0);
          kill_register(opa.f2);
          unlock(t);
        end;
    end;
    emit(4, size, r, opa, 0);
    unlock(r);
    kill_register(r.f2);
    anyconst(~mask, size, t);
    unlock(t);
    emit(3, size, opb, t, 0);
    emit(4, size, opb, r, 0);
    kill_register(r.f2);
  end;
  invalidate(opb, size);
  release(opb);
  release(opa);
end;

{ assign_proc - the code of assignment s (a 140 from its +4).

  First, on the first pass, the register the destination will live in:
  its home (chk_assign), or a register list after the statement (191)
  whose entry (+10 32) can hold the class and holds an object that the
  source's tree contains (target, tleftright evaluate that operand
  first); the source is cached there (setobjcache) unless the operator
  changes the value.  Then the trees are walked (tree_walk), and:

  - for the operators a register can take (0..5, 11, 13..16, 19..22)
    when the destination has a home register (or, for a displacement
    147 from a register variable, a cached register of its base: cgerr
    28 when the classes disagree) holding it: the operation on the
    register (a long's home tried as an address register, its value
    then copied back), its new contents recorded, and an address
    register no longer needed for the destination's base forgotten;
  - else in memory, by operator: a constant and/or (3, 4) of a single
    bit by gen_clr_set, of whole bytes or words by clearing or setting
    them; an exclusive or (5) of one bit by bchg, of a whole byte, word
    or long by not; shifts (15, 16) of 1 in place, else through a
    register; the unary operators (13, 14); aggregates, sets and bit
    fields by their routines; the floating operators by the FPA, the
    68881 or the PEB's registers, or the floating stack (stack_fp); the
    string builtins (cg_misc); the others (0, 2, and what the special
    cases leave) by loading the source (a small constant into a
    register when a moveq is shorter, register_tickle) and storing or
    operating on the destination, recording the register's new
    contents.

  0x0F469E, 0x2224 bytes: two jump tables on the operator (0x0F4BBE, 17
  entries, the register's source operand; 0x0F5268, 31 entries, the
  memory path) and compare chains between; the operator sets as
  longword masks (0x01FFE3BE for setobjcache, 0x0079E83F the register
  operators, 7 for 0..2); the constant kinds' set after pack_assign_proc
  (0x0F4664: 77..87, 101, 200); the string 'disp does not match assign
  reg size' (0x0F68C2) for strtk; the register's records through
  0x3550D8 (cg_addr_regs, stored with the stamp 0x355272) and the
  cache through 0x354FB8; -CPU FPA1 (cpu 8, 0x2C3670 bit 2), M020 (3),
  160 and 68881 (2 and 4, tested as `cpu * [2, 4]' or each) and opt_on
  18 (0x2C366D bit 3); the floating stack's count at 0x356308 and the
  remembered variables at 0x3562FC and 0x356300 (cg_fp's).  A stored
  register's obj2 and size are written twice (the second stores make
  the first dead, as the image has them).

  Not known from the original:
  - the labels' and locals' names; whether the shared tails (generic,
    floating, done) were gotos or the compiler's merging. }

procedure assign_proc;
label
  memory, floating, generic, done;
var
  areg: codegen_$uads_t;
  t: codegen_$uads_t;
  r: integer;
  home: integer;
  found: integer;
  size: integer;
  sz: integer;
  i: integer;
  w: integer;
  off: integer;
  op: integer;
  lo: integer;
  n: integer;
  bits: integer;
  h: integer;
  rlen: integer;
  l: asn_reg_list_ptr_t;
  p: il_$node_ptr_t;
  via_long: boolean;
  in_reg: boolean;
  skip: boolean;
  direct: boolean;
  use_reg: boolean;
  v: integer32;
  nv: integer32;
  m: integer32;
  fld: integer32;
  low: integer32;
  lim: integer32;

  { cspe - the object of a common subexpression's node n (190: its +4;
    189: its +20), else n.

    0x0F467E, 0x20 bytes, no frame: n at (4,SP), the result in A0. }

  function cspe(
      n: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    m: il_$node_ptr_t;
  begin
    m := n;
    if m^.kind = 190 then
      m := m^.xp[1]
    else if m^.kind = 189 then
      m := m^.xp[5];
    cspe := m;
  end;

begin
  found := 31;
  r := chk_assign(s.left, s.desc.rlen);
  if (r = 31) and (cg_pass = 1) then begin
    if s.next^.kind = 191 then begin
      r := getobjcache(s.left);
      if r <> 31 then
        if (cg_addr_cache[r].obj <> s.left) or
            (cg_addr_cache[r].size <> s.desc.rlen) then
          r := 31;
      l := asn_reg_list_ptr_t(s.next);
      for i := 1 to l^.count do
        if l^.ents[i].w10 = 32 then
          if not (l^.ents[i].reg in [0..7]) or (s.desc.rlen = 5) or
              (s.desc.rlen = 4) or (s.desc.rlen = 2) or
              (s.desc.rlen = 1) then
            if not (l^.ents[i].reg in [8..15]) or (s.desc.rlen = 5) then
              if not (l^.ents[i].reg in [16..23]) or (s.desc.rlen = 7) or
                  (s.desc.rlen = 6) then
                if (r = 31) or (r = l^.ents[i].reg) then begin
                  asn_target := cspe(l^.ents[i].obj);
                  if target(s.left) then
                    tleftright(s.left, false)
                  else if target(s.right) then begin
                    tleftright(s.right, true);
                    r := l^.ents[i].reg;
                    exit;
                  end
                  else
                    tleftright(s.right, false);
                end;
    end
    else
      r := getobjcache(s.left);
  end
  else if (cg_pass = 1) and ((s.asnop = 11) or (s.asnop = 0)) then begin
    asn_target := s.left;
    tleftright(s.right, target(s.right));
  end
  else if r = 31 then
    r := getobjcache(s.left);
  if not (s.asnop in [1..5, 7..9, 13..24]) and (r <> 31) then
    setobjcache(s.right, r);
  tree_walk(s.left);
  tree_walk(s.right);
  if s.extra <> nil then
    tree_walk(s.extra);
  updateregassign;
  if s.desc.rlen = 0 then
    return;

  if not (s.asnop in [0..5, 11, 13..16, 19..22]) then
    goto memory;

  { The destination's register. }
  via_long := false;
  size := s.desc.rlen;
  if (size = 5) and not (s.asnop in [0..2]) then
    size := 4;
  home := chk_assign(s.left, size);
  if (home = 31) and (s.left^.kind = 147) then begin
    for i := 0 to 12 do
      if cg_addr_cache[i].obj = s.left^.xp[6] then begin
        p := cg_addr_cache[i].obj;
        skip := false;
        if i <= 7 then
          if p^.kind = 146 then
            if (p^.xp[6]^.kind = 195) or (p^.xp[6]^.kind = 163) then
              if 18 in cargs_$options.opt_on then
                if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
                  skip := p^.xp[7]^.kind = 111;
        if not skip then begin
          found := i;
          exit;
        end;
      end;
    if found <> 31 then begin
      case s.left^.xl[8] of
        1:
          if cg_addr_cache[found].size <> 2 then
            cgerr(28, cg_line,
                strtk('disp does not match assign reg size', 36));
        3, 2:
          if cg_addr_cache[found].size <> 4 then
            cgerr(28, cg_line,
                strtk('disp does not match assign reg size', 36));
        otherwise ;
      end;
      home := found;
    end;
  end;
  if home = 31 then
    if size = 5 then begin
      size := 4;
      home := chk_assign(s.left, 4);
    end
    else if size = 4 then
      if s.asnop in [0..2] then begin
        size := 5;
        home := chk_assign(s.left, 5);
        if home = 31 then
          size := 4;
      end
      else begin
        via_long := true;
        home := chk_assign(s.left, 5);
        size := 5;
      end;
  if home = 31 then
    goto memory;
  if (peek(s.left, size) <> home) and (s.asnop <> 11) and (s.asnop <> 0) then
    goto memory;

  { The operation on the register. }
  if cg_fp_count <> 0 then
    purge_fp;
  if (s.asnop = 11) or (s.asnop = 0) then begin
    cg_addr_locks[home] := cg_addr_locks[home] + 1;
    address_reg(home, opa);
    opa.x := integer32(s.left);
  end
  else if via_long then begin
    cg_addr_locks[home] := cg_addr_locks[home] + 1;
    address_reg(home, areg);
    areg.x := integer32(s.left);
    size := 4;
    if peek(s.left, 4) = 31 then begin
      get_register(s.left, 4, opa);
      emit(0, 4, opa, areg, 0);
    end
    else
      address(s.left, size, opa);
  end
  else
    address(s.left, size, opa);
  sz := size;
  case s.asnop of
    0:
      if peek(s.right, size) <> 31 then
        address(s.right, size, opb)
      else if (size = 5) and (peek(s.right, 4) <> 31) then
        address(s.right, 4, opb)
      else if (size = 4) and (peek(s.right, 5) <> 31) then
        address(s.right, 5, opb)
      else
        address(s.right, size, opb);
    1, 2:
      if (size = 5) or (size = 4) then begin
        if peek(s.right, 5) <> 31 then
          address(s.right, 5, opb)
        else if peek(s.right, 4) <> 31 then
          address(s.right, 4, opb)
        else
          address(s.right, size, opb);
      end
      else
        address(s.right, size, opb);
    3:
      if s.right^.kind in [77..87, 101, 200] then begin
        v := s.right^.xl[2];
        if v = -65536 then begin
          sz := 2;
          opb := cg_zero_ads;
        end
        else if v = -256 then begin
          sz := 1;
          opb := cg_zero_ads;
        end
        else
          anyconst(v, size, opb);
      end
      else
        address(s.right, size, opb);
    4:
      if s.right^.kind in [77..87, 101, 200] then begin
        v := s.right^.xl[2];
        if v = 65535 then
          sz := 2
        else if v = 255 then
          sz := 1;
        anyconst(v, sz, opb);
      end
      else
        address(s.right, size, opb);
    13, 14:
      opb := cg_null_ads;
    15, 16:
      if (s.right^.kind in [77..87, 101, 200]) and (s.right^.xl[2] <= 8) then
        anyconst(s.right^.xl[2], s.desc.w8, opb)
      else
        load_operand(s.right, s.desc.w8, opb);
    otherwise
      address(s.right, size, opb);
  end;
  case s.asnop of
    0:
      if (s.right^.kind in [77..87, 101, 200]) and (s.right^.xl[2] = 0) and
          (home >= 8) and (home <= 15) then
        emit(2, sz, opa, opa, 0)
      else if (8 in cargs_$options.cpu) and
          ((opa.f1 = 13) or (opb.f1 = 13)) then
        emit_assign(sz, opa, opb)
      else
        emit(asn_ops[s.asnop], sz, opa, opb, 0);
    5: begin
      if not (opb.f1 in [1, 3]) then begin
        unlock(opb);
        load_operand(s.right, size, opb);
      end;
      emit(asn_ops[s.asnop], sz, opa, opb, 0);
    end;
    15:
      emit(asn_ops[s.asnop], sz, opa, opb, 3);
    16:
      emit(asn_ops[s.asnop], sz, opa, opb, 2);
    11:
      if (opb.f1 <> opa.f1) or (opb.f2 <> opa.f2) then
        if 8 in cargs_$options.cpu then
          emit_assign(sz, opa, opb)
        else
          emit(asn_ops[s.asnop], sz, opa, opb, 0);
    22, 20:
      if 8 in cargs_$options.cpu then
        emit_div_sub(asn_ops[s.asnop], sz, opa, opb)
      else
        emit(asn_ops[s.asnop], sz, opa, opb, sz);
    21, 19:
      if 8 in cargs_$options.cpu then
        emit_mul_add(asn_ops[s.asnop], sz, opa, opb)
      else
        emit(asn_ops[s.asnop], sz, opa, opb, sz);
    otherwise
      emit(asn_ops[s.asnop], sz, opa, opb, 0);
  end;
  invalidate(opa, s.desc.size);
  if via_long then begin
    emit(0, 5, areg, opa, 0);
    setresult(opa.f2, s.left, 4);
    unlock(opa);
    opa := areg;
    size := 5;
  end;

  { The register's new contents. }
  if ((s.asnop = 11) or (s.asnop = 0)) and not (2 in getphase(s.right)) then
  begin
    if not ((s.right^.kind = 147) and
            (s.right^.xp[6] = cg_addr_regs[home].obj) and
            (size + s.right^.xl[8] = cg_addr_regs[home].size)) then
      setresult(home, s.right, size);
  end
  else if found <> 31 then
    setresult(home, s.left^.xp[6], cg_addr_cache[home].size)
  else
    setresult(home, s.left, size);
  if found <> 31 then begin
    cg_addr_regs[home].obj2 := s.left^.xp[6];
    cg_addr_regs[home].size := cg_addr_cache[home].size;
  end
  else begin
    cg_addr_regs[home].obj2 := s.left;
    cg_addr_regs[home].size := size;
  end;
  cg_addr_regs[home].obj2 := s.left;
  cg_addr_regs[home].size := size;
  cg_addr_regs[home].w8 := cg_addr_2ba;
  cg_addr_regs[home].w14 := 0;
  cg_addr_cache[home].live := true;
  release(opb);
  release(opa);

  { An address register holding the destination's base no longer
    needed: its variable lives in a data register. }
  p := il_$node_ptr_t(opb.x);
  if p = nil then
    return;
  if p^.kind = 147 then
    p := p^.xp[6];
  if p^.kind = 146 then
    p := p^.xp[6];
  if (p^.kind = 110) or (p^.kind = 109) then begin
    h := chk_assign(p, 4);
    if opb.f1 in [1, 2] then
      if opb.f2 in [8..12] then
        if not cg_addr_cache[opb.f2].live then
          if cg_addr_cache[opb.f2].obj = nil then
            if h in [0..7] then
              if cg_addr_cache[h].live then
                if cg_addr_locks[opb.f2] = 0 then
                  kill_register(opb.f2);
  end;
  return;

  { In memory. }
memory:
  if (cg_fp_count <> 0) and
      ((s.desc.rlen < 6) or (s.asnop = 11) or (s.asnop = 0)) then
    purge_fp;
  rlen := s.desc.rlen;
  case s.asnop of
    0, 2:
      goto generic;
    1:
      if (s.right = s.left) and (rlen = 2) then begin
        address(s.left, 0, opa);
        shift(opa, rlen, 1, 1);
        invalidate(opa, rlen);
        goto done;
      end
      else
        goto generic;

    { Constant masks: and, or, exclusive or. }
    3: begin
      if not (s.right^.kind in [77..87, 101, 200]) then
        goto generic;
      if 4 in getphase(s.left) then
        goto generic;
      v := s.right^.xl[2];
      if rlen = 1 then
        v := v ! (-256)
      else if rlen = 2 then
        v := v ! (-65536);
      if v = -1 then
        return;
      nv := ~v;
      if ((v + 1) & nv) = nv then begin
        gen_clr_set(nv, s, 15);
        return;
      end;
      off := 0;
      if rlen = 4 then begin
        if v = 16#00FFFFFF then
          w := 1
        else if v = 16#0000FFFF then
          w := 2
        else if v = -16711681 then begin        { 16#FF00FFFF }
          off := 1;
          w := 1;
        end
        else if v = -65281 then begin           { 16#FFFF00FF }
          off := 2;
          w := 1;
        end
        else if v = -65536 then begin           { 16#FFFF0000 }
          off := 2;
          w := 2;
        end
        else if v = -256 then begin             { 16#FFFFFF00 }
          off := 3;
          w := 1;
        end
        else
          goto generic;
      end
      else if rlen = 2 then begin
        if v = -65281 then
          w := 1
        else if v = -256 then begin
          off := 1;
          w := 1;
        end
        else
          goto generic;
      end
      else
        goto generic;
      address(s.left, 0, opa);
      if (opa.f1 <> 2) and (off <> 0) then begin
        address(s.right, rlen, opb);
        emit(3, rlen, opa, opb, 0);
      end
      else begin
        opa.y := opa.y + off;
        address(smcontk(81, 0), w, opb);
        emit(0, w, opa, opb, 0);
      end;
      invalidate(opa, rlen);
      release(opb);
      goto done;
    end;
    4: begin
      if not (s.right^.kind in [77..87, 101, 200]) then
        goto generic;
      if 4 in getphase(s.left) then
        goto generic;
      v := s.right^.xl[2];
      if rlen = 1 then
        v := v & 16#FF
      else if rlen = 2 then
        v := v & 16#FFFF;
      if v = 0 then
        return;
      if ((-v) & v) = v then begin
        gen_clr_set(v, s, 14);
        return;
      end;
      off := 0;
      if rlen = 4 then begin
        if v = 16#0000FFFF then begin
          off := 2;
          w := 2;
        end
        else if v = -65536 then                 { 16#FFFF0000 }
          w := 2
        else if v = -16777216 then              { 16#FF000000 }
          w := 1
        else if v = 16#00FF0000 then begin
          off := 1;
          w := 1;
        end
        else if v = 16#0000FF00 then begin
          off := 2;
          w := 1;
        end
        else if v = 16#000000FF then begin
          off := 3;
          w := 1;
        end
        else
          goto generic;
      end
      else if rlen = 2 then begin
        if v = 16#FF00 then
          w := 1
        else if v = 16#00FF then begin
          off := 1;
          w := 1;
        end
        else
          goto generic;
      end
      else
        goto generic;
      address(s.left, 0, opa);
      if (opa.f1 <> 2) and (off <> 0) then begin
        address(s.right, rlen, opb);
        emit(4, rlen, opa, opb, 0);
      end
      else begin
        opa.y := opa.y + off;
        anyconst(-1, w, opb);
        emit(0, w, opa, opb, 0);
      end;
      invalidate(opa, rlen);
      release(opb);
      goto done;
    end;
    5: begin
      if not (s.right^.kind in [77..87, 101, 200]) then
        goto generic;
      bits := rlen * 8;
      m := (lshft(1, bits) - 1) & s.right^.xl[2];
      if m = 0 then
        goto generic;
      lo := 0;
      while not odd(m) do begin
        m := rshft(m, 1);
        lo := lo + 1;
      end;
      n := 0;
      repeat
        n := n + 1;
        m := rshft(m, 1);
      until m = 0;
      low := lshft(1, lo);
      fld := lshft(1, lo + n) - low;
      if n = 1 then
        direct := rlen = 1
      else begin
        if (fld & s.right^.xl[2]) <> fld then
          goto generic;
        if (lo & 7) <> 0 then
          goto generic;
        if not ((n = 32) or (n = 16) or (n = 8)) then
          goto generic;
        if not (3 in cargs_$options.cpu) and (lo = 8) and (n = 16) then
          goto generic;
        direct := rshft(n, 3) = rlen;
      end;
      if not direct then
        if 4 in getphase(s.left) then
          goto generic;
      address(s.left, 0, opa);
      if n = 1 then begin
        opa.y := opa.y + rlen - rshft(lo + 8, 3);
        w := 1;
        anyconst(lo & 7, 1, areg);
        op := 16;
      end
      else begin
        opa.y := opa.y + (rlen - rshft(lo + n, 3));
        w := rshft(n, 3);
        areg := cg_null_ads;
        op := 12;
      end;
      emit(op, w, opa, areg, 0);
      invalidate(opa, w);
      release(opa);
      unlock(areg);
      return;
    end;

    { The unary operators, shifts. }
    13, 14: begin
      address(s.left, 0, opa);
      emit(asn_ops[s.asnop], rlen, opa, cg_null_ads, 0);
      invalidate(opa, rlen);
      goto done;
    end;
    15:
      if (s.right^.kind in [77..87, 101, 200]) and (s.right^.xl[2] = 1) then
      begin
        address(s.left, 0, opa);
        if rlen = 2 then
          shift(opa, rlen, s.right^.xw[5], 3)
        else begin
          address(s.left, rlen, t);
          unlock(t);
          get_temp_register(s.left, rlen, opb);
          emit(0, rlen, opb, t, 0);
          emit(1, rlen, opa, opb, 0);
          kill_register(opb.f2);
          unlock(opb);
        end;
        invalidate(opa, rlen);
        goto done;
      end
      else begin
        address(s.left, rlen, t);
        unlock(t);
        get_temp_register(s.left, rlen, opb);
        emit(0, rlen, opb, t, 0);
        if s.right^.kind in [77..87, 101, 200] then
          shift(opb, rlen, s.right^.xw[5], 3)
        else begin
          load_operand(s.right, s.desc.w8, opa);
          emit(13, rlen, opb, opa, 3);
          release(opa);
        end;
        kill_register(opb.f2);
        address(s.left, 0, opa);
        emit(0, rlen, opa, opb, 0);
        invalidate(opa, rlen);
        cg_addr_regs[opb.f2].obj2 := cspe(s.left);
        cg_addr_regs[opb.f2].size := rlen;
        unlock(opb);
        goto done;
      end;
    16:
      if (rlen = 2) and (s.right^.kind in [77..87, 101, 200]) and
          (s.right^.xl[2] = 1) then begin
        address(s.left, 0, opa);
        shift(opa, rlen, s.right^.xw[5], 2);
        invalidate(opa, rlen);
        goto done;
      end
      else begin
        address(s.left, rlen, t);
        unlock(t);
        get_temp_register(s.left, rlen, opb);
        emit(0, rlen, opb, t, 0);
        if s.right^.kind in [77..87, 101, 200] then
          shift(opb, rlen, s.right^.xw[5], 2)
        else begin
          load_operand(s.right, s.desc.w8, opa);
          emit(13, rlen, opb, opa, 2);
          release(opa);
        end;
        kill_register(opb.f2);
        address(s.left, 0, opa);
        emit(0, rlen, opa, opb, 0);
        invalidate(opa, rlen);
        cg_addr_regs[opb.f2].obj2 := cspe(s.left);
        cg_addr_regs[opb.f2].size := rlen;
        unlock(opb);
        goto done;
      end;

    { Aggregates, sets, bit fields, the floating operators. }
    6:
      if (cg_fp_count <> 0) and (s.desc.size = 8) then begin
        s.desc.rlen := 7;
        s.asnop := 11;
        goto floating;
      end
      else
        agg_assign_proc(s);
    7, 8, 9:
      set_aops(s);
    10, 12:
      pack_assign_proc(s);
    11:
      goto floating;
    21, 19: begin
      if (cargs_$options.cpu * [2, 4] <> []) and
          ((rlen = 6) or (rlen = 7)) and (cg_fp_count <> 0) then
        purge_fp;
      load_modifiable(s.right, s.desc.rlen, opa);
      address(s.left, rlen, opb);
      if 8 in cargs_$options.cpu then
        emit_mul_add(asn_ops[s.asnop], rlen, opa, opb)
      else
        emit(asn_ops[s.asnop], rlen, opa, opb, rlen);
      release(opa);
      unlock(opb);
      address(s.left, 0, opb);
      emit(0, rlen, opb, opa, rlen);
      unlock(opb);
      invalidate(opb, delay_378[rlen]);
      setresult(opa.f2, s.left, rlen);
    end;
    22, 20: begin
      if ((2 in cargs_$options.cpu) or (4 in cargs_$options.cpu)) and
          ((rlen = 6) or (rlen = 7)) and (cg_fp_count <> 0) then
        purge_fp;
      r := peek(s.right, rlen);
      if (r <> 31) and (peek(s.left, rlen) = r) and
          (cg_addr_cache[r].obj = s.right) and cg_addr_cache[r].live then
      begin
        address(s.left, rlen, opa);
        get_temp_register(s.left, rlen, opb);
        emit(0, rlen, opb, opa, rlen);
        unlock(opa);
      end
      else
        load_modifiable(s.left, s.desc.rlen, opb);
      kill_register(opb.f2);
      address(s.right, rlen, opa);
      if 8 in cargs_$options.cpu then
        emit_div_sub(asn_ops[s.asnop], rlen, opb, opa)
      else
        emit(asn_ops[s.asnop], rlen, opb, opa, rlen);
      unlock(opb);
      release(opa);
      address(s.left, 0, opa);
      emit(0, rlen, opa, opb, rlen);
      invalidate(opb, delay_378[rlen]);
      goto done;
    end;
    25:
      agg_len_assign_proc(s);
    27:
      cbuiltin_strcat(il_$node_ptr_t(addr(s)));
    28:
      cbuiltin_strcpy(il_$node_ptr_t(addr(s)));
    29:
      cbuiltin_strncat(il_$node_ptr_t(addr(s)));
    30:
      cbuiltin_strncpy(il_$node_ptr_t(addr(s)));
    otherwise ;
  end;
  return;

  { A floating store (11). }
floating:
  rlen := s.desc.rlen;
  if ((2 in cargs_$options.cpu) or (4 in cargs_$options.cpu)) and
      ((rlen = 6) or (rlen = 7)) and (cg_fp_count <> 0) then
    purge_fp;
  if (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
      register_tickle(s.right, false) and ((rlen = 6) or (rlen = 7)) then
  begin
    load_operand(s.right, fp_rlen(s.desc, 2), opb);
    unlock(opb);
  end;

  { Through a floating register when one holds either side. }
  if ((peek(s.right, fp_rlen(s.desc, 2)) in [16..23]) or
      (chk_assign(s.right, fp_rlen(s.desc, 2)) in [16..23]) or
      (chk_assign(s.left, fp_rlen(s.desc, 1)) in [16..23])) and
     (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) and
     ((rlen = 6) or (rlen = 7)) then
    use_reg := true
  else if (8 in cargs_$options.cpu) and (rlen > 7) then
    use_reg := (chk_assign(s.left, fp_rlen(s.desc, 1)) in [16..23]) or
        (peek(s.right, fp_rlen(s.desc, 2)) in [16..23]) or
        (chk_assign(s.right, fp_rlen(s.desc, 2)) in [16..23])
  else
    use_reg := false;
  if use_reg then begin
    address(s.right, fp_rlen(s.desc, 2), opb);
    r := chk_assign(s.left, fp_rlen(s.desc, 1));
    if r <> 31 then begin
      unlock(opb);
      cg_addr_locks[r] := cg_addr_locks[r] + 1;
      address_reg(r, opa);
      emit(0, rlen, opa, opb, fp_rlen(s.desc, 2));
      opb := opa;
      setresult(opb.f2, s.right, rlen);
      cg_addr_cache[r].live := true;
    end
    else if opb.f1 <> 13 then begin
      unlock(opb);
      get_register(s.right, rlen, opa);
      emit(0, rlen, opa, opb, fp_rlen(s.desc, 2));
      opb := opa;
      setresult(opb.f2, s.right, rlen);
    end;
    if r = 31 then begin
      address(s.left, 0, opa);
      emit(0, rlen, opa, opb, fp_rlen(s.desc, 1));
      release(opa);
    end
    else
      opa.x := integer32(s.left);
    release(opb);
    invalidate(opa, s.desc.size);
    if (cg_addr_regs[opb.f2].obj2 = nil) or
        (cg_addr_regs[opb.f2].obj2 <> cg_addr_cache[opb.f2].obj) then begin
      cg_addr_regs[opb.f2].obj2 := cspe(s.left);
      cg_addr_regs[opb.f2].size := rlen;
      cg_addr_regs[opb.f2].w8 := cg_addr_2ba;
    end;
    return;
  end;

  { Else moved, or through the floating stack or the FPA. }
  if (cg_fp_count = 0) and not check_use(cg_fp_last_store, s.right) then
  begin
    if rlen > 6 then begin
      agg_assign_proc(s);
      return;
    end;
    address(s.right, rlen, opb);
    address(s.left, 0, opa);
    fault_free_assign(4, opa, opb);
    invalidate(opa, s.desc.size);
    release(opb);
    r := chk_assign(s.left, rlen);
    if r <> 31 then begin
      address_reg(r, opb);
      emit(0, rlen, opb, opa, 0);
      if found <> 31 then
        setresult(r, s.left^.xp[6], cg_addr_cache[r].size)
      else
        setresult(r, s.left, rlen);
      cg_addr_cache[r].live := true;
    end;
    goto done;
  end;
  if 8 in cargs_$options.cpu then begin
    push_fpa_opr(s.right, 1, rlen, 16);
    push_fpa_opr(s.left, 1, rlen, 16);
  end
  else begin
    if not check_use(cg_fp_result, s.right) then
      stack_fp(1, rlen, s.right);
    stack_fp(63, rlen, s.left);
    purge_fp;
  end;
  r := chk_assign(s.left, rlen);
  if r <> 31 then begin
    address_reg(r, opa);
    address(s.left, 0, opb);
    emit(0, rlen, opa, opb, 0);
    unlock(opb);
    if found <> 31 then
      setresult(r, s.left^.xp[6], cg_addr_cache[r].size)
    else
      setresult(r, s.left, rlen);
    cg_addr_cache[r].live := true;
  end;
  return;

  { The other operators: the source loaded or addressed, the operation
    on the destination. }
generic:
  if (rlen = 5) and ((peek(s.right, 4) <> 31) or (s.asnop <> 0)) then
    size := 4
  else
    size := rlen;
  in_reg := false;
  if s.asnop <> 0 then
    lim := 9
  else if size >= 4 then
    lim := 1
  else
    lim := 65535;
  if s.right^.kind in [77..87, 101, 200] then begin
    skip := false;
    if (ord(s.right^.xc[11]) = 255) and (size = 1) then
      skip := not (4 in getphase(s.left));
    if not skip and not ((size <= 2) and (s.asnop = 0)) then begin
      v := s.right^.xl[2];
      if ((v >= -128) and (v < 0)) or ((v >= lim) and (v <= 127)) then
        in_reg := true
      else if (v < 0) or (v >= lim) then
        in_reg := register_tickle(s.right, in_reg);
    end;
  end
  else
    in_reg := register_tickle(s.right, in_reg);
  if in_reg then
    load_operand(s.right, size, opb)
  else if s.asnop = 0 then begin
    if (size = 4) and (peek(s.right, 5) <> 31) then
      address(s.right, 5, opb)
    else
      address(s.right, size, opb);
  end
  else if s.right^.kind in [77..87, 101, 200] then
    address(s.right, size, opb)
  else
    load_operand(s.right, size, opb);
  address(s.left, 0, opa);
  if (s.asnop = 0) and zero_check(s.right) and (opa.f1 = 1) and
      (opa.f2 >= 8) and (opa.f2 <= 15) then
    emit(2, size, opa, opa, 0)
  else if s.asnop = 0 then
    fault_free_assign(size, opa, opb)
  else
    emit(asn_ops[s.asnop], size, opa, opb, 0);
  invalidate(opa, s.desc.size);
  if (opb.f1 = 1) and ((s.asnop = 11) or (s.asnop = 0)) and
      not (1 in getphase(s.left)) then
    if chk_assign(cg_addr_regs[opb.f2].obj, cg_addr_regs[opb.f2].size) <>
        opb.f2 then
      if chk_assign(cg_addr_regs[opb.f2].obj2,
          cg_addr_regs[opb.f2].size) <> opb.f2 then begin
        if (opb.f2 in [0..7]) and (size = 5) then
          size := 4
        else if opb.f2 in [8..15] then
          size := 5;
        if opb.f2 in [0..12] then begin
          cg_addr_regs[opb.f2].obj2 := cspe(s.left);
          cg_addr_regs[opb.f2].obj := cspe(s.right);
          cg_addr_regs[opb.f2].size := size;
          cg_addr_regs[opb.f2].w8 := cg_addr_2ba;
        end;
      end;
  release(opb);

done:
  release(opa);
end;
