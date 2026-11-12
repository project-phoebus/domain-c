{ reg_life - the m68k register allocator's live ranges: for each
  assignment of a variable (add_range), each cse parent (add_cse_ranges)
  and each constant a loop uses (add_con_range) a range (reg_alloc's
  reg_ranges^[reg_nranges], init_graph) whose bit vector gets the
  points from the definition to its uses (mark_stmts) and whose block
  list gets the blocks the value crosses (find_paths over the live
  variable sets, csepath back through the predecessors, the loop's
  blocks); ranges_intersect, combine_ranges and run_interference
  (add_conflict of each pair of one register class that meet).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C6CD4  --------  assert_is_use_def_at_call_site
    0x0C6CF2  --------  assert_block_on_list
    0x0C6D08  --------  add_block
    0x0C6D7E  --------  find_paths
    0x0C6F3E  --------  mark_stmts
    0x0C7074  --------  ranges_intersect
    0x0C7110  --------  combine_ranges
    0x0C72FA  --------  run_interference
    0x0C73FE  --------  init_graph
    0x0C74E2  --------  get_more_ranges
    0x0C7504  --------  find_next_numbered_stmt
    0x0C7544  --------  find_prev_numbered_stmt
    0x0C7584  --------  csepath
    0x0C7688  --------  add_cse_ranges
    0x0C7EC2  --------  add_range
    0x0C852E  --------  reg_life_$bnum_of_head_for_prehead
    0x0C8628  --------  add_con_range
    A5 0x2D2590 (cc.m68k): the unit has no data (its A5 is reg_vars's).

  find_paths, mark_stmts, ranges_intersect, combine_ranges,
  run_interference, get_more_ranges, add_cse_ranges, add_range and
  add_con_range load A5 (global; reg_alloc.ins.pas has those reg_alloc
  calls); the others are internal (the asserts and the numbered
  statement searches leaves without a frame, docs/rev889-patterns.md
  16).  The cells used are reg_alloc's (reg_alloc.ins.pas, reached
  absolutely: reg_pool, reg_ranges, reg_nranges, reg_nest, reg_words).

  Points: statement s has 2s (before it) and 2s + 1 (after it); a
  statement without a region number (0) stands for the nearest
  numbered one before (find_prev_numbered_stmt) or after it.  The live
  variable sets are opt_main's opt_live_out, opt_not_killed and
  opt_used, by block number (g_opt.ins.pas), the variable by its number
  (a variable's +74, a Fortran variable's +16).

  Not known from the original: the locals' and parameters' names; how
  the conditions were grouped (written as nested tests where a call
  would be a right operand, docs/dpc-gaps.md 24).
}
module reg_life;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';

