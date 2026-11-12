{ hal - the HAL phase of the PRISM back end (hammocks and loops): the
  empty blocks forwarded and senseless loops ended, a header block
  guaranteed before each loop and a tail block on each loop exit, the
  dominators and depth-first lists recomputed, then the hammocks found
  (a block and the block after it such that the first dominates the
  second, the second postdominates the first, both are in the same
  loop and interval, and no path inside goes back through the head)
  and arranged in a tree under lir_main_c70.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x238334  zero (internal)
    --------  0x23834C  collect_hammocks (internal)
    --------  0x2384C6  bb_contains_final_call (internal)
    --------  0x238550  build_work_list (internal)
    --------  0x238616  collect_or_test_hammock_contents (internal)
    --------  0x2386EC  bb_interval (internal)
    --------  0x238706  bb_inside_loop (internal)
    --------  0x238734  loop_header_safe (internal)
    --------  0x23879A  no_path_through_head_in_hammock (internal)
    --------  0x2387C6  hal_$find_hammocks
    --------  0x23899A  build_basic_block (internal)
    --------  0x238A4A  guarantee_header (internal)
    --------  0x238B60  hal_$insert_loop_headers (internal)
    --------  0x238B9A  bb_is_in_loop (internal)
    --------  0x238BD4  hal_$insert_loop_tails (internal)
    --------  0x238CD6  hal_$begin_compilation
    --------  0x238D06  hal_$end_compilation
    --------  0x238D08  hal_$process_routine
    --------  0x238D94  hal_$end_routine
    A5 0x4864D4: the module's data: the hammock heap (+0, "hammocks",
    records of 38 bytes), the dominator vectors' heap (+24).

  A block's fields as hal uses them (backend.ins.pas bb_t): order (+12)
  its bit in the dominator vectors, f.b16 its loop depth, +18 bit 6 a
  loop head (bit 5: one hal leaves alone; bit 3 and bit 1 blocks no
  hammock starts at), +19 bit 7 a hammock's head, bit 6 its end, bit 5
  a hammock with a loop head inside; l46 / l50 the dominator tree, l58
  the candidate ends, l70 the head of its interval, avail_out (+126)
  its dominators, l82 the head of the hammock it is in, l102 / l106
  the hammock's blocks, l98 the hammock record, l150 the work list.
  Opcodes: a new block's JUMP; LABEL instructions moved to a new
  header, JOIN_BP left; a final CALL.

  Not known from the original: every local and parameter name; the
  module variables' names; the hammock record's type and field names. }
module hal;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { A hammock (38 bytes from the hammock heap; a head block's l98):
    its head, the block after it, the hammock it is inside, the first
    hammock inside it and its siblings' list. }
  hal_hammock_ptr_t = ^hal_hammock_t;
  hal_hammock_t = record
    head: bb_ptr_t;                     { +0 }
    tail: bb_ptr_t;                     { +4 }
    parent: hal_hammock_ptr_t;          { +8 }
    child: hal_hammock_ptr_t;           { +12 }
    next: hal_hammock_ptr_t;            { +16 }
    prev: hal_hammock_ptr_t;            { +20 }
  end;

var
  hammock_heap: mrh_$heap_t;            { +0 }
  unused_20: integer32;                 { +20 }
  dom_heap: mrh_$heap_t;                { +24 }

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0): rev889-patterns 100.

  0x238334, 0x18 bytes, internal, no frame: p at (4,SP), n at (8,SP). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := 0;
  end;
end;

{ collect_hammocks - the hammocks headed in bb's dominator subtree and
  its siblings' (bb chained through l50), each visited block marked:
  a block that heads none passes its own hammock (its hammock head's
  record) down to its dominator children; a head's chain of hammocks
  (a hammock ending in the head of the next) becomes one record (from
  the first head reached back through the +19 bit 6 ends to the end
  of the last) put first in parent's children (or the top list,
  lir_main_c70, for none), the chain's own records made its children.

  0x23834C, 0x17A bytes: parent (8) in D4, bb (12) in D3, mark (16) in
  D2.  The address of lir_main_c40 is loaded into D5 and not used
  (rev889-patterns 53).  The calls for a block's children share a tail
  (0x238462). }

