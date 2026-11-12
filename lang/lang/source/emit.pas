{ emit - EMIT, the m68k code generator's instruction selection: a
  generic operation (op, size, two operand descriptors, an extra
  longword) becomes a code cell of the machine instruction whose
  restrictions on the operands, the size and the cpu the operands meet
  (opinfo's table of each operation's instructions), appended to the
  current routine's code; the cells' lengths (ilength) and the
  operands' extension words (adrlen); immediate operands narrowed or
  deferred to the constant pool (chk_imd, defer_constant); the line
  number cells.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0B6908  --------  chk_sz_restr
    0x0B69BC  --------  tst_imd
    0x0B6A1E  --------  chk_op_restr
    0x0B6D26  --------  defer_constant
    0x0B6E14  --------  chk_imd
    0x0B6F78  --------  adrlen
    0x0B7066  --------  sz_case
    0x0B70A0  --------  ilength
    0x0B738E  --------  fnl_slct
    0x0B78C0  --------  emit
    0x0B79DE  --------  emit_line_eop
    A5 0x2CE6A8 (cc.m68k): the module's data, 0x124 bytes (.rwdi sets
    none of it): +0x108..+0x11B the record outbin, jmp_br_resolve and
    unix_objmod reach absolutely (emit_108: +0x108 the code's size so
    far, +0x110 the location counter), +0x120 the line emit_line_eop
    gave last (the cgerr reports' line); +0x0..+0x107 and
    +0x11C..+0x11F are not addressed by any unit.

  adrlen, ilength, fnl_slct, emit and emit_line_eop load A5 (global;
  adrlen only ilength calls); the others are internal (tst_imd and
  sz_case leaves without a frame, docs/rev889-patterns.md 16).  The
  operations' instruction lists are opinfo.pas's data (the unit without
  code, cc.m68k 0x2CE8D8: a pointer per operation 0..77, nil for 32
  and 33; each list of 12-byte entries ending with the one whose flags
  have element 5), declared here as outbin.pas and instr_reorder.pas
  declare opinfo's other tables.

  Not known from the original: the names of the module's variables,
  the locals and the instruction entries' fields; the meaning of the
  restriction codes (chk_op_restr's 0..24, chk_sz_restr's 0..8,
  chk_imd's) and of the descriptors' fields (f1 the addressing mode: 1
  a register, 3 an immediate whose node is x, 13 a floating register,
  16 an FPA register; f2 the register; f6 the immediate's form).

  dpc gaps (docs/dpc-gaps.md): 7 (a real constant compared with 0.0), 8
  (`in' on the constant kind sets and the FPA operations), 24 (calls
  as operands of `and').
}
module emit;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/final.ins.pas';

type
  { An instruction of a generic operation (opinfo's lists, 12 bytes):
    the restriction codes of the destination and the source
    (chk_op_restr) and of the size (chk_sz_restr), the code cell's kind
    and the machine instruction (the cell's +48), and flags: elements
    0..4 the cpu features the instruction needs (fnl_slct's missing
    set), 5 the list's last entry. }
  em_entry_t = record
    dst: integer;                       { +0 }
    src: integer;                       { +2 }
    sz: integer;                        { +4 }
    kind: integer;                      { +6 }
    op: integer;                        { +8 }
    flags: set of 0..15;                { +10 }
  end;
  em_list_t = array [0..63] of em_entry_t;
  em_list_ptr_t = ^em_list_t;

  { A section (il_180^.xp[47], as cg_top.pas's top_sect_t): its code
    cells' last at +24. }
  em_sect_ptr_t = ^em_sect_t;
  em_sect_t = record
    unused_0: array [0..5] of integer32;  { +0 }
    tail: codegen_$cell_ptr_t;          { +24 }
  end;

var
  { The module's data (A5 0x2CE6A8). }
  emit_0: array [0..65] of integer32;   { +0x0: not addressed }
  emit_108: record                      { +0x108: outbin, jmp_br_resolve,
                                          unix_objmod }
    e108: integer32;                    { the code's size so far }
    e10c: integer32;
    e110: integer32;                    { the location counter }
    e114: integer32;
    e118: integer32;
  end;
  emit_11c: integer32;                  { +0x11C: not addressed }
  emit_line: integer;                   { +0x120: the line of the last
                                          line number cell }

  { opinfo.pas's data (cc.m68k 0x2CE8D8, absolute): each generic
    operation's instructions. }
  opinfo_insts: extern array [0..77] of em_list_ptr_t;

  { delay.pas's class_size (its +888, cc.m68k 0x169968): the bytes of
    each register class (docs/questions.md 115). }
  class_size: extern array [0..12] of integer;

define
  emit_108;

{ chk_sz_restr - whether size meets size restriction code: 0 a byte,
  word or long, 1 a byte, 2 a word or long, 3 a long, 4 a word, 5 any,
  6 a single, 7 a single or double, 8 the classes 1, 2, 4, 6, 7; false
  for another code.

  0x0B6908, 0xB4 bytes, link #-8: a jump table of 9; the result cleared
  first; 0's sizes compared in turn (1, 4, 2: `st'), 7's evaluated
  whole, 8's `btst' in 0xD6. }

function chk_sz_restr(
    size: integer;
    code: integer): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  case code of
    0:
      if size in [1, 4, 2] then
        r := true;
    1:
      r := size = 1;
    2:
      if size in [4, 2] then
        r := true;
    3:
      r := size = 4;
    4:
      r := size = 2;
    5:
      r := true;
    6:
      r := size = 6;
    7:
      r := (size = 7) or (size = 6);
    8:
      if size in [1, 2, 4, 6, 7] then
        r := true;
    otherwise
      ;
  end;
  chk_sz_restr := r;
end;

{ tst_imd - whether constant n can be an immediate operand: an
  integer, character or boolean constant (the set at 0x0B6A04: [77..88,
  101, 200]), a string of 1, 2 or 4 characters.

  0x0B69BC, 0x48 bytes: no frame (the parameter at (4,SP)); the
  lengths evaluated whole. }

function tst_imd(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n^.kind in [77..88, 101, 200] then
    tst_imd := true
  else if n^.kind = 92 then
    tst_imd := (n^.str_len = 1) or (n^.str_len = 2) or (n^.str_len = 4)
  else
    tst_imd := false;
end;

{ chk_op_restr - whether operand a meets restriction code: 0 a data
  register (or mode 14), 1 an address register, 21 a register, 2 an
  integer immediate of a byte, 19 a data register or a memory mode
  (2, 4, 8, 9, 12) without f5 bit 2, 3 a data register or the memory
  modes of 0x9B14, 4 the immediate 0 (an integer or real constant), 15
  the immediate 1, 5 not a floating register, 6 the immediate 1..8, 7
  the modes of 0x9B16, 24 an FPA register (16..23), 8 the modes of
  0x9B14, 9 and 16 an immediate (tst_imd), 10 and 12 neither an address
  register nor modes 0 and 13, 11 mode 8, 13 modes 5..7, 14 the modes of
  0x90FC, 17 mode 9, 18 mode 10, 20 a floating register, 22 not an
  immediate (tst_imd) nor a register or modes 8, 9, 23 modes 7 and 15.

  0x0B6A1E, 0x2EE bytes, link #-12: a jump table of 25; no result for
  another code (D0 keeps the code); the kinds the set at 0x0B6D0C
  ([77..87, 101, 200]); 4's real by `jsr fpp_$' (0x0074 0xFF34, then
  `seq'); the registers compared unsigned (`scs', `scc'); the modes'
  sets `btst' in a register (19 the data register test kept in a
  frame byte); the conditions evaluated whole. }

function chk_op_restr(
    in a: codegen_$uads_t;
    code: integer): boolean; options(val_param); internal;
var
  b: boolean;
  v: integer32;
  n: il_$node_ptr_t;
begin
  case code of
    0:
      chk_op_restr := ((a.f1 = 1) or (a.f1 = 14)) and (a.f2 < 8);
    1:
      chk_op_restr := (a.f1 = 1) and (a.f2 >= 8);
    21:
      chk_op_restr := a.f1 = 1;
    2:
      if a.f1 = 3 then begin
        n := il_$node_ptr_t(a.x);
        if n^.kind in [77..87, 101, 200] then begin
          v := n^.int_value;
          chk_op_restr := (v >= -128) and (v <= 127);
        end
        else
          chk_op_restr := false;
      end
      else
        chk_op_restr := false;
    19: begin
      b := (a.f1 = 1) and (a.f2 < 8);
      chk_op_restr := (b or (a.f1 in [2, 4, 8, 9, 12])) and
                      ((a.f5 & 4) = 0);
    end;
    3: begin
      b := (a.f1 = 1) and (a.f2 < 8);
      chk_op_restr := b or (a.f1 in [2, 4, 8, 9, 11, 12, 15]);
    end;
    4:
      if a.f1 = 3 then begin
        n := il_$node_ptr_t(a.x);
        if n^.kind in [77..87, 101, 200] then
          chk_op_restr := n^.int_value = 0
        else if (n^.kind = 88) or (n^.kind = 89) then
          chk_op_restr := n^.real_value = 0.0
        else
          chk_op_restr := false;
      end
      else
        chk_op_restr := false;
    15:
      if a.f1 = 3 then begin
        n := il_$node_ptr_t(a.x);
        if n^.kind in [77..87, 101, 200] then
          chk_op_restr := n^.int_value = 1
        else
          chk_op_restr := false;
      end
      else
        chk_op_restr := false;
    5:
      chk_op_restr := a.f1 <> 13;
    6:
      if a.f1 = 3 then begin
        n := il_$node_ptr_t(a.x);
        if n^.kind in [77..87, 101, 200] then begin
          v := n^.int_value;
          chk_op_restr := (v >= 1) and (v <= 8);
        end
        else
          chk_op_restr := false;
      end
      else
        chk_op_restr := false;
    7:
      chk_op_restr := a.f1 in [1, 2, 4, 8, 9, 11, 12, 15];
    24:
      chk_op_restr := (a.f1 = 16) and (a.f2 in [16..23]);
    8:
      chk_op_restr := a.f1 in [2, 4, 8, 9, 11, 12, 15];
    9, 16:
      if a.f1 = 3 then
        chk_op_restr := tst_imd(il_$node_ptr_t(a.x))
      else
        chk_op_restr := false;
    10, 12:
      chk_op_restr := ((a.f1 <> 1) or (a.f2 < 8)) and (a.f1 <> 0) and
                      (a.f1 <> 13);
    11:
      chk_op_restr := a.f1 = 8;
    13:
      chk_op_restr := a.f1 in [5..7];
    14:
      chk_op_restr := a.f1 in [2..7, 12, 15];
    17:
      chk_op_restr := a.f1 = 9;
    18:
      chk_op_restr := a.f1 = 10;
    20:
      chk_op_restr := a.f1 = 13;
    22:
      if a.f1 = 3 then
        chk_op_restr := not tst_imd(il_$node_ptr_t(a.x))
      else
        chk_op_restr := not (a.f1 in [1, 8, 9]);
    23:
      chk_op_restr := a.f1 in [7, 15];
    otherwise
      ;
  end;
end;

{ defer_constant - the constant pool's node (157, gspace'd: +16 the
  value, +20 the size, +4 the chain) for integer constant n of size
  bytes (1, 2, 4: il's three tables of 16 chains, by the value's low
  four bits), made when the value has none yet.

  0x0B6D26, 0xEE bytes, link #-24: the chains il_tab_80 (size 1),
  il_tab_0 (2) and il_tab_40 (4) addressed absolutely (0x169CF0,
  0x169C70, 0x169CB0); the value's low word read (+10); for another
  size the search starts from n itself (A0 left holding it); the
  result in D1, then A0. }

function defer_constant(
    n: il_$node_ptr_t;
    size: integer): il_$node_ptr_t; options(val_param); internal;
var
  h: integer;
  p: il_$node_ptr_t;
  q: il_$node_ptr_t;
begin
  h := n^.xw[5] & 15;
  p := n;
  case size of
    1:
      p := il_$node_ptr_t(il_tab_80[h]);
    2:
      p := il_$node_ptr_t(il_tab_0[h]);
    4:
      p := il_$node_ptr_t(il_tab_40[h]);
    otherwise
      ;
  end;
  while p <> nil do begin
    if p^.xl[4] = n^.int_value then begin
      defer_constant := p;
      return;
    end;
    p := p^.xp[1];
  end;
  q := gspace(22);
  q^.kind := 157;
  q^.xw[10] := size;
  q^.xl[4] := n^.int_value;
  q^.xl[2] := 0;
  case q^.xw[10] of
    1: begin
      q^.xp[1] := il_$node_ptr_t(il_tab_80[h]);
      il_tab_80[h] := q;
    end;
    2: begin
      q^.xp[1] := il_$node_ptr_t(il_tab_0[h]);
      il_tab_0[h] := q;
    end;
    4: begin
      q^.xp[1] := il_$node_ptr_t(il_tab_40[h]);
      il_tab_40[h] := q;
    end;
    otherwise
      ;
  end;
  defer_constant := q;
end;

{ chk_imd - the form (f6) of immediate operand a for restriction code
  and size: an operand tst_imd accepts (or a double 89 of size 7, a
  195 of size 4) by code (2, 4, 6, 15 none; 5, 9, 10 by the size: 0
  a byte, 1 a word, 2 a long, 4 a single, 5 a double; 16 a word; 12
  and 14 from the constant pool, an integer constant deferred
  there), any other immediate from the pool (3); an operand from the
  pool marks the data register (cg_data_reg) used.

  0x0B6E14, 0x164 bytes, link #-4: f1 tested `andi #0xF8; lsr #3'; the
  first test evaluated whole (`or.b', `bmi'), then 195 and 4 compared;
  jump tables of 15 (code from 2) and 7 (the size from 1); f6 cleared
  (`andi.b #0xF1') and or-ed; the kinds the set at 0x0B6D0C. }

procedure chk_imd(
    var a: codegen_$ads_t;
    code: integer;
    size: integer); options(val_param); internal;
var
  k: integer;
begin
  if a.f1 = 3 then begin
    if tst_imd(il_$node_ptr_t(a.x)) or
       ((il_$node_ptr_t(a.x)^.kind = 89) and (size = 7)) or
       ((il_$node_ptr_t(a.x)^.kind = 195) and (size = 4)) then
      case code of
        2, 4, 6, 15:
          a.f6 := 0;
        5, 9, 10:
          case size of
            1:
              a.f6 := 0;
            2:
              a.f6 := 1;
            4:
              a.f6 := 2;
            6:
              a.f6 := 4;
            7:
              a.f6 := 5;
            otherwise
              ;
          end;
        16:
          a.f6 := 1;
        12, 14: begin
          a.f6 := 3;
          k := il_$node_ptr_t(a.x)^.kind;
          if k in [77..87, 101, 200] then
            a.x := integer32(defer_constant(il_$node_ptr_t(a.x), size));
        end;
        otherwise
          a.f6 := 0;
      end
    else
      a.f6 := 3;
    if a.f6 = 3 then
      cg_addr_used[cg_data_reg] := true;
  end;
end;

{ adrlen - the bytes of operand a's extension words: by its mode (f1)
  2 a displacement (none for 0, 2 for a word, 6 a long: y), 15 4, 3, 12
  and 16 an immediate by its form (f6: 0, 1, 3 2; 2, 4 4; 5 8), 5 and 7
  2, 4 and 6 a displacement of a byte, word or long (2, 4, 6), 11 2
  (il_c4's bit 1 set), the others none.

  0x0B6F78, 0xEE bytes, link #-4, A5 loaded: jump tables of 15 (f1
  from 2) and 6 (f6); f6 6 and 7 left unset (D0 keeps f6). }

function adrlen(
    in a: codegen_$ads_t): integer;
begin
  case a.f1 of
    2:
      if (a.y > 32767) or (a.y < -32768) then
        adrlen := 6
      else if a.y <> 0 then
        adrlen := 2
      else
        adrlen := 0;
    15:
      adrlen := 4;
    3, 12, 16:
      case a.f6 of
        0, 1, 3:
          adrlen := 2;
        2, 4:
          adrlen := 4;
        5:
          adrlen := 8;
        otherwise
          ;
      end;
    5, 7:
      adrlen := 2;
    4, 6:
      if (a.y >= -128) and (a.y <= 127) then
        adrlen := 2
      else if (a.y >= -32768) and (a.y <= 32767) then
        adrlen := 4
      else
        adrlen := 6;
    11: begin
      il_c4 := il_c4 ! 2;
      adrlen := 2;
    end;
    otherwise
      adrlen := 0;
  end;
end;

{ sz_case - the size field's index of a size: byte 0, word 1, long 2,
  single 3, double 4 (3, 5 and others left unset).

  0x0B7066, 0x3A bytes: no frame (the parameter at (4,SP)); a jump
  table of 7 from 1. }

function sz_case(
    size: integer): integer; options(val_param); internal;
begin
  case size of
    1:
      sz_case := 0;
    2:
      sz_case := 1;
    4:
      sz_case := 2;
    6:
      sz_case := 3;
    7:
      sz_case := 4;
    otherwise
      ;
  end;
end;

{ ilength - see codegen.ins.pas: by the cell's kind, the operation word
  (2, or 4 for the 68020's and 68881's two-word forms) and the
  operands' extension words (adrlen); an inline constant (28) its
  constant's bytes (cgerr 3 for a constant of another kind or a pool
  constant of another size); a branch (17, 18, 31) 2, 4 or 6 by its
  instruction; 20, 39 4 or 6; a line number or a block's start or
  end (24, 32, 33) cgerr 3 and 0.

  0x0B70A0, 0x2EE bytes, link #-8, A5 loaded: a jump table of 59; the
  constant kinds compared in turn (88, 89, 90, 198, 157, 92, 156, 212,
  195); a string's length rounded up to even (`addq #1; andi #-2');
  the branches' instructions compared unsigned (`bcs', `bhi') after
  120 and 116 (and 121 and 117) evaluated whole; the first adrlen
  kept in a frame word (-8); the arms adding 2 or 4 share their tails
  (`addq.w #2' at 0x0B737E, `addq.w #4' at 0x0B7354). }

function ilength;
var
  n: integer;
  k: il_$node_ptr_t;
begin
  n := 0;
  case c^.kind of
    0:
      ;
    24, 32, 33:
      cgerr(3, emit_line, nil);
    28: begin
      k := il_$node_ptr_t(c^.ads2.x);
      case k^.kind of
        88:
          n := 4;
        89:
          n := 8;
        90:
          n := 8;
        198:
          n := 16;
        157:
          case k^.xw[10] of
            1:
              n := 2;
            2:
              n := 2;
            4:
              n := 4;
            otherwise
              cgerr(3, emit_line, nil);
          end;
        92, 156, 212:
          n := (k^.str_len + 1) & (-2);
        195:
          n := 4;
        otherwise
          cgerr(3, emit_line, nil);
      end;
    end;
    53:
      n := 4;
    21, 22, 27, 30, 34, 35, 36:
      n := 2;
    1:
      n := adrlen(c^.ads1) + adrlen(c^.ads2) + 2;
    2, 3, 5, 7, 29:
      n := adrlen(c^.ads2) + 2;
    15, 16:
      n := adrlen(c^.ads2) + 2;
    46, 47, 50:
      n := adrlen(c^.ads2) + 4;
    4, 6, 9:
      n := adrlen(c^.ads1) + 2;
    45, 49:
      n := adrlen(c^.ads1) + 4;
    8:
      n := adrlen(c^.ads1) + adrlen(c^.ads2) + 2;
    10, 11, 13:
      n := 2;
    12:
      n := adrlen(c^.ads2) + 2;
    14:
      n := adrlen(c^.ads2) + 4;
    17, 18, 31:
      if (c^.op = 120) or (c^.op = 116) or
         ((c^.op >= 140) and (c^.op <= 153)) then
        n := 2
      else if (c^.op = 121) or (c^.op = 117) or
              ((c^.op >= 154) and (c^.op <= 167)) then
        n := 4
      else
        n := 6;
    19:
      n := adrlen(c^.ads2) + 2;
    20:
      if c^.op = 203 then
        n := 4
      else
        n := 6;
    23:
      n := 4;
    25, 26:
      n := adrlen(c^.ads1) + adrlen(c^.ads2) + 2;
    37, 40:
      n := adrlen(c^.ads1) + 4;
    38, 41, 44:
      n := 4;
    42:
      n := adrlen(c^.ads2) + 4;
    43, 48:
      n := 4;
    39:
      if (c^.op >= 436) and (c^.op <= 441) then
        n := 4
      else
        n := 6;
    52:
      n := adrlen(c^.ads1) + 4;
    51:
      n := adrlen(c^.ads2) + 4;
    54:
      n := adrlen(c^.ads2) + 2;
    55, 56, 57, 58:
      n := adrlen(c^.ads1) + adrlen(c^.ads2) + 2;
    otherwise
      ;
  end;
  ilength := n;
end;

{ fnl_slct - see codegen.ins.pas.  A label (32): its cell when it has
  one (its node's +80; +72 bit 7 set), else a new label cell; a line
  (33) bug_check (emit_line_eop makes those); 39 an inline constant
  (504, or 505 for a class wider than 4 bytes).  Others: the first of
  the operation's instructions (opinfo_insts[op]) whose restrictions
  the operands and the size meet and whose cpu features are there
  (missing: the 68000's [0..4], the 160's [2..4], the 68020's [0, 1,
  3, 4]; the 68881 supplies 3 and 0, the FPA1 4), its cell made with
  the operands packed (src the first), the immediates' forms set
  (chk_imd: x the size for the extended forms), the instruction made
  exact by the cell's kind (sizes by sz_case, conditions by x: the
  branches' 2..15, the 68881's 6, 7 and 12..15); none, or an
  impossible condition: cgerr 5 and an inline 39.  The cell's length
  set (ilength) and added to the routine's code bytes.

  0x0B738E, 0x4E4 bytes, link #-28, A5 loaded: 32 tested twice (the
  label's cell returned at once); 39's cell kind the constant 28 after
  the routine (0x0B7872), class_size compared unsigned (`bls'); the
  entries indexed `ext.l; lsl.l #2' times 3 (D4); the three
  restrictions evaluated whole (a frame byte, -26); the cpu tests
  `btst' of 0x2C3671 bits 4, 5, 6 and 0x2C3670 bit 2, the removals
  `andi.w #-9; andi.w #-2'; x's low word kept at -16, the size for
  chk_imd at -20; the FPA1 operations compared in turn (495, 498, 497,
  494, 493, 491, 490, 492); a jump table of 58 on the kind from 1; the
  conditions' ranges `btst' in 0xFFFC and 0xFFFF; the error path's
  length added from the cell variable it never set (A3 as the caller
  left it: docs/questions.md 124), the code bytes zero-extended. }

function fnl_slct;
label
  1;
var
  ok: boolean;
  missing: set of 0..15;
  e: em_list_ptr_t;
  c: codegen_$cell_ptr_t;
  r: codegen_$cell_ptr_t;
  lab: il_$node_ptr_t;
  i: integer;
  xlow: integer;
  t: integer;
  k: integer;
begin
  if op = 32 then begin
    lab := il_$node_ptr_t(dst.x);
    if lab <> nil then
      if lab^.xp[20] <> nil then begin
        r := codegen_$cell_ptr_t(lab^.xp[20]);
        lab^.xc[72] := chr(ord(lab^.xc[72]) ! 16#80);
        fnl_slct := r;
        return;
      end;
    c := getlabcell(lab);
    r := c;
    pack_ads(src, c^.ads1);
    pack_ads(dst, c^.ads2);
  end;
  if op = 32 then begin
    c^.kind := 0;
    c^.size := 0;
    if lab <> nil then
      lab^.xc[72] := chr(ord(lab^.xc[72]) ! 16#80);
  end
  else if op = 33 then
    bug_check('emit$fnl_slct -- line_eop should only be generated by emit$emit_line_eop%$')
  else if op = 39 then begin
    c := getcodecell(inline_instyp);
    r := c;
    pack_ads(src, c^.ads1);
    pack_ads(dst, c^.ads2);
    if class_size[size] > 4 then
      c^.op := 505
    else
      c^.op := 504;
    c^.size := ilength(c);
  end
  else begin
    i := -1;
    e := opinfo_insts[op];
    missing := [0..4];
    if 2 in cargs_$options.cpu then
      missing := [2..4]
    else if 3 in cargs_$options.cpu then
      missing := [0, 1, 3, 4];
    if 4 in cargs_$options.cpu then begin
      missing := missing - [3];
      missing := missing - [0];
    end
    else if 8 in cargs_$options.cpu then
      missing := missing - [4];
    if e <> nil then
      repeat
        i := i + 1;
        ok := chk_op_restr(dst, e^[i].dst) and chk_op_restr(src, e^[i].src) and
              chk_sz_restr(size, e^[i].sz);
        if ok and (missing * e^[i].flags = []) then begin
          c := getcodecell(e^[i].kind);
          c^.op := e^[i].op;
          xlow := x;
          r := c;
          pack_ads(src, c^.ads1);
          pack_ads(dst, c^.ads2);
          if (e^[i].kind = 37) or (e^[i].kind = 40) then
            if x <> 0 then
              t := xlow
            else
              t := size
          else
            t := size;
          if (8 in cargs_$options.cpu) and
             (c^.op in [495, 498, 497, 494, 493, 491, 490, 492]) then
            chk_imd(c^.ads1, e^[i].src, 4)
          else
            chk_imd(c^.ads1, e^[i].src, t);
          if (e^[i].kind = 42) and (x <> 0) then
            t := xlow
          else
            t := size;
          chk_imd(c^.ads2, e^[i].dst, t);
          case e^[i].kind of
            25:
              c^.ads2.f6 := 1;
            26:
              c^.ads1.f6 := 1;
            10, 11:
              c^.op := c^.op + sz_case(size) + xlow * 3;
            12:
              c^.op := c^.op + sz_case(2) + xlow * 3;
            1, 3, 5, 6, 7, 8, 13:
              c^.op := c^.op + sz_case(size);
            18:
              if xlow in [2..15] then
                c^.op := e^[i].op + xlow - 2
              else
                goto 1;
            19, 23:
              if xlow in [0..15] then
                c^.op := e^[i].op + xlow
              else
                goto 1;
            27: begin
              xlow := x;
              c^.op := xlow;
            end;
            37, 40, 50, 42: begin
              if x = 0 then
                t := size
              else
                t := xlow;
              c^.op := sz_case(t) + e^[i].op;
            end;
            51:
              c^.ads1.f6 := 0;
            52:
              c^.ads2.f6 := 0;
            39, 43: begin
              k := xlow;
              if (k = 7) or (k = 6) then
                c^.op := k + e^[i].op - 6
              else if k in [12, 13, 15, 14] then
                c^.op := k + e^[i].op - 10
              else
                goto 1;
            end;
            otherwise
              ;
          end;
          c^.size := ilength(c);
          cg_code_bytes := cg_code_bytes + c^.size;
          fnl_slct := r;
          return;
        end;
      until 5 in e^[i].flags;
  1:
    cgerr(5, emit_line, nil);
    r := fnl_slct(39, size, x, dst, src);
  end;
  if op <> 33 then
    cg_code_bytes := cg_code_bytes + c^.size;
  fnl_slct := r;
end;

{ emit - see cg.ins.pas: under -CPU FPA1 a move (0) to or from a
  floating register goes to emit_assign; else, when the pass emits
  (at_backend_506), the size made the instruction's (an address 5 a
  long; a long to or from a floating register a single, a single
  otherwise a long, under FPA1 a double a long, unless an operand is an
  FPA register; the bit operations 14..17 a long on a data register,
  else a byte), the cell selected (fnl_slct) and appended to the
  current routine's section (il_180's +188, its last cell +24).

  0x0B78C0, 0x11E bytes, link #-4, A5 loaded: the FPA1 test `btst #2'
  of 0x2C3670; the source's FPA register test evaluated whole, the
  destination's after it; 14..17 compared unsigned (`bcs', `bhi'), the
  register too (`bcc'). }

procedure emit;
var
  c: codegen_$cell_ptr_t;
begin
  if (8 in cargs_$options.cpu) and (op = 0) and
     ((src.f1 = 13) or (dst.f1 = 13)) then
    emit_assign(size, dst, src)
  else if at_backend_506 then begin
    if size = 5 then
      size := 4;
    if not ((8 in cargs_$options.cpu) and
            (((src.f1 = 16) and (src.f2 in [16..23])) or
             ((dst.f1 = 16) and (dst.f2 in [16..23])))) then
      if (src.f1 = 13) or (dst.f1 = 13) then begin
        if size = 4 then
          size := 6;
      end
      else if size = 6 then
        size := 4
      else if (8 in cargs_$options.cpu) and (size = 7) then
        size := 4;
    if (op >= 14) and (op <= 17) then
      if (dst.f1 = 1) and (dst.f2 < 8) then
        size := 4
      else
        size := 1;
    c := fnl_slct(op, size, x, dst, src);
    after(em_sect_ptr_t(il_180^.xp[47])^.tail, c);
    em_sect_ptr_t(il_180^.xp[47])^.tail := c;
  end;
end;

{ emit_line_eop - see cg.ins.pas: when the pass emits, a cell for the
  end of block a (33), the start of block b (32) or a line (24, its
  list of equivalent lines nil and not a return), with the line,
  appended to the current section; the line kept for cgerr.

  0x0B79DE, 0xA6 bytes, link #-4, A5 loaded: the kinds the constants
  after the routine (0x0B7A84: 33, 24, 32); the line's +12 and +16
  cleared (`clr.l', `clr.b'). }

procedure emit_line_eop;
var
  c: codegen_$cell_ptr_t;
begin
  if at_backend_506 then begin
    if a.x <> 0 then begin
      c := getcodecell(block_end_instyp);
      c^.blk := il_$node_ptr_t(a.x);
    end
    else if b.x <> 0 then begin
      c := getcodecell(block_start_instyp);
      c^.blk := il_$node_ptr_t(b.x);
    end
    else begin
      c := getcodecell(line_no_instyp);
      c^.blk := nil;
      c^.ret := false;
    end;
    c^.line := line;
    emit_line := line;
    after(em_sect_ptr_t(il_180^.xp[47])^.tail, c);
    em_sect_ptr_t(il_180^.xp[47])^.tail := c;
  end;
end;
