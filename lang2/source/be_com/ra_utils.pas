{ ra_utils - the register allocator's utilities (cc.a88k only): the
  complex live ranges' lifetimes narrowed to where they are available,
  rematerialization (a value recomputed by a copy of its one defining
  instruction instead of reloaded), the pass-through spilling XTP asks
  for before scheduling (live ranges that pass through a hammock
  without being used there, while the hammock needs more registers
  than there are, are stored before it and reloaded after it), and
  the spill code itself (ra_utils_$add_spill_code: each read of a
  spilled live range gets a reload into a new live range before it,
  each write a store after it, readers close enough sharing a reload;
  a spilled live range's loops broken first, its segments in loop
  bodies given a live range of their own joined by preference moves).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x26DF24  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x26DF46  ra_utils_$begin_compilation
    --------  0x26DF48  ra_utils_$init_for_routine
    --------  0x26DF4A  ra_utils_$end_routine
    --------  0x26DF4C  ra_utils_$end_compilation
    --------  0x26DF4E  init (internal)
    --------  0x26DF68  rws_alloc (internal)
    --------  0x26DFC0  ra_utils_$compute_complex_lifetimes
    --------  0x26E042  get_memory_token (internal)
    --------  0x26E182  get_instr_and_build_address_mode (internal)
    --------  0x26E468  spill_the_victims (internal)
    --------  0x26E764  compute_high_level_pass_through (internal)
    --------  0x26E932  compute_pass_through (internal)
    --------  0x26EADE  count_hammocks (internal)
    --------  0x26EB14  assign_bit_vectors_to_hammocks (internal)
    --------  0x26EB86  initialize_hammock_data (internal)
    --------  0x26EC9A  choose_spill_cost (internal)
    --------  0x26EE12  spill_something (internal)
    --------  0x26EF38  enclosing_intervals_are_hammocks (internal)
    --------  0x26EF88  spill_around_hammocks (internal)
    --------  0x26F0E8  coalesce_spill_victims (internal)
    --------  0x26F2D0  drop_unneeded_stores (internal)
    --------  0x26F362  compute_dominating_definitions (internal)
    --------  0x26F3C8  choose_spill_victims (internal)
    --------  0x26F488  ra_utils_$spill_pass_through_lrs
    --------  0x26F6EE  ra_utils_$rematerialize
    --------  0x26F9D6  get_new_spill_lr (internal)
    --------  0x26FA82  get_new_spill_lts (internal)
    --------  0x26FAA2  rematerialize_result (internal)
    --------  0x26FE44  find_mate_lts (internal)
    --------  0x26FEDC  get_new_mate_lts (internal)
    --------  0x26FF5E  pick_instruction (internal)
    --------  0x2700D0  look_for_lts (internal)
    --------  0x27011A  attach_lts_list_to_new_lr (internal)
    --------  0x27013C  find_best_dom_bb (internal)
    --------  0x2701B8  break_one_loop (internal)
    --------  0x27033A  break_loops_from_spill_victim (internal)
    --------  0x2707E4  rebuild_db_exposed_lts_list (internal)
    --------  0x270818  find_modify_opr (internal)
    --------  0x2708FC  link_other_readers (internal)
    --------  0x270ABE  choose_store_position (internal)
    --------  0x270E2E  no_reg_pair_problem (internal)
    --------  0x270E6C  fill_intend_modify (internal)
    --------  0x270E82  new_db_lts (in ra_utils_$add_spill_code)
    --------  0x270F0C  ra_utils_$add_spill_code
    A5 0x48FAF4 (0x214 bytes): the register kinds of each spill class
    (+0, initialized: 1-based, ip_reg; fp_reg and fp_reg_pair twice),
    lir_$build_operand's record for the spill code (+0x10, 432 bytes,
    backend.ins.pas ra_utils_10: only lir and lir_utils use it), and the
    pass-through spilling's cells (+448 .. +524, below).  +12 and +516
    (three initialized characters, 'ISD') are not referenced.

  The pass-through spilling (XTP, before SCHED and RA) keeps nine bit
  vectors of complex live ranges and two for each hammock (hal's
  records, 38 bytes: ru_ham_t reads +24 .. +36, which hal leaves
  unset): the live ranges that pass through it untouched and those
  already spilled around it.  A hammock whose blocks need more integer
  or floating registers than the target has (target_properties
  +0x26 and +0x46, 24 and 64 for the PRISM; nine tenths of them with
  lir_main_da4) has live ranges passing through it spilled around it:
  rematerializable ones first, then those with one definition and no
  modify, then the rest.  docs/prism-isa.md describes the model.

  During RA a live range's +72 is its first definition (chained at the
  segments' +36), its +28 its spill cost (a single real: 0.0 when it is
  rematerialized, 1.0 otherwise) and its +60 the instruction it is
  rematerialized by; an instruction's +29 and +31 are the floating and
  integer registers live at it (dmp's four counts at +28); a block's
  +2 and +6 the most of each live in it (dmp's max live).  These are
  batch A's records, read through views (ru_lr_t, ru_lts_t, ru_instr_t,
  ru_bb_t, ru_rtn_t).  An operand made by the spill code holds a live
  range (not a segment) at +8 until utils_$complete_copied_instr makes
  the segment.

  Not known from the original: every local, parameter, type and module
  variable name; the views' field names; the source of the 0.9 and 0.75
  and 0.6 factors (FPP words, docs/dpc-gaps.md 7). }
