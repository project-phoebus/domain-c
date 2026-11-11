{ opt_loop - loop-invariant code motion: for each loop (a header whose
  dominating preheader is a latch ending in the loop's mark, an
  evaluation statement), the trees of the loop's statements whose
  values do not change in the loop (opt_loop_hoist gives, by node
  number, the block a tree could be hoisted to) are appended to the
  mark's operands (movenode, at most 10), the subtrees' owners moved
  to the mark and their variables given use-def chains there
  (fixupchildren); loops left by a call of a non-returning routine or
  a branch out are marked (b3 of the mark) and not touched; the
  constants a loop uses are counted (add_constant) and, under opt_on
  17, the real constants of some loops moved out too
  (motion_constants); then trees of the loops that compute the same
  value as one already moved are made to stand for it (checkcses).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0D8960  0x2A5B50  assert_contains_ref_to_sr_temp
    0x0D8AE0  0x2A5CD0  do_move_check
    0x0D8C0E  0x2A5DFE  checkcses
    0x0D935E  0x2A654E  add_constant
    0x0D93E4  0x2A65D4  fixupchildren
    0x0D96CE  0x2A68BE  notalreadymoved
    0x0D9814  0x2A6A04  movenode
    0x0D9A22  0x2A6C12  moveinvariants
    0x0DA402  0x2A75F2  findlooptail
    0x0DA44E  0x2A763E  loopopt
    0x0DA874  0x2A7A64  walkt (in motion_constants)
    0x0DAA8C  0x2A7C7C  motion_constants
    A5 0x2D2EE0 (cc.m68k), 0x49388C (cc.a88k): the module's data, 16
    bytes: +0 the loop's preheader, +4 opt_loop_hoist (g_opt.ins.pas:
    opt_cse and opt_main reach it absolutely), +8 the region of the
    statement moveinvariants works on; +10..+15 not addressed.  dpc
    lays the defined opt_loop_hoist out after the module's own cells
    (cur_r at +4, opt_loop_hoist at +8): the layout is internal to the
    program (opt_cse and opt_main reach the cell by its symbol).

  The routines that load A5 are global (add_constant, loopopt and
  motion_constants in g_opt.ins.pas; do_move_check, fixupchildren,
  notalreadymoved, movenode and findlooptail only this unit calls);
  assert_contains_ref_to_sr_temp, checkcses and moveinvariants do
  not and are internal (moveinvariants runs on loopopt's A5).  walkt
  takes motion_constants' frame in A1 (its statement at -4).

  Statements are read through g_opt.ins.pas's g_opt_stmt_t, trees
  through g_opt_tree_t (the kinds of the 26-byte set after checkcses:
  137, 138, 143, 145..147, 164, 171, 175, 189, 205), other nodes by
  offset.  opt_main_$ensure_var_set and make_motioned_ud_chain are in
  g_opt.ins.pas.

  dpc gaps (docs/dpc-gaps.md): 2 (sparse cases on the node kinds), 3
  (add_constant's new), 7 (walkt's real constants), 8 (`in' on the node
  kind sets).
}
module opt_loop;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

var
  preh: g_opt_block_ptr_t;              { +0: the current loop's
                                          preheader }
  { +4: opt_loop_hoist (g_opt.ins.pas), defined below. }
  cur_r: g_opt_num_t;                   { +8: the region of the
                                          statement moveinvariants
                                          walks }

define
  opt_loop_hoist, add_constant, loopopt, motion_constants;

{ assert_contains_ref_to_sr_temp - tree t refers to a strength
  reduction temporary (il_utils_$is_strength_reduction_temp of its
  variables); constants do not.

  0x0D8960, 0x180 bytes: the kinds compared in turn (the constants'
  labels, 77..90, 92, 93, 101, 156, 176, lead to the end); 146 and
  205/147 separate copies; the result in D2 (`st' before the two
  operands of 145 and 164, cleared when neither has one). }

