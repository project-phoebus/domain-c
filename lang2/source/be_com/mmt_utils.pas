{ mmt_utils - the memory model (MMT) phase's utilities: memory live
  ranges kept for reuse, the MMT_SEQ instructions (kept by operand
  count for reuse) and their tokens, the address comparisons and the
  analysis of the blocks' memory references (com, oli, mmt).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x2551D8  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x2551FA  zero (internal)
    --------  0x255210  mmt_utils_$begin_compilation
    --------  0x255212  mmt_utils_$init_for_routine
    --------  0x25524E  mmt_utils_$end_routine
    --------  0x255250  mmt_utils_$end_compilation
    --------  0x255252  mmt_utils_$save_mem_lr (internal)
    --------  0x25526C  mmt_utils_$save_unneeded_lrs (internal)
    --------  0x2552E0  mmt_utils_$mark_lr_for_removal (internal)
    --------  0x2552F6  mmt_utils_$get_mem_lr
    --------  0x255364  mmt_utils_$lr_is_for_memory
    --------  0x2553BA  mmt_utils_$save_mmt_seq_instruction (internal)
    --------  0x2553E4  mmt_utils_$get_mmt_seq_instruction (internal)
    --------  0x2554A8  add_operand (internal)
    --------  0x255534  build_mmt_seq_instr (internal)
    --------  0x255576  mmt_utils_$mmt_seq_emit
    --------  0x255942  mmt_utils_$mmt_seq_add_token
    --------  0x255A0C  mmt_utils_$mmt_seq_add_tokens_from_instr
    --------  0x255A90  mmt_utils_$mmt_seq_add_tokens_from_bv
    --------  0x255B04  mmt_utils_$can_combine_mmt_seqs
    --------  0x255C04  get_base_and_index (internal)
    --------  0x255C68  disp_known (internal)
    --------  0x255DA8  mmt_utils_$addr_compare
    --------  0x25601A  mmt_utils_$set_address_comparison_function
    --------  0x256054  allocate_descriptor (internal)
    --------  0x256300  compared_already (internal)
    --------  0x2563A0  ids_related (internal)
    --------  0x25642A  inform_about_relationships (internal)
    --------  0x256516  mark_related_references (internal)
    --------  0x256636  discover_relationships (internal)
    --------  0x256AB8  free_mmt_seqs_and_ltss (internal)
    --------  0x256D10  bind_new_tokens_to_operands (internal)
    --------  0x256F6A  insert_mmt_seqs (internal)
    --------  0x2572C6  fill_in_ltss (internal)
    --------  0x257824  count_and_bind_complex_lrs (internal)
    --------  0x25789E  mmt_utils_$analyze_one_bb
    --------  0x257CEC  mmt_utils_$analyze_blocks
    A5 0x48C544: the module's data (0x80 bytes): the MMT_SEQ
    instructions kept for reuse by operand count (+0, 21 chains, 0 for
    more than 20), the descriptors' bit vectors (+84), a mark (+88), the
    descriptors (+92, a table of +96 entries of 40 bytes followed by
    mmt's token map), the memory live ranges kept for reuse (+100), the
    vectors' size in bytes and bits (+108, +112), the address
    comparison (+116), +120 (a live range was marked for removal), +122
    (a block analyzed), +124 (inform the comparison), +126 (every
    reference related); mmt's cells +0xC0..+0x1A8 (mmt.pvt.pas) reached
    absolutely.

  How the analysis goes (analyze_one_bb): each memory reference of a
  block (an instruction with an inscrutable or well-behaved memory
  operand) and each exposed or final segment of a memory live range gets
  a descriptor; following the operands' links from each write to its
  readers, with the address comparison, the descriptors that may touch
  the same storage are related; descriptors with the same relations are
  merged; each descriptor becomes a token (mmt.pvt.pas) with a live
  range, and the block's MMT_SEQ instructions (whose operands read and
  write the tokens' live ranges) and memory segments are rebuilt.

  Not known from the original: every local and parameter name, the
  module cells' names. }
module mmt_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/mmt.pvt.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  mu_heap_ptr_t = ^mrh_$heap_t;

  { A descriptor (40 bytes; +92's table, by number from 1): one class
    of memory references of the block being analyzed.  lr its live range;
    exposed, final the segments on the block's lists; last the final
    segment of its live range (or the one before the block's first);
    instr the reference; related and compared bit vectors of
    descriptors; equiv the descriptor it is equivalent to; num the live
    range's number while the tokens are bound; flag set for one made from
    a segment. }
  mu_desc_t = record
    lr: lr_ptr_t;                       { +0 }
    exposed: lts_ptr_t;                 { +4 }
    final: lts_ptr_t;                   { +8 }
    last: lts_ptr_t;                    { +12 }
    instr: instr_ptr_t;                 { +16 }
    related: bv_ptr_t;               { +20 }
    l24: integer32;                     { +24 }
    compared: bv_ptr_t;              { +28 }
    equiv: integer;                     { +32 }
    num: integer;                       { +34 }
    f36: packed record                  { +36 }
      flag: boolean;
      b36: 0..127;
      b37: 0..255;
      w38: 0..65535;
      end;
  end;
  mu_descs_t = array [1..100000] of mu_desc_t;
  mu_descs_ptr_t = ^mu_descs_t;

  longs_t = array [1..1000000] of integer32;
  longs_ptr_t = ^longs_t;

var
  mu_seqs: array [0..20] of instr_ptr_t;  { +0 }
  mu_bvs: univ_ptr;                       { +84: the descriptors' bit
                                            vectors }
  mu_mark: integer32;                     { +88: the mark of the MMT_SEQs
                                            walked, the references
                                            followed }
  mu_descs: mu_descs_ptr_t;               { +92 }
  mu_ndescs: integer32;                   { +96: the table's size }
  mu_free_lrs: lr_ptr_t;                  { +100 }
  mu_104: integer32;                      { +104 }
  mu_bv_bytes: integer32;                 { +108: a vector's bytes }
  mu_bv_bits: integer32;                  { +112: its bits }
  mu_compare: mmt_compare_t;              { +116 }
  mu_removal: boolean;                    { +120 }
  mu_122: boolean;                        { +122: a block analyzed
                                            already (analyze_blocks) }
  mu_inform: boolean;                     { +124: tell mu_compare every
                                            related pair }
  mu_all_related: boolean;                { +126: no two references
                                            found disjoint }

{ zero - n bytes from p cleared ((n + 3) div 4 longwords; nothing for
  0).  0x2551FA, 0x16 bytes, no frame (zzzzz's and at_backend's have
  the same code). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
  longs_ptr_t = ^longs_t;
var
  k: integer32;
  q: longs_ptr_t;
begin
  q := p;
  for k := 1 to (n + 3) div 4 do
    q^[k] := 0;
end;

{ mmt_utils_$begin_compilation - nothing.  0x255210, 2 bytes. }

procedure mmt_utils_$begin_compilation;
begin
end;

{ mmt_utils_$init_for_routine - no live ranges kept, none marked, +122
  cleared, no address comparison function (nil, 0), the instruction
  chains cleared (84 bytes from +0).

  0x255212, 0x3C bytes: `move.l #0' and `move.b #0' of the cells. }

procedure mmt_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
  mu_free_lrs := nil;
  mu_122 := false;
  mu_removal := false;
  mmt_utils_$set_address_comparison_function(nil, false);
  zero(addr(mu_seqs), 84);
end;

{ mmt_utils_$end_routine - nothing.  0x25524E, 2 bytes. }

procedure mmt_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ mmt_utils_$end_compilation - nothing.  0x255250, 2 bytes. }

procedure mmt_utils_$end_compilation;
begin
end;

{ mmt_utils_$save_mem_lr - lr kept for reuse (first on +100, chained at
  its +12), no longer in use (+3 bit 3) and without segments.

  0x255252, 0x1A bytes, no frame, no A5 (its callers'). }

procedure mmt_utils_$save_mem_lr(
    lr: lr_ptr_t); options(val_param); internal;
begin
  lr^.next := mu_free_lrs;
  mu_free_lrs := lr;
  lr^.f2.b3_3 := false;
  lr^.ltss := nil;
end;

{ mmt_utils_$save_unneeded_lrs - when a live range was marked for
  removal, the routine's live ranges not in use (+3 bit 3 clear) taken
  off its list (+52, the last at +56) and kept for reuse.

  0x25526C, 0x74 bytes, no A5 (its callers'): the removed one's
  successor stored and tested (`bne' after the `move.l'). }

procedure mmt_utils_$save_unneeded_lrs; internal;
var
  lr, nxt, prev: lr_ptr_t;
begin
  if mu_removal then begin
    mu_removal := false;
    lr := mmt_rtn^.lrs;
    prev := nil;
    while lr <> nil do begin
      nxt := lr^.next;
      if lr^.f2.b3_3 then
        prev := lr
      else begin
        if prev = nil then
          mmt_rtn^.lrs := nxt
        else
          prev^.next := nxt;
        if nxt = nil then
          mmt_rtn^.lrs_last := prev;
        mmt_utils_$save_mem_lr(lr);
      end;
      lr := nxt;
    end;
  end;
end;

{ mmt_utils_$mark_lr_for_removal - lr no longer in use (+3 bit 3),
  without segments; +120 set.  0x2552E0, 0x16 bytes, no frame, no A5. }

procedure mmt_utils_$mark_lr_for_removal(
    lr: lr_ptr_t); options(val_param); internal;
begin
  lr^.f2.b3_3 := false;
  lr^.ltss := nil;
  mu_removal := true;
end;

{ mmt_utils_$get_mem_lr - a live range for memory: a kept one (cleared,
  88 bytes, but its +6, in use, appended to the routine's list) or a
  new one (lir_$new_live_range).

  0x2552F6, 0x6E bytes. }

function mmt_utils_$get_mem_lr: lr_ptr_t;
var
  lr: lr_ptr_t;
  w: integer32;
begin
  if mu_free_lrs <> nil then begin
    lr := mu_free_lrs;
    mu_free_lrs := lr^.next;
    w := lr^.num;
    zero(lr, 88);
    lr^.num := w;
    lr^.f2.b3_3 := true;
    mmt_rtn^.lrs_last^.next := lr;
    mmt_rtn^.lrs_last := lr;
    mmt_utils_$get_mem_lr := lr;
  end
  else
    mmt_utils_$get_mem_lr := lir_$new_live_range;
end;

{ mmt_utils_$lr_is_for_memory - whether lr holds memory: not pinned (+3
  bit 7), neither an integer nor a floating register (rrp 16#C000), and
  its first segment's def (if any) not of the argument block (kind 9).

  0x255364, 0x56 bytes. }

function mmt_utils_$lr_is_for_memory(
    lr: lr_ptr_t): boolean;
begin
  if lr^.f2.b3_7 or ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> []) then
    mmt_utils_$lr_is_for_memory := false
  else if lr^.ltss = nil then
    mmt_utils_$lr_is_for_memory := true
  else if lr^.ltss^.refs = nil then
    mmt_utils_$lr_is_for_memory := true
  else if lr^.ltss^.refs^.h.kind = operand$argument_block_memory then
    mmt_utils_$lr_is_for_memory := false
  else
    mmt_utils_$lr_is_for_memory := true;
end;

{ mmt_utils_$save_mmt_seq_instruction - an MMT_SEQ instruction kept for
  reuse on the chain of its operand count (+4; chain 0 for more than
  20).  0x2553BA, 0x2A bytes, no frame, no A5. }

procedure mmt_utils_$save_mmt_seq_instruction(
    instr: instr_ptr_t); options(val_param); internal;
var
  k: integer32;
begin
  if instr^.h.nopnds > 20 then
    k := 0
  else
    k := instr^.h.nopnds;
  instr^.next := mu_seqs[k];
  mu_seqs[k] := instr;
end;

{ mmt_utils_$get_mmt_seq_instruction - an MMT_SEQ instruction of n
  operands: a kept one of n (n at most 20), else from chain 0 the one
  of exactly n or the smallest above (its predecessor noted at +8 while
  searching, then unlinked), else a new one from lir_main_heap (44 + 12n
  bytes).

  0x2553E4, 0xC4 bytes, no A5 (its callers'): the counts compared
  unsigned (`bls'). }

function mmt_utils_$get_mmt_seq_instruction(
    n: integer32): instr_ptr_t; options(val_param); internal;
var
  i, prev, best: instr_ptr_t;
  c: integer32;
begin
  if n <= 20 then begin
    i := mu_seqs[n];
    if i <> nil then
      mu_seqs[n] := i^.next;
  end
  else begin
    i := mu_seqs[0];
    prev := nil;
    best := nil;
    while i <> nil do begin
      c := i^.h.nopnds;
      if c = n then begin
        i^.prev := prev;
        best := i;
        exit;
      end;
      if c > n then
        if (best = nil) or (best^.h.nopnds > i^.h.nopnds) then begin
          i^.prev := prev;
          best := i;
        end;
      prev := i;
      i := i^.next;
    end;
    if best <> nil then
      if best^.prev = nil then
        mu_seqs[0] := best^.next
      else
        best^.prev^.next := best^.next;
    i := best;
  end;
  if i = nil then
    i := mrh_$alloc(mu_heap_ptr_t(lir_main_heap)^, n * 12 + 44);
  mmt_utils_$get_mmt_seq_instruction := i;
end;

{ add_operand - the next operand (count up, at most instr's nopnds:
  bug_check) of an MMT_SEQ: number the count, rrp byte rrp, live range
  lr (a memory operand holds its live range while the tokens are
  bound), kind 10 (inscrutable memory).

  0x2554A8, 0x66 bytes, no A5: the count a longword by address, its low
  word the index and its low byte the number. }

procedure add_operand(
    instr: instr_ptr_t;
    var count: integer32;
    lr: lr_ptr_t;
    rrp: integer); options(val_param); internal;
begin
  count := count + 1;
  if instr^.h.nopnds < count then
    bug_check('MMT_$add_operand: too many operands%$');
  instr^.opnds[count].h.num := count & 255;
  opnd_bytes_ptr_t(addr(instr^.opnds[count]))^.rrp := rrp & 255;
  instr^.opnds[count].ptr := lr;
  instr^.opnds[count].h.kind := operand$inscrutable_memory;
end;

{ build_mmt_seq_instr - an MMT_SEQ (202) of n operands next to anchor,
  from mmt's heap (+0xCC, made lir_main_heap for the call), +2 bit 5
  set.  0x255534, 0x42 bytes, no A5. }

function build_mmt_seq_instr(
    anchor: instr_ptr_t;
    after: boolean;
    n: integer32): instr_ptr_t; options(val_param); internal;
var
  save: univ_ptr;
  i: instr_ptr_t;
begin
  save := lir_main_heap;
  lir_main_heap := addr(mmt_seq_heap);
  i := lir_$optimizer_new_n_opr_instr(anchor, ord(opc$mmt_seq), after, n);
  lir_main_heap := save;
  i^.h.b2_5 := true;
  build_mmt_seq_instr := i;
end;

{ mmt_utils_$mmt_seq_emit - the active tokens (mmt_active) made the
  operands of an MMT_SEQ put next to anchor (after it when after): a
  token read is an operand that reads (16, or 16#30 with the modify, 4,
  when it is also written), one only written an operand that writes
  (8).  More than 255 operands make a chain of MMT_SEQs: each takes up
  to 254 (the read-only tokens first, then the read and written, then
  the written only), writes a live range (a token written, or
  mmt_connector's) that the next reads first.  The tokens' flags and
  links are cleared and the list emptied; nil when it is empty.

  0x255576, 0x34E bytes: the operand count a register passed through a
  frame longword (add_operand's var); the first add_operand of the pair
  pops 14 of its 16 bytes (docs/rev889-patterns.md 51); the scans
  restart at mmt_active when a kind runs out. }

function mmt_utils_$mmt_seq_emit(
    anchor: instr_ptr_t;
    after: boolean): instr_ptr_t;
var
  n, rw, r, w, k, m: integer32;
  t, nxt: mmt_token_ptr_t;
  i: instr_ptr_t;
  last: lr_ptr_t;
  rb, wb: integer;
begin
  if mmt_active = nil then begin
    mmt_utils_$mmt_seq_emit := nil;
    return;
  end;
  n := 0;
  rw := 0;
  r := 0;
  w := 0;
  t := mmt_active;
  repeat
    if t^.f.read then begin
      if t^.f.written then
        rw := rw + 1
      else
        r := r + 1;
      n := n + 1;
    end;
    if t^.f.written then begin
      if not t^.f.read then
        w := w + 1;
      n := n + 1;
    end;
    t := t^.next;
  until t = nil;
  if (r = 0) and (rw = 0) then
    bug_check('MMT_UTILS_$MMT_SEQ_EMIT:  no inputs%$');
  if n = 0 then
    bug_check('MMT_UTILS_$MMT_SEQ_EMIT:  n_operands = 0%$');
  m := n;
  if m > 255 then
    m := 255;
  i := build_mmt_seq_instr(anchor, after, m);
  k := 0;
  while n + k > 255 do begin
    t := mmt_active;
    last := nil;
    repeat
      nxt := t^.next;
      if r <> 0 then begin
        if t^.f.read and not t^.f.written then begin
          add_operand(i, k, t^.lr, 16);
          t^.f.read := false;
          r := r - 1;
          n := n - 1;
          if r = 0 then
            nxt := mmt_active
          else if k = 254 then
            exit;
        end;
      end
      else if rw <> 0 then begin
        if t^.f.read and t^.f.written then begin
          if rw * 2 > 255 - k then begin
            if k = 254 then
              exit;
            add_operand(i, k, t^.lr, 16);
            n := n - 1;
            w := w + 1;
          end
          else begin
            add_operand(i, k, t^.lr, 16#30);
            add_operand(i, k, t^.lr, 4);
            n := n - 2;
            last := t^.lr;
            t^.f.written := false;
          end;
          t^.f.read := false;
          rw := rw - 1;
          if rw = 0 then
            nxt := mmt_active;
        end;
      end
      else begin
        if w = 0 then
          bug_check('MMT_UTILS_$MMT_SEQ_EMIT:  ran out of tokens%$');
        if t^.f.written and not t^.f.read then begin
          add_operand(i, k, t^.lr, 8);
          last := t^.lr;
          n := n - 1;
          t^.f.written := false;
          w := w - 1;
        end;
      end;
      t := nxt;
    until k >= 254;
    if last = nil then begin
      last := mmt_connector.lr;
      add_operand(i, k, last, 8);
    end;
    m := n + 1;
    if m > 255 then
      m := 255;
    i := build_mmt_seq_instr(i, true, m);
    k := 0;
    add_operand(i, k, last, 16);
  end;
  t := mmt_active;
  repeat
    if t^.f.read then begin
      if t^.f.written then begin
        rb := 16#30;
        wb := 4;
      end
      else begin
        rb := 16;
        wb := 8;
      end;
      add_operand(i, k, t^.lr, rb);
      t^.f.read := false;
    end
    else
      wb := 8;
    if t^.f.written then begin
      add_operand(i, k, t^.lr, wb);
      t^.f.written := false;
    end;
    nxt := t^.next;
    t^.next := nil;
    t := nxt;
  until t = nil;
  mmt_active := nil;
  mmt_utils_$mmt_seq_emit := i;
end;

{ mmt_utils_$mmt_seq_add_token - the token at the end of token's
  equivalences (+48) made active (put on mmt_active unless it is
  already read or written), read and written added to its flags.

  0x255942, 0x98 bytes: `or.b' of the two booleans then `bmi' for the
  bug_check; the flags stored as `smi'/`sne' merged with the old bit. }

procedure mmt_utils_$mmt_seq_add_token(
    token: mmt_token_ptr_t;
    read: boolean;
    written: boolean);
var
  t: mmt_token_ptr_t;
begin
  t := token;
  while t^.equiv <> nil do
    t := t^.equiv;
  if not (read or written) then
    bug_check('MMT_UTILS_$MMT_SEQ_ADD_TOKEN: no action specfied%$');
  if not t^.f.read and not t^.f.written then begin
    t^.next := mmt_active;
    mmt_active := t;
  end;
  t^.f.read := read or t^.f.read;
  t^.f.written := written or t^.f.written;
end;

{ mmt_utils_$mmt_seq_add_tokens_from_instr - the tokens of an MMT_SEQ's
  memory operands (kinds 10, 11; their live range's token) made active
  again, read where the operand reads, written where it writes or
  modifies (rrp byte & 12).

  0x255A0C, 0x84 bytes: the operands from the last (`dbf'); the kinds
  tested as `btst' in 16#C00. }

procedure mmt_utils_$mmt_seq_add_tokens_from_instr(
    instr: instr_ptr_t);
var
  j: integer32;
  t: mmt_token_ptr_t;
begin
  for j := instr^.h.nopnds downto 1 do
    if instr^.opnds[j].h.kind in [operand$inscrutable_memory,
                                  operand$well_behaved_memory] then begin
      t := mmt_lr_v_ptr_t(instr^.opnds[j].ptr)^.token;
      mmt_utils_$mmt_seq_add_token(t, instr^.opnds[j].h.read,
          (opnd_bytes_ptr_t(addr(instr^.opnds[j]))^.rrp & 12) <> 0);
    end;
end;

{ mmt_utils_$mmt_seq_add_tokens_from_bv - the tokens whose numbers bv
  holds made active with read and written; whether there was one.
  0x255A90, 0x74 bytes. }

function mmt_utils_$mmt_seq_add_tokens_from_bv(
    bv: bv_ptr_t;
    read: boolean;
    written: boolean): boolean;
var
  found: boolean;
  k: integer32;
begin
  found := false;
  k := bv_$find_next_val(mmt_rtn, bv, 0);
  while k <> 0 do begin
    found := true;
    mmt_utils_$mmt_seq_add_token(mmt_token_map^[k], read, written);
    k := bv_$find_next_val(mmt_rtn, bv, k);
  end;
  mmt_utils_$mmt_seq_add_tokens_from_bv := found;
end;

{ mmt_utils_$can_combine_mmt_seqs - whether the active tokens can join
  seq: none of bv's tokens written, or read with its live range in live;
  every token seq reads read now and none it does not read written; as
  many tokens read now as seq reads.

  0x255B04, 0x100 bytes: seq's operands from the first; the tokens read
  counted along mmt_active, the result `seq'. }

function mmt_utils_$can_combine_mmt_seqs(
    seq: instr_ptr_t;
    bv: bv_ptr_t;
    live: bv_ptr_t): boolean;
var
  k, c, m, j: integer32;
  t: mmt_token_ptr_t;
begin
  if bv <> nil then begin
    k := bv_$find_next_val(mmt_rtn, bv, 0);
    while k <> 0 do begin
      t := mmt_token_map^[k];
      if t^.f.written then begin
        mmt_utils_$can_combine_mmt_seqs := false;
        return;
      end;
      if bv_$test(live, t^.lr) and t^.f.read then begin
        mmt_utils_$can_combine_mmt_seqs := false;
        return;
      end;
      k := bv_$find_next_val(mmt_rtn, bv, k);
    end;
  end;
  c := 0;
  for j := 1 to seq^.h.nopnds do begin
    t := mmt_lr_v_ptr_t(seq^.opnds[j].ptr)^.token;
    if seq^.opnds[j].h.read then begin
      c := c + 1;
      if not t^.f.read then begin
        mmt_utils_$can_combine_mmt_seqs := false;
        return;
      end;
    end
    else if t^.f.written then begin
      mmt_utils_$can_combine_mmt_seqs := false;
      return;
    end;
  end;
  m := 0;
  t := mmt_active;
  while t <> nil do begin
    if t^.f.read then
      m := m + 1;
    t := t^.next;
  end;
  mmt_utils_$can_combine_mmt_seqs := m = c;
end;

{ get_base_and_index - a load's base and index operands (2 and 1), a
  store's (3 and 2); false for another instruction (base and index not
  set).  0x255C04, 0x64 bytes, no A5. }

function get_base_and_index(
    instr: instr_ptr_t;
    out base: opnd_ptr_t;
    out index: opnd_ptr_t): boolean; options(val_param); internal;
begin
  if instruction_attributes[instr^.opc].class = class$load then begin
    base := addr(instr^.opnds[2]);
    index := addr(instr^.opnds[1]);
    get_base_and_index := true;
  end
  else if instruction_attributes[instr^.opc].class = class$store then begin
    base := addr(instr^.opnds[3]);
    index := addr(instr^.opnds[2]);
    get_base_and_index := true;
  end
  else
    get_base_and_index := false;
end;

{ disp_known - whether a's value is known to differ from b's by a fixed
  amount d: two immediates; two displacements (kinds 19..22) from the
  same base (link); the same register-like value (kinds 12..14, 17) of
  the same count (0); else two values of the same kind (1..11) and count
  whose canonical birthpoints are both exact (their displacements'
  difference) or compare equal once their bases' difference is taken
  out.

  0x255C68, 0x140 bytes, no A5: the kinds' sets as `btst' in 16#780000,
  16#7E, 16#2707E and 16#FFE; the birthpoints (24 bytes each at -48 and
  -24) by utils_$get_canonical_birthpoint with 7, its result dropped,
  the first call popping 10 of 12 bytes (docs/rev889-patterns.md 51);
  the exact flags' bytes `and'-ed. }

function disp_known(
    a: opnd_ptr_t;
    b: opnd_ptr_t;
    out d: integer32): boolean; options(val_param); internal;
var
  k: operand$t;
  bp1, bp2: utils_$birthpoint_t;
begin
  k := a^.h.kind;
  if (k = operand$immediate) and (b^.h.kind = operand$immediate) then begin
    d := a^.value - b^.value;
    disp_known := true;
  end
  else if (k in [operand$displacement_arg_block..operand$displacement_XSB_base])
      and (b^.h.kind in [operand$displacement_arg_block..
                         operand$displacement_XSB_base]) then begin
    if a^.link = b^.link then begin
      d := a^.value - b^.value;
      disp_known := true;
    end
    else
      disp_known := false;
  end
  else if (a^.h.count = b^.h.count) and (a^.ptr = b^.ptr)
      and (b^.h.kind = k)
      and not (k in [operand$ip_reg..operand$fp_reg_pair_physical])
      and (k in [operand$ip_reg..operand$fp_reg_pair_physical,
                 operand$ip_reg_like..operand$fp_reg_pair_like,
                 operand$case_jump_base]) then begin
    d := 0;
    disp_known := true;
  end
  else if (a^.h.count = b^.h.count) and (b^.h.kind = k)
      and (k in [operand$ip_reg..operand$well_behaved_memory]) then begin
    utils_$get_canonical_birthpoint(a^.lts, 7, bp1);
    utils_$get_canonical_birthpoint(b^.lts, 7, bp2);
    if bp1.has_base and bp2.has_base then begin
      d := bp1.base - bp2.base;
      disp_known := true;
    end
    else begin
      d := bp1.offset - bp2.offset;
      bp1.offset := 0;
      bp2.offset := 0;
      disp_known := utils_$compare_birthpoints(bp1, bp2);
    end;
  end
  else
    disp_known := false;
end;

{ mmt_utils_$addr_compare - how the memory references of two loads or
  stores relate: 1 the same instruction, or the same address and size;
  3 disjoint (their alias descriptors, 24 bytes before an instruction
  whose +2 bit 7 is set, unrelated; or the displacement at least the
  lower one's size); 2 overlapping; 4 or 5 the one contains the other
  (by which is lower, or larger); 0 not known (both descriptors from
  phases 3 and 4, not both loads or stores, or the addresses not
  comparable).  The addresses are compared base with base (or a's index
  with b's base when neither modifies its base) and index with index
  (a postmodify's index not added: +3 bits 7..6 1); disp the difference
  (made positive).  The sizes are instruction_attributes' +19 bits 2..0
  (log 2).  report is not read.

  0x255DA8, 0x272 bytes: the sizes compared unsigned (`bcc'), the
  displacement signed. }

function mmt_utils_$addr_compare(
    a: instr_ptr_t;
    b: instr_ptr_t;
    report: boolean;
    out disp: integer32): integer;
var
  da, db: alias_$desc_ptr_t;
  base_a, index_a, base_b, index_b, x: opnd_ptr_t;
  ok: boolean;
  d, e: integer32;
  sa, sb, s1, s2: integer;
  neg: boolean;
begin
  if a = b then begin
    mmt_utils_$addr_compare := 1;
    return;
  end;
  if a^.h.b2_7 and b^.h.b2_7 then begin
    da := alias_$desc_ptr_t(integer32(a) - 24);
    db := alias_$desc_ptr_t(integer32(b) - 24);
    if not alias_$related(da^, db^) then begin
      mmt_utils_$addr_compare := 3;
      return;
    end;
    if da^.phase_34 and db^.phase_34 then begin
      mmt_utils_$addr_compare := 0;
      return;
    end;
  end;
  ok := get_base_and_index(a, base_a, index_a);
  ok := get_base_and_index(b, base_b, index_b) and ok;
  if not ok then begin
    mmt_utils_$addr_compare := 0;
    return;
  end;
  x := index_a;
  if not disp_known(base_a, base_b, d) then begin
    if ((a^.h.width & 16#C0) <> 0) or ((b^.h.width & 16#C0) <> 0) then begin
      mmt_utils_$addr_compare := 0;
      return;
    end;
    x := base_a;
    if not disp_known(index_a, base_b, d) then begin
      mmt_utils_$addr_compare := 0;
      return;
    end;
  end;
  if (a^.h.width & 16#C0) = 16#40 then begin
    if (b^.h.width & 16#C0) = 16#40 then
      e := 0
    else if index_b^.h.kind <> operand$immediate then begin
      mmt_utils_$addr_compare := 0;
      return;
    end
    else
      e := index_b^.value;
  end
  else if (b^.h.width & 16#C0) = 16#40 then begin
    if x^.h.kind <> operand$immediate then begin
      mmt_utils_$addr_compare := 0;
      return;
    end;
    e := -x^.value;
  end
  else if not disp_known(x, index_b, e) then begin
    mmt_utils_$addr_compare := 0;
    return;
  end;
  d := d + e;
  disp := d;
  sa := instruction_attributes[a^.opc].w18 & 7;
  sb := instruction_attributes[b^.opc].w18 & 7;
  if d = 0 then begin
    if sa = sb then
      mmt_utils_$addr_compare := 1
    else if sa < sb then
      mmt_utils_$addr_compare := 5
    else
      mmt_utils_$addr_compare := 4;
    return;
  end;
  if d < 0 then begin
    disp := -disp;
    neg := true;
    s1 := sa;
    s2 := sb;
  end
  else begin
    neg := false;
    s1 := sb;
    s2 := sa;
  end;
  if lshft(1, s1) <= disp then
    mmt_utils_$addr_compare := 3
  else if lshft(1, s1) < lshft(1, s2) + disp then
    mmt_utils_$addr_compare := 2
  else if neg then
    mmt_utils_$addr_compare := 4
  else
    mmt_utils_$addr_compare := 5;
end;

{ mmt_utils_$set_address_comparison_function - mu_compare and mu_inform
  set (nil: addr_compare, not informing).  0x25601A, 0x3A bytes:
  `move.l #0x255DA8'. }

procedure mmt_utils_$set_address_comparison_function(
    f: mmt_compare_t;
    inform: boolean);
begin
  if f = nil then begin
    mu_compare := addr(mmt_utils_$addr_compare);
    mu_inform := false;
  end
  else begin
    mu_compare := f;
    mu_inform := inform;
  end;
end;

{ allocate_descriptor - the descriptor of a memory operand o (its
  instruction's, +16: a JOIN_BP's that of its operand 1's live range
  (+40); a RETURN's that of the final segment of the routine's
  all-memory live range; else a new one for the instruction) or of a
  lifetime segment l (its +36, a new one when 0: an exposed segment
  makes the descriptor its live range's, +40; a final one is noted as
  the descriptor's and its live range's descriptor's last).  Exactly one
  of o and l is given.

  0x256054, 0x1AE bytes, no A5: the descriptors 40 bytes apart from
  +92's table (`(-0x28,A0,D2.l)' with D2 = 40k); the count compared
  signed (`ble'). }

function allocate_descriptor(
    o: opnd_ptr_t;
    l: lts_ptr_t): integer32; options(val_param); internal;
var
  i: instr_ptr_t;
  d, k: integer32;
  lr: lr_ptr_t;
  p: ^mu_desc_t;
begin
  if (o = nil) = (l = nil) then
    bug_check('MMT_UTILS_$allocate_descriptor:  illegal arguments%$');
  if o <> nil then begin
    i := utils_ins_$operands_instruction(o);
    if i^.l16 = 0 then begin
      if i^.opc = ord(opc$join_bp) then
        i^.l16 := i^.opnds[1].lts^.lr^.l40
      else if i^.opc = ord(opc$return) then begin
        lr := mmt_rtn_v_ptr_t(mmt_rtn)^.all_lr;
        for k := 1 to mmt_count do
          if (mu_descs^[k].lr = lr) and (mu_descs^[k].final <> nil) then
            i^.l16 := mu_descs^[k].final^.mark;
      end
      else begin
        mmt_count := mmt_count + 1;
        i^.l16 := mmt_count;
        mu_descs^[i^.l16].instr := i;
      end;
      if i^.l16 = 0 then
        bug_check('MMT_UTILS_$allocate_descriptor: exposed LR must be allocated first%$');
    end;
    d := i^.l16;
  end
  else begin
    d := l^.mark;
    if d = 0 then begin
      mmt_count := mmt_count + 1;
      d := mmt_count;
      l^.mark := d;
    end;
    p := addr(mu_descs^[d]);
    p^.lr := l^.lr;
    if l^.f2.exposed then begin
      p^.exposed := l;
      p^.f36.flag := true;
      if (p^.lr^.l40 <> 0) and (p^.lr^.l40 <> d) then
        bug_check('MMT_UTILS_$allocate_descriptors:  exposed LTS must be allocated before final%$');
      p^.lr^.l40 := d;
    end;
    if l^.f2.final then begin
      p^.final := l;
      p^.last := l;
      p^.f36.flag := true;
      if p^.lr^.l40 = 0 then
        p^.lr^.l40 := d
      else
        mu_descs^[p^.lr^.l40].last := l;
    end;
  end;
  if mmt_count > mu_ndescs then
    bug_check('MMT_UTILS_$allocate_descriptor:  too many descriptors%$');
  allocate_descriptor := d;
end;

{ compared_already - whether descriptors a and b were compared (a in b's
  compared vector: true unless a is b); if not, each noted in the
  other's.  0x256300, 0xA0 bytes, no A5: the bits as sets of 0..31 by
  longword (`lsr.l #5' of the number, `andi #31'). }

function compared_already(
    a: integer32;
    b: integer32): boolean; options(val_param); internal;
var
  ca, cb: bv_ptr_t;
begin
  ca := mu_descs^[a].compared;
  cb := mu_descs^[b].compared;
  if (a & 31) in cb^[rshft(a, 5)] then
    compared_already := a <> b
  else begin
    ca^[rshft(b, 5)] := ca^[rshft(b, 5)] + [b & 31];
    cb^[rshft(a, 5)] := cb^[rshft(a, 5)] + [a & 31];
    compared_already := false;
  end;
end;

{ ids_related - descriptors a and b noted related, each in the other's
  related vector.  0x2563A0, 0x8A bytes, no A5. }

procedure ids_related(
    a: integer32;
    b: integer32); options(val_param); internal;
var
  ra, rb: bv_ptr_t;
begin
  ra := mu_descs^[a].related;
  rb := mu_descs^[b].related;
  ra^[rshft(b, 5)] := ra^[rshft(b, 5)] + [b & 31];
  rb^[rshft(a, 5)] := rb^[rshft(a, 5)] + [a & 31];
end;

{ inform_about_relationships - mu_compare told (report true, its answer
  dropped) of each pair of related references (descriptors with an
  instruction) related to a descriptor made from a segment, each pair
  once; the routine's +192 set to the descriptors' count first.  bb is
  not read.

  0x25642A, 0xEC bytes, no A5: mmt_rtn reached as +8 of mmt's +0xC0
  (`movea.l #0x48C428,A2'; docs/rev889-patterns.md 70). }

procedure inform_about_relationships(
    bb: bb_ptr_t); options(val_param); internal;
var
  d, j, m: integer32;
  rel: bv_ptr_t;
  disp: integer32;
begin
  mmt_rtn^.l192 := mmt_count;
  for d := 1 to mmt_count do
    if mu_descs^[d].f36.flag then begin
      rel := mu_descs^[d].related;
      j := 0;
      repeat
        j := bv_$find_next_val(mmt_rtn, rel, j);
        if j <> 0 then
          if mu_descs^[j].instr <> nil then begin
            m := j;
            repeat
              m := bv_$find_next_val(mmt_rtn, rel, m);
              if m <> 0 then
                if mu_descs^[m].instr <> nil then
                  if not compared_already(j, m) then
                    discard(mu_compare^(mu_descs^[j].instr,
                                        mu_descs^[m].instr, true, disp));
            until m = 0;
          end;
      until j = 0;
    end;
end;

{ mark_related_references - the references reached from o along the
  operands' links noted related to descriptor d: an MMT_SEQ walked once
  for this mark (+16 the mark); another reference's descriptor related
  to d unless compared already (with cmp, only when mu_compare does not
  find them disjoint, 3, which clears mu_all_related); then, through the
  operands of a reference followed that write memory, their final
  segments' descriptors and (recursively) their readers.

  0x256516, 0x120 bytes, no A5: the operands from the first. }

procedure mark_related_references(
    cmp: instr_ptr_t;
    d: integer32;
    o: opnd_ptr_t); options(val_param); internal;
var
  p: opnd_ptr_t;
  i: instr_ptr_t;
  e, j: integer32;
  disp: integer32;
  walk: boolean;
begin
  p := o;
  while p <> nil do begin
    i := utils_ins_$operands_instruction(p);
    walk := false;
    if i^.opc = ord(opc$mmt_seq) then begin
      if mu_mark <> i^.l16 then begin
        i^.l16 := mu_mark;
        walk := true;
      end;
    end
    else begin
      e := allocate_descriptor(p, nil);
      if not compared_already(d, e) then begin
        walk := true;
        if cmp = nil then
          ids_related(d, e)
        else if mu_compare^(cmp, i, false, disp) <> 3 then
          ids_related(d, e)
        else
          mu_all_related := false;
      end;
    end;
    if walk then
      for j := 1 to i^.h.nopnds do
        if (i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                   operand$well_behaved_memory])
            and ((opnd_bytes_ptr_t(addr(i^.opnds[j]))^.rrp & 12) <> 0) then begin
          if (i^.opnds[j].lts^.lr^.l40 <> 0) and i^.opnds[j].lts^.f2.final then
            ids_related(d, i^.opnds[j].lts^.mark);
          mark_related_references(cmp, d, i^.opnds[j].link);
        end;
    p := p^.link;
  end;
end;

{ discover_relationships - which memory references of bb may touch the
  same storage: from each exposed segment of a memory live range with a
  descriptor its readers; from each memory operand that writes (made
  inscrutable memory, kind 10) its readers, with mu_compare; an operand
  that only means to modify a segment its last reader; a read of a live
  range written in the block the reads of its last pure write.  Each
  descriptor is related to itself; mu_inform has mu_compare told.  When
  every reference is related to every other (mu_all_related) nothing
  can be gained: false.  Otherwise the descriptors (made from no segment
  or from a segment not both exposed and final) with the same related
  vector are made equivalent to the first (and their live range's
  descriptor that one), the instructions' descriptors (+16) follow,
  MMT_SEQs' cleared: true.

  0x256636, 0x40A bytes, no A5: the operands from the last; the
  compared vectors cleared with zero (+108 bytes). }

function discover_relationships(
    bb: bb_ptr_t): boolean; options(val_param); internal;
var
  l, f: lts_ptr_t;
  i, ii: instr_ptr_t;
  j, jj, d, e: integer32;
  o, p, r: opnd_ptr_t;
begin
  mu_all_related := true;
  mu_mark := 0;
  l := bb^.exposed;
  while l <> nil do begin
    if l^.lr^.l40 <> 0 then begin
      mu_mark := mu_mark + 1;
      mark_related_references(nil, l^.lr^.l40, l^.refs);
    end;
    l := l^.next_exposed;
  end;
  i := bb^.first;
  while i <> nil do begin
    if i^.opc <> ord(opc$mmt_seq) then
      for j := i^.h.nopnds downto 1 do begin
        o := addr(i^.opnds[j]);
        if o^.h.kind in [operand$inscrutable_memory,
                         operand$well_behaved_memory] then begin
          o^.h.kind := operand$inscrutable_memory;
          l := o^.lts;
          if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
            e := allocate_descriptor(o, nil);
            if (l^.mark <> 0) and o^.lts^.f2.final then
              ids_related(e, l^.mark);
            mu_mark := mu_mark + 1;
            mark_related_references(i, e, o^.link);
          end
          else if rrp$intend_to_modify in l^.rrp then begin
            if not o^.h.intend_to_modify then begin
              p := o;
              while p^.link <> nil do
                p := p^.link;
              if utils_ins_$operands_instruction(p) <> i then begin
                e := allocate_descriptor(o, nil);
                mu_mark := mu_mark + 1;
                mark_related_references(i, e, p);
              end;
            end;
          end
          else if l^.lr^.id <> 0 then begin
            f := nil;
            for d := 1 to mmt_count do
              if (mu_descs^[d].lr = l^.lr)
                  and (mu_descs^[d].final <> nil) then begin
                f := mu_descs^[d].final;
                exit;
              end;
            if f <> nil then
              if f = l then begin
                e := allocate_descriptor(o, nil);
                ids_related(e, l^.mark);
              end
              else begin
                while rrp$modify in f^.rrp do
                  f := f^.next;
                if not (rrp$write in f^.rrp) then
                  bug_check('MMT_UTILS_$discover_relationships: expected pure write%$');
                ii := utils_ins_$operands_instruction(f^.refs);
                r := nil;
                for jj := 1 to ii^.h.nopnds do
                  if ii^.opnds[jj].h.read then
                    r := addr(ii^.opnds[jj]);
                if r = nil then
                  bug_check('MMT_UTILS_$discover_relationships: unprecedented memory write!%$');
                e := allocate_descriptor(o, nil);
                mu_mark := mu_mark + 1;
                mark_related_references(i, e, r);
              end;
          end;
        end;
      end;
    i := i^.next;
  end;
  for d := 1 to mmt_count do
    ids_related(d, d);
  if mu_inform then
    inform_about_relationships(bb);
  if mu_all_related then begin
    discover_relationships := false;
    return;
  end;
  for d := 1 to mmt_count do
    zero(mu_descs^[d].compared, mu_bv_bytes);
  for d := 1 to mmt_count do
    if (mu_descs^[d].equiv = 0)
        and ((mu_descs^[d].exposed = nil) or (mu_descs^[d].final = nil)) then
      for e := d + 1 to mmt_count do
        if mu_descs^[e].equiv = 0 then
          if not mu_descs^[e].f36.flag
              or (mu_descs^[e].lr = mu_descs^[d].lr) then
            if bv_$equal(mu_bv_bits, mu_descs^[d].related,
                         mu_descs^[e].related) then begin
              mu_descs^[e].equiv := d;
              if mu_descs^[e].lr <> nil then
                mu_descs^[e].lr^.l40 := d;
            end;
  i := bb^.first;
  while i <> nil do begin
    if i^.opc = ord(opc$mmt_seq) then
      i^.l16 := 0
    else if i^.l16 <> 0 then
      if mu_descs^[i^.l16].equiv <> 0 then
        i^.l16 := mu_descs^[i^.l16].equiv;
    i := i^.next;
  end;
  discover_relationships := true;
end;

{ free_mmt_seqs_and_ltss - bb's memory live ranges' segments in the
  block that are neither exposed nor final freed (a live range left
  without segments marked for removal and its descriptor's cleared);
  the segments of the live ranges the block's memory operands refer to
  freed (all of them for a live range without a number, those in the
  block for one without a descriptor) and the operands' +8 cleared; the
  unneeded live ranges kept; the block's MMT_SEQs unlinked and kept for
  reuse but those with an argument block operand (before any other
  kind), which lose +2 bit 5.

  0x256AB8, 0x258 bytes, no A5: the operands from the last; the segment
  of the block found first, then those that follow in it. }

procedure free_mmt_seqs_and_ltss(
    bb: bb_ptr_t); options(val_param); internal;
var
  d, j: integer32;
  lr: lr_ptr_t;
  l, nxt, prev: lts_ptr_t;
  i, inxt, iprev: instr_ptr_t;
  k: operand$t;
  keep: boolean;
begin
  for d := 1 to mmt_count do begin
    lr := mu_descs^[d].lr;
    if lr = nil then
      exit;
    l := lr^.ltss;
    if l^.bb = bb then
      prev := nil
    else
      repeat
        prev := l;
        l := l^.next;
      until l^.bb = bb;
    repeat
      nxt := l^.next;
      if l^.f2.exposed then
        exit;
      if not l^.f2.final then begin
        if prev = nil then
          lr^.ltss := nxt
        else
          prev^.next := nxt;
        l^.refs := nil;
        l^.lr := nil;
        lir_$free_lifetime_segment(l);
      end
      else
        prev := l;
      l := nxt;
    until (l = nil) or (l^.bb <> bb);
    if lr^.ltss = nil then begin
      mmt_utils_$mark_lr_for_removal(lr);
      mu_descs^[d].lr := nil;
    end;
  end;
  i := bb^.first;
  while i <> nil do begin
    for j := i^.h.nopnds downto 1 do
      if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                operand$well_behaved_memory] then begin
        l := i^.opnds[j].lts;
        lr := l^.lr;
        if (lr <> nil) and (lr^.ltss <> nil) and (l^.refs <> nil) then begin
          l := lr^.ltss;
          if lr^.id = 0 then begin
            lr^.ltss := nil;
            repeat
              nxt := l^.next;
              l^.refs := nil;
              lir_$free_lifetime_segment(l);
              l := nxt;
            until l = nil;
            mmt_utils_$mark_lr_for_removal(lr);
          end
          else if lr^.l40 = 0 then begin
            prev := nil;
            while (l <> nil) and (l^.bb <> bb) do begin
              prev := l;
              l := l^.next;
            end;
            repeat
              nxt := l^.next;
              l^.refs := nil;
              if prev = nil then
                lr^.ltss := nxt
              else
                prev^.next := nxt;
              lir_$free_lifetime_segment(l);
              l := nxt;
            until (l = nil) or (l^.bb <> bb);
            if lr^.ltss = nil then
              mmt_utils_$mark_lr_for_removal(lr);
          end;
        end;
        i^.opnds[j].lts := nil;
      end;
    i := i^.next;
  end;
  mmt_utils_$save_unneeded_lrs;
  iprev := nil;
  i := bb^.first;
  while i <> nil do begin
    inxt := i^.next;
    if i^.opc = ord(opc$mmt_seq) then begin
      keep := false;
      for j := 1 to i^.h.nopnds do begin
        k := i^.opnds[j].h.kind;
        if k = operand$argument_block_memory then begin
          keep := true;
          exit;
        end;
        if k <> operand$none then
          exit;
      end;
      if keep then begin
        iprev := i;
        i^.h.b2_5 := false;
      end
      else begin
        if iprev = nil then
          bb^.first := inxt
        else
          iprev^.next := inxt;
        if inxt = nil then
          bb^.last := iprev
        else
          inxt^.prev := iprev;
        mmt_utils_$save_mmt_seq_instruction(i);
      end;
    end
    else
      iprev := i;
    i := inxt;
  end;
end;

{ bind_new_tokens_to_operands - a token for each descriptor and one
  more (the last, copied to mmt_connector): its vectors, number and
  equivalent flag the descriptor's, its live range the descriptor's (a
  memory live range for one without), which takes the descriptor's
  number (its own kept in the descriptor) and the token; a descriptor
  whose live range carries another number gets a live range of its own
  (88 bytes from the tokens' heap) and is made equivalent to that
  number's token.  The block's memory operands with a descriptor then
  refer to their token's live range, chained from its +44 through
  their links; the tokens simplified.

  0x256D10, 0x21A bytes, no A5: the tokens made from the last; the copy
  of the last token 15 longwords (`move.l (A1)+,(A2)+' three times by
  `dbf'). }

procedure bind_new_tokens_to_operands(
    bb: bb_ptr_t); options(val_param); internal;
var
  d, j: integer32;
  t: mmt_token_ptr_t;
  p: ^mu_desc_t;
  l: lr_ptr_t;
  i: instr_ptr_t;
begin
  mmt_count := mmt_count + 1;
  if mmt_count > mu_ndescs then
    bug_check('MMT_UTILS_$bind_new_tokens_to_operands:  too many descriptors%$');
  for d := mmt_count downto 1 do begin
    p := addr(mu_descs^[d]);
    t := mrh_$alloc_fixed(mmt_token_heap);
    mmt_token_map^[d] := t;
    t^.related := p^.related;
    t^.compared := p^.compared;
    t^.id := d;
    t^.f.equivalent := p^.equiv <> 0;
    if p^.lr = nil then
      p^.lr := mmt_utils_$get_mem_lr;
    t^.lr := p^.lr;
    p^.num := p^.lr^.id;
    p^.lr^.id := d;
    mmt_lr_v_ptr_t(p^.lr)^.token := t;
    mmt_lr_v_ptr_t(p^.lr)^.uses := nil;
  end;
  mmt_connector := mmt_token_map^[mmt_count]^;
  for d := 1 to mmt_count do
    if mu_descs^[d].lr^.id <> d then begin
      l := mrh_$alloc(mmt_token_heap, 88);
      l^.id := d;
      mmt_lr_v_ptr_t(l)^.token := mmt_token_map^[d];
      mmt_token_map^[d]^.lr := l;
      mmt_token_map^[d]^.equiv := mmt_token_map^[mu_descs^[d].lr^.id];
    end;
  i := bb^.first;
  while i <> nil do begin
    if i^.l16 <> 0 then
      for j := 1 to i^.h.nopnds do
        if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                  operand$well_behaved_memory] then begin
          l := mmt_token_map^[i^.l16]^.lr;
          i^.opnds[j].link := mmt_lr_v_ptr_t(l)^.uses;
          mmt_lr_v_ptr_t(l)^.uses := addr(i^.opnds[j]);
          i^.opnds[j].ptr := l;
        end;
    i := i^.next;
  end;
  mmt_$simplify_tokens_in_bb(bb);
end;

{ insert_mmt_seqs - the MMT_SEQs bb needs: for each descriptor with an
  exposed segment, its live range noted in the compared vectors of the
  tokens it is related to and, unless the segment is also final, in
  mmt_140 (active on exit); the intra-block sequences inserted (mmt);
  the memory operands made to refer to their descriptor's live range;
  a token whose live range is not its descriptor's replaced by the one
  of that live range's number; a live range both exposed and final taken
  out of mmt_140.  Then for each descriptor with a final segment and no
  exposed one (until one without a live range) an MMT_SEQ at the block's
  end (before its branches): the related tokens it compared with read,
  those active on exit read and written, its own token written; one
  that would only write its own token is dropped; when it can join the
  previous one the two are combined.

  0x256F6A, 0x35C bytes, no A5: the branch classes as `btst' in
  16#1000062 (branch, fp_branch, jump, return); bv_$subtract's result
  dropped. }

procedure insert_mmt_seqs(
    bb: bb_ptr_t); options(val_param); internal;
var
  d, e, j: integer32;
  p: ^mu_desc_t;
  i, seq: instr_ptr_t;
  lr: lr_ptr_t;
  t: mmt_token_ptr_t;
  after: boolean;
  bv: bv_ptr_t;
begin
  for d := 1 to mmt_count do begin
    p := addr(mu_descs^[d]);
    if p^.exposed <> nil then begin
      for e := 1 to mmt_count do
        if d <> e then
          if bv_$test(p^.related, mmt_token_map^[e]^.lr) then
            bv_$set(mu_descs^[e].compared, p^.lr);
      if p^.exposed <> p^.final then
        bv_$set(mmt_140, p^.lr);
    end;
  end;
  mmt_$insert_blocks_intra_bb_seq(bb);
  i := bb^.first;
  while i <> nil do begin
    for j := 1 to i^.h.nopnds do
      if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                operand$well_behaved_memory] then begin
        lr := i^.opnds[j].ptr;
        i^.opnds[j].ptr := mu_descs^[lr^.id].lr;
      end;
    i := i^.next;
  end;
  for d := 1 to mmt_count do begin
    t := mmt_token_map^[d];
    lr := t^.lr;
    if mu_descs^[d].lr <> lr then
      mmt_token_map^[d] := mmt_token_map^[mu_descs^[d].lr^.id]
    else if mu_descs^[d].exposed <> nil then
      if mu_descs^[d].exposed = mu_descs^[d].final then
        bv_$clear(mmt_140, mu_descs^[d].lr);
  end;
  i := bb^.last;
  while i <> nil do begin
    if not (instruction_attributes[i^.opc].class in
            [class$branch, class$fp_branch, class$jump, class$return]) then
      exit;
    i := i^.prev;
  end;
  if i <> nil then
    after := true
  else begin
    i := bb^.first;
    after := false;
  end;
  seq := nil;
  bv := mmt_scratch;
  for d := 1 to mmt_count do begin
    p := addr(mu_descs^[d]);
    if p^.lr = nil then
      exit;
    if (p^.final <> nil) and (p^.exposed = nil) then begin
      bv_$and_to(mu_bv_bits, p^.related, p^.compared, bv);
      discard(mmt_utils_$mmt_seq_add_tokens_from_bv(bv, true, false));
      bv_$and_to(mu_bv_bits, mmt_140, p^.related, bv);
      discard(mmt_utils_$mmt_seq_add_tokens_from_bv(bv, true, true));
      mmt_utils_$mmt_seq_add_token(mmt_token_map^[p^.lr^.l40], false, true);
      if mmt_active^.next = nil then begin
        mmt_active^.f.read := false;
        mmt_active^.f.written := false;
        mmt_active := nil;
      end
      else begin
        if seq <> nil then
          if mmt_utils_$can_combine_mmt_seqs(seq, nil, nil) then begin
            mmt_utils_$mmt_seq_add_tokens_from_instr(seq);
            i := mmt_utils_$mmt_seq_emit(seq, true);
            discard(lir_utils_$excise_inst(seq));
            seq := i;
          end
          else begin
            i := mmt_utils_$mmt_seq_emit(i, after);
            seq := i;
          end
        else begin
          i := mmt_utils_$mmt_seq_emit(i, after);
          seq := i;
        end;
        after := true;
        bv_$subtract(mu_bv_bits, bv, mmt_140);
      end;
    end;
  end;
end;

{ fill_in_ltss - lifetime segments for the block's memory references
  again: each MMT_SEQ made in mmt's temporary heap (+2 bit 5) copied
  into a lasting one (get_mmt_seq_instruction) in its place; each
  descriptor's last segment before the block found; then for each memory
  operand a segment of its live range: a read the segment being filled
  in (+52; the first the descriptor's exposed one), its readers chained
  from the segment's +40; a write a new segment after the descriptor's
  last (or first of the live range); the operand's rrp bits (& 60)
  added to the segment's and the live range's.  A live range whose final
  segment is not the one written last in the block has the two merged;
  the live ranges get their numbers back; those left without segments
  removed; a live range that is not exposed in the block is split after
  each write that is not final.

  0x2572C6, 0x46E bytes, no A5: the instruction copied as (12n + 44) div
  4 longwords; the rrp bits `or.w' into the segment's and live range's
  first words. }

procedure fill_in_ltss(
    bb: bb_ptr_t); options(val_param); internal;
var
  i, c: instr_ptr_t;
  n, k, d, j: integer32;
  src, dst: longs_ptr_t;
  l, prev, s: lts_ptr_t;
  lr, nlr: lr_ptr_t;
  o, q: opnd_ptr_t;
  done: boolean;
begin
  i := bb^.first;
  while i <> nil do begin
    if (i^.opc = ord(opc$mmt_seq)) and i^.h.b2_5 then begin
      n := i^.h.nopnds;
      c := mmt_utils_$get_mmt_seq_instruction(n);
      src := longs_ptr_t(i);
      dst := longs_ptr_t(c);
      for k := 1 to (n * 12 + 44) div 4 do
        dst^[k] := src^[k];
      if i^.prev = nil then
        bb^.first := c
      else
        i^.prev^.next := c;
      if i^.next = nil then
        bb^.last := c
      else
        i^.next^.prev := c;
      c^.h.b2_5 := false;
    end;
    i := i^.next;
  end;
  for d := 1 to mmt_count do begin
    mmt_lr_v_ptr_t(mu_descs^[d].lr)^.cur := nil;
    if (mu_descs^[d].last = nil) and (mu_descs^[d].exposed <> nil)
        and (mu_descs^[d].final = nil) then begin
      l := mu_descs^[d].lr^.ltss;
      if l <> nil then
        if l^.bb <> bb then begin
          while l^.next^.bb <> bb do
            l := l^.next;
          mu_descs^[d].last := l;
        end;
    end;
  end;
  i := bb^.first;
  while i <> nil do begin
    for j := 1 to i^.h.nopnds do begin
      o := addr(i^.opnds[j]);
      if o^.h.kind in [operand$inscrutable_memory,
                       operand$well_behaved_memory] then begin
        lr := o^.ptr;
        if o^.h.read then begin
          if mmt_lr_v_ptr_t(lr)^.cur <> nil then begin
            l := mmt_lr_v_ptr_t(lr)^.cur;
            opnd_ptr_t(l^.l40)^.link := o;
            o^.lts := l;
          end
          else begin
            l := mu_descs^[lr^.id].exposed;
            if l = nil then
              bug_check('MMT_UTILS_$fill_in_ltss: LTS shouldn''t be exposed%$');
            mmt_lr_v_ptr_t(lr)^.cur := l;
            l^.refs := o;
            o^.lts := l;
          end;
        end
        else begin
          if mmt_lr_v_ptr_t(lr)^.cur <> nil then
            mmt_lr_v_ptr_t(lr)^.cur^.l40 := 0;
          l := mu_descs^[lr^.id].last;
          if l = nil then
            lir_utils_$add_lts_to_lr(0, lr, bb, l)
          else
            l := lir_utils_$add_lts_after_lts(l, 0, bb);
          o^.lts := l;
          l^.refs := o;
          mmt_lr_v_ptr_t(lr)^.cur := l;
        end;
        o^.link := nil;
        o^.lts^.l40 := integer32(o);
        o^.lts^.rrp := rrp$set_t(integer(o^.lts^.rrp)
                                 ! (opnd_bytes_ptr_t(o)^.rrp & 60));
        o^.lts^.lr^.rrp := rrp$set_t(integer(o^.lts^.lr^.rrp)
                                     ! (opnd_bytes_ptr_t(o)^.rrp & 60));
      end;
    end;
    i := i^.next;
  end;
  for d := 1 to mmt_count do begin
    lr := mu_descs^[d].lr;
    if lr = nil then
      exit;
    l := mu_descs^[d].final;
    if (l <> mmt_lr_v_ptr_t(lr)^.cur) and (l <> nil)
        and (mmt_lr_v_ptr_t(lr)^.cur <> nil) then begin
      if (integer(mmt_lr_v_ptr_t(lr)^.cur^.rrp) & 12) = 0 then
        bug_check('MMT_UTILS_$fill_in_ltss: this active on exit LTS must be written locally%$');
      if l^.next <> mmt_lr_v_ptr_t(lr)^.cur then
        bug_check('MMT_UTILS_$fill_in_ltss: LTS list out of order%$');
      if mu_descs^[d].exposed = l then
        bug_check('MMT_UTILS_$fill_in_ltss: LR %3ZWD may not be written in BB#%3ZWD%$',
                  l^.lr^.num, bb^.num);
      q := l^.next^.refs;
      while q <> nil do begin
        q^.lts := l;
        q := q^.link;
      end;
      s := l^.next;
      l^.refs := s^.refs;
      l^.rrp := s^.rrp;
      l^.next := s^.next;
      lir_$free_lifetime_segment(s);
    end;
  end;
  for d := 1 to mmt_count do begin
    lr := mu_descs^[d].lr;
    lr^.id := mu_descs^[d].num;
    if mmt_lr_v_ptr_t(lr)^.cur <> nil then
      mmt_lr_v_ptr_t(lr)^.cur^.l40 := 0
    else if (lr^.ltss = nil) and lr^.f2.b3_3 then
      mmt_utils_$mark_lr_for_removal(lr);
  end;
  mmt_utils_$save_unneeded_lrs;
  for d := 1 to mmt_count do
    if mu_descs^[d].exposed = nil then begin
      if mu_descs^[d].final <> nil then
        l := mu_descs^[d].final
      else
        l := mu_descs^[d].lr^.ltss;
      if l <> nil then begin
        while rrp$modify in l^.rrp do
          l := l^.next;
        done := false;
        while not done and (l^.next <> nil) do begin
          if l^.next^.bb <> bb then
            exit;
          prev := l;
          l := l^.next;
          while rrp$modify in l^.rrp do
            l := l^.next;
          if l^.f2.exposed then
            done := true
          else begin
            nlr := mmt_utils_$get_mem_lr;
            nlr^.ltss := prev^.next;
            prev^.next := l^.next;
            l^.next := nil;
            s := nlr^.ltss;
            while s <> nil do begin
              s^.lr := nlr;
              s := s^.next;
            end;
          end;
        end;
      end;
    end;
end;

{ count_and_bind_complex_lrs - how many of bb's exposed and final
  segments (+62 chained at +16, +66 at +20) are of memory live ranges;
  with bind, a descriptor for each.  0x257824, 0x7A bytes, no A5. }

function count_and_bind_complex_lrs(
    bb: bb_ptr_t;
    bind: boolean): integer32; options(val_param); internal;
var
  c: integer32;
  l: lts_ptr_t;
begin
  c := 0;
  l := bb^.exposed;
  while l <> nil do begin
    if mmt_utils_$lr_is_for_memory(l^.lr) then begin
      c := c + 1;
      if bind then
        discard(allocate_descriptor(nil, l));
    end;
    l := l^.next_exposed;
  end;
  l := bb^.finals;
  while l <> nil do begin
    if mmt_utils_$lr_is_for_memory(l^.lr) then begin
      c := c + 1;
      if bind then
        discard(allocate_descriptor(nil, l));
    end;
    l := l^.next_final;
  end;
  count_and_bind_complex_lrs := c;
end;

{ mmt_utils_$analyze_one_bb - bb's memory references bound to MMT_SEQ
  tokens.  On the routine's first block its live ranges are made in use
  (+3 bit 3) without a descriptor (+40), kind 28 made 27 (+8), and the
  memory ones without segments kept for reuse (their segments' +36
  cleared).  A block with fewer than two instructions referring to
  memory only has their memory operands made inscrutable.  Otherwise
  the descriptors (one for each such instruction and memory segment,
  and one more) and their bit vectors are allocated, the segments bound,
  the relationships discovered and, when something can be gained, the
  MMT_SEQs and segments rebuilt; then the marks cleared and the heaps
  released.  The routine's +192 holds the descriptors' count while
  discovering.

  0x25789E, 0x3CE bytes: the live range before the one removed is a
  register (D2) not set before the loop (docs/rev889-patterns.md 84:
  prev here); the vectors' bytes (n + 32) div 32 * 4; their storage
  2 * bytes * n (M$MIS$LLL). }

procedure mmt_utils_$analyze_one_bb(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    level: integer32);
var
  lr, nxt, prev: lr_ptr_t;
  l: lts_ptr_t;
  i, last: instr_ptr_t;
  n, c, j, d, size, saved: integer32;
  p: integer32;
  ok: boolean;
  st: status_$t;
begin
  mmt_rtn := rtn;
  mmt_level := level;
  if lir_main_c86 <> 0 then
    bug_check('MMT_UTILS_$ANALYZE_ONE_BB:  can''t cope%$');
  if not mu_122 then begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      nxt := lr^.next;
      lr^.l40 := 0;
      lr^.f2.b3_3 := true;
      if mmt_lr_v_ptr_t(lr)^.f8.kind = 28 then
        mmt_lr_v_ptr_t(lr)^.f8.kind := 27;
      if not lr^.f2.b3_7 and ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) = []) then begin
        l := lr^.ltss;
        if l <> nil then begin
          repeat
            l^.mark := 0;
            l := l^.next;
          until l = nil;
          prev := lr;
        end
        else begin
          if prev = nil then
            rtn^.lrs := nxt
          else
            prev^.next := nxt;
          if nxt = nil then
            rtn^.lrs_last := prev;
          mmt_utils_$save_mem_lr(lr);
        end;
      end
      else
        prev := lr;
      lr := nxt;
    end;
  end;
  n := 0;
  last := nil;
  i := bb^.first;
  while i <> nil do begin
    i^.l16 := 0;
    if i^.opc <> ord(opc$mmt_seq) then
      for j := i^.h.nopnds downto 1 do
        if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                  operand$well_behaved_memory] then begin
          n := n + 1;
          last := i;
          exit;
        end;
    i := i^.next;
  end;
  if n <= 1 then begin
    if last <> nil then
      for j := 1 to last^.h.nopnds do
        if last^.opnds[j].h.kind in [operand$inscrutable_memory,
                                     operand$well_behaved_memory] then
          last^.opnds[j].h.kind := operand$inscrutable_memory;
    return;
  end;
  c := count_and_bind_complex_lrs(bb, false);
  mu_ndescs := n + c + 1;
  mu_descs := rws_$alloc_heap(mu_ndescs * 40 + mu_ndescs * 4);
  mmt_token_map := univ_ptr(integer32(mu_descs) + mu_ndescs * 40);
  mu_bv_bytes := ((mu_ndescs + 32) div 32) * 4;
  mu_bv_bits := mu_bv_bytes * 8;
  size := mu_bv_bytes * 2 * mu_ndescs;
  mu_bvs := rws_$alloc_heap(size);
  if (mu_descs = nil) or (mu_bvs = nil) then
    bug_check('MMT_UTILS_$ANALYZE_ONE_BB: disk full?%$');
  zero(mu_descs, mu_ndescs * 40);
  zero(mu_bvs, size);
  p := integer32(mu_bvs);
  for d := 1 to mu_ndescs do begin
    mu_descs^[d].related := bv_ptr_t(p);
    p := p + mu_bv_bytes;
    mu_descs^[d].compared := bv_ptr_t(p);
    p := p + mu_bv_bytes;
  end;
  mmt_$allocate_scratch_vectors(mu_bv_bytes);
  mmt_count := 0;
  if count_and_bind_complex_lrs(bb, true) <> c then
    bug_check('MMT_UTILS_$ANALYZE_ONE_BB:  LTS count changed%$');
  saved := mmt_rtn^.l192;
  ok := discover_relationships(bb);
  mmt_rtn^.l192 := mmt_count;
  if ok then begin
    free_mmt_seqs_and_ltss(bb);
    bind_new_tokens_to_operands(bb);
    insert_mmt_seqs(bb);
    fill_in_ltss(bb);
  end;
  for d := 1 to mmt_count do begin
    lr := mu_descs^[d].lr;
    if lr <> nil then
      if lr^.l40 <> 0 then begin
        lr^.l40 := 0;
        l := lr^.ltss;
        while l <> nil do begin
          l^.mark := 0;
          l := l^.next;
        end;
      end;
  end;
  i := bb^.first;
  while i <> nil do begin
    i^.l16 := 0;
    i := i^.next;
  end;
  mmt_rtn^.l192 := saved;
  mrh_$release_all(mmt_token_heap);
  mrh_$release_all(mmt_seq_heap);
  rws_$release_heap(mu_descs, st);
  rws_$release_heap(mu_bvs, st);
  rws_$release_heap(mmt_scratch, st);
end;

{ mmt_utils_$analyze_blocks - analyze_one_bb for each block of rtn in
  code order (+76, +118), the lifetime segments' hint pointers set up
  first unless lir_main_c8d is set (its value restored after).
  0x257CEC, 0x74 bytes. }

procedure mmt_utils_$analyze_blocks(
    rtn: rtn_ptr_t;
    level: integer32);
var
  saved: boolean;
  bb: bb_ptr_t;
begin
  mmt_rtn := rtn;
  mmt_level := level;
  saved := lir_main_c8d;
  if not saved then
    utils_$initialize_lts_hint_pointers(rtn);
  bb := rtn^.bbs;
  while bb <> nil do begin
    mmt_utils_$analyze_one_bb(rtn, bb, level);
    mu_122 := true;
    bb := bb^.next;
  end;
  mu_122 := false;
  lir_main_c8d := saved;
end;
