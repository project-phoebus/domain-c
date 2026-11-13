{ reg_action - the register allocator's loads and stores: for each
  live range given a register, statements of kind 191 put before or
  after the statements at the range's edges, each holding up to eight
  actions (load the value into the register, store it back to memory)
  in the order the code generator must do them; the constants of
  Fortran's evaluations given registers become trees (op 26) of their
  own, and the ranges that got none have their constants put back.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C241C  --------  assert_fortran_lvalue_not_in_areg
    0x0C246A  --------  replace_parent_with_use
    0x0C24FC  --------  nextrealstmt
    0x0C254E  --------  insert_stmt
    0x0C261E  --------  alloc_stmt
    0x0C26C4  --------  add_actions
    0x0C283E  --------  act
    0x0C28DC  --------  mechanism
    0x0C2A20  --------  killonpath
    0x0C2BC0  --------  do_register_actions
    0x0C369A  --------  insert_reg_stmts
    A5 0x2D2558 (cc.m68k): the module's data, 20 bytes: +0 the
    descriptor (add_node_$desc_t) of the trees insert_reg_stmts builds,
    initialized size 4, register class 5 (`00 00 00 04 00 05'); +0x10
    .. +0x13 zero and not addressed.

  Only insert_reg_stmts loads A5 (global, reg_alloc.ins.pas); the
  others are internal, do_register_actions nested in insert_reg_stmts
  and killonpath in do_register_actions (it reads its parent's range
  and actions through the dynamic link).

  Actions (a 191 statement's acts, g_opt.ins.pas's g_opt_act_t): bit 0
  load, 1 load from a Fortran constant's address (an address register
  not allowed), 3 and 5 stores (3 at a block's exit, 5 after the
  value's assignment), 8 = 3 alone; add_actions puts a store before
  the load of the same register and value.

  Not known from the original: the names of the module's variable, the
  locals and the parameters; why alloc_stmt asks gspace for 336 bytes
  an action where an action takes 12.

  dpc gaps (docs/dpc-gaps.md): 2 (mechanism's kinds as an if chain), 8
  (`in' on the node kind sets).
}
module reg_action;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';

type
  { A routine block (107, 108, 167) from +392: the parameters'
    passing classes, by number (mechanism). }
  ra_rtn_t = record
    unused_0: array [0..195] of integer;  { +0 }
    classes: array [0..63] of integer;  { +392 }
  end;
  ra_rtn_ptr_t = ^ra_rtn_t;

var
  desc: add_node_$desc_t := [size := 4, rlen := rlen_addr, w6 := 0, w8 := 0,
                             flags := [b7 := false, signed := false,
                                       b5 := false, b4 := false,
                                       b3 := false, b2 := false,
                                       b1 := false, b0 := false,
                                       b11 := 0],
                             unused_12 := 0];  { +0 }

define
  insert_reg_stmts;

{ assert_fortran_lvalue_not_in_areg - r is a Fortran constant (146,
  147) of a variable or array (+28: 110 or 111) not given an address
  register class (flags element 2).

  0x0C241C, 0x4E bytes, link #-8: the result in D0 (`seq' of the
  flag's `btst'). }

function assert_fortran_lvalue_not_in_areg(
    r: reg_range_ptr_t): boolean; options(val_param); internal;
var
  t: il_$node_ptr_t;
begin
  assert_fortran_lvalue_not_in_areg := false;
  if r^.node <> nil then begin
    t := r^.node;
    if (t^.kind = disp_node) or (t^.kind = ptr_node) then
      if t^.xp[7] <> nil then
        if (t^.xp[7]^.kind = common_block_name)
            or (t^.xp[7]^.kind = fortran_symbol) then
          assert_fortran_lvalue_not_in_areg := not (2 in r^.flags);
  end;
end;

{ replace_parent_with_use - operand k of the evaluation (139) s
  becomes cse parent p when p is assigned at s, else p's use at s.

  0x0C246A, 0x92 bytes: s and k words, p a pointer; the two stores
  share their code. }

procedure replace_parent_with_use(
    s: reg_num_t;
    k: integer;
    p: g_opt_cse_ptr_t); options(val_param); internal;
var
  u: g_opt_cse_ptr_t;
