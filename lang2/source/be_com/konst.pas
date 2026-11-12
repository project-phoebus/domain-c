{ konst - the KONST phase (cc.a88k only): sparse conditional constant
  propagation over the lifetime segments.  Each definition gets a
  definition descriptor (DD), unique in a hash table: what is known of
  the value (kind 0 nothing, overdefined; 2 some bits, value under a
  mask; 3 a closed signed range, with the bits it implies; 4 a
  constant; 5 not yet known; 1 a symbol's address, +24).  Blocks become
  executable as edges are followed from the entry (an edge's +15 bit 0
  marks it followed); the instructions of a newly reachable block and
  the readers of a changed definition are marked (+28) and evaluated:
  moves copy, loads from the literal pool give the literal's bits,
  conditional branches whose condition codes are known follow only
  one edge, a join birthpoint merges its inputs from executable paths
  (verified by a walk back from the join, verify_jbis).  Finally each
  read of a register whose low bits are known becomes an immediate
  operand where the opcode can encode it, and the edges never followed
  (and unreachable blocks' instructions) are removed.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x24016C  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x24018E  konst_$begin_compilation
    --------  0x240190  konst_$end_compilation
    --------  0x240192  enter_dd_in_hash_table (internal)
    --------  0x24044E  merge_definitions (internal)
    --------  0x240592  dd_for_constant (internal)
    --------  0x2405B2  dd_for_closed_signed_range (internal)
    --------  0x2405DE  apply_output_value (internal)
    --------  0x240642  verify_jbis (internal)
    --------  0x2406AA  scan_paths_back_to_jbi_definitions (internal)
    --------  0x240716  evaluate_join_bp (internal)
    --------  0x2407FA  find_fge_operand (internal)
    --------  0x240858  newly_reachable_bb (internal)
    --------  0x24097A  followable_flow_graph_edge (internal)
    --------  0x2409A8  dd_from_operand (internal)
    --------  0x240ACC  dd_literal_pool_reference (internal)
    --------  0x240C3A  fp_rel_to_0_ccs_from_dd (internal)
    --------  0x240C40  ip_rel_to_0_ccs_from_dd (internal)
    --------  0x240CD0  can_predict_conditional_branch (internal)
    --------  0x240E0E  evaluate_instruction (internal)
    --------  0x2412BC  mark_reader_instructions (internal)
    --------  0x24133A  propagate_definition (internal)
    --------  0x241464  bb_with_marked_instrs (internal)
    --------  0x2414AA  propagate_constants (internal)
    --------  0x24156E  initialize_queues (internal)
    --------  0x2415BA  initialize (internal)
    --------  0x2416FE  update_constant_operands (internal)
    --------  0x241830  update_constants (internal)
    --------  0x2418EE  correct_control_flow_instructions (internal)
    --------  0x241A52  update_control_flow_graph (internal)
    --------  0x241B6C  konst_$process_routine
    --------  0x241BC6  konst_$end_routine
    A5 0x486D04 (0x8C bytes, jbr's too): the definitions' queues by
    kind (+0 the last, +24 the first of each), the DD heap (+48), the
    walk numbers, the block queues (chained at a block's +150, -1 at
    the end), the hash table (+104), the shared DDs (+116 .. +136).

  During KONST a segment's +32 is its place on a queue (-1 the last),
  +40 its DD; an instruction's +28 word marks it for evaluation; a
  block's +130 holds a join input and +146 the walk number verify_jbis
  leaves (batch A's records, read through views: docs/questions.md
  232).

  Not known from the original: every local, parameter, type and module
  variable name but the routines'; the views' field names. }
module konst;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/common/source/htm.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  ko_end = -1;                          { the queues' end marker }

type
  ko_dd_ptr_t = ^ko_dd_t;

  { A DD's +4: its hash (the low byte the kind) or, alone, the kind. }
  ko_key_t = record
    case integer of
      1: (key: integer32);
      2: (k4, k5, k6: char;
          kind: char);                  { +7 }
  end;

  { A definition descriptor (32 bytes, from the DD heap): known (+12)
    the bits whose value (+8) is known; lo and hi (+16, +20) a closed
    signed range (a constant's value both); sym (+24) the symbol of an
    address; serial (+28) its number.  The 21 bytes from the kind are
    hashed. }
  ko_dd_t = record
    next: ko_dd_ptr_t;                  { +0: in its bucket }
    k: ko_key_t;                        { +4 }
    value: integer32;                   { +8 }
    known: integer32;                   { +12 }
    lo: integer32;                      { +16 }
    hi: integer32;                      { +20 }
    sym: univ_ptr;                      { +24 }
    serial: integer32;                  { +28 }
  end;

  { lts_t during KONST. }
  ko_lts_ptr_t = ^ko_lts_t;
  ko_lts_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: 0..65535;                       { +2 }
    refs: opnd_ptr_t;                   { +4 }
    next: ko_lts_ptr_t;                 { +8 }
    bb: bb_ptr_t;                       { +12 }
    space16: array [16..27] of char;
    reached: ko_lts_ptr_t;              { +28: the exposed segments it
                                          reaches (chained at their +28) }
    queue: ko_lts_ptr_t;                { +32: next on its queue }
    space36: array [36..39] of char;
    dd: ko_dd_ptr_t;                    { +40 }
    l44: univ_ptr;                      { +44: the final segment reaching
                                          an exposed one; a definition's
                                          join inputs (ko_jbi_t) }
  end;

  { A join birthpoint's input (utils' ut_jbi_t): instr's low bit (+15
    bit 0) marks an input reached along an executable path. }
  ko_jbi_ptr_t = ^ko_jbi_t;
  ko_jbi_t = record
    next: ko_jbi_ptr_t;                 { +0 }
    next_op: ko_jbi_ptr_t;              { +4 }
    lts: ko_lts_ptr_t;                  { +8 }
    case integer of
      1: (instr: instr_ptr_t);          { +12 }
      2: (i12: integer32);
      3: (f: packed record
            b12, b13, b14: 0..255;
            b15_7_1: 0..127;
            reached: boolean;           { +15 .0 }
            end);
  end;

  { A flow graph edge with next_pred's low bit (+15 bit 0) the mark
    that it was followed. }
  ko_edge_ptr_t = ^ko_edge_t;
  ko_edge_t = record
    source: bb_ptr_t;                   { +0 }
    target: bb_ptr_t;                   { +4 }
    next_succ: ko_edge_ptr_t;           { +8 }
    case integer of
      1: (next_pred: ko_edge_ptr_t);    { +12 }
      2: (i12: integer32);
      3: (f: packed record
            b12, b13, b14: 0..255;
            b15_7_1: 0..127;
            followed: boolean;          { +15 .0 }
            end);
  end;

  { bb_t during KONST: a join input (+130), verify_jbis' walk number
    (+146), the next on a block queue (+150). }
  ko_bb_ptr_t = ^ko_bb_t;
  ko_bb_t = record
    space0: array [0..129] of char;
    jbi: ko_jbi_ptr_t;                  { +130 }
    space134: array [134..145] of char;
    mark: integer32;                    { +146 }
    queue: integer32;                   { +150 }
  end;

  { instr_t's +28 word during KONST: marked for evaluation. }
  ko_instr_ptr_t = ^ko_instr_t;
  ko_instr_t = record
    space0: array [0..27] of char;
    marked: integer;                    { +28 }
  end;

  ko_dd_queues_t = array [0..5] of ko_lts_ptr_t;

var
  ko_last: ko_dd_queues_t;              { +0 }
  ko_first: ko_dd_queues_t;             { +24 }
  ko_heap: mrh_$heap_t;                 { +48: "KONST definition
                                          descriptors" }
  ko_reach_walk: integer32;             { +68: the walk an edge was last
                                          followed in }
  ko_level: integer32;                  { +72: the debug level }
  ko_queue: integer32;                  { +76: the lowest kind queued }
  ko_reach_tail: integer32;             { +80 }
  ko_q84: integer32;                    { +84 (cleared only) }
  ko_mark_tail: integer32;              { +88: the blocks with marked
                                          instructions, last }
  ko_reach_head: integer32;             { +92 }
  ko_q96: integer32;                    { +96 (set only) }
  ko_mark_head: integer32;              { +100 }
  ko_table: htm_$table_ptr_t;           { +104 }
  ko_walk: integer32;                   { +108 }
  ko_count: integer32;                  { +112: the DDs made }
  ko_u16: ko_dd_ptr_t;                  { +116: 0 .. 65535 }
  ko_u8: ko_dd_ptr_t;                   { +120: 0 .. 255 }
  ko_s16: ko_dd_ptr_t;                  { +124: -32768 .. 32767 }
  ko_s8: ko_dd_ptr_t;                   { +128: -128 .. 127 }
  ko_top: ko_dd_ptr_t;                  { +132: kind 5, not yet known }
  ko_bottom: ko_dd_ptr_t;               { +136: kind 0, overdefined }

{ KONST_$BEGIN_COMPILATION, _END_COMPILATION - nothing.  0x24018E,
  0x240190, 2 bytes each (no A5). }

procedure konst_$begin_compilation;
begin
end;

procedure konst_$end_compilation;
begin
end;

{ enter_dd_in_hash_table - the unique DD of kind kind like dd, made
  canonical first: kind 0 and 5 are the shared DDs; an address with
  no symbol is overdefined, a symbol's address knows nothing else; known
  bits with nothing known are an address, all known a constant, the
  sign known a closed signed range, else positive (the unknown bits
  cleared); a range of one value is a constant, an empty one
  overdefined, a range's high bits that both ends share become known
  (a contradiction a bug check); a constant knows every bit.  Found in
  the table (moved to its bucket's head) or made from the heap
  (numbered).

  0x240192, 0x270 bytes, internal: the kind's `case' a jump table of 6
  (kind 6 and above entered as they are); the arms fall into each
  other; the leading bits of the range's differing bits found by a
  loop over a moving mask; htm_$hash_string of the 21 bytes from +7,
  the hash's low byte replaced by the kind. }

function enter_dd_in_hash_table(
    kind: integer32;
    var dd: ko_dd_t): ko_dd_ptr_t; options(val_param); internal;
label
  10, 20, 30, 40, 50, 60;
var
  d, m, bit, t, inv: integer32;
  h, key, bucket: integer32;
  p, prev: ko_dd_ptr_t;
  slot: ^ko_dd_ptr_t;
begin
  case kind of
    0:
      goto 40;
    1:
      goto 30;
    2:
      if dd.known = 0 then begin
        kind := 1;
        goto 30;
      end
      else if dd.known = -1 then begin
        kind := 4;
        dd.lo := dd.value;
        goto 10;
      end
      else if dd.known > 0 then begin
        dd.lo := 0;
        dd.hi := 0;
        dd.value := dd.value & (~dd.known);
      end
      else begin
        dd.lo := dd.value & dd.known;
        dd.hi := (~dd.known) ! dd.value;
        kind := 3;
        goto 20;
      end;
    3:
      goto 20;
    4:
      goto 10;
    5: begin
      enter_dd_in_hash_table := ko_top;
      return;
      end;
    otherwise
  end;
  goto 50;
20:
  if dd.lo = dd.hi then begin
    kind := 4;
    goto 10;
  end;
  if dd.lo > dd.hi then
    goto 40;
  d := xor(dd.hi, dd.lo);
  if d >= 0 then begin
    m := 0;
    bit := 16#80000000;
    while (d & bit) = 0 do begin
      m := m ! bit;
      bit := rshft(bit, 1);
    end;
    dd.known := dd.known ! m;
  end;
  dd.value := dd.value & dd.known;
  t := dd.lo ! dd.value;
  inv := (~dd.known) ! dd.value;
  dd.lo := t & inv;
  dd.hi := (dd.hi ! dd.value) & inv;
  if ((dd.lo & dd.known) <> dd.value) or
     ((dd.hi & dd.known) <> dd.value) or
     ((dd.lo & dd.known) <> (dd.hi & dd.known)) then
    bug_check('KONST_\ENTER_DD_IN_HASH_TABLE -- self-contradictory closed signed range DD%$');
  goto 50;
10:
  dd.hi := dd.lo;
  dd.value := dd.lo;
  dd.known := -1;
  goto 50;
30:
  if dd.sym = nil then
    goto 40;
  dd.lo := 0;
  dd.hi := 0;
  dd.value := 0;
  dd.known := 0;
  goto 50;
40:
  enter_dd_in_hash_table := ko_bottom;
  return;
50:
  dd.k.kind := chr(kind);
  h := htm_$hash_string(dd.k.kind, 21);
  bucket := h & ko_table^.mask;
  key := (h & (~255)) ! kind;
  p := ko_dd_ptr_t(ko_table^.buckets[bucket]);
  slot := univ_ptr(addr(ko_table^.buckets[bucket]));
  while p <> nil do begin
    if (p^.k.key = key) and (p^.lo = dd.lo) and (p^.hi = dd.hi) and
       (p^.value = dd.value) and (p^.known = dd.known) and
       (p^.sym = dd.sym) then begin
      if ko_dd_ptr_t(ko_table^.buckets[bucket]) = p then begin
        enter_dd_in_hash_table := p;
        return;
      end;
      slot^ := p^.next;
      goto 60;
    end;
    slot := univ_ptr(addr(p^.next));
    p := p^.next;
  end;
  p := mrh_$alloc_fixed(ko_heap);
  ko_count := ko_count + 1;
  p^.k.key := key;
  p^.lo := dd.lo;
  p^.hi := dd.hi;
  p^.value := dd.value;
  p^.known := dd.known;
  p^.sym := dd.sym;
  p^.serial := ko_count;
  htm_$increment_table_entries(ko_table, key, bucket);
60:
  p^.next := ko_dd_ptr_t(ko_table^.buckets[bucket]);
  ko_table^.buckets[bucket] := htm_$entry_ptr_t(p);
  enter_dd_in_hash_table := p;
end;

{ merge_definitions - the meet of two DDs: the same one, or the other
  of nil or of kind 0 (overdefined); otherwise by the lesser kind: two
  equal constants stay one, else their range (the bits both share
  known), known bits the bits both know alike, an address nothing; the
  symbol kept when both have it.

  0x24044E, 0x144 bytes, internal: the kinds 1..4 a jump table (higher
  kinds entered with the local unset); the local DD at -40. }

function merge_definitions(
    a: ko_dd_ptr_t;
    b: ko_dd_ptr_t): ko_dd_ptr_t; options(val_param); internal;
label
  10, 20, 30;
var
  dd: ko_dd_t;
  k: integer32;
  x: integer32;
begin
  if (a = b) or (b = nil) then begin
    merge_definitions := a;
    return;
  end;
  if a = nil then begin
    merge_definitions := b;
    return;
  end;
  if a^.k.kind = chr(0) then begin
    merge_definitions := a;
    return;
  end;
  if b^.k.kind = chr(0) then begin
    merge_definitions := b;
    return;
  end;
  if a^.sym = b^.sym then
    dd.sym := a^.sym
  else
    dd.sym := nil;
  k := ord(a^.k.kind);
  if ord(b^.k.kind) < k then
    k := ord(b^.k.kind);
  case k of
    1: begin
      dd.lo := 16#80000000;
      dd.hi := 16#7FFFFFFF;
      dd.value := 0;
      dd.known := 0;
      end;
    2: begin
      dd.lo := 16#80000000;
      dd.hi := 16#7FFFFFFF;
      x := xor(a^.value, b^.value);
      goto 20;
      end;
    3:
      goto 10;
    4:
      if a^.lo = b^.lo then begin
        dd.lo := a^.lo;
        dd.hi := a^.lo;
        dd.value := a^.lo;
        dd.known := -1;
      end
      else begin
        k := 3;
        goto 10;
      end;
    otherwise
  end;
  goto 30;
10:
  dd.lo := a^.lo;
  if dd.lo > b^.lo then
    dd.lo := b^.lo;
  dd.hi := a^.hi;
  if dd.hi < b^.hi then
    dd.hi := b^.hi;
  x := xor(a^.value, b^.value);
20:
  dd.value := (~x) & a^.value;
  dd.known := (~x) & (a^.known & b^.known);
30:
  merge_definitions := enter_dd_in_hash_table(k, dd);
end;

{ dd_for_constant - the DD of the constant v.  0x240592, 0x20 bytes,
  internal. }

function dd_for_constant(
    v: integer32): ko_dd_ptr_t; options(val_param); internal;
var
  dd: ko_dd_t;
begin
  dd.lo := v;
  dd.sym := nil;
  dd_for_constant := enter_dd_in_hash_table(4, dd);
end;

{ dd_for_closed_signed_range - the DD of lo .. hi.  0x2405B2, 0x2C
  bytes, internal. }

function dd_for_closed_signed_range(
    lo: integer32;
    hi: integer32): ko_dd_ptr_t; options(val_param); internal;
var
  dd: ko_dd_t;
begin
  dd.lo := lo;
  dd.hi := hi;
  dd.known := 0;
  dd.sym := nil;
  dd_for_closed_signed_range := enter_dd_in_hash_table(3, dd);
end;

{ apply_output_value - lts's DD becomes dd; a change queues lts (once)
  on the queue of dd's kind, the lowest kind queued kept.

  0x2405DE, 0x64 bytes, internal: the queues by 4 * kind from A5. }

procedure apply_output_value(
    dd: ko_dd_ptr_t;
    lts: ko_lts_ptr_t); options(val_param); internal;
var
  k: integer32;
begin
  if lts^.dd <> dd then begin
    lts^.dd := dd;
    if lts^.queue = nil then begin
      k := ord(dd^.k.kind);
      if ko_last[k] = nil then
        ko_first[k] := lts
      else
        ko_last[k]^.queue := lts;
      ko_last[k] := lts;
      lts^.queue := ko_lts_ptr_t(ko_end);
      if k < ko_queue then
        ko_queue := k;
    end;
  end;
end;

{ verify_jbis - the walk back from a join (number n) over the followed
  edges into bb: a predecessor last walked with a lower number is
  walked; one walked with a higher number (it holds a join input,
  +130, whose definition this walk reaches) has that input marked
  reached.

  0x240642, 0x68 bytes, internal, recursive: the edges' next_pred
  tags masked `andi.l #-2'. }

procedure verify_jbis(
    bb: bb_ptr_t;
    n: integer32); options(val_param); internal;
var
  e: ko_edge_ptr_t;
  src: ko_bb_ptr_t;
begin
  e := ko_edge_ptr_t(bb^.preds);
  while e <> nil do begin
    if e^.f.followed then begin
      src := ko_bb_ptr_t(e^.source);
      if n > src^.mark then begin
        src^.mark := n;
        verify_jbis(e^.source, n);
      end
      else if n < src^.mark then begin
        src^.mark := n;
        src^.jbi^.f.reached := true;
      end;
    end;
    e := ko_edge_ptr_t(e^.i12 & (~1));
  end;
end;

{ scan_paths_back_to_jbi_definitions - the join birthpoint i's inputs
  checked against the edges followed so far: each input's definition
  block marked (one already reached one lower), then the walk back
  from the join's block.

  0x2406AA, 0x6C bytes, internal: the inputs from the join's operand 3
  (+72), chained at their +4. }

procedure scan_paths_back_to_jbi_definitions(
    i: instr_ptr_t); options(val_param); internal;
var
  n: integer32;
  j: ko_jbi_ptr_t;
  bb: ko_bb_ptr_t;
begin
  i^.l16 := ko_reach_walk;
  ko_walk := ko_walk + 2;
  n := ko_walk;
  j := ko_jbi_ptr_t(i^.opnds[3].link);
  while j <> nil do begin
    bb := ko_bb_ptr_t(j^.lts^.bb);
    if j^.f.reached then
      bb^.mark := n - 1
    else begin
      bb^.jbi := j;
      bb^.mark := n;
    end;
    j := j^.next_op;
  end;
  verify_jbis(i^.bb, n - 1);
end;

{ evaluate_join_bp - the join birthpoint i's value: the merge of its
  reached inputs' DDs (rechecked when edges were followed since its
  last check), overdefined when an input's definition does not precede
  the join's block; given to its result (operand 2).

  0x240716, 0xBA bytes, internal. }

procedure evaluate_join_bp(
    i: instr_ptr_t); options(val_param); internal;
var
  stale: boolean;
  order: integer32;
  res: ko_dd_ptr_t;
  j: ko_jbi_ptr_t;
begin
  ko_instr_ptr_t(i)^.marked := 0;
  stale := i^.l16 < ko_reach_walk;
  order := i^.bb^.order;
  res := nil;
  j := ko_jbi_ptr_t(i^.opnds[3].link);
  while j <> nil do begin
    if stale and not j^.f.reached then
      if j^.lts^.bb^.f.executable then begin
        scan_paths_back_to_jbi_definitions(i);
        stale := false;
      end;
    if j^.f.reached then begin
      if j^.lts^.bb^.order <= order then begin
        res := ko_bottom;
        exit;
      end;
      res := merge_definitions(res, j^.lts^.dd);
      if res = ko_bottom then
        exit;
    end;
    j := j^.next_op;
  end;
  if res = nil then
    bug_check('KONST_\EVALUATE_JOIN_BP -- no definition%$');
  apply_output_value(res, ko_lts_ptr_t(i^.opnds[2].lts));
end;

{ find_fge_operand - i's first flow graph edge operand, or nil.
  0x2407FA, 0x5E bytes, internal; A0. }

function find_fge_operand(
    i: instr_ptr_t): opnd_ptr_t; options(val_param); internal;
var
  k: integer;
begin
  for k := 1 to i^.h.nopnds do
    if i^.opnds[k].h.kind = operand$flow_graph_edge then begin
      find_fge_operand := addr(i^.opnds[k]);
      return;
    end;
  find_fge_operand := nil;
end;

{ newly_reachable_bb - bb reached: if it was already, its leading
  labels and join birthpoints are marked for evaluation; otherwise it
  becomes executable, all its instructions marked and the block queued,
  and with hidden successor edges every edge out that no branch of the
  block names is followed.

  0x240858, 0x122 bytes, internal, recursive: the classes label and
  join_bp as the mask 0x4080000, the branches (branch, fp_branch,
  jump, return) as 0x1000062. }

procedure newly_reachable_bb(
    bb: bb_ptr_t); options(val_param); internal;
label
  10;
var
  i, fj, j: instr_ptr_t;
  e: ko_edge_ptr_t;
  op: opnd_ptr_t;
begin
  if bb^.f.executable then begin
    i := bb^.first;
    while i <> nil do begin
      if not (instruction_attributes[i^.opc].class in
              [class$label, class$join_bp]) then
        return;
      ko_instr_ptr_t(i)^.marked := 1;
      i := i^.next;
    end;
    return;
  end;
  bb^.f.executable := true;
  fj := nil;
  i := bb^.first;
  while i <> nil do begin
    ko_instr_ptr_t(i)^.marked := 1;
    if fj = nil then
      if instruction_attributes[i^.opc].class in [class$branch,
          class$fp_branch, class$jump, class$return] then
        fj := i;
    i := i^.next;
  end;
  if ko_mark_tail = 0 then
    ko_mark_head := integer32(bb)
  else
    ko_bb_ptr_t(ko_mark_tail)^.queue := integer32(bb);
  ko_mark_tail := integer32(bb);
  ko_bb_ptr_t(bb)^.queue := ko_end;
  if bb^.f.hidden_successor_edges then begin
    e := ko_edge_ptr_t(bb^.succs);
    while e <> nil do begin
      j := fj;
      while j <> nil do begin
        op := find_fge_operand(j);
        if op <> nil then
          if op^.ptr = univ_ptr(e) then
            goto 10;
        j := j^.next;
      end;
      if not e^.f.followed then begin
        e^.f.followed := true;
        ko_reach_walk := ko_walk;
        newly_reachable_bb(e^.target);
      end;
10:
      e := e^.next_succ;
    end;
  end;
end;

{ followable_flow_graph_edge - e followed (once): its target reached.
  0x24097A, 0x2E bytes, internal. }

procedure followable_flow_graph_edge(
    e: ko_edge_ptr_t); options(val_param); internal;
begin
  if not e^.f.followed then begin
    e^.f.followed := true;
    ko_reach_walk := ko_walk;
    newly_reachable_bb(e^.target);
  end;
end;

{ dd_from_operand - what an operand's value is known to be: a register
  or memory operand's segment's DD (a read's from the final segment
  reaching it; not yet known when there is none), a "like" register's
  or case jump base's segment's, an immediate's constant; a
  displacement or symbol overdefined.

  0x2409A8, 0xBE bytes, internal: the operand kinds a jump table of 29;
  A0. }

function dd_from_operand(
    op: opnd_ptr_t): ko_dd_ptr_t; options(val_param); internal;
var
  lts: ko_lts_ptr_t;
  dd: ko_dd_ptr_t;
begin
  case op^.h.kind of
    operand$ip_reg, operand$fp_reg, operand$fp_reg_pair,
    operand$ip_reg_physical, operand$fp_reg_physical,
    operand$fp_reg_pair_physical, operand$ip_condition_codes,
    operand$fp_condition_codes, operand$argument_block_memory,
    operand$inscrutable_memory, operand$well_behaved_memory: begin
      lts := ko_lts_ptr_t(op^.lts);
      if lts^.rrp * [rrp$modify, rrp$write] <> [] then
        dd := lts^.dd
      else if lts^.l44 <> nil then
        dd := ko_lts_ptr_t(lts^.l44)^.dd
      else
        dd := ko_top;
      if dd = nil then
        dd := ko_top;
      end;
    operand$ip_reg_like, operand$fp_reg_like, operand$fp_reg_pair_like,
    operand$case_jump_base:
      dd := ko_lts_ptr_t(op^.lts)^.dd;
    operand$displacement_routine, operand$displacement_arg_block,
    operand$displacement_stack_frame, operand$displacement_literal_pool,
    operand$displacement_XSB_base, operand$bind_time_immediate:
      dd := ko_bottom;
    operand$immediate:
      dd := dd_for_constant(op^.value);
    operand$none, operand$forward_label_reference,
    operand$flow_graph_edge, operand$symbol_definition,
    operand$label_reference, operand$join_birthpoint_inputs,
    operand$exception_information, operand$spare_2:
      bug_check('KONST_\DD_FROM_OPERAND -- illegal operand kind%$');
    otherwise
      bug_check('KONST_\DD_FROM_OPERAND -- unrecognized operand kind%$');
  end;
  dd_from_operand := dd;
end;

{ dd_literal_pool_reference - the constant a load of the literal pool
  (i's operand 1: the literal, its displacement) reads at offset off:
  the literal's longwords (a single's bits, a double converted to a
  single, the longwords of a double or a quadword), the byte or
  halfword of the load zero- or sign-extended; overdefined for other
  literals or an access past the literal.

  0x240ACC, 0x16E bytes, internal: the literal kinds a jump table of
  21; the access size 1 shl the opcode's +19 bits 2..0; the double's
  conversion through fpp_$ (0x0074 0x00D4 0xFF3E: docs/dpc-gaps.md 7);
  the sign extensions `swap; clr.w; lsl.l #8; swap; ext.l; asr.l #8'
  and `swap; clr.w; swap; ext.l'. }

function dd_literal_pool_reference(
    i: instr_ptr_t;
    off: integer32): ko_dd_ptr_t; options(val_param); internal;
var
  lit: lit_ptr_t;
  w0, w1, w2, w3, size, v: integer32;
  s: ko_dd_ptr_t;
  r: real;
begin
  off := off + i^.opnds[1].value;
  lit := lit_ptr_t(i^.opnds[1].link);
  case lit^.kind of
    0, 1, 2, 3, 8, 9, 10, 11: begin
      w0 := lit^.value;
      size := 4;
      end;
    12: begin
      r := lit^.d;
      w0 := integer32(r);
      size := 4;
      end;
    13, 14: begin
      w0 := lit^.value;
      w1 := lit^.l12;
      size := 8;
      end;
    15: begin
      w0 := lit^.value;
      w1 := lit^.l12;
      w2 := lit^.l16;
      w3 := lit^.l20;
      size := 16;
      end;
    18: begin
      dd_literal_pool_reference := ko_bottom;
      return;
      end;
    19, 20: begin
      dd_literal_pool_reference := ko_bottom;
      return;
      end;
    otherwise begin
      dd_literal_pool_reference := ko_bottom;
      return;
      end;
  end;
  if off + lshft(1, instruction_attributes[i^.opc].w18 & 7) > size then begin
    dd_literal_pool_reference := ko_bottom;
    return;
  end;
  case off of
    0: v := w0;
    4: v := w1;
    8: v := w2;
    12: v := w3;
    otherwise begin
      dd_literal_pool_reference := ko_bottom;
      return;
      end;
  end;
  if i^.opc = ord(opc$loadbu) then
    v := v & 255
  else if i^.opc = 217 then
    v := arshft(lshft(v, 24), 24)
  else if i^.opc = ord(opc$loadwu) then
    v := v & 65535
  else if i^.opc = 218 then
    v := arshft(lshft(v, 16), 16);
  dd_literal_pool_reference := dd_for_constant(v);
end;

{ fp_rel_to_0_ccs_from_dd - the floating condition codes are never
  known.  0x240C3A, 6 bytes, internal, no frame. }

function fp_rel_to_0_ccs_from_dd(
    dd: ko_dd_ptr_t): ko_dd_ptr_t; options(val_param); internal;
begin
  fp_rel_to_0_ccs_from_dd := ko_bottom;
end;

{ ip_rel_to_0_ccs_from_dd - the integer condition codes of a compare
  with 0 of dd's value: N (bit 31) known when the value's sign is, Z
  (bit 30) known set when it is 0 (all known), the low three bits'
  flag (bit 27) known set when they are 0; v and mask the bits known
  already.

  0x240C40, 0x90 bytes, internal: the value bits read at +16 (lo) and
  the known bits at +12. }

function ip_rel_to_0_ccs_from_dd(
    dd: ko_dd_ptr_t;
    v: integer32;
    mask: integer32): ko_dd_ptr_t; options(val_param); internal;
var
  cc: ko_dd_t;
begin
  if dd^.lo < 0 then
    v := v ! 16#80000000;
  if dd^.known < 0 then
    mask := mask ! 16#80000000;
  if dd^.lo = 0 then
    v := v ! 16#40000000;
  if dd^.known = -1 then
    mask := mask ! 16#40000000;
  if (dd^.lo & 7) = 0 then
    v := v ! 16#08000000;
  if (dd^.known & 7) = 7 then
    mask := mask ! 16#08000000;
  cc.lo := v;
  cc.hi := v;
  cc.value := v;
  cc.known := mask;
  cc.sym := nil;
  ip_rel_to_0_ccs_from_dd := enter_dd_in_hash_table(2, cc);
end;

{ can_predict_conditional_branch - whether the branch i's direction is
  known from its condition codes' DD (always when not yet known, never
  when overdefined): its condition's bit known (N for BN/BNN, Z bit 30
  for BEQ/BNE, V bit 29 for BV/BNV, bit 26 for BL2/BNL2, bit 27 for
  BZ3/BNZ3) and a JUMP after it; then only the edge it takes is
  followed.

  0x240CD0, 0x13E bytes, internal: the opcodes 2..27 a jump table. }

function can_predict_conditional_branch(
    i: instr_ptr_t;
    dd: ko_dd_ptr_t): boolean; options(val_param); internal;
var
  v, m: integer32;
  taken, known: boolean;
  j: instr_ptr_t;
begin
  if dd^.k.kind = chr(0) then begin
    can_predict_conditional_branch := false;
    return;
  end;
  if dd^.k.kind = chr(5) then begin
    can_predict_conditional_branch := true;
    return;
  end;
  v := dd^.value;
  m := dd^.known;
  known := false;
  case i^.opc of
    ord(opc$bnn): begin
      taken := v >= 0;
      known := m < 0;
      end;
    ord(opc$bn): begin
      taken := v < 0;
      known := m < 0;
      end;
    ord(opc$bne): begin
      taken := not (30 in bv_word_t(v));
      known := 30 in bv_word_t(m);
      end;
    ord(opc$beq): begin
      taken := 30 in bv_word_t(v);
      known := 30 in bv_word_t(m);
      end;
    ord(opc$bnv): begin
      taken := not (29 in bv_word_t(v));
      known := 29 in bv_word_t(m);
      end;
    ord(opc$bv): begin
      taken := 29 in bv_word_t(v);
      known := 29 in bv_word_t(m);
      end;
    ord(opc$bnl2): begin
      taken := not (26 in bv_word_t(v));
      known := 26 in bv_word_t(m);
      end;
    ord(opc$bl2): begin
      taken := 26 in bv_word_t(v);
      known := 26 in bv_word_t(m);
      end;
    ord(opc$bnz3): begin
      taken := not (27 in bv_word_t(v));
      known := 27 in bv_word_t(m);
      end;
    ord(opc$bz3): begin
      taken := 27 in bv_word_t(v);
      known := 27 in bv_word_t(m);
      end;
    otherwise
  end;
  if known then begin
    j := i^.next;
    if (j = nil) or (j^.opc <> ord(opc$jump)) or
       (j^.opnds[1].h.kind <> operand$flow_graph_edge) then
      known := false
    else if taken then
      followable_flow_graph_edge(ko_edge_ptr_t(i^.opnds[1].ptr))
    else
      followable_flow_graph_edge(ko_edge_ptr_t(j^.opnds[1].ptr));
  end;
  can_predict_conditional_branch := known;
end;

{ evaluate_instruction - i's results: a MOVE copies its source's DD, a
  load of the literal pool through a "like" base register the
  literal's constant; a conditional branch follows the edge its known
  condition codes choose, or all its block's edges; a JUMP its one
  edge.  A MOVE's or load's integer condition codes become those of a
  compare of the result with 0 (C and V known clear); every other
  written register operand is overdefined.

  0x240E0E, 0x330 bytes, internal: the opcodes a chain of compares;
  the operands handled a set (D2) by their numbers. }

procedure evaluate_instruction(
    i: instr_ptr_t); options(val_param); internal;
var
  res: integer32;
  done: bv_word_t;
  op: opnd_ptr_t;
  dd: ko_dd_ptr_t;
  e: ko_edge_ptr_t;
  n, k: integer32;
begin
  res := 0;
  done := [];
  case i^.opc of
    ord(opc$label$), ord(opc$label):
      return;
    ord(opc$move): begin
      apply_output_value(dd_from_operand(addr(i^.opnds[1])),
          ko_lts_ptr_t(i^.opnds[2].lts));
      done := [2];
      res := 2;
      end;
    ord(opc$loadl), 218, ord(opc$loadwu), 217, ord(opc$loadbu):
      if (i^.opnds[1].h.kind = operand$displacement_literal_pool) and
         (i^.opnds[2].h.kind = operand$ip_reg_like) then begin
        apply_output_value(dd_literal_pool_reference(i, 0),
            ko_lts_ptr_t(i^.opnds[3].lts));
        done := [3];
        res := 3;
      end;
    ord(opc$bnl2v), ord(opc$bl2v), ord(opc$bnl2), ord(opc$bl2),
    ord(opc$bnz3), ord(opc$bz3), ord(opc$bgt), ord(opc$ble),
    ord(opc$bge), ord(opc$blt), ord(opc$bhi), ord(opc$bls),
    ord(opc$blo), ord(opc$bhs), ord(opc$bnn), ord(opc$bn),
    ord(opc$bne), ord(opc$beq), ord(opc$bnv), ord(opc$bv),
    ord(opc$fbeq), ord(opc$fbne), ord(opc$fbgt), ord(opc$fble),
    ord(opc$fbge), ord(opc$fblt): begin
      if i^.opnds[1].h.kind <> operand$flow_graph_edge then
        bug_check('KONST_\EVALUATE_INSTRUCTION -- target of cond-branch is not expressed as an FGE%$');
      op := addr(i^.opnds[i^.h.nopnds]);
      if not (op^.h.kind in [operand$ip_condition_codes,
              operand$fp_condition_codes]) then
        bug_check('KONST_\EVALUATE_INSTRUCTION -- condition codes operands not at expected index%$');
      dd := ko_lts_ptr_t(op^.lts)^.dd;
      if dd = nil then
        bug_check('KONST_\EVALUATE_INSTRUCTION -- no definition descriptor for CC input%$');
      if not can_predict_conditional_branch(i, dd) then begin
        e := ko_edge_ptr_t(i^.bb^.succs);
        while e <> nil do begin
          followable_flow_graph_edge(e);
          e := e^.next_succ;
        end;
      end;
      end;
    ord(opc$jump): begin
      if i^.opnds[1].h.kind <> operand$flow_graph_edge then
        if not i^.bb^.f.hidden_successor_edges then
          bug_check('KONST_\EVALUATE_INSTRUCTION -- target of JUMP is not expressed as an FGE%$');
      e := ko_edge_ptr_t(i^.bb^.succs);
      if e <> nil then
        if e^.next_succ = nil then
          if univ_ptr(e) = i^.opnds[1].ptr then
            followable_flow_graph_edge(ko_edge_ptr_t(i^.opnds[1].ptr));
      end;
    otherwise
  end;
  if (res <> 0) and i^.h.sets_cc then begin
    if i^.opnds[i^.h.nopnds].h.kind <> operand$ip_condition_codes then
      bug_check('KONST_\EVALUATE_INSTRUCTION -- IP CCs operand not at end of operand array%$');
    n := i^.h.nopnds;
    done := done + [n];
    apply_output_value(ip_rel_to_0_ccs_from_dd(
        ko_lts_ptr_t(i^.opnds[res].lts)^.dd, 0, 16#30000000),
        ko_lts_ptr_t(i^.opnds[n].lts));
  end;
  for k := 1 to i^.h.nopnds do
    if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then
      if not ((k <= 31) and (k in done)) then
        apply_output_value(ko_bottom, ko_lts_ptr_t(i^.opnds[k].lts));
end;

{ mark_reader_instructions - the instructions reading lts (its
  references after the definition) marked, their block queued, when
  the block is executable.

  0x2412BC, 0x7E bytes, internal: the reader's instruction by
  utils_ins_$operands_instruction. }

procedure mark_reader_instructions(
    lts: ko_lts_ptr_t); options(val_param); internal;
var
  op: opnd_ptr_t;
  bb: bb_ptr_t;
begin
  op := lts^.refs;
  if op = nil then
    return;
  if (opnd_bytes_ptr_t(op)^.rrp & 12) <> 0 then
    op := op^.link;
  if op = nil then
    return;
  bb := lts^.bb;
  if not bb^.f.executable then
    return;
  if ko_bb_ptr_t(bb)^.queue = 0 then begin
    if ko_mark_tail = 0 then
      ko_mark_head := integer32(bb)
    else
      ko_bb_ptr_t(ko_mark_tail)^.queue := integer32(bb);
    ko_mark_tail := integer32(bb);
    ko_bb_ptr_t(bb)^.queue := ko_end;
  end;
  repeat
    ko_instr_ptr_t(utils_ins_$operands_instruction(op))^.marked := 1;
    op := op^.link;
  until op = nil;
end;

{ propagate_definition - a definition's new DD reaches its readers, the
  readers of the exposed segments it reaches and the join birthpoints
  it is an input of.

  0x24133A, 0xB0 bytes, internal: the messages end in '%' alone. }

procedure propagate_definition(
    lts: ko_lts_ptr_t); options(val_param); internal;
var
  s: ko_lts_ptr_t;
  j: ko_jbi_ptr_t;
  i: instr_ptr_t;
  bb: bb_ptr_t;
begin
  if lts^.rrp * [rrp$modify, rrp$write] = [] then
    bug_check('KONST_\PROPAGATE_DEFINITION -- lts is not a definition%');
  if lts^.dd = nil then
    bug_check('KONST_\PROPAGATE_DEFINITION -- lts^.definition_descriptor is NIL%');
  mark_reader_instructions(lts);
  s := lts^.reached;
  while s <> nil do begin
    mark_reader_instructions(s);
    s := s^.reached;
  end;
  j := ko_jbi_ptr_t(lts^.l44);
  while j <> nil do begin
    i := instr_ptr_t(j^.i12 & (~1));
    ko_instr_ptr_t(i)^.marked := 1;
    bb := i^.bb;
    if bb^.f.executable then
      if ko_bb_ptr_t(bb)^.queue = 0 then begin
        if ko_mark_tail = 0 then
          ko_mark_head := integer32(bb)
        else
          ko_bb_ptr_t(ko_mark_tail)^.queue := integer32(bb);
        ko_mark_tail := integer32(bb);
        ko_bb_ptr_t(bb)^.queue := ko_end;
      end;
    j := j^.next;
  end;
end;

{ bb_with_marked_instrs - bb's marked instructions evaluated (a join
  birthpoint by evaluate_join_bp).  0x241464, 0x46 bytes, internal. }

procedure bb_with_marked_instrs(
    bb: bb_ptr_t); options(val_param); internal;
var
  i: instr_ptr_t;
begin
  i := bb^.first;
  while i <> nil do begin
    if ko_instr_ptr_t(i)^.marked <> 0 then begin
      ko_instr_ptr_t(i)^.marked := 0;
      if i^.opc = ord(opc$join_bp) then
        evaluate_join_bp(i)
      else
        evaluate_instruction(i);
    end;
    i := i^.next;
  end;
end;

{ propagate_constants - the work: the definitions queued, lowest kind
  first (each taken starts the scan again), then the reached blocks'
  queue, then the blocks with marked instructions, until all are empty.

  0x2414AA, 0xC4 bytes, internal: the kind read as ko_queue's low word
  (+78); the end marker -1. }

procedure propagate_constants; internal;
label
  10;
var
  p: ko_lts_ptr_t;
  b: integer32;
begin
10:
  ko_queue := 0;
  while ko_queue <> 5 do begin
    p := ko_first[ko_queue];
    if p <> ko_lts_ptr_t(ko_end) then begin
      ko_first[ko_queue] := p^.queue;
      if p^.queue = ko_lts_ptr_t(ko_end) then
        ko_last[ko_queue] := nil;
      p^.queue := nil;
      propagate_definition(p);
      goto 10;
    end;
    ko_queue := ko_queue + 1;
  end;
  b := ko_reach_head;
  if b <> ko_end then begin
    ko_reach_head := ko_bb_ptr_t(b)^.queue;
    if ko_reach_head = ko_end then
      ko_reach_tail := 0;
    ko_bb_ptr_t(b)^.queue := 0;
    newly_reachable_bb(bb_ptr_t(b));
    goto 10;
  end;
  b := ko_mark_head;
  if b <> ko_end then begin
    ko_mark_head := ko_bb_ptr_t(b)^.queue;
    if ko_mark_head = ko_end then
      ko_mark_tail := 0;
    ko_bb_ptr_t(b)^.queue := 0;
    bb_with_marked_instrs(bb_ptr_t(b));
    goto 10;
  end;
end;

{ initialize_queues - every queue empty.  0x24156E, 0x4C bytes,
  internal, no frame. }

procedure initialize_queues; internal;
var
  k: integer;
begin
  ko_q96 := ko_end;
  ko_reach_head := ko_end;
  ko_mark_head := ko_end;
  ko_q84 := 0;
  ko_reach_tail := 0;
  ko_mark_tail := 0;
  for k := 0 to 5 do begin
    ko_first[k] := ko_lts_ptr_t(ko_end);
    ko_last[k] := nil;
  end;
  ko_queue := 0;
end;

{ initialize - the table (256 buckets) and heap of DDs, the shared DDs
  (not yet known, overdefined, the byte and halfword ranges), the
  queues; a new walk number; every block's marks and instructions'
  marks cleared; the entry block executable and its edges followed.

  0x2415BA, 0x126 bytes, internal: the heap's flags and size one
  longword (pattern 105). }

procedure initialize(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  e: ko_edge_ptr_t;
begin
  ko_table := htm_$create_table(256);
  mrh_$initialize(ko_heap, 1, 32, 'KONST definition descriptors%');
  ko_top := mrh_$alloc_fixed(ko_heap);
  ko_top^.k.kind := chr(5);
  ko_top^.serial := 1;
  ko_bottom := mrh_$alloc_fixed(ko_heap);
  ko_bottom^.k.kind := chr(0);
  ko_bottom^.serial := 2;
  ko_count := 2;
  ko_s8 := dd_for_closed_signed_range(-128, 127);
  ko_s16 := dd_for_closed_signed_range(-32768, 32767);
  ko_u8 := dd_for_closed_signed_range(0, 255);
  ko_u16 := dd_for_closed_signed_range(0, 65535);
  initialize_queues;
  ko_reach_walk := 0;
  rtn^.marks := rtn^.marks + 1;
  ko_walk := rtn^.marks;
  rtn^.bbs^.f.executable := true;
  bb := rtn^.bbs;
  while bb <> nil do begin
    ko_bb_ptr_t(bb)^.mark := 0;
    ko_bb_ptr_t(bb)^.queue := 0;
    i := bb^.first;
    while i <> nil do begin
      i^.l24 := 0;
      i^.l16 := 0;
      ko_instr_ptr_t(i)^.marked := 0;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
  e := ko_edge_ptr_t(rtn^.bbs^.succs);
  while e <> nil do begin
    followable_flow_graph_edge(e);
    e := e^.next_succ;
  end;
end;

{ update_constant_operands - each reader op (and those linked after it,
  until one is replaced) whose relevant low bits dd knows becomes an
  immediate operand of that value (shifted by its count) when the
  opcode can encode it there; a move so changed is no longer a
  preference move.  A reader needing no bits is reported on standard
  output.

  0x2416FE, 0x104 bytes, internal: the report a `writeln' (pas_$write,
  pas_$writeln: docs/dpc-gaps.md 4); the walk continues from the
  replaced operand's link, which it has just cleared. }

procedure update_constant_operands(
    dd: ko_dd_ptr_t;
    op: opnd_ptr_t); options(val_param); internal;
var
  i: instr_ptr_t;
  n, mask, v: integer32;
begin
  while op <> nil do begin
    i := utils_ins_$operands_instruction(op);
    n := sem_utils_$number_of_relevant_low_order_bits(op);
    if n = 0 then
      writeln('--- number_of_relevant_low_order_bits = 0 ---');
    mask := lshft(1, n) - 1;
    if (dd^.known = -1) or ((dd^.known & mask) = mask) then begin
      v := lshft(dd^.value & mask, op^.h.count);
      if tm_utils_$can_encode_as_immediate_operand(v, i^.opc,
          op^.h.num) then begin
        utils_$remove_reader_from_lts(op, true);
        op^.h.kind := operand$immediate;
        op^.h.count := 0;
        op^.h.fp_reg_odd_only := false;
        op^.h.fp_reg_even_only := false;
        op^.value := v;
        op^.link := nil;
        if instruction_attributes[i^.opc].b6_0 then
          i^.h.preference := false;
      end;
    end;
    op := op^.link;
  end;
end;

{ update_constants - the DDs found put to use: in each register live
  range, each definition in an executable block gives its DD to the
  executable exposed segments it reaches (and, when it knows bits,
  their readers' operands) and to its own readers; an exposed segment
  no definition reaches is not yet known.

  0x241830, 0xBE bytes, internal. }

procedure update_constants(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  s, r: ko_lts_ptr_t;
  dd: ko_dd_ptr_t;
  k: integer32;
begin
  lr := rtn^.lrs;
  while lr <> nil do begin
    if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] <> [] then begin
      s := ko_lts_ptr_t(lr^.ltss);
      while s <> nil do begin
        if s^.bb^.f.executable then
          if s^.rrp * [rrp$modify, rrp$write] <> [] then begin
            dd := s^.dd;
            if dd = nil then
              dd := ko_bottom;
            k := ord(dd^.k.kind);
            r := s^.reached;
            while r <> nil do begin
              if r^.bb^.f.executable then begin
                r^.dd := dd;
                if k > 1 then
                  update_constant_operands(dd, r^.refs);
              end;
              r := r^.reached;
            end;
            update_constant_operands(dd, s^.refs^.link);
          end
          else if s^.l44 = nil then
            s^.dd := ko_top;
        s := s^.next;
      end;
    end;
    lr := lr^.next;
  end;
end;

{ correct_control_flow_instructions - bb lost edges: its closing
  instruction (a JUMP, trap or RETURN) jumps to its one remaining edge
  (a register target turned into the edge), and the conditional
  branches before it to that edge or to a removed one are deleted.

  0x2418EE, 0x10C bytes, internal: the closing classes as the mask
  0x1004040, the register and memory kinds as 4094, the branches as
  34. }

procedure correct_control_flow_instructions(
    bb: bb_ptr_t); options(val_param); internal;
var
  n: integer32;
  e: fg_edge_ptr_t;
  last, i: instr_ptr_t;
  target: univ_ptr;
  op: opnd_ptr_t;
begin
  n := 0;
  e := bb^.succs;
  while e <> nil do begin
    n := n + 1;
    e := e^.next_succ;
  end;
  last := bb^.last;
  if not (instruction_attributes[last^.opc].class in [class$jump,
          class$trap, class$return]) then
    bug_check('KONST_\CORRECT_CONTROL_FLOW_INSTRUCTIONS -- bb not terminated by an unconditional JUMP%$');
  if n = 1 then begin
    if last^.opnds[1].h.kind in [operand$ip_reg ..
        operand$well_behaved_memory] then begin
      utils_$remove_reader_from_lts(addr(last^.opnds[1]), true);
      last^.opnds[1].h.kind := operand$flow_graph_edge;
    end;
    last^.opnds[1].ptr := bb^.succs;
  end;
  target := nil;
  if last^.opnds[1].h.kind = operand$flow_graph_edge then
    target := last^.opnds[1].ptr;
  i := last^.prev;
  while i <> nil do begin
    if not (instruction_attributes[i^.opc].class in [class$branch,
            class$fp_branch]) then
      exit;
    op := find_fge_operand(i);
    if op <> nil then
      if (op^.ptr = target) or (fg_edge_ptr_t(op^.ptr)^.source = nil) then
        utils_$excise_instruction_cleanly(i, true);
    i := i^.prev;
  end;
end;

{ update_control_flow_graph - the edges never followed removed (their
  source cleared) and the followed ones' marks cleared; a reachable
  block that lost edges corrected, an unreachable one emptied; with any
  removed, the predecessor lists rebuilt and the dominators and depth
  first lists recomputed.  Whether any was removed.

  0x241A52, 0x11A bytes, internal: the blocks in the order from the
  routine's +72 (chained at +114). }

function update_control_flow_graph(
    rtn: rtn_ptr_t): boolean; options(val_param); internal;
var
  changed, removed: boolean;
  bb: bb_ptr_t;
  e, prev: ko_edge_ptr_t;
  i, nxt: instr_ptr_t;
begin
  changed := false;
  bb := rtn^.bbs72;
  while bb <> nil do begin
    ko_bb_ptr_t(bb)^.queue := 0;
    removed := false;
    e := ko_edge_ptr_t(bb^.succs);
    bb^.succs := nil;
    prev := nil;
    while e <> nil do begin
      if not e^.f.followed then begin
        e^.source := nil;
        removed := true;
      end
      else begin
        e^.f.followed := false;
        if prev = nil then
          bb^.succs := fg_edge_ptr_t(e)
        else
          prev^.next_succ := e;
        prev := e;
      end;
      e := e^.next_succ;
    end;
    if prev <> nil then
      prev^.next_succ := nil;
    changed := changed or removed;
    if bb^.f.executable then begin
      if removed then
        correct_control_flow_instructions(bb);
    end
    else begin
      i := bb^.first;
      while i <> nil do begin
        nxt := i^.next;
        utils_$excise_instruction_cleanly(i, true);
        i := nxt;
      end;
    end;
    bb := bb^.next114;
  end;
  if changed then begin
    bb := rtn^.bbs72;
    while bb <> nil do begin
      e := ko_edge_ptr_t(bb^.preds);
      bb^.preds := nil;
      prev := nil;
      while e <> nil do begin
        if e^.source <> nil then begin
          if prev = nil then
            bb^.preds := fg_edge_ptr_t(e)
          else
            prev^.next_pred := e;
          prev := e;
        end;
        e := e^.next_pred;
      end;
      if prev <> nil then
        prev^.next_pred := nil;
      bb := bb^.next114;
    end;
    fg_utils_$recompute_dominators_and_dfs_lists(rtn, 1,
        at_backend_switches.level - 1);
  end;
  update_control_flow_graph := changed;
end;

{ KONST_$PROCESS_ROUTINE - the phase, at debug level 1 or more only:
  initialize, propagate, use the constants, prune the flow graph; the
  routine's walk number moved past konst's.

  0x241B6C, 0x5A bytes (A5): the level `and.b #7' of +0x501; the flow
  graph's result dropped. }

procedure konst_$process_routine;
begin
  if at_backend_switches.level <> 0 then begin
    ko_level := at_backend_switches.level;
    initialize(rtn);
    propagate_constants;
    update_constants(rtn);
    discard(update_control_flow_graph(rtn));
    rtn^.marks := ko_walk + 1;
  end;
end;

{ KONST_$END_ROUTINE - the DD heap released.  0x241BC6, 0x1E bytes
  (A5). }

procedure konst_$end_routine;
begin
  mrh_$release_all(ko_heap);
end;
