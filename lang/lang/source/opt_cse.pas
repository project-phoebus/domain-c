{ opt_cse - common subexpressions: for each tree or reference of the
  routine's blocks (in depth-first order) that may be shared
  (cse_$is_cseable: its operands, their alias descriptors and the
  blocks they could be hoisted to), the nodes before it in its block
  and in the blocks that dominate it are searched, up to cse_limit
  nodes, for an identical one, stopping at a store or call that may
  change an operand (cse); a node found makes the later one stand for
  it (cse_$cse_two_nodes, flag 6) and the hoisting block of the
  later one is narrowed at the loops' marks.  csecleanup then gives
  every shared tree a parent node (190) and each reference a use
  (189).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0D4748  0x2A1938  make_cse_use
    0x0D482E  0x2A1A1E  make_cse_parent
    0x0D4906  0x2A1AF6  patch
    0x0D49C6  0x2A1BB6  saveparent_and_patch
    0x0D49FC  0x2A1BEC  walkopr
    0x0D4C12  0x2A1E02  csecleanup
    0x0D4DE0  0x2A1FD0  moved_check
    0x0D4E32  0x2A2022  check_uplevel_and_moved_check
    0x0D4E80  0x2A2070  cse_$cleanup_phase
    0x0D5024  0x2A2214  cse_$next_cse_serial
    0x0D5082  0x2A2272  assert_disp_over_ptr
    0x0D50AE  0x2A229E  cse_$set_hoistability
    0x0D50F8  0x2A22E8  cse_$is_cseable
    0x0D5812  0x2A2A02  assert_zombie_tree
    0x0D5838  0x2A2A28  cse_$cse_two_nodes
    0x0D58DC  0x2A2ACC  cse
    A5 0x2D2E48 (cc.m68k), 0x4937F4 (cc.a88k): the module's data, 0x90
    bytes (opt_assign has none): the relation table (+0, initialized
    -1, 1, 2, 0), the candidate's operands' hoisting blocks (+8),
    alias descriptors (+16, 24 bytes apart), nodes (+112), the extra
    operand (+128), their count (+130), the relation (+132), cse's
    serial (+134) and cse_limit (+136, which opt_main sets).

  make_cse_use, csecleanup, moved_check and cse load A5 (the last
  three are global, g_opt.ins.pas; make_cse_use only patch calls); the
  others do not and are internal (assert_disp_over_ptr and
  assert_zombie_tree leaf routines without a frame,
  docs/rev889-patterns.md 16), cse_$is_cseable and cse_$cse_two_nodes
  running on cse's A5.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the node kind and operator
  sets).
}
module opt_cse;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';

