{ mmt - the memory model (MMT) phase: each memory reference of the
  routine is given a token (a live range standing for the memory it may
  touch: one for each alias descriptor met, one for each kind of call,
  and four of the routine's own), the tokens that may overlap are
  related (bit vectors over the tokens' live ranges), and MMT_SEQ
  instructions are inserted where memory written in one place must not
  be reordered with memory read or written in another, within a block
  and across blocks; finally the memory operands get lifetime
  segments, and the live ranges whose references are all of one
  well-behaved descriptor are marked well-behaved.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x251DC8  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x251DEA  zero (internal)
    --------  0x251E00  dump_related_vectors (internal)
    --------  0x2521DC  dump_bb_bit_vectors (internal)
    --------  0x25233C  allocate_initialize (internal)
    --------  0x252438  record_routines_memory_usage (internal)
    --------  0x252544  mmt_$simplify_tokens_in_bb
    --------  0x252738  consider_merging_token (internal)
    --------  0x252788  remove_duplicate_tokens (internal)
    --------  0x252900  remove_waste (internal)
    --------  0x25293C  compute_exposure_in_asynchronous_path (internal)
    --------  0x252AB6  insert_equiv_in_main_list (internal)
    --------  0x252B3E  classes_related (internal)
    --------  0x252BB4  classes_related_if_uplevel_or_ref (internal)
    --------  0x252C28  classes_related_if_async (internal)
    --------  0x252CA4  build_related (internal)
    --------  0x253236  get_token_for_call (internal)
    --------  0x25335A  get_hashed_token (internal)
    --------  0x2534E6  get_token (internal)
    --------  0x2535C8  enter_token (in fill_in_token_id_map)
    --------  0x2535EC  enter_equiv_token (in fill_in_token_id_map)
    --------  0x25361E  fill_in_token_id_map (internal)
    --------  0x25372A  get_single_alias_for_lr (internal)
    --------  0x25388C  mmt_seq_is_not_arg_blk_seq (internal)
    --------  0x2538EC  mmt_$allocate_scratch_vectors
    --------  0x253962  mmt_$allocate_tokens (internal)
    --------  0x253DA8  mmt_$insert_blocks_intra_bb_seq
    --------  0x254148  mmt_$insert_intra_bb_seq (internal)
    --------  0x2541F6  remove_existing_relationship (internal)
    --------  0x25430A  update_active_tokens (internal)
    --------  0x254366  mmt_$insert_inter_bb_seq (internal)
    --------  0x254ADC  get_new_lts (internal)
    --------  0x254B54  build_real_mmt_seq (internal)
    --------  0x254BF6  mmt_$allocate_ltss_to_refs (internal)
    --------  0x254DC4  mmt_$points_for_good_behavior (internal)
    --------  0x254F18  mmt_$begin_compilation
    --------  0x254FFC  mmt_$process_routine
    --------  0x2551D4  mmt_$end_routine
    --------  0x2551D6  mmt_$end_compilation
    A5 0x48C368: the module's data (0x1DC bytes): three static tokens
    (+0 mentioned in an asynchronous path, +64 all memory but the
    local, +128 generic memory), the cells mmt.pvt.pas declares
    (+0xC0..+0xE8, +0x100 the fourth static token, +0x140, +0x1A8), the
    statistics (+328..+372: six counters for the routine and their
    totals), the alias classes unrelated to class 12 or 13 (+376), the
    scratch bit vectors (+380..+392), their size in bits and bytes
    (+396, +400), the segments kept for reuse (+404), the routine's
    memory live range (+408), the tokens' hash table and class lists
    (+412, +416), the calls' tokens (+420), two strings for the dumps
    (+432) and two not referenced (+456).  The routines named mmt_$
    that do not load A5 (allocate_tokens, insert_intra_bb_seq, ...)
    are internal.

  Not known from the original: every local and parameter name, the
  module cells' names. }
module mmt;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/mmt.pvt.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { The tokens' hash table (256 chains through +0) and, after it, the
    alias classes' lists (17, through +4): 1092 bytes from the heap. }
  mmt_hash_t = array [0..255] of mmt_token_ptr_t;
  mmt_hash_ptr_t = ^mmt_hash_t;
  mmt_lists_t = array [0..16] of mmt_token_ptr_t;
  mmt_lists_ptr_t = ^mmt_lists_t;

  { What a call instruction points to (the longword after its operands'
    slots, +56 + 12 nopnds): the call's properties as the memory model
    reads them (call_conv's record; TODO(pascal) call_conv.ins.pas):
    +31 the callee may run asynchronously, +33 it reads no memory, +34
    it writes none, +35/+36 neither class 16 read/written, +37 it only
    touches what is passed, +38 not class 1, +39 not the static
    classes, +40 not the dynamic ones. }
  mmt_call_info_ptr_t = ^mmt_call_info_t;
  mmt_call_info_t = record
    space0: array [0..30] of char;
    async: boolean;                     { +31 }
    b32: boolean;
    no_reads: boolean;                  { +33 }
    no_writes: boolean;                 { +34 }
    no_reads_16: boolean;               { +35 }
    no_writes_16: boolean;              { +36 }
    own_only: boolean;                  { +37 }
    no_class_1: boolean;                { +38 }
    no_static: boolean;                 { +39 }
    no_dynamic: boolean;                { +40 }
  end;
  mmt_call_info_ptr_ptr_t = ^mmt_call_info_ptr_t;

  { An alias descriptor in a 24-byte frame area (get_single_alias_for_lr
    clears 24 bytes). }
  mmt_desc24_t = record
    d: alias_$desc_t;
    l20: integer32;
  end;

  mmt_name_t = array [1..20] of char;

const
  { The alias classes of dynamic storage (7..10, 15: 16#8780) and of
    statics and externals (2..6, 14: 16#407C). }
  mmt_dynamic_classes = [7..10, 15];
  mmt_static_classes = [2..6, 14];

define
  mmt_count,
  mmt_level,
  mmt_rtn,
  mmt_seq_heap,
  mmt_active,
  mmt_scratch,
  mmt_token_heap,
  mmt_connector,
  mmt_140,
  mmt_token_map;

var
  mmt_async: mmt_token_slot_t;          { +0: mentioned in an
                                          asynchronous path (id 3) }
  mmt_all: mmt_token_slot_t;            { +64: all but local (id 2) }
  mmt_generic: mmt_token_slot_t;        { +128: generic memory (id 1) }
  mmt_stats: array [0..11] of integer32;   { +328: (total, this
                                          routine's) pairs: 0/1 operands
                                          given segments, 2/3 memory
                                          operands, 4/5 MMT_SEQ operands,
                                          6/7 new segments, 8/9 tokens,
                                          10/11 MMT_SEQs }
  mmt_unrelated: mmt_classes_t;         { +376: classes not related to
                                          class 12 or 13 }
  mmt_380: bv_ptr_t;                    { +380 }
  mmt_384: bv_ptr_t;                    { +384 }
  mmt_388: bv_ptr_t;                    { +388 }
  mmt_392: bv_ptr_t;                    { +392 }
  mmt_bits: linteger;                   { +396 }
  mmt_bytes: integer32;                 { +400 }
  mmt_free_ltss: lts_ptr_t;             { +404 }
  mmt_mem_lr: lr_ptr_t;                 { +408 }
  mmt_hash: mmt_hash_ptr_t;             { +412 }
  mmt_lists: mmt_lists_ptr_t;           { +416 }
  mmt_calls: mmt_token_ptr_t;           { +420 }
  mmt_index_str: array [boolean] of packed array [1..9] of char := [
    '         ', ', indexed'];          { +432 }
  mmt_touched_str: array [boolean] of packed array [1..9] of char := [
    'touched  ', 'untouched'];          { +456 (not referenced) }

  { alias.pas's class names (its +0, A5 0x2E8DFC; docs/questions.md). }
  class_names: extern array [0..16] of mmt_name_t;

{ zero - n bytes from p cleared ((n + 3) div 4 longwords).  0x251DEA,
  0x16 bytes, no frame (mmt_utils' and zzzzz's have the same code). }

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

{ dump_related_vectors - title, then for each token a line (its number
  and name: the static tokens' fixed names, a call's, or its descriptor's
  base, class and symbol; its live range's number and, for one made from
  a descriptor, the displacement and size) followed by its related
  (which 0) or compared (1) vector.

  0x251E00, 0x2BC bytes, no A5: the names built in a 128-byte frame
  buffer, the line in another; the tab column at least 45. }

procedure dump_related_vectors(
    in title: univ vfmt_$string_t;
    which: integer); options(val_param); internal;
var
  name: array [1..128] of char;
  line1: prtobj_$line_t;
  line2: prtobj_$line_t;
  out: array [1..128] of char;
  len, outlen, tab: integer;
  k, kk, l1, l2: integer32;
  t: mmt_token_ptr_t;
  v: bv_ptr_t;
begin
  vfmt_$write(title);
  dmp_$complex_lr_bit_vector_header(mmt_rtn);
  for k := 1 to mmt_count do begin
    t := mmt_token_map^[k];
    if k = 1 then begin
      name := '001: [ Generic memory            ]';
      len := 34;
    end
    else if k = 2 then begin
      name := '002: [ All but local             ]';
      len := 34;
    end
    else if k = 3 then begin
      name := '003: [ Mentioned in async path   ]';
      len := 34;
    end
    else if k = 4 then begin
      name := '004: [ MMT_SEQ connector         ]';
      len := 34;
    end
    else if t^.f.call then begin
      kk := k;
      vfmt_$encode('%3ZLD: %A%$', name, 128, len, kk,
                   '[ token for a CALL ]', 20);
    end
    else begin
      line1.length := 0;
      if t^.desc.base <> nil then
        prtobj(line1, t^.desc.base);
      if t^.desc.sym <> nil then begin
        line2.length := 0;
        prtobj(line2, t^.desc.sym);
        kk := k;
        l2 := line2.length;
        l1 := line1.length;
        vfmt_$encode('%3ZLD: %A (%M20A) (sym = %A)%$', name, 128, len, kk,
                     line1.body, l1, class_names[t^.desc.class],
                     line2.body, l2);
      end
      else begin
        kk := k;
        l1 := line1.length;
        vfmt_$encode('%3ZLD: %A (%M20A)%$', name, 128, len, kk,
                     line1.body, l1, class_names[t^.desc.class]);
      end;
    end;
    if len > 45 then
      tab := len
    else
      tab := 45;
    if t^.f.from_alias then
      vfmt_$encode('%A%T  LR %3ZWD  (disp = %LD, size = %LD%M9A)%$', out,
                   128, outlen, name, len, tab, t^.lr^.num, t^.desc.disp,
                   t^.desc.size, mmt_index_str[t^.desc.inexact])
    else
      vfmt_$encode('%A%T  LR %3ZWD%$', out, 128, outlen, name, len, tab,
                   t^.lr^.num);
    if which = 0 then
      v := t^.related
    else if which = 1 then
      v := t^.compared;
    dmp_$complex_lr_bit_vector(mmt_rtn, out, outlen, v);
  end;
end;

{ dump_bb_bit_vectors - each block's number and its seven vectors as the
  inter-block analysis uses them.  0x2521DC, 0xFC bytes, no A5. }

procedure dump_bb_bit_vectors(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
begin
  bb := mmt_rtn^.bbs;
  while bb <> nil do begin
    vfmt_$write('%/BB#%3ZWD%.', bb^.num);
    dmp_$complex_lr_bit_vector_header(rtn);
    dmp_$complex_lr_bit_vector(rtn, 'EXPOSED_USE', 11, bb^.live_gen);
    dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_ENTRY', 13, bb^.live_in);
    dmp_$complex_lr_bit_vector(rtn, 'NOT_KILLED', 10, bb^.transparent);
    dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_EXIT', 12, bb^.live_out);
    dmp_$complex_lr_bit_vector(rtn, 'GEN_LOCAL', 9, bb^.avail_gen);
    dmp_$complex_lr_bit_vector(rtn, 'AVAIL_ON_ENTRY', 14, bb^.avail_in);
    dmp_$complex_lr_bit_vector(rtn, 'AVAIL_ON_EXIT', 13, bb^.avail_out);
    bb := bb^.next;
  end;
  vfmt_$write('%.');
end;

{ allocate_initialize - the hash table and class lists (1092 bytes)
  allocated and cleared, the calls' list emptied; the static tokens
  cleared (64 bytes each) and given live ranges: generic memory the
  routine's memory live range (+140), all but local a new one (the
  routine's +144), the asynchronous one and the MMT_SEQ connector new
  ones; four tokens.

  0x25233C, 0xFC bytes, no A5. }

procedure allocate_initialize; internal;
var
  size: integer32;
begin
  size := 1092;
  mmt_hash := rws_$alloc_heap(size);
  mmt_calls := nil;
  mmt_lists := univ_ptr(integer32(mmt_hash) + 1024);
  zero(mmt_hash, size);
  zero(addr(mmt_generic), 64);
  mmt_generic.t.lr := mmt_rtn_v_ptr_t(mmt_rtn)^.mem_lr;
  mmt_lr_v_ptr_t(mmt_rtn_v_ptr_t(mmt_rtn)^.mem_lr)^.token := addr(mmt_generic.t);
  zero(addr(mmt_all), 64);
  mmt_all.t.lr := lir_$new_live_range;
  mmt_rtn_v_ptr_t(mmt_rtn)^.all_lr := mmt_all.t.lr;
  mmt_lr_v_ptr_t(mmt_all.t.lr)^.token := addr(mmt_all.t);
  mmt_stats[9] := mmt_stats[9] + 1;
  zero(addr(mmt_async), 64);
  mmt_async.t.lr := lir_$new_live_range;
  mmt_lr_v_ptr_t(mmt_async.t.lr)^.token := addr(mmt_async.t);
  mmt_async.t.f.async := true;
  mmt_stats[9] := mmt_stats[9] + 1;
  zero(addr(mmt_connector), 64);
  mmt_connector.t.lr := lir_$new_live_range;
  mmt_lr_v_ptr_t(mmt_connector.t.lr)^.token := addr(mmt_connector.t);
  mmt_stats[9] := mmt_stats[9] + 1;
  mmt_count := 4;
end;

{ record_routines_memory_usage - with doit (no load or store of generic
  memory), what classes of memory the routine touches (the calls'
  classes and the classes with tokens) noted in its +227/+228 bits:
  nothing when classes 12 or 13 (through parameters, random pointers)
  are touched; else +228 bit 6, +227 bit 0 when class 1 is not, +228
  bit 7 when no static class is, +228 bit 5 when no dynamic class is or
  only dynamic memory of its own frame (no call touches it and no
  dynamic token is uplevel).

  0x252438, 0x10C bytes, no A5: the classes a longword set (`bset' in a
  register), the class masks 16#3000, 16#407C, 16#8780. }

procedure record_routines_memory_usage(
    doit: boolean); options(val_param); internal;
var
  c, cc: mmt_classes_t;
  t: mmt_token_ptr_t;
  k: integer;
  f, done: boolean;
begin
  if doit then begin
    c := [];
    t := mmt_calls;
    while t <> nil do begin
      c := c + t^.reads + t^.writes;
      t := t^.next_class;
    end;
    cc := c;
    for k := 0 to 16 do
      if mmt_lists^[k] <> nil then
        c := c + [k];
    if (c * [12, 13]) = [] then begin
      mmt_rtn^.f228.no_pointer_dereference := true;
      if not (1 in c) then
        mmt_rtn_v_ptr_t(mmt_rtn)^.f227.b0 := true;
      if (c * mmt_static_classes) = [] then
        mmt_rtn^.f228.static_storage_untouched := true;
      if (c * mmt_dynamic_classes) = [] then
        mmt_rtn^.f228.uplevel_dynamic_storage_untouched := true
      else begin
        if (cc * mmt_dynamic_classes) <> [] then
          f := false
        else begin
          f := true;
          done := false;
          for k := 0 to 16 do
            if not done and (k in mmt_dynamic_classes)
                and (mmt_lists^[k] <> nil) then begin
              t := mmt_lists^[k];
              repeat
                if t^.desc.uplevel then begin
                  f := false;
                  done := true;
                end;
                t := t^.next_class;
              until done or (t = nil);
            end;
        end;
        mmt_rtn^.f228.uplevel_dynamic_storage_untouched := f;
      end;
    end;
  end;
end;

{ mmt_$simplify_tokens_in_bb - within bb, reads that follow a write of a
  token (one from a descriptor of class 1 or 13..15, or without a base,
  not of kind 28, not by a JOIN_BP or RETURN) and whose token's
  relations it subsumes are chained; when a later write's token's
  relations subsume that token's, the chained reads (and the modify
  operand after an intend-to-modify read) are made to read the first
  token's live range.  An MMT_SEQ starts afresh.

  0x252544, 0x1BE bytes: the classes `btst' in 16#E002; the reads
  chained through the operands' links. }

procedure mmt_$simplify_tokens_in_bb(
    bb: bb_ptr_t);
var
  prev, t, nt: mmt_token_ptr_t;
  chain, o, q: opnd_ptr_t;
  i, ii: instr_ptr_t;
  j: integer32;
  lr: lr_ptr_t;
begin
  prev := nil;
  chain := nil;
  i := bb^.first;
  while i <> nil do begin
    if i^.opc = ord(opc$mmt_seq) then begin
      prev := nil;
      chain := nil;
    end;
    for j := 1 to i^.h.nopnds do begin
      o := addr(i^.opnds[j]);
      if o^.h.kind in [operand$inscrutable_memory,
                       operand$well_behaved_memory] then begin
        t := mmt_lr_v_ptr_t(o^.ptr)^.token;
        if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
          if (prev <> nil) and (chain <> nil) then
            if bv_$set1_subsumes_set2(mmt_bits, t^.related,
                                      prev^.related) then
              repeat
                chain^.ptr := prev^.lr;
                chain^.h.kind := operand$inscrutable_memory;
                if chain^.h.intend_to_modify then begin
                  ii := utils_ins_$operands_instruction(chain);
                  q := addr(ii^.opnds[chain^.h.num + 1]);
                  if not q^.h.modify then
                    bug_check('MMT_$simplify_tokens_in_bb: mismatched intend-modify%$');
                  q^.ptr := prev^.lr;
                  q^.h.kind := operand$inscrutable_memory;
                end;
                chain := chain^.link;
              until chain = nil;
          lr := o^.ptr;
          nt := mmt_lr_v_ptr_t(lr)^.token;
          if (mmt_lr_v_ptr_t(lr)^.f8.kind <> 28)
              and not ((i^.opc = ord(opc$join_bp))
                       or (i^.opc = ord(opc$return)))
              and ((nt^.desc.base = nil)
                   or (nt^.desc.class in [1, 13..15])) then
            prev := nt
          else
            prev := nil;
          chain := nil;
        end
        else if (prev <> nil) and (t <> addr(mmt_all.t)) then
          if not ((i^.opc = ord(opc$join_bp))
                  or (i^.opc = ord(opc$return))) then
            if bv_$set1_subsumes_set2(mmt_bits, prev^.related,
                                      t^.related) then begin
              o^.link := chain;
              chain := o;
            end;
      end;
    end;
    i := i^.next;
  end;
end;

{ consider_merging_token - whether t may be merged with another token:
  not one merged already or all but local; any token not from a
  descriptor; else one referred to at most twice, or of no size, base,
  of class 13, or inexact.  0x252738, 0x50 bytes, no frame. }

function consider_merging_token(
    t: mmt_token_ptr_t): boolean; options(val_param); internal;
begin
  if t^.f.equivalent or (t = addr(mmt_all.t)) then
    consider_merging_token := false
  else if not t^.f.from_alias then
    consider_merging_token := true
  else if (t^.refs > 2) and (t^.desc.size <> 0) and (t^.desc.base <> nil)
      and (t^.desc.class <> 13) and not t^.desc.inexact then
    consider_merging_token := false
  else
    consider_merging_token := true;
end;

{ remove_duplicate_tokens - the memory operands chained from their
  live ranges (+44); then of each two tokens that may be merged and have
  the same relations, the later's operands moved to the earlier's live
  range (the chains joined) and the later marked merged (the routine's
  all-memory live range follows).

  0x252788, 0x178 bytes, no A5. }

procedure remove_duplicate_tokens; internal;
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  j, k, m: integer32;
  a, b: mmt_token_ptr_t;
  la, lb: lr_ptr_t;
  o, last: opnd_ptr_t;
begin
  bb := mmt_rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      for j := 1 to i^.h.nopnds do
        if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                  operand$well_behaved_memory] then begin
          i^.opnds[j].link := mmt_lr_v_ptr_t(i^.opnds[j].ptr)^.uses;
          mmt_lr_v_ptr_t(i^.opnds[j].ptr)^.uses := addr(i^.opnds[j]);
        end;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
  for k := 1 to mmt_count do begin
    a := mmt_token_map^[k];
    if consider_merging_token(a) then
      for m := k + 1 to mmt_count do begin
        b := mmt_token_map^[m];
        if consider_merging_token(b) then
          if bv_$equal(mmt_bits, a^.related, b^.related) then begin
            lb := b^.lr;
            la := a^.lr;
            o := mmt_lr_v_ptr_t(lb)^.uses;
            last := nil;
            while o <> nil do begin
              o^.ptr := la;
              last := o;
              o := o^.link;
            end;
            lb := b^.lr;
            if last <> nil then begin
              last^.link := mmt_lr_v_ptr_t(la)^.uses;
              mmt_lr_v_ptr_t(la)^.uses := mmt_lr_v_ptr_t(lb)^.uses;
              mmt_lr_v_ptr_t(lb)^.uses := nil;
            end;
            b^.f.equivalent := true;
            if mmt_rtn_v_ptr_t(mmt_rtn)^.all_lr = lb then
              mmt_rtn_v_ptr_t(mmt_rtn)^.all_lr := la;
          end;
      end;
  end;
end;

{ remove_waste - in a routine without asynchronous paths (+226's bit 6),
  each block's tokens simplified and duplicate tokens removed.
  0x252900, 0x3C bytes, no A5. }

procedure remove_waste; internal;
var
  bb: bb_ptr_t;
begin
  if not mmt_rtn_v_ptr_t(mmt_rtn)^.f227.has_async then begin
    bb := mmt_rtn^.bbs;
    while bb <> nil do begin
      mmt_$simplify_tokens_in_bb(bb);
      bb := bb^.next;
    end;
    remove_duplicate_tokens;
  end;
end;

{ compute_exposure_in_asynchronous_path - in a routine with asynchronous
  paths, the tokens read in the asynchronous blocks (+17 bit 2, on the
  +72 list through +114) and live on entry to them marked async: the
  tokens read (not to modify) and related to what is not killed are
  generated, a write of an exact descriptor's token kills it; lifetimes
  propagated (four vectors) and the exposed live ranges walked
  (lir_utils_$get_next_async_exposed_lr).

  0x25293C, 0x17A bytes, no A5. }

procedure compute_exposure_in_asynchronous_path; internal;
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  j, k, state: integer32;
  lr: lr_ptr_t;
  t: mmt_token_ptr_t;
  r: integer;
begin
  if mmt_rtn_v_ptr_t(mmt_rtn)^.f227.has_async then begin
    bv_$initialize_bit_vectors(mmt_rtn, mmt_bits, 4, false);
    bb := mmt_rtn^.bbs72;
    while bb <> nil do begin
      if bb^.f.asynchronous_path then begin
        i := bb^.first;
        while i <> nil do begin
          if i^.opc <> ord(opc$mmt_seq) then
            for j := 1 to i^.h.nopnds do
              if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                                        operand$well_behaved_memory] then begin
                lr := i^.opnds[j].ptr;
                t := mmt_lr_v_ptr_t(lr)^.token;
                r := opnd_bytes_ptr_t(addr(i^.opnds[j]))^.rrp;
                if (r & 48) = 16 then begin
                  bv_$and_to(mmt_bits, bb^.transparent, t^.related, mmt_392);
                  bv_$or(mmt_bits, mmt_392, bb^.live_gen);
                end
                else if ((r & 12) <> 0) and t^.f.from_alias
                    and not t^.desc.inexact then
                  bv_$clear(bb^.transparent, lr);
              end;
          i := i^.next;
        end;
      end;
      bb := bb^.next114;
    end;
    bv_$propagate_lifetimes(mmt_bits, mmt_rtn);
    lr := nil;
    state := 0;
    repeat
      k := lir_utils_$get_next_async_exposed_lr(mmt_rtn, lr, state);
      if k <> 0 then begin
        t := mmt_token_map^[k];
        lr := t^.lr;
        t^.f.async := true;
      end;
    until k = 0;
    bv_$release_bit_vectors(mmt_rtn);
  end;
end;

{ insert_equiv_in_main_list - the tokens equivalent to t (+28) related
  to t and to those after them, and put on t's class list after t.
  0x252AB6, 0x88 bytes, no A5. }

procedure insert_equiv_in_main_list(
    t: mmt_token_ptr_t); options(val_param); internal;
var
  e, f: mmt_token_ptr_t;
begin
  e := t^.equivs;
  while e <> nil do begin
    bv_$set(t^.related, e^.lr);
    bv_$set(e^.related, t^.lr);
    f := e^.equivs;
    while f <> nil do begin
      bv_$set(e^.related, f^.lr);
      bv_$set(f^.related, e^.lr);
      f := f^.equivs;
    end;
    e^.next_class := t^.next_class;
    t^.next_class := e;
    e := e^.equivs;
  end;
end;

{ classes_related - each token of list a related to each of list b
  (with check, only pairs one of which is uplevel).  0x252B3E, 0x76
  bytes, no A5. }

procedure classes_related(
    a: mmt_token_ptr_t;
    b: mmt_token_ptr_t;
    check: boolean); options(val_param); internal;
var
  p, q: mmt_token_ptr_t;
  rel: boolean;
begin
  p := a;
  while p <> nil do begin
    q := b;
    while q <> nil do begin
      if not check then
        rel := true
      else
        rel := p^.desc.uplevel or q^.desc.uplevel;
      if rel then begin
        bv_$set(p^.related, q^.lr);
        bv_$set(q^.related, p^.lr);
      end;
      q := q^.next_class;
    end;
    p := p^.next_class;
  end;
end;

{ classes_related_if_uplevel_or_ref - each token of a related to the
  tokens of b made from a descriptor that is uplevel or flagged (+19
  bit 3).  0x252BB4, 0x74 bytes, no A5. }

procedure classes_related_if_uplevel_or_ref(
    a: mmt_token_ptr_t;
    b: mmt_token_ptr_t); options(val_param); internal;
var
  p, q: mmt_token_ptr_t;
begin
  p := a;
  while p <> nil do begin
    q := b;
    while q <> nil do begin
      if q^.f.from_alias then
        if q^.desc.uplevel or q^.desc.f19_3 then begin
          bv_$set(p^.related, q^.lr);
          bv_$set(q^.related, p^.lr);
        end;
      q := q^.next_class;
    end;
    p := p^.next_class;
  end;
end;

{ classes_related_if_async - the tokens of a and b that are of an
  asynchronous call or exposed in an asynchronous path related.
  0x252C28, 0x7C bytes, no A5. }

procedure classes_related_if_async(
    a: mmt_token_ptr_t;
    b: mmt_token_ptr_t); options(val_param); internal;
var
  p, q: mmt_token_ptr_t;
begin
  p := a;
  while p <> nil do begin
    if p^.f.call_async or p^.f.async then begin
      q := b;
      while q <> nil do begin
        if q^.f.call_async or q^.f.async then begin
          bv_$set(p^.related, q^.lr);
          bv_$set(q^.related, p^.lr);
        end;
        q := q^.next_class;
      end;
    end;
    p := p^.next_class;
  end;
end;

{ build_related - the tokens' relations: the equivalent tokens put on
  the class lists; the tokens of each class related where their
  descriptors are (alias_$related); the static tokens to each other;
  generic memory to every class, all-but-local to every class (the
  dynamic classes only where uplevel); the classes' tokens by what the
  aliaser says of the two classes (0 related, 1 where uplevel, 2 not);
  the calls to the static tokens, to each other (classes in common) and
  to the classes they touch (8 and 10 only where uplevel or flagged);
  each token to itself and not to its mate.  Unless switch 10: the
  asynchronous exposure computed, the asynchronous tokens related to the
  calls, to the asynchronous token and its relations, those to each
  other and to all-but-local, the asynchronous token to the calls and
  the classes, and the descriptors of phases 3 and 4 to each other.

  0x252CA4, 0x55E bytes, no A5: the class loops count words (`dbf'),
  the lists indexed by four times the class. }

procedure build_related; internal;
var
  c, c2: integer;
  k, m: integer32;
  p, q, n, t, u, v: mmt_token_ptr_t;
  s: mmt_classes_t;
  hit: boolean;
begin
  insert_equiv_in_main_list(addr(mmt_generic.t));
  insert_equiv_in_main_list(addr(mmt_all.t));
  insert_equiv_in_main_list(addr(mmt_async.t));
  for c := 0 to 16 do begin
    p := mmt_lists^[c];
    while p <> nil do begin
      n := p^.next_class;
      insert_equiv_in_main_list(p);
      p := n;
    end;
  end;
  for c := 0 to 16 do begin
    p := mmt_lists^[c];
    while p <> nil do begin
      q := p^.next_class;
      while q <> nil do begin
        if alias_$related(p^.desc, q^.desc) then begin
          bv_$set(q^.related, p^.lr);
          bv_$set(p^.related, q^.lr);
        end;
        q := q^.next_class;
      end;
      p := p^.next_class;
    end;
  end;
  classes_related(addr(mmt_generic.t), addr(mmt_all.t), false);
  classes_related(addr(mmt_async.t), addr(mmt_generic.t), false);
  classes_related(addr(mmt_async.t), addr(mmt_all.t), false);
  for c := 0 to 16 do begin
    classes_related(addr(mmt_generic.t), mmt_lists^[c], false);
    classes_related(addr(mmt_all.t), mmt_lists^[c],
                    c in mmt_dynamic_classes);
    for c2 := c + 1 to 16 do
      case alias_$classes_may_be_related(c, c2) of
        0: classes_related(mmt_lists^[c], mmt_lists^[c2], false);
        1: classes_related(mmt_lists^[c], mmt_lists^[c2], true);
        2: ;
        otherwise
          bug_check('MMT_$build_related: unknown response from aliaser%$');
      end;
  end;
  classes_related(addr(mmt_generic.t), mmt_calls, false);
  classes_related(addr(mmt_all.t), mmt_calls, false);
  classes_related_if_async(addr(mmt_async.t), mmt_calls);
  p := mmt_calls;
  while p <> nil do begin
    s := p^.reads + p^.writes;
    q := p^.next_class;
    while q <> nil do begin
      if ((q^.reads + q^.writes) * s) <> [] then begin
        bv_$set(q^.related, p^.lr);
        bv_$set(p^.related, q^.lr);
      end;
      q := q^.next_class;
    end;
    p := p^.next_class;
  end;
  p := mmt_calls;
  while p <> nil do begin
    n := p^.next_class;
    p^.next_class := nil;
    for c := 0 to 16 do begin
      s := p^.reads + p^.writes;
      hit := false;
      if c in [12, 13] then
        hit := true
      else if c in s then
        hit := true;
      if hit then begin
        if c in [8, 10] then
          classes_related_if_uplevel_or_ref(p, mmt_lists^[c])
        else
          classes_related(p, mmt_lists^[c], false);
      end
      else if c in [8, 10] then
        if (s * mmt_unrelated) <> [] then
          classes_related_if_uplevel_or_ref(p, mmt_lists^[c]);
    end;
    p^.next_class := n;
    p := n;
  end;
  for k := 1 to mmt_count do begin
    t := mmt_token_map^[k];
    bv_$set(t^.related, t^.lr);
    if t^.mate <> nil then
      bv_$clear(t^.related, t^.mate^.lr);
  end;
  if not at_backend_switches.sw10 then begin
    compute_exposure_in_asynchronous_path;
    for c := 0 to 16 do
      classes_related_if_async(mmt_calls, mmt_lists^[c]);
    for k := 1 to mmt_count do begin
      t := mmt_token_map^[k];
      if t^.f.async and t^.f.from_alias then begin
        bv_$set(mmt_async.t.related, t^.lr);
        bv_$set(t^.related, mmt_async.t.lr);
        m := bv_$find_next_val(mmt_rtn, t^.related, 0);
        while m <> 0 do begin
          u := mmt_token_map^[m];
          if t^.f.from_alias then begin
            bv_$set(mmt_async.t.related, u^.lr);
            bv_$set(u^.related, mmt_async.t.lr);
          end;
          m := bv_$find_next_val(mmt_rtn, t^.related, m);
        end;
      end;
    end;
    k := bv_$find_next_val(mmt_rtn, mmt_async.t.related, 0);
    while k <> 0 do begin
      u := mmt_token_map^[k];
      if u^.f.from_alias then begin
        bv_$set(mmt_all.t.related, u^.lr);
        bv_$set(u^.related, mmt_all.t.lr);
        m := bv_$find_next_val(mmt_rtn, mmt_async.t.related, k);
        while m <> 0 do begin
          v := mmt_token_map^[m];
          if v^.f.from_alias then begin
            bv_$set(u^.related, v^.lr);
            bv_$set(v^.related, u^.lr);
          end;
          m := bv_$find_next_val(mmt_rtn, mmt_async.t.related, m);
        end;
      end;
      k := bv_$find_next_val(mmt_rtn, mmt_async.t.related, k);
    end;
    classes_related(addr(mmt_async.t), mmt_calls, false);
    for c := 0 to 16 do
      classes_related(addr(mmt_async.t), mmt_lists^[c],
                      c in mmt_dynamic_classes);
    for k := 1 to mmt_count do begin
      u := mmt_token_map^[k];
      if u^.f.from_alias and u^.desc.phase_34 then
        for m := k + 1 to mmt_count do begin
          v := mmt_token_map^[m];
          if v^.f.from_alias and v^.desc.phase_34 then begin
            bv_$set(u^.related, v^.lr);
            bv_$set(v^.related, u^.lr);
          end;
        end;
    end;
  end;
end;

{ get_token_for_call - the token of a call: the classes it may read and
  write (all but 0 and 11..13 to begin with; none read or written by
  the call's properties; class 1, the static and the dynamic classes,
  16 taken out; the classes unrelated to 12 and 13 added unless it only
  touches what is passed) and whether it may run asynchronously (true
  without properties); the calls' token with the same, else a new one
  (call, a new live range, on the calls' list).

  0x253236, 0x124 bytes, no A5: the properties' pointer after the
  operands (`(0x38,A0,D0.w)' with D0 12 nopnds); the sets cleared with
  `andi.l' of their complements. }

function get_token_for_call(
    i: instr_ptr_t): mmt_token_ptr_t; options(val_param); internal;
var
  r, w: mmt_classes_t;
  ci: mmt_call_info_ptr_t;
  async: boolean;
  t: mmt_token_ptr_t;
  lr: lr_ptr_t;
begin
  r := [1..10, 14..16];
  w := r;
  ci := mmt_call_info_ptr_ptr_t(integer32(i) + 56 + 12 * i^.h.nopnds)^;
  if ci = nil then
    async := true
  else begin
    async := ci^.async;
    if ci^.no_reads then
      r := [];
    if ci^.no_writes then
      w := [];
    if ci^.no_class_1 then begin
      r := r - [1];
      w := w - [1];
    end;
    if ci^.no_static then begin
      r := r - mmt_static_classes;
      w := w - mmt_static_classes;
    end;
    if ci^.no_dynamic then begin
      r := r - mmt_dynamic_classes;
      w := w - mmt_dynamic_classes;
    end;
    if ci^.no_reads_16 then
      r := r - [16];
    if ci^.no_writes_16 then
      w := w - [16];
    if not ci^.own_only then begin
      r := r + mmt_unrelated;
      w := w + mmt_unrelated;
    end;
  end;
  t := mmt_calls;
  while t <> nil do begin
    if (t^.f.call_async = async) and (t^.reads = r) and (t^.writes = w) then begin
      get_token_for_call := t;
      return;
    end;
    t := t^.next_class;
  end;
  t := mrh_$alloc_fixed(mmt_token_heap);
  t^.f.call := true;
  t^.reads := r;
  t^.writes := w;
  t^.f.call_async := async;
  lr := lir_$new_live_range;
  t^.lr := lr;
  mmt_lr_v_ptr_t(lr)^.token := t;
  mmt_stats[9] := mmt_stats[9] + 1;
  mmt_count := mmt_count + 1;
  t^.next_class := mmt_calls;
  mmt_calls := t;
  get_token_for_call := t;
end;

{ get_hashed_token - the token of descriptor d (hashed on its base's
  bytes, class, displacement and size): one with the same symbol,
  inexact and phase flags, size, displacement, class and base, else a
  new one (from an alias descriptor, a new live range, on the hash
  chain and its class's list).

  0x25335A, 0x144 bytes, no A5: the base's four bytes from a frame
  copy, `eor.l' throughout, `andi.l #255'. }

function get_hashed_token(
    var d: alias_$desc_t): mmt_token_ptr_t; options(val_param); internal;
type
  ptr_bytes_t = record
    case integer of
      1: (p: il_$node_ptr_t);
      2: (b: packed array [0..3] of 0..255);
  end;
var
  pb: ptr_bytes_t;
  h: integer32;
  t: mmt_token_ptr_t;
  lr: lr_ptr_t;
begin
  if d.class = 0 then
    bug_check('MMT_$get_hashed_token:  alias$never_invalidated should have no token!%$');
  pb.p := d.base;
  h := xor(xor(xor(xor(pb.b[0], pb.b[1]), xor(pb.b[2], pb.b[3])), d.class),
           xor(d.disp, d.size)) & 255;
  t := mmt_hash^[h];
  while t <> nil do begin
    if (t^.desc.sym = d.sym) and (t^.desc.inexact = d.inexact)
        and (t^.desc.phase_34 = d.phase_34) and (t^.desc.size = d.size)
        and (t^.desc.disp = d.disp) and (t^.desc.class = d.class)
        and (t^.desc.base = d.base) then begin
      get_hashed_token := t;
      return;
    end;
    t := t^.next;
  end;
  t := mrh_$alloc_fixed(mmt_token_heap);
  t^.desc := d;
  t^.f.from_alias := true;
  lr := lir_$new_live_range;
  t^.lr := lr;
  mmt_lr_v_ptr_t(lr)^.token := t;
  mmt_stats[9] := mmt_stats[9] + 1;
  t^.next := mmt_hash^[h];
  mmt_hash^[h] := t;
  t^.next_class := mmt_lists^[d.class];
  mmt_lists^[d.class] := t;
  mmt_count := mmt_count + 1;
  get_hashed_token := t;
end;

{ get_token - the token of descriptor d (nil: generic memory): a copy
  with class 11 made 8, an inexact one's displacement and size cleared,
  the base cleared (and inexact) for a class unrelated to itself (but
  an exact class 12), all inexact under switch 12; hashed.

  0x2534E6, 0xBC bytes, no A5: the classes 1..15 `btst' in 16#FFFE. }

function get_token(
    d: alias_$desc_ptr_t): mmt_token_ptr_t; options(val_param); internal;
var
  c: alias_$desc_t;
begin
  if d = nil then
    get_token := addr(mmt_generic.t)
  else begin
    if not (d^.class in [1..15]) then
      bug_check('MMT_$get_token:  illegal alias class%$');
    c := d^;
    if c.class = 11 then
      c.class := 8;
    if c.inexact then begin
      c.disp := 0;
      c.size := 0;
    end;
    if alias_$classes_may_be_related(c.class, c.class) = 0 then
      if c.inexact or (c.class <> 12) then begin
        c.base := nil;
        c.inexact := true;
      end;
    if at_backend_switches.sw12 then begin
      c.disp := 0;
      c.size := 0;
      c.inexact := true;
    end;
    get_token := get_hashed_token(c);
  end;
end;

{ fill_in_token_id_map - the tokens numbered from 1 in the map: the four
  static tokens (generic memory, all but local, asynchronous, the
  connector), the classes' tokens, the calls', each followed by its
  equivalents; the number must come to the count.

  0x25361E, 0xD6 bytes, no A5: the number a word of the frame (-10)
  the nested routines reach (enter_token through A1, enter_equiv_token
  from its dynamic link, docs/rev889-patterns.md 25). }

procedure fill_in_token_id_map; internal;
var
  id: integer;
  c: integer;
  t: mmt_token_ptr_t;

  { enter_token - t numbered next.  0x2535C8, 0x24 bytes, no frame. }

  procedure enter_token(
      t: mmt_token_ptr_t); options(val_param);
  begin
    id := id + 1;
    mmt_token_map^[id] := t;
    t^.id := id;
  end;

  { enter_equiv_token - t's equivalents (+28) numbered.  0x2535EC, 0x32
    bytes. }

  procedure enter_equiv_token(
      t: mmt_token_ptr_t); options(val_param);
  var
    e: mmt_token_ptr_t;
  begin
    e := t^.equivs;
    while e <> nil do begin
      enter_token(e);
      e := e^.equivs;
    end;
  end;

begin
  id := 0;
  enter_token(addr(mmt_generic.t));
  enter_equiv_token(addr(mmt_generic.t));
  enter_token(addr(mmt_all.t));
  enter_equiv_token(addr(mmt_all.t));
  enter_token(addr(mmt_async.t));
  enter_equiv_token(addr(mmt_async.t));
  enter_token(addr(mmt_connector.t));
  enter_equiv_token(addr(mmt_connector.t));
  for c := 0 to 16 do begin
    t := mmt_lists^[c];
    while t <> nil do begin
      enter_token(t);
      enter_equiv_token(t);
      t := t^.next_class;
    end;
  end;
  t := mmt_calls;
  while t <> nil do begin
    enter_token(t);
    enter_equiv_token(t);
    t := t^.next_class;
  end;
  if id <> mmt_count then
    bug_check('MMT_$fill_in_token_id_map: token_id <> active_tokens%$');
end;

{ get_single_alias_for_lr - the one alias descriptor of lr's references
  (their instructions', 24 bytes before those with +2 bit 7; MMT_SEQs
  not counted): found when the first reference has one; every other
  must agree (have one when the first had, and the same uplevel flag,
  class and base), a different size or displacement or an inexact one
  making the result inexact.

  0x25372A, 0x11A bytes, no A5: the result cleared as 24 bytes. }

procedure get_single_alias_for_lr(
    lr: lr_ptr_t;
    var d: mmt_desc24_t;
    var found: boolean); options(val_param); internal;
var
  f: boolean;
  l: lts_ptr_t;
  o: opnd_ptr_t;
  i: instr_ptr_t;
  a: alias_$desc_ptr_t;
begin
  zero(addr(d), 24);
  f := false;
  found := f;
  l := lr^.ltss;
  while l <> nil do begin
    o := l^.refs;
    while o <> nil do begin
      i := utils_ins_$operands_instruction(o);
      if i^.opc <> ord(opc$mmt_seq) then begin
        if i^.h.b2_7 then
          a := alias_$desc_ptr_t(integer32(i) - 24)
        else
          a := nil;
        if not f then begin
          f := true;
          if a <> nil then begin
            found := f;
            d.d := a^;
          end;
        end
        else begin
          if (a <> nil) <> found then
            bug_check('MMT_$get_single_alias_for_lr:  multiple alias descriptors for LR %3ZWD%$',
                      lr^.num);
          if found then begin
            if (d.d.uplevel <> a^.uplevel) or (d.d.class <> a^.class)
                or (d.d.base <> a^.base) then
              bug_check('MMT_$get_single_alias_for_lr:  multiple alias descriptors for LR %3ZWD%$',
                        lr^.num);
            if (d.d.size <> a^.size) or a^.inexact
                or (d.d.disp <> a^.disp) then
              d.d.inexact := true;
          end;
        end;
      end;
      o := o^.link;
    end;
    l := l^.next;
  end;
end;

{ mmt_seq_is_not_arg_blk_seq - whether an MMT_SEQ's first memory operand
  (before any of the argument block, kind 9) is inscrutable or
  well-behaved memory (true also with neither).  0x25388C, 0x60 bytes,
  no A5. }

function mmt_seq_is_not_arg_blk_seq(
    i: instr_ptr_t): boolean; options(val_param); internal;
var
  j: integer32;
  k: operand$t;
begin
  for j := 1 to i^.h.nopnds do begin
    k := i^.opnds[j].h.kind;
    if k in [operand$inscrutable_memory, operand$well_behaved_memory] then begin
      mmt_seq_is_not_arg_blk_seq := true;
      return;
    end;
    if k = operand$argument_block_memory then begin
      mmt_seq_is_not_arg_blk_seq := false;
      return;
    end;
  end;
  mmt_seq_is_not_arg_blk_seq := true;
end;

{ mmt_$allocate_scratch_vectors - five scratch vectors of bytes each,
  cleared: +392 (the storage, mmt_scratch), +388, +320 (mmt_140), +384,
  +380; their size noted (+400 bytes, +396 bits).  0x2538EC, 0x76
  bytes. }

procedure mmt_$allocate_scratch_vectors(
    bytes: integer32);
var
  size: integer32;
  p: integer32;
begin
  size := bytes * 5;
  mmt_scratch := rws_$alloc_heap(size);
  zero(mmt_scratch, size);
  mmt_392 := mmt_scratch;
  p := integer32(mmt_scratch) + bytes;
  mmt_388 := bv_ptr_t(p);
  p := p + bytes;
  mmt_140 := bv_ptr_t(p);
  p := p + bytes;
  mmt_384 := bv_ptr_t(p);
  p := p + bytes;
  mmt_380 := bv_ptr_t(p);
  mmt_bytes := bytes;
  mmt_bits := bytes * 8;
end;

{ mmt_$allocate_tokens - every memory reference given a token: each
  memory live range with segments (not the routine's memory live range)
  a token of its own (a copy of its single descriptor's token, or of
  generic memory's, made its equivalent); the references of the others
  that of their instruction: a load's or store's descriptor's, a
  RETURN's all-but-local, a CALL's, a conditional trap's asynchronous
  one, else generic memory (a load or store without a descriptor noted).
  Each operand then reads its token's live range (+8), counted on the
  token (+52) and marked (unconsumed, +1 bit 6).  Every memory operand
  must have been marked (bug_check); a read followed by a write of the
  same live range becomes an intend-to-modify and a modify.  The
  MMT_SEQs of memory (not the argument block's) are removed, their
  first two written tokens made mates; the others lose +2 bit 5.  Then
  the routine's memory usage recorded, the vectors allocated (scratch,
  and two per token after the map), the tokens numbered, their live
  ranges given the numbers, the relations built and the waste removed.

  0x253962, 0x40C bytes, no A5: the classes `btst' in 16#210000 (load,
  store); the vectors' size (count + 32) div 32 * 4; the map and vectors
  one heap (M$MIS$LLL). }

procedure mmt_$allocate_tokens; internal;
var
  saw: boolean;
  lr: lr_ptr_t;
  l: lts_ptr_t;
  t, g, tk: mmt_token_ptr_t;
  d: mmt_desc24_t;
  found: boolean;
  o, nxt: opnd_ptr_t;
  i, inxt: instr_ptr_t;
  bb: bb_ptr_t;
  j, k, n4, size, total, p: integer32;
  cls: integer;
  st: status_$t;
begin
  allocate_initialize;
  saw := false;
  lr := mmt_rtn^.lrs;
  while lr <> nil do begin
    if mmt_utils_$lr_is_for_memory(lr) then begin
      l := lr^.ltss;
      if (l = nil) or (mmt_rtn_v_ptr_t(mmt_rtn)^.mem_lr = lr) then
        t := nil
      else begin
        get_single_alias_for_lr(lr, d, found);
        if found then
          g := get_token(addr(d.d))
        else
          g := get_token(nil);
        t := mrh_$alloc_fixed(mmt_token_heap);
        t^.desc := g^.desc;
        t^.f.from_alias := g^.f.from_alias;
        t^.lr := lr;
        mmt_lr_v_ptr_t(lr)^.token := t;
        t^.equivs := g^.equivs;
        g^.equivs := t;
        mmt_count := mmt_count + 1;
      end;
      while l <> nil do begin
        o := l^.refs;
        while o <> nil do begin
          i := utils_ins_$operands_instruction(o);
          tk := t;
          if tk = nil then begin
            cls := instruction_attributes[i^.opc].class;
            if i^.h.b2_7 and (cls in [class$load, class$store]) then
              tk := get_token(alias_$desc_ptr_t(integer32(i) - 24))
            else if i^.opc = ord(opc$return) then
              tk := addr(mmt_all.t)
            else if i^.opc = ord(opc$call) then
              tk := get_token_for_call(i)
            else if cls = class$trap_cond then
              tk := addr(mmt_async.t)
            else begin
              tk := addr(mmt_generic.t);
              if cls in [class$load, class$store] then
                saw := true;
            end;
          end;
          nxt := o^.link;
          o^.ptr := tk^.lr;
          tk^.refs := tk^.refs + 1;
          o^.h.unconsumed := true;
          o := nxt;
        end;
        l := l^.next;
      end;
    end;
    lr := lr^.next;
  end;
  bb := mmt_rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if o^.h.kind in [operand$inscrutable_memory,
                         operand$well_behaved_memory] then begin
          if not o^.h.unconsumed then
            bug_check('MMT_$ALLOCATE_TOKENS:  missed operand %3ZWD:%3ZWD:%3ZLD%$',
                      bb^.num, i^.num, j);
          o^.h.unconsumed := false;
          mmt_stats[3] := mmt_stats[3] + 1;
          if o^.h.read then
            if i^.h.nopnds > j then
              if i^.opnds[j + 1].h.kind in [operand$inscrutable_memory,
                                            operand$well_behaved_memory] then
                if i^.opnds[j + 1].ptr = o^.ptr then
                  if i^.opnds[j + 1].h.write then begin
                    o^.h.intend_to_modify := true;
                    i^.opnds[j + 1].h.write := false;
                    i^.opnds[j + 1].h.modify := true;
                  end;
        end;
      end;
      inxt := i^.next;
      if i^.opc = ord(opc$mmt_seq) then
        if mmt_seq_is_not_arg_blk_seq(i) then begin
          if i^.opnds[1].h.write and i^.opnds[2].h.write then begin
            g := mmt_lr_v_ptr_t(i^.opnds[1].ptr)^.token;
            t := mmt_lr_v_ptr_t(i^.opnds[2].ptr)^.token;
            g^.mate := t;
            t^.mate := g;
          end;
          mmt_stats[5] := mmt_stats[5] - i^.h.nopnds;
          mmt_stats[11] := mmt_stats[11] - 1;
          lir_utils_$excise_inst(i);
        end
        else
          i^.h.may_generate_an_exception := false;
      i := inxt;
    end;
    bb := bb^.next;
  end;
  record_routines_memory_usage(not saw);
  mmt_bytes := ((mmt_count + 32) div 32) * 4;
  mmt_bits := mmt_bytes * 8;
  n4 := mmt_count * 4;
  mmt_$allocate_scratch_vectors(mmt_bytes);
  size := (mmt_count * 2) * mmt_bytes;
  total := size + n4;
  mmt_token_map := rws_$alloc_heap(total);
  zero(mmt_token_map, total);
  fill_in_token_id_map;
  p := n4 + integer32(mmt_token_map);
  for k := 1 to mmt_count do begin
    mmt_token_map^[k]^.related := bv_ptr_t(p);
    p := p + mmt_bytes;
    mmt_token_map^[k]^.compared := bv_ptr_t(p);
    p := p + mmt_bytes;
  end;
  for k := 1 to mmt_count do begin
    lr := mmt_token_map^[k]^.lr;
    lr^.id := k;
    mmt_lr_v_ptr_t(lr)^.uses := nil;
  end;
  mmt_rtn^.l192 := mmt_count;
  build_related;
  rws_$release_heap(mmt_hash, st);
  remove_waste;
end;

{ mmt_$insert_blocks_intra_bb_seq - the MMT_SEQs bb needs within itself
  (after its labels and joins): before each memory reference, the
  tokens it is related to that were touched since (compared) made
  active as read; a write also: the related tokens live on (mmt_140)
  read and written (its own token read and written when it was live
  itself), noted as compared by the tokens not related to it, and the
  token taken off mmt_140; a read put on mmt_140.  With tokens active
  the reference's own token is written and an MMT_SEQ emitted before it
  (joined with the previous one when they can combine, given what was
  read and written since, +384 and +380); a write without one ends the
  previous MMT_SEQ.

  0x253DA8, 0x3A0 bytes: the token's vectors cleared by its callers;
  the first add_tokens_from_instr pops 6 of 8 bytes for the emit after
  it (docs/rev889-patterns.md 51). }

procedure mmt_$insert_blocks_intra_bb_seq(
    bb: bb_ptr_t);
var
  i, seq, n: instr_ptr_t;
  j, k: integer32;
  o: opnd_ptr_t;
  t, u: mmt_token_ptr_t;
  r: boolean;
begin
  zero(mmt_384, mmt_bytes);
  zero(mmt_380, mmt_bytes);
  i := bb^.first;
  while i <> nil do begin
    if (i^.opc <> ord(opc$join_bp)) and (i^.opc <> ord(opc$label)) then
      exit;
    i := i^.next;
  end;
  seq := nil;
  while i <> nil do begin
    for j := 1 to i^.h.nopnds do begin
      o := addr(i^.opnds[j]);
      if o^.h.kind in [operand$inscrutable_memory,
                       operand$well_behaved_memory] then begin
        mmt_active := nil;
        t := mmt_lr_v_ptr_t(o^.ptr)^.token;
        if not (o^.h.read and o^.h.intend_to_modify) then begin
          if o^.h.read then begin
            bv_$and_to(mmt_bits, t^.compared, t^.related, mmt_392);
            bv_$clear(mmt_392, t^.lr);
            if mmt_utils_$mmt_seq_add_tokens_from_bv(mmt_392, true, false) then
              bv_$subtract(mmt_bits, mmt_392, t^.compared);
            bv_$set(mmt_140, t^.lr);
          end
          else begin
            bv_$and_to(mmt_bits, t^.compared, t^.related, mmt_392);
            bv_$clear(mmt_392, t^.lr);
            r := mmt_utils_$mmt_seq_add_tokens_from_bv(mmt_392, true, false);
            for k := 1 to mmt_count do begin
              u := mmt_token_map^[k];
              if bv_$test(t^.related, u^.lr) then begin
                if r then
                  bv_$subtract(mmt_bits, mmt_392, u^.compared);
                bv_$set(u^.compared, t^.lr);
              end;
            end;
            bv_$and_to(mmt_bits, mmt_140, t^.related, mmt_392);
            if not r then
              r := bv_$test_and_clear(mmt_392, t^.lr)
            else
              r := false;
            if mmt_utils_$mmt_seq_add_tokens_from_bv(mmt_392, true, true) then begin
              bv_$subtract(mmt_bits, mmt_392, mmt_140);
              if r then
                mmt_utils_$mmt_seq_add_token(t, true, true);
              for k := 1 to mmt_count do begin
                u := mmt_token_map^[k];
                if not bv_$test(t^.related, u^.lr) then begin
                  bv_$and_to(mmt_bits, mmt_392, u^.related, mmt_388);
                  bv_$or(mmt_bits, mmt_388, u^.compared);
                end;
              end;
            end;
            bv_$clear(mmt_140, t^.lr);
          end;
          if mmt_active <> nil then begin
            mmt_utils_$mmt_seq_add_token(t, false, true);
            if (seq <> nil)
                and mmt_utils_$can_combine_mmt_seqs(seq, mmt_384, mmt_380) then begin
              mmt_utils_$mmt_seq_add_tokens_from_instr(seq);
              n := mmt_utils_$mmt_seq_emit(seq, true);
              lir_utils_$excise_inst(seq);
              seq := n;
            end
            else begin
              seq := mmt_utils_$mmt_seq_emit(i, false);
              zero(mmt_384, mmt_bytes);
              zero(mmt_380, mmt_bytes);
            end;
            bv_$set(mmt_384, o^.ptr);
            if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
              bv_$set(mmt_380, o^.ptr);
          end
          else if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
            seq := nil
          else
            bv_$set(mmt_384, o^.ptr);
        end;
      end;
    end;
    i := i^.next;
  end;
end;

{ mmt_$insert_intra_bb_seq - the tokens made inactive (link and flags
  cleared); each asynchronous-list block (+72, through +114) given its
  MMT_SEQs with mmt_140 and the compared vectors cleared.  0x254148,
  0xAE bytes, no A5. }

procedure mmt_$insert_intra_bb_seq; internal;
var
  k: integer32;
  t: mmt_token_ptr_t;
  bb: bb_ptr_t;
begin
  for k := 1 to mmt_count do begin
    t := mmt_token_map^[k];
    t^.next := nil;
    t^.f.read := false;
    t^.f.written := false;
  end;
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    zero(mmt_140, mmt_bytes);
    for k := 1 to mmt_count do
      zero(mmt_token_map^[k]^.compared, mmt_bytes);
    mmt_$insert_blocks_intra_bb_seq(bb);
    bb := bb^.next114;
  end;
end;

{ remove_existing_relationship - bv less the relations of the tokens i
  reads whose live ranges are in live; when i's first operand reads
  memory written by the MMT_SEQ before it (its last operand, the same
  live range), that MMT_SEQ too (recursively).  0x2541F6, 0x114 bytes,
  no A5. }

procedure remove_existing_relationship(
    i: instr_ptr_t;
    bv: bv_ptr_t;
    live: bv_ptr_t); options(val_param); internal;
var
  j: integer32;
  t: mmt_token_ptr_t;
  p: instr_ptr_t;
  q: opnd_ptr_t;
begin
  for j := 1 to i^.h.nopnds do
    if i^.opnds[j].h.kind in [operand$inscrutable_memory,
                              operand$well_behaved_memory] then
      if i^.opnds[j].h.read then begin
        t := mmt_lr_v_ptr_t(i^.opnds[j].ptr)^.token;
        if bv_$test(live, t^.lr) then
          bv_$subtract(mmt_bits, t^.related, bv);
      end;
  if i^.opnds[1].h.read
      and (i^.opnds[1].h.kind in [operand$inscrutable_memory,
                                  operand$well_behaved_memory])
      and (i^.prev <> nil) then
    if i^.prev^.opc = ord(opc$mmt_seq) then begin
      p := i^.prev;
      j := p^.h.nopnds;
      while p^.opnds[j].h.kind = operand$none do
        j := j - 1;
      q := addr(p^.opnds[j]);
      if q^.h.kind in [operand$inscrutable_memory,
                       operand$well_behaved_memory] then
        if (opnd_bytes_ptr_t(q)^.rrp & 12) <> 0 then
          if q^.ptr = i^.opnds[1].ptr then
            remove_existing_relationship(p, bv, live);
    end;
end;

{ update_active_tokens - bv taken out of the compared vectors of the
  tokens related to t.  0x25430A, 0x5C bytes, no A5. }

procedure update_active_tokens(
    t: mmt_token_ptr_t;
    bv: bv_ptr_t); options(val_param); internal;
var
  k: integer32;
begin
  k := bv_$find_next_val(mmt_rtn, t^.related, 0);
  while k <> 0 do begin
    bv_$subtract(mmt_bits, bv, mmt_token_map^[k]^.compared);
    k := bv_$find_next_val(mmt_rtn, t^.related, k);
  end;
end;

{ mmt_$insert_inter_bb_seq - the MMT_SEQs needed across blocks.  Seven
  vectors per block: the reads exposed (live_gen, set unless killed)
  and the local writes (avail_gen, avail_out, transparent losing what a
  write kills); the exit block reads all-but-local; lifetimes and
  availability propagated (dumped from debug level 4).  Then each
  token's compared vector holds the tokens whose relations its own
  subsume; the writes' killed sets propagated again.  Each write whose
  token is reached by an earlier unmatched write or read gets an MMT_SEQ
  of the tokens active there (an MMT_SEQ replaced by the new one); each
  block's live-on-exit tokens get MMT_SEQs at its end (before its
  branches), the tokens with the same compared vector sharing one.

  0x254366, 0x6D8 bytes, no A5: the branch classes `btst' in
  16#1000062; the transparent vectors set to all ones a longword at a
  time; add_tokens_from_instr pops 6 of 8 bytes (pattern 51). }

procedure mmt_$insert_inter_bb_seq; internal;
var
  bb: bb_ptr_t;
  i, nxt, n: instr_ptr_t;
  j, k, m, nlongs: integer32;
  o: opnd_ptr_t;
  t, list, prev, q: mmt_token_ptr_t;
  r: boolean;
begin
  bv_$initialize_bit_vectors(mmt_rtn, mmt_bits, 7, true);
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if o^.h.kind in [operand$inscrutable_memory,
                         operand$well_behaved_memory] then
          if o^.h.read then begin
            bv_$set_if_not_killed(bb^.transparent, o^.ptr, bb^.live_gen);
            if i^.opc <> ord(opc$mmt_seq) then
              bv_$set(bb^.avail_gen, o^.ptr);
          end
          else begin
            t := mmt_lr_v_ptr_t(o^.ptr)^.token;
            bv_$subtract(mmt_bits, t^.related, bb^.transparent);
            if i^.opc <> ord(opc$mmt_seq) then
              bv_$subtract(mmt_bits, t^.related, bb^.avail_gen);
            bv_$clear(bb^.avail_gen, t^.lr);
            bv_$subtract(mmt_bits, t^.related, bb^.avail_out);
            bv_$set(bb^.avail_out, t^.lr);
          end;
      end;
      i := i^.next;
    end;
    bb := bb^.next114;
  end;
  bv_$set(mmt_rtn_v_ptr_t(mmt_rtn)^.exit_bb^.live_gen,
          mmt_rtn_v_ptr_t(mmt_rtn)^.all_lr);
  bv_$propagate_lifetimes(mmt_bits, mmt_rtn);
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    bv_$subtract(mmt_bits, bb^.avail_out, bb^.live_out);
    bv_$subtract(mmt_bits, bb^.transparent, bb^.live_out);
    zero(bb^.avail_out, mmt_bytes);
    bb := bb^.next114;
  end;
  bv_$propagate_availability(mmt_bits, mmt_rtn, true);
  if mmt_level >= 4 then begin
    vfmt_$write('%/After first propagate_lifetimes and availability:%/%.');
    dump_bb_bit_vectors(mmt_rtn);
  end;
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    bv_$copy(mmt_bits, bb^.avail_in, bb^.live_in);
    bb := bb^.next114;
  end;
  bb := mmt_rtn^.bbs72;
  nlongs := mmt_bytes div 4 - 1;
  while bb <> nil do begin
    for k := 0 to nlongs do
      bb^.transparent^[k] := [0..31];
    zero(bb^.avail_in, mmt_bytes);
    zero(bb^.avail_out, mmt_bytes);
    zero(bb^.avail_gen, mmt_bytes);
    bb := bb^.next114;
  end;
  for k := 1 to mmt_count do begin
    t := mmt_token_map^[k];
    zero(t^.compared, mmt_bytes);
    m := bv_$find_next_val(mmt_rtn, t^.related, 0);
    while m <> 0 do begin
      q := mmt_token_map^[m];
      if bv_$set1_subsumes_set2(mmt_bits, t^.related, q^.related) then
        bv_$set(t^.compared, q^.lr);
      m := bv_$find_next_val(mmt_rtn, t^.related, m);
    end;
  end;
  if at_backend_switches.sw9 then
    dump_related_vectors('%/%/Completely killed sets for MMT_$INSERT_INTER_BB_SEQ:%/%.', 1);
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if o^.h.kind in [operand$inscrutable_memory,
                         operand$well_behaved_memory] then
          if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
            t := mmt_lr_v_ptr_t(o^.ptr)^.token;
            bv_$subtract(mmt_bits, t^.compared, bb^.transparent);
            bv_$subtract(mmt_bits, t^.compared, bb^.avail_gen);
            bv_$set(bb^.avail_gen, o^.ptr);
          end;
      end;
      i := i^.next;
    end;
    bb := bb^.next114;
  end;
  bv_$propagate_availability(mmt_bits, mmt_rtn, true);
  if mmt_level >= 4 then begin
    vfmt_$write('%/After second propagate_availability:%/%.');
    dump_bb_bit_vectors(mmt_rtn);
  end;
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    for k := 1 to mmt_count do begin
      t := mmt_token_map^[k];
      bv_$and_to(mmt_bits, bb^.avail_in, t^.related, t^.compared);
    end;
    i := bb^.first;
    while i <> nil do begin
      nxt := i^.next;
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
          if o^.h.kind in [operand$inscrutable_memory,
                           operand$well_behaved_memory] then begin
            mmt_active := nil;
            t := mmt_lr_v_ptr_t(o^.ptr)^.token;
            if bv_$copy_and_test(mmt_bits, t^.compared, mmt_392) then begin
              update_active_tokens(t, mmt_392);
              remove_existing_relationship(i, mmt_392, bb^.live_gen);
              r := mmt_utils_$mmt_seq_add_tokens_from_bv(mmt_392, true, false);
            end
            else
              r := false;
            bv_$and_to(mmt_bits, t^.related, bb^.live_in, mmt_392);
            bv_$clear(mmt_392, o^.ptr);
            if mmt_utils_$mmt_seq_add_tokens_from_bv(mmt_392, true, true) then begin
              bv_$subtract(mmt_bits, mmt_392, bb^.live_in);
              r := true;
            end;
            bv_$clear(bb^.live_in, o^.ptr);
            bv_$clear(bb^.live_gen, o^.ptr);
            if r then begin
              mmt_utils_$mmt_seq_add_tokens_from_instr(i);
              n := mmt_utils_$mmt_seq_emit(i, false);
              if i^.opc = ord(opc$mmt_seq) then begin
                lir_utils_$excise_inst(i);
                nxt := n;
                exit;
              end;
            end;
          end;
      end;
      i := nxt;
    end;
    bb := bb^.next114;
  end;
  bb := mmt_rtn^.bbs72;
  while bb <> nil do begin
    i := bb^.last;
    while i <> nil do begin
      if not (instruction_attributes[i^.opc].class in
              [class$branch, class$fp_branch, class$jump, class$return]) then
        exit;
      i := i^.prev;
    end;
    list := nil;
    k := bv_$find_next_val(mmt_rtn, bb^.live_out, 0);
    while k <> 0 do begin
      t := mmt_token_map^[k];
      bv_$and_to(mmt_bits, bb^.avail_out, t^.related, t^.compared);
      t^.next_class := list;
      list := t;
      k := bv_$find_next_val(mmt_rtn, bb^.live_out, k);
    end;
    while list <> nil do begin
      discard(mmt_utils_$mmt_seq_add_tokens_from_bv(list^.compared, true, false));
      mmt_utils_$mmt_seq_add_token(list, false, true);
      prev := list;
      q := list^.next_class;
      while q <> nil do begin
        if bv_$equal(mmt_bits, list^.compared, q^.compared) then begin
          mmt_utils_$mmt_seq_add_token(q, false, true);
          prev^.next_class := q^.next_class;
        end
        else
          prev := q;
        q := q^.next_class;
      end;
      discard(mmt_utils_$mmt_seq_emit(i, true));
      list := list^.next_class;
    end;
    bb := bb^.next114;
  end;
end;

{ get_new_lts - a new segment of lr in bb: a kept one (cleared, 52
  bytes, put first on lr's list, lr's count up and its low byte the
  segment's number) or lir_utils_$add_lts_to_lr's.  0x254ADC, 0x78
  bytes, no A5. }

function get_new_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
begin
  if mmt_free_ltss <> nil then begin
    l := mmt_free_ltss;
    mmt_free_ltss := l^.next;
    zero(l, 52);
    l^.next := lr^.ltss;
    lr^.ltss := l;
    lr^.w56 := lr^.w56 + 1;
    l^.f2.num := lr^.w56 & 255;
    l^.lr := lr;
    l^.bb := bb;
  end
  else begin
    lir_utils_$add_lts_to_lr(0, lr, bb, l);
    mmt_stats[7] := mmt_stats[7] + 1;
  end;
  get_new_lts := l;
end;

{ build_real_mmt_seq - an MMT_SEQ made in the temporary heap replaced by
  a lasting one (lir_$optimizer_new_n_opr_instr after it, its serial
  number cleared, the operands copied: number, rrp byte, value, kind).
  0x254B54, 0xA2 bytes, no A5. }

function build_real_mmt_seq(
    old: instr_ptr_t): instr_ptr_t; options(val_param); internal;
var
  n: instr_ptr_t;
  j: integer32;
begin
  n := lir_$optimizer_new_n_opr_instr(old, ord(opc$mmt_seq), true,
                                      old^.h.nopnds);
  n^.num := 0;
  for j := 1 to n^.h.nopnds do begin
    n^.opnds[j].h.num := j;
    opnd_bytes_ptr_t(addr(n^.opnds[j]))^.rrp :=
        opnd_bytes_ptr_t(addr(old^.opnds[j]))^.rrp;
    n^.opnds[j].value := old^.opnds[j].value;
    n^.opnds[j].h.kind := old^.opnds[j].h.kind;
  end;
  lir_utils_$excise_inst(old);
  mmt_stats[11] := mmt_stats[11] + 1;
  mmt_stats[5] := mmt_stats[5] + n^.h.nopnds;
  build_real_mmt_seq := n;
end;

{ mmt_$allocate_ltss_to_refs - the tokens' live ranges' segments kept
  for reuse, their counts and hints cleared; then each memory operand
  given a segment of its live range in its block: a read the live
  range's first segment when it is of the block (the read chained after
  its last reader, +40), else a new exposed one; a write a new one (an
  asynchronous token's store marking its instruction, +2 bit 3); the
  operand's rrp byte added to the segment's and the live range's.  The
  temporary MMT_SEQs made lasting first.

  0x254BF6, 0x1CE bytes, no A5: the rrp byte `or.w' unmasked. }

procedure mmt_$allocate_ltss_to_refs; internal;
var
  k, j: integer32;
  t: mmt_token_ptr_t;
  lr: lr_ptr_t;
  l, p: lts_ptr_t;
  bb: bb_ptr_t;
  i: instr_ptr_t;
  o: opnd_ptr_t;
begin
  mmt_free_ltss := nil;
  for k := 1 to mmt_count do begin
    t := mmt_token_map^[k];
    if t^.lr^.ltss <> nil then begin
      p := t^.lr^.ltss;
      while p^.next <> nil do
        p := p^.next;
      p^.next := mmt_free_ltss;
      mmt_free_ltss := t^.lr^.ltss;
      t^.lr^.ltss := nil;
    end;
    lr := t^.lr;
    lr^.w56 := 0;
    lr^.exposed_hint := nil;
    lr^.exposed_prev := nil;
    lr^.exposed := nil;
    lr^.finals := nil;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
  end;
  bb := mmt_rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      if (i^.opc = ord(opc$mmt_seq)) and i^.h.may_generate_an_exception then
        i := build_real_mmt_seq(i);
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if o^.h.kind in [operand$inscrutable_memory,
                         operand$well_behaved_memory] then begin
          if o^.h.read then begin
            lr := o^.ptr;
            if lr^.ltss <> nil then
              if lr^.ltss^.bb = bb then
                l := lr^.ltss
              else
                l := nil
            else
              l := nil;
            if l <> nil then
              opnd_ptr_t(l^.l40)^.link := o
            else begin
              l := get_new_lts(lr, bb);
              l^.refs := o;
              l^.f2.exposed := true;
            end;
          end
          else begin
            t := mmt_lr_v_ptr_t(o^.ptr)^.token;
            if t^.f.async then
              if instruction_attributes[i^.opc].class = class$store then
                i^.h.do_not_delete := true;
            l := get_new_lts(o^.ptr, bb);
            l^.refs := o;
          end;
          l^.l40 := integer32(o);
          lr := o^.ptr;
          lr^.rrp := rrp$set_t(integer(lr^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
          l^.rrp := rrp$set_t(integer(l^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
          o^.lts := l;
          o^.link := nil;
        end;
      end;
      mmt_stats[1] := mmt_stats[1] + i^.h.nopnds;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
end;

{ mmt_$points_for_good_behavior - unless switch 13, the references of
  each token's live range made well-behaved memory (kind 11) when all of
  them (MMT_SEQs aside) are loads or stores with alias descriptors, not
  marked (+2 bit 4), not modifying their base (+3 bits 7..6), and of one
  descriptor: identical to the first, which has the access's size, is
  not of class 13 and is exact.

  0x254DC4, 0x154 bytes, no A5: `cmpa.w D1,A3' tests the first
  descriptor for nil with D1 holding the class set 16#210000, whose low
  word is 0 (docs/rev889-patterns.md 105). }

procedure mmt_$points_for_good_behavior; internal;
var
  k: integer32;
  d, a: alias_$desc_ptr_t;
  lr: lr_ptr_t;
  l: lts_ptr_t;
  o: opnd_ptr_t;
  i: instr_ptr_t;
  good: boolean;
begin
  if not at_backend_switches.sw13 then
    for k := 1 to mmt_count do begin
      d := nil;
      lr := mmt_token_map^[k]^.lr;
      good := true;
      l := lr^.ltss;
      while good and (l <> nil) do begin
        o := l^.refs;
        while good and (o <> nil) do begin
          i := utils_ins_$operands_instruction(o);
          if i^.opc <> ord(opc$mmt_seq) then begin
            if not (instruction_attributes[i^.opc].class in
                    [class$load, class$store])
                or not i^.h.b2_7 or i^.h.volatile_location
                or ((i^.h.width & 16#C0) <> 0) then
              good := false
            else begin
              a := alias_$desc_ptr_t(integer32(i) - 24);
              if d <> nil then begin
                if not alias_$descriptors_are_identical(d^, a^) then
                  good := false;
              end
              else if (lshft(1, instruction_attributes[i^.opc].w18 & 7)
                       <> a^.size)
                  or (a^.class = 13) or a^.inexact then
                good := false
              else
                d := a;
            end;
          end;
          if good then
            o := o^.link;
        end;
        if good then
          l := l^.next;
      end;
      if good then begin
        l := lr^.ltss;
        while l <> nil do begin
          o := l^.refs;
          while o <> nil do begin
            o^.h.kind := operand$well_behaved_memory;
            o := o^.link;
          end;
          l := l^.next;
        end;
      end;
    end;
end;

{ mmt_$begin_compilation - the totals cleared; the classes the aliaser
  does not relate to class 13 or 12 noted; the token heap (64-byte
  items) and the temporary instruction heap (44) set up (flags 1).
  0x254F18, 0xB2 bytes: the two words in one longword (`move.l
  #0x10040'). }

procedure mmt_$begin_compilation;
var
  c: integer;
begin
  mmt_stats[10] := 0;
  mmt_stats[8] := 0;
  mmt_stats[6] := 0;
  mmt_stats[4] := 0;
  mmt_stats[2] := 0;
  mmt_stats[0] := 0;
  for c := 0 to 16 do
    if (alias_$classes_may_be_related(13, c) = 0)
        or (alias_$classes_may_be_related(12, c) = 0) then
      mmt_unrelated := mmt_unrelated + [c];
  mrh_$initialize(mmt_token_heap, 1, 64, 'MMT token descriptor head%.');
  mrh_$initialize(mmt_seq_heap, 1, 44, 'MMT temp instr heap%.');
end;

{ mmt_$process_routine - unless switch 15 or 14: the tokens allocated
  (relations dumped under switch 9), the MMT_SEQs inserted within and
  across blocks, the segments allocated, the well-behaved references
  marked; the routine's counters added to the totals, its +192 put
  back, the tokens' live ranges' numbers cleared, the vectors and heaps
  released; unless switch 11 the instructions resequenced, the global
  data flow walked and the LIR checked.

  0x254FFC, 0x1A6 bytes: the level `moveq #7; and.b' (pattern 99);
  utils_$guarantee_instr_sequence's pop leaves 2 bytes for the next
  call (pattern 51). }

procedure mmt_$process_routine(
    rtn: rtn_ptr_t);
var
  saved, k: integer32;
  st: status_$t;
begin
  if not at_backend_switches.sw15 and not at_backend_switches.sw14 then begin
    mmt_level := at_backend_switches.level;
    lir_utils_$sanity_check(rtn);
    mmt_rtn := rtn;
    mmt_mem_lr := mmt_rtn_v_ptr_t(rtn)^.mem_lr;
    saved := rtn^.l192;
    mmt_stats[11] := 0;
    mmt_stats[9] := 0;
    mmt_stats[7] := 0;
    mmt_stats[5] := 0;
    mmt_stats[3] := 0;
    mmt_stats[1] := 0;
    bv_$release_bit_vectors(rtn);
    mmt_$allocate_tokens;
    if at_backend_switches.sw9 then
      dump_related_vectors('%/%/Relationships after MMT_$ALLOCATE_TOKENS:%/%.', 0);
    mmt_$insert_intra_bb_seq;
    mmt_$insert_inter_bb_seq;
    mmt_$allocate_ltss_to_refs;
    mmt_$points_for_good_behavior;
    mmt_stats[10] := mmt_stats[10] + mmt_stats[11];
    mmt_stats[8] := mmt_stats[8] + mmt_stats[9];
    mmt_stats[6] := mmt_stats[6] + mmt_stats[7];
    mmt_stats[4] := mmt_stats[4] + mmt_stats[5];
    mmt_stats[2] := mmt_stats[2] + mmt_stats[3];
    mmt_stats[0] := mmt_stats[0] + mmt_stats[1];
    rtn^.l192 := saved;
    for k := 1 to mmt_count do
      mmt_token_map^[k]^.lr^.id := 0;
    bv_$release_bit_vectors(rtn);
    rws_$release_heap(mmt_token_map, st);
    rws_$release_heap(mmt_scratch, st);
    mrh_$release_all(mmt_seq_heap);
    mrh_$release_all(mmt_token_heap);
    if not at_backend_switches.sw11 then begin
      utils_$guarantee_instr_sequence(rtn);
      df_utils_$global_walk(rtn, rtn^.l192, 1, 0);
      lir_utils_$sanity_check(rtn);
    end;
  end;
end;

{ mmt_$end_routine - nothing.  0x2551D4, 2 bytes. }

procedure mmt_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ mmt_$end_compilation - nothing.  0x2551D6, 2 bytes. }

procedure mmt_$end_compilation;
begin
end;