begin
  if p^.kind = cse_parent_ob then
    if opt_4009c[s]^.kind = eval_node then
      if p^.p_stmt^.hdr.region = s then
        opt_4009c[s]^.eval_opnd[k] := il_$node_ptr_t(p)
      else begin
        u := p^.p_uses;
        while u <> nil do begin
          if u^.u_ent^.hdr.region = s then begin
            opt_4009c[s]^.eval_opnd[k] := il_$node_ptr_t(u);
            exit;
          end;
          u := u^.u_next;
        end;
      end;
end;

{ nextrealstmt - the first statement from s on that is not a call
  (188); runbackend_16 when none.

  0x0C24FC, 0x52 bytes: the result in D0, runbackend_16 loaded first. }

function nextrealstmt(
    s: reg_num_t): reg_num_t; options(val_param); internal;
var
  k: reg_num_t;
begin
  nextrealstmt := runbackend_16;
  for k := s to runbackend_16 do
    if opt_4009c[k]^.kind <> use_def_ob then begin
      nextrealstmt := k;
      exit;
    end;
end;

{ insert_stmt - link n before s, with s's +4..+25 (its line and block)
  and flags but for the first and last marks, no region; before a label
  (144) that starts a block n ends the block before (its last), else
  n starts s's block.

  0x0C254E, 0xD0 bytes: the copy `move.l' five times and a `move.w';
  the flags of +41..+42 merged into one `andi.w #0x200A; ori.w #0x2000'
  of the word (docs/rev889-patterns.md 10), the region (+43) cleared
  with the longword +42 (`andi.l #0xFF0000FF'); the line
  spos_$null_position. }

procedure insert_stmt(
    s: g_opt_stmt_ptr_t;
    n: g_opt_stmt_ptr_t); options(val_param); internal;
type
  head_t = array [1..11] of integer;    { +4..+25 }
  head_ptr_t = ^head_t;
var
  p: g_opt_stmt_ptr_t;
begin
  head_ptr_t(addr(n^.prev))^ := head_ptr_t(addr(s^.prev))^;
  p := s^.prev;
  p^.next := n;
  n^.prev := p;
  n^.next := s;
  s^.prev := n;
  n^.hdr.b7 := false;
  n^.hdr.b6 := false;
  n^.hdr.b5 := true;
  n^.hdr.b4 := false;
  n^.hdr.b3 := false;
  n^.hdr.counted := false;
  n^.hdr.no_prune := false;
  n^.hdr.deleted := false;
  n^.hdr.b42_7 := false;
  n^.hdr.b42_6 := false;
  n^.hdr.kills := false;
  n^.hdr.b42_4 := false;
  n^.hdr.b42_2 := false;
  n^.hdr.entry := false;
  n^.line := spos_$null_position;
  if (s^.kind = label_node) and s^.hdr.first then begin
    n^.prev^.hdr.last := false;
    n^.hdr.first := false;
    n^.hdr.last := true;
  end
  else begin
    n^.hdr.last := false;
    s^.hdr.first := false;
  end;
  n^.hdr.region := 0;
end;

