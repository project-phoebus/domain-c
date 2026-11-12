{ fg_utils - the flow graph's utilities (cc.a88k only): blocks dropped
  and forwarded, the successor lists ordered, depth-first numbering,
  intervals and loop headers, empty blocks and senseless loops, the
  dominators, join birthpoints (the SSA form of a live range) put in
  and dropped.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x234980  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x2349A2  fg_utils_$begin_compilation
    --------  0x234A46  fg_utils_$init_for_routine
    --------  0x234A74  fg_utils_$end_routine
    --------  0x234A92  fg_utils_$end_compilation
    --------  0x234A94  n_edges (internal)
    --------  0x234AB8  fg_utils_$drop_this_block
    --------  0x234C3C  fg_utils_$forward_this_block
    A5 0x48646C: the module's data: three heaps (+0 the join
    birthpoint instructions', +24 their inputs', +48 the dominator
    buckets'), then the cells the routines below use.

  TODO(pascal) fg_utils: 47 of 53 routines (with the insert's
  utils_ins_$operands_instruction; the first ones in address order,
  through fg_utils_$recompute_dominators_and_dfs_lists, 0x237482); not
  translated yet: mark_live_on_entry_blocks,
  mark_active_on_exit_blocks, init_and_compute_exposure,
  fg_utils_$compute_lr_lifetime, compute_reach_of_definition,
  fg_utils_$recompute_ssa_form_for_lr (they stay extern through
  backend.ins.pas meanwhile).

  Not known from the original: every local and parameter name, the
  module variables' names. }

module fg_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

var
  jbi_heap: mrh_$heap_t;                { +0: the join birthpoint
                                          instructions }
  fg_unused_20: integer32;              { +20 }
  jbi_input_heap: mrh_$heap_t;          { +24: their inputs (ut_jbi_t) }
  fg_unused_44: integer32;              { +44 }
  bucket_heap: mrh_$heap_t;             { +48: the dominator buckets }
  rdfs_last: bb_ptr_t;                  { +68: the reverse depth-first
                                          search's last block }
  rdfs_first: bb_ptr_t;                 { +72: and its first }
  dfs_level: integer32;                 { +76: compute_dfs_lists' debug
                                          level }
  order_count: integer32;               { +80: the blocks
                                          order_successor_lists has
                                          numbered (their order its low
                                          word) }
  dom_rtn: rtn_ptr_t;                   { +84: the routine the dominators
                                          are computed for (its l192 the
                                          vectors' size) }
  final_bb: bb_ptr_t;                   { +88: the block add_final_edges
                                          gives an edge to }
  fg_92: integer;                       { +92 }
  fg_94: boolean;                       { +94: set for each routine:
                                          intervals clears nothing }
  fg_96: boolean;                       { +96: set for each routine:
                                          compute_dfs_lists clears
                                          nothing }

{ fg_utils_$begin_compilation - the three heaps made.

  0x2349A2, 0x52 bytes: flags and default size pushed as one longword
  (pattern 105). }

procedure fg_utils_$begin_compilation;
begin
  mrh_$initialize(bucket_heap, 0, 16, 'dominator bucket heap%');
  mrh_$initialize(jbi_input_heap, 0, 16, 'join_birthpoin_input heap%');
  mrh_$initialize(jbi_heap, 1, 0, 'join birthpoint instruction heap%');
end;

{ fg_utils_$init_for_routine - the join birthpoint instructions' heap
  emptied, +94 and +96 set, lir_main_c8e (definitions may be located)
  cleared.

  0x234A46, 0x2E bytes. }

procedure fg_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(jbi_heap);
  fg_96 := true;
  fg_94 := true;
  lir_main_c8e := false;
end;

{ fg_utils_$end_routine - the join birthpoint inputs' heap emptied.

  0x234A74, 0x1E bytes. }

procedure fg_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(jbi_input_heap);
end;

{ fg_utils_$end_compilation - nothing.

  0x234A92, 0x2 bytes, no A5. }

procedure fg_utils_$end_compilation;
begin
end;

{ n_edges - the edges on the list from e, chained at next_succ when succ
  else at next_pred.

  0x234A94, 0x24 bytes, no frame: e (4), succ (8) a byte. }

function n_edges(
    e: fg_edge_ptr_t;
    succ: boolean): integer32; options(val_param, internal);
var
  n: integer32;
begin
  n := 0;
  while e <> nil do begin
    n := n + 1;
    if succ then
      e := e^.next_succ
    else
      e := e^.next_pred;
  end;
  n_edges := n;
end;

{ fg_utils_$drop_this_block - bb taken out of the flow graph: its edges
  in off their sources' lists of edges out, its edges out off their
  targets' lists of edges in; after phase 1 out of the code order
  (next, next114: the routine's +76 and +72 the ends) and the chains at
  l54/l58 relinked round it; out of its interval head's list of members
  (the head's l74, or the routine's l84 without a head, chained at
  l78); the routine's block count down; bb marked forwarded.

  0x234AB8, 0x184 bytes: rtn (8) in D1, bb (12) in D0; the code order's
  second test on the flags of the store of bb's next (pattern 111). }

procedure fg_utils_$drop_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t);
var
  e: fg_edge_ptr_t;
  next: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  src: bb_ptr_t;
  p: bb_ptr_t;
  h: bb_ptr_t;
begin
  e := bb^.preds;
  while e <> nil do begin
    next := e^.next_pred;
    src := e^.source;
    prev := nil;
    f := src^.succs;
    while (f <> nil) and (f <> e) do begin
      prev := f;
      f := f^.next_succ;
    end;
    if f <> nil then
      if prev = nil then
        src^.succs := f^.next_succ
      else
        prev^.next_succ := f^.next_succ;
    e := next;
  end;
  e := bb^.succs;
  while e <> nil do begin
    next := e^.next_succ;
    src := e^.target;
    prev := nil;
    f := src^.preds;
    while (f <> nil) and (f <> e) do begin
      prev := f;
      f := f^.next_pred;
    end;
    if f <> nil then
      if prev = nil then
        src^.preds := f^.next_pred
      else
        prev^.next_pred := f^.next_pred;
    e := next;
  end;
  if at_backend_phase > phase$fga then begin
    if bb^.next114 = nil then
      rtn^.bbs := bb^.next
    else
      bb^.next114^.next := bb^.next;
    if bb^.next = nil then
      rtn^.bbs72 := bb^.next114
    else
      bb^.next^.next114 := bb^.next114;
    bb^.next114 := nil;
    bb^.next := nil;
    if bb^.l54 <> nil then
      if bb^.l54^.l58 = bb then
        bb^.l54^.l58 := bb^.l58;
    if bb^.l58 <> nil then
      if bb^.l58^.l54 = bb then
        bb^.l58^.l54 := bb^.l54;
  end;
  p := nil;
  if bb^.l70 = nil then begin
    if rtn^.l84 = bb then
      rtn^.l84 := bb^.l78
    else
      p := rtn^.l84;
  end
  else begin
    h := bb^.l70;
    if h^.l74 = bb then
      h^.l74 := bb^.l78
    else
      p := h^.l74;
  end;
  if p <> nil then begin
    while p^.l78 <> bb do
      p := p^.l78;
    p^.l78 := bb^.l78;
  end;
  rtn^.nbbs := rtn^.nbbs - 1;
  bb^.f.forwarded := true;
end;

{ fg_utils_$forward_this_block - bb, a block whose one instruction is
  the jump (or a label and the jump), forwarded: each edge into bb made
  an edge into the jump's target (or the existing edge from the same
  source used, its operands retargeted); for a jump through a register
  (ip_reg, ip_reg_physical, ip_reg_like or case_jump_base), each
  source's branch operand that takes a register replaced by the jump's
  register operand (a reader of a final segment of its live range in the
  source, made and put on the exposed list when new, before RA), the
  source given bb's edges out (hidden); a source whose operand cannot
  take it keeps its edge into bb.  When no edge stays, bb's labels move
  to the target's head, the jump's register segment is excised (before
  RA) and bb dropped.  Traced at debug level 3.

  0x234C3C, 0x3C8 bytes: rtn (8), bb (12), jump (16); the target (-4),
  the edges in (-52), the next (-28), the source (-20), the edge kept
  (-48); kept a source's +18 bit 7 in D5, changed D6; the operands
  walked with D2 = 12k, D3 = 4k (the opcode's operand forms). }

procedure fg_utils_$forward_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    jump: instr_ptr_t);
label
  9;
var
  kind: integer;
  tgt: bb_ptr_t;
  changed: boolean;
  keep: boolean;
  e: fg_edge_ptr_t;
  next: fg_edge_ptr_t;
  src: bb_ptr_t;
  dup: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  ins: instr_ptr_t;
  k: integer32;
  form: integer;
  created: boolean;
  lts: lts_ptr_t;
  op: opnd_ptr_t;
  a: opnd_ptr_t;
  i: instr_ptr_t;
begin
  kind := ord(jump^.opnds[1].h.kind);
  if kind = ord(operand$flow_graph_edge) then begin
    tgt := fg_edge_ptr_t(jump^.opnds[1].ptr)^.target;
    if at_backend_switches.level >= 3 then
      vfmt_$write('Enter fg_utils_$forward_this_block: BB#%3ZWD to BB#%3ZWD%.',
                  bb^.num, tgt^.num);
    if tgt = bb then
      goto 9;
  end
  else begin
    if not (kind in [ord(operand$ip_reg), ord(operand$ip_reg_physical),
                     ord(operand$ip_reg_like), ord(operand$case_jump_base)]) then
      bug_check('FG_UTILS_$FORWARD_THIS_BLOCK:  branch target not understood%$');
    if at_backend_switches.level >= 3 then
      vfmt_$write('Enter fg_utils_$forward_this_block: BB#%3ZWD to <some register>%.',
                  bb^.num);
    tgt := nil;
  end;
  changed := false;
  e := bb^.preds;
  bb^.preds := nil;
  while e <> nil do begin
    next := e^.next_pred;
    src := e^.source;
    dup := nil;
    f := src^.succs;
    while f <> nil do begin
      if f <> e then
        if f^.target = tgt then
          dup := f;
      f := f^.next_succ;
    end;
    if (dup = nil) and (tgt <> nil) then begin
      e^.target := tgt;
      e^.next_pred := tgt^.preds;
      tgt^.preds := e;
    end
    else begin
      keep := src^.f.hidden_successor_edges;
      ins := src^.first;
      while ins <> nil do begin
        for k := 1 to ins^.h.nopnds do
          if ins^.opnds[k].h.kind = operand$flow_graph_edge then
            if fg_edge_ptr_t(ins^.opnds[k].ptr) = e then
              if tgt <> nil then
                ins^.opnds[k].ptr := dup
              else begin
                form := instr_attr_view_ptr_t(addr(instruction_attributes[ins^.opc]))^.opnds[k].form;
                if not ((form = ord(of$ip_reg_or_basic_block))
                        or (form = ord(of$ip_reg_or_long_pc_disp))) then
                  keep := true
                else begin
                  f := bb^.succs;
                  while f <> nil do begin
                    src^.f.hidden_successor_edges := true;
                    discard(lir_$add_flow_graph_edge(src, f^.target));
                    f := f^.next_succ;
                  end;
                  ins^.opnds[k] := jump^.opnds[1];
                  if at_backend_phase <= phase$ra then begin
                    lts := utils_$get_final_lts(jump^.opnds[1].lts^.lr, src, created);
                    if created then begin
                      utils_$put_lts_on_exposed_list(lts);
                      if lir_main_c8e then begin
                        lts^.l44 := jump^.opnds[1].lts^.l44;
                        lts^.l28 := lts_ptr_t(lts^.l44)^.l28;
                        lts_ptr_t(lts^.l44)^.l28 := lts;
                      end;
                    end;
                    ins^.opnds[k].lts := lts;
                    ins^.opnds[k].link := nil;
                    lts^.rrp := lts^.rrp + [rrp$read];
                    op := addr(ins^.opnds[k]);
                    if lts^.refs = nil then
                      lts^.refs := op
                    else begin
                      a := lts^.refs;
                      while a^.link <> nil do
                        a := a^.link;
                      a^.link := op;
                    end;
                  end;
                end;
              end;
        ins := ins^.next;
      end;
      if keep then begin
        e^.next_pred := bb^.preds;
        bb^.preds := e;
        changed := true;
      end
      else if src^.succs = e then
        src^.succs := e^.next_succ
      else begin
        f := src^.succs;
        while f^.next_succ <> e do
          f := f^.next_succ;
        f^.next_succ := e^.next_succ;
      end;
    end;
    e := next;
  end;
  if not changed then begin
    if bb^.first <> nil then
      if instruction_attributes[bb^.first^.opc].class = class$label then begin
        if tgt = nil then
          goto 9;
        i := bb^.first;
        repeat
          i^.bb := tgt;
          if i^.next = nil then
            exit;
          if instruction_attributes[i^.next^.opc].class <> class$label then
            exit;
          i := i^.next;
        until false;
        i^.next := tgt^.first;
        if tgt^.first <> nil then
          tgt^.first^.prev := i
        else
          tgt^.last := i;
        tgt^.first := bb^.first;
      end;
    if jump^.opnds[1].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if at_backend_phase <= phase$ra then
        utils_$excise_lts_cleanly(jump^.opnds[1].lts, true);
    fg_utils_$drop_this_block(rtn, bb);
  end;
9:
end;

{ order_successor_lists - bb's successor lists ordered, depth first
  (order 65535 while in progress, then order_count's low word): the
  edges to successors whose path_to is 2 moved to the end, those of
  path_to 3 to the front (unless bb's own path_to is 3); bb's path_to
  the largest of its successors'.

  0x2350BE, 0xE0 bytes, no A5 load (the A5 of its caller): bb (8) in
  A3; the moved edges' head D2, tail D4, the previous edge D3. }

function order_successor_lists(
    bb: bb_ptr_t): integer; options(val_param, internal);
var
  first: fg_edge_ptr_t;
  last: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
  k: integer;
begin
  bb^.order := 65535;
  if bb^.f14.path_to = 0 then begin
    first := nil;
    prev := nil;
    e := bb^.succs;
    while e <> nil do begin
      t := e^.target;
      if t^.order = 0 then
        k := order_successor_lists(t)
      else
        k := t^.f14.path_to;
      case k of
        0:
          prev := e;
        2: begin
          if prev = nil then
            bb^.succs := e^.next_succ
          else
            prev^.next_succ := e^.next_succ;
          if first = nil then
            first := e
          else
            last^.next_succ := e;
          last := e;
        end;
        3: begin
          if e <> bb^.succs then
            if bb^.f14.path_to <> 3 then begin
              prev^.next_succ := e^.next_succ;
              e^.next_succ := bb^.succs;
              bb^.succs := e;
            end;
          prev := e;
        end;
        otherwise
          ;
      end;
      if bb^.f14.path_to < k then
        bb^.f14.path_to := k;
      e := e^.next_succ;
    end;
    if first <> nil then begin
      last^.next_succ := bb^.succs;
      bb^.succs := first;
    end;
  end;
  order_count := order_count + 1;
  bb^.order := order_count & 16#FFFF;
  order_successor_lists := bb^.f14.path_to;
end;

{ add_final_edges - every block reachable from bb marked (+19 bit 3),
  depth first; a normal block with an edge in from a block not before
  it in the order (a loop's latch) given a hidden edge to final_bb.

  0x23519E, 0x78 bytes, no A5 load: bb (8) in A2. }

procedure add_final_edges(
    bb: bb_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
begin
  bb^.f.b19_3 := true;
  e := bb^.succs;
  while e <> nil do begin
    if not e^.target^.f.b19_3 then
      add_final_edges(e^.target);
    e := e^.next_succ;
  end;
  if bb^.f14.kind = 0 then begin
    e := bb^.preds;
    while e <> nil do begin
      if bb^.order >= e^.source^.order then begin
        bb^.f.hidden_successor_edges := true;
        discard(lir_$add_flow_graph_edge(bb, final_bb));
        return;
      end;
      e := e^.next_pred;
    end;
  end;
end;

{ depth_first_search - bb visited: its interval members (+138) itself,
  on the stack (+19 bit 1), a loop head (+19 bit 2) cleared, +150
  itself, +46, +142, +146 cleared; numbered in preorder (w8, the
  routine's dfs_first .. dfs_last, chained at l98 and back at l102);
  each successor not visited visited with bb its parent (l106), one on
  the stack marked a loop head; then off the stack and put in postorder
  (order; the routine's bbs72 the first, bbs the last, chained at
  next114 and back at next).

  0x235216, 0xE4 bytes, no A5: rtn (8) in A3, bb (12) in A2. }

procedure depth_first_search(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
begin
  bb^.members := bb;
  bb^.f.b19_1 := true;
  bb^.f.b19_2 := false;
  bb^.l150 := bb;
  bb^.l46 := nil;
  bb^.next142 := nil;
  bb^.mark146 := 0;
  if rtn^.dfs_first = nil then begin
    rtn^.dfs_first := bb;
    bb^.w8 := 1;
  end
  else begin
    rtn^.dfs_last^.l98 := fg_edge_ptr_t(bb);
    bb^.w8 := rtn^.dfs_last^.w8 + 1;
  end;
  bb^.l102 := rtn^.dfs_last;
  rtn^.dfs_last := bb;
  e := bb^.succs;
  while e <> nil do begin
    t := e^.target;
    if t^.members = nil then begin
      t^.l106 := bb;
      depth_first_search(rtn, e^.target);
    end
    else if t^.f.b19_1 then
      t^.f.b19_2 := true;
    e := e^.next_succ;
  end;
  bb^.f.b19_1 := false;
  if rtn^.bbs72 = nil then begin
    rtn^.bbs72 := bb;
    bb^.order := 1;
  end
  else begin
    rtn^.bbs^.next114 := bb;
    bb^.order := rtn^.bbs^.order + 1;
  end;
  bb^.next := rtn^.bbs;
  rtn^.bbs := bb;
end;

{ final_edge_fixup - the blocks numbered again by a depth-first search
  from the first block (the routine's +64..+79 cleared first; nbbs the
  last postorder number); the edges in from blocks the search did not
  reach dropped (each block in postorder), then those from forwarded
  blocks (each block in preorder from the last).

  0x2352FA, 0xD8 bytes, no A5: rtn (8) in D2; the first block (-24). }

procedure final_edge_fixup(
    rtn: rtn_ptr_t); options(val_param, internal);
var
  b: bb_ptr_t;
  x: bb_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
begin
  b := rtn^.bbs;
  rtn^.dfs_first := nil;
  rtn^.dfs_last := nil;
  rtn^.bbs72 := nil;
  rtn^.bbs := nil;
  depth_first_search(rtn, b);
  rtn^.nbbs := rtn^.bbs^.order;
  x := rtn^.bbs72;
  while x <> nil do begin
    prev := nil;
    e := x^.preds;
    while e <> nil do begin
      if e^.source^.members <> nil then
        prev := e
      else if prev = nil then
        x^.preds := e^.next_pred
      else
        prev^.next_pred := e^.next_pred;
      e := e^.next_pred;
    end;
    x := x^.next114;
  end;
  x := rtn^.dfs_last;
  while x <> nil do begin
    prev := nil;
    e := x^.preds;
    while e <> nil do begin
      if e^.source^.f.forwarded then begin
        if prev = nil then
          x^.preds := e^.next_pred
        else
          prev^.next_pred := e^.next_pred;
      end
      else
        prev := e;
      e := e^.next_pred;
    end;
    x := x^.l102;
  end;
end;

{ reorder_start_bb_successor_list - of the start block bb's edges out,
  the first to an entry block whose ENTRY's block is not an ENTRY
  statement's (kind 167) moved to the end (the ENTRY must be its
  block's first instruction).  Without one the image appends whatever
  its register last held (kept out: nothing is moved).

  0x2353D2, 0xA6 bytes, no A5: bb (8) in D2; the previous edge D3. }

procedure reorder_start_bb_successor_list(
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  ins: instr_ptr_t;
  found: fg_edge_ptr_t;
begin
  prev := nil;
  found := nil;
  e := bb^.succs;
  while (e <> nil) and (found = nil) do begin
    if e^.target^.f.entry then begin
      ins := e^.target^.first;
      if ins^.opnds[1].h.kind <> operand$symbol_definition then
        bug_check('FG_UTILS_$reorder_start_bb_successor_list --- ENTRY instruction is no longer first within basic block%$');
      if il_$node_ptr_t(ins^.opnds[1].link)^.kind <> 167 then begin
        if prev = nil then
          bb^.succs := e^.next_succ
        else
          prev^.next_succ := e^.next_succ;
        e^.next_succ := nil;
        found := e;
      end;
    end;
    if found = nil then begin
      prev := e;
      e := e^.next_succ;
    end;
  end;
  if found <> nil then
    if bb^.succs = nil then
      bb^.succs := found
    else begin
      f := bb^.succs;
      while f^.next_succ <> nil do
        f := f^.next_succ;
      f^.next_succ := found;
    end;
end;

{ fg_utils_$compute_dfs_lists - the flow graph's depth-first lists made
  again: (after the first time for the routine) the blocks' members,
  +19 bits 2..1, l98 and next114 cleared; the successor lists ordered
  from the first block (the routine's no_return_block set unless the
  first block reaches a return, path_to 3), the start block's
  successors reordered, the final edges added (to the routine's bb80),
  the depth-first search made.

  0x2354E0, 0xA2 bytes: rtn (8) in A2, level (12) in D0 (p3 not read). }

procedure fg_utils_$compute_dfs_lists(
    rtn: rtn_ptr_t;
    level: integer32;
    p3: boolean);
var
  b: bb_ptr_t;
  start: bb_ptr_t;
begin
  if not fg_96 then begin
    b := rtn^.bbs;
    while b <> nil do begin
      b^.members := nil;
      b^.f.b19_2 := false;
      b^.f.b19_1 := false;
      b^.l98 := nil;
      b^.next114 := nil;
      b := b^.next;
    end;
  end;
  fg_96 := false;
  dfs_level := level;
  final_bb := rtn^.bb80;
  final_bb^.order := 65535;
  order_count := 0;
  start := rtn^.bbs;
  if order_successor_lists(start) <> 3 then
    rtn^.f226.no_return_block := true;
  reorder_start_bb_successor_list(start);
  add_final_edges(start);
  final_edge_fixup(rtn);
end;

{ in_interval - whether h is b or one of the interval heads above it
  (l70).

  0x235582, 0x20 bytes, no frame: b (4), h (8). }

function in_interval(
    b: bb_ptr_t;
    h: bb_ptr_t): boolean; options(val_param, internal);
begin
  in_interval := false;
  while b <> nil do begin
    if b = h then begin
      in_interval := true;
      return;
    end;
    b := b^.l70;
  end;
end;

{ loop_entry_is_conditional - whether the interval head h has both an
  edge out to a member of its interval and one leaving it (edges to
  itself not counted).

  0x2355A2, 0x3E bytes, no A5. }

function loop_entry_is_conditional(
    h: bb_ptr_t): boolean; options(val_param, internal);
var
  e: fg_edge_ptr_t;
  outside: boolean;
  inside: boolean;
begin
  outside := false;
  e := h^.succs;
  inside := outside;
  while e <> nil do begin
    if e^.target <> h then
      if e^.target^.l70 = h then
        inside := true
      else
        outside := true;
    e := e^.next_succ;
  end;
  loop_entry_is_conditional := outside and inside;
end;

{ visit_interval_contents - the interval headed by h given loop depth
  depth (inner loops depth + 1); its entry marked conditional when it
  is; each member with an edge leaving the interval marked a loop exit
  (and a conditional entry when it is an additional entry).

  0x2355E0, 0x96 bytes, no A5: h (8) in A2, depth (12) in D2. }

procedure visit_interval_contents(
    h: bb_ptr_t;
    depth: integer32); options(val_param, internal);
var
  m: bb_ptr_t;
  e: fg_edge_ptr_t;
begin
  h^.f.depth := depth & 255;
  if loop_entry_is_conditional(h) then
    h^.f.conditional_entry := true;
  m := h^.l74;
  while m <> nil do begin
    m^.f.depth := depth & 255;
    if m^.f.distinguished_entry then
      visit_interval_contents(m, depth + 1);
    e := m^.succs;
    while e <> nil do
      if not in_interval(e^.target^.l70, h) and (e^.target <> h) then begin
        m^.f.loop_exit := true;
        if m^.f.additional_entry then
          m^.f.conditional_entry := true;
        e := nil;
      end
      else
        e := e^.next_succ;
    m := m^.l78;
  end;
end;

{ fg_utils_$intervals - the routine's intervals (loops) found: for each
  block h in postorder (bbs72, next114), the outermost heads of its
  predecessors (only those not after it for h itself) gathered on a
  work list through l78, each in turn giving its own; a block reached
  from one after h marks h (and the block it was reached from, when
  before h) an additional entry.  When the list closes on h with some
  predecessor and h no additional entry, h heads an interval of the
  blocks gathered (distinguished_entry; their l70 h, its l74 the list;
  an additional entry among them makes h irreducible).  Then each block
  without a head is put on the routine's l84 (an additional entry sets
  rtn +228 bit 2) and its interval visited from depth 1; mark146
  cleared.  The first time for a routine nothing is cleared first.

  0x235676, 0x1AC bytes: rtn (8) in D2; the head D3, the list's tail
  D4, its first unvisited D5, the block whose edges in are walked D6,
  any D0, the first pass D1. }

procedure fg_utils_$intervals(
    rtn: rtn_ptr_t);
label
  1;
var
  b: bb_ptr_t;
  h: bb_ptr_t;
  last: bb_ptr_t;
  next: bb_ptr_t;
  cur: bb_ptr_t;
  p: bb_ptr_t;
  m: bb_ptr_t;
  e: fg_edge_ptr_t;
  any: boolean;
  first: boolean;
begin
  if not fg_94 then begin
    b := rtn^.bbs72;
    while b <> nil do begin
      b^.l70 := nil;
      b^.l74 := nil;
      b^.l78 := nil;
      b^.f.distinguished_entry := false;
      b^.f.irreducible := false;
      b^.f.additional_entry := false;
      b^.f.conditional_entry := false;
      b^.f.depth := 0;
      b := b^.next114;
    end;
  end
  else
    fg_94 := false;
  h := rtn^.bbs72;
  while h <> nil do begin
    last := h;
    next := nil;
    h^.l78 := h;
    any := false;
    cur := h;
    first := true;
  1:
    e := cur^.preds;
    while e <> nil do begin
      p := e^.source;
      while p^.l70 <> nil do
        p := p^.l70;
      if not (first and (p^.order > cur^.order)) then begin
        any := true;
        if p^.l78 = nil then begin
          if next = nil then
            next := p;
          last^.l78 := p;
          last := p;
          p^.l78 := p;
        end;
      end;
      e := e^.next_pred;
    end;
    if next <> nil then begin
      p := next;
      if p = last then
        next := nil
      else
        next := p^.l78;
      if p^.order > h^.order then begin
        h^.f.additional_entry := true;
        if cur^.order < h^.order then
          cur^.f.additional_entry := true;
      end;
      cur := p;
      first := false;
      goto 1;
    end;
    if any and not h^.f.additional_entry then begin
      h^.f.distinguished_entry := true;
      m := h^.l78;
      if m = h then
        m := nil;
      last^.l78 := nil;
      h^.l74 := m;
      h^.l78 := nil;
      while m <> nil do begin
        m^.l70 := h;
        if m^.f.additional_entry then
          h^.f.irreducible := true;
        m := m^.l78;
      end;
    end;
    m := h;
    while m <> nil do begin
      p := m;
      m := m^.l78;
      p^.l78 := nil;
    end;
    h := h^.next114;
  end;
  b := rtn^.bbs;
  while b <> nil do begin
    if b^.l70 = nil then begin
      b^.l78 := rtn^.l84;
      rtn^.l84 := b;
      if b^.f.additional_entry then
        rtn^.f228.b228_2 := true;
      if b^.f.distinguished_entry then
        visit_interval_contents(b, 1);
    end;
    b^.mark146 := 0;
    b := b^.next;
  end;
end;

{ fg_utils_$separate_loop_header_edges - bb's edges in from blocks
  outside the loop headed by head (inside when p3 is false: a source
  is outside when its depth is less than head's or head is not among
  its interval heads) taken off bb's list (when outside <> p3) and
  chained, newest first, at next_pred; the chain.

  0x235822, 0x8E bytes: bb (8) in D3, head (12) in D2, p3 (16) in D1;
  the chain in D4 (returned in A0), the previous edge D5. }

function fg_utils_$separate_loop_header_edges(
    bb: bb_ptr_t;
    head: bb_ptr_t;
    p3: boolean): fg_edge_ptr_t;
var
  moved: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  n: fg_edge_ptr_t;
  a: bb_ptr_t;
  outside: boolean;
begin
  moved := nil;
  prev := moved;
  e := bb^.preds;
  while e <> nil do begin
    a := e^.source;
    if a^.f.depth < head^.f.depth then
      outside := true
    else begin
      outside := true;
      while a <> nil do
        if a = head then begin
          outside := false;
          a := nil;
        end
        else
          a := a^.l70;
    end;
    if outside = p3 then begin
      prev := e;
      e := e^.next_pred;
    end
    else begin
      n := e^.next_pred;
      if prev = nil then
        bb^.preds := n
      else
        prev^.next_pred := n;
      e^.next_pred := moved;
      moved := e;
      e := n;
    end;
  end;
  fg_utils_$separate_loop_header_edges := moved;
end;

{ an_exit_has_multiple_successors - whether a source of the edges on
  the chain list (at next_pred) does not end in a jump with one
  visible successor, or has a branch or jump before that jump.

  0x2358B0, 0x7E bytes, no A5: list (8) in A0. }

function an_exit_has_multiple_successors(
    list: fg_edge_ptr_t): boolean; options(val_param, internal);
var
  src: bb_ptr_t;
  last: instr_ptr_t;
  p: instr_ptr_t;
begin
  an_exit_has_multiple_successors := true;
  while list <> nil do begin
    src := list^.source;
    last := src^.last;
    if (last^.opc <> ord(opc$jump)) or (src^.succs^.next_succ <> nil)
       or src^.f.hidden_successor_edges then
      return;
    p := last^.prev;
    if p <> nil then
      if instruction_attributes[p^.opc].class in [class$branch, class$fp_branch, class$jump] then
        return;
    list := list^.next_pred;
  end;
  an_exit_has_multiple_successors := false;
end;

{ build_exit - a new block for the loop exits on list (edges into the
  loop's header, chained at next_pred): put after the header in code
  order (the postorder numbers made again), a member of the header's
  interval at its depth, the list's edges retargeted to it, ending in a
  jump (kept, +2 bit 6) to the header; list becomes the new edge alone
  (taken off the header's edges in); the block.

  0x23592E, 0xFA bytes, no A5: rtn (8) in D2, list (12) by address in
  D3; the block A2, the header A3, the jump D2. }

function build_exit(
    rtn: rtn_ptr_t;
    var list: fg_edge_ptr_t): bb_ptr_t; options(val_param, internal);
var
  nb: bb_ptr_t;
  t: bb_ptr_t;
  e: fg_edge_ptr_t;
  j: instr_ptr_t;
  ne: fg_edge_ptr_t;
begin
  nb := lir_$new_basic_block;
  t := list^.target;
  nb^.next114 := t;
  t^.next^.next114 := nb;
  nb^.next := t^.next;
  t^.next := nb;
  fg_utils_$recompute_postnum(rtn);
  nb^.l70 := t;
  nb^.l78 := t^.l74;
  t^.l74 := nb;
  nb^.f.depth := t^.f.depth;
  nb^.preds := list;
  e := list;
  while e <> nil do begin
    e^.target := nb;
    e := e^.next_pred;
  end;
  j := lir_$new_instruction(ord(opc$jump));
  j^.bb := nb;
  j^.h.b2_6 := true;
  j^.opnds[1].h.kind := operand$flow_graph_edge;
  j^.opnds[1].h.num := 1;
  ne := lir_$add_flow_graph_edge(nb, t);
  j^.opnds[1].ptr := ne;
  list := ne;
  if ne = t^.preds then
    t^.preds := ne^.next_pred
  else begin
    e := t^.preds;
    while e^.next_pred <> list do
      e := e^.next_pred;
    e^.next_pred := list^.next_pred;
  end;
  list^.next_pred := nil;
  nb^.first := j;
  nb^.last := j;
  build_exit := nb;
end;

{ copy_bb_contents - the header hdr's instructions after its labels and
  join birthpoints, up to its jump, copied to the end of e's source
  (those kept, +2 bit 6: completed, +0 bit 1 and the source position
  copied); the source's jump (bug_check unless a jump to an edge) made
  to jump where the header's jump goes, the source a loop exit
  (bug_check unless it has two edges out).

  0x235A28, 0xF2 bytes: hdr (8) by address, e (12) in D2; the header's
  instruction A3. }

procedure copy_bb_contents(
    var hdr: bb_ptr_t;
    e: fg_edge_ptr_t); options(val_param, internal);
var
  i: instr_ptr_t;
  c: instr_ptr_t;
  j: instr_ptr_t;
begin
  i := hdr^.first;
  while (i^.opc = ord(opc$join_bp)) or (i^.opc = ord(opc$label)) do
    i := i^.next;
  while i^.opc <> ord(opc$jump) do begin
    if i^.h.b2_6 then begin
      c := utils_$copy_instr_template_to_bb_end(i, e^.source);
      utils_$complete_copied_instr(c);
      c^.h.b0_1 := i^.h.b0_1;
      c^.l32 := i^.l32;
    end;
    i := i^.next;
  end;
  j := e^.source^.last;
  if (j^.opc <> ord(opc$jump)) or (j^.opnds[1].h.kind <> operand$flow_graph_edge) then
    bug_check('FG_UTILS_$copy_bb_contents:  exposed JUMP%$');
  j^.opnds[1].ptr := lir_$add_flow_graph_edge(e^.source,
                                              fg_edge_ptr_t(i^.opnds[1].ptr)^.target);
  e^.source^.f.loop_exit := true;
  if n_edges(e^.source^.succs, true) <> 2 then
    bug_check('FG_UTILS_$copy_bb_contents:  wrong number of outgoing edges%$');
end;

{ build_loop_header - the conditional loop headed by hdr made to enter
  unconditionally: its edges in from inside the loop taken off
  (bug_check when there are none) and, when there are more than three
  or an exit has more than one successor, sent through a new exit block
  (build_exit; its mark146 mark); the header's successor inside the
  loop becomes the loop's header (bug_check unless it is in hdr's
  interval): those edges moved to it, the header's code copied to their
  sources (copy_bb_contents), the interval's members moved to it (it
  heads them, hdr leaves the interval: its depth its own head's);
  conditional_entry computed again.

  0x235B84, 0x174 bytes, no A5: rtn (8) in A4, hdr (12) in D3, mark
  (16) in D2; the edges A3, the new header A2. }

procedure build_loop_header(
    rtn: rtn_ptr_t;
    hdr: bb_ptr_t;
    mark: integer32); options(val_param, internal);
var
  list: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  b: bb_ptr_t;
  nb: bb_ptr_t;
  m: bb_ptr_t;
  prev: bb_ptr_t;
begin
  list := fg_utils_$separate_loop_header_edges(hdr, hdr, true);
  if list = nil then
    bug_check('FG_UTILS_$build_loop_header: loop entry with no incoming loop edges%$');
  e := hdr^.succs;
  if hdr <> e^.target^.l70 then
    e := e^.next_succ;
  if (n_edges(list, false) > 3) or an_exit_has_multiple_successors(list) then begin
    nb := build_exit(rtn, list);
    nb^.mark146 := mark;
  end;
  b := e^.target;
  if hdr <> b^.l70 then
    bug_check('FG_UTILS_$build_loop_header: can''t locate new header%$');
  if b^.preds = nil then
    b^.preds := list
  else begin
    e := b^.preds;
    while e^.next_pred <> nil do
      e := e^.next_pred;
    e^.next_pred := list;
  end;
  e := list;
  repeat
    e^.target := b;
    copy_bb_contents(hdr, e);
    e := e^.next_pred;
  until e = nil;
  prev := nil;
  m := hdr^.l74;
  while m <> nil do begin
    if m = b then begin
      if prev = nil then
        hdr^.l74 := m^.l78
      else
        prev^.l78 := m^.l78;
    end
    else begin
      m^.l70 := b;
      prev := m;
    end;
    m := m^.l78;
  end;
  b^.l74 := hdr^.l74;
  hdr^.l74 := nil;
  b^.l78 := hdr^.l78;
  hdr^.l78 := b;
  b^.l70 := hdr^.l70;
  hdr^.f.distinguished_entry := false;
  hdr^.f.conditional_entry := false;
  hdr^.f.loop_exit := false;
  if hdr^.l70 = nil then
    hdr^.f.depth := 0
  else
    hdr^.f.depth := hdr^.l70^.f.depth;
  b^.f.distinguished_entry := true;
  b^.f.irreducible := false;
  b^.f.additional_entry := false;
  b^.f.conditional_entry := loop_entry_is_conditional(b);
end;

{ n_instrs - bb's instructions other than join birthpoints, MMT_SEQs,
  labels and jumps.

  0x235D74, 0x4E bytes, no A5. }

function n_instrs(
    bb: bb_ptr_t): integer32; options(val_param, internal);
var
  n: integer32;
  i: instr_ptr_t;
begin
  n := 0;
  i := bb^.first;
  while i <> nil do begin
    if not ((i^.opc = ord(opc$join_bp)) or (i^.opc = ord(opc$mmt_seq))
            or (i^.opc = ord(opc$label)) or (i^.opc = ord(opc$jump))) then
      n := n + 1;
    i := i^.next;
  end;
  n_instrs := n;
end;

{ every_interval_block_exits - whether every member of h's interval is
  a loop exit and either there are more than two blocks (h and its
  members), h was made for this mark (mark146), or no instruction of h
  and its members may raise an exception without being volatile.

  0x235DC2, 0x9A bytes, no frame: h (4) in A0, mark (8) in D1. }

function every_interval_block_exits(
    h: bb_ptr_t;
    mark: integer32): boolean; options(val_param, internal);
var
  n: integer32;
  m: bb_ptr_t;
  i: instr_ptr_t;
begin
  every_interval_block_exits := false;
  n := 1;
  m := h^.l74;
  while m <> nil do begin
    if not m^.f.loop_exit then
      return;
    n := n + 1;
    m := m^.l78;
  end;
  every_interval_block_exits := true;
  if n > 2 then
    return;
  if mark = h^.mark146 then
    return;
  i := h^.first;
  while i <> nil do begin
    if i^.h.may_generate_an_exception and not i^.h.volatile_location then begin
      every_interval_block_exits := false;
      return;
    end;
    i := i^.next;
  end;
  m := h^.l74;
  while m <> nil do begin
    i := m^.first;
    while i <> nil do begin
      if i^.h.may_generate_an_exception and not i^.h.volatile_location then begin
        every_interval_block_exits := false;
        return;
      end;
      i := i^.next;
    end;
    m := m^.l78;
  end;
end;

{ make_loops_unconditional - each block on list (chained at l78), its
  inner intervals first: a reducible loop head with a conditional
  entry, two edges out, not all of whose blocks exit (or whose code may
  raise exceptions), of at most 10 instructions and no hidden edges,
  given an unconditional entry (build_loop_header).

  0x235E5C, 0xA8 bytes, no A5: rtn (8) in A2, list (12) in A3, mark
  (16). }

procedure make_loops_unconditional(
    rtn: rtn_ptr_t;
    list: bb_ptr_t;
    mark: integer32); options(val_param, internal);
begin
  while list <> nil do begin
    if list^.f.distinguished_entry then
      make_loops_unconditional(rtn, list^.l74, mark);
    if list^.f.distinguished_entry then
      if not list^.f.irreducible then
        if list^.f.conditional_entry then
          if n_edges(list^.succs, true) = 2 then
            if not every_interval_block_exits(list, mark) then
              if n_instrs(list) <= 10 then
                if not list^.f.hidden_successor_edges then
                  build_loop_header(rtn, list, mark);
    list := list^.l78;
  end;
end;

{ fg_utils_$make_loops_unconditional - make_loops_unconditional over
  the routine's outermost blocks (l84) with a new mark.

  0x235F04, 0x30 bytes. }

procedure fg_utils_$make_loops_unconditional(
    rtn: rtn_ptr_t);
begin
  rtn^.marks := rtn^.marks + 1;
  make_loops_unconditional(rtn, rtn^.l84, rtn^.marks);
end;

{ fg_utils_$forward_empty_blocks - each block (bbs72, next114) whose
  first instruction after its labels is a jump forwarded; then each
  conditional branch (class branch or fp_branch) just before a block's
  closing jump that goes where the jump goes excised, and the
  condition codes it read (a definition whose segment is written) taken
  off their definer when nothing else reads them, the definer kept
  (+2 bit 6), not a branch, call, jump, SEQ, trap or SVC and not of
  the attribute's +18 bits 1..0 (its sets_cc or fp_ccs cleared, its
  preference bit the opcode's b6_0); repeated while a branch went.
  The intervals found again when anything changed; whether anything
  did.

  0x235F34, 0x238 bytes: rtn (8); changed D2, again D3; the definer
  (-20) (utils_ins_$operands_instruction of the segment's first
  reference); the set 16#1104266 of classes. }

function fg_utils_$forward_empty_blocks(
    rtn: rtn_ptr_t): boolean;
label
  1;
var
  changed: boolean;
  again: boolean;
  b: bb_ptr_t;
  nxt: bb_ptr_t;
  i: instr_ptr_t;
  j: instr_ptr_t;
  c: instr_ptr_t;
  d: instr_ptr_t;
  k: integer;
  op: opnd_ptr_t;
begin
  changed := false;
1:
  b := rtn^.bbs72;
  while b <> nil do begin
    nxt := b^.next114;
    i := b^.first;
    if i <> nil then begin
      while i^.opc = ord(opc$label) do
        i := i^.next;
      if i^.opc = ord(opc$jump) then begin
        fg_utils_$forward_this_block(rtn, b, i);
        changed := true;
      end;
    end;
    b := nxt;
  end;
  again := false;
  b := rtn^.bbs72;
  while b <> nil do begin
    j := b^.last;
    if j <> nil then
      if j^.opc = ord(opc$jump) then
        if j^.opnds[1].h.kind = operand$flow_graph_edge then begin
          c := j^.prev;
          if c <> nil then
            if instruction_attributes[c^.opc].class in [class$branch, class$fp_branch] then
              if c^.opnds[1].h.kind = operand$flow_graph_edge then
                if fg_edge_ptr_t(j^.opnds[1].ptr)^.target
                   = fg_edge_ptr_t(c^.opnds[1].ptr)^.target then begin
                  d := nil;
                  if c^.opnds[2].h.kind in [operand$ip_condition_codes,
                                            operand$fp_condition_codes] then
                    if (integer(c^.opnds[2].lts^.rrp) & 12) <> 0 then
                      d := utils_ins_$operands_instruction(c^.opnds[2].lts^.refs);
                  utils_$excise_instruction_cleanly(c, true);
                  again := true;
                  changed := again;
                  if d <> nil then
                    if d^.h.b2_6 then
                      if not (instruction_attributes[d^.opc].class
                              in [class$branch, class$call, class$fp_branch,
                                  class$jump, class$seq, class$trap, class$svc,
                                  class$trap_cond]) then
                        if (instruction_attributes[d^.opc].w18 & 16#300) = 0 then begin
                          op := addr(d^.opnds[d^.h.nopnds]);
                          if not op^.lts^.f2.final then
                            if op^.h.kind in [operand$ip_condition_codes,
                                              operand$fp_condition_codes] then
                              if op^.link = nil then begin
                                k := ord(op^.h.kind);
                                if k = ord(operand$ip_condition_codes) then
                                  d^.h.sets_cc := false
                                else if k = ord(operand$fp_condition_codes) then
                                  d^.h.fp_ccs := false
                                else
                                  bug_check('FG_UTILS_$forward_empty_blocks:  unknown CC type%$');
                                utils_$excise_lts_cleanly(op^.lts, changed);
                                op^.h.kind := operand$none;
                                op^.h.num := 0;
                                op^.lts := nil;
                                opnd_bytes_ptr_t(op)^.rrp := 0;
                                d^.h.preference := instruction_attributes[d^.opc].b6_0;
                              end;
                        end;
                end;
        end;
    b := b^.next114;
  end;
  if again then
    goto 1;
  if changed then
    fg_utils_$intervals(rtn);
  fg_utils_$forward_empty_blocks := changed;
end;

{ fg_utils_$end_senseless_loops - each one-block loop (a reducible loop
  head without members, two edges out, no hidden edges, ending in a
  jump to an edge) that writes nothing live into its exit (the block's
  transparent vector and the exit's live_in have no live range in
  common) is ended: a warning (53) for its source line, the
  conditional branch (bug_check unless one) excised, the jump made to
  the exit edge alone, the loop's edge back to itself dropped, and the
  block forwarded when its first instruction after its labels is a
  jump.  Whether any was.

  0x23619E, 0x1BC bytes: rtn (8) in D4; the vector in the frame (-4096,
  4096 bytes); the loop's own edge D6, the exit edge (-4124). }

function fg_utils_$end_senseless_loops(
    rtn: rtn_ptr_t): boolean;
type
  vec_t = array [0..1023] of bv_word_t;
var
  changed: boolean;
  b: bb_ptr_t;
  nxt: bb_ptr_t;
  e: fg_edge_ptr_t;
  self_e: fg_edge_ptr_t;
  out_e: fg_edge_ptr_t;
  v: vec_t;
  br: instr_ptr_t;
  line: integer32;
  i: instr_ptr_t;
begin
  changed := false;
  b := rtn^.bbs72;
  while b <> nil do begin
    nxt := b^.next114;
    if b^.f.distinguished_entry then
      if not b^.f.irreducible then
        if b^.l74 = nil then
          if n_edges(b^.succs, true) = 2 then
            if not b^.f.hidden_successor_edges then
              if b^.last^.opc = ord(opc$jump) then
                if b^.last^.opnds[1].h.kind = operand$flow_graph_edge then begin
                  e := b^.succs;
                  if b = e^.target then begin
                    self_e := e;
                    out_e := e^.next_succ;
                  end
                  else begin
                    out_e := e;
                    self_e := e^.next_succ;
                  end;
                  bv_$and_to(rtn^.l192 + 1, b^.transparent, out_e^.target^.live_in,
                             univ_ptr(addr(v)));
                  if bv_$find_next(rtn, univ_ptr(addr(v)), nil) = nil then begin
                    br := b^.last^.prev;
                    if not (instruction_attributes[br^.opc].class
                            in [class$branch, class$fp_branch]) then
                      bug_check('FG_UTILS_$end_senseless_loops:  expected cond branch%$');
                    line := dmp_$get_line_number(br);
                    if line <> 0 then
                      cgerr(53, line, nil);
                    utils_$excise_instruction_cleanly(br, true);
                    b^.last^.opnds[1].ptr := out_e;
                    b^.succs := out_e;
                    out_e^.next_succ := nil;
                    if self_e = b^.preds then
                      b^.preds := self_e^.next_pred
                    else begin
                      e := b^.preds;
                      while e^.next_pred <> self_e do
                        e := e^.next_pred;
                      e^.next_pred := self_e^.next_pred;
                    end;
                    i := b^.first;
                    while i^.opc = ord(opc$label) do
                      i := i^.next;
                    if i^.opc = ord(opc$jump) then
                      fg_utils_$forward_this_block(rtn, b, i);
                    changed := true;
                  end;
                end;
    b := nxt;
  end;
  fg_utils_$end_senseless_loops := changed;
end;

{ reverse_depth_first_search - bb visited in the reverse flow graph
  (through its edges in): its members and l150 itself, numbered in
  preorder (w8, rdfs_first .. rdfs_last chained at l98 and back at
  l102); each predecessor not visited with a nonzero l150 visited with
  bb its parent (l106); an edge from a predecessor with l150 nil
  dropped (the previous edge is the last one recursed through: an
  edge from a visited block does not move it, as the image has it).

  0x236390, 0x94 bytes, no A5 load (its caller's): bb (8) in A3. }

procedure reverse_depth_first_search(
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  s: bb_ptr_t;
begin
  bb^.members := bb;
  bb^.l150 := bb;
  if rdfs_first = nil then begin
    rdfs_first := bb;
    bb^.w8 := 1;
  end
  else begin
    rdfs_last^.l98 := fg_edge_ptr_t(bb);
    bb^.w8 := rdfs_last^.w8 + 1;
  end;
  bb^.l102 := rdfs_last;
  rdfs_last := bb;
  prev := nil;
  e := bb^.preds;
  while e <> nil do begin
    s := e^.source;
    if s^.members = nil then
      if s^.l150 <> nil then begin
        s^.l106 := bb;
        reverse_depth_first_search(e^.source);
        prev := e;
      end
      else if prev = nil then
        bb^.preds := e^.next_pred
      else
        prev^.next_pred := e^.next_pred;
    e := e^.next_pred;
  end;
end;

{ compress - the path compression of the dominator computation
  (Lengauer and Tarjan): v's ancestor (mark146, a block) compressed
  first, its vector (avail_gen) ored into v's, v's label (l150) the
  ancestor's when the ancestor's label's semidominator (members) comes
  first, v's ancestor the ancestor's.

  0x236424, 0x7C bytes, no A5 load: v (8) in A2. }

procedure compress(
    v: bb_ptr_t); options(val_param, internal);
var
  a: bb_ptr_t;
begin
  a := bb_ptr_t(v^.mark146);
  if a^.mark146 <> 0 then begin
    compress(a);
    bv_$or(dom_rtn^.l192 + 1, a^.avail_gen, v^.avail_gen);
    if a^.l150^.members^.w8 < v^.l150^.members^.w8 then
      v^.l150 := a^.l150;
    v^.mark146 := a^.mark146;
  end;
end;

{ eval - v when it has no ancestor, else its label after compression.

  0x2364A0, 0x26 bytes, no A5 load. }

function eval(
    v: bb_ptr_t): bb_ptr_t; options(val_param, internal);
begin
  if v^.mark146 = 0 then
    eval := v
  else begin
    compress(v);
    eval := v^.l150;
  end;
end;

{ evaldef - nil when v has no ancestor, else its vector after
  compression.

  0x2364C6, 0x26 bytes, no A5 load. }

function evaldef(
    v: bb_ptr_t): bv_ptr_t; options(val_param, internal);
begin
  if v^.mark146 = 0 then
    evaldef := nil
  else begin
    compress(v);
    evaldef := v^.avail_gen;
  end;
end;

{ compute_rel - for each child c of b in the dominator tree (l46,
  siblings at l50), its subtree first: c's avail_gen its live_in, or
  its avail_in unless marked (+19 bit 2), less its avail_out; copied
  into b's avail_in (when b is marked) or ored into it; b unmarked.

  0x2364EC, 0xE0 bytes, no A5 load: b (8) in A2. }

procedure compute_rel(
    b: bb_ptr_t); options(val_param, internal);
var
  c: bb_ptr_t;
begin
  c := b^.l46;
  while c <> nil do begin
    compute_rel(c);
    bv_$copy(dom_rtn^.l192 + 1, c^.live_in, c^.avail_gen);
    if not c^.f.b19_2 then
      bv_$or(dom_rtn^.l192 + 1, c^.avail_in, c^.avail_gen);
    bv_$subtract(dom_rtn^.l192 + 1, c^.avail_out, c^.avail_gen);
    if b^.f.b19_2 then
      bv_$copy(dom_rtn^.l192 + 1, c^.avail_gen, b^.avail_in)
    else
      bv_$or(dom_rtn^.l192 + 1, c^.avail_gen, b^.avail_in);
    b^.f.b19_2 := false;
    c := c^.l50;
  end;
end;

{ replace_exposed_lts - lr's exposed segment in bb replaced by a new
  segment after it on lr's list: with the lists by live range
  (lir_main_c86 1) the new one takes the old one's place on lr's
  exposed list (bug_check when the hint is wrong) and becomes the hint;
  otherwise the old one taken off the block's exposed list and the new
  one put on.  The new segment.

  0x2365CC, 0xB8 bytes, no A5: lr (8) in D2, bb (12) in A3. }

function replace_exposed_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param, internal);
var
  old: lts_ptr_t;
  nw: lts_ptr_t;
  p: lts_ptr_t;
begin
  old := utils_$find_exposed_lts(lr, bb);
  nw := lir_$new_lifetime_segment(lr);
  nw^.bb := bb;
  nw^.next := old^.next;
  old^.next := nw;
  if lir_main_c86 = 1 then begin
    old^.f2.exposed := false;
    nw^.f2.exposed := true;
    nw^.next_exposed := old^.next_exposed;
    old^.next_exposed := nil;
    p := lr^.exposed_prev;
    if p = nil then begin
      if lr^.exposed <> old then
        bug_check('FG_UTILS: replace_exposed -- bad exposed list (case #1)%$');
      lr^.exposed := nw;
    end
    else begin
      if p^.next_exposed <> old then
        bug_check('FG_UTILS: replace_exposed -- bad exposed list (case #2)%$');
      p^.next_exposed := nw;
    end;
    lr^.exposed_hint := nw;
  end
  else begin
    utils_$remove_lts_from_exposed_list(old);
    utils_$put_lts_on_exposed_list(nw);
  end;
  replace_exposed_lts := nw;
end;

{ fg_utils_$generate_join_birthpoint - a join birthpoint for the
  exposed segment lts and the final segment fin of one live range in
  lts's block: a JOIN_BP made first in the block after its labels (from
  the join birthpoint instructions' heap, lir_main_heap switched for
  the call), its operand 1 a reader of lts (read and intend_to_modify,
  lts's parity), operand 2 the definition of fin (modify), operand 3
  the inputs (join_birthpoint_inputs, none yet); the operands' kind
  that of the live range's first referenced segment (a pair's halves
  fp_reg; bug_check without one).  The live range read, intend_to_
  modify and modify; lts read and intend_to_modify; fin modify.  The
  JOIN_BP.

  0x2366F8, 0x138 bytes: lts (8) in D3, fin (12) in D5; the live range
  A2, the block D4, the kind D2; opcode and `after' pushed as one
  longword (16#CB0000, pattern 105). }

function fg_utils_$generate_join_birthpoint(
    lts: lts_ptr_t;
    fin: lts_ptr_t): instr_ptr_t;
var
  lr: lr_ptr_t;
  bb: bb_ptr_t;
  kind: integer;
  s: lts_ptr_t;
  i: instr_ptr_t;
  save: univ_ptr;
  ni: instr_ptr_t;
begin
  lr := lts^.lr;
  kind := 0;
  bb := lts^.bb;
  s := lr^.ltss;
  while s <> nil do
    if s^.refs <> nil then begin
      kind := ord(s^.refs^.h.kind);
      s := nil;
    end
    else
      s := s^.next;
  if kind = 0 then
    bug_check('FG_UTILS_$INSERT_JOIN_BIRTHPOINT: Live Range has no Kind, LR %3WZD%$',
              lr^.num);
  if kind = ord(operand$fp_reg_pair) then
    kind := ord(operand$fp_reg);
  lr^.rrp := lr^.rrp + [rrp$modify, rrp$read, rrp$intend_to_modify];
  lts^.rrp := lts^.rrp + [rrp$read, rrp$intend_to_modify];
  fin^.rrp := fin^.rrp + [rrp$modify];
  i := bb^.first;
  while i^.opc = ord(opc$label) do
    i := i^.next;
  save := lir_main_heap;
  lir_main_heap := addr(jbi_heap);
  ni := lir_$optimizer_new_instruction(i, ord(opc$join_bp), false);
  lir_main_heap := save;
  ni^.bb := bb;
  ni^.opnds[1].h.kind := operand$t(kind);
  ni^.opnds[1].h.num := 1;
  opnd_bytes_ptr_t(addr(ni^.opnds[1]))^.rrp := (opnd_bytes_ptr_t(lts)^.rrp & 3) ! 16#30;
  ni^.opnds[1].lts := lts;
  lts^.refs := addr(ni^.opnds[1]);
  ni^.opnds[2].h.kind := operand$t(kind);
  ni^.opnds[2].h.num := 2;
  opnd_bytes_ptr_t(addr(ni^.opnds[2]))^.rrp := (opnd_bytes_ptr_t(fin)^.rrp & 3) ! 4;
  ni^.opnds[2].lts := fin;
  ni^.opnds[2].link := fin^.refs;
  fin^.refs := addr(ni^.opnds[2]);
  ni^.opnds[3].h.kind := operand$join_birthpoint_inputs;
  ni^.opnds[3].h.num := 3;
  fg_utils_$generate_join_birthpoint := ni;
end;

{ fg_utils_$insert_join_birthpoint - lr's join birthpoint in bb: the
  JOIN_BP already reading its exposed segment there, or one made for
  a new exposed segment (replace_exposed_lts; the old one the join's
  definition) or, when the exposed segment is new, for it and a final
  segment (made final); the two segments' l44 and l28 cleared.

  0x236874, 0xA0 bytes: lr (8), bb (12); created (-32). }

function fg_utils_$insert_join_birthpoint(
    lr: lr_ptr_t;
    bb: bb_ptr_t): instr_ptr_t;
var
  created: boolean;
  x: lts_ptr_t;
  e: lts_ptr_t;
  i: instr_ptr_t;
begin
  x := utils_$get_exposed_lts(lr, bb, created);
  if not created then begin
    if x^.refs <> nil then begin
      i := utils_ins_$operands_instruction(x^.refs);
      if i^.opc = ord(opc$join_bp) then begin
        fg_utils_$insert_join_birthpoint := i;
        return;
      end;
    end;
    e := replace_exposed_lts(lr, bb);
  end
  else begin
    e := x;
    x := utils_$get_final_lts(lr, bb, created);
    x^.f2.final := true;
  end;
  e^.l44 := nil;
  e^.l28 := nil;
  x^.l44 := nil;
  x^.l28 := nil;
  fg_utils_$insert_join_birthpoint := fg_utils_$generate_join_birthpoint(e, x);
end;

{ traverse - the SSA form walk over the dominator tree from bb: unless
  bb is the start block or an entry, each live range live into bb
  (live_in) is given a join birthpoint in bb (and its bit in bb's
  transparent set) when its reaching definition (bb itself when the
  live range is defined there, avail_out, else the block on top of the
  live range's stack, lr +60; bug_check, after a dump at debug level 3,
  when the stack is empty) is bb, or does not pass it through
  (transparent) and is not the first block; never in a final block.
  Then each live range available into bb (avail_in) that bb defines or
  passes through, or every one when bb is the first block, has bb
  pushed on its stack (a 16-byte entry from the dominator buckets'
  heap: the block +0, the next +12); bb's children traversed; and the
  same live ranges' stacks popped (bug_check when empty).

  0x236914, 0x200 bytes: bb (8) in D2; the live range A3, the
  definition A2. }

procedure traverse(
    bb: bb_ptr_t); options(val_param, internal);
type
  stk_ptr_t = ^stk_t;
  stk_t = record
    bb: bb_ptr_t;                       { +0 }
    space4: array [4..11] of char;      { +4 }
    next: stk_ptr_t;                    { +12 }
  end;
var
  lr: lr_ptr_t;
  d: bb_ptr_t;
  s: stk_ptr_t;
  c: bb_ptr_t;
begin
  lr := nil;
  if bb^.f14.kind <> 1 then
    if not bb^.f.entry then
      repeat
        lr := bv_$find_next(dom_rtn, bb^.live_in, lr);
        if lr <> nil then begin
          if bv_$test(bb^.avail_out, lr) then
            d := bb
          else begin
            s := stk_ptr_t(lr^.l60);
            if s = nil then begin
              if dfs_level >= 3 then
                dmp_$whole_routine(dom_rtn, at_backend_switches.sw5, true);
              bug_check('FG_UTILS_$TRAVERSE: birthpoint stack is NIL, 1, BB %3WZD, LR %3WZD%$',
                        bb^.num, lr^.num);
            end;
            d := s^.bb;
          end;
          if bb^.f14.kind <> 2 then
            if (bb = d)
               or (not bv_$test(d^.transparent, lr) and (d <> dom_rtn^.dfs_first)) then begin
              discard(fg_utils_$insert_join_birthpoint(lr, bb));
              bv_$set(bb^.transparent, lr);
            end;
        end;
      until lr = nil;
  lr := nil;
  repeat
    lr := bv_$find_next(dom_rtn, bb^.avail_in, lr);
    if lr <> nil then
      if bv_$test(bb^.avail_out, lr) or bv_$test(bb^.transparent, lr)
         or (bb = dom_rtn^.dfs_first) then begin
        s := mrh_$alloc_fixed(bucket_heap);
        s^.bb := bb;
        s^.next := stk_ptr_t(lr^.l60);
        lr^.l60 := integer32(s);
      end;
  until lr = nil;
  c := bb^.l46;
  while c <> nil do begin
    traverse(c);
    c := c^.l50;
  end;
  lr := nil;
  repeat
    lr := bv_$find_next(dom_rtn, bb^.avail_in, lr);
    if lr <> nil then
      if bv_$test(bb^.avail_out, lr) or bv_$test(bb^.transparent, lr)
         or (bb = dom_rtn^.dfs_first) then begin
        s := stk_ptr_t(lr^.l60);
        if s = nil then
          bug_check('FG_UTILS_$TRAVERSE: birthpoint stack is NIL, 2, BB %3WZD, LR %3WZD%$',
                    bb^.num, lr^.num);
        lr^.l60 := integer32(s^.next);
      end;
  until lr = nil;
end;

{ fg_utils_$add_jbi - lts made an input of the JOIN_BP join: a record
  from the inputs' heap (utils' ut_jbi_t: next +0 on lts's l44 list,
  next_op +4 on join's operand 3 link (+72), lts +8, join +12).

  0x236B9C, 0x4E bytes: join (8) in D2, lts (12) in A2. }

procedure fg_utils_$add_jbi(
    join: instr_ptr_t;
    lts: lts_ptr_t);
type
  jbi_ptr_t = ^jbi_t;
  jbi_t = record
    next: jbi_ptr_t;                    { +0 }
    next_op: jbi_ptr_t;                 { +4 }
    lts: lts_ptr_t;                     { +8 }
    join: instr_ptr_t;                  { +12 }
  end;
var
  r: jbi_ptr_t;
begin
  r := mrh_$alloc_fixed(jbi_input_heap);
  r^.lts := lts;
  r^.join := join;
  r^.next := lts^.l44;
  lts^.l44 := r;
  r^.next_op := jbi_ptr_t(join^.opnds[3].link);
  join^.opnds[3].link := opnd_ptr_t(r);
end;

{ add_join_birthpoint_inputs - from bb back through its predecessors
  not yet marked mark (mark146 set), each block where lr has no
  written final segment (next142, the live range during
  fg_utils_$dominators) searched further, and one where it has gives
  that segment (l134) as an input of join.

  0x236BEA, 0x60 bytes, no A5: join (8), mark (12) in D2, lr (16) in
  A2, bb (20). }

procedure add_join_birthpoint_inputs(
    join: instr_ptr_t;
    mark: integer32;
    lr: lr_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
  s: bb_ptr_t;
begin
  e := bb^.preds;
  while e <> nil do begin
    s := e^.source;
    if mark <> s^.mark146 then begin
      s^.mark146 := mark;
      if lr <> lr_ptr_t(s^.next142) then
        add_join_birthpoint_inputs(join, mark, lr, s)
      else
        fg_utils_$add_jbi(join, s^.l134);
    end;
    e := e^.next_pred;
  end;
end;

{ fg_utils_$dominators - the dominator tree (Lengauer and Tarjan, over
  the depth-first preorder from dfs_last back to dfs_first: the
  semidominator in members, the buckets 16-byte entries chained from
  the semidominator's next142, the ancestor in mark146, the label in
  l150, the immediate dominator in l54), with the availability
  vectors carried along (avail_in from transparent for marked blocks,
  avail_gen and avail_out by the evaluation); the tree's children (l46,
  siblings l50), compute_rel, and, when ssa, the SSA form (traverse);
  then the postdominators the same way over the reverse graph from
  bb80 (l58); the blocks numbered in code order (w8).  When ssa: the
  definitions may be located (lir_main_c8e; bug_check unless the lists
  are by live range), each live range's final written segments noted
  in their blocks (l134 the segment, next142 the live range), and each
  exposed segment given its reaching final segment (the nearest
  dominator's: l44, chained on its l28, its l40 when clear) or, for a
  JOIN_BP's, its inputs (add_join_birthpoint_inputs with a new mark).

  0x236C4A, 0x4D6 bytes: rtn (8), ssa (12) in D2, level (14); the first
  block D3, the block walked D4. }

procedure fg_utils_$dominators(
    rtn: rtn_ptr_t;
    ssa: boolean;
    level: integer32);
type
  ent_ptr_t = ^ent_t;
  ent_t = record
    b0: bb_ptr_t;                       { +0 }
    b4: bb_ptr_t;                       { +4 }
    n8: ent_ptr_t;                      { +8 }
    n12: ent_ptr_t;                     { +12 }
  end;
var
  first: bb_ptr_t;
  b: bb_ptr_t;
  w: bb_ptr_t;
  u: bb_ptr_t;
  v: bb_ptr_t;
  p: bb_ptr_t;
  d: bb_ptr_t;
  e: fg_edge_ptr_t;
  dv: bv_ptr_t;
  ent: ent_ptr_t;
  n: integer32;
  lr: lr_ptr_t;
  s: lts_ptr_t;
  x: lts_ptr_t;
  nx: lts_ptr_t;
  f: lts_ptr_t;
  i: instr_ptr_t;
begin
  dom_rtn := rtn;
  dfs_level := level;
  first := rtn^.dfs_first;
  mrh_$initialize(bucket_heap, 0, 16, 'dominator bucket heap%');
  b := rtn^.dfs_last;
  while b <> first do begin
    if b^.f.b19_2 then
      bv_$copy(rtn^.l192 + 1, b^.transparent, b^.avail_in);
    b := b^.l102;
  end;
  w := rtn^.dfs_last;
  while w <> first do begin
    e := w^.preds;
    while e <> nil do begin
      u := eval(e^.source);
      if u^.members^.w8 < w^.members^.w8 then
        w^.members := u^.members;
      dv := evaldef(e^.source);
      if dv <> nil then
        bv_$or(rtn^.l192 + 1, dv, w^.avail_in);
      e := e^.next_pred;
    end;
    ent := mrh_$alloc_fixed(bucket_heap);
    ent^.b0 := w;
    ent^.n12 := ent_ptr_t(w^.members^.next142);
    w^.members^.next142 := bb_ptr_t(ent);
    bv_$copy(rtn^.l192 + 1, w^.avail_in, w^.avail_gen);
    bv_$or(rtn^.l192 + 1, w^.transparent, w^.avail_gen);
    w^.mark146 := integer32(w^.l106);
    while w^.l106^.next142 <> nil do begin
      p := w^.l106;
      ent := ent_ptr_t(p^.next142);
      v := ent^.b0;
      p^.next142 := bb_ptr_t(ent^.n12);
      u := eval(v);
      if u^.members^.w8 < v^.members^.w8 then
        v^.l54 := u
      else
        v^.l54 := w^.l106;
      bv_$copy(rtn^.l192 + 1, v^.avail_in, v^.avail_out);
      dv := evaldef(v^.l106);
      if dv <> nil then
        bv_$or(rtn^.l192 + 1, dv, v^.avail_out);
    end;
    w := w^.l102;
  end;
  mrh_$release_all(bucket_heap);
  first^.l106 := nil;
  first^.next142 := nil;
  first^.mark146 := 0;
  first^.members := nil;
  w := bb_ptr_t(first^.l98);
  while w <> nil do begin
    if w^.l54 <> w^.members then begin
      bv_$or(rtn^.l192 + 1, w^.l54^.avail_out, w^.avail_out);
      w^.l54 := w^.l54^.l54;
    end;
    w^.l106 := nil;
    w^.members := nil;
    w^.next142 := nil;
    w^.mark146 := 0;
    w := bb_ptr_t(w^.l98);
  end;
  w := first;
  while w <> nil do begin
    w^.f.b19_2 := true;
    if w^.l54 <> nil then begin
      w^.l50 := w^.l54^.l46;
      w^.l54^.l46 := w;
    end;
    w := bb_ptr_t(w^.l98);
  end;
  compute_rel(first);
  if ssa then
    traverse(first);
  mrh_$release_all(bucket_heap);
  rdfs_first := nil;
  rdfs_last := nil;
  b := rtn^.bbs;
  while b <> nil do begin
    b^.l98 := nil;
    b^.l102 := nil;
    b := b^.next;
  end;
  first^.l98 := nil;
  first^.l102 := nil;
  first := rtn^.bb80;
  reverse_depth_first_search(first);
  w := rdfs_last;
  while w <> first do begin
    e := w^.succs;
    while e <> nil do begin
      u := eval(e^.target);
      if u^.members^.w8 < w^.members^.w8 then
        w^.members := u^.members;
      e := e^.next_succ;
    end;
    ent := mrh_$alloc_fixed(bucket_heap);
    ent^.b4 := w;
    ent^.n8 := ent_ptr_t(w^.members^.next142);
    w^.members^.next142 := bb_ptr_t(ent);
    w^.mark146 := integer32(w^.l106);
    while w^.l106^.next142 <> nil do begin
      p := w^.l106;
      ent := ent_ptr_t(p^.next142);
      v := ent^.b4;
      p^.next142 := bb_ptr_t(ent^.n8);
      u := eval(v);
      if u^.members^.w8 < v^.members^.w8 then
        v^.l58 := u
      else
        v^.l58 := w^.l106;
    end;
    w := w^.l102;
  end;
  mrh_$release_all(bucket_heap);
  w := bb_ptr_t(first^.l98);
  while w <> nil do begin
    if w^.l58 <> w^.members then
      w^.l58 := w^.l58^.l58;
    w := bb_ptr_t(w^.l98);
  end;
  n := 0;
  b := rtn^.bbs;
  while b <> nil do begin
    n := n + 1;
    b^.w8 := n;
    b := b^.next;
  end;
  if ssa then begin
    lir_main_c8e := true;
    if lir_main_c86 <> 1 then
      bug_check('FG_UTILS: dominators -- exposed LTSs not attached to LRs%$');
    lr := rtn^.lrs;
    while lr <> nil do begin
      s := lr^.finals;
      while s <> nil do begin
        if (integer(s^.rrp) & 12) <> 0 then begin
          s^.bb^.l134 := s;
          s^.bb^.next142 := bb_ptr_t(lr);
        end;
        s := s^.next_final;
      end;
      x := lr^.exposed;
      while x <> nil do begin
        nx := x^.next_exposed;
        i := utils_ins_$operands_instruction(x^.refs);
        if i^.opc = ord(opc$join_bp) then begin
          rtn^.marks := rtn^.marks + 1;
          add_join_birthpoint_inputs(i, rtn^.marks, lr, x^.bb);
        end
        else begin
          d := x^.bb^.l54;
          while d <> nil do
            if lr_ptr_t(d^.next142) = lr then begin
              f := d^.l134;
              x^.l44 := f;
              x^.l28 := f^.l28;
              f^.l28 := x;
              if f^.l40 = 0 then
                f^.l40 := x^.l40;
              d := nil;
            end
            else
              d := d^.l54;
        end;
        x := nx;
      end;
      lr := lr^.next;
    end;
  end;
end;

{ drop_jbis_on_exposed_list - on the exposed list from list (of the
  block bb, or of its live range when bb is nil), each segment read
  only by a JOIN_BP gives its place to the join's definition (operand 2's
  segment: exposed, its first reference dropped, write and modify
  cleared), and the JOIN_BP is excised.

  0x23715A, 0xA8 bytes, no A5: list (8) in A2, bb (12) in D2; the
  previous segment D3, the join D4. }

procedure drop_jbis_on_exposed_list(
    list: lts_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: lts_ptr_t;
  x: lts_ptr_t;
  f: lts_ptr_t;
  j: instr_ptr_t;
begin
  prev := nil;
  x := list;
  while x <> nil do begin
    if x^.refs <> nil then
      if x^.refs^.link = nil then begin
        j := utils_ins_$operands_instruction(x^.refs);
        if j^.opc = ord(opc$join_bp) then begin
          x^.f2.exposed := false;
          x^.refs := nil;
          f := j^.opnds[2].lts;
          f^.f2.exposed := true;
          f^.refs := f^.refs^.link;
          f^.rrp := f^.rrp - [rrp$modify, rrp$write];
          f^.next_exposed := x^.next_exposed;
          x^.next_exposed := nil;
          if prev <> nil then
            prev^.next_exposed := f
          else if bb <> nil then
            bb^.exposed := f
          else
            x^.lr^.exposed := f;
          x := f;
          lir_utils_$excise_inst(j);
        end;
      end;
    prev := x;
    x := x^.next_exposed;
  end;
end;

{ drop_unconsumed_exposed_segments - the segments on the exposed list
  from list (bb's, or the live range's when bb is nil) that nothing
  references taken off it.

  0x237204, 0x60 bytes, no A5: list (8) in A0, bb (12) in A2. }

procedure drop_unconsumed_exposed_segments(
    list: lts_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: lts_ptr_t;
  n: lts_ptr_t;
begin
  prev := nil;
  while list <> nil do begin
    n := list^.next_exposed;
    if list^.refs = nil then begin
      list^.f2.exposed := false;
      if prev <> nil then
        prev^.next_exposed := n
      else if bb <> nil then
        bb^.exposed := n
      else
        list^.lr^.exposed := n;
      list^.next_exposed := nil;
    end
    else
      prev := list;
    list := n;
  end;
end;

{ drop_unconsumed_final_segments - the same for a final list.

  0x237264, 0x60 bytes, no A5. }

procedure drop_unconsumed_final_segments(
    list: lts_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: lts_ptr_t;
  n: lts_ptr_t;
begin
  prev := nil;
  while list <> nil do begin
    n := list^.next_final;
    if list^.refs = nil then begin
      list^.f2.final := false;
      if prev <> nil then
        prev^.next_final := n
      else if bb <> nil then
        bb^.finals := n
      else
        list^.lr^.finals := n;
      list^.next_final := nil;
    end
    else
      prev := list;
    list := n;
  end;
end;

{ fg_utils_$drop_old_join_birthpoints - when the SSA form is up
  (lir_main_c8e): the JOIN_BPs dropped and the unreferenced exposed
  and final segments taken off their lists (by live range or by block,
  lir_main_c86), each live range's unreferenced segments freed
  (bug_check when one is still exposed or final), the others' l28 and
  l44 cleared; the two join heaps emptied; lir_main_c8e cleared.

  0x2372C4, 0x124 bytes: rtn (8) in A2. }

procedure fg_utils_$drop_old_join_birthpoints(
    rtn: rtn_ptr_t);
var
  lr: lr_ptr_t;
  b: bb_ptr_t;
  prev: lts_ptr_t;
  s: lts_ptr_t;
  n: lts_ptr_t;
begin
  if lir_main_c8e then begin
    if lir_main_c86 = 1 then begin
      lr := rtn^.lrs;
      while lr <> nil do begin
        drop_jbis_on_exposed_list(lr^.exposed, nil);
        drop_unconsumed_exposed_segments(lr^.exposed, nil);
        drop_unconsumed_final_segments(lr^.finals, nil);
        lr := lr^.next;
      end;
    end
    else begin
      b := rtn^.bbs72;
      while b <> nil do begin
        drop_jbis_on_exposed_list(b^.exposed, b);
        drop_unconsumed_exposed_segments(b^.exposed, b);
        drop_unconsumed_final_segments(b^.finals, b);
        b := b^.next114;
      end;
    end;
    lr := rtn^.lrs;
    while lr <> nil do begin
      prev := nil;
      s := lr^.ltss;
      while s <> nil do begin
        n := s^.next;
        if s^.refs <> nil then begin
          s^.l28 := nil;
          s^.l44 := nil;
          prev := s;
        end
        else begin
          if s^.f2.exposed or s^.f2.final then
            bug_check('FG_UTILS_$DROP_OLD_BIRTHPOINTS: exposed/final segments should have been dropped%$');
          if prev = nil then
            lr^.ltss := s^.next
          else
            prev^.next := s^.next;
          lir_$free_lifetime_segment(s);
        end;
        s := n;
      end;
      lr := lr^.next;
    end;
    mrh_$release_all(jbi_input_heap);
    mrh_$release_all(jbi_heap);
    lir_main_c8e := false;
  end;
end;

{ fg_utils_$recompute_postnum - the blocks numbered again: order in
  postorder (bbs72, next114), w8 in code order (bbs, next), from 1.

  0x23743A, 0x48 bytes. }

procedure fg_utils_$recompute_postnum(
    rtn: rtn_ptr_t);
var
  n: integer32;
  b: bb_ptr_t;
begin
  n := 1;
  b := rtn^.bbs72;
  while b <> nil do begin
    b^.order := n & 16#FFFF;
    n := n + 1;
    b := b^.next114;
  end;
  n := 1;
  b := rtn^.bbs;
  while b <> nil do begin
    b^.w8 := n;
    n := n + 1;
    b := b^.next;
  end;
end;

{ fg_utils_$recompute_dominators_and_dfs_lists - the depth-first lists
  made again (the switches' sw3 passed on), the join birthpoints
  dropped, the global data flow walked, then (with the live ranges'
  hints valid, lir_main_c8d set for the while) the intervals when how
  has bit 0 and the dominators, the SSA form when how has bit 1.

  0x237482, 0x92 bytes: rtn (8) in A2, how (12) a word in D3, level
  (14); `addq.l #2,SP' after drop_old_join_birthpoints (pattern 221). }

procedure fg_utils_$recompute_dominators_and_dfs_lists(
    rtn: rtn_ptr_t;
    how: integer;
    level: integer32);
var
  save: boolean;
begin
  fg_utils_$compute_dfs_lists(rtn, level, at_backend_switches.sw3);
  fg_utils_$drop_old_join_birthpoints(rtn);
  df_utils_$global_walk(rtn, rtn^.l192, lir_main_c86, level);
  save := lir_main_c8d;
  lir_main_c8d := true;
  if (how & 1) <> 0 then
    fg_utils_$intervals(rtn);
  fg_utils_$dominators(rtn, (how & 2) <> 0, level);
  lir_main_c8d := save;
end;
