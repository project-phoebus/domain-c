{ cg_addr - the m68k code generator's operands and registers: the
  address descriptors of the IL's nodes (address, the loads into
  registers: load_operand, load_address, load_modifiable, the indexed
  and dereferenced forms), the registers' contents (a record per
  register of the value it holds, cg_addr_regs; the variables living
  in registers, cg_addr_cache; the locks; peek, chk_assign, inquire,
  setresult), the choice of a register (get_register, weight), the
  results of the trees' operations (load_result, load_fp_result), the
  frame's temporaries (allocate_temp, get_temp, the free list), and
  the register state at labels (merge_state, edit_register,
  cg_addr_$init_regs).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0EEFF4  --------  assert_optimizer_is_enabled
    0x0EF020  --------  assert_is_label_node
    0x0EF038  --------  assert_is_nlbranch
    0x0EF050  --------  forceobjcache
    0x0EF112  --------  setobjcache
    0x0EF1F2  --------  getobjcache
    0x0EF2BC  --------  setresult
    0x0EF3BA  --------  check_use
    0x0EF42A  --------  weight
    0x0EF58C  --------  dfree
    0x0EF5B0  --------  address_reg
    0x0EF600  --------  unlock
    0x0EF6F8  --------  chk_assign
    0x0EF7D2  --------  register_tickle
    0x0EF93C  --------  peekdisp
    0x0EF9C2  --------  peek
    0x0EFCD6  --------  cg_addr_$operand_in_reg_any_rlen
    0x0EFD68  --------  load_live_registers
    0x0EFE7E  --------  inquire
    0x0F00B6  --------  kill_register
    0x0F00F4  --------  init_temp
    0x0F011C  --------  invalidate
    0x0F0390  --------  allocate_temp
    0x0F04C6  --------  cg_addr_$addr_of_cse
    0x0F051A  --------  cg_addr_$load_addr_of_cse
    0x0F06F2  --------  cg_addr_$remove_temp_from_free_list
    0x0F0740  --------  get_temp
    0x0F09B6  --------  get_agg_temp
    0x0F09E4  --------  get_childs_agg_temp
    0x0F0A60  --------  cg_addr_$free_alloc_temp
    0x0F0AEA  --------  release
    0x0F0C5A  --------  get_register
    0x0F0E42  --------  get_temp_register
    0x0F0EA4  --------  load_operand
    0x0F1050  --------  load_address
    0x0F11A8  --------  load_modifiable
    0x0F13B8  --------  load_indexreg
    0x0F13FC  --------  load_dereference
    0x0F1526  --------  load_dindex
    0x0F183A  --------  makedeferred
    0x0F18F4  --------  chk_addr
    0x0F197E  --------  address
    0x0F226C  --------  load_result
    0x0F26BA  --------  anyconst
    0x0F2780  --------  load_fp_result
    0x0F2AAC  --------  merge_register
    0x0F2BA8  --------  merge_state
    0x0F2D50  --------  cg_addr_$merge_state_of_assigned_goto_targets
    0x0F2EAA  --------  cg_addr_$init_regs
    0x0F2F6C  --------  edit_register
    A5 0x354FB8 (cc.m68k), 0x2BC bytes: the cells cg.ins.pas declares
    (+0 the register variables, +0xC0 the used registers, +0xE0 the
    locks, +0x120 the registers' records, +0x2A0 .. +0x2BA), defined
    here in that order.  No .rwdi record.

  The assertions, dfree, peekdisp, load_indexreg, load_dereference
  and load_dindex do not load A5 and are internal (they run on their
  callers' A5); merge_register is nested in merge_state; the others
  are global (forceobjcache, makedeferred and the two free-list
  routines are called only here, or not at all).

  Operands are codegen_$uads_t descriptors (docs/questions.md 74: f1
  the mode, 1 a register, 2 d(An), 3 immediate, 4 indexed, 7 a label,
  8 (An)+, 9 -(An), 11 a PEB operation, 12 absolute, 13 a floating
  register, 15 the object; f2 the register, f3 the index register, f4
  its scale; f5 flags: bit 0 getphase 1 or 2, bit 1 a long index, bit
  2 getphase 3 or 4; f6 the absolute's form; x the node, y the
  displacement).  emit's generic instructions as numbers (questions
  77): 0 move, 1 add, 22 lea.  delay.pas's word table at 0x169968
  (delay_378: a class's width) as cg_fp.pas declares it.

  Not known from the original: the names of the module's variables
  (cg.ins.pas's), of the locals and the parameters; the IL nodes'
  fields (by offset; the trees through cg_tree_t). }
module cg_addr;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/fpa.ins.pas';
%include 'lang/lang/source/fop.ins.pas';

type
  { A basic block's successors as merge_state_of_assigned_goto_targets
    reads them (g_opt.ins.pas's g_opt_block_t: +106 their count, +108
    the array from 1; a successor's +84 its first statement). }
  addr_blocks_t = array [1..16383] of il_$node_ptr_t;
  addr_blocks_ptr_t = ^addr_blocks_t;

var
  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, its width in bytes. }
  delay_378: extern array [0..15] of integer;

define
  cg_addr_cache, cg_addr_used, cg_addr_locks, cg_addr_regs,
  cg_addr_half_blk, cg_addr_half_disp, cg_addr_free_temps, cg_addr_2ac,
  cg_addr_2b0, cg_addr_next_freg, cg_addr_next_areg, cg_addr_next_dreg,
  cg_addr_2ba,
  setobjcache, getobjcache, setresult, check_use, weight, address_reg,
  unlock, chk_assign, register_tickle, peek,
  cg_addr_$operand_in_reg_any_rlen, load_live_registers, inquire,
  kill_register, init_temp, invalidate, allocate_temp,
  cg_addr_$addr_of_cse, cg_addr_$load_addr_of_cse, get_temp,
  get_agg_temp, get_childs_agg_temp, release, get_register,
  get_temp_register, load_operand, load_address, load_modifiable,
  chk_addr, address, load_result, anyconst, load_fp_result,
  merge_state, cg_addr_$merge_state_of_assigned_goto_targets,
  cg_addr_$init_regs, edit_register;


{ assert_optimizer_is_enabled - the optimizer runs: not -DBA (cargs
  db 3), and -OPT's level above 2.

  0x0EEFF4, 0x2C bytes, no frame: `andi.l #0x18000' of the longword at
  +0x282, `lsr.l #8; lsr.l #7; cmpi.w #3' (db, +0x283.0 to +0x284.7);
  `andi.b #0x3C' of +0x27F, `lsr.w #2', `cmpi.w #2; shi' (opt).
  opt_main.pas has a routine of the same name (0x0DAC88) that also
  tests +0x2CE5A7 first. }

function assert_optimizer_is_enabled: boolean; internal;
begin
  if cargs_$options.db = 3 then
    assert_optimizer_is_enabled := false
  else
    assert_optimizer_is_enabled := cargs_$options.opt > 2;
end;

{ assert_is_label_node, assert_is_nlbranch - n is a label (144), a goto
  through a label variable (150).

  0x0EF020, 0x0EF038, 0x18 bytes each, no frame: n at (4,SP). }

function assert_is_label_node(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_label_node := false
  else
    assert_is_label_node := n^.kind = 144;
end;

function assert_is_nlbranch(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_nlbranch := false
  else
    assert_is_nlbranch := n^.kind = 150;
end;

{ forceobjcache - setobjcache without the tests of the flags: n (and a
  190's object and chain) marked as cached in register r.  Only
  itself calls it.

  0x0EF050, 0xA8 bytes: the kinds' set after the code (0x0EF0F8: 137,
  138, 143, 145..147, 164, 171, 175, 189, 205); the chain walked by
  `repeat' (no test before the first). }

procedure forceobjcache(
    n: il_$node_ptr_t;
    r: integer); options(val_param);
var
  m: il_$node_ptr_t;
begin
  if (n <> nil) and (r <> 31) then
    if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then begin
      n^.xw[5] := r;
      n^.xw[3] := n^.xw[3] ! 16#400;
    end
    else if n^.kind = 109 then begin
      n^.xw[37] := r;
      n^.xl[8] := n^.xl[8] ! 16#1000000;
    end
    else if n^.kind = 110 then begin
      n^.xw[8] := r;
      n^.xl[6] := n^.xl[6] ! 16#1000000;
    end
    else if n^.kind = 190 then begin
      forceobjcache(n^.xp[1], r);
      m := n^.xp[5];
      repeat
        m^.xw[3] := m^.xw[3] ! 16#400;
        m^.xw[5] := r;
        m := m^.xp[7];
      until m = nil;
    end;
end;

{ setobjcache - n marked as cached in register r: for the trees and
  references (the kinds' set) the word +6 bit 10 and the register at
  +10, for a variable (109) +32 bit 24 and +74, for a 110 +24 bit 24
  and +16; a 190's object and its chain (+20, then +28) each unless
  already marked.  Nothing for a node already marked.

  0x0EF112, 0xE0 bytes: `btst #10' of the word +6, `btst #24' of the
  longwords; the set at 0x0EF0F8 (forceobjcache's). }

procedure setobjcache;
var
  m: il_$node_ptr_t;
begin
  if (n <> nil) and (r <> 31) then
    if (n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
        ((n^.xw[3] & 16#400) = 0) then begin
      n^.xw[5] := r;
      n^.xw[3] := n^.xw[3] ! 16#400;
    end
    else if (n^.kind = 109) and ((n^.xl[8] & 16#1000000) = 0) then begin
      n^.xw[37] := r;
      n^.xl[8] := n^.xl[8] ! 16#1000000;
    end
    else if (n^.kind = 110) and ((n^.xl[6] & 16#1000000) = 0) then begin
      n^.xw[8] := r;
      n^.xl[6] := n^.xl[6] ! 16#1000000;
    end
    else if (n^.kind = 190) and ((n^.xp[1]^.xw[3] & 16#400) = 0) then begin
      setobjcache(n^.xp[1], r);
      m := n^.xp[5];
      repeat
        if (m^.xw[3] & 16#400) = 0 then begin
          m^.xw[3] := m^.xw[3] ! 16#400;
          m^.xw[5] := r;
        end;
        m := m^.xp[7];
      until m = nil;
    end;
end;

{ getobjcache - the register n is marked as cached in when that
  register's cache entry holds n, else the first entry (0..23) that
  does, else the marked register (31 when none); a 190 or 189 by its
  object.

  0x0EF1F2, 0xCA bytes: the result kept in D0 from 31; the entries
  searched with `dbf' of 24, `cmpa.l (A0),A2'. }

function getobjcache;
var
  r: integer;
  i: integer;
begin
  getobjcache := 31;
  if n <> nil then
    if n^.kind = 190 then
      getobjcache := getobjcache(n^.xp[1])
    else if n^.kind = 189 then
      getobjcache := getobjcache(n^.xp[5])
    else begin
      if (n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
          ((n^.xw[3] & 16#400) <> 0) then
        r := n^.xw[5]
      else if (n^.kind = 109) and ((n^.xl[8] & 16#1000000) <> 0) then
        r := n^.xw[37]
      else if (n^.kind = 110) and ((n^.xl[6] & 16#1000000) <> 0) then
        r := n^.xw[8]
      else
        r := 31;
      getobjcache := r;
      if r <> 31 then
        if cg_addr_cache[r].obj <> n then
          for i := 0 to 23 do
            if cg_addr_cache[i].obj = n then begin
              getobjcache := i;
              return;
            end;
    end;
end;

{ setresult - register r holds n's value of class size: a byte, word
  or long in an address register becomes class 5, an address in a
  data register class 4; a single in a data or floating register, a
  double in a floating one, an extended one in a floating register or
  with the FPA (-CPU element 8); nothing for other classes.  The
  record: the object (a 190's or 189's), its class, the stamp, state
  0, no second object.

  0x0EF2BC, 0xFE bytes: a jump table on size - 1 (0..11); the
  registers' sets as longwords (`btst' of 0xFF, 0xFF00, 0xFF00FF,
  0xFF0000); -CPU 8 `btst #2,0x2C3670'. }

procedure setresult;
var
  s: integer;
  m: il_$node_ptr_t;
begin
  if r = 31 then
    return;
  s := size;
  case s of
    1, 2, 4:
      if r in [8..15] then
        s := 5
      else if not (r in [0..7]) then
        return;
    5:
      if r in [0..7] then
        s := 4
      else if not (r in [8..15]) then
        return;
    6:
      if not (r in [0..7, 16..23]) then
        return;
    7:
      if not (r in [16..23]) then
        return;
    8, 12:
      if not (r in [16..23]) and not (8 in cargs_$options.cpu) then
        return;
    otherwise
      return;
  end;
  if n = nil then
    m := n
  else if n^.kind = 190 then
    m := n^.xp[1]
  else if n^.kind = 189 then
    m := n^.xp[5]
  else
    m := n;
  with cg_addr_regs[r] do begin
    obj := m;
    size := s;
    w12 := cg_addr_2ba;
    w14 := 0;
    obj2 := nil;
  end;
end;

{ check_use - a and b the same object (a 190's +4, a 189's +20).

  0x0EF3BA, 0x70 bytes: the kinds tested as compare chains (`cmpi.w
  #190; beq; cmpi.w #189; beq'), a `case' each. }

function check_use;
var
  x: il_$node_ptr_t;
  y: il_$node_ptr_t;
begin
  x := a;
  y := b;
  check_use := false;
  if x = y then
    check_use := true
  else if (x <> nil) and (y <> nil) then begin
    case x^.kind of
      190: x := x^.xp[1];
      189: x := x^.xp[5];
      otherwise
    end;
    case y^.kind of
      190: y := y^.xp[1];
      189: y := y^.xp[5];
      otherwise
    end;
    if x = y then
      check_use := true;
  end;
end;

{ weight - the cost of taking register r: 32767 for a live register
  variable; else the larger of its objects' costs: none 0, a tree's
  value (143, 138) 16001 less its uses (0 when unused), a reference's
  (145, 146, 164, 147) 15001 less its uses, a constant (the kinds'
  set) or a 110 of storage class 5 1, else its stamp + 2 (the second
  object: references as the first, else its stamp + 2); an empty
  register outside cg_addr_2b0 1.

  0x0EF42A, 0x148 bytes: the constants' set after the code (0x0EF572:
  77..90, 92, 93, 101, 156, 163, 176, 195, 198, 200); both costs
  masked with 0x7FFF and compared unsigned (`bhi'); the class of a 110
  `andi.b #0xF0' of +11, `lsr.w #4'.

  Not known from the original:
  - the costs' type (0..32767?). }

function weight;
var
  w1: integer;
  w2: integer;
  k: integer;
begin
  if (r in [0..23]) and cg_addr_cache[r].live then begin
    weight := 32767;
    return;
  end;
  with cg_addr_regs[r] do begin
    if obj = nil then
      w1 := 0
    else begin
      k := obj^.kind;
      if (k = 143) or (k = 138) then begin
        if cg_tree_ptr_t(obj)^.uses = 0 then
          w1 := 0
        else
          w1 := 16001 - cg_tree_ptr_t(obj)^.uses;
      end
      else if (k = 145) or (k = 146) or (k = 164) or (k = 147) then begin
        if cg_tree_ptr_t(obj)^.uses = 0 then
          w1 := 0
        else
          w1 := 15001 - cg_tree_ptr_t(obj)^.uses;
      end
      else if k in [77..90, 92, 93, 101, 156, 163, 176, 195, 198, 200] then
        w1 := 1
      else if (k = 110) and (rshft(ord(obj^.xc[11]) & 16#F0, 4) = 5) then
        w1 := 1
      else
        w1 := w12 + 2;
    end;
    if obj2 = nil then
      w2 := 0
    else begin
      k := obj2^.kind;
      if (k = 145) or (k = 146) or (k = 164) or (k = 147) then begin
        if cg_tree_ptr_t(obj2)^.uses = 0 then
          w2 := 0
        else
          w2 := 15001 - cg_tree_ptr_t(obj2)^.uses;
      end
      else
        w2 := w8 + 2;
    end;
  end;
  if w1 <= w2 then
    w1 := w2;
  if (w1 = 0) and not (r in cg_addr_2b0) then
    w1 := 1;
  weight := w1;
end;

{ dfree - a data register is free: neither locked nor a live register
  variable.

  0x0EF58C, 0x24 bytes, no frame: the result in D0 set true first; the
  count down from 7 to -1 (`subq.w; cmpi.w #-1; bne'). }

function dfree: boolean; internal;
var
  r: integer;
begin
  dfree := true;
  for r := 0 to 7 do
    if (cg_addr_locks[r] = 0) and not cg_addr_cache[r].live then
      return;
  dfree := false;
end;

{ address_reg - register r's operand: mode 13 for a floating register,
  else 1; no index register; the register marked used.

  0x0EF5B0, 0x50 bytes: f2 and f3 stored as one longword
  (`move.l #0x1F0000,(4,A0)' for f3 and f4; docs/rev889-patterns.md
  57), y, f5 and f6, x cleared. }

procedure address_reg;
begin
  if r in [16..23] then
    a.f1 := 13
  else
    a.f1 := 1;
  a.f2 := r;
  a.f3 := 31;
  a.f4 := 0;
  a.y := 0;
  a.f5 := 0;
  a.f6 := 0;
  a.x := 0;
  cg_addr_used[r] := true;
end;

{ unlock - operand a's registers unlocked: for a mode using its
  register (1, 2, 4, 6, 8, 9, 13, 14) the base register (not A5 and A6:
  the set 0..12, 15..23) and for the indexed ones (4, 6, 14) the
  index register (0..15); a register not locked is an error (cgerr 28)
  unless it is the data register or (the base) A7.

  0x0EF600, 0xDA bytes: the sets as longwords (0x6356, 0xFF9FFF,
  0x4050, 0xFFFF); the message a varying constant at 0x0EF6DA, one for
  both calls (docs/dpc-gaps.md 18).  The index register's test
  compares the base register (f2) with the data register: kept.

  Not known from the original:
  - whether the slip is the original's. }

procedure unlock;
begin
  if a.f1 in [1, 2, 4, 6, 8, 9, 13, 14] then begin
    if a.f2 in [0..12, 15..23] then
      if cg_addr_locks[a.f2] = 0 then begin
        if (a.f2 <> cg_data_reg) and (a.f2 <> 15) then
          cgerr(28, cg_line,
              token_$make_string_token('unlocking unlocked register'));
      end
      else
        cg_addr_locks[a.f2] := cg_addr_locks[a.f2] - 1;
    if a.f1 in [4, 6, 14] then
      if a.f3 in [0..15] then
        if cg_addr_locks[a.f3] = 0 then begin
          if a.f2 <> cg_data_reg then
            cgerr(28, cg_line,
                token_$make_string_token('unlocking unlocked register'));
        end
        else
          cg_addr_locks[a.f3] := cg_addr_locks[a.f3] - 1;
  end;
end;

{ chk_assign - the register that is variable n's home (cg_addr_cache)
  for class size: the marked register (getobjcache) first, else the
  first entry; the classes of the same width (delay_378), and an
  address register exactly when size is 5.

  0x0EF6F8, 0xDA bytes: `seq' of size = 5 against `sne' of the
  register's `btst' in 0xFF00, `cmp.b'; the entries searched with
  `dbf' of 24, the result kept in D0. }

function chk_assign;
var
  r: integer;
  i: integer;
begin
  if n = nil then
    chk_assign := 31
  else if n^.kind = 190 then
    chk_assign := chk_assign(n^.xp[1], size)
  else if n^.kind = 189 then
    chk_assign := chk_assign(n^.xp[5], size)
  else begin
    r := getobjcache(n);
    if r <> 31 then
      if cg_addr_cache[r].obj = n then
        if delay_378[cg_addr_cache[r].size] = delay_378[size] then
          if (size = 5) = (r in [8..15]) then begin
            chk_assign := r;
            return;
          end;
    for i := 0 to 23 do
      if cg_addr_cache[i].obj = n then
        if delay_378[cg_addr_cache[i].size] = delay_378[size] then
          if (size = 5) = (i in [8..15]) then begin
            chk_assign := i;
            return;
          end;
    chk_assign := 31;
  end;
end;

{ register_tickle - the current statement (cg_stmt's next past
  register lists, 191) is worth keeping n in a register for: a 142
  whose +56 is n, or whose +56 is a tree adding or subtracting (12,
  40) n (a temporary's owner for a 152) not a constant 0 (unless
  zero_ok); a 140 whose +68 is n.  Never for an integer or real
  constant 0, a string (92) or a node of getphase element 1.

  0x0EF7D2, 0x150 bytes: the integer constants' set after the code
  (0x0EF922: 77..87, 101, 200; their value at +8); the reals' test
  `pea (12,A2); jsr fpp_$' with the operation words 0x0074 0xFF34 and
  `beq' (docs/rev889-patterns.md 19: a comparison with 0); the result
  in D7. }

function register_tickle;
var
  s: il_$node_ptr_t;
  t: il_$node_ptr_t;
  a: il_$node_ptr_t;
  c: il_$node_ptr_t;
begin
  register_tickle := false;
  if (n^.kind in [77..87, 101, 200]) and (n^.xl[2] = 0) then
    return;
  if (n^.kind = 88) or (n^.kind = 89) then
    if n^.real_value = 0.0 then
      return;
  if n^.kind = 92 then
    return;
  if 1 in getphase(n) then
    return;
  s := cg_stmt;
  repeat
    s := s^.xp[2];
  until s^.kind <> 191;
  case s^.kind of
    142: begin
      t := s^.xp[14];
      if t = n then
        register_tickle := true
      else if t^.kind = 143 then
        if (cg_tree_ptr_t(t)^.op = 12) or (cg_tree_ptr_t(t)^.op = 40) then begin
          a := n;
          if n^.kind = 152 then
            a := n^.xp[4];
          c := cg_tree_ptr_t(t)^.opnd[1];
          if c^.kind = 152 then
            c := c^.xp[4];
          if c <> a then begin
            c := cg_tree_ptr_t(t)^.opnd[2];
            if c^.kind = 152 then
              c := c^.xp[4];
            if c <> a then
              return;
          end;
          if not zero_ok then begin
            if (c^.kind in [77..87, 101, 200]) and (c^.xl[2] = 0) then
              return;
            if (c^.kind = 89) or (c^.kind = 88) then
              if c^.real_value = 0.0 then
                return;
          end;
          register_tickle := true;
        end;
    end;
    140:
      if s^.xp[16] = n then
        register_tickle := true;
    otherwise
  end;
end;

{ peekdisp - the data register (0..7) of class size holding the
  reference (147) of base and displacement disp, 31 none.

  0x0EF93C, 0x86 bytes, no A5 load (its caller's): each record's
  objects tested in turn, the result in D0 from 31. }

function peekdisp(
    base: il_$node_ptr_t;
    disp: integer32;
    size: integer): integer; options(val_param); internal;
var
  r: integer;
  o: il_$node_ptr_t;
begin
  peekdisp := 31;
  for r := 0 to 7 do
    if cg_addr_regs[r].size = size then begin
      o := cg_addr_regs[r].obj;
      if o <> nil then
        if o^.kind = 147 then
          if (o^.xp[6] = base) and (o^.xl[8] = disp) then begin
            peekdisp := r;
            return;
          end;
      o := cg_addr_regs[r].obj2;
      if o <> nil then
        if o^.kind = 147 then
          if (o^.xp[6] = base) and (o^.xl[8] = disp) then begin
            peekdisp := r;
            return;
          end;
    end;
end;

{ peek - the register holding n's value of class size: the home
  (chk_assign) holding it in the same width, of the right kind for
  the class; the marked register (getobjcache) of the class; then by
  class: an address in an address register (any record) or a data
  register of class 5, a single or double in a floating register (a
  single also in a data register), an extended one in FP0 and FP1; else
  a data register of the class, and for a byte or word of a reference
  the register holding the word or long it is the low part of (peek
  of the base, peekdisp).

  0x0EF9C2, 0x314 bytes: the conditions on the home evaluated whole
  (`seq', `or.b', `and.b', `bmi'); the records' loops with `dbf'; the
  reference's displacement times 10 plus the size (`add.l', the size
  zero-extended) compared with 11, 22, 31; `cmpi.w #4; bcc': size
  compared unsigned.

  Not known from the original:
  - the size's type (a non-negative subrange?). }

function peek;
var
  r: integer;
  t: integer;
begin
  peek := 31;
  if n = nil then
    return;
  if n^.kind = 190 then begin
    peek := peek(n^.xp[1], size);
    return;
  end;
  if n^.kind = 189 then begin
    peek := peek(n^.xp[5], size);
    return;
  end;
  r := chk_assign(n, size);
  if r <> 31 then
    if delay_378[cg_addr_regs[r].size] = delay_378[size] then
      if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
        if ((size = 7) or (size = 6)) and (r in [16..23]) then begin
          peek := r;
          return;
        end;
        if (r in [8..15]) and (size = 5) then begin
          peek := r;
          return;
        end;
        if r in [0..7] then
          if (size = 1) or (size = 2) or (size = 6) or (size = 4) then begin
            peek := r;
            return;
          end;
      end;
  r := getobjcache(n);
  if r <> 31 then
    if cg_addr_regs[r].size = size then
      if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
        peek := r;
        return;
      end;
  if size = 5 then begin
    for r := 8 to 15 do
      if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
        peek := r;
        return;
      end;
    for r := 0 to 7 do
      if cg_addr_regs[r].size = size then
        if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
          peek := r;
          return;
        end;
    peek := 31;
  end
  else if (size = 6) or (size = 7) then begin
    for r := 16 to 23 do
      if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
        peek := r;
        return;
      end;
    if size = 6 then
      for r := 0 to 7 do
        if cg_addr_regs[r].size = 6 then
          if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
            peek := r;
            return;
          end;
    peek := 31;
  end
  else if (size = 8) or (size = 12) then begin
    if ((cg_addr_regs[16].obj = n) and (cg_addr_regs[17].obj = n)) or
        ((cg_addr_regs[16].obj2 = n) and (cg_addr_regs[17].obj2 = n)) then
      peek := 16
    else
      peek := 31;
  end
  else begin
    for r := 0 to 7 do
      if cg_addr_regs[r].size = size then
        if (cg_addr_regs[r].obj = n) or (cg_addr_regs[r].obj2 = n) then begin
          peek := r;
          return;
        end;
    peek := 31;
    if (n^.kind = 147) and (size < 4) then begin
      t := 31;
      case n^.xl[8] * 10 + size of
        11: t := peek(n^.xp[6], 2);
        22: t := peek(n^.xp[6], 4);
        31: t := peek(n^.xp[6], 4);
        otherwise
      end;
      if t <> 31 then begin
        peek := t;
        return;
      end;
      case size of
        1: begin
          t := peekdisp(n^.xp[6], n^.xl[8] - 1, 2);
          if t = 31 then
            t := peekdisp(n^.xp[6], n^.xl[8] - 3, 4);
        end;
        2:
          t := peekdisp(n^.xp[6], n^.xl[8] - 2, 4);
        otherwise
      end;
      peek := t;
    end;
  end;
end;

{ cg_addr_$operand_in_reg_any_rlen - the live registers (0..23) whose
  second object is n, with a reference's base variable's (109, 110),
  as a set (bit k register k).

  0x0EFCD6, 0x92 bytes: `bset D1,D4; or.l D4,D2' for each register;
  the recursive result `or.l'-ed. }

function cg_addr_$operand_in_reg_any_rlen;
var
  s: integer32;
  r: integer;
  b: il_$node_ptr_t;
begin
  s := 0;
  if n = nil then
    cg_addr_$operand_in_reg_any_rlen := 0
  else if n^.kind = 190 then
    cg_addr_$operand_in_reg_any_rlen := cg_addr_$operand_in_reg_any_rlen(n^.xp[1])
  else if n^.kind = 189 then
    cg_addr_$operand_in_reg_any_rlen := cg_addr_$operand_in_reg_any_rlen(n^.xp[5])
  else begin
    for r := 0 to 23 do
      if (cg_addr_regs[r].obj2 = n) and cg_addr_cache[r].live then
        s := s ! lshft(1, r);
    if n^.kind = 147 then begin
      b := n^.xp[6];
      if (b^.kind = 110) or (b^.kind = 109) then
        s := s ! cg_addr_$operand_in_reg_any_rlen(b);
    end;
    cg_addr_$operand_in_reg_any_rlen := s;
  end;
end;

{ load_live_registers - each register variable marked to be loaded:
  the mark cleared, its value moved into the register unless it is
  there already (from where inquire finds it, or its address; with the
  FPA a floating move by emit_assign), the record set (both objects
  the variable, the stamps), and the register made live.

  0x0EFD68, 0x116 bytes: the entries and records stepped together
  (`dbf' of 24, D5 and D6); the record's w14 stored with `move.w #0'. }

procedure load_live_registers;
var
  a: codegen_$uads_t;
  ra: codegen_$uads_t;
  r: integer;
begin
  for r := 0 to 23 do
    with cg_addr_cache[r] do
      if (obj <> nil) and load then begin
        load := false;
        inquire(obj, size, a);
        if a.f2 <> r then begin
          address_reg(r, ra);
          if a.f2 = 31 then
            address(obj, size, a);
          if (8 in cargs_$options.cpu) and ((ra.f1 = 13) or (a.f1 = 13)) then
            emit_assign(size, ra, a)
          else
            emit(0, size, ra, a, 0);
          cg_addr_regs[r].obj := obj;
          cg_addr_regs[r].w12 := cg_addr_2ba;
          cg_addr_regs[r].size := size;
          cg_addr_regs[r].w14 := 0;
          cg_addr_regs[r].obj2 := obj;
          cg_addr_regs[r].w8 := cg_addr_2ba;
        end;
        unlock(a);
        live := true;
      end;
end;

{ inquire - n's value (a 190's or 189's object) of class size in a
  register (peek): the register locked and marked used, a register
  operand (13 for a floating one); when the record holds n (or a
  reference into the same object at the same width's offset, 147) and
  the value is not loaded yet (w14 2), the load emitted from n's home
  register (a live one of class 5, 6 or 4) or n's address, the home
  made live, the record's state 0 and stamp set; another object's
  record gets obj2's stamp.  No register: mode 0.  Then y and f5
  cleared, the phase flags (f5 bit 0 for getphase 1 or 2, bit 2 for 3
  or 4; not for a 138) and x the node.

  0x0EFE7E, 0x238 bytes: peek's result stored to a.f2 at once; the
  offset test zero-extends delay_378's words (`clr.l; move.w') before
  adding +32; `andi.l #6', `andi.l #0x18' of getphase's set; `bset
  #0/#2,(9,A3)'. }

procedure inquire;
var
  c: codegen_$uads_t;
  b: codegen_$uads_t;
  m: il_$node_ptr_t;
  o: il_$node_ptr_t;
  r: integer;
  ph: add_node_$phase_t;
begin
  case n^.kind of
    190: m := n^.xp[1];
    189: m := n^.xp[5];
    otherwise
      m := n;
  end;
  a.f2 := peek(m, size);
  if a.f2 <> 31 then begin
    cg_addr_locks[a.f2] := cg_addr_locks[a.f2] + 1;
    cg_addr_used[a.f2] := true;
    o := cg_addr_regs[a.f2].obj;
    if (o = m) or
        ((m^.xp[6] = o) and
         (delay_378[size] + m^.xl[8] = delay_378[cg_addr_regs[a.f2].size]) and
         (m^.kind = 147)) then begin
        if cg_addr_regs[a.f2].w14 = 2 then begin
          r := 31;
          if (size = 4) or (size = 6) or (size = 5) then begin
            r := chk_assign(m, 5);
            if r = 31 then
              r := chk_assign(m, 6);
            if r = 31 then
              r := chk_assign(m, 4);
          end;
          if (r <> 31) and cg_addr_cache[r].live then begin
            address_reg(r, b);
            cg_addr_locks[r] := cg_addr_locks[r] + 1;
          end
          else
            address(o, 0, b);
          address_reg(a.f2, c);
          if (8 in cargs_$options.cpu) and ((b.f1 = 13) or (c.f1 = 13)) then
            emit_assign(cg_addr_regs[a.f2].size, c, b)
          else
            emit(0, cg_addr_regs[a.f2].size, c, b, 0);
          unlock(b);
          if cg_addr_cache[a.f2].obj = m then
            cg_addr_cache[a.f2].live := true;
        end;
        cg_addr_regs[a.f2].w14 := 0;
        cg_addr_regs[a.f2].w12 := cg_addr_2ba;
      end
      else
        cg_addr_regs[a.f2].w8 := cg_addr_2ba;
    if a.f2 in [16..23] then
      a.f1 := 13
    else
      a.f1 := 1;
  end
  else
    a.f1 := 0;
  a.y := 0;
  a.f5 := 0;
  if m^.kind <> 138 then begin
    ph := getphase(m);
    if ph * [1, 2] <> [] then
      a.f5 := a.f5 ! 1;
    if ph * [3, 4] <> [] then
      a.f5 := a.f5 ! 4;
  end;
  a.x := integer32(m);
end;

{ kill_register - register r's record emptied (objects nil, state 0);
  r above 23 ignored.

  0x0F00B6, 0x3E bytes: `cmpi.w #23; bhi' (r compared unsigned: the
  range test); the pointers stored with `move.l #0'. }

procedure kill_register;
begin
  if (r >= 0) and (r <= 23) then
    with cg_addr_regs[r] do begin
      obj := nil;
      obj2 := nil;
      w14 := 0;
    end;
end;

{ init_temp - no free temporaries, no spare frame word.

  0x0F00F4, 0x28 bytes: +0x2A8 `clr.l', +0x2A4 and +0x2A0 `move.l #0'. }

procedure init_temp;
begin
  cg_addr_free_temps := nil;
  cg_addr_half_disp := 0;
  cg_addr_half_blk := nil;
end;

{ invalidate - what a store to a's object of size bytes may change
  forgotten: the floating unit's variables in the PEB (cg_fp_in_peb,
  size 4) and last stored (cg_fp_last_store, 7) when related
  (alias_$related), and each register's objects (but the register's
  own variable, or the object of a 190 that is it) when related, of
  getphase element 2 (but a 138), or a variable (109) of a class other
  than 5 of element 1.  An assignment's (140) object is its +64; a
  temporary's (152) owner is hidden from the alias descriptor.

  0x0F011C, 0x274 bytes: the entries and records stepped together
  (`dbf' of 24); delay_378's words zero-extended as the sizes; getphase
  is called for an object already set nil (its result then tested). }

procedure invalidate;
var
  d: alias_$desc_t;
  ad: alias_$desc_t;
  n: il_$node_ptr_t;
  owner: il_$node_ptr_t;
  r: integer;
  ph: add_node_$phase_t;
begin
  n := il_$node_ptr_t(a.x);
  if n <> nil then
    case n^.kind of
      140: n := n^.xp[16];
      152: begin
        owner := n^.xp[4];
        n^.xp[4] := nil;
      end;
      otherwise
    end;
  alias_$alias_desc_with_size(n, size, ad);
  if n^.kind = 152 then
    n^.xp[4] := owner;
  if cg_fp_in_peb <> nil then begin
    alias_$alias_desc_with_size(cg_fp_in_peb, 4, d);
    if alias_$related(ad, d) then
      cg_fp_in_peb := nil;
  end;
  if cg_fp_last_store <> nil then begin
    alias_$alias_desc_with_size(cg_fp_last_store, 7, d);
    if alias_$related(ad, d) then
      cg_fp_last_store := nil;
  end;
  for r := 0 to 23 do
    with cg_addr_regs[r] do begin
      if (obj <> nil) and (obj <> cg_addr_cache[r].obj) then
        if not ((cg_addr_cache[r].obj <> nil) and
                (cg_addr_cache[r].obj^.kind = 190) and
                (cg_addr_cache[r].obj^.xp[1] = obj)) then begin
          alias_$alias_desc_with_size(obj, delay_378[size], d);
          if alias_$related(ad, d) then
            obj := nil;
          ph := getphase(obj);
          if (2 in ph) and (obj^.kind <> 138) then
            obj := nil
          else if obj <> nil then
            if obj^.kind = 109 then
              if (obj^.xw[36] <> 5) and (1 in ph) then
                obj := nil;
        end;
      if (obj2 <> nil) and (obj2 <> cg_addr_cache[r].obj) then
        if not ((cg_addr_cache[r].obj <> nil) and
                (cg_addr_cache[r].obj^.kind = 190) and
                (cg_addr_cache[r].obj^.xp[1] = obj2)) then begin
          alias_$alias_desc_with_size(obj2, delay_378[size], d);
          if alias_$related(ad, d) then
            obj2 := nil;
          ph := getphase(obj2);
          if (2 in ph) and (obj2^.kind <> 138) then
            obj2 := nil
          else if obj2 <> nil then
            if obj2^.kind = 109 then
              if (obj2^.xw[36] <> 5) and (1 in ph) then
                obj2 := nil;
        end;
    end;
end;

{ allocate_temp - a temporary of size bytes (rounded up to even): one
  of that size off the free list when reuse; else a new 152 node
  (gspace 22) whose frame offset is the spare word for a size of 2
  (cg_addr_half_disp, kept for the same routine), or the routine's
  frame grown (il_180's +80, cgerr 2 past its +84 limit), a word left
  first to keep a larger temporary's offset a multiple of 4 under
  -ALIGN (flags_286 element 4).  Then its stamp (+20: cg_top_13a, one
  less when not reuse), no link, its owner.

  0x0F0390, 0x136 bytes: `addq.l #1; andi.b #0xFE'; the free list
  walked with the previous entry in D0, the found entry's path jumping
  past the allocation (a `goto' here); the size 2 case's path likewise
  (the else branch of a compound test here); the frame offset `subq.l
  #2,(80,A0)'; -ALIGN `tst.b 0x2C3674'.

  Not known from the original:
  - the control structure (goto or flags) of the two paths. }

function allocate_temp;
label
  done;
var
  sz: integer32;
  p: il_$node_ptr_t;
  prev: il_$node_ptr_t;
begin
  sz := (size + 1) & (-2);
  if reuse then begin
    p := cg_addr_free_temps;
    prev := nil;
    while p <> nil do
      if p^.xl[2] = sz then begin
        if prev = nil then
          cg_addr_free_temps := p^.xp[3]
        else
          prev^.xp[3] := p^.xp[3];
        goto done;
      end
      else begin
        prev := p;
        p := p^.xp[3];
      end;
  end;
  p := gspace(22);
  p^.kind := 152;
  p^.xl[2] := sz;
  if (sz = 2) and (cg_addr_half_disp <> 0) and (il_180 = cg_addr_half_blk) then begin
    p^.xl[1] := cg_addr_half_disp;
    cg_addr_half_disp := 0;
  end
  else begin
    if sz <> 2 then
      if (((il_180^.xl[20] - sz) & 3) <> 0) and (4 in cargs_$options.flags_286) then begin
        il_180^.xl[20] := il_180^.xl[20] - 2;
        cg_addr_half_disp := il_180^.xl[20];
        cg_addr_half_blk := il_180;
      end;
    il_180^.xl[20] := il_180^.xl[20] - sz;
    if il_180^.xl[20] < il_180^.xl[21] then
      cgerr(2, cg_line, cg_stmt);
    p^.xl[1] := il_180^.xl[20];
  end;
done:
  if reuse then
    p^.xw[10] := cg_top_13a
  else
    p^.xw[10] := cg_top_13a - 1;
  p^.xp[3] := nil;
  p^.xp[4] := owner;
  allocate_temp := p;
end;

{ cg_addr_$addr_of_cse - n (by address) is a 190 or 189, or a
  temporary (152) whose owner is.

  0x0F04C6, 0x54 bytes: the kind in D0 tested in turn. }

function cg_addr_$addr_of_cse;
var
  k: integer;
begin
  k := n^.kind;
  if (k = 190) or (k = 189) then
    cg_addr_$addr_of_cse := true
  else if k = 152 then begin
    k := n^.xp[4]^.kind;
    cg_addr_$addr_of_cse := (k = 190) or (k = 189);
  end
  else
    cg_addr_$addr_of_cse := false;
end;

{ cg_addr_$load_addr_of_cse - the common subexpression of tree n
  (its opnd[1], a temporary's owner) stored into n's temporary (opnd[1]
  made a temporary of the value's width, or its size for an aggregate
  of class 9 or 11, moved by cg_asn_$block_move), then the temporary's
  address loaded (`lea', 22) into an address register for n, its
  operand in a.

  0x0F051A, 0x1D8 bytes: the class tested twice (`seq'/`or.b' the
  second time); emit's x the class zero-extended; the block move's
  registers at -48 and -24. }

procedure cg_addr_$load_addr_of_cse;
var
  r2: codegen_$uads_t;
  r1: codegen_$uads_t;
  t: codegen_$uads_t;
  len: integer32;
  c: il_$node_ptr_t;
  d: il_$node_ptr_t;
  k: integer;
begin
  c := cg_tree_ptr_t(n)^.opnd[1];
  if c^.kind = 152 then
    c := c^.xp[4];
  if c^.kind = 190 then
    d := c^.xp[1]
  else
    d := c^.xp[5];
  k := cg_tree_ptr_t(d)^.desc.rlen;
  if (k = 11) or (k = 9) then
    len := cg_tree_ptr_t(d)^.desc.size
  else
    len := delay_378[k];
  if not ((k = 11) or (k = 9)) then begin
    load_operand(c, k, t);
    if cg_tree_ptr_t(n)^.opnd[1]^.kind <> 152 then
      cg_tree_ptr_t(n)^.opnd[1] := allocate_temp(len, true, cg_tree_ptr_t(n)^.opnd[1]);
    address(cg_tree_ptr_t(n)^.opnd[1], k, a);
    emit(0, k, a, t, k);
    release(t);
    release(a);
  end
  else begin
    load_address(c, t);
    kill_register(t.f2);
    t.f1 := 8;
    if cg_tree_ptr_t(n)^.opnd[1]^.kind <> 152 then
      cg_tree_ptr_t(n)^.opnd[1] := allocate_temp(len, true, cg_tree_ptr_t(n)^.opnd[1]);
    load_address(cg_tree_ptr_t(n)^.opnd[1], a);
    kill_register(a.f2);
    a.f1 := 8;
    cg_asn_$block_move(len, 1, t, a, r1, r2);
    unlock(t);
    unlock(a);
  end;
  address(cg_tree_ptr_t(n)^.opnd[1], 0, t);
  get_register(n, 5, a);
  emit(22, 1, a, t, 0);
  release(t);
end;

{ cg_addr_$remove_temp_from_free_list - the free temporary of size
  bytes (rounded to even) taken off the free list.

  0x0F06F2, 0x4E bytes: the previous entry in A1 (`suba.l A1,A1'). }

procedure cg_addr_$remove_temp_from_free_list(
    size: integer32); options(val_param);
var
  sz: integer32;
  p: il_$node_ptr_t;
  prev: il_$node_ptr_t;
begin
  sz := (size + 1) & (-2);
  p := cg_addr_free_temps;
  prev := nil;
  while p <> nil do
    if p^.xl[2] = sz then begin
      if prev = nil then
        cg_addr_free_temps := p^.xp[3]
      else
        prev^.xp[3] := p^.xp[3];
      return;
    end
    else begin
      prev := p;
      p := p^.xp[3];
    end;
end;

{ get_temp - tree n's temporary: its free one taken off the free list
  when n and its operand are both of operator 26 (the operand a 138);
  a new one when opnd[1] is not a temporary, else its size checked
  (cgerr 3).  When store, n's value stored there: from its register
  (peek of its class, else of 4, 5, 6), the PEB's register (11, 149:
  cg_fp_in_peb, after test_peb_busy unless the last PEB operation
  leaves it idle), D0 or FP0 (the floating stack's result or last
  store), else cgerr 3.

  0x0F0740, 0x262 bytes: the classes' loop `dbf' of 3 from 4; the
  PEB's operations set after the code (0x0F09A2: 1, 63, 83, 104, 149,
  157, 159; cg_fp's); the descriptor at -48, the temporary's at -24.

  Not known from the original:
  - whether the loop over the classes is `for' with `exit'. }

procedure get_temp;
var
  dst: codegen_$uads_t;
  src: codegen_$uads_t;
  len: integer32;
  r: integer;
  s: integer;
  k: integer;
begin
  k := cg_tree_ptr_t(n)^.desc.rlen;
  if (k = 11) or (k = 9) then
    len := cg_tree_ptr_t(n)^.desc.size
  else
    len := delay_378[k];
  if cg_tree_ptr_t(n)^.op = 26 then
    if cg_tree_ptr_t(n)^.opnd[1]^.kind = 138 then
      if cg_tree_ptr_t(cg_tree_ptr_t(n)^.opnd[1])^.op = 26 then
        cg_addr_$remove_temp_from_free_list(len);
  if cg_tree_ptr_t(n)^.opnd[1]^.kind <> 152 then
    cg_tree_ptr_t(n)^.opnd[1] := allocate_temp(len, true, cg_tree_ptr_t(n)^.opnd[1])
  else if ((len + 1) & (-2)) <> cg_tree_ptr_t(n)^.opnd[1]^.xl[2] then
    cgerr(3, cg_line, n);
  if store then begin
    r := peek(n, cg_tree_ptr_t(n)^.desc.rlen);
    if r = 31 then
      for s := 4 to 6 do begin
        r := peek(n, s);
        if r <> 31 then
          exit;
      end;
    if r <> 31 then
      address_reg(r, src)
    else if check_use(cg_fp_in_peb, n) then begin
      if not (cg_fp_last_op in [1, 63, 83, 104, 149, 157, 159]) then
        test_peb_busy;
      src.f1 := 11;
      src.x := 0;
      src.f5 := 5;
      src.y := 149;
      cg_fp_last_op := 149;
    end
    else if check_use(cg_fp_result, n) then begin
      k := cg_tree_ptr_t(n)^.desc.rlen;
      if (k = 1) or (k = 4) or (k = 2) then
        address_reg(0, src)
      else if (k = 7) or (k = 6) then
        address_reg(16, src)
      else
        cgerr(3, cg_line, n);
    end
    else if check_use(cg_fp_last_store, n) then begin
      k := cg_tree_ptr_t(n)^.desc.rlen;
      if (k = 1) or (k = 4) or (k = 2) then
        address_reg(0, src)
      else if (k = 7) or (k = 6) then
        address_reg(16, src)
      else
        cgerr(3, cg_line, n);
    end
    else
      cgerr(3, cg_line, n);
    address(n, 0, dst);
    if (8 in cargs_$options.cpu) and (src.f1 = 13) then
      emit_assign(cg_tree_ptr_t(n)^.desc.rlen, dst, src)
    else
      emit(0, cg_tree_ptr_t(n)^.desc.rlen, dst, src, 0);
  end;
end;

{ get_agg_temp - n made a 138 with a temporary (not stored).

  0x0F09B6, 0x2E bytes. }

procedure get_agg_temp;
begin
  n^.kind := 138;
  get_temp(n, false);
end;

{ get_childs_agg_temp - n made a 138; when its operand is a tree (138,
  137) of a set operation (operators 19..22, 72, 73) n takes the
  operand's temporary (il_node_153 while not emitting), true; else a
  temporary of its own, false.

  0x0F09E4, 0x72 bytes: the operators' set after the code (0x0F0A56,
  0..79). }

function get_childs_agg_temp;
var
  c: il_$node_ptr_t;
begin
  n^.kind := 138;
  c := cg_tree_ptr_t(n)^.opnd[1];
  if ((c^.kind = 138) or (c^.kind = 137)) and
      (cg_tree_ptr_t(c)^.op in [19..22, 72, 73]) then begin
    if not at_backend_506 then
      cg_tree_ptr_t(n)^.opnd[1] := il_node_153
    else
      cg_tree_ptr_t(n)^.opnd[1] := cg_tree_ptr_t(c)^.opnd[1];
    get_childs_agg_temp := true;
  end
  else begin
    get_agg_temp(n);
    get_childs_agg_temp := false;
  end;
end;

{ cg_addr_$free_alloc_temp - a tree's (143, 138) temporary given back
  when emitting and the tree's +18 is negative (address marked it): the
  tree's opnd[1] back to the temporary's owner (cgerr 14 when it is not
  a temporary), and the temporary onto the free list when allocated
  at the current label count (cg_top_13a).

  0x0F0A60, 0x8A bytes: the list's head tested before it is linked
  (nil or the head stored). }

procedure cg_addr_$free_alloc_temp(
    n: il_$node_ptr_t); options(val_param);
var
  t: il_$node_ptr_t;
begin
  if (n^.kind = 143) or (n^.kind = 138) then begin
    t := cg_tree_ptr_t(n)^.opnd[1];
    if at_backend_506 and (cg_tree_ptr_t(n)^.w18 < 0) then begin
      if t^.kind <> 152 then
        cgerr(14, cg_line, n);
      cg_tree_ptr_t(n)^.opnd[1] := t^.xp[4];
      if t^.xw[10] = cg_top_13a then begin
        if cg_addr_free_temps = nil then
          t^.xp[3] := nil
        else
          t^.xp[3] := cg_addr_free_temps;
        cg_addr_free_temps := t;
      end;
    end;
  end;
end;

{ release - operand a unlocked and its nodes' uses counted down (cgerr
  3 at 0): the references (146, 147) down their bases (+24), a tree's
  value (143, 138; its temporary freed at 0), an indexed reference
  (145: its base +24 and index +36 released) or a 164 (+20 and +24).

  0x0F0AEA, 0x170 bytes: the references' loop with its test at the
  bottom; the nested operands released through a descriptor of A6
  (address_reg 14) with x set. }

procedure release;
var
  b: codegen_$uads_t;
  n: il_$node_ptr_t;
begin
  if a.f1 <> 0 then begin
    unlock(a);
    n := il_$node_ptr_t(a.x);
    if n <> nil then begin
      if n^.kind = 190 then
        n := n^.xp[1]
      else if n^.kind = 189 then
        n := n^.xp[5];
      while (n^.kind = 146) or (n^.kind = 147) do begin
        if cg_tree_ptr_t(n)^.uses = 0 then
          cgerr(3, cg_line, n)
        else
          cg_tree_ptr_t(n)^.uses := cg_tree_ptr_t(n)^.uses - 1;
        n := n^.xp[6];
      end;
      if (n^.kind = 143) or (n^.kind = 138) then begin
        if cg_tree_ptr_t(n)^.uses = 0 then
          cgerr(3, cg_line, n)
        else
          cg_tree_ptr_t(n)^.uses := cg_tree_ptr_t(n)^.uses - 1;
        if cg_tree_ptr_t(n)^.uses = 0 then
          cg_addr_$free_alloc_temp(n);
      end;
      if n^.kind = 145 then begin
        if cg_tree_ptr_t(n)^.uses = 0 then
          cgerr(3, cg_line, n)
        else
          cg_tree_ptr_t(n)^.uses := cg_tree_ptr_t(n)^.uses - 1;
        address_reg(14, b);
        b.x := integer32(n^.xp[6]);
        release(b);
        b.x := integer32(n^.xp[9]);
        release(b);
      end;
      if n^.kind = 164 then begin
        if cg_tree_ptr_t(n)^.uses = 0 then
          cgerr(3, cg_line, n)
        else
          cg_tree_ptr_t(n)^.uses := cg_tree_ptr_t(n)^.uses - 1;
        address_reg(14, b);
        b.x := integer32(n^.xp[5]);
        release(b);
        b.x := integer32(n^.xp[6]);
        release(b);
      end;
    end;
  end;
end;

{ get_register - a register of class size for n (a 190's or 189's
  object): n's home (chk_assign) when unlocked and of the class's kind;
  else n's marked register (getobjcache) of the class when unlocked and
  not live; else the lightest unlocked register of the class (A0..A4
  for 5, FP0..FP7 for 6 and 7, D0..D7 else), round robin from the
  class's next register (cgerr 4 when all are locked; an empty one at
  once).  It is marked as n's (setobjcache), its operand in a with x
  n, locked, holding n (setresult), and the class's next register.

  0x0F0C5A, 0x1E8 bytes: the bounds in D5/D4 and the start in D6; the
  weights compared unsigned (`bcs', `bcc'), the register with them
  (`bcs', `bhi'); the paths that find a register jump to the common
  end (0x0F0DE4: a `goto' here). }

procedure get_register;
label
  found;
var
  w: integer;
  r: integer;
  best: integer;
  bw: integer;
  start: integer;
  lo: integer;
  hi: integer;
begin
  if n <> nil then
    if n^.kind = 190 then begin
      get_register(n^.xp[1], size, a);
      return;
    end
    else if n^.kind = 189 then begin
      get_register(n^.xp[5], size, a);
      return;
    end;
  r := chk_assign(n, size);
  if r <> 31 then
    if cg_addr_locks[r] = 0 then begin
      if ((size = 7) or (size = 6)) and (r in [16..23]) then
        goto found;
      if (r in [8..12]) and (size = 5) then
        goto found;
      if r in [0..7] then
        if (size = 1) or (size = 2) or (size = 6) or (size = 4) then
          goto found;
    end;
  best := 31;
  bw := 32767;
  if size = 5 then begin
    start := cg_addr_next_areg;
    lo := 8;
    hi := 12;
  end
  else if (size = 6) or (size = 7) then begin
    start := cg_addr_next_freg;
    lo := 16;
    hi := 23;
  end
  else begin
    start := cg_addr_next_dreg;
    lo := 0;
    hi := 7;
  end;
  r := getobjcache(n);
  if (r >= lo) and (r <= hi) then
    if cg_addr_locks[r] = 0 then begin
      w := weight(r);
      if w < bw then
        goto found;
    end;
  r := start;
  repeat
    if cg_addr_locks[r] = 0 then begin
      w := weight(r);
      if w = 0 then
        goto found;
      if w < bw then begin
        bw := w;
        best := r;
      end;
    end;
    if r >= hi then
      r := lo
    else
      r := r + 1;
  until r = start;
  r := best;
  if r = 31 then
    cgerr(4, cg_line, n);
found:
  setobjcache(n, r);
  address_reg(r, a);
  a.x := integer32(n);
  cg_addr_locks[r] := cg_addr_locks[r] + 1;
  setresult(r, n, size);
  if size = 5 then
    cg_addr_next_areg := r
  else if (size = 6) or (size = 7) then
    cg_addr_next_freg := r
  else
    cg_addr_next_dreg := r;
end;

{ get_temp_register - get_register for n (a 190's or 189's object), or
  for nil (a scratch register) when n is a register's live variable.

  0x0F0E42, 0x62 bytes: the two kinds tested in turn (not `else'); the
  entries searched to the end (`dbf' of 24, `suba.l A3,A3'). }

procedure get_temp_register;
var
  m: il_$node_ptr_t;
  r: integer;
begin
  m := n;
  if m^.kind = 190 then
    m := m^.xp[1];
  if m^.kind = 189 then
    m := m^.xp[5];
  for r := 0 to 23 do
    if (cg_addr_cache[r].obj = m) and cg_addr_cache[r].live then
      m := nil;
  get_register(m, size, a);
end;

{ load_operand - n's value of class size in a register: a long in an
  address register when that is where it is (and an address in a
  data register likewise), a register operand of the class's kind (a
  byte .. address in a register; a single or double in a floating
  register) as it is; else moved (move, or emit_assign with the FPA)
  into get_register's register.

  0x0F0EA4, 0x1AC bytes: the flag in D3 (`st' first); the tests of
  the register's set shared by the classes 5 and 4 (`bra' into the
  other's `btst'); `cmpi.w #1,D2; scc', `cmpi.w #5; sls' (1 <= size
  <= 5, unsigned); the operand copied to a with five `move.l'. }

procedure load_operand;
var
  t: codegen_$uads_t;
  need: boolean;
begin
  need := true;
  if size = 5 then begin
    if (peek(n, 5) = 31) and (peek(n, 4) <> 31) then
      address(n, 4, t)
    else
      address(n, 5, t);
    if (t.f1 = 1) and (t.f2 in [8..15]) then
      need := false;
  end
  else if size = 4 then begin
    if (peek(n, 4) = 31) and (peek(n, 5) <> 31) then
      address(n, 5, t)
    else
      address(n, 4, t);
    if (t.f1 = 1) and (t.f2 in [0..7]) then
      need := false;
  end
  else begin
    address(n, size, t);
    if ((t.f1 = 1) and (size >= 1) and (size <= 5)) or
        ((t.f1 = 13) and ((size = 6) or (size = 7))) then
      need := false;
  end;
  if need then begin
    unlock(t);
    get_register(n, size, a);
    if (8 in cargs_$options.cpu) and ((a.f1 = 13) or (t.f1 = 13)) then
      emit_assign(size, a, t)
    else
      emit(0, size, a, t, 0);
  end
  else
    a := t;
end;

{ load_address - n's address (a 164's +20) in an address register: for
  a 146 whose base (+24) is in no register, or in one cheap to take
  (weight up to 15000 or 16000) and unlocked, the base loaded (moved
  on to a new register when it lands in A5 or above), x n; else the
  address taken (`lea', 22) of n's operand into a register for n (the
  instruction's size by n's kind: 2 for 80 and 83, 4 for 81, 82, 84,
  85, else 1).

  0x0F1050, 0x158 bytes: the flag in D2; `cmpi.w #13; bcs' (f2
  unsigned); a jump table on kind - 80 (0..5); emit's operation and
  size pushed as one longword (#0x00160004, docs/rev889-patterns.md
  54). }

procedure load_address;
var
  t: codegen_$uads_t;
  m: il_$node_ptr_t;
  need: boolean;
  r: integer;
  w: integer;
begin
  need := false;
  m := n;
  if m^.kind = 164 then
    m := m^.xp[5];
  if m^.kind = 146 then begin
    r := peek(m^.xp[6], 5);
    if r = 31 then
      need := true
    else begin
      w := weight(r);
      if ((w <= 15000) or (w = 16000)) and (cg_addr_locks[r] = 0) then
        need := true;
    end;
  end;
  if need then begin
    load_operand(m^.xp[6], 5, a);
    if a.f2 >= 13 then begin
      t := a;
      get_register(nil, 5, a);
      emit(0, 5, a, t, 0);
    end;
    a.x := integer32(m);
  end
  else begin
    address(m, 0, t);
    release(t);
    get_temp_register(m, 5, a);
    case m^.kind of
      80, 83: emit(22, 2, a, t, 0);
      81, 82, 84, 85: emit(22, 4, a, t, 0);
      otherwise
        emit(22, 1, a, t, 0);
    end;
  end;
end;

{ load_modifiable - n's value of class size in a register that may be
  changed: for an address (5) its address (A6 for 153, the data
  register for 154), for 1, 2, 4 its value (load_operand), for 6, 7
  its operand; the register itself when it is an address register
  A0..A4 (5) or a data register (1, 2, 4) locked once, or a floating
  register (6, 7), and is no live register variable; else a copy in a
  new register (emit's x the class).  Another class: cgerr_no_source 28
  'Invalid result length'.

  0x0F11A8, 0x1F8 bytes: a jump table on size - 1 (0..6; 3 the error);
  the tests `tst.b (7,A5,D0)' then `tst.l (0,A5,D0)' (not live, or no
  variable); the copy and the unlock share the tail; the message a
  varying constant at 0x0F13A0. }

procedure load_modifiable;
var
  t: codegen_$uads_t;
begin
  case size of
    5: begin
      if n^.kind = 153 then
        address_reg(14, t)
      else if n^.kind = 154 then
        address_reg(cg_data_reg, t)
      else
        load_address(n, t);
      if (t.f1 = 1) and (t.f2 in [8..12]) and (cg_addr_locks[t.f2] = 1) and
          (not cg_addr_cache[t.f2].live or (cg_addr_cache[t.f2].obj = nil)) then
        a := t
      else begin
        get_temp_register(n, size, a);
        emit(0, size, a, t, size);
        unlock(t);
      end;
    end;
    1, 2, 4: begin
      load_operand(n, size, t);
      if (t.f1 = 1) and (t.f2 in [0..7]) and (cg_addr_locks[t.f2] = 1) and
          (not cg_addr_cache[t.f2].live or (cg_addr_cache[t.f2].obj = nil)) then
        a := t
      else begin
        get_temp_register(n, size, a);
        emit(0, size, a, t, size);
        unlock(t);
      end;
    end;
    6, 7: begin
      address(n, size, t);
      if (t.f1 = 13) and (t.f2 in [16..23]) and
          (not cg_addr_cache[t.f2].live or (cg_addr_cache[t.f2].obj = nil)) then
        a := t
      else begin
        get_temp_register(n, size, a);
        emit(0, size, a, t, size);
        unlock(t);
      end;
    end;
    otherwise
      cgerr_no_source(28, integer32(token_$make_string_token('Invalid result length')));
  end;
end;

{ load_indexreg - the index n of class size loaded (load_operand), its
  register a's index register; f5 bit 1 (a long index) for 4 and 5.

  0x0F13B8, 0x44 bytes, no A5 load (its caller's): `bset #1,(9,A2)'. }

procedure load_indexreg(
    n: il_$node_ptr_t;
    size: integer;
    in out a: codegen_$uads_t); options(val_param); internal;
var
  t: codegen_$uads_t;
begin
  if (size = 4) or (size = 5) then
    a.f5 := a.f5 ! 2;
  load_operand(n, size, t);
  a.f3 := t.f2;
end;

{ load_dereference - the operand (An) of the address n: n's address
  register as it is (inquire); a data register holding it given up
  (unlocked, its record emptied); a register holding a temporary of
  n's address (a 138 of operator 26 whose opnd[1] is n, loaded) copied
  into a new register for n; else n loaded (load_operand).

  0x0F13FC, 0x12A bytes, no A5 load (its caller's): the records' loop
  over A0..A7 (`dbf' of 8) skipped for 153 and 154; the record's
  pointers stored with `move.l #0'. }

procedure load_dereference(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t); options(val_param); internal;
var
  t: codegen_$uads_t;
  r: integer;
begin
  inquire(n, 5, a);
  if a.f1 = 1 then begin
    if a.f2 in [8..15] then begin
      a.f1 := 2;
      return;
    end;
    unlock(a);
    cg_addr_regs[a.f2].obj := nil;
    cg_addr_regs[a.f2].obj2 := nil;
  end;
  if (n^.kind <> 154) and (n^.kind <> 153) then
    for r := 8 to 15 do
      with cg_addr_regs[r] do
        if (size = 5) and (obj <> nil) then
          if (obj^.kind = 138) and (cg_tree_ptr_t(obj)^.op = 26) and
              (cg_tree_ptr_t(obj)^.opnd[1] = n) and (w14 = 0) then begin
            address(obj, 5, t);
            t.f1 := 2;
            unlock(t);
            get_register(n, 5, a);
            emit(0, 5, a, t, 0);
            a.f1 := 2;
            return;
          end;
  load_operand(n, 5, a);
  a.f1 := 2;
end;

{ load_dindex - the operand of the indexed reference n (145: base +24,
  displacement +32, index +36 of class +42 scaled by +40): with a free
  data register or the index in one, a constant index folded into the
  displacement when it fits 8 bits (or -CPU 3, M020) as d(An), else
  d(An,Xn) with the index loaded; with no free data register, a
  constant index fitting 16 bits as d(An), else the sum formed in the
  base's register (the constant added, 1), or the index pushed on the
  stack and added to the base scale times, the displacement added.

  0x0F1526, 0x312 bytes, no A5 load (its caller's): the constants' set
  0x0EF922 (register_tickle's); M020 `btst #5,0x2C3671'; the 16-bit
  test `cmpi.l #32767; bge' (32767 itself excluded: kept); the adds'
  loop `subq.w #2; bmi' and `dbf' (scale - 1 times); load_modifiable's
  size the word 5 at 0x0F1838.

  Not known from the original:
  - the flag (small) for the folded displacement's path. }

procedure load_dindex(
    n: il_$node_ptr_t;
    out a: codegen_$uads_t); options(val_param); internal;
var
  sp: codegen_$uads_t;
  c: codegen_$uads_t;
  t: codegen_$uads_t;
  i: il_$node_ptr_t;
  d: integer32;
  k: integer;
  small: boolean;
begin
  if dfree or (peek(n^.xp[9], n^.xw[21]) in [0..7]) then begin
    i := n^.xp[9];
    small := false;
    if i^.kind in [77..87, 101, 200] then begin
      d := lshft(i^.xl[2], n^.xw[20]) + n^.xl[8];
      if (3 in cargs_$options.cpu) or ((d >= -128) and (d < 128)) then begin
        a.f1 := 2;
        a.y := d;
        small := true;
      end;
    end;
    if not small then begin
      a.f1 := 4;
      a.y := n^.xl[8];
      load_indexreg(n^.xp[9], n^.xw[21], a);
      a.f4 := n^.xw[20];
    end;
    load_dereference(n^.xp[6], t);
    a.f2 := t.f2;
    return;
  end;
  i := n^.xp[9];
  if i^.kind in [77..87, 101, 200] then begin
    d := lshft(i^.xl[2], n^.xw[20]) + n^.xl[8];
    if (3 in cargs_$options.cpu) or ((d >= -32768) and (d < 32767)) then begin
      load_dereference(n^.xp[6], a);
      a.y := d;
      return;
    end;
    if not ((n^.xp[6]^.kind = 154) or (n^.xp[6]^.kind = 153)) then
      load_dereference(n^.xp[6], a);
    a.f1 := 1;
    if (n^.xp[6]^.kind = 154) or (n^.xp[6]^.kind = 153) then
      load_modifiable(n^.xp[6], 5, a);
    anyconst(d, 4, t);
    emit(1, 4, a, t, 0);
    kill_register(a.f2);
    unlock(t);
  end
  else begin
    address_reg(15, sp);
    sp.f1 := 9;
    address(n^.xp[9], n^.xw[21], t);
    unlock(t);
    if (8 in cargs_$options.cpu) and (t.f1 = 13) then
      emit_assign(n^.xw[21], sp, t)
    else
      emit(0, n^.xw[21], sp, t, 0);
    sp.f1 := 2;
    load_modifiable(n^.xp[6], 5, a);
    c := a;
    c.f1 := 2;
    c.y := 0;
    emit(0, 5, a, c, 0);
    for k := 2 to lshft(1, n^.xw[20]) do
      emit(1, n^.xw[21], a, sp, 0);
    sp.f1 := 8;
    emit(1, n^.xw[21], a, sp, 0);
    if n^.xl[8] <> 0 then begin
      anyconst(n^.xl[8], 5, t);
      emit(1, 5, a, t, 0);
      unlock(t);
    end;
    kill_register(a.f2);
  end;
  a.f1 := 2;
end;

{ makedeferred - the operand (An) of a value a (a register operand) or
  of n's address: an address register locked once more; else n's
  address register (peek A0..A4: inquire), or a moved into a new
  address register holding n (setresult).

  0x0F183A, 0xBA bytes: the copy of a at -24 (five `move.l'). }

procedure makedeferred(
    in out a: codegen_$uads_t;
    n: il_$node_ptr_t); options(val_param);
var
  t: codegen_$uads_t;
begin
  if (a.f1 = 1) and (a.f2 in [8..15]) then begin
    cg_addr_locks[a.f2] := cg_addr_locks[a.f2] + 1;
    a.f1 := 2;
  end
  else begin
    if peek(n, 5) in [8..12] then
      inquire(n, 5, a)
    else begin
      t := a;
      get_register(nil, 5, a);
      emit(0, 5, a, t, 0);
      setresult(a.f2, n, 5);
    end;
    a.f1 := 2;
  end;
end;

{ chk_addr - the register (A4 down to D0) that is the live home of a
  temporary (138 of operator 26) holding n's address (its opnd[1], or
  a temporary's owner), its operand in a; 31 none.

  0x0F18F4, 0x8A bytes: the flag in D1 cleared once and tested after
  each entry; `dbf' of 13 counting the register down from 12. }

function chk_addr;
var
  r: integer;
  found: boolean;
  o: il_$node_ptr_t;
begin
  chk_addr := 31;
  found := false;
  for r := 12 downto 0 do begin
    with cg_addr_cache[r] do
      if (obj <> nil) and live then
        if (obj^.kind = 138) and (cg_tree_ptr_t(obj)^.op = 26) then begin
          o := cg_tree_ptr_t(obj)^.opnd[1];
          if o^.kind = 152 then begin
            if n = o^.xp[4] then
              found := true;
          end
          else if n = o then
            found := true;
        end;
    if found then begin
      address_reg(r, a);
      chk_addr := r;
      return;
    end;
  end;
end;

{ address - the operand of n of class size (0 its address): cleared
  (f2, f3 31), then for size not 0 its register (inquire; with the
  PEB the PEB's register for cg_fp_in_peb, or for a single last stored,
  mode 11); a register's object a 190's or 189's; with no register a
  long kept in an address register (load_operand), a single in FP or
  data registers and the like.  Then by kind: constants immediate
  (3), routines and labels (7; a routine of the 3 form in the frame
  +108 off A6; 15 with -ABS), variables in the frame (A6) or the data
  (cg_data_reg) or absolute (12, 109 of class 11), a tree's temporary
  in the frame (when emitting; else the tree's +18 marked negative),
  references through chk_addr, makedeferred, load_dereference,
  load_dindex, the displacement folded (an address in a data register
  for a byte or word at +3/+2), ...; other kinds cgerr 3.  Last, for a
  memory operand (f2 above 7, not immediate or a label; not a 138)
  the phase flags in f5, and x n.

  0x0F197E, 0x8EE bytes: f2 and f3 stored as one longword
  (#0x001F001F); a jump table on kind - 77 (77..212); `cmpi.w #7,(2,A2);
  bls' (f2 unsigned) at the end; the PEB's set 0x0F09A2 (get_temp's);
  -ABS `btst #2,0x2C3673' (flags_286 element 7); M020 `btst
  #5,0x2C3671'; the 8-bit tests `bgt', `blt'; the routine's frame
  field `andi.w #0x180' of +376, `lsr.w #7'; the paths that end the
  routine early (189, 190, 110 of class 6, the loads) return.

  Not known from the original:
  - the IL fields (by offset). }

procedure address;
label
  tail;
var
  b: codegen_$uads_t;
  t: codegen_$uads_t;
  r: integer;
  m: il_$node_ptr_t;
  ph: add_node_$phase_t;
  d: integer32;
  k: integer;
begin
  a.f2 := 31;
  a.f3 := 31;
  a.f5 := 0;
  a.y := 0;
  a.f1 := 0;
  a.f4 := 0;
  a.f6 := 0;
  if size <> 0 then begin
    inquire(n, size, a);
    if (a.f1 = 0) and (1 in cargs_$options.cpu) then
      if check_use(cg_fp_in_peb, n) then begin
        if not (cg_fp_last_op in [1, 63, 83, 104, 149, 157, 159]) then
          test_peb_busy;
        cg_fp_last_op := 149;
        a.y := 149;
        a.f1 := 11;
        a.f5 := 5;
      end
      else if check_use(cg_fp_last_store, n) and (size = 6) then begin
        if not (cg_fp_last_op in [1, 63, 83, 104, 149, 157, 159]) then
          test_peb_busy;
        cg_fp_last_op := 63;
        a.y := 63;
        a.f1 := 11;
        a.f5 := 5;
      end;
  end;
  if (a.f1 = 1) and (a.x <> 0) then begin
    m := il_$node_ptr_t(a.x);
    case m^.kind of
      190: a.x := integer32(m^.xp[1]);
      189: a.x := integer32(m^.xp[5]);
      otherwise
    end;
  end
  else if a.f1 = 0 then
    case size of
      6:
        inquire(n, 4, a);
      5:
        if peek(n, 4) <> 31 then
          load_operand(n, 5, a);
      4:
        if peek(n, 5) <> 31 then
          load_operand(n, 4, a)
        else begin
          r := peek(n, 6);
          if r in [0..7] then
            address(n, 6, a)
          else if (r in [16..23]) and (cg_addr_regs[r].size = 6) then begin
            address(n, 6, t);
            get_temp_register(n, 4, a);
            if 8 in cargs_$options.cpu then
              emit_assign(6, a, t)
            else
              emit(0, 6, a, t, 6);
            unlock(t);
          end;
        end;
      otherwise
    end;
  if a.f1 <> 0 then
    goto tail;
  if size <> 0 then
    if (n^.kind = 109) or (n^.kind = 110) or (n^.kind = 138) or (n^.kind = 137) then
      for r := 0 to 23 do
        if cg_addr_cache[r].obj <> nil then
          if (cg_addr_cache[r].obj = n) and cg_addr_cache[r].live then
            cgerr(23, cg_line, n);
  case n^.kind of
    77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 92, 156, 198,
    200, 212:
      a.f1 := 3;
    105, 106:
      a.f1 := 7;
    107, 108, 167, 172:
      if rshft(n^.xw[188] & 16#180, 7) = 3 then begin
        a.f1 := 2;
        a.f2 := 14;
        a.y := n^.xl[27];
      end
      else if 7 in cargs_$options.flags_286 then
        a.f1 := 15
      else
        a.f1 := 7;
    109: begin
      a.f1 := 2;
      a.y := n^.xl[14];
      k := n^.xw[36];
      if k in [1, 4] then
        a.f2 := cg_data_reg
      else if k = 11 then begin
        a.f6 := 2;
        if (a.y >= -32768) and (a.y <= 32767) then
          a.f6 := 1;
        a.f1 := 12;
      end
      else
        a.f2 := 14;
      cg_addr_used[a.f2] := true;
    end;
    110:
      if rshft(ord(n^.xc[44]) & 16#F0, 4) = 6 then begin
        address(n^.xp[12], size, a);
        return;
      end
      else begin
        a.f1 := 2;
        k := rshft(ord(n^.xc[11]) & 16#F0, 4);
        if k in [1, 4] then
          a.f2 := cg_data_reg
        else
          a.f2 := 14;
        a.y := n^.xl[3];
        cg_addr_used[a.f2] := true;
      end;
    137, 138, 143: begin
      if n^.kind <> 137 then begin
        if (cg_tree_ptr_t(n)^.op = 16) and (cg_tree_ptr_t(n)^.desc.rlen = 9) then begin
          address(cg_tree_ptr_t(n)^.opnd[2], 0, a);
          goto tail;
        end;
        if (size = 4) and (peek(n, 5) <> 31) then begin
          load_operand(n, 4, a);
          return;
        end;
        if (size = 5) and (peek(n, 4) <> 31) then begin
          load_operand(n, 5, a);
          return;
        end;
      end;
      a.f1 := 2;
      a.f2 := 14;
      if at_backend_506 then begin
        m := cg_tree_ptr_t(n)^.opnd[1];
        if (m^.kind <> 152) or
            ((delay_378[size] > m^.xl[2]) and ((size <= 8) or (size = 12))) then
          cgerr(14, cg_line, n);
        a.y := cg_tree_ptr_t(n)^.opnd[1]^.xl[1];
      end
      else if cg_tree_ptr_t(n)^.w18 > 0 then
        cg_tree_ptr_t(n)^.w18 := -cg_tree_ptr_t(n)^.w18;
    end;
    190: begin
      address(n^.xp[1], size, a);
      return;
    end;
    189: begin
      address(n^.xp[5], size, a);
      return;
    end;
    147: begin
      r := chk_addr(n, a);
      if r <> 31 then begin
        makedeferred(a, cg_addr_cache[r].obj);
        goto tail;
      end;
      if peek(n^.xp[6], 5) <> 31 then begin
        d := n^.xl[8];
        if ((d = 2) and (size = 2)) or ((d = 3) and (size = 1)) then begin
          address(n^.xp[6], 5, t);
          unlock(t);
          get_temp_register(n, 4, a);
          emit(0, 4, a, t, 0);
          goto tail;
        end;
      end;
      address(n^.xp[6], 0, a);
      if (3 in cargs_$options.cpu) or (a.f1 <> 4) or
          ((a.y + n^.xl[8] <= 127) and (a.y + n^.xl[8] >= -128)) then
        a.y := a.y + n^.xl[8]
      else begin
        unlock(a);
        get_temp_register(n^.xp[6], 5, b);
        emit(22, 4, b, a, 0);
        b.f1 := 2;
        b.y := a.y + n^.xl[8];
        a := b;
      end;
    end;
    146: begin
      r := chk_addr(n, a);
      if r <> 31 then begin
        makedeferred(a, cg_addr_cache[r].obj);
        goto tail;
      end;
      if (7 in cargs_$options.flags_286) and (n^.xp[6]^.kind = 195) and
          (n^.xp[6]^.xw[10] in [1..3]) then begin
        inquire(n^.xp[6], 5, a);
        if a.f1 = 0 then
          a.f1 := 15
        else
          a.f1 := 2;
      end
      else
        load_dereference(n^.xp[6], a);
    end;
    145: begin
      r := chk_addr(n, a);
      if r <> 31 then
        makedeferred(a, cg_addr_cache[r].obj)
      else
        load_dindex(n, a);
    end;
    164:
      address(n^.xp[5], 0, a);
    152: begin
      a.f1 := 2;
      a.f2 := 14;
      a.y := n^.xl[1];
    end;
    165: begin
      a.f1 := 2;
      a.f2 := 14;
      a.y := n^.xl[4];
    end;
    153:
      address_reg(14, a);
    154:
      address_reg(cg_data_reg, a);
    155: begin
      address_reg(9, a);
      cg_addr_locks[9] := cg_addr_locks[9] + 1;
    end;
    163: begin
      a.f1 := 2;
      a.y := n^.xl[4];
      if ord(n^.xc[20]) = 0 then
        a.f2 := 14
      else
        a.f2 := cg_data_reg;
      cg_addr_used[a.f2] := true;
    end;
    195:
      a.f1 := 3;
    183, 192:
      a.f1 := 15;
    144: begin
      if ord(n^.xc[74]) >= 128 then
        a.f5 := a.f5 ! 1;
      a.f1 := 7;
    end;
    otherwise
      cgerr(3, cg_line, n);
  end;
tail:
  if a.f2 > 7 then
    if not (a.f1 in [3, 7]) and (n^.kind <> 138) then begin
      ph := getphase(n);
      if 1 in ph then
        a.f5 := a.f5 ! 1
      else if 2 in ph then
        a.f5 := a.f5 ! 1;
      if (3 in ph) or (4 in ph) then
        a.f5 := a.f5 ! 5;
    end;
  a.x := integer32(n);
end;

{ load_result - tree n's result register: one of its operands (1..k;
  operand -k alone when k is not positive) moved into a register for
  n.  The first or second operand when the tree's flags (+6 bits 14,
  13: they may be the result) and its marked register (+6 bit 10, +10)
  say it is there; else among the operands those in registers (kept
  locked meanwhile) the first that is a dead temporary (weight 16000),
  else a small constant (moved with moveq: -128..0, 9..127 for add or
  subtract, 1..127 else), else the lightest (taken when its weight is
  15000 or less, else copied), else the first copied.  The chosen
  operand is swapped into opnd[1] when k is positive; a copy is
  moved (emit_assign with the FPA) into get_register's register, else
  the operand's register is taken (inquire); the register locked,
  holding n (setresult, setobjcache).

  0x0F226C, 0x44E bytes: the choice as a signed index (negative: copy;
  `neg.w'); the registers in a longword set at -28 (`bset', `not.l;
  and.l'; locked and unlocked by `btst' over 0..31); the constant's
  tests `blt', `ble', `bgt', `bge'; the weights compared unsigned;
  `cmpi.w #2; bls' (the class unsigned).  The test of the first
  choice under the constant's (0x0F243A) is always false: kept.

  Not known from the original:
  - whether the dead test is the original's. }

procedure load_result;
label
  chosen;
var
  t: codegen_$uads_t;
  regs: cg_regset_t;
  best: integer;
  cst: integer;
  wbest: integer;
  wreg: integer;
  lo: integer;
  hi: integer;
  i: integer;
  r: integer;
  w: integer;
  sel: integer;
  rlen: integer;
  v: integer32;
  o: il_$node_ptr_t;
  x: il_$node_ptr_t;
begin
  regs := [];
  best := 0;
  cst := 0;
  wreg := 0;
  wbest := 32767;
  rlen := cg_tree_ptr_t(n)^.desc.rlen;
  if ((n^.xw[3] & 16#4000) <> 0) and ((k = -1) or (k > 0)) and
      ((n^.xw[3] & 16#400) <> 0) and (n^.xw[5] <> 31) then
    if peek(cg_tree_ptr_t(n)^.opnd[1], rlen) = n^.xw[5] then begin
      best := 1;
      goto chosen;
    end;
  if ((n^.xw[3] & 16#2000) <> 0) and ((k > 1) or (k = -2)) and
      ((n^.xw[3] & 16#400) <> 0) and (n^.xw[5] <> 31) then
    if peek(cg_tree_ptr_t(n)^.opnd[2], rlen) = n^.xw[5] then begin
      best := 2;
      goto chosen;
    end;
  if k > 0 then begin
    lo := 1;
    hi := k;
  end
  else begin
    lo := -k;
    hi := -k;
  end;
  for i := lo to hi do begin
    r := peek(cg_tree_ptr_t(n)^.opnd[i], rlen);
    if r <> 31 then begin
      regs := regs + [r];
      w := weight(r);
      if w = 16000 then begin
        if best = 0 then
          best := i;
      end
      else if w < wbest then begin
        wbest := w;
        wreg := i;
      end;
    end
    else begin
      o := cg_tree_ptr_t(n)^.opnd[i];
      if (o^.kind in [77..87, 101, 200]) and (cst = 0) then begin
        v := o^.xl[2];
        if (v >= -128) and (v <= 0) then
          cst := i
        else if (v <= 127) and (cg_tree_ptr_t(n)^.op = 1) and (v >= 9) then
          cst := i
        else if (v <= 127) and (cg_tree_ptr_t(n)^.op = 2) and (v >= 9) then
          cst := i
        else if (v <= 127) and (v > 0) and
            (cg_tree_ptr_t(n)^.op <> 1) and (cg_tree_ptr_t(n)^.op <> 2) then
          cst := i;
      end;
    end;
  end;
chosen:
  if best <> 0 then
    sel := best
  else if cst <> 0 then begin
    if best <> 0 then begin
      if (rlen <= 2) or (rlen = 5) then
        sel := best
      else if ((n^.xw[3] & 16#400) <> 0) and
          (peek(cg_tree_ptr_t(n)^.opnd[best], rlen) = n^.xw[5]) then
        sel := best
      else
        sel := -cst;
    end
    else
      sel := -cst;
  end
  else if wreg <> 0 then begin
    if wbest > 15000 then
      sel := -wreg
    else
      sel := wreg;
  end
  else
    sel := -lo;
  i := abs(sel);
  if (i <> 1) and (k > 0) then begin
    x := cg_tree_ptr_t(n)^.opnd[1];
    cg_tree_ptr_t(n)^.opnd[1] := cg_tree_ptr_t(n)^.opnd[i];
    cg_tree_ptr_t(n)^.opnd[i] := x;
    i := 1;
  end;
  if sel < 0 then begin
    o := cg_tree_ptr_t(n)^.opnd[i];
    if (rlen = 4) and (peek(o, 4) = 31) and (peek(o, 5) <> 31) then
      address(o, 5, t)
    else if (rlen = 5) and (peek(o, 5) = 31) and (peek(o, 4) <> 31) then
      address(o, 4, t)
    else
      address(o, rlen, t);
    if t.f1 in [1, 13] then
      regs := regs - [t.f2];
    release(t);
    if regs <> [] then
      for r := 0 to 31 do
        if r in regs then
          cg_addr_locks[r] := cg_addr_locks[r] + 1;
    get_register(n, rlen, a);
    if (8 in cargs_$options.cpu) and ((t.f1 = 13) or (a.f1 = 13)) then
      emit_assign(rlen, a, t)
    else
      emit(0, rlen, a, t, 0);
    if regs <> [] then
      for r := 0 to 31 do
        if r in regs then
          cg_addr_locks[r] := cg_addr_locks[r] - 1;
    unlock(a);
  end
  else begin
    inquire(cg_tree_ptr_t(n)^.opnd[i], rlen, a);
    release(a);
  end;
  cg_addr_locks[a.f2] := cg_addr_locks[a.f2] + 1;
  setresult(a.f2, n, rlen);
  setobjcache(n, a.f2);
end;

{ anyconst - the operand of the integer constant value (smcontk 81) of
  size size: a register holding it (inquire), or a data register
  holding a wider constant whose low size bytes are the same (inquire
  of that constant at its own size), else the immediate.

  0x0F26BA, 0x0C6 bytes: the mask `moveq #-1; lsl.l' by size * 8,
  `not.l'; `cmp.w (298,A0),D4; bcc' (the sizes unsigned); the
  constant's node kept at -8. }

procedure anyconst;
var
  c: il_$node_ptr_t;
  mask: integer32;
  r: integer;
begin
  c := smcontk(81, value);
  inquire(c, size, a);
  if a.f1 = 0 then begin
    mask := ~lshft(-1, size * 8);
    for r := 0 to 7 do
      if size < cg_addr_regs[r].size then
        if cg_addr_regs[r].obj <> nil then
          if cg_addr_regs[r].obj^.kind = 81 then
            if (cg_addr_regs[r].obj^.xl[2] & mask) = (value & mask) then begin
              inquire(cg_addr_regs[r].obj, cg_addr_regs[r].size, a);
              return;
            end;
    address(c, 0, a);
  end;
end;

{ load_fp_result - load_result for a floating tree: the operands'
  classes from fp_rlen (the descriptor's own for operator 41), only
  singles and doubles in floating registers counted, no constants;
  the copy by emit_assign with the FPA (of the class +26 for operator
  39), else emit with the operand's class as x.

  0x0F2780, 0x32C bytes: the registers' set in D6 (cleared after the
  first two tests); the floating registers locked and unlocked over
  16..23 (`dbf' of 8); the operand released before the locks (unlike
  load_result). }

procedure load_fp_result;
label
  chosen;
var
  t: codegen_$uads_t;
  regs: cg_regset_t;
  best: integer;
  wbest: integer;
  wreg: integer;
  lo: integer;
  hi: integer;
  i: integer;
  r: integer;
  w: integer;
  c: integer;
  sel: integer;
  rlen: integer;
  x: il_$node_ptr_t;
begin
  best := 0;
  wreg := 0;
  wbest := 32767;
  rlen := cg_tree_ptr_t(n)^.desc.rlen;
  if ((n^.xw[3] & 16#4000) <> 0) and ((k > 0) or (k = -1)) and
      ((n^.xw[3] & 16#400) <> 0) and (n^.xw[5] <> 31) then
    if peek(cg_tree_ptr_t(n)^.opnd[1], rlen) = n^.xw[5] then begin
      best := 1;
      goto chosen;
    end;
  if ((n^.xw[3] & 16#2000) <> 0) and ((k > 0) or (k = -2)) and
      ((n^.xw[3] & 16#400) <> 0) and (n^.xw[5] <> 31) then
    if peek(cg_tree_ptr_t(n)^.opnd[2], rlen) = n^.xw[5] then begin
      best := 2;
      goto chosen;
    end;
  if k > 0 then begin
    lo := 1;
    hi := k;
  end
  else begin
    lo := -k;
    hi := -k;
  end;
  regs := [];
  for i := lo to hi do begin
    if cg_tree_ptr_t(n)^.op = 41 then
      c := rlen
    else
      c := fp_rlen(cg_tree_ptr_t(n)^.desc, i);
    if (c = 6) or (c = 7) then begin
      r := peek(cg_tree_ptr_t(n)^.opnd[i], c);
      if r in [16..23] then begin
        regs := regs + [r];
        w := weight(r);
        if w = 16000 then begin
          if best = 0 then
            best := i;
        end
        else if w < wbest then begin
          wbest := w;
          wreg := i;
        end;
      end;
    end;
  end;
chosen:
  if best <> 0 then
    sel := best
  else if wreg <> 0 then begin
    if wbest > 15000 then
      sel := -wreg
    else
      sel := wreg;
  end
  else
    sel := -lo;
  i := abs(sel);
  if (i <> 1) and (k > 0) then begin
    x := cg_tree_ptr_t(n)^.opnd[1];
    cg_tree_ptr_t(n)^.opnd[1] := cg_tree_ptr_t(n)^.opnd[i];
    cg_tree_ptr_t(n)^.opnd[i] := x;
    i := 1;
  end;
  if sel < 0 then begin
    if cg_tree_ptr_t(n)^.op = 41 then
      c := rlen
    else
      c := fp_rlen(cg_tree_ptr_t(n)^.desc, i);
    address(cg_tree_ptr_t(n)^.opnd[i], c, t);
    release(t);
    if t.f1 = 13 then
      regs := regs - [t.f2];
    if regs <> [] then
      for r := 16 to 23 do
        if r in regs then
          cg_addr_locks[r] := cg_addr_locks[r] + 1;
    get_register(n, rlen, a);
    if 8 in cargs_$options.cpu then begin
      if cg_tree_ptr_t(n)^.op = 39 then
        emit_assign(cg_tree_ptr_t(n)^.desc.w6, a, t)
      else
        emit_assign(rlen, a, t);
    end
    else
      emit(0, rlen, a, t, c);
    if regs <> [] then
      for r := 16 to 23 do
        if r in regs then
          cg_addr_locks[r] := cg_addr_locks[r] - 1;
    unlock(a);
  end
  else begin
    inquire(cg_tree_ptr_t(n)^.opnd[i], rlen, a);
    release(a);
  end;
  cg_addr_locks[a.f2] := cg_addr_locks[a.f2] + 1;
  setresult(a.f2, n, rlen);
  setobjcache(n, a.f2);
end;

{ merge_state - the current register state merged into label lab's
  (cgerr 15 at the first pass for a label of +72 bit 6 with a copy at
  +68): without a state one is taken (runbackend_08's free list, else
  gspace: 396 bytes, kind 180, with the floating registers (-CPU 2, 4,
  8, 9 or 10), else 264, 161), not reached, the next registers and the
  records copied; else each record merged (merge_register).  With -C 2
  the label listed (show_label).

  0x0F2BA8, 0x1A8 bytes: the floating test `andi.w #0x3FFC' of the word
  +0x284, `lsr.w #2; andi.w #0x714' (cpu elements 2, 4, 8, 9, 10); the
  records copied as three longwords and a word... four longwords
  (`move.l (A0)+,(A3)+' times 3, `move.l (A0),(A3)'); the next
  registers' low bytes (+0x2B9, +0x2B7); -C `andi.b #6' of +0x27D. }

procedure merge_state;
var
  s: cg_state_ptr_t;
  r: integer;

  { merge_register - register r's record of a label's state merged
    with the current one (reached: the label's state was reached; a
    change then leaves cg_settled false): the object kept when the
    register still holds it in the class (its state the larger),
    else marked not loaded (2) when reached, else dropped; the second
    object kept when the register still has it, or taken as the
    object (not reached, no object) when it now is the register's
    object of a state not 0.

    0x0F2AAC, 0xFC bytes, no A5 load (its parent's): `cmp.w (14,A0),D3;
    bls' (the states unsigned). }

  procedure merge_register(
      r: integer;
      in out reg: cg_reg_t;
      reached: boolean); options(val_param);
  begin
    if reg.obj <> nil then
      if (cg_addr_regs[r].size = reg.size) and
          ((reg.obj = cg_addr_regs[r].obj) or (reg.obj = cg_addr_regs[r].obj2)) then begin
        if cg_addr_regs[r].w14 > reg.w14 then begin
          if (cg_addr_regs[r].w14 = 2) and reached then
            cg_settled := false;
          reg.w14 := cg_addr_regs[r].w14;
        end;
      end
      else if reached then begin
        if reg.w14 <> 2 then begin
          reg.w14 := 2;
          cg_settled := false;
        end;
      end
      else
        reg.obj := nil;
    if reg.obj2 <> nil then
      if reg.size <> cg_addr_regs[r].size then
        reg.obj2 := nil
      else if reg.obj2 <> cg_addr_regs[r].obj2 then
        if reg.obj2 <> cg_addr_regs[r].obj then
          reg.obj2 := nil
        else if cg_addr_regs[r].w14 <> 0 then begin
          if not reached and (reg.obj = nil) then begin
            reg.obj := reg.obj2;
            reg.w14 := cg_addr_regs[r].w14;
          end;
          reg.obj2 := nil;
        end;
  end;

begin
  if (cg_pass = 1) and odd(rshft(ord(lab^.xc[72]), 6)) and (lab^.xp[17] <> nil) then
    cgerr(15, cg_line, lab);
  if lab^.xp[16] = nil then begin
    if runbackend_08 = nil then begin
      if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then begin
        lab^.xp[16] := gspace(396);
        lab^.xp[16]^.kind := 180;
      end
      else begin
        lab^.xp[16] := gspace(264);
        lab^.xp[16]^.kind := 161;
      end;
    end
    else begin
      lab^.xp[16] := runbackend_08;
      runbackend_08 := lab^.xp[16]^.xp[2];
    end;
    s := cg_state_ptr_t(lab^.xp[16]);
    s^.b7 := false;
    s^.b4 := chr(cg_addr_next_dreg & 16#FF);
    s^.b6 := chr(cg_addr_next_areg & 16#FF);
    for r := 0 to 15 do
      s^.regs[r] := cg_addr_regs[r];
    if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then begin
      s^.w266 := cg_addr_next_freg;
      for r := 16 to 23 do
        s^.fp_regs[r] := cg_addr_regs[r];
    end;
  end
  else begin
    s := cg_state_ptr_t(lab^.xp[16]);
    for r := 0 to 15 do
      merge_register(r, s^.regs[r], s^.b7);
    if cargs_$options.cpu * [2, 4, 8, 9, 10] <> [] then
      for r := 16 to 23 do
        merge_register(r, s^.fp_regs[r], s^.b7);
  end;
  if cargs_$options.c = 2 then
    show_label(lab);
end;

{ cg_addr_$merge_state_of_assigned_goto_targets - n (a goto through a
  label variable, 150; else cgerr 28) merges the state into the label
  of each successor of its basic block (+16; cgerr 28 when it has none
  and the optimizer ran, else nothing).

  0x0F2D50, 0xBA bytes: the messages varying constants at 0x0F2E0A and
  0x0F2E52; with no block and the optimizer the loop runs on nil (the
  image's: kept); the successors at the block's +108 (from 1, `(-4,A0,
  D4.l)') and +106; a successor's +84 its first statement. }

procedure cg_addr_$merge_state_of_assigned_goto_targets;
var
  b: il_$node_ptr_t;
  i: integer;
begin
  if not assert_is_nlbranch(n) then
    cgerr(28, cg_line, token_$make_string_token(
        'CG_ADDR$MERGE_STATE_OF_ASSIGNED_GOTO_TARGETS -- not a nlbranch node'));
  b := n^.xp[4];
  if b = nil then begin
    if not assert_optimizer_is_enabled then
      return;
    cgerr(28, cg_line, token_$make_string_token(
        'CG_ADDR$MERGE_STATE_OF_ASSIGNED_GOTO_TARGETS -- nlbranch has no link to basic block'));
  end;
  for i := 1 to b^.xw[53] do
    if assert_is_label_node(addr_blocks_ptr_t(b^.xp[27])^[i]^.xp[21]) then
      merge_state(addr_blocks_ptr_t(b^.xp[27])^[i]^.xp[21]);
end;

{ cg_addr_$init_regs - the registers forgotten (only the floating ones
  when keep): unlocked, records emptied (class 5 for A0..A7, 6 for the
  floating registers, else 4); without keep the next data and address
  registers D0 and A0 and the floating unit's variables cleared; the
  next floating register FP0.

  0x0F2EAA, 0xC2 bytes: keep by address read once (`move.b (A0),D0');
  the record's +12 longword cleared (w12 and w14 together); `move.w #0'
  for the lock and w8. }

procedure cg_addr_$init_regs;
var
  r: integer;
begin
  if not keep then begin
    cg_addr_next_dreg := 0;
    cg_addr_next_areg := 8;
    cg_fp_last_store := nil;
    cg_fp_in_peb := nil;
    cg_fp_result := nil;
  end;
  cg_addr_next_freg := 16;
  for r := 0 to 23 do
    if not keep or (r in [16..23]) then begin
      cg_addr_locks[r] := 0;
      with cg_addr_regs[r] do begin
        obj := nil;
        w12 := 0;
        w14 := 0;
        obj2 := nil;
        w8 := 0;
        if r in [8..15] then
          size := 5
        else if r in [16..23] then
          size := 6
        else
          size := 4;
      end;
    end;
end;

{ edit_register - a label's record reg of register r checked: a tree
  value (143, 138) no longer used, or another object but the constants
  and variables (the set), dropped; a variable (110, 109) as second
  object taken as the object when there is none, or when it is the
  register's home variable of the record's class, or when the object
  is neither the home's variable nor a tree value; the second object
  dropped; the object dropped unless it is the register's home
  variable; with no home, an object marked 1.

  0x0F2F6C, 0xE0 bytes: the set after the code (0x0F304C: 77..89, 101,
  109, 110, 163, 200); the tree test `seq', `or.b', `bmi'. }

procedure edit_register;
var
  o2: il_$node_ptr_t;
  k: integer;
begin
  if reg.obj <> nil then begin
    k := reg.obj^.kind;
    if (k = 143) or (k = 138) then begin
      if cg_tree_ptr_t(reg.obj)^.uses = 0 then
        reg.obj := nil;
    end
    else if not (k in [77..89, 101, 109, 110, 163, 200]) then
      reg.obj := nil;
  end;
  if reg.obj2 <> nil then begin
    o2 := reg.obj2;
    if (o2^.kind = 110) or (o2^.kind = 109) then
      if reg.obj = nil then begin
        reg.obj := o2;
        reg.w14 := 0;
      end
      else if ((cg_addr_cache[r].obj = o2) and (reg.size = cg_addr_cache[r].size)) or
          ((reg.obj <> cg_addr_cache[r].obj) and
           not ((reg.obj^.kind = 143) or (reg.obj^.kind = 138))) then begin
        reg.obj := reg.obj2;
        reg.w14 := 0;
      end;
  end;
  reg.obj2 := nil;
  if cg_addr_cache[r].obj <> nil then begin
    if cg_addr_cache[r].obj <> reg.obj then
      reg.obj := nil;
  end
  else if reg.obj <> nil then
    reg.w14 := 1;
end;
