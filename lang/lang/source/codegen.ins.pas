{ lang/lang/source/codegen.ins.pas - the m68k code generator's insert
  (cc.m68k's back end: cg_*, final, celpkg, ...).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what lang/lang/source/celpkg.pas (which opens it) needs
  is declared so far, the code cells, the address descriptors and
  CELPKG's routines (which insert of the back end declared them is not
  known; the cg_ and final units that call them open this one).

  Not known from the original: every name here but the routines'.
}

{ TODO(pascal) codegen.ins.pas is a stub

  Add the code generator's other declarations as its units are
  translated. }

const
  { The code cells' kinds (+8), the instructions' types.  outbin.pas's
    dbcod writes the kind with the names of an enumerated type of 59
    values (its write table at cc.m68k 0x0BE564: DEF_LBL_INSTYP,
    MOVE_INSTYP, ...); the cells keep it as an integer here because
    celpkg.pas, getcodecell's callers and the cells' clearing treat it
    as a number.  Not known from the original: the type's name. }
  def_lbl_instyp = 0;
  move_instyp = 1;
  moveq_instyp = 2;
  dest1_sz_instyp = 3;
  a_instyp = 4;
  q_instyp = 5;
  src2_sz_instyp = 6;
  dest2_sz_instyp = 7;
  i_instyp = 8;
  src2_instyp = 9;
  shft_d_instyp = 10;
  shft_cnt_instyp = 11;
  shft_mem_instyp = 12;
  cmpm_instyp = 13;
  i_w_instyp = 14;
  dest2_instyp = 15;
  dest1_instyp = 16;
  br_instyp = 17;
  cbr_instyp = 18;
  logicize_instyp = 19;
  link_instyp = 20;
  unlk_instyp = 21;
  rts_instyp = 22;
  dbcc_instyp = 23;
  line_no_instyp = 24;
  movemr_instyp = 25;
  moverm_instyp = 26;
  fop_instyp = 27;
  inline_instyp = 28;
  case_instyp = 29;
  casejmp_instyp = 30;
  bsr_instyp = 31;
  block_start_instyp = 32;
  block_end_instyp = 33;
  align_instyp = 34;
  nop_instyp = 35;
  tern_32u_instyp = 36;
  tern_src_ext_instyp = 37;
  tern_reg_reg_instyp = 38;
  fbr_instyp = 39;
  m68881_src_ext_instyp = 40;
  m68881_reg_reg_instyp = 41;
  m68881_dst_ext_instyp = 42;
  m68881_set_byte_instyp = 43;
  m68881_tst_reg_instyp = 44;
  m020_src2_instyp = 45;
  m020_dest2_instyp = 46;
  m020_dest1_instyp = 47;
  m68881_i_instyp = 48;
  m020_cmp2_instyp = 49;
  m68881_dest1_instyp = 50;
  m881_moverm_instyp = 51;
  m881_movemr_instyp = 52;
  m881_nop_instyp = 53;
  fpa_reg_reg_instyp = 54;
  fpa_load_instyp = 55;
  fpa_store_instyp = 56;
  fpa_mem_2reg_instyp = 57;
  fpa_cmp_instyp = 58;

type
  { An address descriptor, packed (12 bytes; the cells hold two): five
    small fields in the first three bytes, then two longwords.
    unpack_ads and pack_ads convert it to and from codegen_$uads_t. }
  codegen_$ads_t = packed record
    f1: 0..31;                          { +0.7..3 }
    f2: 0..31;                          { +0.2 to +1.6 }
    f3: 0..31;                          { +1.5..1 }
    f4: 0..3;                           { +1.0 to +2.7 }
    f5: 0..7;                           { +2.6..4 }
    f6: 0..7;                           { +2.3..1 }
    pad: 0..511;                        { +2.0 to +3.0: not used }
    x: integer32;                       { +4 (a label's node) }
    y: integer32;                       { +8 (a label's number) }
  end;

  { An address descriptor, unpacked (20 bytes).  cg.ins.pas declares it
    too, for a unit that opens it first (globals.ins.pas's
    codegen_uads_declared). }
%if not codegen_uads_declared %then
%enable codegen_uads_declared;
  codegen_$uads_t = record
    f1: integer;                        { +0 }
    f2: integer;                        { +2 }
    f3: integer;                        { +4 }
    f4: integer;                        { +6 }
    f5: integer;                        { +8 }
    f6: integer;                        { +10 }
    x: integer32;                       { +12 }
    y: integer32;                       { +16 }
  end;
%endif

  { A code cell (getcodecell: 52 bytes, 20 for kinds 24, 32, 33) or a
    reference cell (getrefcell: 16 bytes), on a circular list. }
  codegen_$cell_ptr_t = ^codegen_$cell_t;
  codegen_$cell_t = record
    next: codegen_$cell_ptr_t;          { +0 }
    prev: codegen_$cell_ptr_t;          { +4 }
    case integer of
      { A code cell. }
      1: (kind: integer;                { +8: the instruction's kind }
          c_10: array [1..7] of integer;  { +10: cleared, but for the
                                          small cells }
          ads1: codegen_$ads_t;         { +24 }
          ads2: codegen_$ads_t);        { +36: a label's (getlabcell) }
      { A reference cell, on its owner's list. }
      2: (target: integer32;            { +8 }
          owner: codegen_$cell_ptr_t);  { +12 }
      { The owner of reference cells: their list at +32. }
      3: (c3_8: array [1..12] of integer;   { +8 }
          refs: codegen_$cell_ptr_t);   { +32 }
      { A line number cell (line_no_instyp: the source line), a block's
        start or end (block_start_instyp, block_end_instyp: the
        block's first line and its node); outbin.pas.  Other cells
        keep a word and a longword there (dbcod prints them as `len'
        and in hexadecimal). }
      4: (c4_8: integer;                { +8 }
          line: integer;                { +10 }
          blk: il_$node_ptr_t;          { +12: a line number cell's list
                                          of equivalent lines }
          ret: boolean);                { +16: a line number cell's
                                          statement returns (outbin's
                                          wr_instr) }
      { A branch (br_instyp, cbr_instyp, bsr_instyp: its size, 2 short
        and 6 long, and its target's number) or a label (def_lbl_instyp:
        its address, which outbin's br_distance reads through the
        reference cell's owner). }
      5: (c5_8: integer;                { +8 }
          size: integer;                { +10 }
          addr: integer32;              { +12 }
          c5_16: array [1..4] of integer;   { +16 }
          c5_ads1: codegen_$ads_t;      { +24 }
          c5_ads2: codegen_$ads_t;      { +36 }
          op: integer;                  { +48: the instruction (outbin's
                                          tables are indexed by it) }
          c5_50: integer);              { +50 }
  end;

{ INIT_CELPKG - no cells allocated.  0x0B645C (final's f_initialize). }
procedure init_celpkg; extern;

{ GETLABCELL - a label cell for lab (nil: a new numbered label).
  0x0B648E: lab a pointer by value, the cell in A0. }
function getlabcell(
    lab: il_$node_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

{ GETREFCELL - a reference cell to target on owner's list.  0x0B650A:
  target a longword and owner a pointer by value, the cell in A0. }
function getrefcell(
    target: integer32;
    owner: codegen_$cell_ptr_t): codegen_$cell_ptr_t;
    options(val_param); extern;

{ GETCODECELL - a code cell of kind.  0x0B6582: kind by address (22
  call sites, most passing a constant), the cell in A0. }
function getcodecell(
    in kind: integer): codegen_$cell_ptr_t; extern;

{ AFTER - link b after a.  0x0B6652: two pointers by value. }
procedure after(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t); options(val_param); extern;

{ DELINK - take c off its list.  0x0B6682: a pointer by value. }
procedure delink(
    c: codegen_$cell_ptr_t); options(val_param); extern;

{ JOIN - splice list b in after a.  0x0B66AE: two pointers by value. }
procedure join(
    a: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t); options(val_param); extern;

{ EMPTY - whether c's list holds only c.  0x0B66EE: no caller in
  cc.m68k. }
function empty(
    c: codegen_$cell_ptr_t): boolean; options(val_param); extern;

{ PACK_ADS, UNPACK_ADS - an address descriptor packed and unpacked.
  0x0B670A, 0x0B6838: both by address. }
procedure pack_ads(
    in u: codegen_$uads_t;
    out p: codegen_$ads_t); extern;

procedure unpack_ads(
    in p: codegen_$ads_t;
    out u: codegen_$uads_t); extern;

{ ILENGTH - the length in bytes of code cell c's instruction.  emit.pas
  0x0B70A0: a pointer by value, a word in D0 (jmp_br_resolve). }
function ilength(
    c: codegen_$cell_ptr_t): integer; options(val_param); extern;

{ FNL_SLCT - a code cell of the machine instruction for op and size on
  operands dst and src (x the extra longword).  emit.pas 0x0B738E: two
  words, a longword, the descriptors' addresses; the cell in A0
  (jmp_br_resolve passes 37, 5, 0, a branch's descriptor and
  cg_null_ads). }
function fnl_slct(
    op: integer;
    size: integer;
    x: integer32;
    in dst: codegen_$uads_t;
    in src: codegen_$uads_t): codegen_$cell_ptr_t; options(val_param); extern;

{ CREATE_TEMP_LABEL - a new temporary label node (kind 144).
  0x0B68AA: no parameters, the node in A0. }
function create_temp_label: il_$node_ptr_t; extern;
