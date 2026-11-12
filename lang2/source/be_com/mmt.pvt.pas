{ lang2/source/be_com/mmt.pvt.pas - the memory model's private insert (cc.a88k only): opened by mmt and
  mmt_utils, after the opcode enumeration.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  For now only the headings of mmt's and mmt_utils' global routines that the other calls, read off the frames and
  the callers' pushes (a pointer univ_ptr, a longword integer32, a word
  integer, a byte boolean; p1..pn); the units' translators add the
  types and cells the units share (docs/backend-plan.md).

  Not known from the original: every parameter name. }

{ TODO(pascal) mmt.pvt.pas: the shared types and cells }

{ mmt.pas (cc.a88k). }

{ MMT_$SIMPLIFY_TOKENS_IN_BB - 0x252544, 0x1BE bytes; called from
  mmt_utils.  Frame 8:al. }
procedure mmt_$simplify_tokens_in_bb(
    p1: univ_ptr); options(val_param); extern;

{ MMT_$ALLOCATE_SCRATCH_VECTORS - 0x2538EC, 0x76 bytes; called from
  mmt_utils.  Frame 8:l. }
procedure mmt_$allocate_scratch_vectors(
    p1: integer32); options(val_param); extern;

{ MMT_$INSERT_BLOCKS_INTRA_BB_SEQ - 0x253DA8, 0x3A0 bytes; called from
  mmt_utils.  Frame 8:al. }
procedure mmt_$insert_blocks_intra_bb_seq(
    p1: univ_ptr); options(val_param); extern;

{ mmt_utils.pas (cc.a88k). }

{ MMT_UTILS_$LR_IS_FOR_MEMORY - 0x255364, 0x56 bytes; called from mmt.
  Frame 8:al.  Result: D0 (callers: D0b3). }
function mmt_utils_$lr_is_for_memory(
    p1: univ_ptr): boolean; options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_EMIT - 0x255576, 0x34E bytes; called from mmt.  Frame
  8:al; 12:bw.  Result: A0 (callers: A05). }
function mmt_utils_$mmt_seq_emit(
    p1: univ_ptr;
    p2: integer): univ_ptr; options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKEN - 0x255942, 0x98 bytes; called from mmt.
  Frame 8:al; 12:bw; 14:b. }
procedure mmt_utils_$mmt_seq_add_token(
    p1: univ_ptr;
    p2: integer;
    p3: boolean); options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKENS_FROM_INSTR - 0x255A0C, 0x84 bytes; called
  from mmt.  Frame 8:al. }
procedure mmt_utils_$mmt_seq_add_tokens_from_instr(
    p1: univ_ptr); options(val_param); extern;

{ MMT_UTILS_$MMT_SEQ_ADD_TOKENS_FROM_BV - 0x255A90, 0x74 bytes; called
  from mmt.  Frame 8:l; 12:b; 14:bw.  Result: D0 (callers: D0b5). }
function mmt_utils_$mmt_seq_add_tokens_from_bv(
    p1: integer32;
    p2: boolean;
    p3: integer): boolean; options(val_param); extern;

{ MMT_UTILS_$CAN_COMBINE_MMT_SEQS - 0x255B04, 0x100 bytes; called from
  mmt.  Frame 8:l; 12:al; 16:l.  Result: D0 (callers: D0b2). }
function mmt_utils_$can_combine_mmt_seqs(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32): boolean; options(val_param); extern;
