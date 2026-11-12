{ lang2/source/be_com/mmt.pvt.pas - the memory model's private insert
  (cc.a88k only): opened by mmt and mmt_utils, after the opcode
  enumeration.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  It holds what mmt and mmt_utils share: the memory tokens
  (one for each class of memory references found to touch the same
  storage), the views of the back end's records through which the two
  units read the fields only the memory model uses (kept out of
  backend.ins.pas while batch A settles those records' names), mmt's
  cells mmt_utils reaches, and the headings each unit calls in the
  other.

  Not known from the original: every type, field, cell and parameter
  name. }

type
  { A memory token (60 bytes; mmt's token heap hands out 64): next on
    the active list of an MMT_SEQ being built (mmt_active); lr (+36)
    the live range standing for its memory; related and compared
    (+40, +44) the bit vectors of the tokens it may overlap and has
    been compared with; equiv (+48) the token it is equivalent to; id
    (+56) its number (the descriptor's); read and written (+58 bits
    7, 6) what the MMT_SEQ being built does with it; equivalent (+58
    bit 1) set when its descriptor had an equivalent; +58 bit 4 set on
    mmt's first static token. }
  mmt_token_ptr_t = ^mmt_token_t;
  mmt_token_t = record
    next: mmt_token_ptr_t;              { +0 }
    space4: array [4..35] of char;      { +4 }
    lr: lr_ptr_t;                       { +36 }
    related: univ_ptr;                  { +40 }
    compared: univ_ptr;                 { +44 }
    equiv: mmt_token_ptr_t;             { +48 }
    l52: univ_ptr;                      { +52 }
    id: integer;                        { +56 }
    f: packed record                    { +58 }
      read: boolean;                    { .7 }
      written: boolean;                 { .6 }
      b5: boolean;
      b4: boolean;                      { .4 }
      b3, b2: boolean;
      equivalent: boolean;              { .1 }
      b0: boolean;
      b59: 0..255;                      { +59 }
      end;
  end;
  mmt_token_map_t = array [1..1000000] of mmt_token_ptr_t;
  mmt_token_map_ptr_t = ^mmt_token_map_t;

  { The memory model's view of a basic block: its lists of exposed
    (+62, chained at a segment's +16) and final (+66, at +20) lifetime
    segments. }
  mmt_bb_v_ptr_t = ^mmt_bb_v_t;
  mmt_bb_v_t = record
    space0: array [0..61] of char;
    exposed: lts_ptr_t;                 { +62 }
    final: lts_ptr_t;                   { +66 }
  end;

  { The memory model's view of a lifetime segment: the exposed and final
    lists' links, desc (+36) the descriptor mmt_utils gave it, last
    (+40) the last operand that reads it (chained through the operands'
    links). }
  mmt_lts_v_ptr_t = ^mmt_lts_v_t;
  mmt_lts_v_t = record
    space0: array [0..15] of char;
    next_exposed: lts_ptr_t;            { +16 }
    next_final: lts_ptr_t;              { +20 }
    space24: array [24..35] of char;
    desc: integer32;                    { +36 }
    last: opnd_ptr_t;                   { +40 }
  end;

  { The memory model's view of a live range: kind (+8, a byte: 28 is
    made 27), uses (+44) the operands that refer to it (chained through
    their links), +52 its token or the segment being filled in. }
  mmt_lr_v_ptr_t = ^mmt_lr_v_t;
  mmt_lr_v_t = record
    space0: array [0..7] of char;
    f8: packed record                   { +8 }
      kind: 0..255;
      b9: 0..255;
      end;
    space10: array [10..43] of char;
    uses: opnd_ptr_t;                   { +44 }
    space48: array [48..51] of char;
    case integer of                     { +52 }
      1: (token: mmt_token_ptr_t);
      2: (cur: lts_ptr_t);
  end;

  { The memory model's view of the routine: mem_lr (+140) the live range
    of the routine's memory, all_lr (+144) the one mmt makes for all
    memory (a return's). }
  mmt_rtn_v_ptr_t = ^mmt_rtn_v_t;
  mmt_rtn_v_t = record
    space0: array [0..139] of char;
    mem_lr: lr_ptr_t;                   { +140 }
    all_lr: lr_ptr_t;                   { +144 }
  end;

var
  { mmt.pas's data (A5 0x48C368) that mmt_utils reaches absolutely
    (translators PC, PC2); mmt defines them. }
  mmt_count: extern integer32;          { +0xC0: the tokens (mmt_utils:
                                          the descriptors) numbered }
  mmt_level: extern integer32;          { +0xC4: the debug level }
  mmt_rtn: extern rtn_ptr_t;            { +0xC8: the routine }
  mmt_seq_heap: extern mrh_$heap_t;     { +0xCC: the MMT_SEQ
                                          instructions' heap (made
                                          lir_main_heap around their
                                          allocation) }
  mmt_active: extern mmt_token_ptr_t;   { +0xE0: the tokens the MMT_SEQ
                                          being built reads or writes }
  mmt_scratch: extern univ_ptr;         { +0xE4: a scratch bit vector }
  mmt_token_heap: extern mrh_$heap_t;   { +0xE8: the tokens' heap }
  mmt_last_token: extern mmt_token_t;   { +0x100: a copy of the last
                                          token made }
  mmt_140: extern univ_ptr;             { +0x140: a bit vector of live
                                          ranges (mmt_utils: active on
                                          exit) }
  mmt_token_map: extern mmt_token_map_ptr_t;   { +0x1A8: the tokens by
                                          number }

{ mmt.pas (cc.a88k). }

{ MMT_$SIMPLIFY_TOKENS_IN_BB - 0x252544, 0x1BE bytes; called from
  mmt_utils.  Frame 8:al. }
procedure mmt_$simplify_tokens_in_bb(
    bb: bb_ptr_t); options(val_param); extern;

{ MMT_$ALLOCATE_SCRATCH_VECTORS - 0x2538EC, 0x76 bytes; called from
  mmt_utils (with the bytes of a bit vector).  Frame 8:l. }
procedure mmt_$allocate_scratch_vectors(
    bytes: integer32); options(val_param); extern;

{ MMT_$INSERT_BLOCKS_INTRA_BB_SEQ - 0x253DA8, 0x3A0 bytes; called from
  mmt_utils.  Frame 8:al. }
procedure mmt_$insert_blocks_intra_bb_seq(
    bb: bb_ptr_t); options(val_param); extern;

{ mmt_utils.pas (cc.a88k). }

{ MMT_UTILS_$LR_IS_FOR_MEMORY - 0x255364, 0x56 bytes; called from mmt.
  Frame 8:al.  Result: D0 (callers: D0b3). }
function mmt_utils_$lr_is_for_memory(
    lr: lr_ptr_t): boolean; options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_EMIT - an MMT_SEQ of the active tokens next to
  anchor.  0x255576, 0x34E bytes; called from mmt.  Frame 8:al; 12:bw.
  Result: A0 (callers: A05). }
function mmt_utils_$mmt_seq_emit(
    anchor: instr_ptr_t;
    after: boolean): instr_ptr_t; options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKEN - 0x255942, 0x98 bytes; called from mmt.
  Frame 8:al; 12:bw; 14:b. }
procedure mmt_utils_$mmt_seq_add_token(
    token: mmt_token_ptr_t;
    read: boolean;
    written: boolean); options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKENS_FROM_INSTR - 0x255A0C, 0x84 bytes; called
  from mmt.  Frame 8:al. }
procedure mmt_utils_$mmt_seq_add_tokens_from_instr(
    instr: instr_ptr_t); options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKENS_FROM_BV - 0x255A90, 0x74 bytes; called
  from mmt.  Frame 8:l; 12:b; 14:bw.  Result: D0 (callers: D0b5). }
function mmt_utils_$mmt_seq_add_tokens_from_bv(
    bv: univ_ptr;
    read: boolean;
    written: boolean): boolean; options(val_param); extern;

{ MMT_UTILS_$CAN_COMBINE_MMT_SEQS - 0x255B04, 0x100 bytes; called from
  mmt.  Frame 8:l; 12:al; 16:l.  Result: D0 (callers: D0b2). }
function mmt_utils_$can_combine_mmt_seqs(
    seq: instr_ptr_t;
    bv: univ_ptr;
    live: univ_ptr): boolean; options(val_param); extern;