type
  { A bit vector's longwords as integers (mark_stmts sets runs of
    bits by masks). }
  rl_longs_t = array [0..16383] of integer32;
  rl_longs_ptr_t = ^rl_longs_t;

  { What type_exp tells of a type, as get_rlen reads it (28 bytes; the
    optimizer's g_opt_vtype_t is passed the same way). }
  rl_texp_t = array [0..6] of integer32;

  { A list cell of a strength reduction temporary's record
    (reg_life_$bnum_of_head_for_prehead): a statement and the next. }
  rl_cell_ptr_t = ^rl_cell_t;
  rl_cell_t = record
    item: il_$node_ptr_t;               { +0 }
    next: rl_cell_ptr_t;                { +4 }
  end;

{ GET_RLEN - the register class of a value of type t.
  lang/c_compiler/source/c_get_rlen.pas 0x0532D8 (c_externs.ins.pas,
  which this unit does not open); D0. }
function get_rlen(
    in t: univ rl_texp_t): integer; extern;

define
  find_paths, mark_stmts, ranges_intersect, combine_ranges,
  run_interference, get_more_ranges, add_cse_ranges, add_range,
  add_con_range;

{ assert_is_use_def_at_call_site - whether s is a call's use and
  definition of a variable (188) with a tree at +56 (the call's: its
  owner (+12) is the call's statement).

  0x0C6CD4, 0x1E bytes: no frame; `sne'. }

function assert_is_use_def_at_call_site(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
begin
  if s <> nil then
    if s^.kind = 188 then begin
      assert_is_use_def_at_call_site := s^.br_cond <> nil;
      return;
    end;
  assert_is_use_def_at_call_site := false;
end;

{ assert_block_on_list - whether block b is on r's list.

  0x0C6CF2, 0x16 bytes: no frame; the byte onlist^[b] (b zero-extended)
  returned as it is. }

function assert_block_on_list(
    r: reg_range_ptr_t;
    b: reg_num_t): boolean; options(val_param); internal;
begin
  assert_block_on_list := r^.onlist^[b];
end;

{ add_block - block b put at the head of r's list (12 bytes from the end
  of reg_pool's free space, a new chunk first when fewer than 12 are
  left) and marked on r's onlist.

  0x0C6D08, 0x76 bytes: reg_pool reached absolutely (0x2D256C); r's +8
  reloaded for each store. }

procedure add_block(
    r: reg_range_ptr_t;
    b: reg_num_t); options(val_param); internal;
var
  old: reg_blk_ptr_t;
begin
  old := r^.blocks;
  if reg_pool^.free < 12 then
    initpool;
  reg_pool^.free := reg_pool^.free - 12;
  r^.blocks := addr(reg_pool^.data[reg_pool^.free]);
  r^.blocks^.next := old;
  r^.blocks^.bnum := b;
  r^.blocks^.cost := 0;
  r^.blocks^.b10 := false;
  r^.onlist^[b] := true;
end;

{ find_paths - the blocks variable v's value from statement s reaches,
  from block b: b is put on r's list; when v is live out of b and b
  is s's block or does not kill v, each successor that uses v, or
  through which v is live, is followed; a Fortran block without
  successors ending in a branch (150) leads to every block marked
  skip.

  0x0C6D7E, 0x1C0 bytes, link #-12: nothing when b is on the list;
  the sets' elements tested `btst' after `255 - v; lsr.w #3' (no
  range check); the successors by `dbf'; the language il_180's +377
  bits 6..4 (2); the skip blocks through il.pas's +0xC0 (0x169D30,
  docs/rev889-patterns.md 70). }

procedure find_paths(
    r: reg_range_ptr_t;
    v: integer;
    b: reg_num_t;
    s: integer); options(val_param);
var
  blk: g_opt_block_ptr_t;
  sb: g_opt_block_ptr_t;
  i: integer;
  k: g_opt_num_t;
begin
  if assert_block_on_list(r, b) then
    return;
  blk := g_opt_blocks_ptr_t(il_11c)^[b];
  add_block(r, b);
  if v = 0 then
    return;
  if not (v in opt_live_out^[b]) then
    return;
  if (opt_4009c[s]^.block^.num = b) or (v in opt_not_killed^[b]) then
    for i := 1 to blk^.nsucc do begin
      sb := blk^.succ^[i];
      if (v in opt_used^[sb^.num]) or
         ((v in opt_live_out^[sb^.num]) and
          (v in opt_not_killed^[sb^.num])) then
        find_paths(r, v, sb^.num, s);
    end;
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
    if blk^.nsucc = 0 then
      if blk^.last_stmt <> nil then
        if blk^.last_stmt^.kind = 150 then
          for k := opt_first_block to opt_last_block do
            if g_opt_blocks_ptr_t(il_11c)^[k]^.flags.skip then
              find_paths(r, v, k, s);
end;

{ mark_stmts - r covers the points p1..p2 (its first and last statements
  widened), or from p1 up to the point after the first statement on the
  way that ends its block with a branch other than to a label (149 not
  of 172) or is followed by a numbered statement.

  0x0C6F3E, 0x136 bytes, link #-16: the points unsigned (`lsr.w #1'
  for their statements, `bls'/`bhi' compares); the walk counts points
  (D1) and statements (D2, its opt_4009c offset in D0); the bits set
  by masks: the bit index p1 - 2 * opt_region + 34 (32 more than
  test_stmt's, its longword less one by `lea (-4,A1,D5.w)'), a first
  partial longword (`moveq #-1; lsl.l'), whole longwords of -1, a last
  partial one ((1 << n) - 1). }

procedure mark_stmts(
    p1: reg_num_t;
    p2: reg_num_t;
    r: reg_range_ptr_t); options(val_param);
var
  s: reg_num_t;
  k: reg_num_t;
  idx: reg_num_t;
  n: reg_num_t;
  b: reg_num_t;
  w: integer;
  mask: integer32;
  st: g_opt_stmt_ptr_t;
  lv: rl_longs_ptr_t;
begin
  s := rshft(p1, 1);
  if s > r^.first then
    s := r^.first;
  r^.first := s;
  s := rshft(p2, 1);
  if s <= r^.last then
    s := r^.last;
  r^.last := s;
  s := rshft(p1, 1);
  idx := p1 - opt_region - opt_region + 34;
  k := p1;
  while k <> p2 do begin
    if odd(k) then begin
      st := opt_4009c[s];
      if st^.hdr.last then begin
        if st^.kind = 149 then
          if st^.x48^.kind <> 172 then
            exit;
        if st^.next^.hdr.region <> 0 then
          exit;
      end;
      s := s + 1;
    end;
    k := k + 1;
  end;
  n := k - p1 + 1;
  lv := rl_longs_ptr_t(r^.live);
  w := rshft(idx, 5) - 1;
  b := idx & 31;
  if b <> 0 then begin
    if n + b > 32 then begin
      mask := lshft(-1, b);
      n := n - (32 - b);
    end
    else begin
      mask := lshft(-1, b);
      if n + b < 32 then
        mask := mask & ~lshft(-1, n + b);
      n := 0;
    end;
    lv^[w] := lv^[w] ! mask;
    w := w + 1;
  end;
  if n <> 0 then begin
    k := rshft(n, 5);
    while k <> 0 do begin
      lv^[w] := -1;
      w := w + 1;
      k := k - 1;
    end;
    n := n & 31;
    if n <> 0 then
      lv^[w] := lv^[w] ! (lshft(1, n) - 1);
  end;
end;

{ ranges_intersect - whether a and b share a point: their statements
  must overlap, then their bit vectors' longwords over the overlap
  (16 statements a longword) are compared from the last down.

  0x0C7074, 0x9C bytes, link #-12: unsigned compares; the longwords
  (s - opt_region + 1) div 16 + 1 (`lsr.w #4'); a `dbf' of the count
  with the index (D3) decremented; `st' on a common bit. }

function ranges_intersect;
var
  f: reg_num_t;
  lo: reg_num_t;
  hi: reg_num_t;
  i: reg_num_t;
begin
  ranges_intersect := false;
  f := b^.first;
  if f > a^.first then
    if f > a^.last then
      return;
  if f < a^.first then
    if a^.first > b^.last then
      return;
  lo := a^.first;
  if lo <= f then
    lo := f;
  lo := rshft(lo - opt_region + 1, 4) + 1;
  hi := a^.last;
  if hi > b^.last then
    hi := b^.last;
  hi := rshft(hi - opt_region + 1, 4) + 1;
  if hi >= lo then
    for i := hi downto lo do
      if a^.live^[i - 1] * b^.live^[i - 1] <> [] then begin
        ranges_intersect := true;
        return;
      end;
end;

{ combine_ranges - b joined to a: the statements spanned, the points,
  the blocks (b's list taken whole when a has none; a range without a
  list stands for its first statement's block), the onlist marks, the
  uses, definitions and flags; b emptied (node and list nil, no uses
  or definitions).

  0x0C7110, 0x1EA bytes, link #-16: b read as a longword into D2; the
  points or-ed by a `dbf' over reg_words (0x2D2578); the onlist bytes
  or-ed over il_124 (0x169D94) when a has a list; b's uses and
  definitions cleared by one `clr.l' of +34. }

procedure combine_ranges;
var
  i: integer;
  p: reg_blk_ptr_t;
begin
  if b^.first < a^.first then
    a^.first := b^.first;
  if b^.last > a^.last then
    a^.last := b^.last;
  for i := 1 to reg_words do
    a^.live^[i - 1] := a^.live^[i - 1] + b^.live^[i - 1];
  if b^.blocks = nil then begin
    if opt_4009c[a^.first]^.block <> opt_4009c[b^.first]^.block then
      if not assert_block_on_list(a, opt_4009c[b^.first]^.block^.num) then begin
        if a^.blocks = nil then
          add_block(a, opt_4009c[a^.first]^.block^.num);
        add_block(a, opt_4009c[b^.first]^.block^.num);
      end;
  end
  else if a^.blocks = nil then begin
    a^.blocks := b^.blocks;
    if not assert_block_on_list(a, opt_4009c[a^.first]^.block^.num) then
      add_block(a, opt_4009c[a^.first]^.block^.num);
  end
  else begin
    p := b^.blocks;
    while p <> nil do begin
      if not assert_block_on_list(a, p^.bnum) then
        add_block(a, p^.bnum);
      p := p^.next;
    end;
  end;
  if a^.blocks <> nil then
    for i := 1 to il_124 do
      a^.onlist^[i] := a^.onlist^[i] or b^.onlist^[i];
  b^.blocks := nil;
  b^.node := nil;
  a^.defs := a^.defs + b^.defs;
  a^.uses := a^.uses + b^.uses;
  a^.flags := a^.flags + b^.flags;
  b^.uses := 0;
  b^.defs := 0;
end;

{ run_interference - the conflicts of the n ranges r^[1..n]: for each
  register class (data 3, address 2, floating 4 when the -CPU has
  floating hardware: 160, 5700, FPA1, MATHLIB), each pair of ranges of
  the class whose points meet conflict both ways.

  0x0C72FA, 0x104 bytes, link #-16: the classes by a pass count (-8,
  -10) and a `case' of compare tests, the class in -2; cargs' -CPU word
  through A3 = 0x2C3664 (+12); the second range from n down to i + 1
  (D2), i = j tested; the flags' word `btst'. }

procedure run_interference;
var
  cls: integer;
  pass: integer;
  i: integer;
  j: integer;
begin
  for pass := 0 to 2 do begin
    case pass of
      0: cls := 3;
      1: cls := 2;
      2: begin
        if cargs_$options.cpu * [2, 4, 8..10] = [] then
          next;
        cls := 4;
      end;
    end;
    for i := 1 to n do
      if cls in r^[i].flags then
        for j := n downto i + 1 do
          if i <> j then
            if cls in r^[j].flags then
              if ranges_intersect(addr(r^[i]), addr(r^[j])) then begin
                add_conflict(addr(r^[i]), j);
                add_conflict(addr(r^[j]), i);
              end;
  end;
end;

{ init_graph - r as a new range numbered reg_nranges: empty, no
  register, with a bit vector of reg_words longwords and an onlist of
  il_124 bytes (from opt_main_20) cleared.

  0x0C73FE, 0xD0 bytes: +6..+25 copied from a 20-byte constant after
  the routine (0x0C74CE: zeros, then 31 for reg and w24); the depth
  (+44) is not cleared; a nil bit vector reported (cgerr_no_source(9,
  0)), a nil onlist not; the clearing loops by `dbf'. }

procedure init_graph(
    r: reg_range_ptr_t); options(val_param); internal;
var
  i: integer;
begin
  r^.node := nil;
  r^.num := reg_nranges;
  r^.degree := 0;
  r^.blocks := nil;
  r^.conflict.next := nil;
  r^.conflict.num := 0;
  r^.first := 0;
  r^.last := 0;
  r^.reg := 31;
  r^.w24 := 31;
  r^.prefer := [];
  r^.rlen := 0;
  r^.uses := 0;
  r^.defs := 0;
  r^.cost := 0;
  r^.priority := 0;
  r^.flags := [];
  r^.live := nil;
  r^.avail := [];
  r^.live := mem_$alloc(opt_main_20, reg_words * 4);
  if r^.live = nil then
    cgerr_no_source(9, 0);
  for i := 1 to reg_words do
    r^.live^[i - 1] := [];
  r^.onlist := mem_$alloc(opt_main_20, il_124);
  for i := 1 to il_124 do
    r^.onlist^[i] := false;
end;

{ get_more_ranges - more ranges than reg_alloc counted: reported.

  0x0C74E2, 0x22 bytes: cgerr_no_source(9, 0). }

procedure get_more_ranges;
begin
  cgerr_no_source(9, 0);
end;

{ find_next_numbered_stmt - s's region number, else the next numbered
  statement's (through +8).

  0x0C7504, 0x40 bytes: no frame; as reg_alloc's find_prev. }

function find_next_numbered_stmt(
    s: g_opt_stmt_ptr_t): integer; options(val_param); internal;
begin
  if s^.hdr.region = 0 then
    repeat
      s := s^.next;
    until (s = nil) or (s^.hdr.region <> 0);
  find_next_numbered_stmt := s^.hdr.region;
end;

{ find_prev_numbered_stmt - s's region number, else the previous
  numbered statement's (through +4).

  0x0C7544, 0x40 bytes: no frame. }

function find_prev_numbered_stmt(
    s: g_opt_stmt_ptr_t): integer; options(val_param); internal;
begin
  if s^.hdr.region = 0 then
    repeat
      s := s^.prev;
    until (s = nil) or (s^.hdr.region <> 0);
  find_prev_numbered_stmt := s^.hdr.region;
end;

{ csepath - range k's blocks from block b back to block a: b is put on
  the list, and when a dominates b its predecessors not on the list
  are followed.

  0x0C7584, 0x104 bytes, link #-16: the range reg_ranges^[k] reloaded
  for each call; add_block's arguments left for the epilogue on the
  a = b path. }

procedure csepath(
    a: reg_num_t;
    b: reg_num_t;
    k: integer); options(val_param); internal;
var
  blk: g_opt_block_ptr_t;
  i: integer;
begin
  if a = b then begin
    if not assert_block_on_list(addr(reg_ranges^[k]), b) then
      add_block(addr(reg_ranges^[k]), b);
  end
  else if dom(g_opt_blocks_ptr_t(il_11c)^[a],
              g_opt_blocks_ptr_t(il_11c)^[b]) then begin
    if not assert_block_on_list(addr(reg_ranges^[k]), b) then
      add_block(addr(reg_ranges^[k]), b);
    blk := g_opt_blocks_ptr_t(il_11c)^[b];
    for i := 1 to blk^.npreds do
      if not assert_block_on_list(addr(reg_ranges^[k]), blk^.pred[i]^.num) then
        csepath(a, blk^.pred[i]^.num, k);
  end;
end;

{ add_cse_ranges - a range for each cse parent made at statement s
  that may live in a register: its tree not flagged 1..4, not a 143,
  of register class below 8 (not 12; a floating class only with
  floating hardware), not a use-twice tree of op 16 or with an op 16
  operand (ops 63, 17, 0).  The range starts at s; each use whose
  block no other use's block dominates (or that no earlier use in its
  own block covers) is reached back through csepath; loops the blocks
  head (dominated by s's block, of another serial) are added whole.
  Then each block of the list is marked: in s's block, from s to each
  use (or to the block's end and from the use's block's start, for a
  use before s), the whole block when uses are in other blocks too; in
  a use's block, from its start to the last use (to its end when a
  successor is on the list), unless another use's block dominates it;
  other blocks whole.

  0x0C7688, 0x83A bytes, link #-68: the parents from s's +26 through
  +8 (-16), the range's end at -68 (reg_ranges + 64 * reg_nranges),
  crossing uses at -52, the uses' regions the bits 23..8 of their
  entry's +42; the classes compared 6, 7, 12, 8; the dominance and
  same-block searches start past the use itself, entered at their test
  (the nil test after the skip); the blocks of a loop marked once
  (+10); the per-block flags in D6 and -54; select_loop's result in A0. }

procedure add_cse_ranges;
var
  p: g_opt_cse_ptr_t;
  t: g_opt_tree_ptr_t;
  rr: reg_range_ptr_t;
  i: integer;
  bn: reg_num_t;
  cross: boolean;
  u: g_opt_cse_ptr_t;
  v: g_opt_cse_ptr_t;
  found: boolean;
  ub: reg_num_t;
  vb: reg_num_t;
  b: reg_blk_ptr_t;
  q: reg_blk_ptr_t;
  blk: g_opt_block_ptr_t;
  l: g_opt_block_ptr_t;
  ur: reg_num_t;
  from: reg_num_t;
  upto: reg_num_t;
  k: reg_num_t;
  last: reg_num_t;
  inb: boolean;
  domd: boolean;
  fb: reg_num_t;
  skip: boolean;
begin
  p := g_opt_cse_ptr_t(opt_4009c[s]^.cses);
  while p <> nil do begin
    t := g_opt_tree_ptr_t(p^.p_tree);
    skip := t^.flags * [1..4] <> [];
    if not skip then
      skip := t^.kind = 143;
    if not skip then
      if t^.kind = 137 then
        if (t^.rlen = 6) or (t^.rlen = 7) or (t^.rlen = 12) or (t^.rlen = 8) then
          skip := cargs_$options.cpu * [2, 4, 8..10] = [];
    if not skip then
      skip := (t^.rlen >= 8) or (t^.rlen = 12);
    if not skip then
      if t^.uses = 2 then begin
        if t^.op = 16 then
          skip := true
        else if (t^.op = 63) or (t^.op = 17) or (t^.op = 0) then
          for i := 1 to t^.count do
            if g_opt_tree_ptr_t(t^.opnd[i])^.kind = 137 then
              if g_opt_tree_ptr_t(t^.opnd[i])^.op = 16 then begin
                skip := true;
                exit;
              end;
      end;
    if not skip then begin
      reg_nranges := reg_nranges + 1;
      if reg_nranges > reg_nest then
        get_more_ranges;
      rr := addr(reg_ranges^[reg_nranges]);
      init_graph(rr);
      rr^.node := il_$node_ptr_t(p);
      rr^.first := s;
      rr^.rlen := t^.rlen;
      bn := opt_4009c[s]^.block^.num;
      add_block(rr, bn);
      u := p^.p_uses;
      cross := false;
      while u <> nil do begin
        v := p^.p_uses;
        if v = u then
          v := v^.u_next;
        found := false;
        ub := opt_4009c[u^.u_ent^.hdr.region]^.block^.num;
        if ub <> bn then
          cross := true;
        while v <> nil do begin
          vb := opt_4009c[v^.u_ent^.hdr.region]^.block^.num;
          if ub <> vb then
            if dom(g_opt_blocks_ptr_t(il_11c)^[ub],
                   g_opt_blocks_ptr_t(il_11c)^[vb]) then begin
              found := true;
              exit;
            end;
          if ub = vb then
            if u^.u_ent^.hdr.region <= v^.u_ent^.hdr.region then
              if assert_block_on_list(rr, ub) then begin
                found := true;
                exit;
              end;
          v := v^.u_next;
          if v = u then
            v := v^.u_next;
        end;
        if not found then
          csepath(bn, ub, reg_nranges);
        u := u^.u_next;
      end;
      b := rr^.blocks;
      while b <> nil do begin
        blk := g_opt_blocks_ptr_t(il_11c)^[b^.bnum];
        if blk^.flags.header and (blk^.num <> bn) then
          if dom(g_opt_blocks_ptr_t(il_11c)^[bn], blk) then begin
            l := select_loop(blk^.num);
            if l <> nil then
              if g_opt_blocks_ptr_t(il_11c)^[bn]^.serial <> l^.serial then
                while l <> nil do begin
                  if not assert_block_on_list(rr, l^.num) then
                    add_block(rr, l^.num);
                  q := rr^.blocks;
                  while q <> nil do begin
                    if (q^.bnum = l^.num) and not q^.b10 then begin
                      q^.b10 := true;
                      exit;
                    end;
                    q := q^.next;
                  end;
                  l := l^.link;
                end;
          end;
        b := b^.next;
      end;
      b := rr^.blocks;
      while b <> nil do begin
        last := 0;
        if b^.bnum = bn then begin
          if not cross then begin
            rr^.blocks := nil;
            u := p^.p_uses;
            while u <> nil do begin
              ur := u^.u_ent^.hdr.region;
              if ur >= s then begin
                from := s * 2;
                upto := ur * 2 + 1;
                if b^.b10 then
                  upto := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.last_stmt^.hdr.region * 2 + 1;
                if upto = 1 then
                  upto := upto + 2 * find_next_numbered_stmt(g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.last_stmt);
                mark_stmts(from, upto, rr);
              end
              else begin
                k := opt_4009c[ur]^.block^.last_stmt^.hdr.region;
                if k = 0 then
                  k := find_next_numbered_stmt(opt_4009c[ur]^.block^.last_stmt);
                upto := k * 2 + 1;
                from := s * 2;
                mark_stmts(from, upto, rr);
                k := opt_4009c[ur]^.block^.first_stmt^.hdr.region;
                if k = 0 then
                  from := 2 * find_prev_numbered_stmt(opt_4009c[ur]^.block^.first_stmt)
                else
                  from := k * 2;
                upto := ur * 2 + 1;
                mark_stmts(from, upto, rr);
              end;
              u := u^.u_next;
            end;
          end
          else begin
            from := s * 2;
            k := opt_4009c[s]^.block^.last_stmt^.hdr.region;
            if k = 0 then
              k := find_next_numbered_stmt(opt_4009c[s]^.block^.last_stmt);
            upto := k * 2 + 1;
            mark_stmts(from, upto, rr);
          end;
        end
        else begin
          u := p^.p_uses;
          inb := false;
          domd := false;
          while u <> nil do begin
            if b^.bnum = opt_4009c[u^.u_ent^.hdr.region]^.block^.num then begin
              inb := true;
              if u^.u_ent^.hdr.region > last then
                last := u^.u_ent^.hdr.region;
              v := p^.p_uses;
              fb := opt_4009c[v^.u_ent^.hdr.region]^.block^.num;
              while v <> nil do begin
                if v = u then
                  v := v^.u_next
                else if opt_4009c[v^.u_ent^.hdr.region]^.block =
                        opt_4009c[u^.u_ent^.hdr.region]^.block then
                  v := v^.u_next
                else begin
                  if dom(g_opt_blocks_ptr_t(il_11c)^[fb],
                         g_opt_blocks_ptr_t(il_11c)^[opt_4009c[u^.u_ent^.hdr.region]^.block^.num]) then
                    domd := true;
                  v := v^.u_next;
                end;
              end;
            end;
            u := u^.u_next;
          end;
          blk := g_opt_blocks_ptr_t(il_11c)^[b^.bnum];
          if inb and not domd then begin
            k := blk^.first_stmt^.hdr.region;
            if k = 0 then
              k := find_prev_numbered_stmt(blk^.first_stmt);
            from := k * 2;
            upto := last * 2 + 1;
            for i := 1 to blk^.nsucc do
              if not b^.b10 then
                if assert_block_on_list(rr, blk^.succ^[i]^.num) then
                  b^.b10 := true;
            if b^.b10 then
              upto := blk^.last_stmt^.hdr.region * 2 + 1;
            mark_stmts(from, upto, rr);
          end
          else if not (inb and domd) then begin
            k := blk^.first_stmt^.hdr.region;
            if k = 0 then
              k := find_prev_numbered_stmt(blk^.first_stmt);
            from := k * 2;
            k := g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.last_stmt^.hdr.region;
            if k = 0 then
              k := find_next_numbered_stmt(g_opt_blocks_ptr_t(il_11c)^[b^.bnum]^.last_stmt);
            upto := k * 2 + 1;
            mark_stmts(from, upto, rr);
          end;
        end;
        b := b^.next;
      end;
    end;
    p := p^.p_next;
  end;
end;

{ add_range - the range of variable v (its number in statement s's
  vars) from its assignment at s, when the value is used (its def-use
  chain): its node, first statement and register class (5 for a
  variable of class 5 or a Fortran variable of class 5, or 3 with +32;
  else get_rlen of the optimizer's record, or runbackend_18 by the size
  class).  When every use is in s's block and v is not live out of it
  past a later assignment in the block, the points from s (2s + 1, or
  2s when s also reads v) to each use (2u, or 2u + 1 when the use also
  assigns v; a call's use-def stands for its call statement), a use
  before s marked from the block's start and from s to the block's end.
  Otherwise find_paths gives the blocks, each marked: s's block from s
  to its end and from its start to each use before s; a block that
  uses v and does not carry it through, from its start to its last
  use; other blocks whole.

  0x0C7EC2, 0x66C bytes, link #-56: the variable's entry at -42, s
  sign-extended at -52 (the uses compared `cmp.l; ble'), the range's end
  at -46 (reg_ranges loaded before the count grows), the variable's
  number at -24, s's block at -8; the sets tested after the 255 range
  check (`bcs'); the vset test (s's +34) after its own range check; the
  later assignment searched s + 1 .. the block's last region by `dbf'. }

procedure add_range;
var
  e: g_opt_var_ptr_t;
  rr: reg_range_ptr_t;
  t: il_$node_ptr_t;
  vn: integer;
  blk: g_opt_block_ptr_t;
  cross: boolean;
  c: g_opt_chain_ptr_t;
  k: integer;
  us: reg_num_t;
  from: reg_num_t;
  from0: reg_num_t;
  upto: reg_num_t;
  last: reg_num_t;
  bn: reg_num_t;
  b: reg_blk_ptr_t;
  lb: g_opt_block_ptr_t;
  st: g_opt_stmt_ptr_t;
  whole: boolean;
begin
  e := opt_4009c[s]^.vars^[v];
  if e^.du = nil then
    return;
  reg_nranges := reg_nranges + 1;
  if reg_nranges > reg_nest then
    get_more_ranges;
  rr := addr(reg_ranges^[reg_nranges]);
  init_graph(rr);
  rr^.node := e^.node;
  rr^.first := s;
  t := rr^.node;
  if t^.kind = 109 then begin
    vn := t^.xw[37];
    if t^.xw[36] = 5 then
      rr^.rlen := 5
    else
      rr^.rlen := get_rlen(opt_var_types^[vn]);
  end
  else begin
    vn := t^.xw[8];
    if (rshft(ord(t^.xc[11]) & 16#F0, 4) = 5) or
       ((rshft(ord(t^.xc[44]) & 16#F0, 4) = 3) and (t^.xl[8] <> 0)) then
      rr^.rlen := 5
    else
      rr^.rlen := runbackend_18[ord(t^.xc[10]) & 15];
  end;
  blk := opt_4009c[s]^.block;
  cross := false;
  c := e^.du;
  while c <> nil do begin
    if blk <> c^.stmt^.block then begin
      cross := true;
      exit;
    end;
    c := c^.next;
  end;
  if not cross then
    if vn <= 255 then
      if vn in opt_live_out^[blk^.num] then begin
        cross := true;
        for k := s + 1 to blk^.last_stmt^.hdr.region do
          if opt_4009c[k]^.hdr.vnum = v then begin
            cross := false;
            exit;
          end;
      end;
  if not cross then begin
    from := s * 2;
    c := e^.du;
    while c <> nil do begin
      us := c^.stmt^.hdr.region;
      from0 := from;
      st := opt_4009c[s];
      if not ((st^.hdr.vnum = v) and (st^.vset <> nil) and (v in st^.vset^)) then
        from0 := from0 + 1;
      if assert_is_use_def_at_call_site(opt_4009c[us]) then
        us := g_opt_tree_ptr_t(opt_4009c[us]^.br_cond)^.owner^.hdr.region;
      upto := us * 2;
      st := opt_4009c[us];
      if (st^.hdr.vnum = v) and (st^.vset <> nil) and (v in st^.vset^) then
        upto := upto + 1;
      if us > s then
        mark_stmts(from0, upto, rr)
      else begin
        k := blk^.first_stmt^.hdr.region;
        if k = 0 then
          k := find_prev_numbered_stmt(blk^.first_stmt);
        mark_stmts(k * 2, upto, rr);
        k := blk^.last_stmt^.hdr.region;
        if k = 0 then
          k := find_next_numbered_stmt(blk^.last_stmt);
        mark_stmts(from0, k * 2 + 1, rr);
      end;
      c := c^.next;
    end;
    return;
  end;
  find_paths(rr, vn, blk^.num, s);
  b := rr^.blocks;
  while b <> nil do begin
    bn := b^.bnum;
    if bn <> blk^.num then begin
      lb := g_opt_blocks_ptr_t(il_11c)^[bn];
      from := lb^.first_stmt^.hdr.region * 2;
      if from = 0 then
        from := 2 * find_prev_numbered_stmt(lb^.first_stmt);
      whole := true;
      if vn <= 255 then
        if vn in opt_used^[bn] then
          if not (vn in opt_not_killed^[bn]) then
            whole := false
          else if not (vn in opt_live_out^[bn]) then
            whole := false;
      if not whole then begin
        last := 0;
        c := e^.du;
        while c <> nil do begin
          if c^.stmt^.block^.num = bn then
            if c^.stmt^.hdr.region > last then
              last := c^.stmt^.hdr.region;
          c := c^.next;
        end;
        if assert_is_use_def_at_call_site(opt_4009c[last]) then
          last := g_opt_tree_ptr_t(opt_4009c[last]^.br_cond)^.owner^.hdr.region;
        upto := last * 2;
        if opt_4009c[last]^.hdr.vnum = v then
          upto := upto + 1;
      end
      else begin
        k := lb^.last_stmt^.hdr.region;
        if k = 0 then
          k := find_next_numbered_stmt(lb^.last_stmt);
        upto := k * 2 + 1;
      end;
      mark_stmts(from, upto, rr);
    end
    else begin
      from := s * 2;
      st := opt_4009c[s];
      if not ((st^.hdr.vnum = v) and (st^.vset <> nil) and (v in st^.vset^)) then
        from := from + 1;
      k := blk^.last_stmt^.hdr.region;
      if k = 0 then
        k := find_next_numbered_stmt(blk^.last_stmt);
      mark_stmts(from, k * 2 + 1, rr);
      c := e^.du;
      while c <> nil do begin
        us := c^.stmt^.hdr.region;
        if c^.stmt^.block = blk then begin
          if assert_is_use_def_at_call_site(opt_4009c[us]) then
            us := g_opt_tree_ptr_t(opt_4009c[us]^.br_cond)^.owner^.hdr.region;
          upto := us * 2;
          st := opt_4009c[us];
          if (st^.hdr.vnum = v) and (st^.vset <> nil) and (v in st^.vset^) then
            upto := upto + 1;
          if us <= s then begin
            k := blk^.first_stmt^.hdr.region;
            if k = 0 then
              k := find_prev_numbered_stmt(blk^.first_stmt);
            mark_stmts(k * 2, upto, rr);
          end;
        end;
        c := c^.next;
      end;
    end;
    b := b^.next;
  end;
end;

{ reg_life_$bnum_of_head_for_prehead - the number of the loop header
  whose preheader is block b: for a strength reduction temporary t,
  the loop header of the block of its record (a variable's +52, a
  Fortran variable's +46) or of the statements on its list (+8) whose
  preheader is b; otherwise the successor of b that is a loop header
  with b as preheader; else reported (cgerr 28 'bad block flow graph'
  at b's first statement's line; the result not set).

  0x0C852E, 0xE6 bytes, link #-24: the record's block +16 and its loop
  header +12; the search loop has no other end; the successors by
  `dbf'; strtk's string after the routine (20 characters). }

function reg_life_$bnum_of_head_for_prehead(
    b: reg_num_t;
    t: il_$node_ptr_t): integer; options(val_param); internal;
var
  blk: g_opt_block_ptr_t;
  x: il_$node_ptr_t;
  l: rl_cell_ptr_t;
  h: g_opt_block_ptr_t;
  sb: g_opt_block_ptr_t;
  i: integer;
begin
  blk := g_opt_blocks_ptr_t(il_11c)^[b];
  if il_utils_$is_strength_reduction_temp(t) then begin
    if t^.kind = 109 then
      x := t^.xp[13]
    else
      x := t^.xp2[11];
    l := rl_cell_ptr_t(x^.xp[2]);
    repeat
      if l = nil then
        h := g_opt_block_ptr_t(x^.xp[4])^.loop
      else begin
        h := g_opt_block_ptr_t(l^.item^.xp[4])^.loop;
        l := l^.next;
      end;
    until h^.preheader = blk;
    reg_life_$bnum_of_head_for_prehead := h^.num;
    return;
  end;
  for i := 1 to blk^.nsucc do begin
    sb := blk^.succ^[i];
    if sb <> nil then
      if sb^.flags.header then
        if sb^.preheader <> nil then
          if sb^.preheader = blk then begin
            reg_life_$bnum_of_head_for_prehead := sb^.num;
            return;
          end;
  end;
  cgerr(28, blk^.first_stmt^.line, strtk('bad block flow graph', 20));
end;

{ add_con_range - a range for constant (or strength reduction
  temporary) t used by statement s, the evaluation heading a latch
  block (not a Fortran constant (147) of a variable): of the class of
  t's kind (6 and 7 the reals 88, 89; a Fortran constant's or
  parameter's by its variable's size class, runbackend_18; a variable's
  get_rlen of its type; else 5), from s to the start of the next block,
  and over each block of the loop whose preheader is s's block (with
  the block after a loop's closing branch when it is the empty
  evaluation or label that the branch's label (+72 field 8, or 2 then
  4) leads to).

  0x0C8628, 0x500 bytes, link #-56: the kinds compared 88, 89, 195,
  163, 147, 146, 109, 110 in turn; the next block il_11c^[num + 1]
  (`(0,A3,D4.l)'); the loop's points: the last region's 2r + 1 tested
  for 0 (never: the find_next call is dead); the label's field `andi.b
  #0x3E; lsr.w #1' of +72; the second test reads the branch's next
  without a nil test. }

procedure add_con_range;
var
  st: g_opt_stmt_ptr_t;
  pb: reg_num_t;
  h: integer;
  rr: reg_range_ptr_t;
  x: il_$node_ptr_t;
  te: rl_texp_t;
  from: reg_num_t;
  upto: reg_num_t;
  k: reg_num_t;
  k2: reg_num_t;
  l: g_opt_block_ptr_t;
  ls: g_opt_stmt_ptr_t;
  nb: g_opt_block_ptr_t;
begin
  if t^.kind = 147 then
    if t^.xp[6]^.kind = 109 then
      return;
  st := opt_4009c[s];
  if not st^.block^.flags.latch then
    return;
  pb := st^.block^.num;
  h := reg_life_$bnum_of_head_for_prehead(pb, t);
  reg_nranges := reg_nranges + 1;
  if reg_nranges > reg_nest then
    get_more_ranges;
  rr := addr(reg_ranges^[reg_nranges]);
  init_graph(rr);
  rr^.node := t;
  if rr^.node^.kind = 88 then
    rr^.rlen := 6
  else if rr^.node^.kind = 89 then
    rr^.rlen := 7
  else if (rr^.node^.kind = 195) or (rr^.node^.kind = 163) then
    rr^.rlen := 5
  else if rr^.node^.kind = 147 then begin
    x := rr^.node^.xp[7];
    if x^.kind = 110 then
      rr^.rlen := runbackend_18[ord(x^.xc[10]) & 15]
    else
      rr^.rlen := 5;
  end
  else if rr^.node^.kind = 146 then begin
    x := rr^.node^.xp[7];
    if x^.kind = 110 then
      rr^.rlen := runbackend_18[ord(x^.xc[10]) & 15]
    else if x^.kind = 111 then
      rr^.rlen := runbackend_18[ord(x^.xp[3]^.xc[10]) & 15]
    else
      rr^.rlen := 5;
  end
  else if rr^.node^.kind = 109 then begin
    type_exp(rr^.node^.xp[7], addr(te));
    rr^.rlen := get_rlen(te);
  end
  else if rr^.node^.kind = 110 then
    rr^.rlen := runbackend_18[ord(rr^.node^.xc[10]) & 15]
  else
    rr^.rlen := 5;
  rr^.first := s;
  add_block(rr, opt_4009c[s]^.block^.num);
  from := s * 2;
  nb := g_opt_blocks_ptr_t(il_11c)^[opt_4009c[s]^.block^.num + 1];
  upto := nb^.first_stmt^.hdr.region * 2;
  if upto = 0 then
    upto := 2 * find_next_numbered_stmt(nb^.first_stmt);
  mark_stmts(from, upto, rr);
  l := select_loop(h);
  while l <> nil do begin
    if not assert_block_on_list(rr, l^.num) then
      add_block(rr, l^.num);
    from := l^.first_stmt^.hdr.region * 2;
    upto := l^.last_stmt^.hdr.region * 2 + 1;
    if from = 0 then
      from := 2 * find_prev_numbered_stmt(l^.first_stmt);
    if upto = 0 then
      upto := 2 * find_next_numbered_stmt(l^.last_stmt);
    mark_stmts(from, upto, rr);
    ls := l^.last_stmt;
    if ls^.kind = 142 then
      if ls^.br_target^.kind = 144 then
        if rshft(ord(ls^.br_target^.xc[72]) & 16#3E, 1) = 8 then
          if ls^.next <> nil then
            if ls^.next^.kind = 139 then
              if ls^.next^.eval_count = 0 then
                if ls^.next = g_opt_blocks_ptr_t(il_11c)^[l^.num + 1]^.first_stmt then
                  if not assert_block_on_list(rr, l^.num + 1) then begin
                    add_block(rr, l^.num + 1);
                    nb := g_opt_blocks_ptr_t(il_11c)^[l^.num + 1];
                    k := nb^.first_stmt^.hdr.region;
                    if k = 0 then begin
                      k := find_prev_numbered_stmt(nb^.first_stmt);
                      k2 := find_next_numbered_stmt(g_opt_blocks_ptr_t(il_11c)^[l^.num + 1]^.first_stmt);
                    end
                    else
                      k2 := k;
                    mark_stmts(k * 2, k2 * 2 + 1, rr);
                  end;
    ls := l^.last_stmt;
    if ls^.kind = 142 then
      if ls^.br_target^.kind = 144 then
        if rshft(ord(ls^.br_target^.xc[72]) & 16#3E, 1) = 2 then
          if ls^.next^.kind = 144 then
            if rshft(ord(il_$node_ptr_t(ls^.next)^.xc[72]) & 16#3E, 1) = 4 then
              if ls^.next = g_opt_blocks_ptr_t(il_11c)^[l^.num + 1]^.first_stmt then
                if not assert_block_on_list(rr, l^.num + 1) then begin
                  add_block(rr, l^.num + 1);
                  nb := g_opt_blocks_ptr_t(il_11c)^[l^.num + 1];
                  k := nb^.first_stmt^.hdr.region;
                  if k = 0 then begin
                    k := find_prev_numbered_stmt(nb^.first_stmt);
                    k2 := find_next_numbered_stmt(g_opt_blocks_ptr_t(il_11c)^[l^.num + 1]^.first_stmt);
                  end
                  else
                    k2 := k;
                  mark_stmts(k * 2, k2 * 2 + 1, rr);
                end;
    l := l^.link;
  end;
end;