function assert_contains_ref_to_sr_temp(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  k: integer;
begin
  r := false;
  if t <> nil then
    case t^.kind of
      110, 109:
        r := il_utils_$is_strength_reduction_temp(t);
      146:
        r := assert_contains_ref_to_sr_temp(t^.xp[6]);
      205, 147:
        r := assert_contains_ref_to_sr_temp(t^.xp[6]);
      145: begin
        r := true;
        if not assert_contains_ref_to_sr_temp(t^.xp[6]) then
          if not assert_contains_ref_to_sr_temp(t^.xp[9]) then
            r := false;
      end;
      164: begin
        r := true;
        if not assert_contains_ref_to_sr_temp(t^.xp[5]) then
          if not assert_contains_ref_to_sr_temp(t^.xp[6]) then
            r := false;
      end;
      143, 137:
        for k := 1 to g_opt_tree_ptr_t(t)^.count do
          if assert_contains_ref_to_sr_temp(g_opt_tree_ptr_t(t)^.opnd[k]) then begin
            r := true;
            exit;
          end;
      77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 92, 93,
      101, 156, 176:
        ;
      otherwise
    end;
  assert_contains_ref_to_sr_temp := r;
end;

{ do_move_check - each operand of tree t that stands for another node
  (moved_check) replaced by it, and its own operands likewise.

  0x0D8AE0, 0x12E bytes: t by address (reloaded after each call); the
  kinds compared in turn, 175 and 171 separate copies. }

procedure do_move_check(
    var t: il_$node_ptr_t);
var
  k: integer;
begin
  case t^.kind of
    143, 137:
      for k := 1 to g_opt_tree_ptr_t(t)^.count do begin
        moved_check(g_opt_tree_ptr_t(t)^.opnd[k]);
        do_move_check(g_opt_tree_ptr_t(t)^.opnd[k]);
      end;
    147, 205, 146: begin
      moved_check(t^.xp[6]);
      do_move_check(t^.xp[6]);
    end;
    145: begin
      moved_check(t^.xp[6]);
      moved_check(t^.xp[9]);
      do_move_check(t^.xp[6]);
      do_move_check(t^.xp[9]);
    end;
    164: begin
      moved_check(t^.xp[5]);
      moved_check(t^.xp[6]);
      do_move_check(t^.xp[5]);
      do_move_check(t^.xp[6]);
    end;
    175: begin
      moved_check(t^.xp[4]);
      do_move_check(t^.xp[4]);
    end;
    171: begin
      moved_check(t^.xp[4]);
      do_move_check(t^.xp[4]);
    end;
    otherwise
  end;
end;

{ checkcses - in each loop whose preheader ends in a mark with
  operands: each tree of the loop's blocks (taken through the nodes it
  stands for, flag 6) has its operands put through moved_check; when
  the tree (an operator, 145..147 or 205) is owned by the mark, every
  other tree of the loop of the same kind and value (the same
  operator, operands and descriptor; for references the same base,
  displacement and, when target_properties' +0x7F, the same +22 byte)
  is made to stand for it (flag 6, its number) and its uses added.
  Then the routine's statements (but the last block's last) are put
  through do_move_check, and a latch's mark loses its repeated
  operands (each later copy given back and replaced by 0).

  0x0D8C0E, 0x702 bytes, link #-80: the kinds of the 26-byte sets
  after the routine (the trees; 137, 143, 145..147, 205; the
  constants 77..90, 92, 93, 101, 156, 163, 176, 195, 198, 200 that a
  mark's operands skip); a 137's descriptor (+20, 16 bytes) compared
  with `cmpm.l' (a record comparison); 147/205/146/145 and 175/171
  separate copies.

  Not known from the original:
  - whether the loop over the statements was a repeat or a while. }

type
  lp_desc_ptr_t = ^add_node_$desc_t;

procedure checkcses; internal;
var
  h: g_opt_num_t;
  b: g_opt_block_ptr_t;
  m: g_opt_stmt_ptr_t;
  lp: g_opt_block_ptr_t;
  head: g_opt_block_ptr_t;
  l2: g_opt_block_ptr_t;
  n: g_opt_num_t;
  j: g_opt_num_t;
  t: g_opt_tree_ptr_t;
  u: g_opt_tree_ptr_t;
  k: integer;
  same: boolean;
  s: g_opt_stmt_ptr_t;
  x: il_$node_ptr_t;
begin
  for h := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[h];
    if not b^.flags.header then
      next;
    if b^.preheader = nil then
      next;
    m := b^.preheader^.first_stmt;
    if m^.kind <> 139 then
      next;
    if m^.eval_count = 0 then
      next;
    head := select_loop(h);
    lp := head;
    if lp <> nil then
      repeat
        for n := lp^.first to lp^.last do begin
          t := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[n]);
          if not (t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) then
            next;
          while 6 in t^.flags do
            t := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[t^.stmt]);
          case t^.kind of
            143, 137:
              for k := 1 to t^.count do
                moved_check(t^.opnd[k]);
            147, 205, 146:
              moved_check(il_$node_ptr_t(t)^.xp[6]);
            145: begin
              moved_check(il_$node_ptr_t(t)^.xp[6]);
              moved_check(il_$node_ptr_t(t)^.xp[9]);
            end;
            164: begin
              moved_check(il_$node_ptr_t(t)^.xp[5]);
              moved_check(il_$node_ptr_t(t)^.xp[6]);
            end;
            175:
              moved_check(il_$node_ptr_t(t)^.xp[4]);
            171:
              moved_check(il_$node_ptr_t(t)^.xp[4]);
            otherwise
          end;
          l2 := head;
          if t^.kind in [137, 143, 145..147, 205] then
            if t^.owner = m then
              while l2 <> nil do begin
                for j := l2^.first to l2^.last do begin
                  if j = n then
                    next;
                  if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
                    if j = t^.stmt then
                      next;
                  u := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[j]);
                  if not (u^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) then
                    next;
                  if u^.uses = 0 then
                    next;
                  while 6 in u^.flags do
                    u := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[u^.stmt]);
                  if not (u^.kind in [137, 143, 145..147, 205]) then
                    next;
                  if u^.kind <> t^.kind then
                    next;
                  if u = t then
                    next;
                  case u^.kind of
                    143, 137:
                      for k := 1 to u^.count do
                        moved_check(u^.opnd[k]);
                    147, 205, 146:
                      moved_check(il_$node_ptr_t(u)^.xp[6]);
                    145: begin
                      moved_check(il_$node_ptr_t(u)^.xp[6]);
                      moved_check(il_$node_ptr_t(u)^.xp[9]);
                    end;
                    164: begin
                      moved_check(il_$node_ptr_t(u)^.xp[5]);
                      moved_check(il_$node_ptr_t(u)^.xp[6]);
                    end;
                    175:
                      moved_check(il_$node_ptr_t(u)^.xp[4]);
                    171:
                      moved_check(il_$node_ptr_t(u)^.xp[4]);
                    otherwise
                  end;
                  case u^.kind of
                    137:
                      if (t^.op = u^.op) and (t^.count = u^.count) then
                        if lp_desc_ptr_t(addr(t^.size))^ =
                           lp_desc_ptr_t(addr(u^.size))^ then begin
                          same := true;
                          for k := 1 to t^.count do
                            if t^.opnd[k] <> u^.opnd[k] then
                              same := false;
                          if same then begin
                            u^.flags := u^.flags + [6];
                            u^.stmt := t^.stmt;
                            t^.uses := t^.uses + u^.uses;
                            for k := 1 to u^.count do
                              adjust_uc(u^.opnd[k], -1);
                          end;
                        end;
                    147:
                      if il_$node_ptr_t(t)^.xl[8] = il_$node_ptr_t(u)^.xl[8] then
                        if il_$node_ptr_t(t)^.xp[7] = il_$node_ptr_t(u)^.xp[7] then
                          if il_$node_ptr_t(t)^.xp[6] = il_$node_ptr_t(u)^.xp[6] then begin
                            u^.flags := u^.flags + [6];
                            u^.stmt := t^.stmt;
                            t^.uses := t^.uses + u^.uses;
                          end;
                    205:
                      if il_$node_ptr_t(t)^.xp[8] = il_$node_ptr_t(u)^.xp[8] then
                        if il_$node_ptr_t(t)^.xp[7] = il_$node_ptr_t(u)^.xp[7] then
                          if il_$node_ptr_t(t)^.xp[6] = il_$node_ptr_t(u)^.xp[6] then begin
                            u^.flags := u^.flags + [6];
                            u^.stmt := t^.stmt;
                            t^.uses := t^.uses + u^.uses;
                          end;
                    146:
                      if il_$node_ptr_t(t)^.xp[7] = il_$node_ptr_t(u)^.xp[7] then
                        if il_$node_ptr_t(t)^.xp[6] = il_$node_ptr_t(u)^.xp[6] then
                          if not target_properties.p_7f or
                             (il_$node_ptr_t(t)^.xc[22] = il_$node_ptr_t(u)^.xc[22]) then begin
                            u^.flags := u^.flags + [6];
                            u^.stmt := t^.stmt;
                            t^.uses := t^.uses + u^.uses;
                          end;
                    145:
                      if il_$node_ptr_t(t)^.xl[8] = il_$node_ptr_t(u)^.xl[8] then
                        if il_$node_ptr_t(t)^.xp[6] = il_$node_ptr_t(u)^.xp[6] then
                          if il_$node_ptr_t(t)^.xp[9] = il_$node_ptr_t(u)^.xp[9] then
                            if il_$node_ptr_t(t)^.xw[21] = il_$node_ptr_t(u)^.xw[21] then
                              if il_$node_ptr_t(t)^.xw[20] = il_$node_ptr_t(u)^.xw[20] then
                                if not target_properties.p_7f or
                                   (il_$node_ptr_t(t)^.xc[22] = il_$node_ptr_t(u)^.xc[22]) then begin
                                  u^.flags := u^.flags + [6];
                                  u^.stmt := t^.stmt;
                                  t^.uses := t^.uses + u^.uses;
                                end;
                    otherwise
                  end;
                end;
                l2 := l2^.link;
              end;
        end;
        lp := lp^.link;
      until lp = nil;
  end;

  s := g_opt_blocks_ptr_t(il_11c)^[opt_first_block]^.first_stmt;
  if s <> nil then
    repeat
      case s^.kind of
        139:
          for k := 1 to s^.eval_count do
            if not (s^.eval_opnd[k]^.kind in [77..90, 92, 93, 101, 156, 163,
                                              176, 195, 198, 200]) then begin
              moved_check(s^.eval_opnd[k]);
              do_move_check(s^.eval_opnd[k]);
            end;
        140: begin
          moved_check(s^.asg_lhs);
          do_move_check(s^.asg_lhs);
          moved_check(s^.asg_rhs);
          do_move_check(s^.asg_rhs);
          if s^.asg_x <> nil then begin
            moved_check(s^.asg_x);
            do_move_check(s^.asg_x);
          end;
        end;
        142: begin
          moved_check(s^.br_cond);
          do_move_check(s^.br_cond);
        end;
        151:
          if s^.x48 <> nil then begin
            moved_check(s^.x48);
            do_move_check(s^.x48);
          end;
        otherwise
      end;
      if (s^.kind = 139) and (s^.eval_count <> 0) then
        if s^.block^.flags.latch then
          for k := 1 to s^.eval_count do
            for j := k + 1 to s^.eval_count do
              if s^.eval_opnd[j] = s^.eval_opnd[k] then begin
                x := s^.eval_opnd[j];
                case x^.kind of
                  137:
                    adjust_uc(x, -1);
                  147:
                    g_opt_tree_ptr_t(x)^.uses := g_opt_tree_ptr_t(x)^.uses - 1;
                  205:
                    g_opt_tree_ptr_t(x)^.uses := g_opt_tree_ptr_t(x)^.uses - 1;
                  146:
                    g_opt_tree_ptr_t(x)^.uses := g_opt_tree_ptr_t(x)^.uses - 1;
                  145:
                    g_opt_tree_ptr_t(x)^.uses := g_opt_tree_ptr_t(x)^.uses - 1;
                  otherwise
                end;
                s^.eval_opnd[j] := smcontk(81, 0);
              end;
      s := s^.next;
    until (s = nil) or
          (s = g_opt_blocks_ptr_t(il_11c)^[opt_last_block]^.last_stmt);
end;

{ add_constant - count constant t once more in block b's list of
  constants, adding it (a 10-byte record from new) the first time.

  0x0D935E, 0x86 bytes: both by address; a nil from new is
  cgerr_no_source(9, 0). }

procedure add_constant(
    in t: il_$node_ptr_t;
    in b: g_opt_block_ptr_t);
var
  p: g_opt_const_ptr_t;
  q: g_opt_const_ptr_t;
begin
  p := b^.consts;
  while p <> nil do begin
    if p^.node = t then begin
      p^.count := p^.count + 1;
      exit;
    end;
    p := p^.next;
  end;
  if p = nil then begin
    new(q);
    if q = nil then
      cgerr_no_source(9, 0);
    q^.node := t;
    q^.count := 1;
    q^.next := b^.consts;
    b^.consts := q;
  end;
end;

{ fixupchildren - tree t now evaluated at statement r (the mark): a
  tree without an owner, or whose owner's block r's block dominates,
  gets r as owner; the operands likewise; with f, each variable
  reached (of opt_region's table) is added to r's used variables and
  given an entry in r's table, a copy of opt_region's with no uses,
  and a use-def chain there (make_motioned_ud_chain).

  0x0D93E4, 0x2EA bytes, link #-84: all three by address (the
  recursive calls pass frame copies of r and f); the kinds compared
  in turn, 171 and 175 separate copies; the variable's 18-byte entry
  from mem_$alloc of opt_main_18 (nil reported as cgerr_no_source(9,
  0)), copied whole (four `move.l' and a `move.w'); the variable's
  set formed in a 32-byte frame set. }

