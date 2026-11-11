{ cg_misc - the m68k code generator's helpers and C builtins: the state
  dumps (show_state, show_label), temporary labels, the reversed
  condition, alignment and zero tests, sign extension, the aggregate
  loops, masks and shifts, filling, and the inline string builtins
  (strcpy, strncpy, strcat, strncat, strlen, strcmp, strncmp).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0F973C  --------  show_state
    0x0F99EC  --------  show_label
    0x0F9BC8  --------  templabel
    0x0F9BEE  --------  reverse_cc
    0x0F9C16  --------  unaligned
    0x0F9CD0  --------  zero_check
    0x0F9D24  --------  s_extend
    0x0F9DB8  --------  agg_len_loop_start
    0x0F9EB2  --------  agg_loop_start
    0x0F9F4A  --------  agg_loop_end
    0x0FA012  --------  genmask
    0x0FA050  --------  shift
    0x0FA27E  --------  agg_opr
    0x0FA410  --------  fill
    0x0FA580  --------  cbuiltin_strcpy
    0x0FA67C  --------  cbuiltin_strncpy
    0x0FA95A  --------  cbuiltin_strcat
    0x0FAAFC  --------  cbuiltin_strncat
    0x0FAD8A  --------  cbuiltin_strlen
    0x0FAEF0  --------  cg_misc_$strcmp_can_use_longs
    0x0FAF2A  --------  compare_two_bytes
    0x0FAFCC  --------  cg_misc_$strcmp_by_longs
    0x0FB42C  --------  cbuiltin_strcmp
    0x0FB7D6  --------  cbuiltin_strncmp
    A5 0x356310 (cc.m68k): +0 the label templabel gives while
    at_backend_506 is false (cg_top's f_initialize sets it).

  Every routine loads A5 (global) but cg_misc_$strcmp_by_longs
  (internal) and its nested compare_two_bytes.

  The code of the string builtins is built with emit's generic
  instructions as numbers (docs/questions.md 77): 0 move, 1 add, 2
  subtract, 3 and, 12 not, 13 a shift (x its kind), 18 compare or test
  (against cg_zero_ads), 20 a conditional branch (x the 68000's condition
  code: 6 NE, 7 EQ, 15 LE), 21 a branch, 29 swap, 30 ext, 32 a label;
  the operands' modes (f1) 1 register, 2 d(An), 8 (An)+, 9 -(An)
  (docs/questions.md 74).

  Not known from the original: the names of the module's variable, the
  locals and the parameters. }
module cg_misc;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/cg.ins.pas';

type
  { A label's saved register state (show_label: a label node's +64):
    two bytes, then the registers' records as cg_addr's table. }
  misc_state_ptr_t = ^misc_state_t;
  misc_state_t = record
    unused_0: integer32;                { +0 }
    b4: char;                           { +4 }
    b5: char;                           { +5 }
    b6: char;                           { +6 }
    b7: char;                           { +7 }
    regs: array [0..15] of cg_reg_t;    { +8 }
  end;

define
  cg_misc_label,
  show_state, show_label, templabel, reverse_cc, unaligned, zero_check,
  s_extend, agg_len_loop_start, agg_loop_start, agg_loop_end, genmask,
  shift, agg_opr, fill, cbuiltin_strcpy, cbuiltin_strncpy,
  cbuiltin_strcat, cbuiltin_strncat, cbuiltin_strlen,
  cg_misc_$strcmp_can_use_longs, cbuiltin_strcmp, cbuiltin_strncmp;

{ show_state - the pass, the line (and its file when not the main one),
  then each data and address register holding an object: its name,
  `(LOCKED)', its size (WORD, LONG, BYTE), the object and a 138's use
  count.

  0x0F973C, 0x24E bytes: the registers' records at 0x3550D8 and their
  locks at 0x355098 (cg_addr's, absolute) stepped together (`dbf' of
  16); the size's name a 16-byte constant copied to a local. }

procedure show_state;
var
  line: prtsub_$line_t;
  region: integer32;
  lno: integer32;
  r: integer;
  k: integer;
  name: array [1..16] of char;
begin
  line.length := 0;
  prtcats(line, 'PASS = ', 7);
  prtint(line, cg_top_142, 2, false);
  prtcats(line, '  LINE = ', 9);
  spos_$decode_source_position(cg_line, region, lno);
  prtint(line, lno, 5, false);
  if not spos_$is_main_source_file(region) then begin
    prtcats(line, ' OF ', 4);
    prtobj(line, spos_$region_user_name(region));
  end;
  listln(line);
  line.length := 0;
  prtcats(line, 'REGISTER STATE', 14);
  listln(line);
  for r := 0 to 15 do
    if cg_addr_regs[r].obj <> nil then begin
      line.length := 0;
      k := r;
      if r < 8 then
        prtcatc(line, 'D')
      else begin
        prtcatc(line, 'A');
        k := k - 8;
      end;
      prtint(line, k, 1, false);
      prtcatc(line, '=');
      if cg_addr_locks[r] <> 0 then
        prtcats(line, ' (LOCKED)', 9);
      if cg_addr_regs[r].size = 2 then
        name := ' (WORD)         '
      else if cg_addr_regs[r].size > 2 then
        name := ' (LONG)         '
      else
        name := ' (BYTE)         ';
      prtcats(line, name, 8);
      prtobj(line, cg_addr_regs[r].obj);
      if cg_addr_regs[r].obj^.kind = 138 then begin
        prtcats(line, ' UC=', 4);
        prtint(line, cg_addr_regs[r].obj^.xw[8], 3, false);
      end;
      listln(line);
    end;