procedure collect_hammocks(
    parent: hal_hammock_ptr_t;
    bb: bb_ptr_t;
    mark: integer32); options(val_param); internal;
var
  h: hal_hammock_ptr_t;
  first: bb_ptr_t;
  last: bb_ptr_t;
  rec: hal_hammock_ptr_t;
  top: hal_hammock_ptr_t;
begin
  while bb <> nil do begin
    if bb^.mark146 <> mark then begin
      bb^.mark146 := mark;
      if not bb^.f.b19_7 then begin
        if bb^.l82 = nil then
          h := nil
        else
          h := hal_hammock_ptr_t(bb^.l82^.l98);
        collect_hammocks(h, bb^.l46, mark);
      end
      else begin
        first := bb;
        while first^.f.b19_6 do begin
          first := first^.preds^.source;
          if not first^.f.b19_7 then
            first := first^.l82;
          first^.mark146 := mark;
        end;
        last := bb;
        while hal_hammock_ptr_t(last^.l98)^.tail^.f.b19_7 do begin
          last := hal_hammock_ptr_t(last^.l98)^.tail;
          last^.mark146 := mark;
        end;
        last := hal_hammock_ptr_t(last^.l98)^.tail;
        if (first = bb) and (hal_hammock_ptr_t(bb^.l98)^.tail = last) then
          rec := hal_hammock_ptr_t(bb^.l98)
        else begin
          rec := mrh_$alloc_fixed(hammock_heap);
          rec^.head := first;
          rec^.tail := last;
        end;
        rec^.parent := parent;
        if parent = nil then begin
          top := hal_hammock_ptr_t(lir_main_c70);
          if top <> nil then begin
            top^.prev := rec;
            rec^.next := top;
          end;
          lir_main_c70 := rec;
        end
        else begin
          if parent^.child <> nil then begin
            parent^.child^.prev := rec;
            rec^.next := parent^.child;
          end;
          parent^.child := rec;
        end;
        if rec = hal_hammock_ptr_t(bb^.l98) then
          collect_hammocks(rec, bb^.l46, mark)
        else
          repeat
            h := hal_hammock_ptr_t(first^.l98);
            if rec^.child <> nil then begin
              rec^.child^.prev := h;
              h^.next := rec^.child;
            end;
            rec^.child := h;
            h^.parent := rec;
            collect_hammocks(h, first^.l46, mark);
            first := h^.tail;
          until first = last;
      end;
    end;
    bb := bb^.l50;
  end;
end;

