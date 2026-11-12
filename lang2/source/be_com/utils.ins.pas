{ lang2/source/be_com/utils.ins.pas - be_com utils.pas's insert
  (cc.a88k only): opened last, after the opcode enumeration, by 29
  be_com units (asm, at_backend, com, df_utils, dfa, fg_utils, fga,
  hal, iv, konst, life, lir, lir_main, lir_utils, mmt, mmt_utils, oli,
  post, ra, ra_utils, sanity, sched, sched_utils, sem_utils, tm_utils,
  tr_utils, trans, utils, xtp).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  It holds a routine body: utils_ins_$operands_instruction
  is compiled into each unit that calls it (19 units: com, df_utils,
  fg_utils, fga, iv, konst, life, mmt, mmt_utils, oli, ra, ra_utils,
  sanity, sched, sched_utils, tr_utils, trans, utils, xtp, each copy
  at its unit's start); the units that open the insert without calling
  it have none, so Rev 8.89 dropped an internal routine nothing calls.
  dpc keeps it (an extra routine the gate reports as missing from the
  image).

  The headings of utils.pas's global routines that other units call
  were read off its frames and the callers' pushes (a pointer univ_ptr,
  a longword integer32, a word integer, a byte boolean; p1..pn): the
  translator of utils.pas narrows them.

  Not known from the original: every parameter name. }