module ra_utils;

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
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang2/source/be_com/lir.pvt.pas';
%include 'lang2/source/be_com/ra.pvt.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { Instruction classes as the image's masks group them. }
  ru_branchy = [class$branch, class$fp_branch, class$jump,
      class$return];                    { 0x1000062 }
  ru_fp_ops = [class$fp_double, class$immediate,
      class$fp_single];                 { 0x20108 }

  { Operand kinds as the image's masks group them. }
  ru_not_reg = [operand$none, operand$flow_graph_edge ..
      operand$immediate, operand$spare_3];      { 0x10FF0001 }
  ru_regs = [operand$ip_reg .. operand$fp_reg_pair_physical];    { 126 }
  ru_reg_or_mem = [operand$ip_reg ..
      operand$well_behaved_memory];     { 4094 }
  ru_ip_kinds = [operand$ip_reg, operand$ip_reg_physical,
      operand$ip_reg_like, operand$case_jump_base];    { 0x21012 }
  ru_singles = [operand$fp_reg, operand$fp_reg_physical,
      operand$fp_reg_like];             { 8228 }
  ru_pairs = [operand$fp_reg_pair, operand$fp_reg_pair_physical,
      operand$fp_reg_pair_like];        { 16456 }
  ru_movable = [operand$ip_reg .. operand$fp_reg_pair_physical,
      operand$ip_reg_like .. operand$fp_reg_pair_like,
      operand$case_jump_base];          { 0x2707E }

type
  { lr_t (batch A's) as the allocator uses it: the spill cost (+28, a
    single real), the instruction that rematerializes it (+60), its
    first definition (+72, the next at the segment's +36).  The cost's
    longword view (i) serves the gate's gap 7 rewrite only. }
  ru_cost_t = record
    case integer of
      1: (r: real);
      2: (i: integer32);
  end;
  ru_lts_ptr_t = ^ru_lts_t;
  ru_lr_ptr_t = ^ru_lr_t;
  ru_lr_t = record
    space0: array [0..27] of char;
    cost: ru_cost_t;                    { +28 }
    space32: array [32..59] of char;
    remat: instr_ptr_t;                 { +60 }
    space64: array [64..71] of char;
    defs: lts_ptr_t;                    { +72 }
  end;
  ru_lts_t = record
    space0: array [0..35] of char;
    next_def: lts_ptr_t;                { +36 }
  end;

  { The first longword of a live range or a segment as bytes: b1 the
    low byte of rrp (bits 1..0: fp_reg_odd_only, fp_reg_even_only). }
  ru_bytes_ptr_t = ^ru_bytes_t;
  ru_bytes_t = packed record
    b0: 0..255;
    b1: 0..255;
    b2: 0..255;
    b3: 0..255;
  end;

  { An instruction's counts during RA (dmp's +28..+31). }
  ru_instr_ptr_t = ^ru_instr_t;
  ru_instr_t = record
    space0: array [0..27] of char;
    b28: char;                          { +28 }
    fp_live: char;                      { +29 }
    b30: char;                          { +30 }
    ip_live: char;                      { +31 }
  end;

  { A block's register counts (dmp's dmp_bb_t). }
  ru_bb_ptr_t = ^ru_bb_t;
  ru_bb_t = packed record
    live_in_ip: 0..255;                 { +0 }
    live_out_ip: 0..255;
    max_ip: 0..255;                     { +2 }
    pass_ip: 0..255;
    live_in_fp: 0..255;
    live_out_fp: 0..255;
    max_fp: 0..255;                     { +6 }
    pass_fp: 0..255;
  end;

  { The routine's live ranges batch A has not named: +116 (the stack
    frame's, dbg_life) and +120. }
  ru_rtn_ptr_t = ^ru_rtn_t;
  ru_rtn_t = record
    space0: array [0..115] of char;
    lr116: lr_ptr_t;                    { +116 }
    lr120: lr_ptr_t;                    { +120 }
  end;

  { A hammock (hal's 38-byte record, hal_hammock_t's fields and what
    the pass-through spilling keeps after them). }
  ru_ham_ptr_t = ^ru_ham_t;
  ru_ham_t = record
    head: bb_ptr_t;                     { +0 }
    tail: bb_ptr_t;                     { +4 }
    parent: ru_ham_ptr_t;               { +8 }
    child: ru_ham_ptr_t;                { +12 }
    next: ru_ham_ptr_t;                 { +16 }
    prev: ru_ham_ptr_t;                 { +20 }
    pass: bv_ptr_t;                     { +24: live through, untouched }
    spilled: bv_ptr_t;                  { +28: spilled around it }
    ip: integer;                        { +32: integer registers needed }
    fp: integer;                        { +34: floating registers needed }
    done: boolean;                      { +36 }
  end;

  { A reload's facts (add_spill_code's word at -106, passed to
    pick_instruction): adjust the bytes added to the reload's
    displacement (2 or 3 for a 16- or 8-bit part, 4 a single's odd
    half); clear the reader's +2 bit 6 afterwards, a new live range made,
    the reader's own segment kept (keep), the reader sets the condition
    codes, the reload takes 8 or 16 bits (bits 3, 2). }
  ru_fl_t = record
    case integer of
      1: (w: integer);                  { the word (cleared, set to 128,
                                          `andi.w #-145') }
      2: (f: packed record
            adjust: 0..255;             { -106 }
            clear: boolean;             { -105 .7 }
            new_lr: boolean;            { .6 }
            keep: boolean;              { .5 }
            sets_cc: boolean;           { .4 }
            byte8: boolean;             { .3 }
            half16: boolean;            { .2 }
            b1, b0: boolean;
            end);
  end;

  { instruction_attributes' operand descriptions as the delays read
    them (sched_utils' su_attr_t): the delay is +4k+2 bits 5..2. }
  ru_attr_opnd_t = packed record
    form: 0..255;                       { +4k }
    num: 0..255;                        { +4k+1 }
    kind2: 0..3;                        { +4k+2 .7..6 }
    delay: 0..15;                       { .5..2 }
    b2_1_0: 0..3;
    b3: 0..255;                         { +4k+3 }
  end;
  ru_attr_ptr_t = ^ru_attr_t;
  ru_attr_t = record
    w0: 0..65535;                       { +0 }
    w2: 0..65535;                       { +2 }
    opnds: array [1..4] of ru_attr_opnd_t;   { +4 }
  end;

  { spill_instr_forms' load_ptrs or store_ptrs (lir.pvt.pas). }
  ru_forms_ptr_t = ^ru_forms_t;
  ru_forms_t = array [0..6] of spill_desc_ptr_t;

  ru_kinds_t = set of operand$t;
  ru_ptrs_t = array [1..65535] of univ_ptr;
  ru_ptrs_ptr_t = ^ru_ptrs_t;

define
  ra_utils_10;                          { +0x10 }

var
  ru_kinds: array [operand$ip_reg .. operand$fp_reg_pair] of ru_kinds_t
      := [[operand$ip_reg], [operand$fp_reg, operand$fp_reg_pair],
          [operand$fp_reg, operand$fp_reg_pair]];  { +0 }
  ru_0c: integer32;                     { +12 }
  ru_unique: bv_ptr_t;                  { +448: unique values }
  ru_single_def: bv_ptr_t;              { +452: one definition, no
                                          modify, not available where
                                          read }
  ru_cand_ip: bv_ptr_t;                 { +456 }
  ru_cand_fp: bv_ptr_t;                 { +460 }
  ru_work: bv_ptr_t;                    { +464 }
  ru_pass: bv_ptr_t;                    { +468: also the space of
                                          ru_single_def }
  ru_remat: ru_ptrs_ptr_t;              { +472: by complex id, the
                                          rematerializing instruction }
  ru_homes: ru_ptrs_ptr_t;              { +476: by complex id, the memory
                                          home }
  ru_rtn: rtn_ptr_t;                    { +480 }
  ru_mem_fp: bv_ptr_t;                  { +484 }
  ru_remat_fp: bv_ptr_t;                { +488 }
  ru_mem_ip: bv_ptr_t;                  { +492 }
  ru_remat_ip: bv_ptr_t;                { +496 }
  ru_bytes: integer32;                  { +500: a vector's bytes }
  ru_bits: integer32;                   { +504: its bits }
  ru_ham_space: univ_ptr;               { +508 }
  ru_empty: bv_ptr_t;                   { +512 }
  ru_204: packed array [1..3] of char := 'ISD';   { +516 }
  ru_nip: integer;                      { +520 }
  ru_nfp: integer;                      { +522 }
  ru_depth: integer32 := 0;             { +524 }

{ RA_UTILS_$BEGIN_COMPILATION, _INIT_FOR_ROUTINE, _END_ROUTINE,
  _END_COMPILATION - nothing.  0x26DF46, 0x26DF48, 0x26DF4A, 0x26DF4C,
  2 bytes each (no A5). }

procedure ra_utils_$begin_compilation;
begin
end;

procedure ra_utils_$init_for_routine;
begin
end;

procedure ra_utils_$end_routine;
begin
end;

procedure ra_utils_$end_compilation;
begin
end;

{ init - n bytes from p set to v, a longword at a time ((n + 3) div 4
  of them; nothing for 0): rev889-patterns 100 with a value.

  0x26DF4E, 0x1A bytes, internal, no frame: p at (4,SP), n (8), v
  (12); the `beq' on n's move. }

procedure init(
    p: univ_ptr;
    n: integer32;
    v: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := v;
  end;
end;

{ rws_alloc - n bytes of the heap (a bug check when there is none).

  0x26DF68, 0x2E bytes, internal: n by value, passed by address to
  rws_$alloc_heap; A0. }

function rws_alloc(
    n: integer32): univ_ptr; options(val_param); internal;
var
  p: univ_ptr;
begin
  p := rws_$alloc_heap(n);
  if p = nil then
    bug_check('RA_UTILS_$rws_alloc -- no disk space?%$');
  rws_alloc := p;
end;

{ RA_UTILS_$COMPUTE_COMPLEX_LIFETIMES - the lifetimes and availability
  propagated (the latter on any path), then each block's live_in and
  live_out narrowed to the live ranges available on entry and exit.

  0x26DFC0, 0x82 bytes: the bits l192 + 1 at -4; `addql #6,SP' leaves
  the next call's word (pattern 51). }

procedure ra_utils_$compute_complex_lifetimes;
var
  n: integer32;
  bb: bb_ptr_t;
begin
  n := rtn^.l192 + 1;
  bv_$propagate_lifetimes(n, rtn);
  bv_$propagate_availability(n, rtn, true);
  bb := rtn^.bbs72;
  while bb <> nil do begin
    bv_$and(n, bb^.avail_in, bb^.live_in);
    bv_$and(n, bb^.avail_out, bb^.live_out);
    bb := bb^.next114;
  end;
end;

{ get_memory_token - a new live range standing for memory: an MMT_SEQ
  put after the LIMIT of each successor of the routine's first block
  writes it (operand 2, inscrutable memory) and reads the LIMIT's own
  inscrutable memory operand (operand 1, linked after it).

  0x26E042, 0x140 bytes, internal: the token in D5, the successors in
  D4; the search for the LIMIT's memory operand counts down from the
  last (`dbf', the longword idiom). }

function get_memory_token: lr_ptr_t; internal;
label
  10;
var
  tok: lr_ptr_t;
  e: fg_edge_ptr_t;
  bb: bb_ptr_t;
  i: instr_ptr_t;
  seq: instr_ptr_t;
  k: integer32;
begin
  tok := lir_$new_live_range;
  e := ru_rtn^.bbs^.succs;
  while e <> nil do begin
    bb := e^.target;
    i := bb^.first;
    while i <> nil do begin
      if i^.opc = ord(opc$limit) then
        goto 10;
      i := i^.next;
    end;
10:
    if i <> nil then begin
      seq := lir_$optimizer_new_n_opr_instr(i, ord(opc$mmt_seq), true, 2);
      seq^.opnds[2].h.num := 2;
      seq^.opnds[2].h.kind := operand$inscrutable_memory;
      seq^.opnds[2].lts := utils_$get_new_lts(tok, bb, false);
      seq^.opnds[2].lts^.refs := addr(seq^.opnds[2]);
      seq^.opnds[2].lts^.rrp := seq^.opnds[2].lts^.rrp + [rrp$write];
      opnd_bytes_ptr_t(addr(seq^.opnds[2]))^.rrp := 8;
      for k := i^.h.nopnds downto 1 do
        if i^.opnds[k].h.kind = operand$inscrutable_memory then begin
          seq^.opnds[1].h.num := 1;
          seq^.opnds[1].h.kind := operand$inscrutable_memory;
          seq^.opnds[1].lts := i^.opnds[k].lts;
          seq^.opnds[1].link := i^.opnds[k].link;
          i^.opnds[k].link := addr(seq^.opnds[1]);
          seq^.opnds[1].lts^.rrp := seq^.opnds[1].lts^.rrp + [rrp$read];
          opnd_bytes_ptr_t(addr(seq^.opnds[1]))^.rrp := 16;
          exit;
        end;
    end;
    e := e^.next_succ;
  end;
  get_memory_token := tok;
end;

{ get_instr_and_build_address_mode - a load or store (opc) of lr's
  memory home, in bb at its head (after its join birthpoints and labels)
  or at its end (before its closing transfers): the displacement (a
  stack frame displacement of the home's node, +4 for the odd half of a
  pair kept as singles), the base (the frame register's segment,
  asm_658, read) and memory (tok: a load reads it, a store reads it to
  modify it and modifies it).  The memory home is made the first time
  (by complex id), and kept only for unique values: otherwise lr's is
  cleared and the variable's node flagged (+34 or +26 bit 3).  The
  register operand is left to the caller.

  0x26E182, 0x2E6 bytes, internal: lr (8), bb (12), opc a word (16),
  at_head a byte (18), tok (20); A0.  The displacement and base are
  operands 1 and 2 of a load, 2 and 3 of a store; memory the last
  operand (less one when the opcode's b14_0). }

function get_instr_and_build_address_mode(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    opc: integer;
    at_head: boolean;
    tok: lr_ptr_t): instr_ptr_t; options(val_param); internal;
label
  10;
type
  ru_node_ptr_t = ^ru_node_t;
  ru_node_t = record
    space0: array [0..1] of char;
    kind: integer;                      { +2 }
    space4: array [4..25] of char;
    b26: char;                          { +26 (FORTRAN symbol) }
    b27: char;
    space28: array [28..33] of char;
    b34: char;                          { +34 (VAR_NAME) }
  end;
var
  home: univ_ptr;
  h: ru_node_ptr_t;
  instr: instr_ptr_t;
  a: instr_ptr_t;
  p: instr_ptr_t;
  d, b: integer32;
begin
  if ru_homes^[lr^.id] = nil then begin
    lir_utils_$add_memory_home(ru_rtn, lr, false);
    ru_homes^[lr^.id] := lr^.memory_home;
    if lr^.mate <> nil then
      ru_homes^[lr^.mate^.id] := ru_homes^[lr^.id];
    if not bv_$test(ru_unique, lr) then begin
      lr^.memory_home := nil;
      if lr^.mate <> nil then
        lr^.mate^.memory_home := nil;
    end
    else if (lr^.mate <> nil) and not bv_$test(ru_unique, lr^.mate) then begin
      lr^.memory_home := nil;
      lr^.mate^.memory_home := nil;
    end
    else begin
      h := lr^.memory_home;
      if h^.kind = 109 then
        h^.b34 := chr(ord(h^.b34) ! 8)
      else if h^.kind = 110 then
        h^.b26 := chr(ord(h^.b26) ! 8);
    end;
  end;
  home := ru_homes^[lr^.id];
  instr := lir_$get_new_instruction_no_exceptions(nil, opc, 16#2000, home, nil);
  instr^.bb := bb;
  instr^.h.b2_6 := true;
  if at_head then begin
    a := bb^.first;
    while (a^.opc = ord(opc$join_bp)) or (a^.opc = ord(opc$label)) do
      a := a^.next;
  end
  else begin
    a := bb^.last;
    while a^.prev <> nil do begin
      if not (instruction_attributes[a^.prev^.opc].class in ru_branchy) then
        goto 10;
      a := a^.prev;
    end;
  end;
10:
  p := a^.prev;
  instr^.prev := p;
  if p = nil then
    bb^.first := instr
  else
    p^.next := instr;
  instr^.next := a;
  a^.prev := instr;
  if instruction_attributes[opc].class = class$load then begin
    d := 1;
    b := 2;
  end
  else begin
    d := 2;
    b := 3;
  end;
  instr^.opnds[d].h.num := d;
  instr^.opnds[d].h.kind := operand$displacement_stack_frame;
  instr^.opnds[d].link := home;
  if (rrp$fp_reg_odd_only in lr^.rrp) and (lr^.mate <> nil) and
     ((instruction_attributes[opc].w18 & 7) <> 3) then
    instr^.opnds[d].value := 4;
  instr^.opnds[b].h.num := b;
  instr^.opnds[b].h.kind := operand$ip_reg_like;
  instr^.opnds[b].value := asm_658;
  opnd_bytes_ptr_t(addr(instr^.opnds[b]))^.rrp := 16;
  if instruction_attributes[instr^.opc].b14_0 then
    d := instr^.h.nopnds - 1
  else
    d := instr^.h.nopnds;
  if instruction_attributes[opc].class = class$load then begin
    instr^.opnds[d].h.num := d;
    instr^.opnds[d].h.kind := operand$inscrutable_memory;
    instr^.opnds[d].ptr := tok;
    opnd_bytes_ptr_t(addr(instr^.opnds[d]))^.rrp := 16;
  end
  else begin
    instr^.opnds[d - 1].h.num := d - 1;
    instr^.opnds[d - 1].h.kind := operand$inscrutable_memory;
    instr^.opnds[d - 1].ptr := tok;
    opnd_bytes_ptr_t(addr(instr^.opnds[d - 1]))^.rrp := 48;
    instr^.opnds[d].h.num := d;
    instr^.opnds[d].h.kind := operand$inscrutable_memory;
    instr^.opnds[d].ptr := tok;
    opnd_bytes_ptr_t(addr(instr^.opnds[d]))^.rrp := 4;
  end;
  get_instr_and_build_address_mode := instr;
end;

{ spill_the_victims - for each block, the live ranges chosen to be live
  on its entry (live_in, now the reloads) reloaded at its head (or
  rematerialized there by a copy of their instruction), and those to be
  live on its exit (live_out, the stores) stored at its end; a pair's
  odd half goes with its even half (a double load or store) when both
  are chosen.  Whether anything was done.

  0x26E468, 0x2B2 bytes, internal: the token in D5 (made when first
  needed), the flag in D2; D0.  The reloads' at_head argument is D2,
  just set (true). }

function spill_the_victims: boolean; internal;
var
  size: integer32;
  tok: lr_ptr_t;
  any: boolean;
  bb: bb_ptr_t;
  lr: lr_ptr_t;
  r: instr_ptr_t;
  instr: instr_ptr_t;
  opc: integer;
  kind: operand$t;
  st: status_$t;
begin
  size := ru_rtn^.l192 * 4;
  ru_homes := rws_alloc(size);
  init(ru_homes, size, 0);
  tok := nil;
  any := false;
  bb := ru_rtn^.bbs;
  while bb <> nil do begin
    lr := nil;
    repeat
      lr := bv_$find_next(ru_rtn, bb^.live_in, lr);
      if lr <> nil then
        if not ((rrp$fp_reg_odd_only in lr^.rrp) and (lr^.mate <> nil) and
                bv_$test(bb^.live_in, lr^.mate)) then begin
          any := true;
          r := ru_remat^[lr^.id];
          if r <> nil then
            utils_$complete_copied_instr_at_bb_head(
                utils_$copy_instr_template_to_bb_head(r, bb))
          else begin
            if rrp$ip_reg in lr^.rrp then begin
              opc := ord(opc$loadl);
              kind := operand$ip_reg;
            end
            else if (lr^.mate = nil) or not bv_$test(bb^.live_in, lr^.mate) then begin
              opc := ord(opc$loads);
              kind := operand$fp_reg;
            end
            else begin
              opc := ord(opc$loadd);
              kind := operand$fp_reg_pair;
            end;
            if tok = nil then
              tok := get_memory_token;
            instr := get_instr_and_build_address_mode(lr, bb, opc, true, tok);
            instr^.opnds[3].h.num := 3;
            instr^.opnds[3].h.kind := kind;
            instr^.opnds[3].ptr := lr;
            opnd_bytes_ptr_t(addr(instr^.opnds[3]))^.rrp :=
                (ru_bytes_ptr_t(lr)^.b1 & 3) ! 8;
            if opc = ord(opc$loadd) then begin
              instr^.opnds[4].h.num := 4;
              instr^.opnds[4].h.kind := kind;
              instr^.opnds[4].ptr := lr^.mate;
              opnd_bytes_ptr_t(addr(instr^.opnds[4]))^.rrp :=
                  (ru_bytes_ptr_t(lr^.mate)^.b1 & 3) ! 8;
            end;
            utils_$complete_copied_instr_at_bb_head(instr);
          end;
        end;
    until lr = nil;
    lr := nil;
    repeat
      lr := bv_$find_next(ru_rtn, bb^.live_out, lr);
      if lr <> nil then
        if not ((rrp$fp_reg_odd_only in lr^.rrp) and (lr^.mate <> nil) and
                bv_$test(bb^.live_out, lr^.mate)) then begin
          any := true;
          if ru_remat^[lr^.id] <> nil then
            bug_check('RA_UTILS_$spill_the_victims:  STORE requested for rematerializable LR%$');
          if rrp$ip_reg in lr^.rrp then begin
            opc := ord(opc$storel);
            kind := operand$ip_reg;
          end
          else if (lr^.mate = nil) or not bv_$test(bb^.live_out, lr^.mate) then begin
            opc := ord(opc$stores);
            kind := operand$fp_reg;
          end
          else begin
            opc := ord(opc$stored);
            kind := operand$fp_reg_pair;
          end;
          if tok = nil then
            tok := get_memory_token;
          instr := get_instr_and_build_address_mode(lr, bb, opc, false, tok);
          instr^.opnds[1].h.num := 1;
          instr^.opnds[1].h.kind := kind;
          instr^.opnds[1].ptr := lr;
          opnd_bytes_ptr_t(addr(instr^.opnds[1]))^.rrp :=
              (ru_bytes_ptr_t(lr)^.b1 & 3) ! 16;
          if opc = ord(opc$stored) then begin
            instr^.opnds[4].h.num := 4;
            instr^.opnds[4].h.kind := kind;
            instr^.opnds[4].ptr := lr^.mate;
            opnd_bytes_ptr_t(addr(instr^.opnds[4]))^.rrp :=
                (ru_bytes_ptr_t(lr^.mate)^.b1 & 3) ! 16;
          end;
          utils_$complete_copied_instr(instr);
        end;
    until lr = nil;
    bb := bb^.next;
  end;
  rws_$release_heap(ru_homes, st);
  spill_the_victims := any;
end;

{ compute_high_level_pass_through - h's pass-through set and register
  needs from its children (once: done), recursively: the live ranges
  that pass through every child and through the blocks between one
  child's tail and the next's head (when they are the same block;
  otherwise nothing passes through, nor through a hammock that starts
  the routine or ends at its final block), the most registers any of
  them needs; then or-ed into ru_pass.

  0x26E764, 0x17C bytes, internal: h (8) in D5, the flag in D2, the
  needs in D3, D4 (children's signed, blocks' unsigned); the children
  must be in postorder of their heads (bb +12). }

procedure compute_high_level_pass_through(
    h: ru_ham_ptr_t); options(val_param); internal;
var
  changed: boolean;
  pass: bv_ptr_t;
  c: ru_ham_ptr_t;
  ip, fp: integer;
  t: bb_ptr_t;
begin
  changed := false;
  pass := h^.pass;
  c := h^.child;
  if h^.done then
    while c <> nil do begin
      compute_high_level_pass_through(c);
      c := c^.next;
    end
  else begin
    ip := 0;
    fp := 0;
    while c <> nil do begin
      compute_high_level_pass_through(c);
      if c^.ip > ip then
        ip := c^.ip;
      if c^.fp > fp then
        fp := c^.fp;
      bv_$and(ru_bits, c^.pass, pass);
      if c^.prev <> nil then begin
        if c^.head^.order < c^.prev^.head^.order then
          bug_check('RA_UTILS_$compute_high_level_pass_through: hammocks must be linked in postorder%$');
        if c^.tail <> c^.prev^.head then
          changed := true
        else begin
          t := c^.tail;
          bv_$and(ru_bits, t^.transparent, pass);
          bv_$and(ru_bits, t^.live_in, pass);
          bv_$and(ru_bits, t^.live_out, pass);
          bv_$subtract(ru_bits, t^.live_gen, pass);
          if ru_bb_ptr_t(t)^.max_ip > ip then
            ip := ru_bb_ptr_t(t)^.max_ip;
          if ru_bb_ptr_t(t)^.max_fp > fp then
            fp := ru_bb_ptr_t(t)^.max_fp;
        end;
      end;
      c := c^.next;
    end;
    h^.ip := ip;
    h^.fp := fp;
    h^.done := true;
  end;
  if changed or (h^.head^.f14.kind = 1) or (h^.tail^.f14.kind = 2) then
    init(pass, ru_bytes, 0);
  bv_$or(ru_bits, pass, ru_pass);
end;

{ compute_pass_through - each hammock head's hammock (bb +98): the live
  ranges that pass through all its blocks untouched (+102, chained at
  +106; an inner hammock's set and needs taken whole) and the most
  registers its blocks need; then the higher levels from lir_main_c70.

  0x26E932, 0x14E bytes, internal: the blocks from rtn +72 (chained at
  +114), the needs in D2, D3. }

procedure compute_pass_through; internal;
var
  bb: bb_ptr_t;
  b: bb_ptr_t;
  h: ru_ham_ptr_t;
  pass: bv_ptr_t;
  ip, fp: integer;
begin
  bb := ru_rtn^.bbs72;
  while bb <> nil do begin
    if bb^.f.hammock_entry then begin
      ip := 0;
      h := ru_ham_ptr_t(bb^.l98);
      fp := ip;
      pass := h^.pass;
      b := bb^.l102;
      while b <> nil do begin
        if ru_bb_ptr_t(b)^.max_ip > ip then
          ip := ru_bb_ptr_t(b)^.max_ip;
        if ru_bb_ptr_t(b)^.max_fp > fp then
          fp := ru_bb_ptr_t(b)^.max_fp;
        bv_$and(ru_bits, b^.transparent, pass);
        bv_$and(ru_bits, b^.live_in, pass);
        bv_$and(ru_bits, b^.live_out, pass);
        bv_$subtract(ru_bits, b^.live_gen, pass);
        if b^.f.hammock_entry then begin
          if not ru_ham_ptr_t(b^.l98)^.done then
            bug_check('RA_UTILS_$compute_pass_through:  encountered uninitialized hammock, BB#%3ZWD, head BB#%3ZWD%$',
                      b^.num, bb^.num);
          bv_$and(ru_bits, ru_ham_ptr_t(b^.l98)^.pass, pass);
          h := ru_ham_ptr_t(b^.l98);
          if h^.ip > ip then
            ip := h^.ip;
          if h^.fp > fp then
            fp := h^.fp;
        end;
        b := b^.l106;
      end;
      ru_ham_ptr_t(bb^.l98)^.ip := ip;
      ru_ham_ptr_t(bb^.l98)^.fp := fp;
      ru_ham_ptr_t(bb^.l98)^.done := true;
    end;
    bb := bb^.next114;
  end;
  h := ru_ham_ptr_t(lir_main_c70);
  while h <> nil do begin
    compute_high_level_pass_through(h);
    h := h^.next;
  end;
end;

{ count_hammocks - the hammocks in h's list and below.

  0x26EADE, 0x36 bytes, internal: D0. }

function count_hammocks(
    h: ru_ham_ptr_t): integer32; options(val_param); internal;
var
  n: integer32;
begin
  n := 0;
  while h <> nil do begin
    n := n + (count_hammocks(h^.child) + 1);
    h := h^.next;
  end;
  count_hammocks := n;
end;

{ assign_bit_vectors_to_hammocks - two vectors from p for each hammock
  in h's list and below: pass (all ones) and spilled (empty), done
  cleared.

  0x26EB14, 0x72 bytes, internal: h (8), p (12) by address. }

procedure assign_bit_vectors_to_hammocks(
    h: ru_ham_ptr_t;
    var p: integer32); options(val_param); internal;
begin
  while h <> nil do begin
    h^.done := false;
    h^.pass := bv_ptr_t(p);
    init(h^.pass, ru_bytes, -1);
    p := p + ru_bytes;
    h^.spilled := bv_ptr_t(p);
    init(h^.spilled, ru_bytes, 0);
    p := p + ru_bytes;
    assign_bit_vectors_to_hammocks(h^.child, p);
    h := h^.next;
  end;
end;

{ initialize_hammock_data - the nine vectors and two for each hammock,
  from one block of the heap, and the hammocks' pass-through sets;
  false when there are no hammocks.

  0x26EB86, 0x114 bytes, internal: D0.  The product by m$mis$lll; the
  vectors' places computed from the base each time. }

function initialize_hammock_data: boolean; internal;
var
  n: integer32;
  base: integer32;
  p: integer32;
begin
  n := count_hammocks(ru_ham_ptr_t(lir_main_c70));
  if n = 0 then begin
    initialize_hammock_data := false;
    return;
  end;
  ru_ham_space := rws_alloc((n + n + 9) * ru_bytes);
  init(ru_ham_space, ru_bytes * 9, 0);
  base := integer32(ru_ham_space);
  ru_work := bv_ptr_t(base);
  ru_remat_ip := bv_ptr_t(base + ru_bytes);
  ru_mem_ip := bv_ptr_t(base + ru_bytes * 2);
  ru_remat_fp := bv_ptr_t(base + ru_bytes * 3);
  ru_mem_fp := bv_ptr_t(base + ru_bytes * 4);
  ru_empty := bv_ptr_t(base + ru_bytes * 5);
  ru_unique := bv_ptr_t(base + ru_bytes * 6);
  ru_cand_fp := bv_ptr_t(base + ru_bytes * 7);
  ru_cand_ip := bv_ptr_t(base + ru_bytes * 8);
  p := base + ru_bytes * 9;
  assign_bit_vectors_to_hammocks(ru_ham_ptr_t(lir_main_c70), p);
  compute_pass_through;
  initialize_hammock_data := true;
end;

{ choose_spill_cost - for each live range in v not marked never to
  spill (the routine's +100, +108, +112, +120 are so marked first): its
  rematerializing instruction (by complex id) and cost 0.0, or cost 1.0;
  it goes in the rematerializable or the memory vector of its register
  file; a unique value is a candidate, otherwise a live range is not
  when it has no definition, more than one, or a modify.  The candidate
  vectors are the memory ones less the others.

  0x26EC9A, 0x178 bytes, internal: v (8); the costs stored as single
  reals (`clrl', `move.l #0x3F800000'). }

procedure choose_spill_cost(
    v: bv_ptr_t); options(val_param); internal;
var
  size: integer32;
  lr: lr_ptr_t;
  r: instr_ptr_t;
begin
  size := ru_rtn^.l192 * 4;
  ru_remat := rws_alloc(size);
  init(ru_remat, size, 0);
  lr_ptr_t(ru_rtn^.l112)^.rrp := lr_ptr_t(ru_rtn^.l112)^.rrp + [rrp$life_mark];
  ru_rtn^.db_lr^.rrp := ru_rtn^.db_lr^.rrp + [rrp$life_mark];
  ru_rtn^.ap_lr^.rrp := ru_rtn^.ap_lr^.rrp + [rrp$life_mark];
  ru_rtn_ptr_t(ru_rtn)^.lr120^.rrp := ru_rtn_ptr_t(ru_rtn)^.lr120^.rrp + [rrp$life_mark];
  lr := nil;
  repeat
    lr := bv_$find_next(ru_rtn, v, lr);
    if lr <> nil then
      if not (rrp$life_mark in lr^.rrp) then begin
        r := ra_utils_$rematerialize(ru_rtn, lr, true);
        if r <> nil then begin
          ru_remat^[lr^.id] := r;
          ru_lr_ptr_t(lr)^.cost.r := 0.0;
          if rrp$ip_reg in lr^.rrp then
            bv_$set(ru_remat_ip, lr)
          else if rrp$fp_reg in lr^.rrp then
            bv_$set(ru_remat_fp, lr);
        end
        else begin
          ru_lr_ptr_t(lr)^.cost.r := 1.0;
          if rrp$ip_reg in lr^.rrp then
            bv_$set(ru_mem_ip, lr)
          else if rrp$fp_reg in lr^.rrp then
            bv_$set(ru_mem_fp, lr);
        end;
        if rrp$unique_value in lr^.rrp then begin
          bv_$set(ru_unique, lr);
          bv_$set(ru_single_def, lr);
        end
        else if (ru_lr_ptr_t(lr)^.defs = nil) or
                (ru_lts_ptr_t(ru_lr_ptr_t(lr)^.defs)^.next_def <> nil) or
                (rrp$modify in lr^.rrp) then
          bv_$clear(ru_single_def, lr);
      end;
  until lr = nil;
  bv_$and_to(ru_bits, ru_mem_ip, ru_single_def, ru_cand_ip);
  bv_$and_to(ru_bits, ru_mem_fp, ru_single_def, ru_cand_fp);
end;

{ spill_something - up to count live ranges of v that pass through h
  and are not spilled around it yet spilled around it: marked spilled,
  reloaded at its tail (live_in) and, unless remat (rematerializable:
  no store), stored at the end of its head (live_out); an even half's
  odd half with it when it qualifies too.  The number spilled.

  0x26EE12, 0x126 bytes, internal: h (8), v (12), remat a byte (16),
  count a longword (18) in D3; D0 a word. }

function spill_something(
    h: ru_ham_ptr_t;
    v: bv_ptr_t;
    remat: boolean;
    count: integer32): integer; options(val_param); internal;
label
  10;
var
  k: integer;
  lr: lr_ptr_t;
begin
  bv_$and_to(ru_bits, h^.pass, v, ru_work);
  bv_$subtract(ru_bits, h^.spilled, ru_work);
  k := 0;
  lr := nil;
  while count > 0 do begin
    lr := bv_$find_next(ru_rtn, ru_work, lr);
    if lr = nil then
      goto 10;
    k := k + 1;
    count := count - 1;
    bv_$set(h^.spilled, lr);
    bv_$set(h^.tail^.live_in, lr);
    if not remat then
      bv_$set(h^.head^.live_out, lr);
    if lr^.mate <> nil then
      if rrp$fp_reg_even_only in lr^.rrp then
        if bv_$test(ru_work, lr^.mate) then begin
          k := k + 1;
          count := count - 1;
          bv_$set(h^.spilled, lr^.mate);
          bv_$set(h^.tail^.live_in, lr^.mate);
          if not remat then
            bv_$set(h^.head^.live_out, lr^.mate);
          bv_$clear(ru_work, lr^.mate);
        end;
  end;
10:
  spill_something := k;
end;

{ enclosing_intervals_are_hammocks - whether the hammocks enclosing h
  (through its parents) account for every loop level up to level: a
  parent whose head is one level out takes level one down; true at
  level 0, false at the top.

  0x26EF38, 0x50 bytes, internal: h (8), level (12) in D2 (its move's
  flags tested); the recursive call's D0 returned as it is. }

function enclosing_intervals_are_hammocks(
    h: ru_ham_ptr_t;
    level: integer32): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := level = 0;
  if not r and (h <> nil) then
    if h^.head^.f.depth = level - 1 then
      r := enclosing_intervals_are_hammocks(h^.parent, h^.head^.f.depth)
    else
      r := enclosing_intervals_are_hammocks(h^.parent, level);
  enclosing_intervals_are_hammocks := r;
end;

{ spill_around_hammocks - for each hammock of h's list (top down): the
  live ranges v (spilled around an enclosing hammock) count as spilled
  here too and the registers they freed (ip_used, fp_used) are taken
  off its needs; a hammock that is not a loop's interval, or whose
  enclosing hammocks cover its loop levels, has as many of its excess
  registers spilled as can be: rematerializable, candidates, then any
  in memory, integer and floating apart.

  0x26EF88, 0x160 bytes, internal: h (8), v (12), ip_used (16) and
  fp_used (18) words; the excess a longword in D2, the counts D4, D3. }

procedure spill_around_hammocks(
    h: ru_ham_ptr_t;
    v: bv_ptr_t;
    ip_used: integer;
    fp_used: integer); options(val_param); internal;
var
  excess: integer32;
  ki, kf, t: integer;
begin
  while h <> nil do begin
    bv_$or(ru_bits, v, h^.spilled);
    h^.ip := h^.ip - ip_used;
    h^.fp := h^.fp - fp_used;
    ki := 0;
    kf := ki;
    if (h^.head^.l70 = nil) or
       enclosing_intervals_are_hammocks(h^.parent, h^.head^.f.depth) then begin
      excess := h^.ip - ru_nip;
      if excess > 0 then begin
        ki := spill_something(h, ru_remat_ip, true, excess);
        excess := excess - ki;
        if excess > 0 then begin
          t := spill_something(h, ru_cand_ip, false, excess);
          ki := ki + t;
          excess := excess - t;
          if excess > 0 then
            ki := ki + spill_something(h, ru_mem_ip, false, excess);
        end;
      end;
      excess := h^.fp - ru_nfp;
      if excess > 0 then begin
        kf := spill_something(h, ru_remat_fp, true, excess);
        excess := excess - kf;
        if excess > 0 then begin
          t := spill_something(h, ru_cand_fp, false, excess);
          kf := kf + t;
          excess := excess - t;
          if excess > 0 then
            kf := kf + spill_something(h, ru_mem_fp, false, excess);
        end;
      end;
    end;
    if h^.child <> nil then
      spill_around_hammocks(h^.child, h^.spilled, ip_used + ki, fp_used + kf);
    h := h^.next;
  end;
end;

{ coalesce_spill_victims - bottom up, until nothing changes: where a
  hammock's tail is the next hammock's head, the live ranges that are
  reloaded there and stored there and not touched in it are dropped
  from both; the reloads at that block that the hammock before passes
  through move to the previous hammock's tail, the stores that this
  hammock passes through to its head.

  0x26F0E8, 0x1E8 bytes, internal: h (8) in A3, the stable flag in D2;
  the block in A4; ru_empty is never set (the emptiness test). }

procedure coalesce_spill_victims(
    h: ru_ham_ptr_t); options(val_param); internal;
var
  c: ru_ham_ptr_t;
  stable: boolean;
  t: bb_ptr_t;
begin
  c := h;
  while c <> nil do begin
    coalesce_spill_victims(c^.child);
    c := c^.next;
  end;
  repeat
    c := h;
    stable := true;
    while c <> nil do begin
      if c^.prev <> nil then
        if c^.tail = c^.prev^.head then begin
          t := c^.tail;
          bv_$copy(ru_bits, t^.transparent, ru_work);
          bv_$subtract(ru_bits, t^.live_gen, ru_work);
          bv_$and_to(ru_bits, t^.live_in, t^.live_out, ru_pass);
          bv_$and(ru_bits, ru_work, ru_pass);
          bv_$subtract(ru_bits, ru_pass, t^.live_in);
          bv_$subtract(ru_bits, ru_pass, t^.live_out);
          bv_$and_to(ru_bits, t^.live_in, ru_work, ru_pass);
          bv_$and(ru_bits, c^.prev^.pass, ru_pass);
          if not bv_$equal(ru_bits, ru_pass, ru_empty) then begin
            bv_$subtract(ru_bits, ru_pass, t^.live_in);
            bv_$or(ru_bits, ru_pass, c^.prev^.tail^.live_in);
            stable := false;
          end;
          bv_$and_to(ru_bits, t^.live_out, ru_work, ru_pass);
          bv_$and(ru_bits, c^.pass, ru_pass);
          if not bv_$equal(ru_bits, ru_pass, ru_empty) then begin
            bv_$subtract(ru_bits, ru_pass, t^.live_out);
            bv_$or(ru_bits, ru_pass, c^.head^.live_out);
            stable := false;
          end;
        end;
      c := c^.next;
    end;
  until stable;
end;

{ drop_unneeded_stores - bb's stores (live_out) less those made in a
  dominator (bb +54), once a walk (mark146); its transparent vector
  becomes the stores made on its dominators' path (with its own), kept
  for the candidates.

  0x26F2D0, 0x92 bytes, internal: bb (8), mark (12) in D2. }

procedure drop_unneeded_stores(
    bb: bb_ptr_t;
    mark: integer32); options(val_param); internal;
var
  d: bb_ptr_t;
begin
  if bb^.mark146 <> mark then begin
    bb^.mark146 := mark;
    bv_$copy(ru_bits, bb^.live_out, bb^.transparent);
    d := bb^.l54;
    if d <> nil then begin
      drop_unneeded_stores(d, mark);
      bv_$subtract(ru_bits, d^.transparent, bb^.live_out);
      bv_$or(ru_bits, d^.transparent, bb^.transparent);
    end;
    bv_$and(ru_bits, ru_single_def, bb^.transparent);
  end;
end;

{ compute_dominating_definitions - bb's avail_in: what is available on
  exit from its dominator (all ones for the first), once a walk.

  0x26F362, 0x66 bytes, internal: bb (8), mark (12). }

procedure compute_dominating_definitions(
    bb: bb_ptr_t;
    mark: integer32); options(val_param); internal;
var
  d: bb_ptr_t;
begin
  if bb^.mark146 <> mark then begin
    bb^.mark146 := mark;
    d := bb^.l54;
    if d <> nil then begin
      compute_dominating_definitions(d, mark);
      bv_$and_to(ru_bits, d^.avail_in, d^.transparent, bb^.avail_in);
    end
    else
      init(bb^.avail_in, ru_bytes, -1);
  end;
end;

{ choose_spill_victims - each block's reloads (live_in) and stores
  (live_out) chosen: cleared, the hammocks spilled around top down,
  coalesced bottom up, and the stores a dominator makes dropped.

  0x26F3C8, 0xC0 bytes, internal: the two word arguments of
  spill_around_hammocks pushed as one `clrl' (pattern 105). }

procedure choose_spill_victims; internal;
var
  bb: bb_ptr_t;
  mark: integer32;
  st: status_$t;
begin
  bb := ru_rtn^.bbs72;
  while bb <> nil do begin
    init(bb^.live_in, ru_bytes, 0);
    init(bb^.live_out, ru_bytes, 0);
    bb := bb^.next114;
  end;
  init(ru_pass, ru_bytes, 0);
  spill_around_hammocks(ru_ham_ptr_t(lir_main_c70), ru_pass, 0, 0);
  coalesce_spill_victims(ru_ham_ptr_t(lir_main_c70));
  ru_rtn^.marks := ru_rtn^.marks + 1;
  mark := ru_rtn^.marks;
  bb := ru_rtn^.bbs72;
  while bb <> nil do begin
    drop_unneeded_stores(bb, mark);
    bb := bb^.next114;
  end;
  rws_$release_heap(ru_ham_space, st);
  ru_ham_space := nil;
end;

{ RA_UTILS_$SPILL_PASS_THROUGH_LRS - XTP's pass-through spilling (from
  xtp_$process_routine, before scheduling): the routine's bit vectors
  (seven a block), its blocks cleaned for RA, the complex lifetimes, the
  single-definition candidates (less those available where they are
  read in a dominated block), the conflict graph; when the routine
  needs more integer or floating registers than the target has (fewer
  by a tenth with lir_main_da4), the hammocks' spills chosen and made.
  Whether any spill code was added.  level (the debug level) is not
  read: ra_650 takes at_backend's.

  0x26F488, 0x266 bytes: rtn (8), level (12); D0.  The registers there
  are the words at target_properties +0x26 and +0x46 (the low words of
  p_14[4] and p_14[12], pattern 129); the tenth taken off with the FPP
  (0x00BC, 0x00A0 0.9, 0x0154 0x0068: round, docs/dpc-gaps.md 7);
  lir_main_c89 and _c88 (bytes) are the most of each live at once.
  `addql #2,SP' after bv_$release_availability_bit_vectors leaves
  ra_$build_conflict_graph's pad (pattern 51). }

function ra_utils_$spill_pass_through_lrs;
var
  any: boolean;
  bb: bb_ptr_t;
  mark: integer32;
  lr: lr_ptr_t;
  s: lts_ptr_t;
  st: status_$t;
begin
  any := false;
  ru_rtn := rtn;
  ru_ham_space := nil;
  bv_$initialize_bit_vectors(rtn, rtn^.l192 + 1, 7, true);
  ra_650 := at_backend_switches.level;
  ru_remat := nil;
  bb := rtn^.bbs;
  while bb <> nil do begin
    ra_$clean_bb_and_init_bit_vectors(bb, [1..3], false);
    bb := bb^.next;
  end;
  ru_bytes := rshft(ru_rtn^.l192 + 32, 5) * 4;
  ru_bits := ru_bytes * 8;
  ra_utils_$compute_complex_lifetimes(rtn);
  ru_pass := rws_alloc(ru_bytes + ru_bytes);
  ru_single_def := bv_ptr_t(integer32(ru_pass) + ru_bytes);
  init(ru_single_def, ru_bytes, -1);
  ru_rtn^.marks := ru_rtn^.marks + 1;
  mark := ru_rtn^.marks;
  bb := ru_rtn^.bbs72;
  while bb <> nil do begin
    compute_dominating_definitions(bb, mark);
    if bb^.l54 <> nil then begin
      bv_$and_to(ru_bits, bb^.avail_in, bb^.live_gen, ru_pass);
      bv_$subtract(ru_bits, ru_pass, ru_single_def);
    end;
    bb := bb^.next114;
  end;
  bv_$release_availability_bit_vectors(rtn);
  ra_$build_conflict_graph(rtn, [1..3], true);
  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.rrp := lr^.rrp - [rrp$ra_marked];
    s := lr^.ltss;
    while s <> nil do begin
      s^.rrp := s^.rrp - [rrp$ra_marked];
      s := s^.next;
    end;
    lr := lr^.next;
  end;
  ru_nip := target_properties.p_14[4];
  ru_nfp := target_properties.p_14[12];
  if lir_main_da4 then begin
    ru_nip := round(ru_nip * 0.9);
    ru_nfp := round(ru_nfp * 0.9);
  end;
  if (ord(lir_main_c89) > ru_nip) or (ord(lir_main_c88) > ru_nfp) then
    if initialize_hammock_data then begin
      choose_spill_cost(ru_pass);
      choose_spill_victims;
      any := spill_the_victims;
    end;
  if ru_ham_space <> nil then
    rws_$release_heap(ru_ham_space, st);
  if ru_remat <> nil then
    rws_$release_heap(ru_remat, st);
  bv_$release_bit_vectors(rtn);
  rws_$release_heap(ru_pass, st);
  ra_utils_$spill_pass_through_lrs := any;
end;

{ RA_UTILS_$REMATERIALIZE - the instruction that recomputes lr's value,
  or nil.  A live range split from another (home_lr) takes that one's
  instruction.  Otherwise lr must have one definition (and its mate, if
  any, one, by a double access), not modified: a move (b6_0) of a
  register that is not physical nor both a unique value and never
  spilled is followed to its source's (at most 20 deep, never to lr
  itself); else every operand read must be a complex unique value never
  spilled and every one written lr's (or its mate's) definition, no
  slower than a reload; a load (unless any_load) must not be grouped or
  continued and must read memory that is a constant's (an immediate's
  alias class 0 or 11) when its operand 3 is a register or memory; and
  every other definition of lr must consume the same symbols.

  0x26F6EE, 0x2E8 bytes: rtn (8) in D2, lr (12) in A4, any_load a byte
  (16); A0 (-62).  The depth is +524.  The operands counted down from
  the last (D5, D3 12n, D4 4n). }

function ra_utils_$rematerialize;
label
  99;
var
  result: instr_ptr_t;
  mdef: lts_ptr_t;
  def: lts_ptr_t;
  m: lr_ptr_t;
  i: instr_ptr_t;
  j: instr_ptr_t;
  src: lr_ptr_t;
  x: lr_ptr_t;
  n: integer32;
  kind: operand$t;
  o: integer;
  k: operand$t;
  desc: alias_$desc_t;
  av, ao: ru_attr_ptr_t;
begin
  result := nil;
  mdef := nil;
  m := lr^.mate;
  if m <> nil then begin
    mdef := ru_lr_ptr_t(m)^.defs;
    if mdef = nil then
      goto 99;
    if ru_lts_ptr_t(mdef)^.next_def <> nil then
      goto 99;
    if rrp$modify in m^.rrp then
      goto 99;
  end;
  if lr^.home_lr <> nil then begin
    result := ru_lr_ptr_t(lr^.home_lr)^.remat;
    goto 99;
  end;
  def := ru_lr_ptr_t(lr)^.defs;
  if def = nil then
    goto 99;
  if not (rrp$write in def^.rrp) then
    goto 99;
  if rrp$modify in lr^.rrp then
    goto 99;
  i := utils_ins_$operands_instruction(def^.refs);
  if mdef <> nil then
    if (instruction_attributes[i^.opc].w18 & 7) <> 3 then
      goto 99;
  if instruction_attributes[i^.opc].b6_0 then
    if i^.opnds[1].h.kind in ru_regs then
      if ru_lts_ptr_t(def)^.next_def = nil then
        if not i^.h.sets_cc then
          if not i^.h.fp_ccs then begin
            src := i^.opnds[2].lts^.lr;
            if (ru_depth > 20) or (src = lr) then begin
              result := nil;
              goto 99;
            end;
            if not src^.f2.physical then
              if (src^.rrp * [rrp$life_mark, rrp$unique_value]) <>
                 [rrp$life_mark, rrp$unique_value] then begin
                ru_depth := ru_depth + 1;
                result := ra_utils_$rematerialize(rtn, src, any_load);
                ru_depth := ru_depth - 1;
                goto 99;
              end;
          end;
  av := addr(instruction_attributes[i^.opc]);
  n := i^.h.nopnds;
  while n > 0 do begin
    kind := i^.opnds[n].h.kind;
    if not (kind in ru_not_reg) then
      if i^.opnds[n].h.read and (kind in ru_regs) then begin
        x := i^.opnds[n].lts^.lr;
        if x^.id = 0 then
          goto 99;
        if (x^.rrp * [rrp$life_mark, rrp$unique_value]) <>
           [rrp$life_mark, rrp$unique_value] then
          goto 99;
      end
      else begin
        if not (kind in ru_regs) then
          goto 99;
        if not i^.opnds[n].h.write then
          goto 99;
        if i^.opnds[n].lts <> def then
          if (kind <> operand$fp_reg_pair) or (i^.opnds[n].lts <> mdef) then
            goto 99;
        case kind of
          operand$ip_reg: o := ord(opc$loadl);
          operand$fp_reg: o := ord(opc$loads);
          otherwise
            o := ord(opc$loadd);
        end;
        if instruction_attributes[i^.opc].nresults >= n then begin
          ao := addr(instruction_attributes[o]);
          if av^.opnds[n].delay > ao^.opnds[3].delay then
            goto 99;
        end;
      end;
    n := n - 1;
  end;
  if not any_load and (instruction_attributes[i^.opc].class = class$load) then begin
    if i^.h.may_generate_an_exception then
      goto 99;
    if i^.h.b2_7 then
      goto 99;
    k := i^.opnds[3].h.kind;
    if not (k in ru_not_reg) and (k in ru_reg_or_mem) then begin
      if i^.opnds[1].h.kind <> operand$immediate then
        goto 99;
      if not alias_$get_alias_desc(il_$node_ptr_t(i^.opnds[1].link), 4, desc) then
        goto 99;
      if not (desc.class in [0, 11]) then
        goto 99;
    end;
  end;
  def := ru_lts_ptr_t(def)^.next_def;
  while def <> nil do begin
    j := utils_ins_$operands_instruction(def^.refs);
    if not utils_$instrs_consume_identical_symbols(i, j) then
      goto 99;
    def := ru_lts_ptr_t(def)^.next_def;
  end;
  result := i;
99:
  ra_utils_$rematerialize := result;
end;

{ get_new_spill_lr - a new live range of lr's register file (a pair's
  half when lr has a mate) whose node, memory home and home_lr (the
  live range it was split from) are lr's (the mate's for the other
  half).

  0x26F9D6, 0xAC bytes, internal: lr (8) in D2; A0 (D0). }

function get_new_spill_lr(
    lr: lr_ptr_t): lr_ptr_t; options(val_param); internal;
var
  m: lr_ptr_t;
  n: lr_ptr_t;
  nm: lr_ptr_t;
begin
  m := lr^.mate;
  if m = nil then begin
    if rrp$fp_reg in lr^.rrp then
      n := lir_$new_live_range_fp_reg
    else
      n := lir_$new_live_range_ip_reg;
  end
  else begin
    n := lir_$new_live_range_fp_reg_pair;
    if rrp$fp_reg_odd_only in lr^.rrp then
      n := n^.mate;
    nm := n^.mate;
    nm^.node20 := m^.node20;
    nm^.memory_home := m^.memory_home;
    if m^.home_lr <> nil then
      nm^.home_lr := m^.home_lr
    else
      nm^.home_lr := m;
  end;
  n^.node20 := lr^.node20;
  n^.memory_home := lr^.memory_home;
  if lr^.home_lr <> nil then
    n^.home_lr := lr^.home_lr
  else
    n^.home_lr := lr;
  get_new_spill_lr := n;
end;

{ get_new_spill_lts - a new segment of lr (no block, no properties).

  0x26FA82, 0x20 bytes, internal: lr (8); A0. }

function get_new_spill_lts(
    lr: lr_ptr_t): lts_ptr_t; options(val_param); internal;
var
  lts: lts_ptr_t;
begin
  lir_utils_$add_lts_to_lr(0, lr, nil, lts);
  get_new_spill_lts := lts;
end;

{ rematerialize_result - a copy of tmpl (a rematerializing instruction)
  for reader, in bb, writing lts (and mlts, a pair's odd half, or a
  pair's double instruction narrowed to single: LOADD to LOADS, COPYD to
  COPYS, the odd half's displacement +4 or source the template's
  operand 3): its reads take segments of their live ranges in bb
  (exposed, made when needed), linked after the definition; first and
  second the written operands.

  0x26FAA2, 0x2EC bytes, internal: tmpl (8), reader (12) in A2, bb (16)
  in D5, lts (20) in D4, mlts (24), first (28) and second (32) by
  address; A0.  The template's operands counted in -24, the copy's in
  D2 (D3 12k).  An unexpected double instruction is a bug check that
  leaves the copy unset (-20). }

function rematerialize_result(
    tmpl: instr_ptr_t;
    reader: instr_ptr_t;
    bb: bb_ptr_t;
    lts: lts_ptr_t;
    mlts: lts_ptr_t;
    var first: opnd_ptr_t;
    var second: opnd_ptr_t): instr_ptr_t; options(val_param); internal;
label
  10;
var
  x: instr_ptr_t;
  n: integer32;
  k: integer32;
  o: opnd_ptr_t;
  s: lts_ptr_t;
  l: lr_ptr_t;
begin
  if mlts <> nil then
    x := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
        tmpl^.opc, 0, nil, nil)
  else if tmpl^.opc = ord(opc$loadd) then
    x := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
        ord(opc$loads), 0, nil, nil)
  else if tmpl^.opc = ord(opc$copyd) then
    x := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
        ord(opc$copys), 0, nil, nil)
  else if instruction_attributes[tmpl^.opc].class = class$fp_double then
    bug_check('RA_UTILS: REMATERIALIZE_RESULT - unexpected DP instruction without 2nd LTS%$')
  else
    x := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
        tmpl^.opc, 0, nil, nil);
  first := nil;
  second := nil;
  x^.h.b2_6 := true;
  x^.h.grouped := false;
  x^.h.width := tmpl^.h.width;
  x^.h.b0_1 := reader^.h.b0_1;
  x^.l32 := reader^.l32;
  n := 0;
  k := 0;
  while tmpl^.h.nopnds > n do begin
    n := n + 1;
    k := k + 1;
    o := addr(x^.opnds[k]);
    o^.link := tmpl^.opnds[n].link;
    o^.value := tmpl^.opnds[n].value;
    o^.h := tmpl^.opnds[n].h;
    o^.h.num := k;
    if o^.h.read and not (o^.h.kind in ru_not_reg) then begin
      if not (o^.h.kind in ru_regs) then
        bug_check('RA_UTILS: REMATERIALIZE_RESULT - illegal read operand%$')
      else begin
        l := o^.lts^.lr;
        if not (rrp$unique_value in l^.rrp) or (l^.id = 0) then
          bug_check('RA_UTILS: REMATERIALIZE_RESULT - illegal read operand%$');
      end;
      s := o^.lts^.lr^.ltss;
      while s <> nil do begin
        if s^.bb = bb then
          goto 10;
        s := s^.next;
      end;
10:
      if s = nil then begin
        lir_utils_$add_lts_to_lr(opnd_bytes_ptr_t(o)^.rrp, o^.lts^.lr, bb, s);
        s^.f2.exposed := true;
        s^.lr^.f2.b3_4 := true;
      end;
      o^.lts := s;
      if s^.refs = nil then
        s^.refs := o
      else begin
        o^.link := s^.refs^.link;
        s^.refs^.link := o;
      end;
    end
    else if o^.h.modify then
      bug_check('RA_UTILS: REMATERIALIZE_RESULT - modify operand%$')
    else if o^.h.write and (o^.h.kind in ru_regs) then begin
      o^.lts := lts;
      if (o^.h.kind = operand$fp_reg_pair) and (first <> nil) then
        second := o
      else
        first := o;
      if integer32(lts) = lir_main_c4c then
        o^.h.kind := operand$ip_reg_like;
      if o^.h.kind = operand$fp_reg_pair then
        if mlts <> nil then
          lts := mlts
        else begin
          o^.h.kind := operand$fp_reg;
          if rrp$fp_reg_odd_only in lts^.rrp then begin
            opnd_bytes_ptr_t(o)^.rrp := (opnd_bytes_ptr_t(o)^.rrp & 16#FE) ! 2;
            if x^.opc = ord(opc$loads) then
              x^.opnds[1].value := x^.opnds[1].value + 4
            else if x^.opc = ord(opc$copys) then
              x^.opnds[1].value := tmpl^.opnds[3].value;
          end;
          if x^.opc = ord(opc$copys) then
            n := n + 1;
          n := n + 1;
        end;
    end;
  end;
  x^.h.nopnds := k;
  rematerialize_result := x;
end;

{ find_mate_lts - the segment of lts's live range's mate that instr
  writes as a pair (kind fp_reg_pair).

  0x26FE44, 0x6E bytes, internal: instr (8), lts (12); A0 (unset after
  the bug check). }

function find_mate_lts(
    instr: instr_ptr_t;
    lts: lts_ptr_t): lts_ptr_t; options(val_param); internal;
var
  m: lr_ptr_t;
  k: integer32;
begin
  m := lts^.lr^.mate;
  for k := 1 to instr^.h.nopnds do
    if instr^.opnds[k].h.kind = operand$fp_reg_pair then
      if instr^.opnds[k].lts^.lr = m then begin
        find_mate_lts := instr^.opnds[k].lts;
        return;
      end;
  bug_check('RA_UTILS: FIND_MATE_LTS -- lts not found%$');
end;

{ get_new_mate_lts - for op, a pair's even half, the odd half's operand
  after it in instr (of lr's mate) given a new segment of lts's live
  range's mate; nil for another operand.

  0x26FEDC, 0x82 bytes, internal: op (8), lr (12) in D3, instr (16),
  lts (20) in D4; A0. }

function get_new_mate_lts(
    op: opnd_ptr_t;
    lr: lr_ptr_t;
    instr: instr_ptr_t;
    lts: lts_ptr_t): lts_ptr_t; options(val_param); internal;
var
  k: integer32;
  o: opnd_ptr_t;
begin
  if (op^.h.kind = operand$fp_reg_pair) and op^.h.fp_reg_even_only then begin
    k := op^.h.num;
    while instr^.h.nopnds > k do begin
      k := k + 1;
      o := addr(instr^.opnds[k]);
      if o^.h.fp_reg_odd_only then
        if o^.lts^.lr^.mate = lr then begin
          o^.lts := get_new_spill_lts(lts^.lr^.mate);
          get_new_mate_lts := o^.lts;
          return;
        end;
    end;
  end;
  get_new_mate_lts := nil;
end;

{ pick_instruction - the template a reload (forms: spill_instr_forms'
  loads) or store (its stores) of op, which holds lts, is made from: a
  pair's (kind must then be fp_reg_pair); a floating register's even or
  odd single when it is a half of a 64-bit variable (a VAR_NAME of 64
  bits, or a node whose +10 low nibble is 5, 6 or 13) and kind is a
  pair or its live range physical, any other floating register's; an
  integer register's, of 8 or 16 bits when fl says so.

  0x26FF5E, 0xF2 bytes, internal: kind a word (8), fl a word (10: its
  low byte tested, `btst #3,(11,A6)'), op (12), lts (16), forms (20),
  node (24); A0.  The test of the variable's size reuses D0 (kind's
  low byte, positive: false) when the segment has no parity; after the
  even/odd bug check D0 is what bug_check left (written false); after
  the pair bug check A0 is unset. }

function pick_instruction(
    kind: operand$t;
    fl: integer;
    op: opnd_ptr_t;
    lts: lts_ptr_t;
    forms: ru_forms_ptr_t;
    node: univ_ptr): spill_desc_ptr_t; options(val_param); internal;
type
  ru_var_ptr_t = ^ru_var_t;
  ru_var_t = record
    space0: array [0..1] of char;
    kind: integer;                      { +2 }
    space4: array [4..9] of char;
    b10: char;                          { +10 }
    b11: char;
    space12: array [12..35] of char;
    l36: integer32;                     { +36 (VAR_NAME: its size in
                                          bits) }
  end;
var
  b: boolean;
  v: ru_var_ptr_t;
begin
  if op^.h.kind = operand$fp_reg_pair then begin
    if kind <> operand$fp_reg_pair then
      bug_check('RA_UTILS: PICK_INSTRUCTION -- unexpected FP_REG_PAIR operand%$')
    else
      pick_instruction := forms^[0];
  end
  else if rrp$fp_reg in lts^.rrp then begin
    b := false;
    if lts^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] <> [] then
      if (kind = operand$fp_reg_pair) or lts^.lr^.f2.physical then begin
        v := node;
        if v^.kind = 109 then
          b := v^.l36 = 64
        else
          b := (ord(v^.b10) & 15) in [5, 6, 13];
      end
      else
        bug_check('RA_UTILS: PICK_INSTRUCTION -- unexpected even/odd FP_REG operand%$');
    if b and (rrp$fp_reg_even_only in lts^.rrp) then
      pick_instruction := forms^[1]
    else if b and (rrp$fp_reg_odd_only in lts^.rrp) then
      pick_instruction := forms^[2]
    else
      pick_instruction := forms^[3];
  end
  else if (fl & 8) <> 0 then
    pick_instruction := forms^[6]
  else if (fl & 4) <> 0 then
    pick_instruction := forms^[5]
  else
    pick_instruction := forms^[4];
end;

{ look_for_lts - lr's segment in bb, made final there; a new one
  (first_in_bb and final, `or.w #0x50') when it has none.

  0x2700D0, 0x4A bytes, internal: lr (8), bb (12); A0. }

function look_for_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  s: lts_ptr_t;
begin
  s := lr^.ltss;
  while s <> nil do begin
    if s^.bb = bb then begin
      s^.f2.final := true;
      look_for_lts := s;
      return;
    end;
    s := s^.next;
  end;
  s := get_new_spill_lts(lr);
  s^.bb := bb;
  s^.f2.first_in_bb := true;
  s^.f2.final := true;
  look_for_lts := s;
end;

{ attach_lts_list_to_new_lr - the segments of list given to lr, their
  properties or-ed into lr's.

  0x27011A, 0x22 bytes, internal, no frame: lr (4,SP), list (8,SP); the
  flags of the store of ltss (pattern 111). }

procedure attach_lts_list_to_new_lr(
    lr: lr_ptr_t;
    list: lts_ptr_t); options(val_param); internal;
begin
  lr^.ltss := list;
  while list <> nil do begin
    list^.lr := lr;
    lr^.rrp := lr^.rrp + list^.rrp;
    list := list^.next;
  end;
end;

{ find_best_dom_bb - bb's dominator one loop level out (bb +16 the
  depth) when target dominates it (or target itself on the way); nil
  for a block outside loops or target.  A last test of the routine's
  start block (+14 = 1) is reached only with no block (dead).

  0x27013C, 0x7C bytes, internal: bb (8), target (12) in D0; A0. }

function find_best_dom_bb(
    bb: bb_ptr_t;
    target: bb_ptr_t): bb_ptr_t; options(val_param); internal;
label
  10, 99;
var
  r: bb_ptr_t;
  d: bb_ptr_t;
begin
  r := nil;
  if (bb^.f.depth <> 0) and (bb <> target) then begin
    d := bb^.l54;
    while d <> nil do begin
      if d = target then begin
        r := d;
        goto 99;
      end;
      if d^.f.depth = bb^.f.depth - 1 then
        goto 10;
      d := d^.l54;
    end;
10:
    r := d;
    if d <> nil then begin
      while d <> nil do begin
        if d = target then
          goto 99;
        d := d^.l54;
      end;
      r := nil;
    end;
    if d <> nil then
      if d^.f14.kind = 1 then
        r := nil;
  end;
99:
  find_best_dom_bb := r;
end;

{ break_one_loop - lr's segments moved to list: those in blocks deeper
  in loops than best (the block found so far, whose depth is the
  bound) whose dominator one level out (find_best_dom_bb toward target)
  is best or the first found; a deeper match restarts the list (the
  segments collected so far go back to lr); those of the same depth
  with the same dominator are added.  changed is set when a segment
  deeper than target's block stays or a list is restarted, cleared when
  the list is empty.

  0x2701B8, 0x182 bytes, internal: lr (8), best (12) and list (16) by
  address, changed (20) by address in D5, target (24) in D4; prev at
  -12, the list's last at -8; the walk resumes after prev (or at lr's
  first) each time, through the flags of prev's store (-12) on one
  path (pattern 111).  The depths compared unsigned (bytes). }

procedure break_one_loop(
    lr: lr_ptr_t;
    var best: bb_ptr_t;
    var list: lts_ptr_t;
    var changed: boolean;
    target: bb_ptr_t); options(val_param); internal;
label
  20, 30;
var
  none: boolean;
  depth: integer32;
  prev: lts_ptr_t;
  last: lts_ptr_t;
  s: lts_ptr_t;
  b: bb_ptr_t;
  d: bb_ptr_t;
begin
  none := best = nil;
  if best = nil then
    depth := 0
  else
    depth := best^.f.depth;
  prev := nil;
  last := nil;
  list := nil;
  s := lr^.ltss;
  while s <> nil do begin
    b := s^.bb;
    d := find_best_dom_bb(b, target);
    if b^.f.depth > depth then
      if none or (d = best) then begin
        if (d <> nil) and (d^.f.depth <= b^.f.depth) then begin
          if last <> nil then begin
            if prev = nil then
              prev := last;
            last^.next := lr^.ltss;
            lr^.ltss := list;
            changed := true;
          end;
          list := s;
          last := s;
          if prev = nil then
            lr^.ltss := s^.next
          else
            prev^.next := s^.next;
          s^.next := nil;
          best := d;
          depth := b^.f.depth;
          goto 20;
        end
        else begin
          prev := s;
          goto 20;
        end;
      end;
    if (d = best) and (b^.f.depth <> 0) and (b^.f.depth >= depth) then begin
      if last = nil then
        list := s
      else
        last^.next := s;
      last := s;
      if prev = nil then
        lr^.ltss := s^.next
      else
        prev^.next := s^.next;
      s^.next := nil;
      goto 20;
    end;
    if b^.f.depth > target^.f.depth then
      changed := true;
    prev := s;
20:
    if prev <> nil then
      s := prev^.next
    else
      s := lr^.ltss;
  end;
  if list = nil then
    changed := false;
end;

{ break_loops_from_spill_victim - a spill victim with one definition
  (and its mate, if any, one in the same block), not modified, not
  physical, not split already: its segments in each loop body below
  the definition's block get a new live range of their own, joined to
  the old one by a preference move at the end (before the closing
  transfers, and an IPCCNOP's group) of the dominator one loop level
  out, until no loop is left; then the old live range's remaining
  segments get a new "backbone" live range, a spill victim, with the
  rematerializing instruction kept in the old one (+60).

  0x27033A, 0x46A bytes, internal: rtn (8), lr (12) in D6, trace a
  byte (16) in D2 (add_spill_code passes a local it never sets); the
  definition at -56, the mate at -36, the block at -52, the lists at
  -60 and -44, changed in D3, traced in D4.  The second list's test is
  made twice. }

procedure break_loops_from_spill_victim(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t;
    trace: boolean); options(val_param); internal;
label
  10, 20;
var
  def: lts_ptr_t;
  m: lr_ptr_t;
  md: lts_ptr_t;
  remat: instr_ptr_t;
  changed: boolean;
  traced: boolean;
  bbv: bb_ptr_t;
  list60: lts_ptr_t;
  list44: lts_ptr_t;
  flag: boolean;
  found: boolean;
  s: lts_ptr_t;
  nl: lr_ptr_t;
  kind: operand$t;
  i: instr_ptr_t;
  after: boolean;
  mv: instr_ptr_t;
  r: opnd_ptr_t;
  ns: lts_ptr_t;
begin
  if ru_lr_ptr_t(lr)^.defs = nil then
    return;
  if rrp$modify in lr^.rrp then
    return;
  if lr^.f2.physical then
    return;
  if lr^.home_lr <> nil then
    return;
  if not lr^.f2.b3_0 then
    return;
  if lr^.id = 0 then
    return;
  def := ru_lr_ptr_t(lr)^.defs;
  if ru_lts_ptr_t(def)^.next_def <> nil then
    return;
  if def^.refs = nil then
    return;
  if lr^.mate <> nil then begin
    if rrp$fp_reg_odd_only in lr^.rrp then
      return;
    m := lr^.mate;
    if ru_lr_ptr_t(m)^.defs = nil then
      return;
    if m^.f2.physical then
      return;
    md := ru_lr_ptr_t(m)^.defs;
    if ru_lts_ptr_t(md)^.next_def <> nil then
      return;
    if rrp$modify in m^.rrp then
      return;
    if md^.refs = nil then
      return;
    if md^.bb <> def^.bb then
      return;
  end
  else
    m := nil;
  remat := ra_utils_$rematerialize(rtn, lr, false);
  changed := false;
  traced := changed;
  repeat
    bbv := nil;
    flag := changed;
    break_one_loop(lr, bbv, list60, flag, def^.bb);
    changed := flag;
    if (bbv <> nil) and (m <> nil) then begin
      flag := changed;
      break_one_loop(m, bbv, list44, flag, def^.bb);
      changed := flag;
    end
    else
      list44 := nil;
    found := false;
    s := lr^.ltss;
    while s <> nil do begin
      if s^.bb <> bbv then begin
        found := true;
        goto 10;
      end;
      s := s^.next;
    end;
10:
    if not found and (bbv = def^.bb) then begin
      changed := false;
      if list60 <> nil then begin
        s := list60;
        while s^.next <> nil do
          s := s^.next;
        s^.next := lr^.ltss;
        lr^.ltss := list60;
      end;
      if list44 <> nil then begin
        s := list44;
        while s^.next <> nil do
          s := s^.next;
        s^.next := m^.ltss;
        m^.ltss := list44;
      end;
    end
    else if bbv <> nil then begin
      if trace and not traced then
        vfmt_$write('  Splitting LR# %3ZWD%.', lr^.num);
      traced := true;
      nl := get_new_spill_lr(lr);
      bv_$make_live_range_complex(rtn, nl);
      attach_lts_list_to_new_lr(nl, list60);
      if list44 <> nil then
        attach_lts_list_to_new_lr(nl^.mate, list44);
      if list44 <> nil then
        kind := operand$fp_reg_pair
      else if def^.refs^.h.kind in ru_ip_kinds then
        kind := operand$ip_reg
      else
        kind := operand$fp_reg;
      i := bbv^.last;
      while i <> nil do begin
        if not (instruction_attributes[i^.opc].class in ru_branchy) then
          goto 20;
        i := i^.prev;
      end;
20:
      if i <> nil then
        if (i^.opc = ord(opc$ipccnop)) and (kind = operand$ip_reg) then
          if (i^.prev = nil) or not i^.prev^.h.grouped then
            i := i^.prev;
      if i <> nil then
        after := true
      else begin
        after := false;
        i := bbv^.first;
      end;
      i^.bb := bbv;
      mv := lir_utils_$create_preference_move(kind, i, after);
      if kind = operand$ip_reg then begin
        if mv^.next^.opc = ord(opc$ipccnop) then
          mv^.h.grouped := true;
      end
      else if mv^.prev <> nil then
        if mv^.prev^.opc = ord(opc$ipccnop) then
          if (mv^.prev^.prev = nil) or not mv^.prev^.prev^.h.grouped then
            mv^.prev^.h.grouped := true;
      s := look_for_lts(lr, bbv);
      mv^.opnds[1].lts := s;
      opnd_bytes_ptr_t(addr(mv^.opnds[1]))^.rrp :=
          opnd_bytes_ptr_t(addr(mv^.opnds[1]))^.rrp ! (ru_bytes_ptr_t(s)^.b1 & 3);
      if s^.refs = nil then
        s^.refs := addr(mv^.opnds[1])
      else begin
        r := s^.refs;
        while r^.link <> nil do
          r := r^.link;
        r^.link := addr(mv^.opnds[1]);
      end;
      ns := get_new_spill_lts(nl);
      mv^.opnds[2].lts := ns;
      opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp :=
          opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp ! (ru_bytes_ptr_t(ns)^.b1 & 3);
      ns^.refs := addr(mv^.opnds[2]);
      if m <> nil then begin
        s := look_for_lts(m, bbv);
        mv^.opnds[3].lts := s;
        opnd_bytes_ptr_t(addr(mv^.opnds[3]))^.rrp :=
            opnd_bytes_ptr_t(addr(mv^.opnds[3]))^.rrp ! (ru_bytes_ptr_t(s)^.b1 & 3);
        if s^.refs = nil then
          s^.refs := addr(mv^.opnds[3])
        else begin
          r := s^.refs;
          while r^.link <> nil do
            r := r^.link;
          r^.link := addr(mv^.opnds[3]);
        end;
        ns := get_new_spill_lts(nl^.mate);
        mv^.opnds[4].lts := ns;
        opnd_bytes_ptr_t(addr(mv^.opnds[4]))^.rrp :=
            opnd_bytes_ptr_t(addr(mv^.opnds[4]))^.rrp ! (ru_bytes_ptr_t(ns)^.b1 & 3);
        ns^.refs := addr(mv^.opnds[4]);
      end;
    end;
  until not changed;
  if traced then begin
    ru_lr_ptr_t(lr)^.remat := remat;
    nl := get_new_spill_lr(lr);
    bv_$make_live_range_complex(rtn, nl);
    if trace then
      vfmt_$write('    Replacing backbone with LR # %3ZWD%.', nl^.num);
    nl^.f2.b3_0 := true;
    attach_lts_list_to_new_lr(nl, lr^.ltss);
    if nl^.mate <> nil then begin
      nl^.mate^.f2.b3_0 := true;
      attach_lts_list_to_new_lr(nl^.mate, lr^.mate^.ltss);
    end;
  end;
end;

{ rebuild_db_exposed_lts_list - the DB register's live range (rtn
  +108) gets its exposed list (+72, chained at the segments' +16) back
  from its segments, its hints cleared.

  0x2707E4, 0x34 bytes, internal, no frame (4,SP). }

procedure rebuild_db_exposed_lts_list(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  s: lts_ptr_t;
begin
  lr := rtn^.db_lr;
  lr^.exposed_hint := nil;
  lr^.exposed_prev := nil;
  lr^.exposed := nil;
  s := lr^.ltss;
  while s <> nil do begin
    if s^.f2.exposed then begin
      s^.next_exposed := lr^.exposed;
      lr^.exposed := s;
    end;
    s := s^.next;
  end;
end;

{ find_modify_opr - the intend_to_modify read of op's instruction that
  op (a modify) modifies: the same parity bits.

  0x270818, 0x94 bytes, internal: op (8); A0 (unset after the second
  bug check). }

function find_modify_opr(
    op: opnd_ptr_t): opnd_ptr_t; options(val_param); internal;
var
  i: instr_ptr_t;
  k: integer32;
begin
  if not op^.h.modify then
    bug_check('RA_UTILS_$find_modify_opr: expected modify%$');
  i := utils_ins_$operands_instruction(op);
  for k := 1 to i^.h.nopnds do
    if i^.opnds[k].h.intend_to_modify then
      if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 3) =
         (opnd_bytes_ptr_t(op)^.rrp & 3) then begin
        find_modify_opr := addr(i^.opnds[k]);
        return;
      end;
  bug_check('RA_UTILS_$find_modify_opr: failed%$');
end;

{ link_other_readers - op, the first of the readers after new_op's
  that read the same spilled value, and the readers after it linked to
  new_op (its segment) while they are close enough: nothing in pass 2
  or with lir_main_da4; from a later pass at most a distance of 20
  (0.6 of the readers' span) instructions and never past one where
  more registers are live than the bound (the block's most times 0.75,
  at least the registers there are less 2).  A reader linked loses its
  +2 bit 6 when it refers to the memory home and the value is not
  rematerialized.  Whether every reader was linked; the chain ends at
  the last linked.

  0x2708FC, 0x1C2 bytes, internal: new_op (8), instr (12), op (16),
  remat (20), kind a word (24) in D7, pass a word (26), complex_not a
  byte (28); D0 (-50).  The factors with the FPP (0x00C4, 0x00A0
  0.75 / 0.6, 0x0154 0x0068: round; docs/dpc-gaps.md 7); the
  registers there are target_properties +0x24 and +0x44 whole. }

function link_other_readers(
    new_op: opnd_ptr_t;
    instr: instr_ptr_t;
    op: opnd_ptr_t;
    remat: instr_ptr_t;
    kind: operand$t;
    pass: integer;
    complex_not: boolean): boolean; options(val_param); internal;
label
  10, 99;
var
  result: boolean;
  bound: integer32;
  nregs: integer32;
  dist: integer32;
  c: integer32;
  a3: instr_ptr_t;
  r: opnd_ptr_t;
  last: instr_ptr_t;
  b: boolean;
  g: boolean;
  x: instr_ptr_t;
  cur: opnd_ptr_t;
begin
  result := false;
  cur := new_op;
  if (pass = 2) or lir_main_da4 then
    goto 99;
  if op = nil then
    goto 99;
  if kind in ru_ip_kinds then begin
    bound := ru_bb_ptr_t(instr^.bb)^.max_ip;
    nregs := target_properties.p_14[4];
  end
  else begin
    bound := ru_bb_ptr_t(instr^.bb)^.max_fp;
    nregs := target_properties.p_14[12];
  end;
  bound := round(bound * 0.75);
  if nregs - 2 > bound then
    bound := nregs - 2;
  if pass = 0 then
    dist := 100000
  else begin
    a3 := utils_ins_$operands_instruction(new_op);
    r := op;
    while r^.link <> nil do
      r := r^.link;
    last := utils_ins_$operands_instruction(r);
    dist := last^.num - a3^.num;
    if dist <= 0 then
      dist := 20
    else begin
      dist := round(dist * 0.6);
      if dist > 20 then
        dist := 20;
    end;
  end;
  b := (pass <> 0) or complex_not;
  g := not instr^.h.grouped;
  x := instr^.next;
  repeat
    a3 := utils_ins_$operands_instruction(op);
    if b and (a3^.num <> instr^.num) then
      while x <> a3 do begin
        if g then begin
          dist := dist - 1;
          if dist = 0 then
            goto 10;
          if kind in ru_ip_kinds then
            c := ord(ru_instr_ptr_t(x)^.ip_live)
          else
            c := ord(ru_instr_ptr_t(x)^.fp_live);
          if c > bound then
            goto 10;
        end;
        g := not x^.h.grouped;
        x := x^.next;
        if x = nil then
          goto 10;
      end;
    cur^.link := op;
    op^.lts := new_op^.lts;
    if remat = nil then
      if utils_$instr_is_ref_to_memory_home(a3) then
        a3^.h.b2_6 := false;
    cur := op;
    op := op^.link;
  until op = nil;
  result := true;
10:
  cur^.link := nil;
99:
  link_other_readers := result;
end;

{ choose_store_position - the instruction a store (new, of op's value,
  op being the write) goes after: op's instruction (past its group),
  moved later by the store's latency (the definition's and the store's
  delays, less what lies between) while nothing in the way reads or
  writes the value or its memory home, uses its memory slot, transfers
  control, or (with a latency left) has more registers live than the
  bound (the registers live before the group plus 4, at least the
  registers there are less 2).  ok cleared when the latency ran out.

  0x270ABE, 0x370 bytes, internal: op (8), new (12), lr (16), pass a
  word (20) in D3, ok (22) by address; A0.  The delays from
  sched_utils_$operand_delay with no flags; the latency counted down in
  D2 alongside a `dbf' count (D1). }

function choose_store_position(
    op: opnd_ptr_t;
    new: instr_ptr_t;
    lr: lr_ptr_t;
    pass: integer;
    var ok: boolean): instr_ptr_t; options(val_param); internal;
label
  10, 20, 99;
var
  def_i: instr_ptr_t;
  d: integer32;
  gap: integer32;
  pos: instr_ptr_t;
  k: instr_ptr_t;
  bound: integer32;
  n: integer32;
  m1: univ_ptr;
  m2: univ_ptr;
  src_lr: lr_ptr_t;
  x: instr_ptr_t;
  first: boolean;
  c: integer32;
  mo: opnd_ptr_t;
  w: integer;
  j: integer32;
  o: opnd_ptr_t;
  t: lr_ptr_t;
  h: univ_ptr;
begin
  ok := true;
  def_i := utils_ins_$operands_instruction(new^.opnds[1].lts^.refs);
  d := sched_utils_$operand_delay(def_i, op, []);
  d := d + sched_utils_$operand_delay(new, addr(new^.opnds[1]), []);
  pos := utils_ins_$operands_instruction(op);
  gap := pos^.num - def_i^.num;
  if gap < 0 then
    gap := 0;
  d := d - gap;
  if d < 0 then
    d := 0;
  if instruction_attributes[def_i^.opc].b6_0 or (pass = 2) then
    d := 0;
  while pos^.h.grouped or
        (pos^.h.atomic_update and (pos^.next <> nil) and pos^.next^.h.atomic_update) do
    pos := pos^.next;
  if lir_main_da4 then
    goto 99;
  if op^.lts^.lr^.f2.physical then
    goto 99;
  k := utils_ins_$operands_instruction(op);
  while k^.prev <> nil do begin
    if not k^.prev^.h.grouped then
      goto 10;
    k := k^.prev;
  end;
10:
  if op^.h.kind in ru_ip_kinds then begin
    bound := ord(ru_instr_ptr_t(k)^.ip_live);
    n := target_properties.p_14[4];
  end
  else begin
    bound := ord(ru_instr_ptr_t(k)^.fp_live);
    n := target_properties.p_14[12];
  end;
  bound := bound + 4;
  if n - 2 > bound then
    bound := n - 2;
  if lr^.mate = nil then
    m1 := nil
  else
    m1 := lr^.mate^.memory_home;
  src_lr := new^.opnds[1].lts^.lr;
  if src_lr^.mate = nil then
    m2 := nil
  else
    m2 := src_lr^.mate^.memory_home;
  while d >= 0 do begin
    x := pos^.next;
    first := true;
    while x <> nil do begin
      if first then begin
        first := false;
        if d <> 0 then begin
          if op^.h.kind in ru_ip_kinds then
            c := ord(ru_instr_ptr_t(x)^.ip_live)
          else
            c := ord(ru_instr_ptr_t(x)^.fp_live);
          if c > bound then
            goto 99;
        end;
        if instruction_attributes[x^.opc].class = class$load then
          mo := addr(x^.opnds[1])
        else if instruction_attributes[x^.opc].class = class$store then
          mo := addr(x^.opnds[2])
        else
          mo := nil;
        if mo <> nil then
          if mo^.h.kind = new^.opnds[2].h.kind then
            if mo^.link = new^.opnds[2].link then
              goto 99;
      end;
      if instruction_attributes[x^.opc].class in ru_branchy then
        goto 99;
      if d <> 0 then
        w := 28
      else
        w := 16;
      for j := 1 to x^.h.nopnds do begin
        o := addr(x^.opnds[j]);
        if o^.h.kind in ru_reg_or_mem then begin
          t := o^.lts^.lr;
          h := t^.memory_home;
          if (m2 <> nil) and (h = m2) then
            goto 99;
          if h = src_lr^.memory_home then
            goto 99;
          if (m1 <> nil) and (h = m1) then
            goto 99;
          if h = lr^.memory_home then
            goto 99;
          if t = src_lr^.mate then
            goto 99;
          if t = src_lr then
            goto 99;
          if t = lr^.mate then
            goto 99;
          if (opnd_bytes_ptr_t(o)^.rrp & w) <> 0 then
            if t = lr then
              goto 99;
        end;
      end;
      if x^.h.grouped or
         (x^.h.atomic_update and (x^.next <> nil) and x^.next^.h.atomic_update) then
        x := x^.next
      else
        goto 20;
    end;
20:
    if d = 0 then
      ok := false
    else begin
      if x = nil then
        goto 99;
      pos := x;
    end;
    d := d - 1;
  end;
99:
  choose_store_position := pos;
end;

{ no_reg_pair_problem - false when op is a single and a reader on the
  chain from r reads a pair.

  0x270E2E, 0x3E bytes, internal, no frame: op (4,SP), r (8,SP); D0. }

function no_reg_pair_problem(
    op: opnd_ptr_t;
    r: opnd_ptr_t): boolean; options(val_param); internal;
begin
  if op^.h.kind in ru_singles then
    while r <> nil do begin
      if r^.h.kind in ru_pairs then begin
        no_reg_pair_problem := false;
        return;
      end;
      r := r^.link;
    end;
  no_reg_pair_problem := true;
end;

{ fill_intend_modify - lts and its live range given intend_to_modify.

  0x270E6C, 0x16 bytes, internal, no frame (4,SP). }

procedure fill_intend_modify(
    lts: lts_ptr_t); options(val_param); internal;
begin
  lts^.rrp := lts^.rrp + [rrp$intend_to_modify];
  lts^.lr^.rrp := lts^.lr^.rrp + [rrp$intend_to_modify];
end;

{ RA_UTILS_$ADD_SPILL_CODE - the spill code for the spilled live ranges
  (+3 bit 0) of kind's register file (ru_kinds): each spilled live
  range's loops broken first (pass 0); then in each block, for each
  instruction still marked (+2 bit 6) and each operand of the file whose
  live range (a pair's even half) is spilled and not the routine's +112:
  - the value's rematerializing instruction found (kept in the live
    range, +60, once: +3 bit 2), or its memory home made;
  - an instruction that only refers to the memory home is unmarked (or,
    setting the condition codes, given a new register result for a
    TST);
  - a read gets a reload into a new live range before it (or a copy of
    the rematerializing instruction), the closer later readers linked
    to the reload; a move's or a TST's or an EXTEND's or EXTRACTU's read
    of a spilled register is narrowed to a load of the right size where
    it can be;
  - a write or modify gets a store after it (choose_store_position),
    the writing move turned into a TST (or TSTD/TSTS, or unmarked) when
    that is all it did, later readers linked to the stored register.
  Afterwards the live ranges' +3 bit 2 is cleared and, with the debug
  switches sw14 and sw4, the routine dumped.

  0x270F0C, 0xD5E bytes: rtn (8), kind a word (12) in D5, pass a word
  (14) in D6.  new_db_lts is passed to lir_utils_$flesh_out_new_load_
  or_store as a routine (an 18-byte trampoline in the frame at -148:
  `lea abs,A0' A5, `lea abs,A1' the frame, `jmp new_db_lts', with
  cache_$clear after it; docs/dpc-gaps.md 21).  The instruction loop
  keeps the block at -100, the previous unmarked instruction at -96
  (new reloads go after it), the DB register's segment at -92 (set when
  an operand reads it), the reader at -72; the operand loop counts in
  -122 (the longword idiom) with 12k at -160, the operand at -126; the
  reload's facts at -106 (ru_fl_t), the victim at -24 (the even half),
  its live range at -64, the rematerializing instruction at -20, the
  new segment in D7, the mate's at -48.  lir_$get_new_instruction_no_
  exceptions is given four arguments (its heading has five; the fifth
  is passed nil here). }

procedure ra_utils_$add_spill_code;
label
  10, 20, 30, 50, 60, 70, 80;
var
  trace: boolean;
  any: boolean;
  lr: lr_ptr_t;
  bb: bb_ptr_t;
  prev_ins: instr_ptr_t;
  dbref: lts_ptr_t;
  i: instr_ptr_t;
  k: integer32;
  op: opnd_ptr_t;
  s: lts_ptr_t;
  l: lr_ptr_t;
  lrv: lr_ptr_t;
  v: lr_ptr_t;
  complex: boolean;
  remat: instr_ptr_t;
  nl: lr_ptr_t;
  ns: lts_ptr_t;
  fl: ru_fl_t;
  d7: lts_ptr_t;
  k2: operand$t;
  b: boolean;
  mlts: lts_ptr_t;
  rlink: opnd_ptr_t;
  mop: opnd_ptr_t;
  ni: instr_ptr_t;
  first: opnd_ptr_t;
  second: opnd_ptr_t;
  form: spill_desc_ptr_t;
  tmp88: opnd_ptr_t;
  src: opnd_ptr_t;
  dst: opnd_ptr_t;
  mo: opnd_ptr_t;
  rl: opnd_ptr_t;
  ml: opnd_ptr_t;
  old: lts_ptr_t;
  b1, b2: boolean;
  p: instr_ptr_t;
  ok: boolean;

  { new_db_lts - the DB register's segment exposed in the block being
    filled (made when needed); a bug check when DB was spilled.

    0x270E82, 0x4E bytes, nested (the static link in A1; loads A5):
    the parent's rtn (8) and block (-100); utils_$get_exposed_lts's
    flag at -14; A0. }

  function new_db_lts: lts_ptr_t;
  var
    lr: lr_ptr_t;
    created: boolean;
  begin
    lr := rtn^.db_lr;
    if lr^.f2.b3_0 then
      bug_check('RA_UTILS_$ADD_SPILL_CODE\NEW_DB_LTS -- DB has been spilled%$');
    new_db_lts := utils_$get_exposed_lts(lr, bb, created);
  end;

begin
  lir_422a := true;
  spill_instr_forms.forms[0].num := 1;
  spill_instr_forms.forms[2].num := 3;
  rebuild_db_exposed_lts_list(rtn);
  trace := false;
  any := false;
  lr := rtn^.lrs;
  while lr <> nil do begin
    if (lr^.home_lr <> nil) and (lr^.memory_home = nil) then
      lr^.memory_home := lr^.home_lr^.memory_home;
    if lr^.f2.b3_0 then begin
      if pass = 0 then
        break_loops_from_spill_victim(rtn, lr, trace);
      any := true;
    end;
    lr := lr^.next;
  end;
  if not any then
    goto 80;
  bb := rtn^.bbs;
  while bb <> nil do begin
    prev_ins := nil;
    dbref := nil;
    i := bb^.first;
    while i <> nil do begin
      fl.w := 0;
      if i^.h.b2_6 then
        for k := 1 to i^.h.nopnds do begin
          op := addr(i^.opnds[k]);
          if not (op^.h.kind in ru_kinds[kind]) then
            goto 60;
          s := op^.lts;
          l := s^.lr;
          if l^.f2.physical then
            goto 60;
          if (op^.h.kind = operand$fp_reg_pair) and op^.h.fp_reg_odd_only then
            goto 60;
          lrv := l;
          if l = rtn^.db_lr then
            dbref := s;
          if rrp$fp_reg_odd_only in l^.rrp then
            v := l^.mate
          else
            v := l;
          if not v^.f2.b3_0 then
            goto 60;
          if v = lr_ptr_t(rtn^.l112) then
            goto 60;
          if l^.f2.serialize then
            bug_check('RA_UTILS_$ADD_SPILL_CODE -- spill victim is user declared register.%$')
          else if l^.f2.no_modify then
            bug_check('RA_UTILS_$ADD_SPILL_CODE -- spill victim is no_modify register.%$');
          complex := l^.id <> 0;
          remat := ra_utils_$rematerialize(rtn, v, false);
          if not l^.f2.b3_2 then begin
            l^.f2.b3_2 := true;
            ru_lr_ptr_t(l)^.remat := remat;
            if remat = nil then
              lir_utils_$add_memory_home(rtn, l, false);
          end;
          if remat = nil then
            if utils_$instr_is_ref_to_memory_home(i) then begin
              if not (i^.h.sets_cc or i^.h.fp_ccs) then begin
                i^.h.b2_6 := false;
                goto 70;
              end;
              nl := get_new_spill_lr(l);
              lir_utils_$add_lts_to_lr(8, nl, bb, ns);
              i^.opnds[3].lts := ns;
              i^.opnds[3].link := nil;
              ns^.refs := addr(i^.opnds[3]);
              if i^.opnds[3].h.kind = operand$fp_reg_pair then begin
                lir_utils_$add_lts_to_lr(8, nl^.mate, bb, ns);
                i^.opnds[5].lts := ns;
                i^.opnds[5].link := nil;
                ns^.refs := addr(i^.opnds[5]);
              end;
              goto 70;
            end;

          { The reads. }
          if op^.h.read then begin
            fl.w := 128;
            fl.f.sets_cc := i^.h.sets_cc;
            if complex and (op^.h.intend_to_modify or (op^.link <> nil)) then
              goto 10;
            { Reads that need no new live range or a narrower load. }
            if instruction_attributes[i^.opc].b6_0 then begin
              if i^.opnds[1].h.count <> 0 then
                goto 10;
              if i^.h.fp_ccs then
                goto 10;
              k2 := i^.opnds[2].h.kind;
              d7 := i^.opnds[2].lts;
              if k2 = operand$ip_reg_like then
                if d7^.lr^.f2.physical then
                  if d7^.lr^.f2.reg = 31 then
                    goto 30;
              if i^.opnds[1].h.kind <> k2 then
                goto 10;
              if not d7^.lr^.f2.b3_0 then
                goto 30;
              if d7^.lr^.f2.physical then
                goto 30;
              fl.f.keep := true;
              goto 20;
            end;
            if i^.opc = ord(opc$tst) then begin
              d7 := lts_ptr_t(lir_main_c4c);
              goto 30;
            end;
            if i^.opnds[2].h.unconsumed or
               (integer32(i^.opnds[2].lts) = lir_main_c4c) then
              if op^.h.num = 1 then
                if i^.opc = ord(opc$move) then
                  if i^.h.sets_cc then begin
                    d7 := lts_ptr_t(lir_main_c4c);
                    goto 30;
                  end;
            b := i^.opc = ord(opc$tstw);
            if not b then
              if i^.h.sets_cc and (op^.h.num = 1) then begin
                b := (i^.opnds[2].h.unconsumed or
                      (integer32(i^.opnds[2].lts) = lir_main_c4c)) and
                     (i^.opc = ord(opc$extend15));
                if not b then
                  if i^.opnds[3].h.unconsumed or
                     (integer32(i^.opnds[3].lts) = lir_main_c4c) then
                    b := (i^.opnds[2].lts = nil) and
                         (i^.opnds[2].h.kind = operand$immediate) and
                         (i^.opc = ord(opc$extractu)) and (i^.h.width = 16);
              end;
            if b then begin
              if remat <> nil then
                goto 10;
              fl.f.adjust := 2;
              fl.f.half16 := true;
              d7 := lts_ptr_t(lir_main_c4c);
              goto 30;
            end;
            b := i^.opc = ord(opc$tstb);
            if not b then
              if i^.h.sets_cc and (op^.h.num = 1) then begin
                b := (i^.opnds[2].h.unconsumed or
                      (integer32(i^.opnds[2].lts) = lir_main_c4c)) and
                     (i^.opc = ord(opc$extend7));
                if not b then
                  if i^.opnds[3].h.unconsumed or
                     (integer32(i^.opnds[3].lts) = lir_main_c4c) then
                    b := (i^.opnds[2].lts = nil) and
                         (i^.opnds[2].h.kind = operand$immediate) and
                         (i^.opc = ord(opc$extractu)) and (i^.h.width = 8);
              end;
            if b then begin
              if remat <> nil then
                goto 10;
              fl.f.adjust := 3;
              fl.f.byte8 := true;
              d7 := lts_ptr_t(lir_main_c4c);
              goto 30;
            end;
            if i^.opc = ord(opc$extractu) then begin
              if op^.h.num <> 1 then
                goto 10;
              if i^.opnds[2].h.kind <> operand$immediate then
                goto 10;
              if i^.opnds[2].lts <> nil then
                goto 10;
              if remat <> nil then
                goto 10;
              if i^.h.width = 8 then begin
                fl.f.adjust := 3;
                fl.f.byte8 := true;
              end
              else if i^.h.width = 16 then begin
                fl.f.adjust := 2;
                fl.f.half16 := true;
              end
              else
                goto 10;
              d7 := i^.opnds[3].lts;
              if not d7^.lr^.f2.b3_0 then
                goto 30;
              fl.f.keep := true;
              goto 20;
            end;
            if instruction_attributes[i^.opc].class <> class$fp_control then
              goto 10;
            if remat <> nil then
              goto 10;
            d7 := i^.opnds[2].lts;
            if i^.opnds[1].h.kind = operand$fp_reg then
              if rrp$fp_reg_odd_only in i^.opnds[1].lts^.rrp then
                if i^.opnds[1].lts^.lr^.mate <> nil then
                  fl.f.adjust := 4;
            goto 30;
            { A new live range for the reload. }
10:
            fl.w := fl.w & (-145);
20:
            fl.f.new_lr := true;
            d7 := get_new_spill_lts(get_new_spill_lr(lrv));
30:
            if op^.h.kind <> operand$fp_reg_pair then
              mlts := nil
            else if fl.f.new_lr then
              mlts := get_new_mate_lts(op, lrv, i, d7)
            else
              mlts := find_mate_lts(i, d7);
            op^.lts := d7;
            if d7^.lr^.f2.physical or not fl.f.new_lr then begin
              rlink := nil;
              mop := nil;
            end
            else begin
              rlink := op^.link;
              if mlts = nil then
                mop := nil
              else
                mop := utils_$find_mate_operand(op)^.link;
            end;
            if remat <> nil then begin
              ni := rematerialize_result(remat, i, bb, d7, mlts, first, second);
            end
            else begin
              if integer32(d7) = lir_main_c4c then
                op^.h.kind := operand$ip_reg_like;
              form := pick_instruction(kind, fl.w, op, d7,
                  addr(spill_instr_forms.load_ptrs), v^.memory_home);
              ni := lir_$get_new_instruction_no_exceptions(
                  addr(lir_3b80), form^.opc, 16#2000, v^.memory_home, nil);
              spill_instr_forms.forms[3].num := 1;
              spill_instr_forms.forms[1].num := 2;
              tmp88 := nil;
              lir_utils_$flesh_out_new_load_or_store(
                  addr(ni^.opnds[3]), addr(ni^.opnds[4]), addr(ni^.opnds[1]),
                  addr(ni^.opnds[2]), v^.memory_home, d7, mlts, form, ni, i,
                  dbref, tmp88, new_db_lts);
              ni^.opnds[1].value := ni^.opnds[1].value + fl.f.adjust;
              first := addr(ni^.opnds[3]);
              second := addr(ni^.opnds[4]);
              ni^.h.may_generate_an_exception := true;
            end;
            if no_reg_pair_problem(first, rlink) then begin
              if rlink <> nil then begin
                if rrp$intend_to_modify in rlink^.lts^.rrp then
                  fill_intend_modify(d7);
                discard(link_other_readers(first, i, rlink, remat, kind, pass,
                    not complex));
              end;
              if mop <> nil then begin
                if rrp$intend_to_modify in mop^.lts^.rrp then
                  fill_intend_modify(mlts);
                discard(link_other_readers(second, i, mop, remat, kind, pass,
                    not complex));
              end;
            end;
            if fl.f.sets_cc then begin
              ni^.h.sets_cc := true;
              src := addr(i^.opnds[i^.h.nopnds]);
              dst := addr(ni^.opnds[ni^.h.nopnds]);
              dst^.h := src^.h;
              dst^.h.num := ni^.h.nopnds;
              dst^.lts := src^.lts;
              dst^.lts^.refs := dst;
              dst^.link := src^.link;
            end;
            if fl.f.clear then
              i^.h.b2_6 := false;
            if prev_ins = nil then begin
              ni^.next := bb^.first;
              bb^.first := ni;
              ni^.next^.prev := ni;
            end
            else begin
              ni^.next := prev_ins^.next;
              if ni^.next = nil then
                bb^.last := ni
              else
                ni^.next^.prev := ni;
              prev_ins^.next := ni;
              ni^.prev := prev_ins;
            end;
            ni^.bb := bb;
            prev_ins := ni;
          end;

          { The writes and modifies. }
          if (opnd_bytes_ptr_t(op)^.rrp & 12) = 0 then
            goto 60;
          if op^.h.modify then begin
            if remat <> nil then
              bug_check('RA_UTILS_$ADD_SPILL_CODE: modify of rematerialize victim.%$');
            mo := find_modify_opr(op);
            fl.f.new_lr := true;
            d7 := get_new_spill_lts(mo^.lts^.lr);
            goto 50;
          end;
          if remat <> nil then begin
            i^.h.b2_6 := false;
            goto 60;
          end;
          if instruction_attributes[i^.opc].b6_0 then begin
            if i^.opnds[1].h.kind in ru_movable then begin
              d7 := i^.opnds[1].lts;
              if not complex or (i^.opnds[2].link = nil) then begin
                if i^.h.sets_cc then
                  utils_$set_instruction_opcode(i, ord(opc$tst))
                else if not i^.h.fp_ccs then
                  i^.h.b2_6 := false
                else if op^.h.kind = operand$fp_reg_pair then
                  utils_$set_instruction_opcode(i, ord(opc$tstd))
                else
                  utils_$set_instruction_opcode(i, ord(opc$tsts));
                goto 50;
              end;
            end;
          end
          else if instruction_attributes[i^.opc].class = class$fp_control then
            if not i^.h.sets_cc then begin
              d7 := i^.opnds[1].lts;
              i^.h.b2_6 := false;
              goto 50;
            end;
          if not fl.f.keep then begin
            fl.f.new_lr := true;
            d7 := get_new_spill_lts(get_new_spill_lr(lrv));
          end;
50:
          if d7^.lr^.f2.physical then begin
            rl := nil;
            ml := nil;
          end
          else begin
            rl := op^.link;
            if op^.h.kind <> operand$fp_reg_pair then
              ml := nil
            else
              ml := utils_$find_mate_operand(op)^.link;
          end;
          if not fl.f.keep and (op^.h.kind = operand$fp_reg_pair) and
             not fl.f.new_lr then
            mlts := find_mate_lts(i, d7);
          old := op^.lts;
          op^.lts := d7;
          if not fl.f.keep then
            if op^.h.kind <> operand$fp_reg_pair then
              mlts := nil
            else if fl.f.new_lr then
              mlts := get_new_mate_lts(op, lrv, i, d7);
          form := pick_instruction(kind, 0, op, d7,
              addr(spill_instr_forms.store_ptrs), v^.memory_home);
          ni := lir_$get_new_instruction_no_exceptions(
              addr(lir_3b80), form^.opc, 16#2000, v^.memory_home, nil);
          spill_instr_forms.forms[3].num := 2;
          spill_instr_forms.forms[1].num := 3;
          tmp88 := nil;
          lir_utils_$flesh_out_new_load_or_store(
              addr(ni^.opnds[1]), addr(ni^.opnds[4]), addr(ni^.opnds[2]),
              addr(ni^.opnds[3]), v^.memory_home, d7, mlts, form, ni, i,
              dbref, tmp88, new_db_lts);
          op^.lts^.refs := op;
          op^.link := addr(ni^.opnds[1]);
          if rrp$fp_reg_odd_only in old^.rrp then
            if not (rrp$fp_reg_odd_only in d7^.rrp) then
              if lrv^.mate <> nil then
                if form^.kind <> 3 then
                  ni^.opnds[2].value := ni^.opnds[2].value + 4;
          ni^.h.may_generate_an_exception := true;
          { The later readers linked to the stored register. }
          if i^.h.b2_6 and not fl.f.keep then
            if no_reg_pair_problem(addr(ni^.opnds[1]), rl) then begin
              b1 := false;
              b2 := b1;
              if rl <> nil then begin
                if rrp$intend_to_modify in rl^.lts^.rrp then begin
                  fill_intend_modify(d7);
                  b1 := true;
                end;
                b2 := link_other_readers(addr(ni^.opnds[1]), i, rl, remat,
                    kind, pass, not complex);
              end;
              if ml <> nil then begin
                if rrp$intend_to_modify in ml^.lts^.rrp then
                  fill_intend_modify(mlts)
                else
                  b1 := false;
                if not link_other_readers(addr(ni^.opnds[4]), i, ml, remat,
                       kind, pass, not complex) then
                  b2 := false;
              end;
              if b2 and b1 then
                ni^.h.b2_6 := false;
            end;
          { A TST made of the writing move reads no register. }
          if i^.h.b2_6 then
            if i^.opc = ord(opc$tst) then
              i^.opnds[2].h.kind := operand$none
            else if i^.opc = ord(opc$tsts) then
              i^.opnds[2].h.kind := operand$none
            else if i^.opc = ord(opc$tstd) then begin
              i^.opnds[4].h.kind := operand$none;
              i^.opnds[2].h.kind := operand$none;
            end;
          if ni^.h.b2_6 then begin
            p := choose_store_position(op, ni, lrv, pass, ok);
            ni^.next := p^.next;
            if ni^.next = nil then
              bb^.last := ni
            else
              ni^.next^.prev := ni;
            p^.next := ni;
            ni^.prev := p;
            ni^.bb := bb;
            if ni^.next <> nil then
              if not ok then
                if (ni^.next^.opc = ord(opc$ipccnop)) or
                   (instruction_attributes[ni^.next^.opc].class in ru_fp_ops) then
                  ni^.h.grouped := true;
          end;
60:
        end;
70:
      if not (i^.h.grouped or
              (i^.h.atomic_update and (i^.next <> nil) and i^.next^.h.atomic_update)) then
        prev_ins := i;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.f2.b3_2 := false;
    lr := lr^.next;
  end;
  if at_backend_switches.sw14 and at_backend_switches.sw4 then
    dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
80:
end;