procedure fixupchildren(
    var t: il_$node_ptr_t;
    in r: integer;
    in f: boolean);
var
  n: il_$node_ptr_t;
  rr: integer;
  ff: boolean;
  v: integer;
  vv: integer;
  e: g_opt_stmt_ptr_t;
  k: integer;
begin
  rr := r;
  n := t;
  ff := f;
  if n = nil then
    return;
  if (n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
     (g_opt_tree_ptr_t(n)^.owner = nil) then
    g_opt_tree_ptr_t(n)^.owner := opt_4009c[rr]
  else if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if dom(opt_4009c[rr]^.block, g_opt_tree_ptr_t(n)^.owner^.block) then
      g_opt_tree_ptr_t(n)^.owner := opt_4009c[rr];
  case n^.kind of
    143, 137:
      for k := 1 to g_opt_tree_ptr_t(n)^.count do
        fixupchildren(g_opt_tree_ptr_t(n)^.opnd[k], rr, ff);
    147, 205, 146:
      fixupchildren(n^.xp[6], rr, ff);
    145: begin
      fixupchildren(n^.xp[6], rr, ff);
      fixupchildren(n^.xp[9], rr, ff);
    end;
    164: begin
      fixupchildren(n^.xp[5], rr, ff);
      fixupchildren(n^.xp[6], rr, ff);
    end;
    171:
      fixupchildren(n^.xp[4], rr, ff);
    175:
      fixupchildren(n^.xp[4], rr, ff);
    110, 109:
      if ff then begin
        v := find_var(n);
        if v > 0 then begin
          e := opt_4009c[rr];
          opt_main_$ensure_var_set(e^.vset);
          e^.vset^ := e^.vset^ + [v];
          if e^.vars^[v] = nil then begin
            e^.vars^[v] := mem_$alloc(opt_main_18, 18);
            if e^.vars^[v] = nil then
              cgerr_no_source(9, 0);
            e^.vars^[v]^ := opt_4009c[opt_region]^.vars^[v]^;
            e^.vars^[v]^.count := 0;
            vv := v;
            make_motioned_ud_chain(vv, rr, opt_4009c[rr]);
          end;
        end;
      end;
    otherwise
  end;
end;

{ notalreadymoved - tree t may still be moved to its loop's mark: not
  marked 12; the block it would go to (opt_loop_hoist's for an
  operator, and outside C for a 147 or 146, else the current
  preheader) exists, is not dominated by... (for a 147/146 whose
  hoisting block is not that block, that block must not dominate it),
  is a latch whose first statement is the mark (139), and t is not
  among the mark's operands already.

  0x0D96CE, 0x146 bytes: t by address; the result in D2; the hoisting
  table's words zero-extended. }

function notalreadymoved(
    in t: il_$node_ptr_t): boolean;
var
  n: il_$node_ptr_t;
  b: g_opt_block_ptr_t;
  m: g_opt_stmt_ptr_t;
  k: integer;
begin
  notalreadymoved := false;
  n := t;
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if 12 in g_opt_tree_ptr_t(n)^.flags then
      return;
  if n^.kind = 137 then begin
    if opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt] = 0 then
      return;
    b := g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]];
  end
  else
    b := preh;
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
    if (n^.kind = 147) or (n^.kind = 146) then begin
      if opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt] = 0 then
        return;
      b := g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]];
    end;
  if b = nil then
    return;
  if (n^.kind = 147) or (n^.kind = 146) then
    if opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt] <> 0 then
      if b <> g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]] then
        if dom(b, g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]]) then
          return;
  if b^.flags.latch then
    if b^.first_stmt^.kind = 139 then begin
      m := b^.first_stmt;
      if m^.eval_count = 0 then
        notalreadymoved := true
      else begin
        for k := 1 to m^.eval_count do
          if m^.eval_opnd[k] = n then
            return;
        notalreadymoved := true;
      end;
    end;