{ alloc_stmt - a new 191 statement of n actions, none used.

  0x0C261E, 0x9A bytes: gspace(n * 336 + 50) (`lsl.w #4', the
  products added); each action copied from a 12-byte constant after
  the routine (nil, registers 31 and 31, 0, 0); s by address. }

procedure alloc_stmt(
    n: integer;
    out s: g_opt_stmt_ptr_t); options(val_param); internal;
var
  k: integer;
begin
  s := gspace(n * 336 + 50);
  if s = nil then
    cgerr_no_source(9, 0);
  s^.kind := reg_list_ob;
  s^.act_count := 0;
  s^.acts[1].node := nil;
  s^.acts[1].reg := 31;
  s^.acts[1].reg2 := 31;
  s^.acts[1].rlen := rlen_null;
  s^.acts[1].action := 0;
  for k := 2 to n do
    s^.acts[k] := s^.acts[1];
end;

{ add_actions - add action a of range r to the 191 statement s (none
  when s has it already); a full statement (8) gets a new one after it,
  or before it when a store goes before a load s holds; a store goes
  before the load of the same value and register (the load moved to
  the end).

  0x0C26C4, 0x17A bytes, link #-20: the actions indexed by a 12-byte
  stride from +40; `a & 40' and `& 3' of the action words. }

procedure add_actions(
    r: reg_range_ptr_t;
    s: g_opt_stmt_ptr_t;
    a: integer); options(val_param); internal;
var
  k: integer;
  n: g_opt_stmt_ptr_t;
  pos: integer;
begin
  for k := 1 to s^.act_count do
    if s^.acts[k].node <> nil then
      if s^.acts[k].node = r^.node then
        if s^.acts[k].reg = r^.reg then
          if a = s^.acts[k].action then
            return;
  if s^.act_count = 8 then begin
    alloc_stmt(8, n);
    if (a & 40) <> 0 then begin
      for k := 1 to s^.act_count do begin
        if (s^.acts[k].node = r^.node) and (s^.acts[k].reg = r^.reg) and
           ((s^.acts[k].action & 3) <> 0) then begin
          insert_stmt(s, n);
          exit;
        end;
        if k = s^.act_count then
          insert_stmt(s^.next, n);
      end;
    end
    else
      insert_stmt(s^.next, n);
    s := n;
  end;
  pos := s^.act_count + 1;
  if s^.act_count > 0 then
    if (a & 40) <> 0 then
      for k := 1 to s^.act_count do
        if (s^.acts[k].node = r^.node) and (s^.acts[k].reg = r^.reg) and
           ((s^.acts[k].action & 3) <> 0) then begin
          s^.acts[s^.act_count + 1] := s^.acts[k];
          pos := k;
          exit;
        end;
  s^.act_count := s^.act_count + 1;
  s^.acts[pos].node := r^.node;
  s^.acts[pos].reg := r^.reg;
  s^.acts[pos].reg2 := r^.w24;
  s^.acts[pos].rlen := r^.rlen;
  s^.acts[pos].action := a;
end;

{ act - action a of range r in the 191 statement s, which when it is
  not one is made and put before t (or the first statement after t
  that general_opts did not delete).

  0x0C283E, 0x9E bytes: s by value and replaced (alloc_stmt gets its
  slot's address); r passed on as a longword. }

procedure act(
    r: reg_range_ptr_t;
    a: integer;
    s: g_opt_stmt_ptr_t;
    t: g_opt_stmt_ptr_t); options(val_param); internal;
var
  k: reg_num_t;
begin
  if s^.kind <> reg_list_ob then begin
    alloc_stmt(8, s);
    k := t^.hdr.region;
    if k <> 0 then
      if opt_4009c[k]^.hdr.deleted then begin
        repeat
          k := k + 1;
        until not opt_4009c[k]^.hdr.deleted;
        t := opt_4009c[k];
      end;
    insert_stmt(t, s);
  end;
  add_actions(r, s, a);
end;

{ mechanism - how argument k of the call c passes to the routine t: 7
  by value, 2 by reference, else the class the routine declares (a
  Fortran routine's argument by reference, a C function's by value);
  11 counts as 3.  A Fortran constant (146, 147) is followed to its
  variable (+28) unless C's (122), a 175 to its +20.

  0x0C28DC, 0x144 bytes: the kinds tested in a compare chain (dpc gap
  2); 159's classes the low nibbles of the words at +8 (`and.b
  (9,A2,D1.w)'); 173 and 174's the words at +76; the routines' (107,
  108, 167) the words at +392; any other kind cgerr_no_source(0, t)
  and D0 as it is; paramclass of abs(k) - 1 for a variable (109) of
  class other than 1 passed to 171. }

function mechanism(
    t: il_$node_ptr_t;
    k: integer;
    c: il_$node_ptr_t): integer; options(val_param); internal;
var
  m: integer;
  lang: integer;
begin
  m := 7;
  repeat
    if (t^.kind = disp_node) or (t^.kind = ptr_node) then begin
      if (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 3) and
         (t^.xp[7]^.kind = integer_type) then begin
        m := 2;
        exit;
      end;
      t := t^.xp[7];
    end
    else if t^.kind = lib_dsc then begin
      m := ord(t^.xc[9 + 2 * k]) & 15;
      exit;
    end
    else if t^.kind = fortran_symbol then
      exit
    else if (t^.kind = function_blk) or (t^.kind = procedure_blk)
        or (t^.kind = entry_blk) then begin
      lang := rshft(ord(t^.xc[377]) & 16#70, 4);
      if lang = 2 then
        m := 7
      else if lang = 3 then
        m := 2
      else if lang = 4 then
        m := 7
      else
        m := ra_rtn_ptr_t(t)^.classes[k];
      exit;
    end
    else if t^.kind = pf_call then
      t := t^.xp[5]
    else if t^.kind = cc_call then begin
      m := 2;
      exit;
    end
    else if (t^.kind = func__type) or (t^.kind = proc__type) then begin
      m := t^.xw[38 + k];
      exit;
    end
    else begin
      cgerr_no_source(0, integer32(t));
      return;
    end;
  until false;
  if m = 11 then
    m := 3;
  if t^.kind = cc_call then
    if c^.xp[12]^.kind = var_name then
      if (c^.xp[12]^.xw[36] = 1) or (paramclass(c^.xp[14], abs(k) - 1) = 4) then
        m := 7;
  mechanism := m;
end;

{ insert_reg_stmts - the loads and stores of the n ranges r^[1..n].

  0x0C369A, 0x2D2 bytes, link #-28: the ranges by a 64-byte stride; a
  range given no register (31) of a Fortran constant evaluated (139) in
  a loop's block has the evaluation's operand put back: its cse parent
  or use, the tree under its constants (their uses counted down), or
  the integer 0 (smcontk); a variable's range marks its node (109:
  +33 bit 2, 110: +25 bit 2); a Fortran constant's in such an
  evaluation, in C (or a 145, or of an address register), becomes the
  tree buildtreenode(26, desc, its range, 1) of the range's class,
  whose +4..+15 are then copied onto themselves (`lea (4,A0),A1; lea
  (4,A0),A4'), and replaces the constant among the operands. }

procedure insert_reg_stmts(
    r: reg_ranges_ptr_t;
    n: integer);
var
  k: integer;
  j: integer;
  rr: reg_range_ptr_t;
  st: g_opt_stmt_ptr_t;
  t: il_$node_ptr_t;
  x: il_$node_ptr_t;

  { do_register_actions - the actions of range r, of variable v: its
    register taken from the registers free over its blocks; then over
    each block (or the statements from its first to its block's end),
    at each statement s: a load at the range's entry (the loop's
    first block: after a label, else before s) for a constant or a
    strength reduction temporary, before s's assignment of v when s
    uses the old value, a cse parent's at its assignment; a store
    after the last use of a strength reduction temporary; at the
    statements where the range is live: a call's (188) argument passed
    by reference loaded back, the store of v after its assignment (and
    at the block's exit, killonpath) when it must reach memory. }

  procedure do_register_actions(
      r: reg_range_ptr_t;
      v: integer); options(val_param);
  var
    store: boolean;
    b: reg_blk_ptr_t;
    s1: reg_num_t;
    s2: reg_num_t;
    s: reg_num_t;
    q: reg_num_t;
    cls: integer;
    how: integer;
    st: g_opt_stmt_ptr_t;
    x: g_opt_stmt_ptr_t;
    nb: g_opt_block_ptr_t;
    j: integer;

    { killonpath - the store of r's register on the edge from the
      block of s (its last statement) into block b when r does not
      reach b: the store at the block's end (pending, how element 3)
      once, before s (or after a Fortran label of class 4, a new 191
      statement taking over the block's first mark), then how at b's
      start (after its labels).

      0x0C2A20, 0x1A0 bytes, link #-20: the parent's frame from the
      dynamic link (`move.l (A6),D4'): r its (8), how its (-36). }

    procedure killonpath(
        s: g_opt_stmt_ptr_t;
        b: g_opt_block_ptr_t); options(val_param);
    var
      k: reg_num_t;
      x: g_opt_stmt_ptr_t;
      n: g_opt_stmt_ptr_t;
    begin
      if b = nil then
        return;
      k := b^.first_stmt^.hdr.region;
      if k = 0 then begin
        x := s^.next;
        while x^.hdr.region = 0 do
          x := x^.next;
        k := x^.hdr.region;
      end;
      if test_stmt(r, 2 * k) then
        return;
      if (how & 8) <> 0 then begin
        if (s^.kind = label_node) and
           (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2) and
           (rshft(ord(il_$node_ptr_t(s)^.xc[72]) & 16#3E, 1) = 4) then begin
          x := s^.next;
          if x^.kind <> reg_list_ob then begin
            alloc_stmt(8, n);
            x := n;
            insert_stmt(s^.next, n);
          end;
          if x <> nil then
            if x^.hdr.first then begin
              x^.hdr.first := false;
              x^.next^.hdr.first := true;
            end;
        end
        else begin
          x := s^.prev;
          if x^.kind <> reg_list_ob then begin
            alloc_stmt(8, n);
            x := n;
            insert_stmt(s, n);
          end;
        end;
        add_actions(r, x, 8);
        how := how & ~8;
      end;
      x := b^.first_stmt;
      while x^.kind = label_node do
        x := x^.next;
      if x^.kind = reg_list_ob then
        n := x
      else if x^.prev^.kind = reg_list_ob then
        n := x^.prev
      else begin
        alloc_stmt(8, n);
        insert_stmt(x, n);
      end;
      add_actions(r, n, how);
    end;

  begin
    b := r^.blocks;
    if b = nil then
      opt_4009c[r^.first]^.block^.regs := opt_4009c[r^.first]^.block^.regs - [r^.reg]
    else
      repeat
        g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.regs :=
          g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.regs - [r^.reg];
        b := b^.next;
      until b = nil;

    { Whether the value must be stored back. }
    if r^.node^.kind = var_name then begin
      if (r^.node^.xw[36] = 2) or
         ((r^.node^.xw[36] = 1) and (il_180^.kind = program_blk)) or
         (r^.node^.xw[36] = 5) then
        store := false
      else
        store := 8 in r^.flags;
      if r^.node^.xw[36] = 1 then
        if il_180^.kind <> program_blk then
          store := true;
    end
    else if r^.node^.kind = fortran_symbol then begin
      cls := rshft(ord(r^.node^.xc[11]) & 16#F0, 4);
      if (cls in [0, 2]) or
         ((rshft(ord(r^.node^.xc[11]) & 16#F0, 4) = 1) and
          (il_180^.kind = program_blk)) then
        store := false
      else
        store := 8 in r^.flags;
      if rshft(ord(r^.node^.xc[11]) & 16#F0, 4) = 1 then
        if il_180^.kind <> program_blk then
          store := true;
    end
    else
      store := false;

    b := r^.blocks;
    if b = nil then begin
      s1 := r^.first;
      s2 := opt_4009c[r^.last]^.block^.last_stmt^.hdr.region;
    end;
    repeat
      if b <> nil then begin
        nb := g_opt_blocks_ptr_t(il_11c)^[b^.bnum];
        s1 := nb^.first_stmt^.hdr.region;
        s2 := nb^.last_stmt^.hdr.region;
      end;
      if b <> nil then begin
        if s2 = 0 then
          s2 := g_opt_blocks_ptr_t(il_11c)^[b^.bnum + 1]^.first_stmt^.hdr.region;
      end
      else if s2 = 0 then
        if s1 <= runbackend_16 then
          for q := s1 to runbackend_16 do
            if opt_4009c[q]^.block <> opt_4009c[s1]^.block then begin
              s2 := q;
              exit;
            end;
      if (s1 = 0) and (b <> nil) then
        if b^.bnum <> 1 then begin
          x := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.first_stmt^.prev;
          while x^.hdr.region = 0 do
            x := x^.prev;
          s1 := x^.hdr.region;
        end
        else begin
          x := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.first_stmt^.next;
          while x^.hdr.region = 0 do
            x := x^.next;
          s1 := x^.hdr.region;
        end;
      if s1 <= s2 then
        for s := s1 to s2 do begin
          st := opt_4009c[s];

          { A constant's load at the loop's entry. }
          if r^.node^.kind in [real_ob..dpreal_ob, tree_node..gen_tree_node,
                               dindex_node..disp_node, addr_con,
                               reloc_absolute_addr_con] then
            if not test_stmt(r, 2 * (s - 1) + 1) then
              if st^.block^.flags.latch then begin
                if r^.node^.kind in [tree_node..gen_tree_node,
                                     dindex_node..disp_node] then
                  how := 1
                else
                  how := 3;
                if assert_fortran_lvalue_not_in_areg(r) then
                  how := how ! 2;
                if (st^.block^.first_stmt = st)
                    and (st^.kind = label_node) then
                  act(r, how, st^.next, st^.next)
                else
                  act(r, how, st^.prev, st);
              end;

          { A strength reduction temporary's load at the loop's entry. }
          if il_utils_$is_strength_reduction_temp(r^.node) then
            if test_stmt(r, 2 * s) then
              if not test_stmt(r, 2 * (s - 1) + 1) then
                if st^.block^.flags.latch then begin
                  how := 1;
                  if (st^.block^.first_stmt = st)
                      and (st^.kind = label_node) then
                    act(r, how, st^.next, st^.next)
                  else
                    act(r, how, st^.prev, st);
                end;

          { The value's load before its assignment at s. }
          if st^.hdr.vnum = v then
            if test_stmt(r, 2 * s + 1) then
              if not test_stmt(r, 2 * s) then begin
                if (v <> 0) and (st^.vars^[v]^.du <> nil) and
                   (((st^.vset <> nil) and (v in st^.vset^)) or
                    (st^.kind = use_def_ob)) then
                  how := 3
                else
                  how := 1;
                act(r, how, st^.prev, st);
              end;
          if (r^.node^.kind = fortran_symbol)
              or (r^.node^.kind = var_name) then
            if (st^.hdr.vnum = v) and (v > 0) then
              if test_stmt(r, 2 * s + 1) then
                if test_stmt(r, 2 * s) then
                  if (opt_4009c[s]^.vars^[v]^.flags & 16#200) <> 0 then
                    if not test_stmt(r, 2 * s - 1) then
                      if opt_4009c[s]^.block^.flags.latch then
                        if opt_4009c[s]^.next <> nil then
                          if opt_4009c[s]^.next^.hdr.region = 0 then begin
                            how := 1;
                            act(r, how, st^.prev, st);
                          end;

          { A cse parent's load at its assignment. }
          if r^.node^.kind = cse_parent_ob then
            if g_opt_cse_ptr_t(r^.node)^.p_stmt^.hdr.region = s then
              act(r, 1, st^.prev, st);

          { A strength reduction temporary's store after its last use. }
          if il_utils_$is_strength_reduction_temp(r^.node) then
            if test_stmt(r, 2 * (s - 1) + 1) then
              if not test_stmt(r, 2 * s) then
                act(r, 32, st^.next, st^.next);

          if test_stmt(r, 2 * s) then begin
            if v <> 0 then
              if st^.hdr.vnum = v then
                if st^.kind = use_def_ob then
                  if test_stmt(r, 2 * s + 1) then
                    if test_stmt(r, 2 * s) then
                      if st^.vars^[v]^.du <> nil then
                        act(r, 3, st^.prev, st);
            if store then
              how := 40
            else
              how := 32;
            if st^.vset <> nil then
              if v in st^.vset^ then begin
                { A call's argument passed by reference. }
                if st^.kind = use_def_ob then begin
                  if il_$node_ptr_t(st)^.xw[30] > 0 then
                    if mechanism(il_$node_ptr_t(st)^.xp[14]^.xp[10],
                                 il_$node_ptr_t(st)^.xw[30],
                                 il_$node_ptr_t(st)) >= 6 then
                      if (8 in r^.flags) or
                         (il_$node_ptr_t(st)^.xp[14]^.xp[10]^.kind = lib_dsc) then
                        act(r, 8, st^.prev, st);
                  q := nextrealstmt(s);
                  if test_stmt(r, 2 * s + 1) then
                    if not st^.hdr.last then
                      if not test_stmt(r, 2 * q + 1) then begin
                        x := opt_4009c[q];
                        if x^.block = st^.block then
                          if not x^.hdr.last then
                            act(r, 32, x^.next, x^.next);
                      end;
                end;

                { A variable the routine's callers may read. }
                cls := rshft(ord(r^.node^.xc[11]) & 16#F0, 4);
                if (((r^.node^.kind = var_name) and
                     (r^.node^.xw[36] in [1, 3, 4, 7, 8, 10, 11])) or
                    ((r^.node^.kind = fortran_symbol) and
                     (cls in [1, 3, 4, 7, 8, 10, 11]))) and
                   (il_180^.kind <> program_blk) then
                  if not test_stmt(r, 2 * s + 1) then begin
                    if st^.prev^.kind = reg_list_ob then
                      act(r, 8, st^.prev, st^.prev)
                    else
                      act(r, 8, st, st);
                  end
                  else if find_var(r^.node) = st^.hdr.vnum then
                    act(r, 8, st^.next, st^.next);
                how := how & ~8;
                if not test_stmt(r, 2 * s + 1) then
                  if not st^.hdr.last then
                    act(r, how, st^.next, st^.next);
              end;

            { A constant's store where the range ends. }
            if r^.node^.kind in [real_ob..dpreal_ob, tree_node..gen_tree_node,
                                 dindex_node..disp_node, addr_con,
                                 cse_parent_ob, reloc_absolute_addr_con] then
              if not test_stmt(r, 2 * (s + 1)) then
                if not st^.hdr.last then begin
                  if assert_fortran_lvalue_not_in_areg(r) then
                    how := how ! 8;
                  act(r, how, st^.next, st^.next);
                end;

            { The block's exits. }
            if st^.hdr.last then begin
              nb := st^.block;
              if assert_fortran_lvalue_not_in_areg(r) then
                how := how ! 8;
              for j := 1 to nb^.nsucc do
                killonpath(st, nb^.succ^[j]);
            end;
          end;
        end;
      if b <> nil then
        b := b^.next;
    until b = nil;
  end;

begin
  for k := 1 to n do begin
    rr := addr(r^[k]);
    if rr^.reg = 31 then begin
      if (rr^.node^.kind = dindex_node) or (rr^.node^.kind = disp_node) or
         (rr^.node^.kind = ptr_node) then
        if opt_4009c[rr^.first]^.kind = eval_node then
          if opt_4009c[rr^.first]^.block^.flags.latch then begin
            g_opt_tree_ptr_t(rr^.node)^.uses := g_opt_tree_ptr_t(rr^.node)^.uses - 1;
            st := opt_4009c[rr^.first];
            for j := 1 to st^.eval_count do
              if st^.eval_opnd[j] = rr^.node then begin
                t := rr^.node^.xp[6];
                if t^.kind = cse_parent_ob then begin
                  if g_opt_cse_ptr_t(t)^.p_stmt^.hdr.region = rr^.first then
                    st^.eval_opnd[j] := t
                  else
                    replace_parent_with_use(rr^.first, j, g_opt_cse_ptr_t(t));
                end
                else if (t^.kind in [tree_node..gen_tree_node, cmp_tree_node,
                                     dindex_node..disp_node, cs_node, cc_call,
                                     pf_call, cse_use_ob,
                                     sym_disp_node])
                                         and (t^.kind <> cse_use_ob) then begin
                  x := t;
                  while (x^.kind = disp_node) or (x^.kind = ptr_node) do begin
                    g_opt_tree_ptr_t(x)^.uses := g_opt_tree_ptr_t(x)^.uses - 1;
                    x := x^.xp[6];
                  end;
                  if x^.kind in [tree_node..gen_tree_node, cmp_tree_node,
                                 dindex_node..disp_node, cs_node, cc_call,
                                 pf_call,
                                 cse_use_ob..cse_parent_ob, sym_disp_node] then
                    st^.eval_opnd[j] := x
                  else
                    st^.eval_opnd[j] := smcontk(integer_ob, 0);
                end
                else
                  st^.eval_opnd[j] := smcontk(integer_ob, 0);
                exit;
              end;
          end;
    end
    else if rr^.node^.kind = var_name then begin
      do_register_actions(rr, rr^.node^.xw[37]);
      rr^.node^.xc[33] := chr(ord(rr^.node^.xc[33]) ! 4);
    end
    else if rr^.node^.kind = fortran_symbol then begin
      do_register_actions(rr, rr^.node^.xw[8]);
      rr^.node^.xc[25] := chr(ord(rr^.node^.xc[25]) ! 4);
    end
    else if (rr^.node^.kind = dindex_node) or (rr^.node^.kind = ptr_node) or
            (rr^.node^.kind = disp_node) then begin
      if opt_4009c[rr^.first]^.kind = eval_node then
        if opt_4009c[rr^.first]^.block^.flags.latch then begin
          st := opt_4009c[rr^.first];
          if (rr^.node^.kind = dindex_node) or
             (rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2) or
             (2 in rr^.flags) then begin
            desc.rlen := rr^.rlen;
            rr^.node := buildtreenode(addr_top, desc, rr^, 1);
            g_opt_cse_ptr_t(rr^.node)^.u_hdr := g_opt_cse_ptr_t(rr^.node)^.u_hdr;
            for j := 1 to st^.eval_count do
              if g_opt_tree_ptr_t(rr^.node)^.opnd[1] = st^.eval_opnd[j] then
                st^.eval_opnd[j] := rr^.node;
          end;
        end;
      do_register_actions(rr, 0);
    end
    else
      do_register_actions(rr, 0);
  end;
end;