end;

{ show_label - label lab, the two bytes of its saved state (+64), and
  the state's registers: each object with its +14 and +12 words, then
  each second object with its +8 word.

  0x0F99EC, 0x1DC bytes: two counted loops of 16 (`dbf'), the records
  at (0x8 + 16k,A2). }

procedure show_label(
    lab: il_$node_ptr_t); options(val_param);
var
  line: prtsub_$line_t;
  s: misc_state_ptr_t;
  k: integer;
begin
  line.length := 0;
  prtobj(line, lab);
  if lab^.xp[16] <> nil then begin
    prtcatc(line, ',');
    prtint(line, ord(misc_state_ptr_t(lab^.xp[16])^.b4), 2, false);
    prtcatc(line, ',');
    prtint(line, ord(misc_state_ptr_t(lab^.xp[16])^.b6), 2, false);
  end;
  listln(line);
  s := misc_state_ptr_t(lab^.xp[16]);
  if s <> nil then begin
    line.length := 0;
    for k := 0 to 15 do begin
      if s^.regs[k].obj <> nil then begin
        prtobj(line, s^.regs[k].obj);
        prtcatc(line, '(');
        prtint(line, s^.regs[k].w14, 2, false);
        prtcatc(line, ',');
        prtint(line, s^.regs[k].w12, 5, false);
        prtcatc(line, ')');
      end;
      prtcatc(line, ',');
    end;
    listln(line);
    line.length := 0;
    for k := 0 to 15 do begin
      if s^.regs[k].obj2 <> nil then begin
        prtobj(line, s^.regs[k].obj2);
        prtcatc(line, '(');
        prtint(line, s^.regs[k].w8, 5, false);
        prtcatc(line, ')');
      end;
      prtcatc(line, ',');
    end;
    listln(line);
  end;
end;

{ templabel - a new temporary label (create_temp_label) while
  at_backend_506, else the module's label.

  0x0F9BC8, 0x26 bytes: the result in A0 from the call or A5@. }

function templabel;
begin
  if at_backend_506 then
    templabel := create_temp_label
  else
    templabel := cg_misc_label;
end;

{ reverse_cc - the opposite condition of cc (the conditions in pairs:
  odd minus 1, even plus 1).

  0x0F9BEE, 0x28 bytes. }

function reverse_cc(
    cc: integer): integer; options(val_param);
begin
  if odd(cc) then
    reverse_cc := cc - 1
  else
    reverse_cc := cc + 1;
end;

{ unaligned - n's storage may be at an odd address (never with cpu 3,
  the 68020): its descriptor's displacement odd or inexact, or its base
  a 109 of storage class 3 or 5, a chain of 118s not ending in a 132, a
  110 of +11 class 5 or +15 bit 0, or any other kind but 92 and 111.

  0x0F9C16, 0xBA bytes: `btst' of the class in 40; the 118 chain walked
  through the descriptor's base. }

function unaligned(
    n: il_$node_ptr_t): boolean; options(val_param);
var
  d: alias_$desc_t;
  r: boolean;
begin
  if 3 in cargs_$options.cpu then
    unaligned := false
  else begin
    alias_$basic_alias_desc(n, d);
    r := odd(d.disp) or d.inexact;
    if d.base <> nil then
      case d.base^.kind of
        109: begin
          if (d.base^.xw[36] = 3) or (d.base^.xw[36] = 5) then
            r := true;
        end;
        118: begin
          repeat
            d.base := d.base^.xp[7];
          until d.base^.kind <> 118;
          if d.base^.kind <> 132 then
            r := true;
        end;
        92, 111: ;
        110: begin
          if rshft(ord(d.base^.xc[11]) & 16#F0, 4) = 5 then
            r := true
          else if odd(ord(d.base^.xc[15])) then
            r := true;
        end;
        otherwise r := true;
      end;
    unaligned := r;
  end;
end;

{ zero_check - n is the integer constant 0.

  0x0F9CD0, 0x3A bytes: the set [77..87, 101, 200] at 0x0F9D0A. }

function zero_check(
    n: il_$node_ptr_t): boolean; options(val_param);
begin
  if n^.kind in [77..87, 101, 200] then
    zero_check := n^.xl[2] = 0
  else
    zero_check := false;
end;

{ s_extend - operand a sign-extended from size from to size too: `extb.l'
  (61) from a byte to a long on the 68020, else `ext.w' (30, size 2)
  from a byte and `ext.l' (30, size 4) to a long.

  0x0F9D24, 0x94 bytes: the instruction and size pushed as one
  longword (docs/rev889-patterns.md 54); unsigned compare of the
  sizes. }

procedure s_extend;
begin
  if too > from then begin
    if (from = 1) and (too = 4) and (3 in cargs_$options.cpu) then
      emit(61, 4, a, cg_null_ads, 0)
    else begin
      if from = 1 then
        emit(30, 2, a, cg_null_ads, 0);
      if too = 4 then
        emit(30, 4, a, cg_null_ads, 0);
    end;
  end;
end;

{ agg_len_loop_start - the head of a loop over an aggregate whose length
  operand a addresses: the length (a word at a, as d(An) of 0) moved to
  a scratch register r, plus 1 (1), shifted left 2, and a new label's
  address (32) in lab.

  0x0F9DB8, 0xFA bytes: a copied to a local (a value parameter); its
  mode and y kept and put back around the move; get_register(nil, 2,
  r). }

procedure agg_len_loop_start;
var
  f1: integer;
  y: integer32;
begin
  get_register(nil, 2, r);
  f1 := a.f1;
  y := a.y;
  a.f1 := 2;
  a.y := 0;
  emit(0, 2, r, a, 0);
  a.f1 := f1;
  a.y := y;
  address(smcontk(81, 2), 0, lab);
  emit(1, 2, r, lab, 0);
  unlock(lab);
  shift(r, 2, 2, 2);
  address(templabel, 0, lab);
  emit(32, 5, lab, cg_null_ads, 0);
end;

{ agg_loop_start - the head of a loop of count iterations: the count
  (a word up to 65535, else a long) loaded into a modifiable register r
  (its contents forgotten), a new label's address (32) in lab.

  0x0F9EB2, 0x98 bytes: the size and the constant's node passed by
  address from locals. }

procedure agg_loop_start;
var
  size: integer;
  k: il_$node_ptr_t;
begin
  if count > 65535 then
    size := 4
  else
    size := 2;
  k := smcontk(81, count);
  load_modifiable(k, size, r);
  kill_register(r.f2);
  address(templabel, 0, lab);
  emit(32, 5, lab, cg_null_ads, 0);
end;

{ agg_loop_end - the end of agg_loop_start's loop: `dbf' (28, x 1) up to
  65535, else a subtraction of 1 (2) and the branch back (20, x 10);
  the registers released.

  0x0F9F4A, 0xC8 bytes. }

procedure agg_loop_end;
var
  t: codegen_$uads_t;
begin
  if count <= 65535 then
    emit(28, 2, lab, r, 1)
  else begin
    address(smcontk(81, 1), 4, t);
    emit(2, 4, r, t, 0);
    emit(20, 5, lab, cg_null_ads, 10);
    release(t);
  end;
  release(lab);
  release(r);
end;

{ genmask - the bits lo + 1 .. n, from the most significant, set for
  those up to hi.

  0x0FA012, 0x3E bytes: `dbf' over n - lo; an unsigned compare with
  hi. }

function genmask;
var
  m: integer32;
  i: integer;
begin
  m := 0;
  for i := lo + 1 to n do begin
    m := lshft(m, 1);
    if i <= hi then
      m := m + 1;
  end;
  genmask := m;
end;

{ shift - operand a of size size shifted by count (how: 0 arithmetic
  right, 2 logical right, 1 and 3 left; emit's x for the shift, 13).
  One bit of a non-register at size 2 as a shift of 1; else the count
  taken modulo 64: from 16 a swap (29) with ext.l (30) or the low word
  cleared (and, 3, with the immediate 0) and the rest shifted again;
  over 8 by the count in a register when anyconst gives one (mode 1),
  else a shift of 8 first; 1 left as an add to itself (1).

  0x0FA050, 0x22E bytes: anyconst's size 1 is the D0 that holds 1 from
  the first test (docs/rev889-patterns.md 24); the case on how a jump
  table of 4 (0, 1, 3 the swap first); the call of itself for count -
  16. }

procedure shift;
var
  t: codegen_$uads_t;
begin
  if count <> 0 then begin
    if (count = 1) and (a.f1 <> 1) and (size = 2) then begin
      address(smcontk(81, 1), 0, t);
      emit(13, size, a, t, how);
      unlock(t);
    end
    else begin
      count := count & 63;
      if count > 8 then begin
        anyconst(count, 1, t);
        unlock(t);
        if t.f1 = 1 then begin
          emit(13, size, a, t, how);
          return;
        end;
      end;
      if count >= 16 then begin
        case how of
          0, 1, 3: begin
            emit(29, 2, a, cg_null_ads, 0);
            if how = 0 then
              emit(30, 4, a, cg_null_ads, 0)
            else
              emit(3, 2, a, cg_zero_ads, 0);
          end;
          2: begin
            emit(3, 2, a, cg_zero_ads, 0);
            emit(29, 2, a, cg_null_ads, 0);
          end;
          otherwise ;
        end;
        shift(a, size, count - 16, how);
      end
      else begin
        if count > 8 then begin
          address(smcontk(81, 8), 0, t);
          emit(13, size, a, t, how);
          count := count - 8;
        end;
        if (count = 1) and ((how = 3) or (how = 1)) then
          emit(1, size, a, a, 0)
        else if count <> 0 then begin
          address(smcontk(81, count), 0, t);
          emit(13, size, a, t, how);
        end;
      end;
    end;
  end;
end;

{ agg_opr - the operand a of aggregate node n for a block operation:
  for a string (92) or a set (156, 212) constant whose bytes are all
  alike, or a double (89) of 0.0, the immediate 0 (cg_zero_ads) or the
  byte four times as a longword constant in a register; a set of 1, 2
  or 4 bytes its own operand; anything else its address loaded into an
  address register (when load_address gives another kind, unlocked and
  addressed again, size 5) and used as (An)+ (8).

  0x0FA27E, 0x192 bytes: the byte (or the set's first word, whose two
  bytes must agree) kept in a frame longword (-4) and replicated into
  its other bytes; the words counted as len div 2 plus the odd byte
  (`lsr.w', `btst #0'); the double tested with fpp_$ (0x0074 0xFF34,
  then `bne'; docs/rev889-patterns.md 19); cg_zero_ads copied by one
  shared tail (five `move.l'); the test for an address register as
  two unsigned compares.  Not known from the original: whether the two shared ends
  were labels (they follow the case, in this order). }

procedure agg_opr;
label
  replicate, general;
var
  v: record case integer of
    1: (c: array [0..3] of char);
    2: (w: integer);
    3: (l: integer32);
  end;
  i: integer;
  k: integer;
begin
  case n^.kind of
    92: begin
      v.c[0] := n^.str_chars[1];
      for i := 2 to n^.str_len do
        if n^.str_chars[i] <> v.c[0] then
          goto general;
      if v.c[0] <> chr(0) then
        goto replicate;
      a := cg_zero_ads;
    end;
    156, 212: begin
      if (n^.set_len = 4) or (n^.set_len = 2) or (n^.set_len = 1) then
        address(n, n^.set_len, a)
      else begin
        v.w := n^.set_words[1];
        if v.c[0] <> v.c[1] then
          goto general;
        k := n^.set_len div 2;
        if odd(n^.set_len) then
          k := k + 1;
        for i := 2 to k do
          if n^.set_words[i] <> v.w then
            goto general;
        if v.w <> 0 then
          goto replicate;
        a := cg_zero_ads;
      end;
    end;
    89: begin
      if n^.real_value <> 0.0 then
        goto general;
      a := cg_zero_ads;
    end;
    otherwise
      goto general;
  end;
  return;
replicate:
  v.c[1] := v.c[0];
  v.c[2] := v.c[0];
  v.c[3] := v.c[0];
  load_operand(smcontk(81, v.l), 4, a);
  return;
general:
  load_address(n, a);
  kill_register(a.f2);
  if not (a.f2 in [8..15]) then begin
    unlock(a);
    address(n, 5, a);
  end;
  a.f1 := 8;
end;

{ fill - len bytes at node n's address set to value (cg_addr_2b6 set to
  8 meanwhile): up to 8 bytes as longword moves (0, size 4) to
  displacements 0, 4 and a word move for the rest; more as (An)+ moves
  through n's address loaded into a register, in agg_loop_start's loop
  above 16 bytes, then a word move when len mod 4 is 2.

  0x0FA410, 0x170 bytes: the comparisons of len unsigned (`bhi', `bcc',
  `bcs', `bls'); the longwords counted len div 4 - 1 (`lsr.l #2') in a
  longword, the short form a while loop on its sign (`bpl'); the word
  move shared by the two forms (docs/rev889-patterns.md 23). }

procedure fill;
var
  lab: codegen_$uads_t;                 { -24 }
  r: codegen_$uads_t;                   { -48 }
  v: codegen_$uads_t;                   { -72 }
  d: codegen_$uads_t;                   { -96 }
  k: 0..2147483647;
  c: integer32;
  save: integer;
begin
  save := cg_addr_2b6;
  cg_addr_2b6 := 8;
  address(smcontk(81, value), 4, v);
  if len <= 8 then begin
    address(n, 0, d);
    while len >= 4 do begin
      emit(0, 4, d, v, 0);
      d.y := d.y + 4;
      len := len - 4;
    end;
    if len >= 2 then
      emit(0, 2, d, v, 0);
  end
  else begin
    load_address(n, d);
    kill_register(d.f2);
    d.f1 := 8;
    k := len;
    c := k div 4 - 1;
    if len > 16 then begin
      agg_loop_start(c, r, lab);
      emit(0, 4, d, v, 0);
      agg_loop_end(c, r, lab);
    end
    else
      while c >= 0 do begin
        emit(0, 4, d, v, 0);
        c := c - 1;
      end;
    if (k & 3) = 2 then
      emit(0, 2, d, v, 0);
  end;
  unlock(v);
  release(d);
  cg_addr_2b6 := save;
end;

{ cbuiltin_strcpy - strcpy(+60, +64) of tree n inline (nothing when the
  two operands are the same node): both addresses in modifiable
  registers, a label (32), `move.b (As)+,(Ad)+' (0, size 1) and the
  branch back while not zero (20, x 6); the registers unlocked and
  forgotten.

  0x0FA580, 0xFA bytes: load_modifiable's size 5 a word after the
  routine (0x0FA67A), passed by address. }

procedure cbuiltin_strcpy;
var
  dst: codegen_$uads_t;                 { -72 }
  src: codegen_$uads_t;                 { -48 }
  lab: codegen_$uads_t;                 { -24 }
begin
  if n^.xp[16] <> n^.xp[15] then begin
    load_modifiable(n^.xp[16], 5, src);
    load_modifiable(n^.xp[15], 5, dst);
    address(templabel, 5, lab);
    emit(32, 5, lab, cg_null_ads, 0);
    src.f1 := 8;
    dst.f1 := 8;
    emit(0, 1, dst, src, 0);
    emit(20, 5, lab, cg_null_ads, 6);
    unlock(src);
    unlock(dst);
    kill_register(src.f2);
    kill_register(dst.f2);
  end;
end;

{ cbuiltin_strncpy - strncpy(+60, +64, +68) of tree n inline: the count
  in a modifiable register tested (18 with the immediate 0) and nothing
  done when not positive (20, x 15); the loop copying bytes (`move.b
  (As)+,(Ad)+', leaving for the padding when one is zero, x 7) and
  counting down (2, by the constant 1) while not zero (x 6); then the
  padding loop storing zeros while the count lasts; the registers
  unlocked, the count's released and all three forgotten.

  0x0FA67C, 0x2DC bytes: three labels first; load_modifiable's sizes 5
  and 4 words after the routines (0x0FA67A, 0x0FA958), passed by
  address; the unconditional branches 21. }

procedure cbuiltin_strncpy;
var
  done: codegen_$uads_t;                { -24 }
  pad: codegen_$uads_t;                 { -48 }
  loop: codegen_$uads_t;                { -72 }
  src: codegen_$uads_t;                 { -96 }
  one: codegen_$uads_t;                 { -120 }
  dst: codegen_$uads_t;                 { -144 }
  count: codegen_$uads_t;               { -168 }
begin
  address(templabel, 0, loop);
  address(templabel, 0, pad);
  address(templabel, 0, done);
  load_modifiable(n^.xp[16], 5, src);
  load_modifiable(n^.xp[15], 5, dst);
  load_modifiable(n^.xp[17], 4, count);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, done, cg_null_ads, 15);
  emit(32, 5, loop, cg_null_ads, 0);
  src.f1 := 8;
  dst.f1 := 8;
  emit(0, 1, dst, src, 0);
  emit(20, 5, pad, cg_null_ads, 7);
  anyconst(1, 4, one);
  emit(2, 4, count, one, 0);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, loop, cg_null_ads, 6);
  emit(21, 5, done, cg_null_ads, 0);
  emit(32, 5, pad, cg_null_ads, 0);
  emit(2, 4, count, one, 0);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, done, cg_null_ads, 7);
  dst.f1 := 8;
  emit(0, 1, dst, cg_zero_ads, 0);
  emit(21, 5, pad, cg_null_ads, 0);
  emit(32, 5, done, cg_null_ads, 0);
  unlock(src);
  unlock(dst);
  release(count);
  kill_register(count.f2);
  kill_register(src.f2);
  kill_register(dst.f2);
  unlock(one);
end;

{ cbuiltin_strcat - strcat(+60, +64) of tree n inline: the destination
  stepped past its terminator (`tst.b (Ad)+', 18 with the immediate 0,
  branching back while not zero, x 6) and backed up by one (2, its
  register as mode 1), then strcpy's loop.

  0x0FA95A, 0x1A2 bytes: the branches of size 0. }

procedure cbuiltin_strcat;
var
  copy: codegen_$uads_t;                { -24 }
  scan: codegen_$uads_t;                { -48 }
  src: codegen_$uads_t;                 { -72 }
  one: codegen_$uads_t;                 { -96 }
  dst: codegen_$uads_t;                 { -120 }
begin
  address(templabel, 0, scan);
  address(templabel, 0, copy);
  load_modifiable(n^.xp[15], 5, dst);
  load_modifiable(n^.xp[16], 5, src);
  emit(32, 5, scan, cg_null_ads, 0);
  dst.f1 := 8;
  emit(18, 1, dst, cg_zero_ads, 0);
  emit(20, 0, scan, cg_null_ads, 6);
  anyconst(1, 4, one);
  dst.f1 := 1;
  emit(2, 4, dst, one, 0);
  emit(32, 5, copy, cg_null_ads, 0);
  src.f1 := 8;
  dst.f1 := 8;
  emit(0, 1, dst, src, 0);
  emit(20, 0, copy, cg_null_ads, 6);
  unlock(src);
  unlock(dst);
  kill_register(src.f2);
  kill_register(dst.f2);
  unlock(one);
end;

{ cbuiltin_strncat - strncat(+60, +64, +68) of tree n inline: strcat's
  scan for the terminator, then, when the count is positive, the copy
  of at most count bytes (leaving at a zero byte, x 7) and a zero
  stored after them.

  0x0FAAFC, 0x28E bytes: the count loaded after the scan. }

procedure cbuiltin_strncat;
var
  done: codegen_$uads_t;                { -24 }
  copy: codegen_$uads_t;                { -48 }
  scan: codegen_$uads_t;                { -72 }
  src: codegen_$uads_t;                 { -96 }
  one: codegen_$uads_t;                 { -120 }
  dst: codegen_$uads_t;                 { -144 }
  count: codegen_$uads_t;               { -168 }
begin
  address(templabel, 0, scan);
  address(templabel, 0, copy);
  address(templabel, 0, done);
  load_modifiable(n^.xp[15], 5, dst);
  load_modifiable(n^.xp[16], 5, src);
  emit(32, 5, scan, cg_null_ads, 0);
  dst.f1 := 8;
  emit(18, 1, dst, cg_zero_ads, 0);
  emit(20, 0, scan, cg_null_ads, 6);
  anyconst(1, 4, one);
  dst.f1 := 1;
  emit(2, 4, dst, one, 0);
  load_modifiable(n^.xp[17], 4, count);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, done, cg_null_ads, 15);
  emit(32, 5, copy, cg_null_ads, 0);
  src.f1 := 8;
  dst.f1 := 8;
  emit(0, 1, dst, src, 0);
  emit(20, 0, done, cg_null_ads, 7);
  emit(2, 4, count, one, 0);
  emit(20, 5, copy, cg_null_ads, 6);
  emit(0, 1, dst, cg_zero_ads, 0);
  emit(32, 5, done, cg_null_ads, 0);
  unlock(src);
  unlock(dst);
  unlock(count);
  kill_register(src.f2);
  kill_register(dst.f2);
  kill_register(count.f2);
  unlock(one);
end;

{ cbuiltin_strlen - strlen(opnd[1]) of tree n inline: a register for n
  set to -1, then counted up (1) while `tst.b (As)+' finds no zero
  (x 6); its value n's (setresult in n's class).

  0x0FAD8A, 0x166 bytes. }

procedure cbuiltin_strlen;
var
  lab: codegen_$uads_t;                 { -24 }
  s: codegen_$uads_t;                   { -48 }
  one: codegen_$uads_t;                 { -72 }
  minus_one: codegen_$uads_t;           { -96 }
  r: codegen_$uads_t;                   { -120 }
begin
  address(templabel, 0, lab);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[1], 5, s);
  get_register(n, 4, r);
  anyconst(-1, 4, minus_one);
  emit(0, 4, r, minus_one, 0);
  emit(32, 5, lab, cg_null_ads, 0);
  anyconst(1, 4, one);
  emit(1, 4, r, one, 0);
  s.f1 := 8;
  emit(18, 1, s, cg_zero_ads, 0);
  emit(20, 5, lab, cg_null_ads, 6);
  unlock(s);
  unlock(r);
  kill_register(s.f2);
  unlock(one);
  unlock(minus_one);
  setresult(r.f2, n, cg_tree_ptr_t(n)^.desc.rlen);
end;

{ cg_misc_$strcmp_can_use_longs - neither of strcmp tree n's operands
  may be at an odd address.

  0x0FAEF0, 0x3A bytes: the second test's result complemented
  (`not.b'). }

function cg_misc_$strcmp_can_use_longs;
begin
  if unaligned(cg_tree_ptr_t(n)^.opnd[1]) then
    cg_misc_$strcmp_can_use_longs := false
  else
    cg_misc_$strcmp_can_use_longs := not unaligned(cg_tree_ptr_t(n)^.opnd[2]);
end;

{ cg_misc_$strcmp_by_longs - strcmp(opnd[1], opnd[2]) of tree n by
  longwords: a longword of each string compared (`move.l (A1)+,a',
  `cmp.l (A2)+,a'); while they agree and the first holds no zero byte
  ((x - 0x01010101) and not x and 0x80808080, with not 12 and and 3)
  the loop goes on, a zero byte giving 0; at a difference the four
  bytes before the strings' registers compared in turn
  (compare_two_bytes), the result their difference (a longword
  subtraction, or of bytes sign-extended when the tree's desc.w6 is
  set) in a register for n.

  0x0FAFCC, 0x460 bytes: no A5 load (internal); two scratch registers
  (get_register(nil, 4)) and a third for the zero test; the operands'
  modes set to 2 (d(An)) for the bytes. }

procedure cg_misc_$strcmp_by_longs(
    n: il_$node_ptr_t); options(val_param); internal;
var
  zero: codegen_$uads_t;                { -24 }
  t: codegen_$uads_t;                   { -48 }
  b: codegen_$uads_t;                   { -72 }
  a: codegen_$uads_t;                   { -96 }
  ones: codegen_$uads_t;                { -120 }
  ne: codegen_$uads_t;                  { -144 }
  loop: codegen_$uads_t;                { -168 }
  done: codegen_$uads_t;                { -192 }
  bytes: codegen_$uads_t;               { -216 }
  highs: codegen_$uads_t;               { -240 }
  s2: codegen_$uads_t;                  { -264 }
  s1: codegen_$uads_t;                  { -288 }

  { compare_two_bytes - the bytes at k of the two strings moved to a
    and b (1), to ne when b's is zero (x 7) or when they differ (18,
    x 6).

    0x0FAF2A, 0xA2 bytes: the parent's frame from the dynamic link
    (`movea.l (A6),A2'; docs/rev889-patterns.md 25). }

  procedure compare_two_bytes(
      k: integer); options(val_param);
  begin
    s1.y := k;
    s2.y := k;
    emit(0, 1, a, s1, 0);
    emit(0, 1, b, s2, 0);
    emit(20, 5, ne, cg_null_ads, 7);
    emit(18, 1, a, b, 0);
    emit(20, 5, ne, cg_null_ads, 6);
  end;

begin
  address(templabel, 0, loop);
  address(templabel, 0, bytes);
  address(templabel, 0, ne);
  address(templabel, 0, done);
  get_register(nil, 4, a);
  get_register(nil, 4, b);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[1], 5, s1);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[2], 5, s2);
  anyconst(16#01010101, 4, ones);
  emit(0, 4, b, ones, 0);
  emit(32, 5, loop, cg_null_ads, 0);
  s1.f1 := 8;
  s2.f1 := 8;
  emit(0, 4, a, s1, 0);
  emit(18, 4, a, s2, 0);
  emit(20, 5, bytes, cg_null_ads, 6);
  get_register(nil, 4, t);
  emit(0, 4, t, a, 0);
  emit(2, 4, t, b, 0);
  emit(12, 4, a, cg_null_ads, 0);
  emit(3, 4, t, a, 0);
  anyconst(16#80808080, 4, highs);
  emit(3, 4, t, highs, 0);
  unlock(ones);
  unlock(highs);
  emit(20, 5, loop, cg_null_ads, 7);
  anyconst(0, 4, zero);
  emit(0, 4, a, zero, 0);
  unlock(zero);
  emit(21, 5, done, cg_null_ads, 0);
  emit(32, 5, bytes, cg_null_ads, 0);
  s1.f1 := 2;
  s2.f1 := 2;
  anyconst(0, 4, zero);
  emit(0, 4, a, zero, 0);
  emit(0, 4, b, zero, 0);
  unlock(zero);
  compare_two_bytes(-4);
  compare_two_bytes(-3);
  compare_two_bytes(-2);
  compare_two_bytes(-1);
  emit(32, 5, ne, cg_null_ads, 0);
  if cg_tree_ptr_t(n)^.desc.w6 = 0 then
    emit(2, 4, a, b, 0)
  else begin
    emit(2, 1, a, b, 0);
    emit(30, 2, a, cg_null_ads, 0);
    emit(30, 4, a, cg_null_ads, 0);
  end;
  emit(32, 5, done, cg_null_ads, 0);
  setresult(a.f2, n, 4);
  unlock(s1);
  unlock(s2);
  unlock(t);
  unlock(a);
  unlock(b);
  kill_register(s1.f2);
  kill_register(s2.f2);
  kill_register(b.f2);
  kill_register(t.f2);
end;

{ cbuiltin_strcmp - strcmp(opnd[1], opnd[2]) of tree n inline: by
  longwords when neither string may be unaligned
  (cg_misc_$strcmp_can_use_longs), else a byte loop: equal pointers
  give 0 (x 7); `cmpm.b' (18, size 1, both (An)+) leaving at a
  difference (x 6), going on while the byte (at -1 of the second, mode
  2) is not zero; the result 0, or the bytes before the registers
  (mode 9, -(An)) subtracted: zero-extended into two registers when the
  tree's desc.w6 is 0, else as bytes sign-extended (30).

  0x0FB42C, 0x3AA bytes: the second string's displacement set to -1 and
  back to 0 around its test. }

procedure cbuiltin_strcmp;
var
  done: codegen_$uads_t;                { -24 }
  ne: codegen_$uads_t;                  { -48 }
  eq: codegen_$uads_t;                  { -72 }
  loop: codegen_$uads_t;                { -96 }
  r2: codegen_$uads_t;                  { -120 }
  r: codegen_$uads_t;                   { -144 }
  s2: codegen_$uads_t;                  { -168 }
  s1: codegen_$uads_t;                  { -192 }
begin
  if cg_misc_$strcmp_can_use_longs(n) then
    cg_misc_$strcmp_by_longs(n)
  else begin
    address(templabel, 0, loop);
    address(templabel, 0, eq);
    address(templabel, 0, ne);
    address(templabel, 0, done);
    load_modifiable(cg_tree_ptr_t(n)^.opnd[1], 5, s1);
    load_modifiable(cg_tree_ptr_t(n)^.opnd[2], 5, s2);
    emit(18, 4, s2, s1, 0);
    emit(20, 5, eq, cg_null_ads, 7);
    get_register(nil, 4, r);
    emit(32, 5, loop, cg_null_ads, 0);
    s1.f1 := 8;
    s2.f1 := 8;
    emit(18, 1, s2, s1, 0);
    emit(20, 5, ne, cg_null_ads, 6);
    s2.f1 := 2;
    s2.y := -1;
    emit(18, 1, s2, cg_zero_ads, 0);
    emit(20, 5, loop, cg_null_ads, 6);
    s2.y := 0;
    emit(32, 5, eq, cg_null_ads, 0);
    emit(0, 4, r, cg_zero_ads, 0);
    emit(21, 5, done, cg_null_ads, 0);
    emit(32, 5, ne, cg_null_ads, 0);
    s1.f1 := 9;
    if cg_tree_ptr_t(n)^.desc.w6 = 0 then begin
      emit(0, 4, r, cg_zero_ads, 0);
      emit(0, 1, r, s1, 0);
      get_register(nil, 4, r2);
      s2.f1 := 9;
      emit(0, 4, r2, cg_zero_ads, 0);
      emit(0, 1, r2, s2, 0);
      emit(2, 4, r, r2, 0);
      unlock(r2);
    end
    else begin
      emit(0, 1, r, s1, 0);
      s2.f1 := 9;
      emit(2, 1, r, s2, 0);
      emit(30, 2, r, cg_null_ads, 0);
      emit(30, 4, r, cg_null_ads, 0);
    end;
    unlock(r);
    emit(32, 5, done, cg_null_ads, 0);
    setresult(r.f2, n, 4);
    unlock(s1);
    unlock(s2);
    kill_register(s1.f2);
    kill_register(s2.f2);
  end;
end;

{ cbuiltin_strncmp - strncmp(opnd[1], opnd[2], opnd[3]) of tree n
  inline: strcmp's byte loop, with a count in a modifiable register
  (equal when not positive, x 15) counted down (2) at each equal byte
  that is not zero; the bytes subtracted as bytes sign-extended when
  the tree's desc.w6 is 1, else zero-extended into two registers.

  0x0FB7D6, 0x476 bytes: load_modifiable's size 4 the word after
  cbuiltin_strcat (0x0FA958). }

procedure cbuiltin_strncmp;
var
  done: codegen_$uads_t;                { -24 }
  ne: codegen_$uads_t;                  { -48 }
  eq: codegen_$uads_t;                  { -72 }
  loop: codegen_$uads_t;                { -96 }
  r2: codegen_$uads_t;                  { -120 }
  r: codegen_$uads_t;                   { -144 }
  s2: codegen_$uads_t;                  { -168 }
  s1: codegen_$uads_t;                  { -192 }
  one: codegen_$uads_t;                 { -216 }
  count: codegen_$uads_t;               { -240 }
begin
  address(templabel, 0, loop);
  address(templabel, 0, eq);
  address(templabel, 0, ne);
  address(templabel, 0, done);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[1], 5, s1);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[2], 5, s2);
  emit(18, 4, s2, s1, 0);
  emit(20, 5, eq, cg_null_ads, 7);
  get_register(nil, 4, r);
  load_modifiable(cg_tree_ptr_t(n)^.opnd[3], 4, count);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, eq, cg_null_ads, 15);
  emit(32, 5, loop, cg_null_ads, 0);
  s1.f1 := 8;
  s2.f1 := 8;
  emit(18, 1, s2, s1, 0);
  emit(20, 5, ne, cg_null_ads, 6);
  s2.f1 := 2;
  s2.y := -1;
  emit(18, 1, s2, cg_zero_ads, 0);
  emit(20, 5, eq, cg_null_ads, 7);
  s2.y := 0;
  anyconst(1, 4, one);
  emit(2, 4, count, one, 0);
  emit(18, 4, count, cg_zero_ads, 0);
  emit(20, 5, loop, cg_null_ads, 6);
  emit(32, 5, eq, cg_null_ads, 0);
  emit(0, 4, r, cg_zero_ads, 0);
  emit(21, 5, done, cg_null_ads, 0);
  emit(32, 5, ne, cg_null_ads, 0);
  s1.f1 := 9;
  if cg_tree_ptr_t(n)^.desc.w6 = 1 then begin
    emit(0, 1, r, s1, 0);
    s2.f1 := 9;
    emit(2, 1, r, s2, 0);
    emit(30, 2, r, cg_null_ads, 0);
    emit(30, 4, r, cg_null_ads, 0);
  end
  else begin
    emit(0, 4, r, cg_zero_ads, 0);
    emit(0, 1, r, s1, 0);
    get_register(nil, 4, r2);
    emit(0, 4, r2, cg_zero_ads, 0);
    s2.f1 := 9;
    emit(0, 1, r2, s2, 0);
    emit(2, 4, r, r2, 0);
    unlock(r2);
  end;
  unlock(r);
  emit(32, 5, done, cg_null_ads, 0);
  setresult(r.f2, n, 4);
  unlock(count);
  unlock(s1);
  unlock(s2);
  kill_register(count.f2);
  kill_register(s1.f2);
  kill_register(s2.f2);
  unlock(one);
end;