end;

{ movenode - append tree t to its loop's mark (at most 10 operands):
  not a tree marked 12, a reference to a variable of the region's
  table, a tree using a strength reduction temporary, or (outside C) a
  contents of a register (195, 163) of a 111; trees but references
  are marked 15; the tree is used once more and, when the mark's
  block dominates its owner's, its subtrees given to the mark
  (fixupchildren with f true).

  0x0D9814, 0x20C bytes: t by address; the mark found as in
  notalreadymoved; the operand count compared unsigned (`bcc'); the
  true for fixupchildren a constant byte after the routine (0xFF). }

procedure movenode(
    in t: il_$node_ptr_t);
var
  n: il_$node_ptr_t;
  b: g_opt_block_ptr_t;
  m: g_opt_stmt_ptr_t;
  tmp: il_$node_ptr_t;
  rr: integer;
begin
  n := t;
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if 12 in g_opt_tree_ptr_t(n)^.flags then
      return;
  if (n^.kind = 146) or (n^.kind = 205) or (n^.kind = 147) then
    if (n^.xp[6]^.kind = 110) or (n^.xp[6]^.kind = 109) then
      if find_var(n^.xp[6]) <> 0 then
        return;
  if assert_contains_ref_to_sr_temp(n) then
    return;
  if n^.kind = 146 then
    if (n^.xp[6]^.kind = 195) or (n^.xp[6]^.kind = 163) then
      if n^.xp[7] <> nil then
        if n^.xp[7]^.kind = 111 then
          if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
            return;
  if n^.kind = 137 then
    b := g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]]
  else
    b := preh;
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
    if (n^.kind = 147) or (n^.kind = 146) then
      b := g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(n)^.stmt]];
  if not b^.flags.latch then
    return;
  m := b^.first_stmt;
  if m^.kind <> 139 then
    return;
  if not ((n^.kind = 205) or (n^.kind = 147) or (n^.kind = 146) or
          (n^.kind = 145)) then
    if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
      g_opt_tree_ptr_t(n)^.flags := g_opt_tree_ptr_t(n)^.flags + [15];
  if m^.eval_count >= 10 then
    return;
  m^.eval_count := m^.eval_count + 1;
  m^.eval_opnd[m^.eval_count] := n;
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then begin
    adjust_uc(n, 1);
    if dom(m^.block, g_opt_tree_ptr_t(n)^.owner^.block) then begin
      tmp := n;
      rr := m^.hdr.region;
      fixupchildren(tmp, rr, true);
    end;
  end;
end;

{ moveinvariants - walk statement or tree t of a loop, h the block
  its enclosing tree could be hoisted to (0 at a statement): trees
  already moved or marked 15 are left; an operator owned by another
  statement whose hoisting block h dominates is left; trees but
  references are marked 15 (an operator used more than once that
  cannot be hoisted, in a block of the loop that is not its header's
  run, loses it again and is left); then by kind: an operator (opt_on
  16) whose hoisting block differs from h is moved (not an operator
  4..6, 37, 41 at a header whose label is of class 2), its operands
  walked with its hoisting block; a reference (146, 147) likewise
  under opt_on 16, and under opt_on 18 in C a reference through a
  local pointer variable, or a constant-address reference, is moved
  with its constant counted; a register contents (195, 163) or real
  constant (88, 89) operand is walked only when the hoisting block is
  0.

  0x0D9A22, 0x9DA bytes, link #-16, no A5 (loopopt's); t and h by
  value (t's slot passed by address to notalreadymoved, movenode and
  add_constant); h kept in D3 as the operands' hoisting block; the
  operands' kinds tested twice (`seq'/`or.b' of 195, 163, 89, 88, then
  a compare chain of 88, 89, 195, 163 when h is 0); the operators of
  the 6-byte set after the routine (4..6, 37, 41); the header block
  read as il_11c^[preh^.num + 1] (`(0,A0,D1.l)' with D1 the number
  times 4); cargs' +0x284 word for the cpu set (`and.w #0x3FFC;
  lsr.w #2; andi.w #0x714'). }

procedure moveinvariants(
    t: il_$node_ptr_t;
    h: g_opt_num_t); options(val_param); internal;
var
  h2: g_opt_num_t;
  hh: g_opt_num_t;
  k: integer;
  x: il_$node_ptr_t;
  v: il_$node_ptr_t;
  lang: integer;
  hb: g_opt_block_ptr_t;
  sz: integer;
  ok: boolean;
  inreg: boolean;
begin
  h2 := h;
  if t = nil then
    return;
  if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then begin
    if g_opt_tree_ptr_t(t)^.stmt = 0 then
      return;
    if 15 in g_opt_tree_ptr_t(t)^.flags then
      return;
    if t^.kind = 137 then
      if opt_4009c[cur_r] <> g_opt_tree_ptr_t(t)^.owner then
        if opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt] <> 0 then
          if h <> 0 then
            if dom(g_opt_blocks_ptr_t(il_11c)^[h],
                   g_opt_blocks_ptr_t(il_11c)^[opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt]]) then
              return;
    if not ((t^.kind = 205) or (t^.kind = 147) or (t^.kind = 146) or
            (t^.kind = 145)) then
      g_opt_tree_ptr_t(t)^.flags := g_opt_tree_ptr_t(t)^.flags + [15];
    if t^.kind = 137 then
      if opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt] = 0 then
        if g_opt_tree_ptr_t(t)^.uses > 1 then begin
          hb := g_opt_tree_ptr_t(t)^.owner^.block;
          if hb^.depth = 0 then
            return;
          if hb^.serial <> g_opt_blocks_ptr_t(il_11c)^[preh^.num + 1]^.serial then begin
            g_opt_tree_ptr_t(t)^.flags := g_opt_tree_ptr_t(t)^.flags - [15];
            return;
          end;
        end;
  end;

  case t^.kind of
    139:
      for k := 1 to g_opt_stmt_ptr_t(t)^.eval_count do
        moveinvariants(g_opt_stmt_ptr_t(t)^.eval_opnd[k], 0);
    142:
      moveinvariants(g_opt_stmt_ptr_t(t)^.br_cond, 0);
    140: begin
      moveinvariants(g_opt_stmt_ptr_t(t)^.asg_lhs, 0);
      x := g_opt_stmt_ptr_t(t)^.asg_rhs;
      if not ((x^.kind = 89) or (x^.kind = 88)) then
        moveinvariants(x, 0);
      moveinvariants(g_opt_stmt_ptr_t(t)^.asg_x, 0);
    end;

    137, 143: begin
      if 16 in cargs_$options.opt_on then begin
        hh := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
        if (hh <> 0) and (hh <> h) then begin
          hb := g_opt_blocks_ptr_t(il_11c)^[preh^.num + 1];
          if not ((hb^.first_stmt^.kind = 144) and
                  (rshft(ord(il_$node_ptr_t(hb^.first_stmt)^.xc[72]) & 16#3E, 1) = 2) and
                  (t^.kind = 137) and
                  (g_opt_tree_ptr_t(t)^.op in [4..6, 37, 41])) then begin
            if notalreadymoved(t) then
              movenode(t);
            h2 := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
          end;
        end;
      end;
      for k := 1 to g_opt_tree_ptr_t(t)^.count do begin
        x := g_opt_tree_ptr_t(t)^.opnd[k];
        if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
                (x^.kind = 88)) or
           ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
          moveinvariants(x, h2);
      end;
    end;

    146, 147: begin
      lang := rshft(ord(il_180^.xc[377]) & 16#70, 4);
      if (18 in cargs_$options.opt_on) and (lang = 2) then begin
        hh := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
        if (hh <> 0) and (hh <> h) then begin
          { A reference to be hoisted. }
          if lang = 2 then begin
            v := t^.xp[7];
            inreg := false;
            if v <> nil then
              if v^.kind = 110 then
                if find_var(v) <> 0 then
                  inreg := true;
            if not inreg then
              if notalreadymoved(t) then
                movenode(t);
          end
          else if notalreadymoved(t) then begin
            movenode(t);
            add_constant(t, opt_4009c[cur_r]^.block);
          end;
          h2 := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
          lang := rshft(ord(il_180^.xc[377]) & 16#70, 4);
          if lang = 2 then begin
            x := t^.xp[6];
            if (x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
               (x^.kind = 88) then begin
              if h2 = preh^.num then
                return;
              if not (x^.kind in [88, 89, 195, 163]) then
                return;
            end;
            moveinvariants(x, h2);
            return;
          end;
          x := t^.xp[6];
          if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
                  (x^.kind = 88)) or
             ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
            moveinvariants(x, h2);
          return;
        end;

        { Not to be hoisted: a constant reference. }
        if (g_opt_tree_ptr_t(t)^.flags * [2, 3, 4, 12]) <> [] then
          return;
        if (lang <> 2) or ((ord(il_180^.xc[376]) & 16#08) <> 0) or
           preh^.first_stmt^.hdr.b3 or (hh <> 0) then begin
          moveinvariants(t^.xp[6], h2);
          return;
        end;
        if t^.xp[7] <> nil then begin
          { A local pointer variable's target (110, class 3, no base or
            displacement, a frame offset at +58, of 1..5 bytes). }
          v := t^.xp[7];
          ok := false;
          if v^.kind = 110 then
            if t^.xp[6] <> nil then
              if find_var(v) = 0 then
                if (t^.xp[6]^.kind = 146) or (t^.xp[6]^.kind = 195) or
                   (t^.xp[6]^.kind = 163) then
                  if rshft(ord(v^.xc[44]) & 16#F0, 4) = 3 then
                    if v^.xp[7] = nil then
                      if v^.xp[8] = nil then
                        if v^.xp2[14] <> nil then begin
                          sz := ord(v^.xc[10]) & 15;
                          if sz in [1..5] then
                            ok := true;
                        end;
          if not ok then
            { Through a 111 whose +12 is such a variable. }
            if t^.xp[7] <> nil then
              if t^.xp[7]^.kind = 111 then
                if t^.xp[6] <> nil then
                  if (t^.xp[6]^.kind = 146) or (t^.xp[6]^.kind = 195) or
                     (t^.xp[6]^.kind = 163) then begin
                    v := t^.xp[7]^.xp[3];
                    if v^.kind = 110 then
                      if rshft(ord(v^.xc[44]) & 16#F0, 4) = 3 then
                        if v^.xp[7] = nil then
                          if v^.xp[8] = nil then
                            if v^.xp2[14] <> nil then begin
                              sz := ord(v^.xc[10]) & 15;
                              if sz in [1..5] then
                                ok := true;
                            end;
                  end;
          if ok then begin
            sz := ord(v^.xc[10]) & 15;
            if (sz in [4, 5]) and
               (cargs_$options.cpu * [2, 4, 8, 9, 10] = []) then begin
              moveinvariants(t^.xp[6], h2);
              return;
            end;
            if h2 = 0 then
              if notalreadymoved(t) then
                movenode(t);
            add_constant(t, opt_4009c[cur_r]^.block);
            return;
          end;
        end;
        moveinvariants(t^.xp[6], h2);
        return;
      end;

      { Without opt_on 18 (or outside C). }
      if 16 in cargs_$options.opt_on then begin
        hh := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
        if (hh <> 0) and (hh <> h) then begin
          if notalreadymoved(t) then begin
            movenode(t);
            add_constant(t, opt_4009c[cur_r]^.block);
          end;
          h2 := opt_loop_hoist^[g_opt_tree_ptr_t(t)^.stmt];
        end;
      end;
      x := t^.xp[6];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;

    145: begin
      x := t^.xp[6];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
      x := t^.xp[9];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;
    205: begin
      x := t^.xp[6];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;
    164: begin
      x := t^.xp[5];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
      x := t^.xp[6];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;
    175: begin
      x := t^.xp[4];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;
    171: begin
      x := t^.xp[4];
      if not ((x^.kind = 195) or (x^.kind = 163) or (x^.kind = 89) or
              (x^.kind = 88)) or
         ((h2 = 0) and (x^.kind in [88, 89, 195, 163])) then
        moveinvariants(x, h2);
    end;
    otherwise
  end;
end;

{ findlooptail - the first predecessor of loop header l in the same
  loop (its serial) other than l itself, else l.

  0x0DA402, 0x4C bytes: l by address; the result in A0. }

function findlooptail(
    in l: g_opt_block_ptr_t): g_opt_block_ptr_t;
var
  r: g_opt_block_ptr_t;
  j: integer;
begin
  r := l;
  for j := 1 to l^.npreds do
    if (l^.serial = l^.pred[j]^.serial) and (l^.pred[j] <> l) then begin
      r := l^.pred[j];
      exit;
    end;
  findlooptail := r;
end;

{ loopopt - under opt_on 16, 17 or 18: every block is marked visited;
  for each loop header (in reverse depth-first order) whose preheader
  is a latch dominating it and ends in a mark, unless its label is of
  class 11: under opt_on 18 the loop is first checked for calls of the
  routines 15, 47, 16, a branch out of the loop to a label of class 11
  or 13 and a 150 (a non-local exit), and the routine for a block
  marked skip, any of which marks the mark b3; then each block of the
  loop still visited (not b7 or skip) whose loop's other blocks leave
  only to blocks of the same depth (or are dominated by it) has the
  invariants of its region statements (evaluations, branches,
  assignments) moved, and loses its visited mark.  Then checkcses.

  0x0DA44E, 0x426 bytes, link #-68: opt_on 16..18 tested together
  (`and.l #0x7FFFFFFE' of cargs +0x280, `lsr.l #1', `andi.l
  #0x70000'); the first checks' failures share one block (0x0DA5DC:
  b3 set, D3 cleared, then the motion's loop, whose test of the loop
  list fails at once only when the list was walked to its end); the
  labels' classes 11 and 13 `btst' on 0x2800; the region statements'
  numbers compared unsigned (`bhi').

  Not known from the original:
  - how the shared failure block was written (here the flag ok and
    exits). }

procedure loopopt;
var
  k: g_opt_num_t;
  i: g_opt_num_t;
  h: g_opt_num_t;
  b: g_opt_block_ptr_t;
  p: g_opt_block_ptr_t;
  l: g_opt_block_ptr_t;
  tail: g_opt_block_ptr_t;
  x: g_opt_block_ptr_t;
  l2: g_opt_block_ptr_t;
  ok: boolean;
  n: g_opt_num_t;
  t: g_opt_stmt_ptr_t;
  c: integer;
  j: integer;
  first: g_opt_num_t;
  last: g_opt_num_t;
  r: g_opt_num_t;
  leave: boolean;
  cls: integer;
begin
  if cargs_$options.opt_on * [16, 17, 18] = [] then
    return;
  for k := opt_first_block to opt_last_block do
    g_opt_blocks_ptr_t(il_11c)^[k]^.flags.visited := true;
  for i := opt_last_block downto opt_first_block do begin
    h := opt_dfs_block^[i];
    b := g_opt_blocks_ptr_t(il_11c)^[h];
    if not b^.flags.header then
      next;
    p := b^.preheader;
    if p = g_opt_blocks_ptr_t(il_11c)^[h] then
      next;
    if p = nil then
      next;
    if not p^.flags.latch then
      next;
    if not dom(p, g_opt_blocks_ptr_t(il_11c)^[h]) then
      next;
    if b^.first_stmt^.kind = 144 then
      if rshft(ord(il_$node_ptr_t(b^.first_stmt)^.xc[72]) & 16#3E, 1) = 11 then
        next;
    preh := b^.preheader;
    if preh^.first_stmt^.kind <> 139 then
      next;
    l := select_loop(h);
    tail := findlooptail(l);

    if 18 in cargs_$options.opt_on then begin
      ok := true;
      x := l;
      while x <> nil do begin
        for n := x^.first to x^.last do begin
          t := g_opt_stmt_ptr_t(g_opt_nodes_ptr_t(il_120)^[n]);
          leave := false;
          if t^.kind = 137 then begin
            c := g_opt_tree_ptr_t(t)^.op;
            if (c = 15) or (c = 47) or (c = 16) then
              leave := true;
          end;
          if not leave then
            if (t^.kind = 141) or (t^.kind = 150) or (t^.kind = 142) then
              case t^.kind of
                142: begin
                  cls := rshft(ord(t^.br_target^.xc[72]) & 16#3E, 1);
                  if cls in [11, 13] then
                    if opt_4009c[g_opt_stmt_ptr_t(t^.br_target)^.hdr.region]^.block^.serial <>
                       l^.serial then
                      leave := true;
                end;
                141: begin
                  cls := rshft(ord(t^.br_target^.xc[72]) & 16#3E, 1);
                  if cls in [11, 13] then
                    if t^.block^.serial <> l^.serial then
                      leave := true;
                end;
                150:
                  leave := true;
              end;
          if leave then begin
            preh^.first_stmt^.hdr.b3 := true;
            ok := false;
            exit;
          end;
        end;
        if not ok then
          exit;
        x := x^.link;
      end;
      if ok then
        for k := opt_first_block to opt_last_block do
          if g_opt_blocks_ptr_t(il_11c)^[k]^.flags.skip then begin
            preh^.first_stmt^.hdr.b3 := true;
            exit;
          end;
    end;

    while l <> nil do begin
      if not l^.flags.b7 and not l^.flags.skip and l^.flags.visited then begin
        leave := false;
        l2 := select_loop(b^.num);
        while (l2 <> nil) and not leave do begin
          if l2 <> l then begin
            if l2 = tail then
              if not dom(l, l2) then
                leave := true;
            if not leave then
              for j := 1 to l2^.nsucc do
                if l2^.succ^[j]^.serial <> l2^.serial then
                  if not l2^.flags.header then
                    if not dom(l, l2) then
                      if l2^.succ^[j]^.depth <> l2^.depth then begin
                        leave := true;
                        exit;
                      end;
          end;
          l2 := l2^.link;
        end;
        if not leave then begin
          last := l^.last_stmt^.hdr.region;
          first := l^.first_stmt^.hdr.region;
          if first <= last then
            for r := first to last do
              if (opt_4009c[r]^.kind = 139) or (opt_4009c[r]^.kind = 142) or
                 (opt_4009c[r]^.kind = 140) then begin
                cur_r := r;
                moveinvariants(il_$node_ptr_t(opt_4009c[r]), 0);
              end;
          l^.flags.visited := false;
        end;
      end;
      l := l^.link;
    end;
  end;
  checkcses;
end;

{ motion_constants - under opt_on 17 (and not target_properties'
  +0x7F): every block's visited mark cleared; for each loop header (in
  reverse depth-first order) with a preheader ending in a mark and a
  label of class 2, 5 or 8, the real constants (and register
  contents) of the loop's statements are counted and moved (walkt),
  each block once.

  0x0DAA8C, 0x1FC bytes, link #-24: the statement walked at -4, which
  walkt reads through A1; the classes `btst' on 0x124; the statements
  of a block up to its last (or a nil next). }

procedure motion_constants;
var
  s: g_opt_stmt_ptr_t;
  k: g_opt_num_t;
  i: g_opt_num_t;
  h: g_opt_num_t;
  b: g_opt_block_ptr_t;
  l: g_opt_block_ptr_t;
  j: integer;
  x: il_$node_ptr_t;
  cls: integer;

  { walkt - the constants of tree t: an operator's operands (only the
    first of a scaling by a power of two; for operator 41 of a double
    of width 4 (rlen 6 or 7) on a cpu with element 4 and neither 5
    nor 9, the constants 0.5 and 1.0 its expansion uses too); a
    register contents (163, 195) or real constant (88, 89; for these,
    only on a cpu with one of 2, 4, 8, 9, 10 and when not 0.0) is
    counted at the statement's block (the preheader when the statement
    has no region) and moved.

    0x0DA874, 0x208 bytes: motion_constants' frame from A1 (kept in
    D6, passed on); the double 0.5 and 1.0 by address from after the
    routine to rlcontk; the comparison with 0.0 inline fpp_$ words
    (0x0074, 0xFF34) and `beq'; 89 and 88 tested twice (`seq'/`or.b',
    then a compare chain); t's slot passed by address to add_constant,
    notalreadymoved and movenode. }

  procedure walkt(
      t: il_$node_ptr_t); options(val_param);
  var
    k: integer;
  begin
    if t = nil then
      return;
    case t^.kind of
      143, 137:
        if is_scale_candidate(g_opt_tree_ptr_t(t)) then
          walkt(g_opt_tree_ptr_t(t)^.opnd[1])
        else
          for k := 1 to g_opt_tree_ptr_t(t)^.count do begin
            walkt(g_opt_tree_ptr_t(t)^.opnd[k]);
            if g_opt_tree_ptr_t(t)^.op = 41 then
              if 4 in cargs_$options.cpu then
                if cargs_$options.cpu * [5, 9] = [] then
                  if (g_opt_tree_ptr_t(t)^.rlen = 7) or
                     (g_opt_tree_ptr_t(t)^.rlen = 6) then
                    if g_opt_tree_ptr_t(t)^.w26 = 4 then begin
                      walkt(rlcontk(0.5));
                      walkt(rlcontk(1.0));
                    end;
          end;
      205, 147, 146:
        walkt(t^.xp[6]);
      145: begin
        walkt(t^.xp[6]);
        walkt(t^.xp[9]);
      end;
      164: begin
        walkt(t^.xp[5]);
        walkt(t^.xp[6]);
      end;
      175:
        walkt(t^.xp[4]);
      171:
        walkt(t^.xp[4]);
      163, 88, 89, 195: begin
        if (t^.kind = 89) or (t^.kind = 88) then begin
          if cargs_$options.cpu * [2, 4, 8, 9, 10] = [] then
            return;
          if t^.real_value = 0.0 then
            return;
          if not ((t^.kind = 89) or (t^.kind = 88)) then
            return;
        end;
        if s^.hdr.region <> 0 then
          add_constant(t, s^.block)
        else
          add_constant(t, preh);
        if notalreadymoved(t) then
          movenode(t);
      end;
      otherwise
    end;
  end;

begin
  if not (17 in cargs_$options.opt_on) then
    return;
  if target_properties.p_7f then
    return;
  for k := opt_first_block to opt_last_block do
    g_opt_blocks_ptr_t(il_11c)^[k]^.flags.visited := false;
  for i := opt_last_block downto opt_first_block do begin
    h := opt_dfs_block^[i];
    b := g_opt_blocks_ptr_t(il_11c)^[h];
    if not b^.flags.header then
      next;
    if b^.preheader = nil then
      next;
    if b^.preheader^.first_stmt^.kind <> 139 then
      next;
    if b^.first_stmt^.kind <> 144 then
      next;
    cls := rshft(ord(il_$node_ptr_t(b^.first_stmt)^.xc[72]) & 16#3E, 1);
    if not (cls in [2, 5, 8]) then
      next;
    l := select_loop(h);
    preh := l^.preheader;
    while l <> nil do begin
      s := l^.first_stmt;
      if not l^.flags.visited then begin
        l^.flags.visited := true;
        repeat
          case s^.kind of
            140: begin
              walkt(s^.asg_lhs);
              x := s^.asg_rhs;
              if not ((x^.kind = 89) or (x^.kind = 88)) then
                walkt(s^.asg_rhs);
              walkt(s^.asg_x);
            end;
            139:
              for j := 1 to s^.eval_count do
                walkt(s^.eval_opnd[j]);
            142:
              walkt(s^.br_cond);
            151:
              if s^.x48 <> nil then
                walkt(s^.x48);
            otherwise
          end;
          s := s^.next;
        until (s = nil) or (s = l^.last_stmt^.next);
      end;
      l := l^.link;
    end;
  end;
end;
