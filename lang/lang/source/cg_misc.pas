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
    0x0FAEF0  --------  cg_misc_$strcmp_can_use_longs
    A5 0x356310 (cc.m68k): +0 the label templabel gives while
    at_backend_506 is false (cg_top's f_initialize sets it).

  Every routine loads A5 (global).

  TODO(pascal) cg_misc is started: 12 of its 24 routines are written
  (show_state, show_label, templabel, reverse_cc, unaligned,
  zero_check, s_extend, agg_len_loop_start, agg_loop_start,
  agg_loop_end, genmask, cg_misc_$strcmp_can_use_longs); shift
  (0x0FA050), agg_opr (0x0FA27E), fill (0x0FA410), cbuiltin_strcpy
  (0x0FA580), cbuiltin_strncpy (0x0FA67C), cbuiltin_strcat (0x0FA95A),
  cbuiltin_strncat (0x0FAAFC), cbuiltin_strlen (0x0FAD8A),
  cg_misc_$strcmp_by_longs
  (0x0FAFCC, with compare_two_bytes 0x0FAF2A nested), cbuiltin_strcmp
  (0x0FB42C) and cbuiltin_strncmp (0x0FB7D6) are not.

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
  cg_misc_$strcmp_can_use_longs;

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