{ bb_contains_final_call - whether bb ends (before a last jump, trap
  or return: the mask 0x01004040 of classes, and any SEQs) in a CALL
  whose +3 bit 3 or bit 5 is set.

  0x2384C6, 0x8A bytes: bb (8); `st'/`clr.b' D0. }

function bb_contains_final_call(
    bb: bb_ptr_t): boolean; options(val_param); internal;
var
  result: boolean;
  i: instr_ptr_t;
begin
  result := false;
  i := bb^.last;
  if i <> nil then begin
    if instruction_attributes[i^.opc].class in
       [class$jump, class$trap, class$return] then
      i := i^.prev;
    while (i <> nil) and then
          (instruction_attributes[i^.opc].class = class$seq) do
      i := i^.prev;
    if i <> nil then
      if i^.opc = ord(opc$call) then
        if ((i^.h.width & 8) <> 0) or ((i^.h.width & 16#20) <> 0) then
          result := true;
  end;
  bb_contains_final_call := result;
end;

{ build_work_list - the dominator vectors over bb's dominator subtree
  (bb's avail_out := vec, its children's a copy with bb's bit set),
  and the blocks with dominator children that may head a hammock (not
  +18 bit 3 or bit 1, no final call) put on the work list (l150).

  0x238550, 0x110 bytes: bb (8), vec (12), nbytes (16), list (20) by
  address.  A leaf of the dominator tree returns at once (not listed).
  The copy by longwords ((nbytes + 3) div 4), the bit set through a
  cleared frame longword (dpc's set constructor, rev889). }

procedure build_work_list(
    bb: bb_ptr_t;
    vec: bv_ptr_t;
    nbytes: integer32;
    var list: bb_ptr_t); options(val_param); internal;
var
  child: bb_ptr_t;
  v: bv_ptr_t;
  k: integer32;
begin
  bb^.avail_out := vec;
  child := bb^.l46;
  if child <> nil then begin
    if not bb^.f.b18_3 and not bb^.f.b18_1 then
      if not bb_contains_final_call(bb) then begin
        bb^.l150 := list;
        list := bb;
      end;
    v := mrh_$alloc_fixed(dom_heap);
    for k := 0 to rshft(nbytes + 3, 2) - 1 do
      v^[k] := vec^[k];
    v^[bb^.order div 32] := v^[bb^.order div 32] + [bb^.order mod 32];
    repeat
      build_work_list(child, v, nbytes, list);
      child := child^.l50;
    until child = nil;
  end;
end;

{ collect_or_test_hammock_contents - with test, whether every block
  reachable from bb before tail (not through head again) may be in a
  hammock headed by head (not +18 bit 3, not after head in order);
  without test, those blocks put on head's list (l82 := head, l106,
  head's l102), a hammock met skipped whole (from its end), and head's
  +19 bit 5 set when a loop head is inside.

  0x238616, 0xD6 bytes: bb (8), head (12), tail (16), test (20, a
  byte), mark (22); the answer in D2.  The order compared unsigned
  (`bls').  A successor is followed when its mark is below this
  walk's (`ble' past it). }

function collect_or_test_hammock_contents(
    bb: bb_ptr_t;
    head: bb_ptr_t;
    tail: bb_ptr_t;
    test: boolean;
    mark: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  e: fg_edge_ptr_t;
  s: bb_ptr_t;
begin
  if bb^.f.b18_3 or (bb^.order > head^.order) then begin
    result := false;
    if test then begin
      collect_or_test_hammock_contents := false;
      return;
    end;
  end
  else
    result := true;
  if (bb <> tail) and (bb^.mark146 <> mark) then begin
    bb^.mark146 := mark;
    if bb <> head then begin
      if not test then begin
        bb^.l82 := head;
        bb^.l106 := head^.l102;
        head^.l102 := bb;
      end;
      if bb^.f.b19_7 then begin
        collect_or_test_hammock_contents :=
          collect_or_test_hammock_contents(
              hal_hammock_ptr_t(bb^.l98)^.tail, head, tail, test, mark);
        return;
      end;
    end;
    e := bb^.succs;
    while e <> nil do begin
      s := e^.target;
      if (s <> tail) and (s^.mark146 < mark) then begin
        if s^.f.b18_6 then
          head^.f.b19_5 := true;
        if not collect_or_test_hammock_contents(s, head, tail, test,
                                                mark) then begin
          result := false;
          if test then begin
            collect_or_test_hammock_contents := false;
            return;
          end;
        end;
      end;
      e := e^.next_succ;
    end;
  end;
  collect_or_test_hammock_contents := result;
end;

{ bb_interval - the head of bb's interval: bb itself when it is a loop
  head (+18 bit 6) not left alone (bit 5), else its l70.

  0x2386EC, 0x1A bytes, no frame (bb at (4,SP)); A0. }

function bb_interval(
    bb: bb_ptr_t): bb_ptr_t; options(val_param); internal;
begin
  if bb^.f.b18_6 and not bb^.f.b18_5 then
    bb_interval := bb
  else
    bb_interval := bb^.l70;
end;

{ bb_inside_loop - whether head is bb or one of its interval heads (up
  l70), when bb's loop depth is not below head's.

  0x238706, 0x2E bytes, no frame (bb at (4,SP), head at (8,SP)); the
  depths compared unsigned (`bcc'). }

function bb_inside_loop(
    bb: bb_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
var
  b: bb_ptr_t;
begin
  bb_inside_loop := false;
  if bb^.f.b16 >= head^.f.b16 then begin
    b := bb;
    while b <> nil do begin
      if b = head then begin
        bb_inside_loop := true;
        return;
      end;
      b := b^.l70;
    end;
  end;
end;

{ loop_header_safe - whether tail dominates every predecessor of the
  loop head head that is inside the loop (other than tail): tail's bit
  in their dominator vectors.

  0x238734, 0x66 bytes: head (8), tail (12); tail's order in D2. }

function loop_header_safe(
    head: bb_ptr_t;
    tail: bb_ptr_t): boolean; options(val_param); internal;
var
  k: integer32;
  e: fg_edge_ptr_t;
begin
  k := tail^.order;
  e := head^.preds;
  while e <> nil do begin
    if e^.source <> tail then
      if bb_inside_loop(e^.source, head) then
        if not ((k mod 32) in e^.source^.avail_out^[k div 32]) then begin
          loop_header_safe := false;
          return;
        end;
    e := e^.next_pred;
  end;
  loop_header_safe := true;
end;

{ no_path_through_head_in_hammock - collect_or_test_hammock_contents
  testing from head with a new mark.

  0x23879A, 0x2C bytes: rtn (8), head (12), tail (16).  head pushed
  twice, the second by `move.l (SP),-(SP)' (rev889-patterns 69); the
  callee's D0 left as the result (rev889-patterns 87). }

function no_path_through_head_in_hammock(
    rtn: rtn_ptr_t;
    head: bb_ptr_t;
    tail: bb_ptr_t): boolean; options(val_param); internal;
begin
  rtn^.marks := rtn^.marks + 1;
  no_path_through_head_in_hammock :=
    collect_or_test_hammock_contents(head, head, tail, true, rtn^.marks);
end;

{ hal_$find_hammocks - the routine's hammocks.

  0x2387C6, 0x1C2 bytes: rtn (8) in D3.  The hammock heap emptied,
  lir_main_c70 cleared; each block's mark, l82, l106 and +19 bits 7..5
  (`andi.w #0xFF1F' of +18) cleared.  The vectors' bytes: the first
  block's order rounded up to 32 bits (`andi.b #0xE0'); the vectors'
  heap made for them ("dominator vectors", flags 0), a cleared vector
  for the root and the work list built.  For each block on the list,
  each candidate end (l58, l58's l58, ...) not +18 bit 3, of the same
  loop depth and interval, dominated by the block (its bit in the
  candidate's vector), safe for a loop head, with no path through the
  head: a hammock record (head, end) for the block (l98, +19 bit 7,
  l102 cleared; the end +19 bit 6) and its contents collected (new
  mark), the candidates' search ended.  The vectors' heap emptied; the
  tree collected from the first block with a new mark.  The first
  interval head is kept in a frame slot (-28) for the comparison. }

procedure hal_$find_hammocks(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
  nbytes: integer32;
  v: bv_ptr_t;
  list: bb_ptr_t;
  head: bb_ptr_t;
  tail: bb_ptr_t;
  k: integer32;
  rec: hal_hammock_ptr_t;
  iv: bb_ptr_t;
  found: boolean;
begin
  mrh_$release_all(hammock_heap);
  lir_main_c70 := nil;
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.mark146 := 0;
    bb^.l82 := nil;
    bb^.l106 := nil;
    bb^.f.b19_7 := false;
    bb^.f.b19_6 := false;
    bb^.f.b19_5 := false;
    bb := bb^.next;
  end;
  nbytes := rshft((rtn^.bbs^.order + 31) & 16#FFFFFFE0, 3);
  mrh_$initialize(dom_heap, 0, nbytes, 'dominator vectors%');
  v := mrh_$alloc_fixed(dom_heap);
  zero(v, nbytes);
  list := nil;
  build_work_list(rtn^.bbs, v, nbytes, list);
  head := list;
  while head <> nil do begin
    tail := head^.l58;
    k := head^.order;
    while tail <> nil do begin
      found := false;
      if not tail^.f.b18_3 and (tail^.f.b16 = head^.f.b16) then begin
        iv := bb_interval(tail);
        if iv = bb_interval(head) then
          if (k mod 32) in tail^.avail_out^[k div 32] then
            if not head^.f.b18_6 or loop_header_safe(head, tail) then
              found := no_path_through_head_in_hammock(rtn, head, tail);
      end;
      if found then begin
        rec := mrh_$alloc_fixed(hammock_heap);
        head^.l98 := univ_ptr(rec);
        rec^.head := head;
        rec^.tail := tail;
        head^.f.b19_7 := true;
        head^.l102 := nil;
        tail^.f.b19_6 := true;
        rtn^.marks := rtn^.marks + 1;
        discard(collect_or_test_hammock_contents(head, head, tail, false,
                                                 rtn^.marks));
        tail := nil;
      end
      else
        tail := tail^.l58;
    end;
    head := head^.l150;
  end;
  mrh_$release_all(dom_heap);
  rtn^.marks := rtn^.marks + 1;
  collect_hammocks(nil, rtn^.bbs, rtn^.marks);
end;

{ build_basic_block - a new block before bb (in code order: next,
  next114) with bb's interval head and its depth, put on bb's l78
  chain after it, taking edges (its edges in, chained at next_pred,
  retargeted), holding one JUMP (+2 bit 6, operand 1 a flow graph edge
  to bb).

  0x23899A, 0xB0 bytes: edges (8) in D2, bb (12); A0.
  lir_$new_instruction's word argument padded (rev889-patterns 8). }

function build_basic_block(
    edges: fg_edge_ptr_t;
    bb: bb_ptr_t): bb_ptr_t; options(val_param); internal;
var
  nb: bb_ptr_t;
  e: fg_edge_ptr_t;
  j: instr_ptr_t;
begin
  nb := lir_$new_basic_block;
  nb^.next := bb;
  nb^.next114 := bb^.next114;
  nb^.next114^.next := nb;
  bb^.next114 := nb;
  nb^.l70 := bb^.l70;
  if nb^.l70 <> nil then
    nb^.f.b16 := nb^.l70^.f.b16;
  nb^.l78 := bb^.l78;
  bb^.l78 := nb;
  nb^.preds := edges;
  e := edges;
  repeat
    e^.target := nb;
    e := e^.next_pred;
  until e = nil;
  j := lir_$new_instruction(ord(opc$jump));
  j^.bb := nb;
  j^.h.b2_6 := true;
  j^.opnds[1].h.kind := operand$flow_graph_edge;
  j^.opnds[1].h.num := 1;
  j^.opnds[1].ptr := lir_$add_flow_graph_edge(nb, bb);
  nb^.first := j;
  nb^.last := j;
  build_basic_block := nb;
end;

{ guarantee_header - a header block before the loop head head: the
  loop's entering edges separated (fg_utils_$separate_loop_header_edges
  with false); none, or one from a block of one successor, put back
  first on head's edges in; otherwise a new block takes them and the
  head's leading LABELs (among its leading LABELs and JOIN_BPs) move to
  it, in order.

  0x238A4A, 0x116 bytes: head (8) in D2; the last label moved in D1. }

procedure guarantee_header(
    head: bb_ptr_t); options(val_param); internal;
var
  edges: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  multi: boolean;
  nb: bb_ptr_t;
  prev: instr_ptr_t;
  i: instr_ptr_t;
  nx: instr_ptr_t;
begin
  edges := fg_utils_$separate_loop_header_edges(head, head, false);
  if edges = nil then
    return;
  if edges^.next_pred <> nil then
    multi := true
  else if edges^.source^.succs^.next_succ <> nil then
    multi := true
  else
    multi := false;
  if not multi then begin
    e := edges;
    while e^.next_pred <> nil do
      e := e^.next_pred;
    e^.next_pred := head^.preds;
    head^.preds := edges;
    return;
  end;
  nb := build_basic_block(edges, head);
  prev := nil;
  i := head^.first;
  while (i <> nil) and then
        ((i^.opc = ord(opc$join_bp)) or (i^.opc = ord(opc$label))) do begin
    nx := i^.next;
    if i^.opc = ord(opc$label) then begin
      i^.bb := nb;
      if i^.prev = nil then
        head^.first := i^.next
      else
        i^.prev^.next := i^.next;
      if i^.next = nil then
        head^.last := i^.prev
      else
        i^.next^.prev := i^.prev;
      if prev = nil then begin
        i^.next := nb^.first;
        nb^.first := i;
        i^.prev := nil;
      end
      else begin
        i^.next := prev^.next;
        prev^.next := i;
        i^.prev := prev;
      end;
      i^.next^.prev := i;
      prev := i;
    end;
    i := nx;
  end;
end;

{ hal_$insert_loop_headers - a header for each loop head (+18 bit 6)
  not left alone (bit 5).  0x238B60, 0x3A bytes: rtn (8). }

procedure hal_$insert_loop_headers(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    if bb^.f.b18_6 and not bb^.f.b18_5 then
      guarantee_header(bb);
    bb := bb^.next;
  end;
end;

{ bb_is_in_loop - whether head is bb or an interval head above it (up
  l70) while the depths are not below head's.

  0x238B9A, 0x3A bytes: bb (8), head (12); the depths compared
  unsigned (`bcc'). }

function bb_is_in_loop(
    bb: bb_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
var
  b: bb_ptr_t;
begin
  b := bb;
  while (b <> nil) and then (b^.f.b16 >= head^.f.b16) do begin
    if b = head then begin
      bb_is_in_loop := true;
      return;
    end;
    b := b^.l70;
  end;
  bb_is_in_loop := false;
end;

{ hal_$insert_loop_tails - a tail block on each loop exit: a block
  (+18 bit 1, or a loop head without l74) of two successors, in a loop
  not left alone, one successor inside the loop and the other (the
  exit, not the final block, +80) not reached from below the head (up
  its l54 chain): the exit's edges from the loop separated (true) and
  given a new block, whose l54 is the exiting block.  In the order of
  the routine's +72 (through next114).

  0x238BD4, 0x102 bytes: rtn (8) in D2, the block in D3, the loop's
  head in D4. }

procedure hal_$insert_loop_tails(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  e: fg_edge_ptr_t;
  head: bb_ptr_t;
  b: bb_ptr_t;
  edges: fg_edge_ptr_t;
  nb: bb_ptr_t;
begin
  bb := rtn^.bbs72;
  while bb <> nil do begin
    if bb^.f.b18_1 or (bb^.f.b18_6 and (bb^.l74 = nil)) then
     if bb^.succs^.next_succ <> nil then
      if bb^.succs^.next_succ^.next_succ = nil then begin
        if bb^.f.b18_6 then
          head := bb
        else
          head := bb^.l70;
        if not head^.f.b18_5 then begin
          e := nil;
          if not bb_is_in_loop(bb^.succs^.target, head) then
            e := bb^.succs
          else if not bb_is_in_loop(bb^.succs^.next_succ^.target,
                                    head) then
            e := bb^.succs^.next_succ;
          if e <> nil then
            if e^.target <> rtn^.bb80 then begin
              b := e^.target^.l54;
              while (b <> head) and (b <> nil) and then
                    (b^.f.b16 >= head^.f.b16) do
                b := b^.l54;
              if b <> head then begin
                edges := fg_utils_$separate_loop_header_edges(e^.target,
                                                              head, true);
                nb := build_basic_block(edges, edges^.target);
                nb^.l54 := bb;
              end;
            end;
        end;
      end;
    bb := bb^.next114;
  end;
end;

{ hal_$begin_compilation - the hammock heap ("hammocks", flags 1,
  records of 38 bytes: the two words pushed as one longword,
  rev889-patterns 105).  0x238CD6, 0x26 bytes. }

procedure hal_$begin_compilation;
begin
  mrh_$initialize(hammock_heap, 1, 38, 'hammocks%');
end;

{ hal_$end_compilation - nothing.  0x238D06, 2 bytes. }

procedure hal_$end_compilation;
begin
end;

{ hal_$process_routine - the phase: unless switch 15, and (unless
  lir_main_da4) the empty blocks forwarded (again when senseless loops
  were ended), the bit vectors released, the loops' headers and tails,
  the dominators and dfs lists recomputed (2, level 0); then the
  hammocks.

  0x238D08, 0x8C bytes: rtn (8) in A2.  forward_empty_blocks' result
  dropped; recompute's arguments after `addq.l #2,SP' (two bytes of
  the previous call's argument left: rev889-patterns 51). }

procedure hal_$process_routine(
    rtn: rtn_ptr_t);
begin
  lir_utils_$sanity_check(rtn);
  if not at_backend_switches.sw15 then begin
    if not lir_main_da4 then begin
      discard(fg_utils_$forward_empty_blocks(rtn));
      if fg_utils_$end_senseless_loops(rtn) then
        discard(fg_utils_$forward_empty_blocks(rtn));
      bv_$release_bit_vectors(rtn);
      hal_$insert_loop_headers(rtn);
      hal_$insert_loop_tails(rtn);
      fg_utils_$recompute_dominators_and_dfs_lists(rtn, 2, 0);
    end;
    hal_$find_hammocks(rtn);
  end;
end;

{ hal_$end_routine - the hammock heap emptied.  0x238D94, 0x1C bytes. }

procedure hal_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(hammock_heap);
end;
