{ opt_select - the optimizer's flow graph: the basic blocks' depth-first
  orders (dfs, depth_first_dom), their immediate dominators (dominators,
  Lengauer and Tarjan's algorithm with eval and compress; dom reads
  opt_main's dominance matrix), the natural loops (find_loops) and the
  lists of blocks of a loop or a straight run (select_loop,
  select_block_list), and whether a statement starts a block
  (new_block).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0E56D4  0x2B28C4  resetserial
    0x0E5712  0x2B2902  compress
    0x0E575E  0x2B294E  eval
    0x0E5782  0x2B2972  dom
    0x0E57DA  0x2B29CA  select_block_list
    0x0E58FC  0x2B2AEC  select_loop
    0x0E599E  0x2B2B8E  new_block
    0x0E59F8  0x2B2BE8  dfs
    0x0E5A6C  0x2B2C5C  depth_first_dom
    0x0E5B70  0x2B2D60  dominators
    0x0E5D0A  0x2B2EFA  find_loops
    A5 0x3530D4 (cc.m68k), 0x513A80 (cc.a88k): the module's data, a
    word (initialized to 0): the serial number of the latest list.

  The global routines (g_opt.ins.pas) load A5; resetserial, compress
  and eval do not and are internal (resetserial runs on its caller's
  A5).  The blocks are il_11c^[1..il_124] (il.pas's +0x11C and +0x124,
  which the image reaches as fields of a record at il.pas's +0xC0:
  `movea.l #0x169D30,A0', then (92,A0)); they and the routine block
  (il_180^) are read through g_opt.ins.pas's views.

  dpc gaps (docs/dpc-gaps.md): 3 (dominators' new).
}
module opt_select;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

var
  serial: integer := 0;                 { +0 }

define
  dom, select_block_list, select_loop, new_block, dfs, depth_first_dom,
  dominators, find_loops;

{ resetserial - clear every block's serial and start again at 1.

  0x0E56D4, 0x3E bytes: the blocks counted with il_124 (`tst.w; beq'
  then `dbf'); serial stored through the caller's A5. }

procedure resetserial; internal;
var
  k: integer;
begin
  for k := 1 to il_124 do
    g_opt_blocks_ptr_t(il_11c)^[k]^.serial := 0;
  serial := 1;
end;

{ compress - path compression of v's ancestors, keeping in v's label
  the block of least semidominator number on the path.

  0x0E5712, 0x4C bytes: recursive; the numbers compared unsigned
  (`bcc'). }

procedure compress(
    v: g_opt_block_ptr_t); options(val_param); internal;
begin
  if v^.ancestor^.ancestor <> nil then begin
    compress(v^.ancestor);
    if v^.ancestor^.lbl^.sdno < v^.lbl^.sdno then
      v^.lbl := v^.ancestor^.lbl;
    v^.ancestor := v^.ancestor^.ancestor;
  end;
end;

{ eval - v when it is a root of the forest, else (compressed) the label
  of its path.

  0x0E575E, 0x24 bytes: the result in A0. }

function eval(
    v: g_opt_block_ptr_t): g_opt_block_ptr_t; options(val_param); internal;
begin
  if v^.ancestor = nil then
    eval := v
  else begin
    compress(v);
    eval := v^.lbl;
  end;
end;

{ dom - a dominates b: b's row of opt_dom at a's number; false when a
  is b or either is nil.

  0x0E5782, 0x58 bytes: the row of b (+82, zero-extended; the table
  from 0, `lea (0,A2,D1.l)'), its byte at a's number. }

function dom(
    a: g_opt_block_ptr_t;
    b: g_opt_block_ptr_t): boolean;
begin
  dom := false;
  if a <> b then
    if a <> nil then
      if b <> nil then
        dom := opt_dom[b^.num]^[a^.num];
end;

{ select_block_list - the blocks of the region from block first back
  to block stop, linked through link, each given the new serial: when
  first starts a straight run (run, +0 bit 3) and stop is the block
  before it, the run's blocks from first up to the one marked last
  (+0 bit 4); else first's predecessors dominated by stop, then
  theirs, and so on (each block once).

  0x0E57DA, 0x122 bytes, link #-32: serial -1 restarts the numbering
  (resetserial); first - 1 and stop compared as longwords; the list's
  first block kept in D7, its last in D6, and the first pass over
  first's own predecessors flagged in D3 (`st'). }

function select_block_list(
    first: g_opt_num_t;
    stop: g_opt_num_t): g_opt_block_ptr_t;
var
  b: g_opt_block_ptr_t;
  x: g_opt_block_ptr_t;
  head: g_opt_block_ptr_t;
  tail: g_opt_block_ptr_t;
  k: g_opt_num_t;
  j: integer;
  starting: boolean;
begin
  if serial = -1 then
    resetserial
  else
    serial := serial + 1;
  tail := nil;
  b := g_opt_blocks_ptr_t(il_11c)^[first];
  if b^.flags.run and (first - 1 = stop) then begin
    k := first;
    repeat
      x := g_opt_blocks_ptr_t(il_11c)^[k];
      x^.serial := serial;
      x^.link := nil;
      if tail <> nil then
        tail^.link := x;
      tail := x;
      k := k + 1;
    until tail^.flags.last;
    select_block_list := g_opt_blocks_ptr_t(il_11c)^[first];
  end
  else begin
    head := nil;
    starting := true;
    repeat
      for j := 1 to b^.npreds do
        if dom(g_opt_blocks_ptr_t(il_11c)^[stop], b^.pred[j]) then begin
          x := b^.pred[j];
          if serial <> x^.serial then begin
            x^.link := nil;
            if tail = nil then
              head := x
            else
              tail^.link := x;
            x^.serial := serial;
            tail := x;
          end;
        end;
      if starting then begin
        b := head;
        starting := false;
      end
      else
        b := b^.link;
    until b = nil;
    select_block_list := head;
  end;
end;

{ select_loop - the blocks of the natural loop headed by block h: h,
  then the predecessors h dominates of each block in the list (each
  once, by the new serial), linked through link.

  0x0E58FC, 0xA2 bytes, link #-28: h's block kept in D5 for the result,
  the list's last in D6. }

function select_loop(
    h: g_opt_num_t): g_opt_block_ptr_t;
var
  head: g_opt_block_ptr_t;
  tail: g_opt_block_ptr_t;
  p: g_opt_block_ptr_t;
  x: g_opt_block_ptr_t;
  j: integer;
begin
  if serial = -1 then
    resetserial
  else
    serial := serial + 1;
  head := g_opt_blocks_ptr_t(il_11c)^[h];
  head^.serial := serial;
  head^.link := nil;
  tail := head;
  p := head;
  repeat
    for j := 1 to p^.npreds do
      if dom(g_opt_blocks_ptr_t(il_11c)^[h], p^.pred[j]) then begin
        x := p^.pred[j];
        if serial <> x^.serial then begin
          x^.serial := serial;
          x^.link := nil;
          tail^.link := x;
          tail := x;
        end;
      end;
    p := p^.link;
  until p = nil;
  select_loop := head;
end;

{ new_block - statement t starts a basic block: a label (144), an
  empty evaluation (139 with no operands), or anything after a branch
  (142, 141, 150).

  0x0E599E, 0x5A bytes: the result in D0 from `clr.b'. }

function new_block(
    t: g_opt_stmt_ptr_t): boolean;
begin
  new_block := false;
  if t^.kind = 144 then
    new_block := true
  else if (t^.kind = 139) and (t^.eval_count = 0) then
    new_block := true
  else if t^.prev <> nil then
    if (t^.prev^.kind = 142) or (t^.prev^.kind = 141) or
       (t^.prev^.kind = 150) then
      new_block := true;
end;

{ dfs - visit the blocks reached from b (b's successors first) and
  number them in postorder, n counting down: opt_dfs_block^[n] the
  block, opt_dfs_number^[block] n.

  0x0E59F8, 0x74 bytes: the visited flag (+0 bit 5); the successors
  (+108, count at +106); n a word by address (`subq.w #1,(A2)'). }

procedure dfs(
    b: g_opt_block_ptr_t;
    var n: g_opt_num_t);
var
  j: integer;
begin
  if not b^.flags.visited then begin
    b^.flags.visited := true;
    for j := 1 to b^.nsucc do
      dfs(b^.succ^[j], n);
    opt_dfs_block^[n] := b^.num;
    opt_dfs_number^[b^.num] := n;
    n := n - 1;
  end;
end;

{ depth_first_dom - the depth-first spanning tree from b for
  dominators: each block its own label and semidominator, appended to
  rtn's preorder list (pre_first .. pre_last, numbered from 1, its
  depth one more than the previous block's) on the way down and to its
  postorder list on the way up; an unvisited successor (semi nil)
  gets b as its parent.

  0x0E5A6C, 0x104 bytes: both parameters by address (opt_main passes
  il_180's address and a block table entry's, the recursion an edge's
  first field); the successor list's first edge is tested before the
  loop (`tst.l (A2)': its target, not the list). }

procedure depth_first_dom(
    var rtn: il_$node_ptr_t;
    var b: g_opt_block_ptr_t);
var
  e: g_opt_edge_ptr_t;
begin
  b^.semi := b;
  b^.lbl := b;
  b^.post_prev := nil;
  with g_opt_rtn_ptr_t(rtn)^ do begin
    if pre_first = nil then begin
      pre_first := b;
      b^.sdno := 1;
      b^.pre_depth := 1;
    end
    else begin
      pre_last^.pre_next := b;
      b^.sdno := pre_last^.sdno + 1;
      b^.pre_depth := pre_last^.pre_depth + 1;
    end;
    b^.pre_prev := pre_last;
    pre_last := b;
  end;
  e := b^.succs;
  if e^.dest <> nil then
    while e <> nil do begin
      if e^.dest^.semi = nil then begin
        e^.dest^.parent := b;
        depth_first_dom(rtn, e^.dest);
      end;
      e := e^.next_succ;
    end;
  with g_opt_rtn_ptr_t(rtn)^ do begin
    if post_first = nil then begin
      post_first := b;
      b^.post_no := 1;
    end
    else begin
      post_last^.post_next := b;
      b^.post_no := post_last^.post_no + 1;
    end;
    b^.post_prev := post_last;
    post_last := b;
  end;
end;

{ dominators - the immediate dominator (idom) of each of rtn's blocks
  but root, from the preorder list taken backwards: the semidominator
  from the predecessors (a nil predecessor ends their list), the block
  put in its semidominator's bucket (a 16-byte edge from new) and
  linked to its parent, whose bucket is then emptied; then forwards,
  the idoms corrected and the working fields (+56..+77) cleared, and
  every block of the routine with an idom gets it as dom too.

  0x0E5B70, 0x19A bytes, link #-44: rtn by address, root by value; a
  nil from new is cgerr_no_source(9, 0) (0x0E5BF0); the clearing is
  five `clr.l' and a `clr.w' (docs/rev889-patterns.md 57); the last
  loop over opt_first_block..opt_last_block (`bcs', `dbf').

  Not known from the original:
  - how the working fields were cleared (taken as six assignments). }

procedure dominators(
    var rtn: il_$node_ptr_t;
    root: g_opt_block_ptr_t);
var
  v: g_opt_block_ptr_t;
  u: g_opt_block_ptr_t;
  w: g_opt_block_ptr_t;
  e: g_opt_edge_ptr_t;
  c: g_opt_edge_ptr_t;
  k: g_opt_num_t;
begin
  v := g_opt_rtn_ptr_t(rtn)^.pre_last;
  while v <> root do begin
    e := v^.preds_list;
    while e <> nil do begin
      if e^.src = nil then
        exit;
      u := eval(e^.src);
      if u^.sdno < v^.sdno then begin
        v^.semi := u^.semi;
        v^.sdno := u^.sdno;
      end;
      e := e^.next_pred;
    end;
    new(c);
    if c = nil then
      cgerr_no_source(9, 0);
    c^.dest := v;
    c^.next_pred := v^.semi^.bucket;
    v^.semi^.bucket := c;
    v^.ancestor := v^.parent;
    if v^.parent <> nil then
      while v^.parent^.bucket <> nil do begin
        w := v^.parent^.bucket^.dest;
        v^.parent^.bucket := v^.parent^.bucket^.next_pred;
        u := eval(w);
        if u^.sdno < w^.sdno then
          w^.idom := u
        else
          w^.idom := v^.parent;
      end;
    v := v^.pre_prev;
  end;
  root^.parent := nil;
  root^.bucket := nil;
  root^.ancestor := nil;
  root^.lbl := nil;
  root^.semi := nil;
  root^.sdno := 0;
  v := root^.pre_next;
  while v <> nil do begin
    if (v^.idom <> v^.semi) and (v^.idom <> nil) then
      v^.idom := v^.idom^.idom;
    v^.parent := nil;
    v^.bucket := nil;
    v^.ancestor := nil;
    v^.lbl := nil;
    v^.semi := nil;
    v^.sdno := 0;
    v := v^.pre_next;
  end;
  for k := opt_first_block to opt_last_block do
    with g_opt_blocks_ptr_t(il_11c)^[k]^ do
      if idom <> nil then
        dom := idom;
end;

{ find_loops - for each block in depth-first order (opt_dfs_block from
  opt_first_block to opt_last_block) not skipped and with at most 512
  predecessors: the predecessors numbered at or after it are its back
  edges' sources (kept in a frame array), the others counted (nfwd);
  when it has back edges and dominates each of their sources (or is
  one), it heads a loop: marked header, its dominator noted as
  preheader (and marked latch when it is one of its predecessors),
  and each block of the loop (select_loop) one loop deeper, with the
  header as its loop.

  0x0E5D0A, 0x182 bytes, link #-2084: the array at -2048 (512
  pointers), reached as (-2052,A0) with A0 the frame pointer plus 4
  per entry; the depth-first numbers compared unsigned (`bcs'); the
  loop counter a frame word compared with opt_last_block at the end.

  Not known from the original:
  - why the depth is tested positive after it is incremented. }

procedure find_loops;
var
  k: g_opt_num_t;
  h: g_opt_num_t;
  is_loop: boolean;
  b: g_opt_block_ptr_t;
  nback: integer;
  nfwd: integer;
  j: integer;
  l: g_opt_block_ptr_t;
  back: array [1..512] of g_opt_block_ptr_t;
begin
  k := opt_first_block - 1;
  repeat
    k := k + 1;
    h := opt_dfs_block^[k];
    is_loop := true;
    b := g_opt_blocks_ptr_t(il_11c)^[h];
    if not b^.flags.skip and (b^.npreds <= 512) then begin
      nback := 0;
      nfwd := 0;
      for j := 1 to b^.npreds do
        if opt_dfs_number^[b^.pred[j]^.num] >= opt_dfs_number^[h] then begin
          nback := nback + 1;
          back[nback] := b^.pred[j];
        end
        else
          nfwd := nfwd + 1;
      if nback = 0 then
        is_loop := false;
      for j := 1 to nback do
        if h <> back[j]^.num then
          if not dom(g_opt_blocks_ptr_t(il_11c)^[h], back[j]) then
            is_loop := false;
      if is_loop then begin
        b^.flags.header := true;
        b^.preheader := b^.dom;
        if b^.idom <> nil then
          for j := 1 to b^.npreds do
            if b^.idom = b^.pred[j] then begin
              b^.idom^.flags.latch := true;
              exit;
            end;
        l := select_loop(h);
        while l <> nil do begin
          l^.depth := l^.depth + 1;
          if l^.depth > 0 then
            l^.loop := g_opt_blocks_ptr_t(il_11c)^[h];
          l := l^.link;
        end;
      end;
      b^.nfwd := nfwd;
    end;
  until k = opt_last_block;
end;