type
  { An operand's descriptor (24 bytes apart in the table). }
  cse_desc_t = record
    d: alias_$desc_t;
    unused_20: integer32;
  end;

var
  { +0: the relation of two hoisting blocks by which of them is 0. }
  rel_tab: array [boolean, boolean] of integer := [[-1, 1], [2, 0]];
  hoist: array [1..4] of g_opt_num_t;   { +8 }
  descs: array [1..4] of cse_desc_t;    { +16 }
  opnds: array [1..4] of il_$node_ptr_t;  { +112 }
  extra: integer;                       { +128: a displacement over a
                                          pointer's pointer counts too }
  nopnds: integer;                      { +130 }
  rel: integer;                         { +132: the operand whose
                                          hoisting block decides }
  serial: integer;                      { +134 }
  { +136: cse_limit (g_opt.ins.pas), defined below. }

  { delay.pas's data (cc.m68k 0x169968, absolute): a word for each
    register class, the bytes. }
  delay_378: extern array [0..15] of integer;

define
  cse_limit, csecleanup, moved_check, cse;

{ make_cse_use - a use (189) of node idx's parent, for statement stmt
  (or the first one after it with a region), linked into the parent's
  uses.

  0x0D4748, 0xE6 bytes: gspace(36) (nil reported as cgerr_no_source(9,
  0)); the tree's +4..+15 copied as three longwords; x stored at +32
  and cleared again. }

function make_cse_use(
    stmt: g_opt_stmt_ptr_t;
    idx: g_opt_num_t;
    x: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
var
  p: g_opt_cse_ptr_t;
  orig: il_$node_ptr_t;
  n: g_opt_cse_ptr_t;
  r: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
begin
  p := g_opt_cse_ptr_t(g_opt_nodes_ptr_t(il_120)^[idx]);
  orig := p^.p_tree;
  n := gspace(36);
  if n = nil then
    cgerr_no_source(9, 0);
  n^.kind := 189;
  r := stmt^.hdr.region;
  if r = 0 then begin
    s := stmt;
    repeat
      s := s^.next;
      r := s^.hdr.region;
    until r <> 0;
  end;
  n^.u_hdr := g_opt_cse_ptr_t(orig)^.u_hdr;
  g_opt_tree_ptr_t(n)^.flags := g_opt_tree_ptr_t(n)^.flags + [6];
  g_opt_tree_ptr_t(n)^.stmt := idx;
  n^.u_next := nil;
  n^.u_parent := p;
  n^.u_tree := orig;
  n^.u_x := x;
  n^.u_ent := opt_4009c[r];
  n^.u_next := nil;
  n^.u_x := nil;
  n^.u_next := p^.p_uses;
  p^.p_uses := n;
  make_cse_use := il_$node_ptr_t(n);
end;

{ make_cse_parent - the parent (190) of node idx, put in its place in
  il_120 and listed at statement stmt (or, without a region, the
  nearest statement before it with one), which is marked no_prune; a
  tree whose owner is not stmt gets stmt as owner.

  0x0D482E, 0xD8 bytes: gspace(28); +20 and +24 cleared twice. }

function make_cse_parent(
    stmt: g_opt_stmt_ptr_t;
    idx: g_opt_num_t): il_$node_ptr_t; options(val_param); internal;
var
  orig: il_$node_ptr_t;
  p: g_opt_cse_ptr_t;
  s: g_opt_stmt_ptr_t;
  r: g_opt_num_t;
begin
  orig := g_opt_nodes_ptr_t(il_120)^[idx];
  p := gspace(28);
  if p = nil then
    cgerr_no_source(9, 0);
  p^.kind := 190;
  r := stmt^.hdr.region;
  if r = 0 then begin
    s := stmt;
    repeat
      s := s^.prev;
      r := s^.hdr.region;
    until r <> 0;
  end
  else begin
    s := stmt;
    if g_opt_tree_ptr_t(orig)^.owner <> s then
      g_opt_tree_ptr_t(orig)^.owner := s;
  end;
  p^.p_tree := orig;
  p^.p_uses := nil;
  p^.p_24 := 0;
  p^.p_next := nil;
  p^.p_num := idx;
  p^.p_stmt := s;
  p^.p_uses := nil;
  p^.p_24 := 0;
  g_opt_nodes_ptr_t(il_120)^[idx] := il_$node_ptr_t(p);
  if g_opt_cse_ptr_t(s^.cses) <> nil then
    p^.p_next := g_opt_cse_ptr_t(s^.cses);
  s^.cses := il_$node_ptr_t(p);
  s^.hdr.no_prune := true;
  make_cse_parent := il_$node_ptr_t(p);
end;

{ patch - replace operand t of statement stmt, when it is (or stands
  through a parent or a use for) a tree used twice or more that cse
  made shared (its number at +10), by the tree's parent (made when its
  il_120 entry is not one yet) or a new use (the result dropped when
  t is a use already).

  0x0D4906, 0xC0 bytes: the three kinds compared whole (`seq; or.b');
  the use count compared signed (`blt'). }

procedure patch(
    stmt: g_opt_stmt_ptr_t;
    var t: il_$node_ptr_t;
    x: il_$node_ptr_t); options(val_param); internal;
var
  a: il_$node_ptr_t;
  idx: g_opt_num_t;
begin
  a := t;
  if a = nil then
    return;
  if (a^.kind = 190) or (a^.kind = 189) or (a^.kind = 137) then begin
    if a^.kind = 190 then
      a := g_opt_cse_ptr_t(a)^.p_tree;
    if a^.kind = 189 then
      a := g_opt_cse_ptr_t(a)^.u_tree;
    if g_opt_tree_ptr_t(a)^.uses < 2 then
      return;
    idx := g_opt_tree_ptr_t(a)^.stmt;
    if idx = 0 then
      return;
    if g_opt_nodes_ptr_t(il_120)^[idx]^.kind <> 190 then
      t := make_cse_parent(stmt, idx)
    else if t^.kind = 189 then
      a := make_cse_use(stmt, idx, x)
    else
      t := make_cse_use(stmt, idx, x);
  end;
end;

{ saveparent_and_patch - patch, keeping a parent that t was.

  0x0D49C6, 0x36 bytes. }

procedure saveparent_and_patch(
    stmt: g_opt_stmt_ptr_t;
    var t: il_$node_ptr_t;
    x: il_$node_ptr_t); options(val_param); internal;
var
  old: il_$node_ptr_t;
begin
  old := t;
  patch(stmt, t, x);
  if old^.kind = 190 then
    t := old;
end;

{ walkopr - patch the operands of tree t of statement stmt and walk
  them: a tree's (the commutative operators' last first: the set of
  0..47 at 0x0D4C0C), a reference's base (+24), a 145's +24 and +36,
  a 175's or 171's +16, a 164's +20 and +24; a use is not walked, a
  parent is walked through.

  0x0D49FC, 0x1F6 bytes: the kinds the set at 0x0D4BF2 holds (137,
  138, 143, 145..147, 164, 171, 175, 189, 205) and 190; the case a
  compare chain; the last walk of each arm shared. }

procedure walkopr(
    stmt: g_opt_stmt_ptr_t;
    t: il_$node_ptr_t); options(val_param); internal;
var
  j: integer;
  tr: g_opt_tree_ptr_t;
begin
  if t = nil then
    return;
  if t^.kind = 189 then
    return;
  if not (t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) then
    if t^.kind <> 190 then
      return;
  if t^.kind = 190 then
    t := g_opt_cse_ptr_t(t)^.p_tree;
  case t^.kind of
    143, 137: begin
      tr := g_opt_tree_ptr_t(t);
      if tr^.op in [2, 4..6, 11, 15, 16, 21, 35, 37] then
        for j := tr^.count downto 1 do begin
          saveparent_and_patch(stmt, tr^.opnd[j], t);
          walkopr(stmt, tr^.opnd[j]);
        end
      else
        for j := 1 to tr^.count do begin
          saveparent_and_patch(stmt, tr^.opnd[j], t);
          walkopr(stmt, tr^.opnd[j]);
        end;
    end;
    146, 147, 205: begin
      saveparent_and_patch(stmt, t^.xp[6], t);
      walkopr(stmt, t^.xp[6]);
    end;
    145: begin
      saveparent_and_patch(stmt, t^.xp[6], t);
      walkopr(stmt, t^.xp[6]);
      saveparent_and_patch(stmt, t^.xp[9], t);
      walkopr(stmt, t^.xp[9]);
    end;
    175: begin
      saveparent_and_patch(stmt, t^.xp[4], t);
      walkopr(stmt, t^.xp[4]);
    end;
    171: begin
      saveparent_and_patch(stmt, t^.xp[4], t);
      walkopr(stmt, t^.xp[4]);
    end;
    164: begin
      saveparent_and_patch(stmt, t^.xp[5], t);
      walkopr(stmt, t^.xp[5]);
      saveparent_and_patch(stmt, t^.xp[6], t);
      walkopr(stmt, t^.xp[6]);
    end;
    otherwise ;
  end;
end;

{ csecleanup - patch and walk the operands of every statement of the
  routine (evaluations' trees and references, assignments' sides and
  +72, conditional branches' conditions, a 151's +48), block by block
  in depth-first order from the routine's first block to the end, then
  from the start up to it.

  0x0D4C12, 0x1CE bytes: the first block's position k in opt_dfs_block
  is searched first (D5 left as it was when it is not there); a
  block's statements from first_stmt (+84) to last_stmt's next (+88);
  each operand patched with the statement as x. }

procedure csecleanup;
label
  10;
var
  k: g_opt_num_t;
  lo: g_opt_num_t;
  hi: g_opt_num_t;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  j: integer;
begin
  hi := opt_last_block;
  for k := opt_first_block to opt_last_block do
    if opt_dfs_block^[k] = opt_first_block then begin
      lo := k;
      exit;
    end;
10:
  for k := lo to hi do begin
    b := g_opt_blocks_ptr_t(il_11c)^[opt_dfs_block^[k]];
    s := b^.first_stmt;
    repeat
      case s^.kind of
        139:
          for j := 1 to s^.eval_count do
            if s^.eval_opnd[j]^.kind in [137, 138, 143, 145..147, 164, 171,
                                         175, 189, 205] then begin
              patch(s, s^.eval_opnd[j], il_$node_ptr_t(s));
              walkopr(s, s^.eval_opnd[j]);
            end;
        140: begin
          patch(s, s^.asg_lhs, il_$node_ptr_t(s));
          walkopr(s, s^.asg_lhs);
          patch(s, s^.asg_rhs, il_$node_ptr_t(s));
          walkopr(s, s^.asg_rhs);
          if s^.asg_x <> nil then begin
            patch(s, s^.asg_x, il_$node_ptr_t(s));
            walkopr(s, s^.asg_x);
          end;
        end;
        142: begin
          patch(s, s^.br_cond, il_$node_ptr_t(s));
          walkopr(s, s^.br_cond);
        end;
        151:
          if s^.br_target <> nil then begin
            patch(s, s^.br_target, il_$node_ptr_t(s));
            walkopr(s, s^.br_target);
          end;
        otherwise ;
      end;
      s := s^.next;
    until (s = nil) or (s = b^.last_stmt^.next);
  end;
  if lo <> opt_first_block then begin
    hi := lo - 1;
    lo := opt_first_block;
    goto 10;
  end;
end;

{ moved_check - t, or when it is a tree or reference standing for its
  statement node (flag 6), that node (il_120 by its +10).

  0x0D4DE0, 0x52 bytes. }

procedure moved_check(
    var t: il_$node_ptr_t);
begin
  if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if 6 in g_opt_tree_ptr_t(t)^.flags then
      t := g_opt_nodes_ptr_t(il_120)^[g_opt_tree_ptr_t(t)^.stmt];
end;

{ check_uplevel_and_moved_check - moved_check, and up set when t is
  then a variable of another routine's frame (a 109's +34 or a 110's
  +26, bit 8 of the word).

  0x0D4E32, 0x4E bytes. }

procedure check_uplevel_and_moved_check(
    var t: il_$node_ptr_t;
    var up: boolean); internal;
begin
  moved_check(t);
  if (t^.kind = 109) and ((t^.xw[17] & 16#100) <> 0) then
    up := true
  else if (t^.kind = 110) and ((t^.xw[13] & 16#100) <> 0) then
    up := true;
end;

{ cse_$cleanup_phase - moved_check every operand of every node of the
  routine's blocks.

  0x0D4E80, 0x1A4 bytes: the blocks and nodes through il.pas's record
  at +0xC0 (+92, +96); an evaluation's operands from the last. }

procedure cse_$cleanup_phase; internal;
var
  k: g_opt_num_t;
  i: g_opt_num_t;
  j: integer;
  b: g_opt_block_ptr_t;
  t: il_$node_ptr_t;
  st: g_opt_stmt_ptr_t;
  tr: g_opt_tree_ptr_t;
begin
  for k := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[k];
    for i := b^.first to b^.last do begin
      t := g_opt_nodes_ptr_t(il_120)^[i];
      st := g_opt_stmt_ptr_t(t);
      tr := g_opt_tree_ptr_t(t);
      case t^.kind of
        139:
          for j := st^.eval_count downto 1 do
            moved_check(st^.eval_opnd[j]);
        140: begin
          moved_check(st^.asg_lhs);
          moved_check(st^.asg_rhs);
          if st^.asg_x <> nil then
            moved_check(st^.asg_x);
        end;
        142:
          moved_check(st^.br_cond);
        151:
          if st^.br_target <> nil then
            moved_check(st^.br_target);
        137, 143:
          for j := 1 to tr^.count do
            moved_check(tr^.opnd[j]);
        147, 205, 146:
          moved_check(t^.xp[6]);
        145: begin
          moved_check(t^.xp[6]);
          moved_check(t^.xp[9]);
        end;
        164: begin
          moved_check(t^.xp[5]);
          moved_check(t^.xp[6]);
        end;
        175:
          moved_check(t^.xp[4]);
        171:
          moved_check(t^.xp[4]);
        otherwise ;
      end;
    end;
  end;
end;

{ cse_$next_cse_serial - the next serial number for the blocks' walk
  marks; at -1 every block's mark (+98) is cleared and it starts again
  at 1.

  0x0D5024, 0x5E bytes. }

procedure cse_$next_cse_serial(
    var n: integer); internal;
var
  k: g_opt_num_t;
begin
  if n = -1 then begin
    for k := opt_first_block to opt_last_block do
      g_opt_blocks_ptr_t(il_11c)^[k]^.cse_serial := 0;
    n := 1;
  end
  else
    n := n + 1;
end;

{ assert_disp_over_ptr - t is a displacement (205, 147) of a pointer
  dereference (146).

  0x0D5082, 0x2C bytes, no frame. }

function assert_disp_over_ptr(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if t = nil then
    assert_disp_over_ptr := false
  else if (t^.kind = 205) or (t^.kind = 147) then
    assert_disp_over_ptr := t^.xp[6]^.kind = 146
  else
    assert_disp_over_ptr := false;
end;

{ cse_$set_hoistability - h: the block node t could be hoisted to
  (opt_loop_hoist by its number) when t is a tree or reference with a
  number, else 0.

  0x0D50AE, 0x4A bytes. }

procedure cse_$set_hoistability(
    t: il_$node_ptr_t;
    var h: g_opt_num_t); options(val_param); internal;
begin
  if (t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
     (g_opt_tree_ptr_t(t)^.stmt <> 0) then
    h := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt]
  else
    h := 0;
end;

{ cse_$is_cseable - whether node n may be shared, its operands, their
  descriptors and hoisting blocks set up in the module's tables (rel
  the operand whose hoisting block is the innermost); the operands of
  a node that is not are moved_check-ed (and a 148 makes its routine
  the current block, il_180).

  0x0D50F8, 0x710 bytes, link #-32.  A reference (205, 147, 146) used
  at all: its base, of 4 bytes (a displacement's descriptor of class
  0), and the pointer under a displacement over a pointer; not with
  flag 2.  A 145 (always): its +24 and +36 (of +42 bytes), the
  relation from rel_tab and the dominance of their hoisting blocks.
  An operator (137) used at all: none of its operands of another
  frame (check_uplevel_and_moved_check, the commutative ones from the
  last), not 26 of a tree or of a variable without bit 12 (+34 or
  +26), not flag 2, not one of the operators of the set of 0..79 at
  0x0D5808 (11, 12, 15, 16, 23, 24, 47, 63, 66), at most 4 operands;
  each operand's descriptor of the value's bytes (delay's table, or
  its size), rel the first operand that is a tree or reference, moved
  to one with a later hoisting block, or none, then to one whose block
  rel's dominates; some operators' descriptors get other sizes (39,
  6, 5, 3, 13, 14, 22, 18, 25) or class 0 (26).

  Not known from the original:
  - the names; why the outer loop of the last search counts i
    without using it. }

function cse_$is_cseable(
    n: g_opt_num_t): boolean; options(val_param); internal;
var
  t: il_$node_ptr_t;
  tr: g_opt_tree_ptr_t;
  st: g_opt_stmt_ptr_t;
  ok: boolean;
  up: boolean;
  k: integer;
  i: integer;
  j: integer;
  sz: integer32;
  x: il_$node_ptr_t;
begin
  t := g_opt_nodes_ptr_t(il_120)^[n];
  tr := g_opt_tree_ptr_t(t);
  st := g_opt_stmt_ptr_t(t);
  ok := false;
  opt_loop_hoist^[n] := 0;
  for k := 1 to 4 do
    hoist[k] := 0;
  case t^.kind of
    205, 147, 146:
      if tr^.uses <> 0 then begin
        moved_check(t^.xp[6]);
        nopnds := 1;
        opnds[1] := t^.xp[6];
        alias_$alias_desc_with_size(opnds[1], 4, descs[1].d);
        if (t^.kind = 205) or (t^.kind = 147) then begin
          descs[1].d.class := 0;
          if assert_disp_over_ptr(t) then begin
            opnds[2] := t^.xp[6]^.xp[6];
            alias_$alias_desc_with_size(opnds[2], 4, descs[2].d);
          end;
        end;
        rel := 1;
        cse_$set_hoistability(t^.xp[6], hoist[1]);
        ok := not (2 in tr^.flags);
      end;
    145: begin
      moved_check(t^.xp[6]);
      moved_check(t^.xp[9]);
      nopnds := 2;
      opnds[1] := t^.xp[6];
      alias_$alias_desc_with_size(opnds[1], 4, descs[1].d);
      opnds[2] := t^.xp[9];
      alias_$alias_desc_with_size(opnds[2], t^.xw[21] & 16#FFFF, descs[2].d);
      ok := true;
      cse_$set_hoistability(t^.xp[6], hoist[1]);
      cse_$set_hoistability(t^.xp[9], hoist[2]);
      rel := rel_tab[hoist[1] = 0, hoist[2] = 0];
      if rel = -1 then
        if hoist[2] = hoist[1] then
          rel := 1
        else if dom(g_opt_blocks_ptr_t(il_11c)^[hoist[1]],
                    g_opt_blocks_ptr_t(il_11c)^[hoist[2]]) then
          rel := 2
        else if dom(g_opt_blocks_ptr_t(il_11c)^[hoist[2]],
                    g_opt_blocks_ptr_t(il_11c)^[hoist[1]]) then
          rel := 1
        else
          rel := 0;
    end;
    137:
      if tr^.uses <> 0 then begin
        up := false;
        if tr^.op in [2, 4..6, 11, 15, 16, 21, 35, 37] then
          for j := tr^.count downto 1 do
            check_uplevel_and_moved_check(tr^.opnd[j], up)
        else
          for j := 1 to tr^.count do
            check_uplevel_and_moved_check(tr^.opnd[j], up);
        if (tr^.op = 26) and (tr^.opnd[1]^.kind = 137) then
          up := true;
        if tr^.op = 26 then begin
          x := tr^.opnd[1];
          if ((x^.kind = 109) and ((x^.xw[17] & 16#1000) = 0)) or
             ((x^.kind = 110) and ((x^.xw[13] & 16#1000) = 0)) then
            up := true;
        end;
        if not up then
          if not (2 in tr^.flags) then
            if not (tr^.op in [11, 12, 15, 16, 23, 24, 47, 63, 66]) then
              if tr^.count <= 4 then begin
                ok := true;
                sz := delay_378[tr^.rlen];
                if sz = 0 then
                  sz := tr^.size;
                nopnds := tr^.count;
                for j := 1 to nopnds do begin
                  opnds[j] := tr^.opnd[j];
                  alias_$alias_desc_with_size(opnds[j], sz, descs[j].d);
                  cse_$set_hoistability(opnds[j], hoist[j]);
                end;
                rel := 0;
                for j := 1 to nopnds do
                  if opnds[j]^.kind in [137, 138, 143, 145..147, 164, 171,
                                        175, 189, 205] then begin
                    rel := j;
                    exit;
                  end;
                if (rel > 0) and (hoist[rel] <> 0) then
                  for j := 1 to nopnds do
                    if (hoist[j] > hoist[rel]) and (hoist[rel] <> 0) then
                      rel := j
                    else if hoist[j] = 0 then
                      if opnds[j]^.kind in [137, 138, 143, 145..147, 164,
                                            171, 175, 189, 205] then
                        rel := j;
                if (rel > 0) and (hoist[rel] <> 0) then
                  for i := 1 to nopnds do
                    for j := i + 1 to nopnds do
                      if hoist[j] <> 0 then
                        if hoist[j] <> hoist[rel] then
                          if dom(g_opt_blocks_ptr_t(il_11c)^[hoist[rel]],
                                 g_opt_blocks_ptr_t(il_11c)^[hoist[j]]) then
                            rel := j;
                case tr^.op of
                  39:
                    descs[1].d.size := delay_378[tr^.w26];
                  6, 5, 3: begin
                    descs[1].d.size := tr^.w26;
                    descs[2].d.size := tr^.w28;
                  end;
                  13:
                    descs[1].d.size := 4;
                  14:
                    descs[1].d.size := tr^.w26;
                  22, 18:
                    descs[1].d.size := tr^.w26;
                  26:
                    descs[1].d.class := 0;
                  25: begin
                    descs[2].d.size := 2;
                    descs[3].d.size := 2;
                  end;
                  otherwise ;
                end;
              end;
      end;
    143:
      if tr^.uses <> 0 then
        for j := 1 to tr^.count do
          moved_check(tr^.opnd[j]);
    164:
      if tr^.uses <> 0 then begin
        moved_check(t^.xp[5]);
        moved_check(t^.xp[6]);
      end;
    175:
      moved_check(t^.xp[4]);
    171:
      moved_check(t^.xp[4]);
    140: begin
      moved_check(st^.asg_lhs);
      moved_check(st^.asg_rhs);
      if st^.asg_x <> nil then
        moved_check(st^.asg_x);
    end;
    139:
      for j := 1 to st^.eval_count do
        moved_check(st^.eval_opnd[j]);
    142:
      moved_check(st^.br_cond);
    148: begin
      x := st^.br_target;
      if (x^.kind <> 167) and (x^.kind <> 172) then
        il_180 := x;
    end;
    otherwise ;
  end;
  cse_$is_cseable := ok;
end;

{ assert_zombie_tree - t is a tree (143, 137) no longer used.

  0x0D5812, 0x26 bytes, no frame: `sle' of the use count. }

function assert_zombie_tree(
    t: g_opt_tree_ptr_t): boolean; options(val_param); internal;
begin
  if t = nil then
    assert_zombie_tree := false
  else if (t^.kind = 143) or (t^.kind = 137) then
    assert_zombie_tree := t^.uses <= 0
  else
    assert_zombie_tree := false;
end;

{ cse_$cse_two_nodes - make node a stand for node b (or what b stands
  for): flag 6 and b's number, its uses added to b's, and b's
  operands' uses given back when b is an operator.

  0x0D5838, 0xA4 bytes. }

procedure cse_$cse_two_nodes(
    a: g_opt_num_t;
    b: g_opt_num_t); options(val_param); internal;
var
  x: g_opt_tree_ptr_t;
  y: g_opt_tree_ptr_t;
  k: integer;
begin
  x := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[b]);
  y := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[a]);
  if assert_zombie_tree(y) then
    return;
  if assert_zombie_tree(x) then
    return;
  if 6 in x^.flags then begin
    b := x^.stmt;
    x := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[b]);
  end;
  y^.flags := y^.flags + [6];
  y^.stmt := b;
  x^.uses := x^.uses + y^.uses;
  if x^.kind = 137 then
    for k := 1 to x^.count do
      adjust_uc(x^.opnd[k], -1);
end;

{ cse - find the common subexpressions: for each block in depth-first
  order and each node i of it that cse_$is_cseable allows, the nodes
  before it (j counting down, up to cse_limit of them) in its block,
  the blocks select_block_list gives back to its dominator, then the
  dominator and so on (each block once: its cse_serial; same false
  once outside i's block), until a node is found identical or one may
  change an operand (stop):
  - an operator (137) not marked 2: a store (15, 16) stops when it
    may touch an operand's storage (alias_$related_call); else, in i's
    block, the same operator with the same operands and descriptor
    is the cse (cse_$cse_two_nodes); a node that is an operand stops
    (unless opt_on element 16, cargs +0x281 bit 1); an operator 17 of
    the reference i's base ends the search;
  - a reference (145, 147, 205, 146) in i's block of the same kind,
    base, +28 (or neither a 146 nor a 145), +32 (147, 145: a
    displacement; 205: a node), +22 (146, 145 under target property
    +0x7F) and for a 145 +42, +36 and +40, is the cse; else as above;
  - an assignment: to a strength reduction temporary's pointer i
    dereferences (directly, under a displacement, over a 205) stops;
    so does one whose left side's descriptors (alias_$basic_alias_desc,
    the second of the stored bytes) are related to an operand's, or,
    in a block of kind 2 (il_180's +377), a variable sharing storage
    (a 110 of storage kind 3, the chain at +28) with an operand;
  - an evaluation's operands are moved_check-ed; an empty one is a
    loop's mark: when its block is a latch and i is a reference or
    operator (the set at 0x0D625A: 137, 145..147, 205), i's hoisting
    block is narrowed to the loop's (by depth) when the mark's block
    dominates i's statement's, and to rel's operand's when the mark's
    block dominates that, and cleared when an operand that is a tree
    has none;
  - anything else is passed over.
  Then cse_$cleanup_phase.

  0x0D58DC, 0x97E bytes, link #-148.  cse_$next_cse_serial's argument
  pop leaves 2 bytes for cse_$is_cseable's pad (docs/rev889-patterns.md
  51); the descriptors of the alias tests are frame records at -24 and
  -48 (the first copied to the second, five longwords).

  Not known from the original:
  - the names; how the walk was written (the image jumps back into the
    scan from three places: taken as gotos); why the left side's
    descriptor is made twice. }

procedure cse;
label
  10, 20, 30, 90;
var
  k: g_opt_num_t;
  bn: g_opt_num_t;
  blk: g_opt_block_ptr_t;
  i: g_opt_num_t;
  t: il_$node_ptr_t;
  tt: g_opt_tree_ptr_t;
  bnum: g_opt_num_t;
  b: g_opt_block_ptr_t;
  list: g_opt_block_ptr_t;
  same: boolean;
  stop: boolean;
  j: g_opt_num_t;
  lo: g_opt_num_t;
  steps: integer;
  x: il_$node_ptr_t;
  xt: g_opt_tree_ptr_t;
  xs: g_opt_stmt_ptr_t;
  m: integer;
  r: il_$node_ptr_t;
  p: il_$node_ptr_t;
  q: il_$node_ptr_t;
  lhs: il_$node_ptr_t;
  da: alias_$desc_t;
  db: alias_$desc_t;
  sz: integer32;
  mark: g_opt_block_ptr_t;
  deeper: boolean;
  h: g_opt_block_ptr_t;
begin
  serial := 0;
  for k := opt_first_block to opt_last_block do begin
    bn := opt_dfs_block^[k];
    blk := g_opt_blocks_ptr_t(il_11c)^[bn];
    for i := blk^.first to blk^.last do begin
      cse_$next_cse_serial(serial);
      if not cse_$is_cseable(i) then
        goto 90;
      steps := 0;
      t := g_opt_nodes_ptr_t(il_120)^[i];
      tt := g_opt_tree_ptr_t(t);
      bnum := bn;
      b := g_opt_blocks_ptr_t(il_11c)^[bnum];
      same := true;
      if b^.dom = nil then
        list := nil
      else
        list := select_block_list(bnum, b^.dom^.num);
      j := i - 1;
      lo := b^.first;
      stop := false;
10:
      if j < lo then begin
        if list <> nil then begin
          if list^.cse_serial <> serial then begin
            same := false;
            j := list^.last;
            lo := list^.first;
            list^.cse_serial := serial;
          end;
          list := list^.link;
        end
        else if b^.dom = nil then
          stop := true
        else begin
          if bn <> bnum then
            b^.cse_serial := serial;
          bnum := b^.dom^.num;
          b := g_opt_blocks_ptr_t(il_11c)^[bnum];
          same := true;
          if b^.dom = nil then
            list := nil
          else
            list := select_block_list(bnum, b^.dom^.num);
          j := b^.last;
          lo := b^.first;
        end;
        if stop then
          goto 20;
        goto 10;
      end;
      if stop then
        goto 20;
      x := g_opt_nodes_ptr_t(il_120)^[j];
      xt := g_opt_tree_ptr_t(x);
      xs := g_opt_stmt_ptr_t(x);
      case x^.kind of
        137: begin
          if 2 in xt^.flags then
            goto 20;
          if xt^.uses <> 0 then begin
            if (xt^.op = 15) or (xt^.op = 16) then begin
              if assert_disp_over_ptr(t) then
                extra := 1
              else
                extra := 0;
              for m := 1 to nopnds + extra do
                if alias_$related_call(descs[m].d, x) then
                  stop := true;
              goto 20;
            end;
            if not same then
              goto 20;
            if xt^.uses <> 0 then
              if (t^.kind = 137) and (tt^.op = xt^.op) and
                 (xt^.count = nopnds) and (xt^.size = tt^.size) and
                 (xt^.rlen = tt^.rlen) and (xt^.w26 = tt^.w26) and
                 (xt^.w28 = tt^.w28) and
                 (xt^.dflags.signed = tt^.dflags.signed) then begin
                for m := 1 to xt^.count do
                  if xt^.opnd[m] <> tt^.opnd[m] then
                    goto 30;
                stop := true;
                cse_$cse_two_nodes(i, j);
                goto 20;
              end;
          end;
30:
          if not (16 in cargs_$options.opt_on) then
            for m := 1 to nopnds do
              if opnds[m] = x then begin
                stop := true;
                exit;
              end;
          if (xt^.op = 17) and (t^.kind = 146) and (t^.xp[6] = x) then
            goto 90;
        end;
        145, 147, 205, 146: begin
          if not same then
            goto 20;
          if (x^.kind = t^.kind) and (x^.xp[6] = t^.xp[6]) then
            if (x^.xp[7] = t^.xp[7]) or
               not ((x^.kind = 146) or (x^.kind = 145)) then
              if not (((x^.kind = 147) or (x^.kind = 145)) and
                      (x^.xl[8] <> t^.xl[8])) then
                if not ((x^.kind = 205) and (x^.xp[8] <> t^.xp[8])) then
                  if not (((x^.kind = 146) or (x^.kind = 145)) and
                          target_properties.p_7f and
                          (x^.xc[22] <> t^.xc[22])) then
                    if (x^.kind <> 145) or
                       ((x^.xw[21] = t^.xw[21]) and (x^.xp[9] = t^.xp[9]) and
                        (x^.xw[20] = t^.xw[20])) then begin
                      stop := true;
                      cse_$cse_two_nodes(i, j);
                      goto 20;
                    end;
          if not (16 in cargs_$options.opt_on) then
            for m := 1 to nopnds do
              if opnds[m] = x then begin
                stop := true;
                goto 20;
              end;
        end;
        140: begin
          if t^.kind = 146 then
            if il_utils_$is_strength_reduction_temp(t^.xp[6]) then begin
              r := nil;
              lhs := xs^.asg_lhs;
              if lhs^.kind = 146 then
                if lhs^.xp[7] = t^.xp[7] then
                  if il_utils_$is_strength_reduction_temp(lhs^.xp[6]) then
                    r := xs^.asg_lhs^.xp[6];
              lhs := xs^.asg_lhs;
              if lhs^.kind = 147 then
                if lhs^.xp[6]^.kind = 146 then
                  if lhs^.xp[6]^.xp[7] = t^.xp[7] then
                    if il_utils_$is_strength_reduction_temp(
                           lhs^.xp[6]^.xp[6]) then
                      r := xs^.asg_lhs^.xp[6]^.xp[6];
              lhs := xs^.asg_lhs;
              if lhs^.kind = 147 then
                if lhs^.xp[6]^.kind = 205 then
                  if lhs^.xp[6]^.xp[6]^.kind = 146 then
                    if lhs^.xp[6]^.xp[6]^.xp[7] = t^.xp[7] then
                      if il_utils_$is_strength_reduction_temp(
                             lhs^.xp[6]^.xp[6]^.xp[6]) then
                        r := xs^.asg_lhs^.xp[6]^.xp[6]^.xp[6];
              lhs := xs^.asg_lhs;
              if lhs^.kind = 205 then
                if lhs^.xp[6]^.kind = 146 then
                  if lhs^.xp[6]^.xp[7] = t^.xp[7] then
                    if il_utils_$is_strength_reduction_temp(
                           lhs^.xp[6]^.xp[6]) then
                      r := xs^.asg_lhs^.xp[6]^.xp[6];
              if t^.xp[6] = r then
                stop := true;
            end;
          alias_$basic_alias_desc(xs^.asg_lhs, da);
          db := da;
          alias_$basic_alias_desc(xs^.asg_lhs, da);
          sz := delay_378[xs^.asg_rlen];
          if sz = 0 then
            sz := xs^.asg_size;
          db.size := sz;
          if assert_disp_over_ptr(t) then
            extra := 1
          else
            extra := 0;
          for m := 1 to nopnds + extra do begin
            if alias_$related(da, descs[m].d) or
               alias_$related(db, descs[m].d) then begin
              stop := true;
              goto 20;
            end;
            if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
              if (xs^.asg_lhs^.kind = 147) or (xs^.asg_lhs^.kind = 110) then
                if (opnds[m]^.kind = 147) or (opnds[m]^.kind = 110) then begin
                  if opnds[m]^.kind = 147 then
                    p := opnds[m]^.xp[6]
                  else
                    p := opnds[m];
                  if xs^.asg_lhs^.kind = 147 then
                    q := xs^.asg_lhs^.xp[6]
                  else
                    q := xs^.asg_lhs;
                  if (p^.kind = 110) and (q^.kind = 110) then
                    if rshft(ord(p^.xc[44]) & 16#F0, 4) = 3 then
                      if rshft(ord(q^.xc[44]) & 16#F0, 4) = 3 then begin
                        r := p^.xp[7];
                        if r <> nil then
                          while r <> p do begin
                            if q = r then begin
                              stop := true;
                              exit;
                            end;
                            r := r^.xp[7];
                          end;
                      end;
                end;
          end;
        end;
        143: ;
        139:
          if xs^.eval_count <> 0 then
            for m := 1 to xs^.eval_count do
              moved_check(xs^.eval_opnd[m])
          else begin
            mark := xs^.block;
            if mark^.flags.latch then
              if t^.kind in [137, 145..147, 205] then begin
                if dom(mark, tt^.owner^.block) then
                  if opt_loop_hoist^[i] <> 0 then begin
                    if mark^.depth <
                       g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[i]]^.depth then
                      opt_loop_hoist^[i] := mark^.num;
                  end
                  else if g_opt_blocks_ptr_t(il_11c)^[bn]^.depth <> 0 then
                    if g_opt_blocks_ptr_t(il_11c)^[bn]^.depth >
                       g_opt_blocks_ptr_t(il_11c)^[mark^.num]^.depth then
                      opt_loop_hoist^[i] := mark^.num;
                if rel <> 0 then
                  if hoist[rel] <> 0 then
                    if hoist[rel] <> mark^.num then
                      if dom(xs^.block,
                             g_opt_blocks_ptr_t(il_11c)^[hoist[rel]]) then begin
                        h := g_opt_blocks_ptr_t(il_11c)^[hoist[rel]];
                        deeper := false;
                        if opt_loop_hoist^[i] <> 0 then
                          deeper := h^.depth >
                              g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[i]]^.depth
                        else if g_opt_blocks_ptr_t(il_11c)^[bn]^.depth <> 0 then
                          deeper := g_opt_blocks_ptr_t(il_11c)^[bn]^.depth >
                                    h^.depth;
                        if deeper then
                          opt_loop_hoist^[i] := hoist[rel];
                      end;
                for m := 1 to nopnds do
                  if opnds[m]^.kind in [137, 138, 143, 145..147, 164, 171,
                                        175, 189, 205] then
                    if hoist[m] = 0 then
                      opt_loop_hoist^[i] := 0;
              end;
          end;
        otherwise ;
      end;
20:
      j := j - 1;
      steps := steps + 1;
      if (steps <= cse_limit) and (j <> 0) and not stop then
        goto 10;
90:
    end;
  end;
  cse_$cleanup_phase;
end;
