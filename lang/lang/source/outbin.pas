{ outbin - OUTBIN, the m68k back end's object code output: outcode walks
  each section's code cells (CELPKG's) in source order, assembles each
  instruction (assemble, genfpinst, the extension words of wr_addr_ext,
  the constants of define_constant) into the object file through
  unix_objmod's emit_16, notes the relocations of the routines' address
  constants (add_proc_reloc, onto unix_objmod's list) and the line
  numbers (the COFF line entries of ln_begin, ln_number and ln_end, and
  the .lines section's statements through GEN_DEBUG_, the stack_debug_
  routines buffering an inlined block's), writes the section headers of
  the code sections and, under -EXP, the expanded listing (the
  instructions in assembler form: prtads, prtlabel, the FPX and FPA
  instructions); dbcod dumps the cells.

  Image addresses (DOMAIN C 6.9; cc.m68k only: cc.a88k has empty
  add_proc_reloc and outcode in lang2/source/be_com/target_at_dummies.pas):
    cc.m68k   cc.a88k
    0x0BBE28  --------  assert_is_an_fpx_command_instr
    0x0BBEF0  --------  attempt_fpx_command_opcode_disassembly
    0x0BC128  --------  assert_are_producing_68k_expanded_listing
    0x0BC140  --------  assert_is_line_no_instyp
    0x0BC158  --------  assert_is_inlined_block
    0x0BC178  --------  assert_is_inline_block_start
    0x0BC1A2  --------  assert_is_inline_block_end
    0x0BC1CC  --------  assert_inline_block_start_follows
    0x0BC1F2  --------  assert_is_interesting_line_no_instyp
    0x0BC22C  --------  format_hint_for_line_number
    0x0BC27C  --------  emit_hint_for_line_number
    0x0BC29A  --------  emit_hint_for_inlined_routine_line_no_instyp
    0x0BC350  --------  purge_stack
    0x0BC484  --------  next_put_element
    0x0BC504  --------  stack_debug_$lines_stmt_end
    0x0BC522  --------  stack_debug_$range_open
    0x0BC5F4  --------  stack_debug_$lines_def
    0x0BC62E  --------  stack_debug_$lines_entry
    0x0BC63E  --------  stack_debug_$lines_return
    0x0BC64E  --------  stack_debug_$range_close
    0x0BC688  --------  begin_unwind_scope
    0x0BC76A  --------  end_unwind_scope
    0x0BC7AE  --------  bit_fld_op
    0x0BC7EA  --------  show_assign
    0x0BCA98  --------  sort_ln_bb
    0x0BCB46  --------  put_ln_index
    0x0BCB92  --------  ln_begin
    0x0BCD34  --------  ln_number
    0x0BCE62  --------  ln_end
    0x0BCFA2  --------  write_proc
    0x0BD00C  --------  prtlabel
    0x0BD0BC  --------  prt_bit_field
    0x0BD212  --------  prt_expr_bit_field
    0x0BD2EA  --------  dump_bit_field
    0x0BD56C  --------  dump_expr_bit_field
    0x0BD696  --------  prt_int_regs
    0x0BD85E  --------  fp_get_sin_regname
    0x0BD88C  --------  prt_fp_regs
    0x0BDAE0  --------  prtads
    0x0BDF34  --------  prtsiz
    0x0BDFEC  --------  dbcod
    0x0BE96A  --------  br_distance
    0x0BE9D0  --------  pc_disp_ok
    0x0BEA06  --------  gen_ea_bits
    0x0BEB12  --------  fpreg_ord (in genfpinst)
    0x0BEB1C  --------  fpreg (in genfpinst)
    0x0BEB32  --------  genfpinst
    0x0BED86  --------  areg
    0x0BED92  --------  assemble
    0x0BF1A8  --------  fardisp
    0x0BF21C  --------  init_proc_reloc
    0x0BF23E  --------  dump_proc_reloc
    0x0BF2D2  --------  get_reloc_symndx
    0x0BF472  --------  add_proc_reloc
    0x0BF506  --------  reloc_proc_addr (in outcode)
    0x0BF606  --------  define_constant (in outcode)
    0x0BFA5C  --------  check_addressing_mode (in wr_instr)
    0x0BFB06  --------  wr_addr_ext (in wr_instr)
    0x0C0016  --------  coff_lines_proc_start (in wr_instr)
    0x0C01D4  --------  coff_lines_proc_end (in wr_instr)
    0x0C02EC  --------  coff_equiv_lines (in wr_instr)
    0x0C0346  --------  coff_lines_instruction (in wr_instr)
    0x0C0420  --------  executable_insts_follow_prev_lineno (in wr_instr)
    0x0C0464  --------  wr_instr (in outcode)
    0x0C1B94  --------  wr_section (in outcode)
    0x0C1CFC  --------  outbin_$firstln (in outcode)
    0x0C1D5C  --------  next_section (in outcode)
    0x0C1DBA  --------  init_section_info (in outcode)
    0x0C1E58  --------  reset_section_info (in outcode)
    0x0C1FC6  --------  outcode
    A5 0x2D179C (cc.m68k): the module's data, 0xDBC bytes (to
    reg_action's), laid out as the variables below in their order:
      +0x0     the floating registers' names (FP0..FP7)
      +0x1E    the relocations collected for a section's procedure
               constants (a count, then 25 pairs at +0x20)
      +0xE8    the listing line
      +0x1F0   the 32 register contents show_assign last printed
      +0x270   the FPA extension words, +0x3B8 the FPA instructions'
               names, +0x780 their operation words (161 each)
      +0x8C8   the 68881 commands' names (64), +0xC48 the format
               letters, +0xC50 eight bit masks
      +0xC60   the scalars (the stack of inlined blocks, the section
               table, offsets, the line number buffers, the listing
               state); +0xCD0, +0xCF0, +0xD10 and +0xD40 four copies of
               the integer registers' names (the static tables of
               prt_int_regs, prtads, dbcod and wr_instr); +0xD60 the
               unwind scope; +0xD90 to +0xDB6 the .lines state.
    .rwdi initializes the tables and some scalars (noted with them).
    At -4 the address of pas_$output (the dumps' writes).

  The module-level routines that load A5 are global; the others are
  internal.  reloc_proc_addr, define_constant, wr_instr, wr_section,
  outbin_$firstln, next_section, init_section_info and
  reset_section_info are nested in outcode and use its locals (-8 the
  section being written, -12 the last one); reset_section_info takes
  outcode's frame from its dynamic link (docs/rev889-patterns.md 25).
  check_addressing_mode, wr_addr_ext, the coff_lines_ routines and
  executable_insts_follow_prev_lineno are nested in wr_instr; wr_addr_ext
  and coff_lines_proc_start and _end take its frame from the dynamic
  link.  fpreg_ord and fpreg are nested in genfpinst.

  The nodes' fields are read through il.ins.pas's views by offset, the
  code cells through codegen.ins.pas's variants.

  Not known from the original: the names of the module's variables, the
  locals and the parameters; the record types of the line number
  buffers, the stack of inlined blocks and the section table. }
module outbin;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/vfmt.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/final.ins.pas';
%include 'us/us/ins/fpp.ins.pas';
%include '/sys/ins/fpp.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'lang/lang/source/unix_objmod.ins.pas';
%include 'lang/lang/source/gen_unwind.ins.pas';
%include 'us/us/sys/ins/unwind.ins.pas';
%include 'lang/lang/source/gen_debug.ins.pas';
%include 'lang/lang/source/fop.ins.pas';

{ Foreign routines and cells the unit uses that none of its inserts
  declares (docs/questions.md): }

{ DBL_TO_REAL - kfold.pas 0x0ACDC2: the double constant p made single,
  an overflow reported with line; the single in D0 (as unix_objmod.pas
  declares it; docs/dpc-gaps.md 19). }
function dbl_to_real(
    p: il_$node_ptr_t;
    line: integer): real; options(val_param); extern;

type
  { The current block's line table (cg_top's +0x130, set from a block's
    +120): a basic block and its first line, 8 bytes apart, the first at the
    pointer's target; its count is IL's +0x124. }
  outbin_ln_bb_t = record
    blk_no: unix_objmod_$count_t;       { +0: a basic block (show_assign
                                          is given its low word) }
    line: integer;                      { +4 }
    pad: integer;                       { +6 }
  end;
  outbin_ln_bb_ptr_t = ^array [1..4000] of outbin_ln_bb_t;

  { A pair of longwords: a relocation of dump_proc_reloc's, the words of
    a longword or a double. }
  outbin_long_t = record
    case integer of
      1: (l: integer32);
      2: (high: integer;
          low: integer);
      3: (c: array [1..4] of char);
      4: (r: real);
  end;
  outbin_double_t = record
    case integer of
      1: (d: double);
      2: (l: array [1..2] of integer32);
      3: (w: array [1..4] of integer);
  end;
  outbin_pair_t = record
    a: integer32;
    b: integer32;
  end;

  { A register's name, a floating register's, an FPA instruction's. }
  outbin_reg_name_t = array [1..2] of char;
  outbin_reg_names_t = array [0..15] of outbin_reg_name_t;
  outbin_fp_name_t = array [1..3] of char;
  outbin_fpa_name_t = array [1..6] of char;
  outbin_fpx_name_t = record
    length: integer;
    body: array [1..12] of char;
  end;

  { The stack of inlined blocks' .lines elements (stack_debug_$...;
    purge_stack replays them): 18-byte elements, 240 to a 4324-byte
    chunk; a frame (22 bytes) for each block open, on a circular list
    (A5 + 0xC60 the innermost). }
  outbin_elem_ptr_t = ^outbin_elem_t;
  outbin_elem_t = record
    kind: integer;                      { +0: 0 range open, 1 lines
                                          def, 2 statement end, 3
                                          entry, 4 return, 5 range
                                          close }
    case integer of
      1: (l: array [1..4] of integer32);    { +2 }
      2: (blk: il_$node_ptr_t;              { +2 }
          pc: integer32);                   { +6 }
  end;
  outbin_chunk_ptr_t = ^outbin_chunk_t;
  outbin_chunk_t = record
    next: outbin_chunk_ptr_t;           { +0 }
    elems: array [1..240] of outbin_elem_t;  { +4 }
  end;
  outbin_frame_ptr_t = ^outbin_frame_t;
  outbin_frame_t = record
    next: outbin_frame_ptr_t;           { +0 }
    prev: outbin_frame_ptr_t;           { +4 }
    first: outbin_chunk_ptr_t;          { +8 }
    last: outbin_chunk_ptr_t;           { +12 }
    start: integer32;                   { +16: the block's address }
    count: integer;                     { +20: elements in the last }
  end;

  { A block of the line number index (put_ln_index; 1032 bytes from
    gspace): 512 words. }
  outbin_lnbuf_ptr_t = ^outbin_lnbuf_t;
  outbin_lnbuf_t = record
    x0: integer32;                      { +0 }
    next: outbin_lnbuf_ptr_t;           { +4 }
    words: array [0..511] of integer;   { +8 }
  end;

  { The section table (init_section_info; 12 bytes an entry, from
    pas_$new): a code section and where its output stopped. }
  outbin_sect_info_t = record
    sect: il_$node_ptr_t;               { +0 }
    off: integer32;                     { +4 }
    index: integer32;                   { +8: unix_objmod's +0x5D44 }
  end;
  outbin_sect_info_ptr_t = ^array [1..1000] of outbin_sect_info_t;

  { An equivalent line of a line number cell (its +12 list, wr_instr). }
  outbin_equiv_ptr_t = ^outbin_equiv_t;
  outbin_equiv_t = record
    next: outbin_equiv_ptr_t;           { +0 }
    line: integer;                      { +4 }
  end;

  { The register contents noted for a block (its +24 through IL's +0x11C
    vector): a node and how it is held, 8 bytes a register. }
  outbin_regstate_ptr_t = ^outbin_regstate_t;
  outbin_regstate_t = record
    x0: integer32;                      { +0 }
    regs: array [0..23] of record
      node: il_$node_ptr_t;             { +4 }
      how: integer;                     { +8 }
      pad: integer;
    end;
  end;
  outbin_blocks_ptr_t = ^array [1..32767] of il_$node_ptr_t;

  { A block's saved registers (+220): D0..D7, A0..A7, FP0..FP7. }
  outbin_regset_t = set of 0..31;

var
  { emit.pas's data (cc.m68k A5 0x2CE6A8) +0x108..+0x11B: the code's size
    (+0x108) and the location counter (+0x110, its low word +0x112),
    as unix_objmod.pas declares them. }
  emit_108: extern record
    e108: integer32;
    e10c: integer32;
    e110: unix_objmod_$count_t;
    e114: integer32;
    e118: integer32;
  end;

  { cg_top.pas's data (A5 0x356314) +0x130 (0x356444, absolute): the
    current block's line table. }
  cg_top_130: extern outbin_ln_bb_ptr_t;

  { delay.pas's data (A5 0x1695F0) +0x378 and +0x398 (0x169968,
    0x169988, absolute): two tables of words ln_end indexes, a register
    class by an argument's kind and the class's code. }
  delay_378: extern array [0..15] of integer;
  delay_398: extern array [0..15] of integer;

  { opinfo.pas's data (the unit without code; cc.m68k 0x2CF9E2 and
    0x2D05C4, absolute): each instruction's operation word (assemble,
    genfpinst) and its 9-character name (dbcod), indexed by the cell's
    +48. }
  opinfo_opword: extern array [0..367] of integer;
  opinfo_names: extern array [0..367] of array [1..9] of char;

  { The module's data, in the image's order. }
  fp_names: array [16..23] of outbin_fp_name_t := [
    'FP0', 'FP1', 'FP2', 'FP3', 'FP4', 'FP5', 'FP6', 'FP7'];   { +0 }
  nrelocs: integer;                     { +0x1E }
  relocs: array [1..25] of outbin_pair_t;   { +0x20 }
  line: prtsub_$line_t;                 { +0xE8: the listing line }
  shown: array [0..31] of il_$node_ptr_t;   { +0x1F0 }
  { +0x270: the FPA instructions' extension words (wr_addr_ext). }
  fpa_ext: array [0..160] of integer := [
    0, 28676, 0, 28748, 28752, 0, 0, 0, 0, 0,
    28680, 0, 28756, 28760, 0, 0, 0, 0, 0, 28692,
    0, 28780, 28784, 0, 0, 0, 0, 0, 28704, 0,
    28804, 28808, 0, 0, 0, 0, 0, 28716, 0, 28828,
    28832, 0, 0, 0, 0, 0, 28728, 0, 28852, 28856,
    0, 0, 0, 0, 0, 28740, 0, 28876, 28880, 0,
    0, 0, 0, 28684, 28860, 28864, 0, 0, 0, 0,
    0, 0, 0, 29176, 29180, 29204, 29204, 29208, 29208, 29160,
    29164, 0, 0, 29152, 29152, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 29156, 29156, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 29692, 0, 28932,
    29184, 29188, 29192, 29168, 29172, 0, 0, 0, 0, 0,
    0];
  { +0x3B8: the FPA instructions' names (prtads, dbcod, wr_instr); two
    entries .rwdi leaves unset (84, 103) are blanks here. }
  fpa_ops: array [0..160] of outbin_fpa_name_t := [
    'FSLV  ', 'FSLA  ', 'FSLC  ', 'FDLA  ', 'FDLC  ', 'CLA   ', 'CLC   ', 'DCLA  ',
    'DCLC  ', 'FSAV  ', 'FSAA  ', 'FSAC  ', 'FDAA  ', 'FDAC  ', 'CAA   ', 'CAC   ',
    'DCAA  ', 'DCAC  ', 'FSSV  ', 'FSSA  ', 'FSSC  ', 'FDSA  ', 'FDSC  ', 'CSA   ',
    'CSC   ', 'DCSA  ', 'DCSC  ', 'FSISV ', 'FSISA ', 'FSISC ', 'FDISA ', 'FDISC ',
    'CISA  ', 'CISC  ', 'DCISA ', 'DCISC ', 'FSMV  ', 'FSMA  ', 'FSMC  ', 'FDMA  ',
    'FDMC  ', 'CMA   ', 'CMC   ', 'DCMA  ', 'DCMC  ', 'FSDV  ', 'FSDA  ', 'FSDC  ',
    'FDDA  ', 'FDDC  ', 'CDA   ', 'CDC   ', 'DCDA  ', 'DCDC  ', 'FSIDV ', 'FSIDA ',
    'FSIDC ', 'FDIDA ', 'FDIDC ', 'CIDA  ', 'CIDC  ', 'DCIDA ', 'DCIDC ', 'FSSTA ',
    'FDSTA ', 'CSTA  ', 'DCSTA ', 'FSSTX ', 'FDSTX ', 'CSTX  ', 'DCSTX ', 'FSSTWX',
    'FDSTWX', 'FSSTLX', 'FDSTLX', 'FSLWV ', 'FSLLV ', 'FDLWV ', 'FDLLV ', 'FDCNV ',
    'FSCNV ', 'CCNV  ', 'DCCNV ', 'FNEG  ', '      ', 'FSCVX ', 'FSCAX ', 'FSCCX ',
    'FDCAX ', 'FDCCX ', 'FCCAX ', 'FCCCX ', 'FDCCAX', 'FDCCCX', 'E$21V ', 'E$22V ',
    'E$22A ', 'E$22C ', 'E$61V ', 'E$62V ', 'E$62A ', 'E$62C ', 'E$66A ', 'E$66C ',
    'FABS  ', '      ', 'FSSIN ', 'FDSIN ', 'FSCOS ', 'FDCOS ', 'FSTAN ', 'FDTAN ',
    'FSLOG ', 'FDLOG ', 'FSLG10', 'FDLG10', 'FSEXP ', 'FDEXP ', 'FSATAN', 'FDATAN',
    'FSAT2V', 'FSAT2A', 'FSAT2C', 'FDAT2A', 'FDAT2C', 'FSSQRT', 'FDSQRT', 'FSTRNC',
    'FDTRNC', 'FSNINT', 'FDNINT', 'SMAXV ', 'SMAXA ', 'SMAXC ', 'DMAXA ', 'DMAXC ',
    'SMINV ', 'SMINA ', 'SMINC ', 'DMINA ', 'DMINC ', 'CCONJ ', 'DCCONJ', 'CSWAP ',
    'DCSWAP', 'TSTX  ', '      ', 'FBUSY ', 'FEXIT ', 'INTACC', 'IMULT ', 'IDIV  ',
    'IIDIV ', 'FSLPIA', 'FDLPIA', 'SLUV  ', 'DLUV  ', 'FSFAC ', 'FDFAC ', 'SUTLX ',
    'DUTLX '];
  { +0x780: their operation words (assemble). }
  fpa_opword: array [0..160] of integer := [
    -150, -118, -84, 116, 120, 392, 396, 476, 480, 0,
    4, 8, 132, 136, 400, 404, 484, 488, 12, 16,
    20, 140, 144, 408, 412, 492, 496, 24, 28, 32,
    148, 152, 416, 420, 500, 504, 36, 40, 44, 156,
    160, 424, 428, 508, 512, 48, 52, 56, 164, 168,
    432, 436, 516, 520, 60, 64, 68, 172, 176, 440,
    444, 524, 528, -48, 124, 448, 532, -194, 128, 452,
    536, 100, 204, 104, 208, 84, 92, 188, 196, 216,
    212, 460, 544, 108, 108, 72, 76, 80, 180, 184,
    556, 560, 584, 588, 296, 304, 300, 308, 312, 320,
    316, 324, 328, 332, 112, 112, 244, 248, 252, 256,
    260, 264, 236, 240, 608, 612, 228, 232, 268, 272,
    280, 276, 284, 288, 292, 220, 224, 336, 344, 340,
    348, 364, 368, 372, 384, 388, 352, 356, 360, 376,
    380, 464, 548, 456, 540, -204, -204, 0, -158, 0,
    0, 0, 0, 0, 0, 468, 472, 592, 596, 600,
    604];
  { +0x8C8: the 68881 commands' names by their command field
    (attempt_fpx_command_opcode_disassembly): a length and 12
    characters (.rwdi sets the name and a null after it; blanks here). }
  fpx_names: array [0..63] of outbin_fpx_name_t := [
    [length := 5, body := 'FMOVE       '], [length := 4, body := 'FINT        '],
    [length := 5, body := 'FSINH       '], [length := 6, body := 'FINTRZ      '],
    [length := 5, body := 'FSQRT       '], [length := 0, body := '            '],
    [length := 7, body := 'FLOGNP1     '], [length := 0, body := '            '],
    [length := 7, body := 'FETOXM1     '], [length := 5, body := 'FTANH       '],
    [length := 5, body := 'FATAN       '], [length := 0, body := '            '],
    [length := 5, body := 'FASIN       '], [length := 6, body := 'FATANH      '],
    [length := 4, body := 'FSIN        '], [length := 4, body := 'FTAN        '],
    [length := 5, body := 'FETOX       '], [length := 7, body := 'FTWOTOX     '],
    [length := 7, body := 'FTENTOX     '], [length := 0, body := '            '],
    [length := 5, body := 'FLOGN       '], [length := 6, body := 'FLOG10      '],
    [length := 5, body := 'FLOG2       '], [length := 0, body := '            '],
    [length := 4, body := 'FABS        '], [length := 5, body := 'FCOSH       '],
    [length := 4, body := 'FNEG        '], [length := 0, body := '            '],
    [length := 5, body := 'FACOS       '], [length := 4, body := 'FCOS        '],
    [length := 7, body := 'FGETEXP     '], [length := 7, body := 'FGETMAN     '],
    [length := 4, body := 'FDIV        '], [length := 4, body := 'FMOD        '],
    [length := 4, body := 'FADD        '], [length := 4, body := 'FMUL        '],
    [length := 7, body := 'FSGLDIV     '], [length := 4, body := 'FREM        '],
    [length := 6, body := 'FSCALE      '], [length := 7, body := 'FSGLMUL     '],
    [length := 4, body := 'FSUB        '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 4, body := 'FCMP        '], [length := 0, body := '            '],
    [length := 4, body := 'FTST        '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            '],
    [length := 0, body := '            '], [length := 0, body := '            ']
];
  fmt_letters: array [0..7] of char := 'LSXPWDBP';    { +0xC48 }
  bit_masks: array [0..7] of integer := [
    1, 2, 4, 8, 16, 32, 64, 128];       { +0xC50: no routine reads it }
  stack: outbin_frame_ptr_t := nil;     { +0xC60 }
  sect_info: outbin_sect_info_ptr_t;    { +0xC64 }
  nsect_info: integer32;                { +0xC68 }
  sect_no: integer32;                   { +0xC6C }
  reloc_sect: il_$node_ptr_t;           { +0xC70 }
  nlines: integer32;                    { +0xC74 }
  nrel: integer32;                      { +0xC78 }
  obj_base: integer32;                  { +0xC7C }
  direct_base: integer32;               { +0xC80 }
  ln_flag: unix_objmod_$count_t;        { +0xC84 }
  obj_off: integer32;                   { +0xC88 }
  sect_base: integer32;                 { +0xC8C }
  inline_depth: integer32 := 0;         { +0xC90 }
  ln_p1: outbin_lnbuf_ptr_t;            { +0xC94 }
  ln_p2: outbin_lnbuf_ptr_t;            { +0xC98 }
  ln_p3: outbin_lnbuf_ptr_t;            { +0xC9C }
  ln_start_pc: unix_objmod_$count_t;    { +0xCA0 }
  ln_first: outbin_lnbuf_ptr_t;         { +0xCA4 }
  lnbuf: outbin_lnbuf_ptr_t;            { +0xCA8 }
  ln_total: unix_objmod_$count_t;       { +0xCAC }
  ln_count: integer;                    { +0xCB0 }
  range_depth: integer := 0;            { +0xCB2 }
  fpa_reg: integer;                     { +0xCB4 }
  list_depth: integer := 0;             { +0xCB6 }
  ln_line: integer;                     { +0xCB8 }
  list_line: integer := 0;              { +0xCBA }
  cur_line: integer := 0;               { +0xCBC }
  show_index: integer;                  { +0xCBE }
  ln_i1: integer;                       { +0xCC0 }
  ln_i2: integer;                       { +0xCC2 }
  ln_i3: integer;                       { +0xCC4 }
  ln_last_line: integer;                { +0xCC6 }
  b_cc8: boolean := false;              { +0xCC8: no routine reads it }
  dbcod_on: boolean := false;           { +0xCCA }
  hdr_map: univ_ptr;                    { +0xD30 }
  code_sect: il_$node_ptr_t;            { +0xD34 }
  cur_sect: il_$node_ptr_t;             { +0xD38 }
  scope: gen_unwind_$scope_t;           { +0xD60 }
  stmt_no: unix_objmod_$count_t;        { +0xD90 }
  stmt_pc: integer32;                   { +0xD94 }
  equiv: outbin_equiv_ptr_t := nil;     { +0xD98 }
  range: gen_debug_$range_ptr_t;        { +0xD9C }
  first_line: integer;                  { +0xDA0 }
  lines_pending: boolean;               { +0xDA2 }
  in_inline_end: boolean;               { +0xDA4 }
  at_block_start: boolean := false;     { +0xDA6 }
  in_routine: boolean := false;         { +0xDA8 }
  scope_open: boolean := false;         { +0xDAA }
  scope_closed: boolean := false;       { +0xDAC }
  stmt_open: boolean := false;          { +0xDAE }
  return_pending: boolean;              { +0xDB0 }
  return_seen: boolean;                 { +0xDB2 }
  entry_pending: boolean;               { +0xDB4 }
  entry_seen: boolean;                  { +0xDB6 }

{ assert_is_an_fpx_command_instr - whether c moves a 68881 command (a
  string constant `CommandCIR...') to the FPX's command register.

  0x0BBE28, 0xBA bytes, no A5: cpu 5 (FPX: `tst.b 0x2C3671; bpl'),
  kind 1 (move_instyp), the source's f1 3 and f6 1, the destination's
  f1 12 and f5 & 5 (`andi.w #5'), its x a string constant (92) whose
  first str_len characters (pas_$ctov of 120 characters, pas_$substr
  from 1) equal 'CommandCIR' (pas_$str_compare with the varying
  constant 0x0BBEE2).

  Not known from the original:
  - the varying string's type (pas_$ctov's 120). }

function assert_is_an_fpx_command_instr(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
type
  fpx_chars_t = array [1..120] of char;
  fpx_chars_ptr_t = ^fpx_chars_t;
var
  s: il_$node_ptr_t;
begin
  if (5 in cargs_$options.cpu) and (c^.kind = move_instyp) and
      (c^.ads1.f1 = 3) and (c^.ads1.f6 = 1) and (c^.ads2.f1 = 12) and
      ((c^.ads2.f5 & 5) <> 0) and (c^.ads2.x <> 0) then begin
    s := il_$node_ptr_t(c^.ads2.x);
    if s^.kind = 92 then begin
      assert_is_an_fpx_command_instr := substr(fpx_chars_ptr_t(addr(s^.str_chars))^, 1, s^.str_len) = 'CommandCIR';
      return;
    end;
  end;
  assert_is_an_fpx_command_instr := false;
end;

{ attempt_fpx_command_opcode_disassembly - under -EXP, the 68881 command
  c moves to the FPX (its source's constant: a word) in the listing line:
  a blank, a left brace, `FP' and the format, register and command,
  and a right brace.

  0x0BBEF0, 0x218 bytes, no A5: the constant's +10 word w; nothing when
  w is negative or the command (w & 63) has no name (fpx_names' length
  0).  Bits 14..13 both set (`andi.l #0x6000; cmpi.l #0x6000'): FMOVE.
  and the format letter of bits 12..10 (fmt_letters), ` FP' and bits
  9..7, `,<ea>'; else the name, `.', and with bit 14 the format letter
  and ` <ea>' else `X FP' and bits 12..10, then `,', `FP' and bits
  9..7; then the right brace. }

procedure attempt_fpx_command_opcode_disassembly(
    c: codegen_$cell_ptr_t); options(val_param); internal;
var
  w: integer;
  cmd: integer;
  n: integer;
  x: integer32;
  r: integer;
begin
  if not cargs_$options.exp then
    return;
  w := il_$node_ptr_t(c^.ads1.x)^.xw[5];
  cmd := w & 63;
  if w < 0 then
    return;
  n := fpx_names[cmd].length;
  if n = 0 then
    return;
  prtcats(line, ' {', 2);
  x := w;
  if (x & 16#6000) = 16#6000 then begin
    prtcats(line, 'FMOVE.', 6);
    r := rshft(x & 16#1C00, 10);
    prtcatc(line, fmt_letters[r]);
    prtcats(line, ' FP', 3);
    r := rshft(x & 16#380, 7);
    prtint(line, r, 1, false);
    prtcats(line, ',<ea>', 5);
  end
  else begin
    prtcats(line, fpx_names[cmd].body, n);
    prtcatc(line, '.');
    if (w & 16#4000) <> 0 then begin
      r := rshft(x & 16#1C00, 10);
      prtcatc(line, fmt_letters[r]);
      prtcats(line, ' <ea>', 5);
    end
    else begin
      r := rshft(x & 16#1C00, 10);
      prtcats(line, 'X FP', 4);
      prtint(line, r, 1, false);
    end;
    prtcatc(line, ',');
    prtcats(line, 'FP', 2);
    r := rshft(x & 16#380, 7);
    prtint(line, r, 1, false);
  end;
  prtcatc(line, '}');
end;

{ assert_are_producing_68k_expanded_listing - -EXP with a 68K target.

  0x0BC128, 0x18 bytes, no frame: target_properties' +0x10 zero and
  cargs_$options.exp (`btst #1,0x2C3666'). }

function assert_are_producing_68k_expanded_listing: boolean; internal;
begin
  assert_are_producing_68k_expanded_listing :=
      (target_properties.p_10 = 0) and cargs_$options.exp;
end;

{ assert_is_line_no_instyp - c is a line number cell.

  0x0BC140, 0x18 bytes, no frame (docs/rev889-patterns.md 16). }

function assert_is_line_no_instyp(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if c <> nil then
    assert_is_line_no_instyp := c^.kind = line_no_instyp
  else
    assert_is_line_no_instyp := false;
end;

{ assert_is_inlined_block - b is a block (172) inlined (bit 2 of +374).

  0x0BC158, 0x20 bytes, no frame. }

function assert_is_inlined_block(
    b: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (b <> nil) and (b^.kind = 172) then
    assert_is_inlined_block := (ord(b^.xc[374]) & 4) <> 0
  else
    assert_is_inlined_block := false;
end;

{ assert_is_inline_block_start, assert_is_inline_block_end - c starts
  (block_start_instyp) or ends (block_end_instyp) an inlined block.

  0x0BC178, 0x0BC1A2, 0x2A bytes each. }

function assert_is_inline_block_start(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if (c <> nil) and (c^.kind = block_start_instyp) then
    assert_is_inline_block_start := assert_is_inlined_block(c^.blk)
  else
    assert_is_inline_block_start := false;
end;

function assert_is_inline_block_end(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if (c <> nil) and (c^.kind = block_end_instyp) then
    assert_is_inline_block_end := assert_is_inlined_block(c^.blk)
  else
    assert_is_inline_block_end := false;
end;

{ assert_inline_block_start_follows - c is a label cell (kind 0) whose
  next cell starts an inlined block.

  0x0BC1CC, 0x26 bytes. }

function assert_inline_block_start_follows(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if (c <> nil) and (c^.kind = def_lbl_instyp) then
    assert_inline_block_start_follows :=
        assert_is_inline_block_start(c^.next)
  else
    assert_inline_block_start_follows := false;
end;

{ assert_is_interesting_line_no_instyp - c is a line number cell not
  followed by an inlined block's start nor by another line number.

  0x0BC1F2, 0x3A bytes: `bmi' to true when the start follows (`st'),
  else not assert_is_line_no_instyp(c^.next) (`not.b'). }

function assert_is_interesting_line_no_instyp(
    c: codegen_$cell_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_line_no_instyp(c) then begin
    if assert_is_inline_block_start(c^.next) then
      assert_is_interesting_line_no_instyp := true
    else
      assert_is_interesting_line_no_instyp :=
          not assert_is_line_no_instyp(c^.next);
  end
  else
    assert_is_interesting_line_no_instyp := false;
end;

{ format_hint_for_line_number - s := tab to 5, `LINE: ' and n.

  0x0BC22C, 0x4A bytes: the length cleared, prttab 5, prtcats of 6,
  prtint(s, n, 5, true). }

procedure format_hint_for_line_number(
    out s: prtsub_$line_t;
    n: integer32); options(val_param); internal;
begin
  s.length := 0;
  prttab(s, 5);
  prtcats(s, 'LINE: ', 6);
  prtint(s, n, 5, true);
end;

{ emit_hint_for_line_number - the hint for line n listed.

  0x0BC27C, 0x1E bytes: a 258-byte line at (-264,A6). }

procedure emit_hint_for_line_number(
    n: integer32); options(val_param); internal;
var
  s: prtsub_$line_t;
begin
  format_hint_for_line_number(s, n);
  listln(s);
end;

{ emit_hint_for_inlined_routine_line_no_instyp - for a line number cell
  c, its line's hint listed, with ` (routine: "name")' when an inlined
  block starts after it and the block has a name (+296).

  0x0BC29A, 0xA8 bytes: the literals at 0x0BC344 (12) and 0x0BC342
  (2, `")'). }

procedure emit_hint_for_inlined_routine_line_no_instyp(
    c: codegen_$cell_ptr_t); options(val_param); internal;
var
  s: prtsub_$line_t;
  name: il_$node_ptr_t;
begin
  if assert_is_line_no_instyp(c) then begin
    format_hint_for_line_number(s, c^.line);
    if assert_is_inline_block_start(c^.next) then
      if c^.next^.blk^.xp[74] <> nil then begin
        prtcats(s, ' (routine: "', 12);
        name := c^.next^.blk^.xp[74];
        prtcats(s, name^.idnt_name, name^.idnt_len);
        prtcats(s, '")', 2);
      end;
    listln(s);
  end;
end;

{ purge_stack - the .lines elements buffered for the inlined blocks
  replayed into GEN_DEBUG_ (in order, frame by frame round the circular
  list from the innermost) and the buffers given back.

  0x0BC350, 0x134 bytes: for each chunk (the last holding the frame's
  count, the others 240) a `dbf' over its elements and a jump table of
  6 on the kind; the chunk then the frame disposed (4324 and 22 bytes);
  `cmp.l (3168,A5)' ends the loop; the stack then nil.  The range
  open's result is kept in a local (-8) for the close. }

procedure purge_stack; internal;
var
  f, old_f: outbin_frame_ptr_t;
  c, old_c: outbin_chunk_ptr_t;
  n, i: integer;
  r: gen_debug_$range_ptr_t;
begin
  if stack <> nil then begin
    f := stack;
    repeat
      c := f^.first;
      while c <> nil do begin
        if c = f^.last then
          n := f^.count
        else
          n := 240;
        for i := 1 to n do
          with c^.elems[i] do
            case kind of
              0: r := gen_debug_$range_open(0, blk^.xw[133], 0);
              1: gen_debug_$lines_def(l[1], l[2], l[3], l[4]);
              2: gen_debug_$lines_stmt_end(l[1]);
              3: gen_debug_$lines_entry;
              4: gen_debug_$lines_return;
              5: blk^.xl[50] := gen_debug_$range_close(r, pc);
            end;
        old_c := c;
        c := c^.next;
        dispose(old_c);  { 4324 bytes }
      end;
      old_f := f;
      f := f^.next;
      dispose(old_f);  { 22 bytes }
    until f = stack;
    stack := nil;
  end;
end;

{ next_put_element - the next element of the innermost frame (a new
  chunk when the last is full).

  0x0BC484, 0x80 bytes: pas_$new of 4324, cgerr_no_source(9, 0) when it
  fails; the element's address in A0 (`lea (-14,A1,D0.w)'). }

function next_put_element: outbin_elem_ptr_t; internal;
var
  c: outbin_chunk_ptr_t;
begin
  if stack^.count = 240 then begin
    new(c);  { 4324 bytes }
    if c = nil then
      cgerr_no_source(9, 0);
    c^.next := nil;
    stack^.last^.next := c;
    stack^.last := c;
    stack^.count := 0;
  end;
  stack^.count := stack^.count + 1;
  next_put_element := addr(stack^.last^.elems[stack^.count]);
end;

{ stack_debug_$lines_stmt_end, _$lines_def, _$lines_entry,
  _$lines_return - GEN_DEBUG_'s calls noted in the innermost frame
  (kinds 2, 1, 3, 4).

  0x0BC504 (0x1E bytes), 0x0BC5F4 (0x3A), 0x0BC62E (0x10), 0x0BC63E
  (0x10). }

procedure stack_debug_$lines_stmt_end(
    pc: integer32); options(val_param); internal;
var
  e: outbin_elem_ptr_t;
begin
  e := next_put_element;
  e^.kind := 2;
  e^.l[1] := pc;
end;

{ stack_debug_$range_open - a frame for inlined block blk, starting at
  pc, pushed (inserted after the innermost on the circular list), with
  a first chunk and a range-open element.

  0x0BC522, 0xD2 bytes: range_depth incremented; pas_$new of 22 and
  4324, cgerr_no_source(9, 0) when either fails. }

procedure stack_debug_$range_open(
    blk: il_$node_ptr_t;
    pc: integer32); options(val_param); internal;
var
  f: outbin_frame_ptr_t;
  c: outbin_chunk_ptr_t;
  e: outbin_elem_ptr_t;
begin
  range_depth := range_depth + 1;
  new(f);  { 22 bytes }
  if f = nil then
    cgerr_no_source(9, 0);
  if stack = nil then begin
    f^.next := f;
    f^.prev := f;
  end
  else begin
    f^.next := stack^.next;
    f^.next^.prev := f;
    f^.prev := stack;
    f^.prev^.next := f;
  end;
  stack := f;
  stack^.start := pc;
  new(c);  { 4324 bytes }
  if c = nil then
    cgerr_no_source(9, 0);
  c^.next := nil;
  stack^.last := c;
  stack^.first := c;
  stack^.count := 0;
  e := next_put_element;
  e^.kind := 0;
  e^.blk := blk;
end;

procedure stack_debug_$lines_def(
    file_index: integer32;
    line: integer32;
    stmt: integer32;
    pc: integer32); options(val_param); internal;
var
  e: outbin_elem_ptr_t;
begin
  e := next_put_element;
  e^.kind := 1;
  e^.l[1] := file_index;
  e^.l[2] := line;
  e^.l[3] := stmt;
  e^.l[4] := pc;
end;

procedure stack_debug_$lines_entry; internal;
var
  e: outbin_elem_ptr_t;
begin
  e := next_put_element;
  e^.kind := 3;
end;

procedure stack_debug_$lines_return; internal;
var
  e: outbin_elem_ptr_t;
begin
  e := next_put_element;
  e^.kind := 4;
end;

{ stack_debug_$range_close - the block's range-close element noted and
  its frame popped (the stack its +4).

  0x0BC64E, 0x3A bytes. }

procedure stack_debug_$range_close(
    blk: il_$node_ptr_t;
    pc: integer32); options(val_param); internal;
var
  e: outbin_elem_ptr_t;
begin
  e := next_put_element;
  e^.kind := 5;
  e^.blk := blk;
  e^.pc := pc;
  range_depth := range_depth - 1;
  stack := stack^.prev;
end;

{ begin_unwind_scope - scope s opened for routine blk at pc: its start
  (pc plus the routine's section offset, +188's +56), +224, the other
  fields cleared, and the registers the routine saves (+220: D0..D7 bits
  0..7, A0..A7 8..15, FP0..FP7 16..23) as three sets.

  0x0BC688, 0xE2 bytes: three `dbf' loops of 8, each element added with
  `bset' into a word temporary and `or.w'. }

procedure begin_unwind_scope(
    blk: il_$node_ptr_t;
    pc: integer32;
    out s: gen_unwind_$scope_t); options(val_param); internal;
var
  i: integer;
begin
  s.start := pc + blk^.xp[47]^.xl[14];
  s.x8 := blk^.xl[56];
  s.aregs := [];
  s.dregs := [];
  s.fregs := [];
  s.b22 := false;
  s.x12 := 0;
  s.b23 := false;
  s.b24 := false;
  for i := 0 to 7 do
    if i in outbin_regset_t(blk^.xl[55]) then
      s.dregs := s.dregs + [i];
  for i := 0 to 7 do
    if i + 8 in outbin_regset_t(blk^.xl[55]) then
      s.aregs := s.aregs + [i];
  for i := 0 to 7 do
    if i + 16 in outbin_regset_t(blk^.xl[55]) then
      s.fregs := s.fregs + [i];
end;

{ end_unwind_scope - scope s closed at pc and added to the unwind table.

  0x0BC76A, 0x44 bytes: gen_unwind_$add_scope(s, nil (`clr.l'), the
  section's +64). }

procedure end_unwind_scope(
    blk: il_$node_ptr_t;
    pc: integer32;
    in out s: gen_unwind_$scope_t); options(val_param); internal;
begin
  s.len := pc + blk^.xp[47]^.xl[14] - s.start;
  gen_unwind_$add_scope(s, nil, blk^.xp[47]^.xw[32]);
end;

{ bit_fld_op - op is a bit field instruction (70..77).

  0x0BC7AE, 0x3C bytes, no frame: compares with 71, 70, 73, 72, 77, 76,
  74, 75 in turn (docs/rev889-patterns.md 46). }

function bit_fld_op(
    op: integer): boolean; options(val_param); internal;
begin
  bit_fld_op := (op = 71) or (op = 70) or (op = 73) or (op = 72) or
      (op = 77) or (op = 76) or (op = 74) or (op = 75);
end;

{ show_assign - under -EXP, the start of basic block n listed and the
  registers whose contents its table (IL's +0x11C vector, the block's
  +24) changed since the last: `    BLOCK: ' n, then a line for each
  changed register of 24 (D, A or FP and its number, `: ', a common
  subexpression (138, 145..147: `CSE ' and its +10) or the object, and
  how it is held: `:b', `:w', `:l', `:a', `:r', `:d').

  0x0BC7EA, 0x290 bytes: shown (A5 + 0x1F0) keeps the last contents; no
  table clears all 32 (`dbf' of 32); the kinds by a jump table of 10
  from 138, the holds by one of 7 from 1 (3 nothing). }

procedure show_assign(
    n: integer); options(val_param); internal;
var
  s: prtsub_$line_t;
  rs: outbin_regstate_ptr_t;
  r: integer;
  i: integer;
  p: il_$node_ptr_t;
begin
  if n = 0 then
    return;
  s.length := 0;
  prtcats(s, '    BLOCK: ', 11);
  prtint(s, n, 5, false);
  listln(s);
  if il_11c = nil then
    return;
  if outbin_blocks_ptr_t(il_11c)^[n] = nil then
    return;
  rs := outbin_regstate_ptr_t(outbin_blocks_ptr_t(il_11c)^[n]^.xp[6]);
  if rs = nil then begin
    for i := 0 to 31 do
      shown[i] := nil;
    return;
  end;
  for r := 0 to 23 do begin
    p := rs^.regs[r].node;
    if p <> shown[r] then begin
      shown[r] := p;
      if shown[r] <> nil then begin
        s.length := 0;
        prttab(s, 6);
        if r < 8 then begin
          prtcatc(s, 'D');
          prtint(s, r, 1, true);
        end
        else if r < 16 then begin
          prtcatc(s, 'A');
          prtint(s, r - 8, 1, true);
        end
        else begin
          prtcats(s, 'FP', 2);
          prtint(s, r - 16, 1, true);
        end;
        prtcats(s, ': ', 2);
        if rs^.regs[r].node <> nil then begin
          case rs^.regs[r].node^.kind of
            138, 145, 146, 147: begin
              prtcats(s, 'CSE ', 4);
              prtint(s, rs^.regs[r].node^.xw[5], 5, false);
            end;
            otherwise
              prtobj(s, rs^.regs[r].node);
          end;
          case rs^.regs[r].how of
            1: prtcats(s, ':b', 2);
            2: prtcats(s, ':w', 2);
            4: prtcats(s, ':l', 2);
            5: prtcats(s, ':a', 2);
            6: prtcats(s, ':r', 2);
            7: prtcats(s, ':d', 2);
          end;
        end;
        listln(s);
      end;
    end;
  end;
end;

{ sort_ln_bb - the block's line table sorted by line (a Shell sort over
  IL's +0x124 entries).

  0x0BCA98, 0xAE bytes: the gap halved (`lsr.w #1' first, then `asr.l'
  with the rounding of a signed division); the entries swapped as a
  block and a line (6 bytes). }

procedure sort_ln_bb; internal;
var
  gap, i, j, k: integer;
  t: outbin_ln_bb_t;
begin
  gap := il_124 div 2;
  while gap > 0 do begin
    for i := gap + 1 to il_124 do begin
      j := i - gap;
      while j > 0 do begin
        k := j + gap;
        if cg_top_130^[j].line > cg_top_130^[k].line then begin
          t.blk_no.l := cg_top_130^[j].blk_no.l;
          t.line := cg_top_130^[j].line;
          cg_top_130^[j].blk_no.l := cg_top_130^[k].blk_no.l;
          cg_top_130^[j].line := cg_top_130^[k].line;
          cg_top_130^[k].blk_no.l := t.blk_no.l;
          cg_top_130^[k].line := t.line;
        end;
        j := j - gap;
      end;
    end;
    gap := gap div 2;
  end;
end;

{ put_ln_index - w appended to the line number index (a new 1032-byte
  block from gspace when one fills, 512 words); its byte count grows
  by 2.

  0x0BCB46, 0x4C bytes. }

procedure put_ln_index(
    w: integer); options(val_param); internal;
begin
  lnbuf^.words[ln_count] := w;
  ln_count := ln_count + 1;
  if ln_count = 512 then begin
    lnbuf^.next := gspace(1032);
    lnbuf := lnbuf^.next;
    ln_count := 0;
  end;
  ln_total.l := ln_total.l + 2;
end;

{ ln_begin - with -DB, a routine's entry in the line number index (1,
  its name's length and characters two to a word, the last padded; 2,
  three words filled in by ln_end, the first line) and its first COFF
  line entry (line 0, against symbol symndx of sect) appended to
  unix_objmod's list.

  0x0BCB92, 0x1A2 bytes: -DB is cargs' longword +0x282 & 0x18000
  (db); the characters masked with 127 into a word shifted 8 (`lsl.w');
  pas_$new of 18, cgerr_no_source(9, 0); il_180 := blk unless it is
  inlined code (172). }

procedure ln_begin(
    blk: il_$node_ptr_t;
    sect: il_$node_ptr_t;
    symndx: integer32); options(val_param); internal;
var
  w: integer;
  i: integer;
  name: il_$node_ptr_t;
  l: unix_objmod_$lnno_ptr_t;
begin
  if cargs_$options.db <> 0 then begin
    w := 0;
    blk^.xl[59] := ln_total.l;
    if blk^.xp[74] <> nil then begin
      put_ln_index(1);
      put_ln_index(blk^.xp[74]^.idnt_len);
      name := blk^.xp[74];
      for i := 1 to name^.idnt_len do begin
        w := lshft(w, 8) + (ord(name^.idnt_name[i]) & 127);
        if not odd(i) then
          put_ln_index(w);
      end;
      if odd(name^.idnt_len) then
        put_ln_index(lshft(w, 8));
    end;
    put_ln_index(2);
    ln_p3 := lnbuf;
    ln_i3 := ln_count;
    put_ln_index(0);
    ln_p2 := lnbuf;
    ln_i2 := ln_count;
    put_ln_index(0);
    ln_p1 := lnbuf;
    ln_i1 := ln_count;
    put_ln_index(0);
    ln_last_line := cur_line;
    put_ln_index(ln_last_line);
    ln_start_pc.l := emit_108.e110.l;
    blk^.xl[58] := ln_start_pc.l;
    ln_flag.l := 1;
    ln_line := 0;
    nlines := nlines + 1;
    new(l);  { 18 bytes }
    if l = nil then
      cgerr_no_source(9, 0);
    l^.sect := sect;
    l^.addr := 0;
    l^.symndx := symndx;
    l^.line := 0;
    l^.next := nil;
    if uobj_lnno_head = nil then begin
      uobj_lnno_head := l;
      uobj_lnno_list := uobj_lnno_head;
    end
    else begin
      uobj_lnno_list^.next := l;
      uobj_lnno_list := uobj_lnno_list^.next;
    end;
    if blk^.kind <> 172 then
      il_180 := blk;
  end;
end;

{ ln_number - with -DB, a statement at line n (above 0, a new line or a
  new address) in the line number index (the line and address
  increments in one word when under 254, else escapes) and a COFF line
  entry at addr of sect.

  0x0BCD34, 0x12E bytes: the address increment of the low words
  (0x2CE7BA less A5 + 0xCA2); the entry's line the low word of
  A5 + 0xC84 (ln_flag). }

procedure ln_number(
    sect: il_$node_ptr_t;
    addr: integer32;
    n: integer); options(val_param); internal;
var
  dl, w, da: integer;
  l: unix_objmod_$lnno_ptr_t;
begin
  if (cargs_$options.db <> 0) and (n > 0) then
    if (n <> ln_last_line) or (emit_108.e110.l - ln_start_pc.l <> 0) then
        begin
      dl := n - ln_last_line;
      if (dl < 0) or (dl >= 254) then
        w := -512
      else begin
        w := lshft(dl, 8);
        dl := 0;
      end;
      da := emit_108.e110.low - ln_start_pc.low;
      if da >= 254 then
        w := w + 254
      else begin
        w := w + da;
        da := 0;
      end;
      put_ln_index(w);
      if dl <> 0 then
        put_ln_index(dl);
      if da <> 0 then
        put_ln_index(da);
      ln_last_line := n;
      ln_start_pc.l := emit_108.e110.l;
      nlines := nlines + 1;
      new(l);  { 18 bytes }
      if l = nil then
        cgerr_no_source(9, 0);
      l^.sect := sect;
      l^.addr := addr;
      l^.symndx := 0;
      l^.line := ln_flag.low;
      l^.next := nil;
      if uobj_lnno_head = nil then begin
        uobj_lnno_head := l;
        uobj_lnno_list := uobj_lnno_head;
      end
      else begin
        uobj_lnno_list^.next := l;
        uobj_lnno_list := uobj_lnno_list^.next;
      end;
      ln_line := n;
    end;
end;

{ ln_end - with -DB, the routine's three words of ln_begin filled in
  (its code's length, high and low, and its index's length), its
  arguments' classes (3, twice their count, a word each through delay's
  tables) for a routine with arguments (+293) not of linkage 3 (+377
  bits 6..4), and the end (ten words with -DBS or more, the index's
  offset kept at +184; else one).

  0x0BCE62, 0x140 bytes: `clr.w; swap' for the high word; the argument
  kinds at +396.. (a word each, under 6). }

procedure ln_end(
    blk: il_$node_ptr_t); options(val_param); internal;
var
  len: unix_objmod_$count_t;
  i: integer;
  k: integer;
begin
  if cargs_$options.db <> 0 then begin
    len.l := emit_108.e110.l - blk^.xl[58];
    ln_p3^.words[ln_i3] := len.high;
    ln_p2^.words[ln_i2] := emit_108.e110.low - blk^.xw[117];
    ln_p1^.words[ln_i1] := ln_total.low - blk^.xw[119];
    if (ord(blk^.xc[293]) <> 0) and
        (rshft(ord(blk^.xc[377]) & 16#70, 4) <> 3) then begin
      put_ln_index(3);
      put_ln_index(ord(blk^.xc[293]) * 2);
      for i := 1 to ord(blk^.xc[293]) do begin
        k := blk^.xw[197 + i];
        if (k >= 0) and (k < 6) then
          put_ln_index(delay_378[delay_398[k]])
        else
          put_ln_index(0);
      end;
    end;
    if cargs_$options.db >= 2 then begin
      blk^.xl[46] := ln_total.l;
      for i := 1 to 10 do
        put_ln_index(0);
    end
    else
      put_ln_index(0);
  end;
end;

{ write_proc - word w of code: in the listing (hexadecimal) under -EXP,
  past the code's size an error (cgerr 6), then emit_16 and the
  offsets advanced by 2.

  0x0BCFA2, 0x6A bytes: emit_16 of the parameter's address. }

procedure write_proc(
    w: integer); options(val_param); internal;
begin
  if cargs_$options.exp then
    prthex(line, w, 4);
  if emit_108.e110.l > emit_108.e108 then
    cgerr(6, cur_line, nil);
  emit_16(w);
  obj_off := obj_off + 2;
  emit_108.e110.l := emit_108.e110.l + 2;
end;

{ prtlabel - label u (an unpacked descriptor) to s: a numbered label
  (no node) `T$$' and its number; a temporary label (144) of class 13
  (+72 bits 5..1) whose cell follows an inlined block's start with a
  name, the name; else the node.

  0x0BD00C, 0xAC bytes: the label's cell is the node's +80 (getlabcell),
  the cell before it (+4) the block's start. }

procedure prtlabel(
    in out s: prtsub_$line_t;
    in u: codegen_$uads_t);
var
  n: il_$node_ptr_t;
  c: codegen_$cell_ptr_t;
  name: il_$node_ptr_t;
begin
  if u.x = 0 then begin
    prtcats(s, 'T$$', 3);
    prtint(s, u.y, 6, false);
    return;
  end;
  n := il_$node_ptr_t(u.x);
  if (n^.kind = 144) and (rshft(ord(n^.xc[72]) & 16#3E, 1) = 13) then begin
    c := codegen_$cell_ptr_t(n^.xp[20])^.prev;
    if c^.kind = block_start_instyp then
      if c^.blk^.xp[74] <> nil then begin
        name := c^.blk^.xp[74];
        if name^.idnt_len <> 0 then begin
          prtcats(s, name^.idnt_name, name^.idnt_len);
          return;
        end;
      end;
  end;
  prtobj(s, n);
end;

{ prt_bit_field - a bit field's offset and width (braces round `off:width') to s: a
  field (140) at +54 and +56 (the offset less 8 when it lies in the
  second byte of a word and size is not 1), a common subexpression
  (138) at +26 and +28; else the node's +8 and `:1'.

  0x0BD0BC, 0x154 bytes: the words unsigned (`clr.l; move.w', `bcs',
  `bhi'). }

procedure prt_bit_field(
    in out s: prtsub_$line_t;
    in p: il_$node_ptr_t;
    in size: integer);
var
  off: integer;
begin
  prtcatc(s, '{');
  if p^.kind = 140 then begin
    if (p^.xw[27] >= 8) and (p^.xw[27] + p^.xw[28] <= 16) and
        (size <> 1) then
      off := p^.xw[27] - 8
    else
      off := p^.xw[27];
    prtint(s, off, 5, false);
    prtcatc(s, ':');
    prtint(s, p^.xw[28], 5, false);
  end
  else if p^.kind = 138 then begin
    if (p^.xw[13] >= 8) and (p^.xw[13] + p^.xw[14] <= 16) then
      off := p^.xw[13] - 8
    else
      off := p^.xw[13];
    prtint(s, off, 5, false);
    prtcatc(s, ':');
    prtint(s, p^.xw[14], 5, false);
  end
  else begin
    prtint(s, p^.xl[2], 5, false);
    prtcats(s, ':1', 2);
  end;
  prtcatc(s, '}');
end;

{ prt_expr_bit_field - a bit field of an expression (braces round `off:width') to s:
  the offset the constant at p's +44 (less 8 as in prt_bit_field), or
  with mode 14 `D' and register reg; the width p's +28.

  0x0BD212, 0xD8 bytes: the constant's longword compared, its low word
  printed. }

procedure prt_expr_bit_field(
    in out s: prtsub_$line_t;
    in p: il_$node_ptr_t;
    in reg: integer;
    in mode: integer);
var
  off: integer;
  k: il_$node_ptr_t;
begin
  prtcatc(s, '{');
  if mode <> 14 then begin
    k := p^.xp[11];
    if (k^.int_value >= 8) and (p^.xw[14] + k^.int_value <= 16) then
      off := k^.xw[5] - 8
    else
      off := k^.xw[5];
    prtint(s, off, 5, false);
  end
  else begin
    prtcatc(s, 'D');
    prtint(s, reg, 1, true);
  end;
  prtcatc(s, ':');
  prtint(s, p^.xw[14], 5, false);
  prtcatc(s, '}');
end;

{ dump_bit_field, dump_expr_bit_field - prt_bit_field's and
  prt_expr_bit_field's values written to standard output (a debugging
  aid; no caller).

  0x0BD2EA (0x1E2 bytes), 0x0BD56C (0x100): pas_$write of the 32- and
  31-character literals and the words (integer16, 0x0A28; integer32,
  0x0A31; with a width, 0x0A68), pas_$writeln (docs/dpc-gaps.md 4). }

procedure dump_bit_field(
    in p: il_$node_ptr_t;
    in size: integer);
var
  off: integer;
begin
  if p^.kind = 140 then begin
    if (p^.xw[27] >= 8) and (p^.xw[27] + p^.xw[28] <= 16) and
        (size <> 1) then
      off := p^.xw[27] - 8
    else
      off := p^.xw[27];
    writeln('                field  offset = ', off);
    write('                field  width  = ', p^.xw[28]);
  end
  else if p^.kind = 138 then begin
    if (p^.xw[13] >= 8) and (p^.xw[13] + p^.xw[14] <= 16) then
      off := p^.xw[13] - 8
    else
      off := p^.xw[13];
    writeln('                field offset  = ', off);
    write('                field  width  = ', p^.xw[14]);
  end
  else begin
    writeln('                field offset = ', p^.xl[2]);
    write('                field  width = 1');
  end;
  writeln;
end;

procedure dump_expr_bit_field(
    in p: il_$node_ptr_t;
    in reg: integer;
    in mode: integer);
var
  off: integer;
  k: il_$node_ptr_t;
begin
  if mode <> 14 then begin
    k := p^.xp[11];
    if (k^.int_value >= 8) and (p^.xw[14] + k^.int_value <= 16) then
      off := k^.xw[5] - 8
    else
      off := k^.xw[5];
    write('                field offset  = ', off);
  end
  else
    write('                field offset in register D', reg:1);
  writeln;
  write('                field  width  = ', p^.xw[14]);
  writeln;
end;

{ prt_int_regs - the integer registers of a MOVEM (c's mask: the
  destination's constant for movemr_instyp (25), the source's for
  moverm_instyp (26) unless to the predecrement (f1 9), whose mask is
  reversed) to s as `D0-D3/A2'.

  0x0BD696, 0x1C8 bytes: a `dbf' of 16 over the mask (`lsr.w', or a
  bit from 0x8000 down) with the names at A5 + 0xCD0 (the routine's
  static table); a run's last register printed after `-' at its end. }

procedure prt_int_regs(
    in out s: prtsub_$line_t;
    c: codegen_$cell_ptr_t); options(val_param);
var
  regs: static outbin_reg_names_t := [
      'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7',
      'A0', 'A1', 'A2', 'A3', 'A4', 'DB', 'SB', 'SP'];
  first: boolean;
  in_run: boolean;
  run_end: integer;
  mask: integer;
  m, bit: integer32;
  r: integer;
begin
  first := true;
  in_run := false;
  run_end := 0;
  if (c^.kind = movemr_instyp) or
      ((c^.kind = moverm_instyp) and (c^.ads2.f1 <> 9)) then begin
    if c^.kind = movemr_instyp then
      mask := il_$node_ptr_t(c^.ads2.x)^.xw[5]
    else
      mask := il_$node_ptr_t(c^.ads1.x)^.xw[5];
    for r := 0 to 15 do begin
      if odd(mask) then begin
        if in_run then
          run_end := r
        else begin
          if first then
            first := false
          else
            prtcatc(s, '/');
          prtcats(s, regs[r], 2);
          in_run := true;
        end;
      end
      else begin
        if in_run and (run_end <> 0) then begin
          prtcatc(s, '-');
          prtcats(s, regs[run_end], 2);
          run_end := 0;
        end;
        in_run := false;
      end;
      mask := rshft(mask, 1);
    end;
  end
  else begin
    bit := 16#8000;
    m := il_$node_ptr_t(c^.ads1.x)^.xw[5] & 16#FFFF;
    for r := 0 to 15 do begin
      if (m & bit) <> 0 then begin
        if in_run then
          run_end := r
        else begin
          if first then
            first := false
          else
            prtcatc(s, '/');
          prtcats(s, regs[r], 2);
          in_run := true;
        end;
      end
      else begin
        if in_run and (run_end <> 0) then begin
          prtcatc(s, '-');
          prtcats(s, regs[run_end], 2);
          run_end := 0;
        end;
        in_run := false;
      end;
      bit := rshft(bit, 1);
    end;
  end;
  if in_run then begin
    prtcatc(s, '-');
    prtcats(s, regs[run_end], 2);
  end;
end;

{ fp_get_sin_regname - the highest floating register (16..23) in mask.

  0x0BD85E, 0x2E bytes, no A5: a `dbf' of 8. }

function fp_get_sin_regname(
    mask: integer): integer; options(val_param); internal;
var
  r: integer;
  i: integer;
begin
  r := 16;
  for i := 16 to 23 do begin
    if odd(mask) then
      r := i;
    mask := rshft(mask, 1);
  end;
  fp_get_sin_regname := r;
end;

{ prt_fp_regs - the floating registers of an FMOVEM to s: a 68881 move
  of a register pair (kinds 40 and 41 with an instruction of 358..363)
  `FPm:FPn'; m881_moverm_instyp (51) the source's mask in register
  order; else the destination's from bit 7 down; as prt_int_regs.

  0x0BD88C, 0x226 bytes: the set of instructions a 46-byte constant
  after the routine (`btst', 0..367); the names fp_names. }

procedure prt_fp_regs(
    in out s: prtsub_$line_t;
    c: codegen_$cell_ptr_t); options(val_param);
var
  first: boolean;
  in_run: boolean;
  run_end: integer;
  mask: integer;
  m, bit: integer32;
  r: integer;
begin
  first := true;
  in_run := false;
  run_end := 16;
  if ((c^.kind = m68881_reg_reg_instyp) or
      (c^.kind = m68881_src_ext_instyp)) and (c^.op in [358..363]) then
      begin
    prtcats(s, fp_names[c^.ads2.f2], 3);
    prtcatc(s, ':');
    prtcats(s, fp_names[fp_get_sin_regname(
        il_$node_ptr_t(c^.ads2.x)^.xw[5])], 3);
  end
  else if c^.kind = m881_moverm_instyp then begin
    mask := il_$node_ptr_t(c^.ads1.x)^.xw[5];
    for r := 16 to 23 do begin
      if odd(mask) then begin
        if in_run then
          run_end := r
        else begin
          if first then
            first := false
          else
            prtcatc(s, '/');
          prtcats(s, fp_names[r], 3);
          in_run := true;
        end;
      end
      else begin
        if in_run and (run_end <> 16) then begin
          prtcatc(s, '-');
          prtcats(s, fp_names[run_end], 3);
          run_end := 16;
        end;
        in_run := false;
      end;
      mask := rshft(mask, 1);
    end;
  end
  else begin
    bit := 128;
    m := il_$node_ptr_t(c^.ads2.x)^.xw[5] & 16#FFFF;
    for r := 16 to 23 do begin
      if (m & bit) <> 0 then begin
        if in_run then
          run_end := r
        else begin
          if first then
            first := false
          else
            prtcatc(s, '/');
          prtcats(s, fp_names[r], 3);
          in_run := true;
        end;
      end
      else begin
        if in_run and (run_end <> 16) then begin
          prtcatc(s, '-');
          prtcats(s, fp_names[run_end], 3);
          run_end := 16;
        end;
        in_run := false;
      end;
      bit := rshft(bit, 1);
    end;
  end;
  if in_run then begin
    prtcatc(s, '-');
    prtcats(s, fp_names[run_end], 3);
  end;
end;

{ prtads - operand u (an unpacked descriptor) to s in assembler form, by
  its mode (f1): 0 `EMPTY_ADS', 1 a register, 2 d(An), 3 #immediate, 4
  and 6 indexed, 7 a label, 8 (An)+, 9 -(An), 10 `SR', 11 an FPA
  register, 12 and 16 absolute, 13 a floating register, 14 a register
  pair, 15 the object; else `UNRECOGNIZED_ADS'.

  0x0BDAE0, 0x42C bytes: a jump table of 17; the registers' names at
  A5 + 0xCF0 (the routine's static table); a displacement beyond 16
  bits printed in 12 places; a CSE or 143 node with a temporary (+40)
  `T$' (152) or `F$' and the displacement; mode 7's y the label's
  reference cell (its owner's second descriptor unpacked for
  prtlabel); mode 11 keeps the register at A5 + 0xCB4 (fpa_reg). }

procedure prtads(
    in out s: prtsub_$line_t;
    in u: codegen_$uads_t);
var
  regs: static outbin_reg_names_t := [
      'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7',
      'A0', 'A1', 'A2', 'A3', 'A4', 'DB', 'SB', 'SP'];
  n: il_$node_ptr_t;
  l: codegen_$cell_ptr_t;
  t: codegen_$uads_t;
begin
  case u.f1 of
    0: prtcats(s, 'EMPTY_ADS', 9);
    1: prtcats(s, regs[u.f2], 2);
    2: begin
      if u.x = 0 then begin
        if (u.y > 32767) or (u.y < -32768) then
          prtint(s, u.y, 12, false)
        else if u.y <> 0 then
          prtint(s, u.y, 5, false);
      end
      else begin
        n := il_$node_ptr_t(u.x);
        if ((n^.kind = 138) or (n^.kind = 143)) and (n^.xp[10] <> nil)
            then begin
          if n^.xp[10]^.kind = 152 then
            prtcats(s, 'T$', 2)
          else
            prtcats(s, 'F$', 2);
          prtint(s, u.y, 5, false);
        end
        else
          prtobj(s, n);
      end;
      prtcatc(s, '(');
      prtcats(s, regs[u.f2], 2);
      prtcatc(s, ')');
    end;
    3: begin
      if u.f6 <> 3 then
        prtcatc(s, '#');
      prtobj(s, il_$node_ptr_t(u.x));
      if u.y <> 0 then begin
        prtcatc(s, '+');
        prtint(s, u.y, 5, true);
      end;
    end;
    4, 6: begin
      if u.x <> 0 then begin
        n := il_$node_ptr_t(u.x);
        if not ((n^.kind = 138) and (n^.xw[18] = 13)) then
          prtobj(s, n);
      end
      else if u.y <> 0 then
        prtint(s, u.y, 5, false);
      prtcatc(s, '(');
      if u.f1 = 4 then begin
        prtcats(s, regs[u.f2], 2);
        prtcatc(s, ',');
      end;
      prtcats(s, regs[u.f3], 2);
      if (u.f5 & 2) <> 0 then
        prtcats(s, '.L', 2)
      else
        prtcats(s, '.W', 2);
      if u.f4 <> 0 then begin
        prtcatc(s, '*');
        prtint(s, lshft(1, u.f4), 1, false);
      end;
      prtcatc(s, ')');
    end;
    7: begin
      l := codegen_$cell_ptr_t(u.y);
      if l = nil then
        prtobj(s, il_$node_ptr_t(u.x))
      else begin
        unpack_ads(l^.owner^.ads2, t);
        prtlabel(s, t);
      end;
    end;
    8: begin
      prtcatc(s, '(');
      prtcats(s, regs[u.f2], 2);
      prtcats(s, ')+', 2);
    end;
    9: begin
      prtcats(s, '-(', 2);
      prtcats(s, regs[u.f2], 2);
      prtcatc(s, ')');
    end;
    10: prtcats(s, 'SR', 2);
    11: begin
      fpa_reg := u.y;
      prtcats(s, fpa_ops[fpa_reg], 6);
    end;
    12, 16: begin
      prtobj(s, il_$node_ptr_t(u.x));
      if u.f6 <> 2 then
        prtcats(s, '.W', 2)
      else
        prtcats(s, '.L', 2);
    end;
    13: prtcats(s, fp_names[u.f2], 3);
    14: begin
      prtcats(s, regs[u.f3], 2);
      prtcatc(s, ':');
      prtcats(s, regs[u.f2], 2);
    end;
    15: prtobj(s, il_$node_ptr_t(u.x));
    otherwise
      prtcats(s, 'UNRECOGNIZED_ADS', 16);
  end;
end;

{ prtsiz - an operand size to s: NULL, BYTE, WORD, LONG, ADDR or AGG;
  else the number.

  0x0BDF34, 0xB8 bytes: a jump table of 12; the names as longword
  constants stored in a 4-character local; no caller. }

procedure prtsiz(
    in out s: prtsub_$line_t;
    in size: integer);
var
  name: array [1..4] of char;
begin
  case size of
    0: name := 'NULL';
    1: name := 'BYTE';
    2: name := 'WORD';
    4: name := 'LONG';
    5: name := 'ADDR';
    11: name := 'AGG ';
    otherwise begin
      prtint(s, size, 6, false);
      return;
    end;
  end;
  prtcats(s, name, 4);
end;

{ dbcod - with the flag at A5 + 0xCCA (nothing sets it), the code cells
  of every section dumped to standard output: a label's address and
  name, a block's start or end line, a line number, else the cell's
  address, +12, +10, kind (as the enumerated type's name), instruction
  (an FPA one's from fpa_ops, else opinfo's) and operands as prtads
  prints them, the bit fields' and registers' forms.

  0x0BDFEC, 0x52E bytes, no caller: vfmt_$write2 and vfmt_$write5 with
  the literals 0x0BE932, 0x0BE924, 0x0BE8E6 (the unused arguments the
  word at 0x0BE966); the kind written with the enumerated type's name
  table at 0x0BE564 (pas_$write 0x0F65); the bit field instructions
  214, 215 (prt_expr_bit_field), 213 (prt_bit_field) and 216 (an
  integer constant, else the register at A5 + 0xD10, then `:1' and a right brace); a
  destination in a data register (f1 14) of 214 or 215 printed as mode
  1 (the cell's descriptor changed and restored); the line written a
  character at a time (pas_$write 0x0112), then ' ' and writeln.

  Not known from the original:
  - the kind's type (an integer here: codegen.ins.pas). }

procedure dbcod;
var
  regs: static outbin_reg_names_t := [
      'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7',
      'A0', 'A1', 'A2', 'A3', 'A4', 'DB', 'SB', 'SP'];
  s: prtsub_$line_t;
  u: codegen_$uads_t;
  sect: il_$node_ptr_t;
  c: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  r, m: integer;
  k: il_$node_ptr_t;
  i: integer;
  zero: integer32;
begin
  if not dbcod_on then
    return;
  zero := 0;
  writeln;
  write('-------------- Instruction Dump --------------');
  writeln;
  writeln;
  sect := il_10c;
  if sect^.xp[3] = nil then
    sect := sect^.xp[1];
  while sect <> nil do begin
    writeln;
    vfmt_$write2('Procedure Section :%A%.', sect^.xp[2]^.idnt_name,
        sect^.xp[2]^.idnt_len);
    writeln;
    c := codegen_$cell_ptr_t(sect^.xp[5])^.next;
    while c <> codegen_$cell_ptr_t(sect^.xp[5]) do begin
      s.length := 0;
      if c^.kind = def_lbl_instyp then begin
        p := c;
        vfmt_$write2('Label@ %8ZH %$', p, zero);
        unpack_ads(c^.ads2, u);
        prtlabel(s, u);
      end
      else if c^.kind = block_start_instyp then begin
        writeln;
        write('Block-Begin Line ', c^.line:1);
        writeln;
      end
      else if c^.kind = block_end_instyp then begin
        writeln;
        write('Block-End Line ', c^.line:1);
        writeln;
      end
      else if c^.kind = line_no_instyp then begin
        writeln;
        write('Line ', c^.line:1);
        writeln;
      end
      else begin
        p := c;
        vfmt_$write5('Cell @ %8ZH : (%8ZH)(len = %1JWD)   %$', p, c^.blk,
            c^.line, zero, zero);
        write(c^.kind:1);
        write('   ');
        if c^.kind = fop_instyp then
          prtcats(s, fpa_ops[c^.op], 6)
        else
          prtcats(s, opinfo_names[c^.op], 9);
        prtcats(s, '    ', 4);
        if c^.kind = moverm_instyp then
          prt_int_regs(s, c)
        else if c^.kind = m881_moverm_instyp then
          prt_fp_regs(s, c)
        else begin
          unpack_ads(c^.ads1, u);
          prtads(s, u);
        end;
        if (c^.op = 215) or (c^.op = 214) then begin
          r := c^.ads2.f3;
          m := c^.ads2.f1;
          prt_expr_bit_field(s, il_$node_ptr_t(c^.ads1.x), r, m);
        end;
        prtcatc(s, ',');
        if c^.kind = movemr_instyp then
          prt_int_regs(s, c)
        else if c^.kind = m881_movemr_instyp then
          prt_fp_regs(s, c)
        else if (c^.ads2.f1 = 14) and ((c^.op = 215) or (c^.op = 214))
            then begin
          c^.ads2.f1 := 1;
          unpack_ads(c^.ads2, u);
          prtads(s, u);
          c^.ads2.f1 := 14;
        end
        else begin
          unpack_ads(c^.ads2, u);
          prtads(s, u);
        end;
        if c^.op = 213 then begin
          r := c^.ads2.f1;
          prt_bit_field(s, il_$node_ptr_t(c^.ads2.x), r);
        end
        else if c^.op = 216 then begin
          prtcatc(s, '{');
          k := il_$node_ptr_t(c^.ads1.x);
          if (k <> nil) and (k^.kind in [77..87, 101, 200]) then
            prtint(s, k^.int_value, 5, false)
          else
            prtcats(s, regs[c^.ads1.f2], 2);
          prtcats(s, ':1}', 3);
        end;
      end;
      for i := 1 to s.length do
        write(s.body[i]);
      write(' ');
      writeln;
      c := c^.next;
    end;
    sect := sect^.xp[1];
  end;
  writeln;
  writeln;
end;

{ br_distance - the displacement of a branch to label a from the current
  location (the label's address, its reference cell's owner's +12, less
  the location in the section); not a label, or out of 16 bits without
  the 68020 (cpu 3), cgerr 10.

  0x0BE96A, 0x66 bytes: the location in a local (-24); the result left
  in D0 (undefined on the error without a label). }

function br_distance(
    in a: codegen_$ads_t): integer32; internal;
var
  here: integer32;
  d: integer32;
begin
  if a.f1 = 7 then begin
    here := emit_108.e110.l - sect_base;
    d := codegen_$cell_ptr_t(a.y)^.owner^.addr - here;
    br_distance := d;
    if not (3 in cargs_$options.cpu) then
      if (d < -32768) or (d > 32767) then
        cgerr(10, cur_line, nil);
  end
  else
    cgerr(10, cur_line, nil);
end;

{ pc_disp_ok - target is within 16 bits of the extension word's
  location.

  0x0BE9D0, 0x36 bytes. }

function pc_disp_ok(
    target: integer32): boolean; options(val_param); internal;
var
  here: integer32;
  d: integer32;
begin
  here := emit_108.e110.l + 2 - sect_base;
  d := target - here;
  pc_disp_ok := (d <= 32767) and (d >= -32768);
end;

{ gen_ea_bits - the effective address field (mode and register) of
  operand a, by its f1.

  0x0BEA06, 0x10C bytes, no frame: a jump table of 16 from 1 (f1 13 and
  14, and out of range, leave D0 as it is: no value); f1 3's by a table
  of 6 on f6 (6 and 7 likewise); f1 11 sets bit 1 of IL's +0xC4. }

function gen_ea_bits(
    in a: codegen_$ads_t): integer; internal;
begin
  case a.f1 of
    1: gen_ea_bits := a.f2;
    2: begin
      if a.y = 0 then
        gen_ea_bits := a.f2 + 8
      else if (a.y <= 32767) and (a.y >= -32768) then
        gen_ea_bits := a.f2 + 32
      else
        gen_ea_bits := a.f2 + 40;
    end;
    3: case a.f6 of
      0, 1, 2, 4, 5: gen_ea_bits := 60;
      3: gen_ea_bits := 58;
    end;
    4, 12, 16: begin
      if a.f6 = 2 then
        gen_ea_bits := 57
      else
        gen_ea_bits := 56;
    end;
    5, 7: gen_ea_bits := 58;
    6: gen_ea_bits := 59;
    8: gen_ea_bits := a.f2 + 16;
    9: gen_ea_bits := a.f2 + 24;
    10: gen_ea_bits := 60;
    11: begin
      il_c4 := il_c4 ! 2;
      gen_ea_bits := 56;
    end;
    15: gen_ea_bits := 57;
  end;
end;

{ genfpinst - the 68881 command word of code cell cell: opinfo's word
  for its instruction plus the registers' fields by its kind (37..50),
  the single and double forms' adjustments without cpu 2.

  0x0BEB32, 0x254 bytes, A5: a jump table of 14 from kind 37; the two
  forms of a register pair (kinds 40, 41 and instructions 358..363,
  prt_fp_regs' set); the tail of kinds 37/40 and 38/41 shared (the
  adjustments: instructions 304..309 +8, 322..327 +1, 224..229 -1);
  kind 44 with instructions 298..303 and kind 50 add 8 with cpu 4. }

function genfpinst;
var
  c: codegen_$cell_ptr_t;
  w: integer;
  r, s, t: integer;

  { fpreg_ord - floating register r's number (r - 16).  0x0BEB12, 0xA
    bytes, no frame. }
  function fpreg_ord(
      r: integer): integer; options(val_param);
  begin
    fpreg_ord := r - 16;
  end;

  { fpreg - floating register r in the command word's field (bits
    9..7).  0x0BEB1C, 0x16 bytes. }
  function fpreg(
      r: integer): integer; options(val_param);
  begin
    fpreg := lshft(fpreg_ord(r) & 7, 7);
  end;

begin
  c := cell;
  w := opinfo_opword[c^.op];
  case c^.kind of
    tern_src_ext_instyp, m68881_src_ext_instyp: begin
      if ((c^.kind = m68881_reg_reg_instyp) or
          (c^.kind = m68881_src_ext_instyp)) and
          (c^.op in [358..363]) then begin
        r := c^.ads2.f2;
        s := fp_get_sin_regname(il_$node_ptr_t(c^.ads2.x)^.xw[5]);
        t := fpreg(s);
        w := w + (fpreg_ord(r) + t);
      end
      else
        w := w + fpreg(c^.ads2.f2);
      if not (2 in cargs_$options.cpu) then
        if (c^.op >= 304) and (c^.op <= 309) then
          w := w + 8
        else if (c^.op >= 322) and (c^.op <= 327) then
          w := w + 1
        else if (c^.op >= 224) and (c^.op <= 229) then
          w := w - 1;
    end;
    tern_reg_reg_instyp, m68881_reg_reg_instyp: begin
      w := w + lshft(fpreg(c^.ads1.f2), 3);
      if ((c^.kind = m68881_reg_reg_instyp) or
          (c^.kind = m68881_src_ext_instyp)) and
          (c^.op in [358..363]) then begin
        r := c^.ads2.f2;
        s := fp_get_sin_regname(il_$node_ptr_t(c^.ads2.x)^.xw[5]);
        t := fpreg(s);
        w := w + (fpreg_ord(r) + t);
      end
      else
        w := w + fpreg(c^.ads2.f2);
      if not (2 in cargs_$options.cpu) then
        if (c^.op >= 304) and (c^.op <= 309) then
          w := w + 8
        else if (c^.op >= 322) and (c^.op <= 327) then
          w := w + 1
        else if (c^.op >= 224) and (c^.op <= 229) then
          w := w - 1;
    end;
    m68881_tst_reg_instyp: begin
      w := w + lshft(fpreg(c^.ads2.f2), 3);
      if (c^.op >= 298) and (c^.op <= 303) then
        if 4 in cargs_$options.cpu then
          w := w + 8;
    end;
    m68881_dst_ext_instyp:
      w := w + fpreg(c^.ads1.f2);
    m68881_dest1_instyp:
      if 4 in cargs_$options.cpu then
        w := w + 8;
    m68881_i_instyp:
      w := w + (fpreg(c^.ads2.f2) + il_$node_ptr_t(c^.ads1.x)^.xw[5]);
    otherwise
  end;
  genfpinst := w;
end;

{ areg - address register r's number (r - 8, three bits).

  0x0BED86, 0xC bytes, no frame. }

function areg(
    r: integer): integer; options(val_param); internal;
begin
  areg := (r - 8) & 7;
end;

{ assemble - the operation word of code cell c: opinfo's word for its
  instruction completed with the operands' fields by its kind (1..58).

  0x0BED92, 0x416 bytes, no A5: a jump table of 58 from kind 1 (22, 24,
  28, 30, 32..35, 39 and 53 nothing); a move to or from SR (f1 10)
  0x46C0 or 0x40C0 and the other operand; a short branch's
  displacement (br_distance less 2) beyond a byte cgerr 10 with its
  number (smcontk(81, +12)), zero a NOP (0x4E71, the cell made an
  align_instyp of instruction 208), else its low byte; a long branch
  (+10 6) 0xFF; FOP's word from fpa_opword; the 68881's 0xF200,
  0xF240, 0xFC00 forms. }

function assemble(
    c: codegen_$cell_ptr_t): integer; options(val_param); internal;
var
  w: integer;
  dst, src: integer;
  d: unix_objmod_$count_t;
begin
  w := opinfo_opword[c^.op];
  case c^.kind of
    move_instyp: begin
      if c^.ads2.f1 = 10 then
        w := gen_ea_bits(c^.ads1) + 16#46C0
      else if c^.ads1.f1 = 10 then
        w := gen_ea_bits(c^.ads2) + 16#40C0
      else begin
        dst := gen_ea_bits(c^.ads2);
        w := w + (gen_ea_bits(c^.ads1) + (lshft(dst & 7, 9) +
            lshft(dst & 56, 3)));
      end;
    end;
    moveq_instyp:
      w := w + (ord(il_$node_ptr_t(c^.ads1.x)^.xc[11]) +
          lshft(c^.ads2.f2, 9));
    a_instyp: begin
      src := gen_ea_bits(c^.ads1);
      w := w + (lshft(areg(c^.ads2.f2), 9) + src);
    end;
    q_instyp:
      w := w + (gen_ea_bits(c^.ads2) +
          lshft(il_$node_ptr_t(c^.ads1.x)^.xw[5] & 7, 9));
    br_instyp, cbr_instyp, bsr_instyp: begin
      if c^.size = 2 then begin
        d.l := br_distance(c^.ads2) - 2;
        if abs(d.low) > 254 then
          cgerr(10, cur_line, smcontk(81, c^.addr))
        else if d.l = 0 then begin
          w := 16#4E71;
          c^.kind := align_instyp;
          c^.op := 208;
        end
        else
          w := w + (d.low & 255);
      end;
      if c^.size = 6 then
        w := w + 255;
    end;
    src2_sz_instyp, src2_instyp:
      w := w + (gen_ea_bits(c^.ads1) + lshft(c^.ads2.f2, 9));
    m020_src2_instyp, m020_cmp2_instyp:
      w := w + gen_ea_bits(c^.ads1);
    dest2_sz_instyp: begin
      w := w + gen_ea_bits(c^.ads2);
      w := w + lshft(c^.ads1.f2, 9);
      w := w ! 256;
    end;
    m020_dest2_instyp, m020_dest1_instyp:
      w := w + gen_ea_bits(c^.ads2);
    shft_d_instyp: begin
      w := w + lshft(c^.ads1.f2, 9);
      w := w + c^.ads2.f2;
      w := w ! 32;
    end;
    shft_cnt_instyp:
      w := w + (lshft(il_$node_ptr_t(c^.ads1.x)^.xw[5] & 7, 9) +
          c^.ads2.f2);
    shft_mem_instyp: begin
      w := (w & (-1792)) ! lshft(w & 24, 6);   { 16#F900 }
      w := w ! gen_ea_bits(c^.ads2);
      w := w ! 192;
    end;
    cmpm_instyp: begin
      src := lshft(areg(c^.ads2.f2), 9);
      w := w + (areg(c^.ads1.f2) + src);
    end;
    dest2_instyp: begin
      if bit_fld_op(c^.op) then
        w := w + 256;
      w := w + (gen_ea_bits(c^.ads2) + lshft(c^.ads1.f2, 9));
    end;
    i_w_instyp: begin
      if bit_fld_op(c^.op) then
        w := w + 2048;
      w := w + gen_ea_bits(c^.ads2);
    end;
    dest1_sz_instyp, i_instyp, dest1_instyp, logicize_instyp,
        moverm_instyp, case_instyp:
      w := w + gen_ea_bits(c^.ads2);
    movemr_instyp:
      w := w + (gen_ea_bits(c^.ads1) + 1024);
    link_instyp:
      w := w + areg(c^.ads1.f2);
    unlk_instyp:
      w := w + areg(c^.ads2.f2);
    fop_instyp:
      w := fpa_opword[c^.op];
    dbcc_instyp:
      w := w + c^.ads1.f2;
    tern_32u_instyp:
      w := w + (lshft(c^.ads2.f2, 9) + c^.ads1.f2);
    tern_src_ext_instyp:
      w := gen_ea_bits(c^.ads1) - 1024;   { 16#FC00 }
    tern_reg_reg_instyp:
      w := -1024;
    m68881_src_ext_instyp, m881_movemr_instyp:
      w := gen_ea_bits(c^.ads1) - 3584;   { 16#F200 }
    m68881_reg_reg_instyp, m68881_tst_reg_instyp, m68881_i_instyp:
      w := -3584;
    m68881_dst_ext_instyp, m68881_dest1_instyp, m881_moverm_instyp:
      w := gen_ea_bits(c^.ads2) - 3584;
    m68881_set_byte_instyp:
      w := gen_ea_bits(c^.ads2) - 3520;   { 16#F240 }
    fpa_reg_reg_instyp:
      w := w + gen_ea_bits(c^.ads2);
    fpa_load_instyp, fpa_store_instyp, fpa_mem_2reg_instyp,
        fpa_cmp_instyp: begin
      dst := gen_ea_bits(c^.ads2);
      w := w + (gen_ea_bits(c^.ads1) + (lshft(dst & 7, 9) +
          lshft(dst & 56, 3)));
    end;
    otherwise
  end;
  assemble := w;
end;

{ fardisp - operand a needs a long displacement: a PC-relative constant
  (f1 3, f6 3) or a label (f1 7) out of 16 bits.

  0x0BF1A8, 0x74 bytes. }

function fardisp(
    in a: codegen_$ads_t): boolean; internal;
begin
  if (a.f1 = 3) and (a.f6 = 3) and
      not pc_disp_ok(il_$node_ptr_t(a.x)^.xp[2]^.xl[3]) then
    fardisp := true
  else if a.f1 = 7 then
    fardisp := not pc_disp_ok(codegen_$cell_ptr_t(a.y)^.owner^.addr)
  else
    fardisp := false;
end;

{ init_proc_reloc - the procedure constants' relocations of section s
  begun.

  0x0BF21C, 0x22 bytes. }

procedure init_proc_reloc(
    s: il_$node_ptr_t); options(val_param);
begin
  reloc_sect := s;
  nrelocs := 0;
end;

{ dump_proc_reloc - the relocations collected appended to the section's
  list (+52, linked through +4) as a node of kind 193 (212 bytes from
  gspace: the count at +10, the pairs from +12).

  0x0BF23E, 0x94 bytes, no caller: the kind and the link stored by one
  `move.l #0x00C10000,(2,A0)' and `clr.w (6,A0)'. }

procedure dump_proc_reloc;
var
  r: il_$node_ptr_t;
  p: il_$node_ptr_t;
  i: integer;
begin
  if nrelocs <> 0 then begin
    r := gspace(212);
    r^.kind := 193;
    r^.xp[1] := nil;
    r^.xw[5] := nrelocs;
    for i := 1 to nrelocs do begin
      r^.xl[2 * i + 1] := relocs[i].a;
      r^.xl[2 * i + 2] := relocs[i].b;
    end;
    if reloc_sect^.xp[13] = nil then
      reloc_sect^.xp[13] := r
    else begin
      p := reloc_sect^.xp[13];
      while p^.xp[1] <> nil do
        p := p^.xp[1];
      p^.xp[1] := r;
    end;
    nrelocs := 0;
  end;
end;

{ get_reloc_symndx - the COFF symbol a relocation against p refers to,
  by its kind (a label, 144, n).

  0x0BF2D2, 0x184 bytes, no A5: compares in turn; a variable (109)
  of class 1 or 7 (`btst' of 0x82) its block's section's symbol; a
  transfer vector (159) searched in unix_objmod's global names (the
  result undefined when absent); else cgerr_no_source(28, strtk(...)). }

function get_reloc_symndx(
    p: il_$node_ptr_t;
    n: integer32): integer32; options(val_param); internal;
var
  i: integer;
begin
  case p^.kind of
    167, 108, 107:
      get_reloc_symndx := p^.xw[133];
    192:
      get_reloc_symndx := uobj_5d6c.l;
    194:
      get_reloc_symndx := get_reloc_symndx(p^.xp[2], 0);
    183:
      get_reloc_symndx := p^.xw[22];
    111:
      get_reloc_symndx := p^.xw[16];
    109:
      if p^.xw[36] in [1, 7] then
        get_reloc_symndx := p^.xp[5]^.xp[48]^.xw[22]
      else begin
        get_reloc_symndx := p^.xw[38];
        if (p^.xw[38] = 0) and (p^.xw[36] = 10) then
          get_reloc_symndx := p^.xp[20]^.xw[16];
      end;
    110:
      get_reloc_symndx := p^.xw[33];
    159:
      for i := 1 to uobj_global_name_count.low do
        if uobj_global_names[i].name = p then begin
          get_reloc_symndx := uobj_global_names[i].symndx;
          return;
        end;
    195:
      get_reloc_symndx := get_reloc_symndx(p^.xp[3], 0);
    163:
      if p^.xp[2]^.kind = 144 then
        get_reloc_symndx := get_reloc_symndx(p^.xp[2], p^.xp[6]^.xw[32])
      else
        get_reloc_symndx := get_reloc_symndx(p^.xp[2], 0);
    144:
      get_reloc_symndx := n;
    otherwise
      cgerr_no_source(28,
          integer32(strtk('NO COFF SYMNO FOR THIS NODE ', 28)));
  end;
end;

{ add_proc_reloc - a relocation of the longword at vaddr of sect against
  symbol symndx (target the node it refers to) appended to unix_objmod's
  list; the section's count grows.

  0x0BF472, 0x94 bytes: pas_$new of 20, cgerr_no_source(9, 0). }

procedure add_proc_reloc;
var
  r: unix_objmod_$reloc_ptr_t;
begin
  new(r);  { 20 bytes }
  if r = nil then
    cgerr_no_source(9, 0);
  r^.sect := sect;
  r^.vaddr := vaddr;
  r^.symndx := symndx;
  r^.target := target;
  r^.next := nil;
  if uobj_reloc_head = nil then begin
    uobj_reloc_head := r;
    uobj_reloc_tail := uobj_reloc_head;
  end
  else begin
    uobj_reloc_tail^.next := r;
    uobj_reloc_tail := uobj_reloc_tail^.next;
  end;
  nrel := nrel + 1;
end;

{ outcode - the code of every code section written to the object file
  (unix_objmod's output_data_info calls it): the sections taken in the
  order of their first lines (next_section), each section's cells
  written by wr_instr up to the next routine's start, a section's
  object space mapped (putobj, 163808 bytes at most) and its section
  header written the first time; the section table and the counts
  kept in the section nodes (+56 its address, +60 its symbol, +68 and
  +72 the relocations and line numbers).

  0x0C1FC6, 0x444 bytes, A5: shown cleared (32 longwords); with -DB the
  line number index's first block (gspace 1032); the sections' +48 (the
  next cell) and +36 (the location) set up; a section with no code
  (+12 0) gets symbol 0; the header (putobj of 40 bytes at the section
  headers' offset + 40 (n - 1), n its +66) named by unix_put_obj_name,
  its address the section's start plus unix_objmod's +0x5D74, its
  pointers zero and flags 16#00200020 (a 16-byte constant copied); at
  the end the mapping freed, the table disposed (pas_$dispose of 12 n
  bytes) and the section headers' offset advanced by 40 n.

  Not known from the original:
  - the locals' names (-8 and -12 are the nested routines'). }

procedure outcode;
var
  sect: il_$node_ptr_t;                 { -8: the section being written }
  prev_sect: il_$node_ptr_t;            { -12: the last section }
  last_code: il_$node_ptr_t;
  last_sect: il_$node_ptr_t;
  new_sect: boolean;
  c: codegen_$cell_ptr_t;
  i: integer;
  size: integer32;
  h: unix_objmod_$scnhdr_ptr_t;

  { reloc_proc_addr - a relocation for the address of p (plus offset)
    at the current location, and the address's two words (offset; the
    relocation adds the symbol's): an element's or field's address
    (147, 146, 164, an offset 195 adding its +16) followed down to the
    object.

    0x0BF506, 0xE0 bytes: the static link in A1 (outcode's frame, for
    the section at -8); the objects a set of 0..207 after the routine
    (107..111, 167, 183, 192, 194); an offset of kind 1 (+20) ends the
    walk; another kind cgerr_no_source(20, idntk(76, 'CASE ', 5));
    add_proc_reloc pops 14 bytes (docs/rev889-patterns.md 11). }

  procedure reloc_proc_addr(
      p: il_$node_ptr_t;
      offset: integer32); options(val_param);
  var
    off: unix_objmod_$count_t;
  begin
    off.l := offset;
    while not (p^.kind in [107..111, 167, 183, 192, 194]) do
      case p^.kind of
        147: p := p^.xp[6];
        146: p := p^.xp[6];
        164: p := p^.xp[5];
        195: begin
          if p^.xw[10] = 1 then
            exit;
          off.l := off.l + p^.xl[4];
          p := p^.xp[3];
        end;
        otherwise
          cgerr_no_source(20, integer32(idntk(76, 'CASE ', 5)));
      end;
    add_proc_reloc(obj_off + direct_base, sect, get_reloc_symndx(p, 0),
        p);
    write_proc(off.high);
    write_proc(off.low);
  end;

  { define_constant - constant c of size kind (0 byte, 1 word, 2 long,
    3 single, 4 and 5 double, 6 and 7 string, 8 address, 9 double
    complex) written; under -EXP its listing line (`DC' with its size, or
    `AC', and the value).

    0x0BF606, 0x44C bytes: the comparisons in turn; a byte the value's
    low word shifted 8; a single through dbl_to_real; the doubles' and
    the double complex's longwords copied to a local and written a word
    at a time; a string a word (two characters) at a time with the
    listing's hexadecimal suppressed (cargs_$options.exp cleared with
    `bclr #9' of its byte, docs/rev889-patterns.md 49, and restored);
    the listing's `.W' and `.L' prtads' literals (0x0BDF20, 0x0BDF1E;
    docs/rev889-patterns.md 34), a string of more than 32 characters
    cut with `...', kind 7 at most 8 words in hexadecimal (`...' when
    more remain). }

  procedure define_constant(
      c: il_$node_ptr_t;
      kind: integer); options(val_param);
  label
    1;
  var
    v: outbin_long_t;
    d: outbin_double_t;
    pair: outbin_long_t;
    i: integer;
    save: boolean;
  begin
    if cargs_$options.exp then begin
      line.length := 0;
      prttab(line, 6);
      prthex(line, emit_108.e110.l - sect_base, 4);
      prtcatc(line, ':');
    end;
    case kind of
      0: write_proc(lshft(c^.xw[9], 8));
      1: write_proc(c^.xw[9]);
      2: begin
        v.l := c^.xl[4];
        write_proc(v.high);
        write_proc(c^.xw[9]);
      end;
      3: begin
        v.r := dbl_to_real(c, cur_line);
        write_proc(v.high);
        write_proc(v.low);
      end;
      5, 4: begin
        d.l[1] := c^.bits[1];
        d.l[2] := c^.bits[2];
        for i := 1 to 4 do
          write_proc(d.w[i]);
      end;
      9: begin
        for i := 1 to 2 do
          d.l[i] := c^.bits[i];
        for i := 1 to 4 do
          write_proc(d.w[i]);
        for i := 1 to 2 do
          d.l[i] := c^.bits[i + 2];
        for i := 1 to 4 do
          write_proc(d.w[i]);
      end;
      7, 6: begin
        save := cargs_$options.exp;
        cargs_$options.exp := false;
        for i := 1 to (c^.str_len + 1) div 2 do begin
          pair.c[1] := c^.str_chars[2 * i - 1];
          pair.c[2] := c^.str_chars[2 * i];
          write_proc(pair.high);
        end;
        cargs_$options.exp := save;
      end;
      8: reloc_proc_addr(c, 0);
    end;
    if cargs_$options.exp then begin
      prttab(line, 40);
      if kind = 8 then begin
        prtcats(line, 'AC', 2);
        prttab(line, 50);
        prtobj(line, c);
      end
      else begin
        prtcats(line, 'DC', 2);
        case kind of
          0: begin
            prtcats(line, '.B', 2);
            prttab(line, 50);
            prtint(line, c^.xl[4], 3, false);
          end;
          1: begin
            prtcats(line, '.W', 2);
            prttab(line, 50);
            prtint(line, c^.xl[4], 5, false);
          end;
          2: begin
            prtcats(line, '.L', 2);
            prttab(line, 50);
            prtint(line, c^.xl[4], 10, false);
          end;
          9, 5, 4, 3: begin
            prttab(line, 50);
            prtobj(line, c);
          end;
          6: begin
            prttab(line, 50);
            prtcatc(line, '''');
            if c^.str_len > 32 then begin
              prtcats(line, c^.str_chars, 32);
              prtcats(line, '...', 3);
            end
            else
              prtcats(line, c^.str_chars, c^.str_len);
            prtcatc(line, '''');
          end;
          7: begin
            prttab(line, 50);
            for i := 1 to 8 do begin
              prthex(line, c^.xw[8 + i], 4);
              if 2 * i >= c^.str_len then
                goto 1;
            end;
            prtcats(line, '...', 3);
          end;
        end;
      end;
    1:
      listln(line);
    end;
  end;


  { wr_instr - code cell c written: a line number cell or a routine's start or end
    (block_start_instyp, block_end_instyp) updates the line state, the
    .lines statements (coff_lines_...), the expanded listing's hints and
    source lines (advance_listing_to_line) and the COFF line entries
    (ln_begin, ln_end, ln_number); a label checks its address; an inline
    constant goes to define_constant; any other instruction marks the
    pending entry and return, defines a statement, is rewritten when an
    address constant lies too far (to an indexed form off the data base
    register: `DB not valid' when the routine has none), and is
    assembled (its operation word, the 68881's and 68020's extension
    words, the operands' extensions), then listed under -EXP.

    0x0C0464, 0x171A bytes, no A5: outcode's frame from the dynamic link
    (the section at -8, passed to ln_begin and ln_number, and in A1 to
    define_constant); the 68020 bit field instructions (kinds 45, 46)
    take a field (140) or a common subexpression (138) in a descriptor's
    x, replaced by its +64 or +40 for the assembly (the node kept in
    D3); IL's +0xC4 gets bit 3 with the 68020, bit 8 for the FPA kinds
    (54..58, a set of 0..63 after the routine), 4 or bit 4 for the
    68881's (cpu 2); the instructions' cases by a jump table of 53 from
    kind 2 (kinds out of range write both operands' extensions); the
    statement's last address (the location less 1, in an inlined block
    from its frame's start) kept at A5 + 0xD94; the listing's operand
    forms by a jump table of 56 from kind 3 (the register names of a
    static table at A5 + 0xD40; the bit field of 214 and 215 through
    prt_expr_bit_field, a data register destination shown as mode 1 and
    restored, 213's through prt_bit_field; the FPX commands); at the end
    the node taken from the descriptor put back.

    Not known from the original:
    - the locals' names (-56 and -54 the saved line and statement for
      coff_equiv_lines). }

  procedure wr_instr(
      c: codegen_$cell_ptr_t); options(val_param);
  label
    9;
  var
    regs: static outbin_reg_names_t := [
        'D0', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7',
        'A0', 'A1', 'A2', 'A3', 'A4', 'DB', 'SB', 'SP'];
    save_line: integer;                 { -56 }
    save_stmt: integer;                 { -54 }
    saved: il_$node_ptr_t;
    p: codegen_$cell_ptr_t;
    t: il_$node_ptr_t;
    u: codegen_$uads_t;
    n: il_$node_ptr_t;
    i: integer;
    w: integer;
    off: integer;
    have_w: boolean;
    d: integer32;

    { check_addressing_mode - displacement d beyond 16 bits (cgerr 24)
      or a scaled index (cgerr 28) on a 68000.

      0x0BFA5C, 0x64 bytes: the messages through strtk. }

    procedure check_addressing_mode(
        d: integer32;
        scaled: integer); options(val_param);
    begin
      if (d < -32768) or (d > 32767) then
        cgerr(24, cur_line,
            strtk('Program too large, displacement to data > 32k ', 46))
      else if scaled <> 0 then
        cgerr(28, cur_line, strtk('Incorrect Address Mode ', 23));
    end;

    { wr_addr_ext - the extension words of operand a, by its mode (f1):
      2 a displacement (a long one as the 68020's full format 0x0170),
      5 a word, 7 a branch's displacement (two words for a long branch,
      the cell's +10 6), 4 and 6 an index (brief, or the full formats
      0x0120 and 0x0130 on the 68020), 16 a word, 12 an absolute
      address plus a constant's value (by f6, a word or two), 3 an
      immediate (by f6: a byte, a word, a long (a single, a string's
      four characters, an address constant through reloc_proc_addr), a
      single, a double, else a PC-relative displacement), 11 an FPA
      register's extension word, 15 an address constant.

      0x0BFB06, 0x4F2 bytes: wr_instr's frame from the dynamic link
      (its cell at +8) and outcode's through it (passed in A1 to
      reloc_proc_addr); jump tables of 17 and 6; the integer constant
      kinds compared in turn (77..87, 200), 109 and the others 0;
      strtk('Procedure length exceeds 32k ', 29) for cgerr 24; the
      words of a longword through a local (-296), a double's through
      another (-288). }

    procedure wr_addr_ext(
        in a: codegen_$ads_t);
    var
      v: outbin_long_t;
      d: outbin_double_t;
      n: il_$node_ptr_t;
      x: integer32;
      l: integer;
      i: integer;
    begin
      case a.f1 of
        2: begin
          if not (3 in cargs_$options.cpu) then
            check_addressing_mode(a.y, 0);
          if (a.y > 32767) or (a.y < -32768) then begin
            v.l := a.y;
            write_proc(368);
            write_proc(v.high);
            write_proc(v.low);
          end
          else if a.y <> 0 then
            write_proc(a.y);
        end;
        5: write_proc(a.y);
        7: begin
          v.l := br_distance(a);
          if not (3 in cargs_$options.cpu) then
            check_addressing_mode(v.l, 0);
          if c^.size = 6 then
            write_proc(v.high);
          write_proc(v.low);
        end;
        4, 6: begin
          if not (3 in cargs_$options.cpu) then
            if (a.y > 127) or (a.y < -128) then
              check_addressing_mode(65535, 1)
            else
              check_addressing_mode(a.y, a.f4);
          l := 0;
          if (a.f5 & 2) <> 0 then
            l := 1;
          if not (3 in cargs_$options.cpu) or ((a.y <= 127) and
              (3 in cargs_$options.cpu) and (a.y >= -128)) then
            write_proc(lshft(a.f3 * 2 + l, 11) + (a.y & 255) +
                lshft(a.f4, 9))
          else if (a.y >= -32768) and (a.y <= 32767) then begin
            write_proc(lshft(a.f3 * 2 + l, 11) + lshft(a.f4, 9) + 288);
            write_proc(a.y);
          end
          else begin
            write_proc(lshft(a.f3 * 2 + l, 11) + lshft(a.f4, 9) + 304);
            v.l := a.y;
            write_proc(v.high);
            write_proc(v.low);
          end;
        end;
        16: write_proc(a.y);
        12: begin
          n := il_$node_ptr_t(a.x);
          case n^.kind of
            81, 79, 78, 77, 87, 85, 84, 83, 86, 80, 82, 200:
              x := n^.int_value;
            109:
              x := 0;
            otherwise
              x := 0;
          end;
          x := x + a.y;
          case a.f6 of
            1: write_proc(x);
            2: begin
              v.l := x;
              write_proc(v.high);
              write_proc(v.low);
            end;
          end;
        end;
        3: begin
          n := il_$node_ptr_t(a.x);
          case a.f6 of
            0: if n^.kind = 92 then begin
                v.c[1] := chr(0);
                v.c[2] := n^.str_chars[1];
                write_proc(v.high);
              end
              else
                write_proc(ord(n^.xc[11]));
            1: if n^.kind = 92 then begin
                for i := 1 to 2 do
                  v.c[i] := n^.str_chars[i];
                write_proc(v.high);
              end
              else
                write_proc(n^.xw[5]);
            2: if n^.kind = 88 then begin
                d.l[1] := 0;
                v.r := dbl_to_real(n, cur_line);
                write_proc(v.high);
                write_proc(v.low);
              end
              else if n^.kind = 92 then begin
                for i := 1 to 4 do
                  v.c[i] := n^.str_chars[i];
                write_proc(v.high);
                write_proc(v.low);
              end
              else if n^.kind = 195 then
                reloc_proc_addr(n, 0)
              else begin
                v.l := n^.int_value;
                write_proc(v.high);
                write_proc(v.low);
              end;
            4: begin
              v.r := dbl_to_real(n, cur_line);
              write_proc(v.high);
              write_proc(v.low);
            end;
            5: begin
              d.l[1] := n^.bits[1];
              d.l[2] := n^.bits[2];
              write_proc(d.w[1]);
              write_proc(d.w[2]);
              write_proc(d.w[3]);
              write_proc(d.w[4]);
            end;
            otherwise begin
              x := n^.xp[2]^.xl[3] - (emit_108.e110.l - sect_base) + a.y;
              if (x > 32767) or (x < -32768) then
                cgerr(24, cur_line,
                    strtk('Procedure length exceeds 32k ', 29))
              else
                write_proc(x);
            end;
          end;
        end;
        11: begin
          fpa_reg := a.y;
          write_proc(fpa_ext[fpa_reg]);
        end;
        15: reloc_proc_addr(il_$node_ptr_t(a.x), a.y);
        otherwise
      end;
    end;

    { coff_lines_proc_start - with -DB and a module (IL's +0xD4), a
      routine's (or inlined block's) start for .lines: the block's first
      line's file (get_include_file_index of +300; the other result
      and +270's not used) begins a new statement count when it changes;
      a routine opens a GEN_DEBUG_ range and resets the entry and return
      flags, an inlined block (172) ends the pending statement and
      opens a stack frame; the block's +156 and +160 get the location
      and the object offset.

      0x0C0016, 0x1BE bytes: wr_instr's frame from the dynamic link (its
      cell +12 the block); the linkage (+377 bits 6..4) 2 or 3 (`btst'
      of 12) takes the first line from +300, else the current line. }

    procedure coff_lines_proc_start;
    var
      file_index, ln: integer;
      f2, l2: integer;
      linkage: integer;
    begin
      if (cargs_$options.db <> 0) and (il_d4 <> nil) then begin
        get_include_file_index(c^.blk^.xw[150], file_index, ln);
        get_include_file_index(c^.blk^.xw[135], f2, l2);
        if gen_debug_$read_file_index <> file_index then begin
          stmt_no.l := 0;
          cur_line := ln;
        end;
        if c^.blk^.kind <> 172 then begin
          range := gen_debug_$range_open(0, c^.blk^.xw[133],
              emit_108.e110.l - sect_base);
          entry_pending := false;
          return_seen := false;
          return_pending := false;
          if cargs_$options.db <> 0 then
            entry_seen := true;
          in_routine := true;
          at_block_start := true;
          scope_open := false;
          scope_closed := false;
          linkage := rshft(ord(c^.blk^.xc[377]) & 16#70, 4);
          if linkage in [2, 3] then
            first_line := c^.blk^.xw[150]
          else
            first_line := cur_line;
        end
        else begin
          if not at_block_start and stmt_open and in_routine then
            if range_depth = 0 then
              gen_debug_$lines_stmt_end(stmt_pc)
            else
              stack_debug_$lines_stmt_end(stmt_pc);
          stack_debug_$range_open(c^.blk, emit_108.e110.l);
        end;
        c^.blk^.xl[39] := emit_108.e110.l - sect_base;
        c^.blk^.xl[40] := obj_off;
        lines_pending := true;
        stmt_open := false;
      end;
    end;

    { coff_lines_proc_end - with -DB and a module, a routine's (or
      inlined block's) end for .lines: a pending return marked; the
      block's +160 made its code's object length; a routine's unwind
      scope closed (when one is open and not closed), its range closed
      (the .lines offset to +200) and the stack purged; an inlined
      block's frame closed.

      0x0C01D4, 0x118 bytes: wr_instr's frame from the dynamic link. }

    procedure coff_lines_proc_end;
    begin
      if (cargs_$options.db <> 0) and (il_d4 <> nil) then begin
        if return_pending and (c^.blk^.kind <> 172) then begin
          if range_depth = 0 then
            gen_debug_$lines_return
          else
            stack_debug_$lines_return;
          return_pending := false;
          return_seen := false;
        end;
        c^.blk^.xl[40] := obj_off - c^.blk^.xl[40];
        stmt_open := false;
        if c^.blk^.kind <> 172 then begin
          in_routine := false;
          if scope_open and not scope_closed then
            end_unwind_scope(il_180, emit_108.e110.l - sect_base, scope);
          c^.blk^.xl[50] := gen_debug_$range_close(range,
              emit_108.e110.l - sect_base);
          if stack <> nil then
            purge_stack;
        end
        else begin
          lines_pending := true;
          stack_debug_$range_close(c^.blk, emit_108.e110.l - stack^.start);
        end;
      end;
    end;

    procedure coff_lines_instruction; forward;

    { coff_equiv_lines - the equivalent lines of the pending line number
      cell (A5 + 0xD98) defined at the same location, each as its own
      statement; the current line and statement restored.

      0x0C02EC, 0x5A bytes: the static link in A1 (wr_instr's frame: the
      saved line and statement at -56 and -54). }

    procedure coff_equiv_lines;
    var
      p: outbin_equiv_ptr_t;
    begin
      p := equiv;
      equiv := nil;
      save_line := cur_line;
      save_stmt := stmt_no.low;
      stmt_no.l := 0;
      while p <> nil do begin
        cur_line := p^.line;
        coff_lines_instruction;  { forward }
        p := p^.next;
      end;
      cur_line := save_line;
      stmt_no.l := save_stmt;
    end;

    { coff_lines_instruction - with -DB, a module and a routine open, a
      statement defined at the current location (the routine's first
      line at its start, else the current line; its file and line from
      get_include_file_index), through the stack in an inlined block;
      then the equivalent lines.

      0x0C0346, 0xDA bytes: the static link in A1. }

    procedure coff_lines_instruction;
    var
      file_index, ln: integer;
    begin
      if (cargs_$options.db <> 0) and (il_d4 <> nil) and in_routine then
          begin
        if at_block_start then
          get_include_file_index(first_line, file_index, ln)
        else
          get_include_file_index(cur_line, file_index, ln);
        if range_depth = 0 then
          gen_debug_$lines_def(file_index, ln, stmt_no.l,
              emit_108.e110.l - sect_base)
        else
          stack_debug_$lines_def(file_index, ln, stmt_no.l,
              emit_108.e110.l - stack^.start);
        if equiv <> nil then
          coff_equiv_lines;
        lines_pending := true;
      end;
    end;

    { executable_insts_follow_prev_lineno - an instruction (a cell not a
      label, line number or block start or end) lies between c and the
      line number cell before it.

      0x0C0420, 0x3E bytes: the kinds a set of 0..47 after the routine
      (0, 24, 32, 33). }

    function executable_insts_follow_prev_lineno(
        c: codegen_$cell_ptr_t): boolean; options(val_param);
    var
      p: codegen_$cell_ptr_t;
    begin
      executable_insts_follow_prev_lineno := false;
      p := c^.prev;
      while p^.kind <> line_no_instyp do begin
        if not (p^.kind in [0, 24, 32, 33]) then
          executable_insts_follow_prev_lineno := true;
        p := p^.prev;
      end;
    end;

  begin
    saved := nil;
    if (c^.kind = m020_dest2_instyp) or (c^.kind = m020_src2_instyp) then
      if (c^.ads2.x <> 0) and (il_$node_ptr_t(c^.ads2.x)^.kind = 140)
          then begin
        saved := il_$node_ptr_t(c^.ads2.x);
        c^.ads2.x := saved^.xl[16];
      end
      else if (c^.ads1.x <> 0) and
          (il_$node_ptr_t(c^.ads1.x)^.kind = 138) then begin
        saved := il_$node_ptr_t(c^.ads1.x);
        c^.ads1.x := saved^.xl[10];
      end;
    if 3 in cargs_$options.cpu then
      il_c4 := il_c4 ! 8;
    if c^.kind in [54..58] then
      il_c4 := il_c4 ! 16#100;
    if (c^.kind = line_no_instyp) or (c^.kind = block_end_instyp) or
        (c^.kind = block_start_instyp) then begin
      if not lines_pending then
        if (c^.kind = line_no_instyp) or (c^.blk^.kind <> 172) then
          coff_lines_instruction;
      if (c^.kind = line_no_instyp) and (c^.line = cur_line) and
          (not at_block_start or (first_line = c^.line)) and
          executable_insts_follow_prev_lineno(c) then
        stmt_no.l := stmt_no.l + 1
      else begin
        if (c^.line < list_line) and (c^.line >= 0) and
            not assert_inline_block_start_follows(c^.next) then begin
          if in_inline_end then begin
            in_inline_end := false;
            list_line := c^.line;
          end;
        end
        else
          list_line := c^.line;
        if assert_are_producing_68k_expanded_listing then
          if assert_is_line_no_instyp(c) then
            if assert_is_inline_block_start(c^.next) then
              inline_depth := inline_depth + 1;
        if assert_are_producing_68k_expanded_listing then
          if inline_depth <> 0 then
            if assert_is_interesting_line_no_instyp(c) then
              emit_hint_for_inlined_routine_line_no_instyp(c);
        if assert_are_producing_68k_expanded_listing then
          if inline_depth <> 0 then
            if assert_is_inline_block_end(c) then begin
              inline_depth := inline_depth - 1;
              if inline_depth = 0 then
                if assert_is_interesting_line_no_instyp(c^.next) then
                  if not assert_is_inline_block_start(c^.next^.next) then
                    emit_hint_for_line_number(c^.next^.line);
            end;
        if c^.line <> 0 then begin
          cur_line := c^.line;
          stmt_no.l := 0;
        end;
      end;
      if c^.kind = block_start_instyp then begin
        in_inline_end := false;
        coff_lines_proc_start;
      end
      else if c^.kind = block_end_instyp then begin
        if (ord(c^.blk^.xc[374]) & 4) <> 0 then
          in_inline_end := true;
        coff_lines_proc_end;
      end
      else if c^.kind = line_no_instyp then begin
        if c^.ret or (c^.next = nil) or (c^.next^.kind <> line_no_instyp)
            or assert_inline_block_start_follows(c^.next^.next) then begin
          p := c^.next;
          while p <> nil do begin
            if (p^.kind = line_no_instyp) and
                assert_inline_block_start_follows(p^.next) then begin
              lines_pending := false;
              exit;
            end;
            if (p^.kind = line_no_instyp) or (p^.kind = block_end_instyp) or
                (p^.kind = block_start_instyp) then
              exit;
            if p^.kind <> def_lbl_instyp then begin
              lines_pending := false;
              exit;
            end;
            p := p^.next;
          end;
        end;
        equiv := outbin_equiv_ptr_t(c^.blk);
        if entry_seen and scope_open then
          entry_pending := true;
        if c^.ret and return_seen then
          return_pending := true;
      end;
      if cargs_$options.exp then begin
        error_listing_0c := true;
        if c^.kind = line_no_instyp then begin
          if assert_inline_block_start_follows(c^.next) or
              assert_is_inline_block_start(c^.next) then
            list_depth := list_depth + 1;
        end
        else if assert_is_inline_block_start(c) then
          if not ((c^.prev <> nil) and (c^.prev^.kind = line_no_instyp))
              then
            if not ((c^.prev <> nil) and (c^.prev^.kind = def_lbl_instyp)
                and (c^.prev^.prev <> nil) and
                (c^.prev^.prev^.kind = line_no_instyp)) then
              list_depth := list_depth + 1;
        if list_depth = 0 then
          advance_listing_to_line(list_line);
        if (c^.kind = block_end_instyp) and (c^.blk^.kind = 172) and
            ((ord(c^.blk^.xc[374]) & 4) <> 0) then
          list_depth := list_depth - 1;
        error_listing_0c := false;
        if cg_top_130 <> nil then
          while (show_index <= il_124) and
              (cg_top_130^[show_index].line <= cur_line) do begin
            if cg_top_130^[show_index].line <> 0 then
              show_assign(cg_top_130^[show_index].blk_no.low);
            show_index := show_index + 1;
          end;
      end;
      if c^.kind = block_start_instyp then begin
        if (c^.blk^.kind <> 172) and (c^.blk^.kind <> 167) then
          ln_begin(c^.blk, sect, c^.blk^.xw[133]);
      end
      else if c^.kind = block_end_instyp then begin
        if c^.blk^.kind <> 172 then begin
          ln_end(c^.blk);
          for i := 0 to 31 do
            shown[i] := nil;
        end;
      end
      else if c^.kind = line_no_instyp then
        if ln_line <> c^.line then begin
          if ln_line <> 0 then
            if ln_line > c^.line then
              ln_flag.l := ln_flag.l + 1
            else
              ln_flag.l := ln_flag.l + (c^.line - ln_line);
          ln_number(sect, obj_off + direct_base, cur_line);
        end;
      goto 9;
    end;
    if cargs_$options.exp then begin
      line.length := 0;
      prttab(line, 6);
      prthex(line, emit_108.e110.l - sect_base, 4);
      prtcatc(line, ':');
    end;
    if c^.kind = def_lbl_instyp then begin
      if emit_108.e110.l - sect_base <> c^.addr then
        cgerr(16, cur_line, smcontk(81, c^.addr));
      if c^.ads2.x <> 0 then
        il_$node_ptr_t(c^.ads2.x)^.xl[14] := emit_108.e110.l - sect_base;
      if cargs_$options.exp then begin
        prttab(line, 30);
        unpack_ads(c^.ads2, u);
        prtlabel(line, u);
        listln(line);
      end;
      goto 9;
    end;
    if c^.kind = inline_instyp then begin
      n := il_$node_ptr_t(c^.ads2.x);
      case n^.kind of
        88: define_constant(n, 3);
        89: define_constant(n, 4);
        90: define_constant(n, 5);
        198: define_constant(n, 9);
        157: case n^.xw[10] of
          1: define_constant(n, 0);
          2: define_constant(n, 1);
          4: define_constant(n, 2);
          otherwise
            cgerr(3, cur_line, nil);
        end;
        92: define_constant(n, 6);
        156, 212: define_constant(n, 7);
        195: define_constant(n, 8);
        otherwise
          cgerr(3, cur_line, nil);
      end;
      goto 9;
    end;
    if entry_pending then begin
      if range_depth = 0 then
        gen_debug_$lines_entry
      else
        stack_debug_$lines_entry;
      entry_seen := false;
      entry_pending := false;
      return_seen := true;
      at_block_start := false;
    end;
    if return_pending then begin
      if range_depth = 0 then
        gen_debug_$lines_return
      else
        stack_debug_$lines_return;
      return_pending := false;
      return_seen := false;
    end;
    stmt_open := true;
    coff_lines_instruction;
    t := nil;
    if (c^.kind = a_instyp) and (c^.op = 12) and fardisp(c^.ads1) then begin
      if (ord(il_180^.xc[375]) & 8) = 0 then
        cgerr_no_source(28, integer32(strtk('DB not valid ', 13)));
      c^.op := 5;
      t := get_proc_addr_con(6, il_$node_ptr_t(c^.ads1.x),
          integer32(cur_sect), code_sect);
    end
    else if (c^.kind = dest1_instyp) and (c^.op = 13) and
        fardisp(c^.ads2) then begin
      if (ord(il_180^.xc[375]) & 8) = 0 then
        cgerr_no_source(28, integer32(strtk('DB not valid ', 13)));
      c^.kind := move_instyp;
      c^.op := 2;
      t := get_proc_addr_con(6, il_$node_ptr_t(c^.ads2.x),
          integer32(cur_sect), code_sect);
      c^.ads2.f1 := 9;
      c^.ads2.f2 := 15;
    end;
    if t <> nil then begin
      c^.ads1.f1 := 2;
      c^.ads1.f2 := 13;
      c^.ads1.y := t^.xl[4];
      c^.ads1.x := 0;
    end;
    if c^.kind <> casejmp_instyp then
      write_proc(assemble(c));
    case c^.kind of
      movemr_instyp: begin
        write_proc(il_$node_ptr_t(c^.ads2.x)^.xw[5]);
        wr_addr_ext(c^.ads1);
      end;
      moverm_instyp: begin
        write_proc(il_$node_ptr_t(c^.ads1.x)^.xw[5]);
        wr_addr_ext(c^.ads2);
      end;
      br_instyp, cbr_instyp, bsr_instyp:
        if c^.size > 2 then
          wr_addr_ext(c^.ads2);
      dest1_sz_instyp, q_instyp, dest2_sz_instyp, shft_mem_instyp,
          dest2_instyp, dest1_instyp, logicize_instyp, dbcc_instyp,
          case_instyp, fpa_reg_reg_instyp:
        wr_addr_ext(c^.ads2);
      casejmp_instyp: begin
        d := codegen_$cell_ptr_t(c^.ads2.y)^.owner^.addr -
            codegen_$cell_ptr_t(c^.ads1.y)^.owner^.addr;
        if (d < -32768) or (d > 32767) then
          cgerr(10, cur_line, nil);
        write_proc(d);
      end;
      link_instyp: begin
        if scope_open then begin
          end_unwind_scope(il_180, emit_108.e110.l - sect_base, scope);
          entry_seen := true;
        end
        else
          scope_open := true;
        wr_addr_ext(c^.ads2);
        begin_unwind_scope(il_180, emit_108.e110.l - sect_base, scope);
      end;
      unlk_instyp: begin
        wr_addr_ext(c^.ads2);
        end_unwind_scope(il_180, emit_108.e110.l - sect_base, scope);
        scope_closed := true;
      end;
      tern_32u_instyp:
        il_c4 := 4;
      src2_instyp: begin
        if (c^.op = 220) or (c^.op = 222) then
          il_c4 := 4;
        wr_addr_ext(c^.ads1);
      end;
      tern_src_ext_instyp, m68881_src_ext_instyp: begin
        write_proc(genfpinst(c));
        wr_addr_ext(c^.ads1);
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m68881_dst_ext_instyp: begin
        write_proc(genfpinst(c));
        wr_addr_ext(c^.ads2);
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      tern_reg_reg_instyp, m68881_reg_reg_instyp: begin
        write_proc(genfpinst(c));
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m68881_tst_reg_instyp: begin
        write_proc(genfpinst(c));
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m68881_dest1_instyp: begin
        write_proc(genfpinst(c));
        wr_addr_ext(c^.ads2);
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m68881_i_instyp: begin
        write_proc(genfpinst(c));
        il_c4 := il_c4 ! 16;
      end;
      m881_nop_instyp: begin
        wr_addr_ext(c^.ads2);
        il_c4 := il_c4 ! 16;
      end;
      fbr_instyp: begin
        wr_addr_ext(c^.ads2);
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m68881_set_byte_instyp: begin
        write_proc(opinfo_opword[c^.op]);
        wr_addr_ext(c^.ads2);
        if 2 in cargs_$options.cpu then
          il_c4 := 4
        else
          il_c4 := il_c4 ! 16;
      end;
      m020_src2_instyp: begin
        have_w := true;
        case c^.op of
          55: w := lshft(c^.ads2.f2, 12) + 2048;
          57: w := lshft(c^.ads2.f2, 12);
          49: w := lshft(c^.ads2.f2, 12) + c^.ads2.f2 + 2048;
          52: w := lshft(c^.ads2.f2, 12) + c^.ads2.f2;
          50: w := lshft(c^.ads2.f2, 12) + c^.ads2.f3 + 2048;
          53: w := lshft(c^.ads2.f2, 12) + c^.ads2.f3;
          214, 215: begin
            if c^.ads2.f1 = 14 then
              off := c^.ads2.f3 + 32
            else begin
              off := saved^.xp[11]^.xw[5];
              if (off >= 8) and (saved^.xw[14] + off <= 16) then
                off := off - 8;
            end;
            if saved^.xw[14] <> 32 then
              w := lshft(c^.ads2.f2, 12) + lshft(off, 6) + saved^.xw[14]
            else
              w := lshft(c^.ads2.f2, 12) + lshft(off, 6);
          end;
          otherwise
            have_w := false;
        end;
        if have_w then
          write_proc(w);
        wr_addr_ext(c^.ads1);
      end;
      m020_cmp2_instyp: begin
        wr_addr_ext(c^.ads1);
        if c^.ads2.f2 >= 8 then
          write_proc(lshft(c^.ads2.f2, 12) + 4096)
        else
          write_proc(lshft(c^.ads2.f2, 12));
      end;
      m020_dest2_instyp: begin
        if (saved^.xw[27] >= 8) and (saved^.xw[27] + saved^.xw[28] <= 16)
            and (c^.ads2.f1 <> 1) then
          off := saved^.xw[27] - 8
        else
          off := saved^.xw[27];
        if saved^.xw[28] <> 32 then
          write_proc(lshft(c^.ads1.f2, 12) + lshft(off, 6) + saved^.xw[28])
        else
          write_proc(lshft(c^.ads1.f2, 12) + lshft(off, 6));
        wr_addr_ext(c^.ads2);
      end;
      m020_dest1_instyp: begin
        n := il_$node_ptr_t(c^.ads1.x);
        if (n <> nil) and (n^.kind in [77..87, 101, 200]) then
          write_proc(lshft(n^.int_value, 6) + 1)
        else
          write_proc(lshft(c^.ads1.f2, 6) + 2049);
        wr_addr_ext(c^.ads2);
      end;
      m881_movemr_instyp: begin
        write_proc(opinfo_opword[c^.op] +
            il_$node_ptr_t(c^.ads2.x)^.int_value);
        wr_addr_ext(c^.ads1);
        il_c4 := il_c4 ! 16;
      end;
      m881_moverm_instyp: begin
        write_proc(opinfo_opword[c^.op] +
            il_$node_ptr_t(c^.ads1.x)^.int_value);
        wr_addr_ext(c^.ads2);
        il_c4 := il_c4 ! 16;
      end;
      moveq_instyp, shft_d_instyp, shft_cnt_instyp, rts_instyp,
          fop_instyp, align_instyp:
        ;
      otherwise begin
        wr_addr_ext(c^.ads1);
        wr_addr_ext(c^.ads2);
      end;
    end;
    if range_depth = 0 then
      stmt_pc := emit_108.e110.l - sect_base - 1
    else
      stmt_pc := emit_108.e110.l - stack^.start - 1;
    if cargs_$options.exp then begin
      prttab(line, 40);
      if c^.kind = fop_instyp then
        prtcats(line, fpa_ops[c^.op], 6)
      else
        prtcats(line, opinfo_names[c^.op], 9);
      case c^.kind of
        dest1_sz_instyp, dest1_instyp, br_instyp, cbr_instyp,
            logicize_instyp, unlk_instyp, case_instyp, bsr_instyp,
            fbr_instyp, m68881_set_byte_instyp, m68881_tst_reg_instyp,
            m020_dest1_instyp, m68881_dest1_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads2, u);
          prtads(line, u);
          if c^.kind = m020_dest1_instyp then begin
            prtcatc(line, '{');
            n := il_$node_ptr_t(c^.ads1.x);
            if n <> nil then
              if (n^.kind in [77..87, 101, 200]) then
                prtint(line, n^.int_value, 5, false)
              else
                prtcats(line, regs[c^.ads1.f2], 2);
            prtcats(line, ':1}', 3);
          end;
        end;
        casejmp_instyp: begin
          unpack_ads(c^.ads2, u);
          prtads(line, u);
          prtcatc(line, '-');
          unpack_ads(c^.ads1, u);
          prtads(line, u);
        end;
        moverm_instyp, m881_moverm_instyp: begin
          prttab(line, 50);
          if c^.kind = moverm_instyp then
            prt_int_regs(line, c)
          else
            prt_fp_regs(line, c);
          prtcatc(line, ',');
          unpack_ads(c^.ads2, u);
          prtads(line, u);
        end;
        movemr_instyp, m881_movemr_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtads(line, u);
          prtcatc(line, ',');
          if c^.kind = movemr_instyp then
            prt_int_regs(line, c)
          else
            prt_fp_regs(line, c);
        end;
        fpa_cmp_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtcats(line, fp_names[c^.ads1.f3], 3);
          prtcatc(line, ',');
          prtcats(line, fp_names[c^.ads1.f2], 3);
        end;
        fpa_reg_reg_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads2, u);
          prtcats(line, fp_names[c^.ads2.f3], 3);
          prtcatc(line, ',');
          prtcats(line, fp_names[c^.ads2.f2], 3);
        end;
        fpa_load_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtads(line, u);
          prtcatc(line, ',');
          unpack_ads(c^.ads2, u);
          prtcats(line, fp_names[c^.ads2.f2], 3);
        end;
        fpa_store_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtcats(line, fp_names[c^.ads1.f2], 3);
          prtcatc(line, ',');
          unpack_ads(c^.ads2, u);
          prtads(line, u);
        end;
        fpa_mem_2reg_instyp: begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtads(line, u);
          prtcatc(line, ',');
          unpack_ads(c^.ads2, u);
          prtcats(line, fp_names[c^.ads2.f2], 3);
          prtcatc(line, ',');
          prtcats(line, fp_names[c^.ads2.f2], 3);
        end;
        rts_instyp, fop_instyp, align_instyp, nop_instyp, m881_nop_instyp:
          ;
        otherwise begin
          prttab(line, 50);
          unpack_ads(c^.ads1, u);
          prtads(line, u);
          have_w := false;
          if (c^.op = 215) or (c^.op = 214) then begin
            t := saved;
            w := c^.ads2.f1;
            off := c^.ads2.f3;
            prt_expr_bit_field(line, t, off, w);
            if c^.ads2.f1 = 14 then begin
              have_w := true;
              c^.ads2.f1 := 1;
            end;
          end
          else if assert_is_an_fpx_command_instr(c) then
            attempt_fpx_command_opcode_disassembly(c);
          prtcatc(line, ',');
          if ((c^.kind = m68881_reg_reg_instyp) or
              (c^.kind = m68881_src_ext_instyp)) and
              (c^.op in [358..363]) then
            prt_fp_regs(line, c)
          else begin
            unpack_ads(c^.ads2, u);
            prtads(line, u);
            if have_w then
              c^.ads2.f1 := 14;
            if c^.op = 213 then begin
              t := saved;
              w := c^.ads2.f1;
              prt_bit_field(line, t, w);
            end;
          end;
        end;
      end;
      listln(line);
    end;
  9:
    if saved <> nil then
      if saved^.kind = 140 then
        c^.ads2.x := integer32(saved)
      else
        c^.ads1.x := integer32(saved);
  end;

  { wr_section - under -EXP, section s's listing lines: its name and
    `DFSECT' (` readonly,instruction' for a code section, 182), then
    `SECT' and its name (with its size, +20 plus +24, for 183).

    0x0C1B94, 0x144 bytes: the literals 0x0C1CF0 (7), 0x0C1CD8 (21),
    0x0C1CF8 and 0x0C1CEE (two blanks). }

  procedure wr_section(
      s: il_$node_ptr_t); options(val_param);
  begin
    if cargs_$options.exp then begin
      line.length := 0;
      prttab(line, 30);
      prtobj(line, s^.xp[2]);
      prttab(line, 40);
      prtcats(line, ' DFSECT', 7);
      if s^.kind = 182 then begin
        prttab(line, 50);
        prtcats(line, ' readonly,instruction', 21);
      end;
      listln(line);
      line.length := 0;
      prttab(line, 40);
      prtcats(line, 'SECT', 4);
      prttab(line, 50);
      prtobj(line, s^.xp[2]);
      if s^.kind = 183 then begin
        prtcats(line, '  ', 2);
        prtint(line, s^.xl[5] + s^.xl[6], 8, false);
      end;
      listln(line);
      line.length := 0;
    end;
  end;

  { outbin_$firstln - the first line of section s's cells still to be
    written (from +48, up to +24 or +20): a line number cell's or a
    routine's start's; none when there is neither.

    0x0C1CFC, 0x60 bytes: 32767 when none. }

  function outbin_$firstln(
      s: il_$node_ptr_t;
      out none: boolean): integer; options(val_param);
  var
    c: codegen_$cell_ptr_t;
  begin
    none := false;
    c := codegen_$cell_ptr_t(s^.xp[12]);
    outbin_$firstln := 32767;
    while (c <> codegen_$cell_ptr_t(s^.xp[6])) and
        (c <> codegen_$cell_ptr_t(s^.xp[5])) do begin
      if c^.kind = line_no_instyp then begin
        outbin_$firstln := c^.line;
        return;
      end
      else if (c^.kind = block_start_instyp) and (c^.blk^.kind <> 172)
          then begin
        outbin_$firstln := c^.line;
        return;
      end;
      c := c^.next;
    end;
    none := true;
  end;

  { next_section - the code section whose remaining cells start at the
    lowest line; nil when none has any.

    0x0C1D5C, 0x5E bytes. }

  function next_section: il_$node_ptr_t;
  var
    s, best: il_$node_ptr_t;
    min: integer32;
    ln: integer32;
    found: boolean;
    none: boolean;
  begin
    min := 2147483647;
    s := il_10c;
    if s^.xl[3] = 0 then
      s := s^.xp[1];
    best := s;
    found := false;
    while s <> nil do begin
      ln := outbin_$firstln(s, none);
      if not none then
        if ln < min then begin
          min := ln;
          best := s;
          found := true;
        end;
      s := s^.xp[1];
    end;
    if not found then
      best := nil;
    next_section := best;
  end;

  { init_section_info - the section table: an entry cleared for each
    section with code.

    0x0C1DBA, 0x9E bytes: pas_$new of 12 n bytes (the size known at run
    time: called directly), cgerr_no_source(9, 0); a `for' of 32 bits
    (docs/rev889-patterns.md 17). }

  procedure init_section_info;
  var
    n: integer32;
    s: il_$node_ptr_t;
    i: integer32;
  begin
    n := 0;
    s := il_10c;
    while s <> nil do begin
      if s^.xl[3] > 0 then
        n := n + 1;
      s := s^.xp[1];
    end;
    nsect_info := n;
    pas_$new(sect_info, nsect_info * 12);
    if sect_info = nil then
      cgerr_no_source(9, 0);
    for i := 1 to nsect_info do begin
      sect_info^[i].sect := nil;
      sect_info^[i].off := 0;
      sect_info^[i].index := 0;
    end;
  end;

  { reset_section_info - where the last section's output stopped saved
    in its entry (or the first free one), and the current section's
    restored; a section met for the first time gets the next free entry
    and its object space (after the last, rounded to 4), and true.

    0x0C1E58, 0x16E bytes: outcode's frame from the dynamic link
    (prev_sect at -12); the loops over the low word of the count. }

  function reset_section_info: boolean;
  var
    i: integer;
  begin
    reset_section_info := false;
    if prev_sect <> nil then
      for i := 1 to nsect_info do
        if (sect_info^[i].sect = prev_sect) or (sect_info^[i].sect = nil)
            then begin
          sect_info^[i].off := obj_off;
          sect_info^[i].index := uobj_direct_index;
          exit;
        end;
    for i := 1 to nsect_info do
      if sect_info^[i].sect = cur_sect then begin
        obj_off := sect_info^[i].off;
        uobj_direct_index := sect_info^[i].index;
        uobj_direct_base := cur_sect^.xl[4] + obj_base;
        if (uobj_direct_base & 3) <> 0 then
          uobj_direct_base := (uobj_direct_base & (-4)) + 4;
        return;
      end
      else if sect_info^[i].sect = nil then begin
        reset_section_info := true;
        uobj_direct_base := cur_sect^.xl[4] + obj_base;
        if (uobj_direct_base & 3) <> 0 then
          uobj_direct_base := (uobj_direct_base & (-4)) + 4;
        sect_info^[i].sect := cur_sect;
        obj_off := 0;
        uobj_direct_index := 0;
        if uobj_direct_base >= uobj_obj_pos then begin
          uobj_obj_pos := uobj_direct_base + cur_sect^.xl[3];
          if ((uobj_obj_pos - uobj_sect_start) & 3) <> 0 then begin
            uobj_pad_from := uobj_obj_pos;
            uobj_obj_pos := (uobj_obj_pos & (-4)) + 4;
          end;
        end;
        uobj_sect_start := uobj_direct_base;
        return;
      end;
  end;

begin
  for i := 0 to 31 do
    shown[i] := nil;
  if cargs_$options.db <> 0 then begin
    ln_first := gspace(1032);
    lnbuf := ln_first;
    ln_total.l := 0;
    ln_count := 0;
  end;
  last_sect := nil;
  last_code := nil;
  init_section_info;
  cur_sect := il_10c;
  if cur_sect^.xp[3] = nil then
    cur_sect := cur_sect^.xp[1];
  while cur_sect <> nil do begin
    cur_sect^.xp[12] :=
        il_$node_ptr_t(codegen_$cell_ptr_t(cur_sect^.xp[5])^.next);
    cur_sect^.xl[9] := cur_sect^.xl[4];
    cur_sect := cur_sect^.xp[1];
  end;
  prev_sect := nil;
  cur_sect := next_section;
  while cur_sect <> nil do begin
    if cur_sect^.xl[3] = 0 then
      cur_sect^.xw[30] := 0
    else begin
      nrel := 0;
      nlines := 0;
      ln_line := 0;
      sect_no := cur_sect^.xw[32];
      if prev_sect = nil then begin
        obj_base := uobj_obj_pos;
        obj_off := 0;
        uobj_direct_index := 0;
        new_sect := reset_section_info;
        direct_base := uobj_direct_base;
        uobj_direct_left := cur_sect^.xl[3];
        if (uobj_direct_left & 3) <> 0 then
          uobj_direct_left := (uobj_direct_left & (-4)) + 4;
        if uobj_direct_left > 163808 then
          uobj_obj_map := putobj(uobj_direct_base, 163808)
        else
          uobj_obj_map := putobj(uobj_direct_base, uobj_direct_left);
      end
      else if cur_sect <> prev_sect then begin
        freeobj(uobj_obj_map);
        new_sect := reset_section_info;
        direct_base := uobj_direct_base;
        uobj_direct_left := cur_sect^.xl[3];
        if (uobj_direct_left & 3) <> 0 then
          uobj_direct_left := (uobj_direct_left & (-4)) + 4;
        if uobj_direct_left > 163808 then
          uobj_obj_map := putobj(uobj_direct_base, 163808)
        else
          uobj_obj_map := putobj(uobj_direct_base, uobj_direct_left);
      end
      else
        new_sect := false;
      if new_sect then
        cur_sect^.xl[14] := uobj_sect_start + uobj_addr_bias;
      sect := cur_sect;
      sect_base := cur_sect^.xl[4];
      emit_108.e110.l := cur_sect^.xl[9];
      init_proc_reloc(cur_sect);
      c := codegen_$cell_ptr_t(cur_sect^.xp[12]);
      while c <> codegen_$cell_ptr_t(cur_sect^.xp[5]) do begin
        if (c^.kind = block_start_instyp) and (c^.blk^.kind <> 172) then
            begin
          il_180 := c^.blk;
          code_sect := c^.blk^.xp[48];
          cg_top_130 := outbin_ln_bb_ptr_t(c^.blk^.xp[30]);
          il_11c := c^.blk^.xp[41];
          il_124 := c^.blk^.xw[137];
          if cargs_$options.exp and (cg_top_130 <> nil) then
            sort_ln_bb;
          show_index := 1;
        end;
        wr_instr(c);
        if code_sect <> last_code then begin
          last_code := code_sect;
          wr_section(code_sect);
        end;
        if cur_sect <> last_sect then begin
          last_sect := cur_sect;
          wr_section(cur_sect);
        end;
        c := c^.next;
        if (c^.kind = block_start_instyp) and (c^.blk^.kind <> 172) then
          exit;
      end;
      cur_sect^.xp[12] := il_$node_ptr_t(c);
      cur_sect^.xl[9] := emit_108.e110.l;
      if new_sect then begin
        if uobj_lnno_scnhdr_pos = 0 then begin
          uobj_lnno_scnhdr_pos := uobj_scnhdr_pos;
          uobj_code_scnhdr_pos := uobj_scnhdr_pos;
          uobj_reloc_scnhdr_pos := uobj_scnhdr_pos;
        end;
        cur_sect^.xw[30] := uobj_nsyms;
        uobj_nsyms := uobj_nsyms + 1;
        hdr_map := putobj(uobj_scnhdr_pos + (cur_sect^.xw[33] - 1) * 40,
            40);
        size := cur_sect^.xl[3];
        if (size & 3) <> 0 then
          size := (size & (-4)) + 4;
        h := hdr_map;
        unix_put_obj_name(h^.s_name, cur_sect^.xp[2]);
        h^.s_paddr := uobj_sect_start + uobj_addr_bias;
        h^.s_vaddr := uobj_sect_start + uobj_addr_bias;
        h^.s_size := size;
        h^.s_scnptr := uobj_sect_start;
        h^.s_relptr := 0;
        h^.s_lnnoptr := 0;
        h^.s_nreloc := 0;
        h^.s_nlnno := 0;
        h^.s_flags := [unix_objmod_$styp_text,
            unix_objmod_$styp_instruction];
        freeobj(hdr_map);
        uobj_code_size := uobj_code_size + size;
      end;
      cur_sect^.xl[17] := cur_sect^.xl[17] + nrel;
      cur_sect^.xl[18] := cur_sect^.xl[18] + nlines;
      prev_sect := cur_sect;
    end;
    cur_sect := next_section;
  end;
  freeobj(uobj_obj_map);
  pas_$dispose(sect_info, nsect_info * 12);
  uobj_scnhdr_pos := uobj_scnhdr_pos + nsect_info * 40;
end;