{ UTILS_INS_$OPERANDS_INSTRUCTION - the instruction an operand is in:
  the k-th operand is at the instruction's +32 + 12k and holds k at its
  +0.  (xtp 0x287ABC, 0x22 bytes: no frame, the operand at (4,SP),
  `clr.w; move.b (A0)' times 12 as a word (`lsl.w #2', the double
  added), subtracted with 32 from the operand's address; A0.) }
function utils_ins_$operands_instruction(
    o: opnd_ptr_t): instr_ptr_t; options(val_param); internal;
begin
  utils_ins_$operands_instruction :=
    instr_ptr_t(integer32(o) - 32 - o^.h.num * 12);
end;

{ utils.pas (cc.a88k). }

{ UTILS_$BEGIN_COMPILATION - 0x28493E, 0x44 bytes; called from at_backend.
  }
procedure utils_$begin_compilation; extern;

{ UTILS_$END_COMPILATION - 0x2849A6, 0x1C bytes; called from at_backend. }
procedure utils_$end_compilation; extern;

{ UTILS_$EXCISE_INSTRUCTION_CLEANLY - 0x2849C2, 0x18E bytes; called from
  com fg_utils konst sanity tr_utils trans.  Frame 8:al; 12:bw.  Result:
  read (callers: D01). }
function utils_$excise_instruction_cleanly(
    p1: univ_ptr;
    p2: boolean): integer32; options(val_param); extern;

{ UTILS_$EXCISE_INSTRUCTION_IF_UNCONSUMED - 0x284B90, 0x7E bytes; called
  from iv.  Frame 8:a; 12:b.  Result: D0 (callers: D0b1). }
function utils_$excise_instruction_if_unconsumed(
    p1: univ_ptr;
    p2: boolean): boolean; options(val_param); extern;

{ UTILS_$REMOVE_READER_FROM_LTS - 0x284C0E, 0xC0 bytes; called from com
  konst tr_utils trans.  Frame 8:al; 12:b.  Result: read (callers: D01). }
function utils_$remove_reader_from_lts(
    p1: univ_ptr;
    p2: boolean): integer32; options(val_param); extern;

{ UTILS_$REMOVE_LTS_FROM_EXPOSED_LIST - 0x284D3A, 0xB6 bytes; called from
  com fg_utils tr_utils trans.  Frame 8:al. }
procedure utils_$remove_lts_from_exposed_list(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$REMOVE_LTS_FROM_FINAL_LIST - 0x284E36, 0xB6 bytes; called from
  com fg_utils tr_utils trans.  Frame 8:a. }
procedure utils_$remove_lts_from_final_list(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$EXCISE_LTS_CLEANLY - 0x284F28, 0x128 bytes; called from com
  fg_utils iv sanity tr_utils trans.  Frame 8:al; 12:bw. }
procedure utils_$excise_lts_cleanly(
    p1: univ_ptr;
    p2: boolean); options(val_param); extern;

{ UTILS_$MAYBE_MERGE_SOURCE_STATEMENTS - 0x285110, 0x10E bytes; called
  from tr_utils trans.  Frame 8:al; 12:al. }
procedure utils_$maybe_merge_source_statements(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ UTILS_$GUARANTEE_INSTR_SEQUENCE - 0x28521E, 0x56 bytes; called from mmt
  trans.  Frame 8:al. }
procedure utils_$guarantee_instr_sequence(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$RESEQUENCE_INSERTED_INSTRUCTION - 0x285274, 0x5A bytes; called
  from tr_utils.  Frame 8:al. }
procedure utils_$resequence_inserted_instruction(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$INITIALIZE_LTS_HINT_POINTERS - 0x2852CE, 0x3E bytes; called from
  mmt_utils.  Frame 8:al. }
procedure utils_$initialize_lts_hint_pointers(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$FIND_EXPOSED_LTS - 0x28530C, 0xEA bytes; called from com fg_utils
  lir_utils oli tr_utils trans.  Frame 8:al; 12:al.  Result: A0 (callers:
  A014). }
function utils_$find_exposed_lts(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$FIND_FINAL_LTS - 0x2853F6, 0xEA bytes; called from df_utils iv
  oli sched tr_utils trans.  Frame 8:al; 12:al.  Result: A0 (callers:
  A019). }
function utils_$find_final_lts(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$PUT_LTS_ON_EXPOSED_LIST - 0x2854E0, 0xDC bytes; called from com
  fg_utils iv tr_utils trans.  Frame 8:al. }
procedure utils_$put_lts_on_exposed_list(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$PUT_LTS_ON_FINAL_LIST - 0x2855FC, 0xDE bytes; called from com
  fg_utils iv tr_utils trans.  Frame 8:al. }
procedure utils_$put_lts_on_final_list(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$FIND_LAST_LTS_IN_BB - 0x285714, 0xAA bytes; called from com
  fg_utils iv tr_utils trans.  Frame 8:al; 12:al; 16:a.  Result: A0
  (callers: A010).  lr's last segment in bb; the one before it through
  prev (tr_utils' reading of its calls). }
function utils_$find_last_lts_in_bb(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    out prev: lts_ptr_t): lts_ptr_t; options(val_param); extern;

{ UTILS_$GET_NEW_LTS - 0x2857BE, 0xDA bytes; called from com ra_utils
  tr_utils trans.  Frame 8:al; 12:al; 16:bw.  Result: A0 (callers: A09). }
function utils_$get_new_lts(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer): univ_ptr; options(val_param); extern;

{ UTILS_$GET_EXPOSED_LTS - 0x285898, 0x72 bytes; called from com fg_utils
  iv lir_utils ra_utils tr_utils trans.  Frame 8:al; 12:al; 16:a.  Result:
  A0 (callers: A020). }
function utils_$get_exposed_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    out created: boolean): lts_ptr_t; options(val_param); extern;

{ UTILS_$GET_FINAL_LTS - 0x28590A, 0x7C bytes; called from com fg_utils iv
  tr_utils trans.  Frame 8:al; 12:l; 16:a.  Result: A0 (callers: A015
  D0w1).  lr's final segment in bb (nil for no lr), a new one put on
  the final list when there is none (created true; the body read by
  tr_utils' translator). }
function utils_$get_final_lts(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    out created: boolean): lts_ptr_t; options(val_param); extern;

{ UTILS_$COMPARE_BIRTHPOINTS - 0x285986, 0x70 bytes; called from com
  mmt_utils.  Frame 8:a; 12:a.  Result: D0 (callers: D0b3). }
function utils_$compare_birthpoints(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;

{ UTILS_$GET_CANONICAL_BIRTHPOINT - 0x285ABA, 0x400 bytes; called from com
  mmt_utils trans.  Frame 8:al; 12:w; 14:al.  Result: A0 (callers: D01). }
function utils_$get_canonical_birthpoint(
    p1: univ_ptr;
    p2: integer;
    p3: univ_ptr): integer32; options(val_param); extern;

{ UTILS_$SET_INSTRUCTION_OPCODE - 0x285F16, 0x44 bytes; called from oli
  ra_utils tr_utils trans.  Frame 8:a; 12:w. }
procedure utils_$set_instruction_opcode(
    p1: univ_ptr;
    p2: integer); options(val_param); extern;

{ UTILS_$COPY_INSTR_TEMPLATE_TO_BB_END - 0x286128, 0x62 bytes; called from
  com fg_utils oli.  Frame 8:al; 12:al.  Result: D0 (callers: A03 D0l1). }
function utils_$copy_instr_template_to_bb_end(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$COPY_INSTR_TEMPLATE_TO_BB_HEAD - 0x28618A, 0x50 bytes; called
  from com oli ra_utils.  Frame 8:al; 12:al.  Result: D0 (callers: A03). }
function utils_$copy_instr_template_to_bb_head(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$COMPLETE_COPIED_INSTR - 0x286230, 0x14E bytes; called from com
  fg_utils oli ra_utils.  Frame 8:al.  Result: read (callers: D01). }
function utils_$complete_copied_instr(
    p1: univ_ptr): integer32; options(val_param); extern;

{ UTILS_$COMPLETE_COPIED_INSTR_AT_BB_HEAD - 0x28637E, 0x1E6 bytes; called
  from com ra_utils.  Frame 8:al. }
procedure utils_$complete_copied_instr_at_bb_head(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$STRIP_EXTRANEOUS_MODIFIES - 0x286700, 0x19A bytes; called from
  life ra.  Frame 8:al. }
procedure utils_$strip_extraneous_modifies(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$MOVE_DEFINITION - 0x286A22, 0xD6 bytes; called from com tr_utils
  trans.  Frame 8:al; 12:al; 16:bw. }
procedure utils_$move_definition(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: boolean); options(val_param); extern;

{ UTILS_$LOCATE_DEFINITION - 0x286B88, 0xD2 bytes; called from com oli
  tr_utils.  Frame 8:al; 12:al.  Result: A0 (callers: A012). }
function utils_$locate_definition(
    p1: univ_ptr;
    p2: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$FIND_JOIN_BP - 0x286C5A, 0x48 bytes; called from trans.  Frame
  8:a.  Result: A0 (callers: A03). }
function utils_$find_join_bp(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$ADD_BIRTHPOINT - 0x286CA2, 0x12A bytes; called from fg_utils iv
  oli trans.  Frame 8:al; 12:al; 16:bw.  Result: read (callers: D02). }
function utils_$add_birthpoint(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer): integer32; options(val_param); extern;

{ UTILS_$APPLY_FUNC_TO_ALL_DEFS - 0x286FDA, 0x134 bytes; called from com.
  Frame 8:l; 12:al; 16:l.  Result: D0 (callers: D0l1). }
function utils_$apply_func_to_all_defs(
    p1: integer32;
    p2: univ_ptr;
    p3: integer32): integer32; options(val_param); extern;

{ UTILS_$APPLY_FUNC_TO_ALL_USES - 0x28720E, 0xEA bytes; called from com
  tr_utils.  Frame 8:al; 12:al; 16:al.  Result: D0 (callers: D0b2). }
function utils_$apply_func_to_all_uses(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr): boolean; options(val_param); extern;

{ UTILS_$FIND_MATE_OPERAND - 0x28733A, 0x182 bytes; called from com
  lir_utils ra_utils tm_utils.  Frame 8:al.  Result: A0 (callers: A015). }
function utils_$find_mate_operand(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ UTILS_$INSTR_IS_REF_TO_ARGUMENT_BLOCK - 0x287608, 0x34 bytes; called
  from lir.  Frame 8:al.  Result: D0 (callers: D0b2). }
function utils_$instr_is_ref_to_argument_block(
    p1: univ_ptr): boolean; options(val_param); extern;

{ UTILS_$INSTR_IS_REF_TO_MEMORY_HOME - 0x28763C, 0x196 bytes; called from
  lir_main ra_utils.  Frame 8:al.  Result: D0 (callers: D0b3). }
function utils_$instr_is_ref_to_memory_home(
    p1: univ_ptr): boolean; options(val_param); extern;

{ UTILS_$INSTRS_CONSUME_IDENTICAL_SYMBOLS - 0x2877D2, 0x16C bytes; called
  from ra_utils.  Frame 8:al; 12:al.  Result: D0 (callers: D0b1). }
function utils_$instrs_consume_identical_symbols(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;

{ UTILS_$STRIP_MAY_GEN_EXCEPTION - 0x28793E, 0xB0 bytes; called from lir.
  Frame 8:al. }
procedure utils_$strip_may_gen_exception(
    p1: univ_ptr); options(val_param); extern;

{ UTILS_$FIND_UNUSED_OPERAND_SLOT - 0x2879EE, 0x80 bytes; called from lir.
  Frame 8:al; 12:al.  Result: D0 (callers: D0l4). }
function utils_$find_unused_operand_slot(
    p1: univ_ptr;
    p2: univ_ptr): integer32; options(val_param); extern;
