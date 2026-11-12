{ bin - the PRISM back end's binary output (cc.a88k only): the code
  cells of each code section, already encoded by the earlier phases (a
  cell's +12 is its 32-bit instruction word), written into the object
  file through a 512-byte window (putobj), with the displacements that
  are known only now patched into the words (literal pool, routine,
  argument block and stack frame, exception stubs), the literal pools
  and case tables laid out, each routine's exception stubs appended,
  and the debugging tables (gen_debug: code ranges and line numbers)
  and the unwind table (gen_unwind: a scope for each routine) fed as it
  goes; lst's listing lines asked for along the way under -EXP.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x222B3C  bin_$begin_compilation
    --------  0x222BD8  bin_$end_compilation
    --------  0x222BDA  bin_$check_window (internal)
    --------  0x222C40  bin_$put_byte_to_pure_text (internal)
    --------  0x222C6C  bin_$put_word_to_pure_text (internal)
    --------  0x222CF6  bin_$put_long_to_pure_text (internal)
    --------  0x222D84  add_exception_table_entry (internal)
    --------  0x222E10  bin_$put_cc_long_to_pure_text (internal)
    --------  0x222F7A  bin_$advance_to_location (internal)
    --------  0x222FF0  bin_$emit_literal_pool (internal)
    --------  0x22326E  bin_$emit_table (internal)
    --------  0x2232EC  map_statement_to_src_loc_and_offset (internal)
    --------  0x2233CC  new_code_range (internal)
    --------  0x22342A  initialize_block (internal)
    --------  0x22346A  set_end_pc (internal)
    --------  0x223494  set_current_block (internal)
    --------  0x22352E  emit_a_pc_to_exception_correlation (internal)
    --------  0x22358C  emit_a_pc_to_line_correlation (internal)
    --------  0x22361A  emit_dot_lines_for_cc (internal)
    --------  0x223728  bin_$unwind_bits
    --------  0x223786  zero (internal)
    --------  0x22379C  add_unwind_rec (internal)
    --------  0x223BE0  put_procedure_start (internal)
    --------  0x223C8C  close_previous_routine (internal)
    --------  0x223D68  set_current_routine (internal)
    --------  0x223DA6  resolve_ap_or_sf_relative_disp (internal)
    --------  0x223EEC  get_exception_info (internal)
    --------  0x223F3E  resolve_exception_stub_disp (internal)
    --------  0x223FA8  add_unwind_for_exception_stub (internal)
    --------  0x223FD0  put_exception (internal)
    --------  0x224240  put_exception_stubs (internal)
    --------  0x224314  bin_$emit_compilation_pure_text
    A5 0x485D38: the module's data (144 bytes): the exception stubs'
    heap (+0) and the code ranges' (+24); +0x30..+0x43 the record
    unix_objmod.pas declares as emit_108 (the code's size +0x30, the
    window's base +0x34, the location +0x38, the code's object offset
    +0x3C, the window +0x40: emit.pas's cells in cc.m68k, defined here
    in cc.a88k); the window's offset (+0x44); the exception ranges
    (+0x48..+0x50); the current routine's statement tables
    (+0x54..+0x5C); the frame's limit (+0x60); the section's offset
    (+0x64); the current routine, block and statement (+0x68, +0x6C,
    +0x78, +0x7C); the stubs' list (+0x70, +0x74); the code ranges'
    list (+0x80); five flags (+0x84..+0x8C).

  The unit opened bug_check.ins.pas after coff_dst.ins.pas; it is opened
  here before at_base.ins.pas, since backend.ins.pas's at_backend
  headings (instr_bug_check, ...) use its types (docs/questions.md,
  translator PB).

  Not known from the original: every local, parameter and module cell
  name; the records (the routine's bin_rtn_t view of rtn_t, the IL
  nodes', the sections', the code ranges', the stubs') are named by
  offset where their use is not plain. }
module bin;

%include 'lang/lang/source/globals.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/coff_dst.ins.pas';
%include 'lang/lang/source/gen_debug.ins.pas';
%include 'lang/lang/source/gen_unwind.ins.pas';
%include 'us/us/sys/ins/unwind.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';

type
  bin_rtn_ptr_t = ^bin_rtn_t;
  bin_node_ptr_t = ^bin_node_t;
  code_range_ptr_t = ^code_range_t;

  { A routine's statement tables: by statement, its source position's
    listing line (line_map, lst_13c), a bit (stmt_bits), the index of
    its block (stmt_index) in stmt_blocks. }
  line_map_ptr_t = ^array [0..65535] of integer;
  stmt_bits_ptr_t = ^packed array [0..65535] of boolean;
  stmt_index_ptr_t = ^array [0..65535] of 0..65535;
  stmt_blocks_ptr_t = ^array [0..65535] of bin_node_ptr_t;

  { A routine (backend.ins.pas's rtn_t) as bin reads it: its IL node,
    statement tables, the next in its section (+40), size (+44), the
    code cells (+88), the saved registers' masks (+160..+168), the
    frame's limits (+172, +176), the unwind words (+208..+224) and
    flags (+226 bit 6 the return PC saved, bit 0 the stack frame
    pushed; +227 bit 5). }
  bin_rtn_t = record
    node: bin_node_ptr_t;               { +0 }
    unused_4: array [4..23] of char;    { +4 }
    line_map: line_map_ptr_t;           { +24 }
    stmt_bits: stmt_bits_ptr_t;         { +28 }
    stmt_index: stmt_index_ptr_t;       { +32 }
    stmt_blocks: stmt_blocks_ptr_t;     { +36 }
    next: bin_rtn_ptr_t;                { +40 }
    size: integer32;                    { +44 }
    l48: integer32;                     { +48 }
    unused_52: array [52..87] of char;  { +52 }
    cells: cell_ptr_t;                  { +88 }
    unused_92: array [92..159] of char; { +92 }
    ip_saved: integer32;                { +160 }
    fp_saved_hi: integer32;             { +164 }
    fp_saved: integer32;                { +168 }
    l172: integer32;                    { +172 }
    l176: integer32;                    { +176 }
    unused_180: array [180..207] of char;    { +180 }
    stack_reg: integer;                 { +208 }
    save_disp: integer;                 { +210 }
    w212: integer;                      { +212 }
    w214: integer;                      { +214 }
    stack_disp: integer;                { +216 }
    save_reg_disp: integer;             { +218 }
    w220: integer;                      { +220 }
    reg_1: integer;                     { +222 }
    reg_2: integer;                     { +224 }
    f226: packed record                 { +226 }
      b7: boolean;
      rp_saved: boolean;                { .6 }
      b5_1: 0..31;
      pushed: boolean;                  { .0 }
      b227_7, b227_6: boolean;          { +227 }
      b227_5: boolean;                  { .5 }
      b227_4_0: 0..31;
      end;
  end;

  { A routine's code record (its IL node's +188): the code's address
    (+16), the unwind base (+56) and the symbol (+64). }
  bin_code_ptr_t = ^bin_code_t;
  bin_code_t = record
    unused_0: array [0..15] of char;    { +0 }
    start: integer32;                   { +16 }
    unused_20: array [20..55] of char;  { +20 }
    base: integer32;                    { +56 }
    unused_60: integer32;               { +60 }
    sym: integer;                       { +64 }
  end;

  { A routine's name (its IL node's +296). }
  bin_name_ptr_t = ^bin_name_t;
  bin_name_t = record
    unused_0: array [0..15] of char;    { +0 }
    len: integer;                       { +16 }
    chars: array [1..256] of char;      { +18 }
  end;

  { A routine's or block's IL node as bin reads it. }
  bin_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer32;                { +4 }
    parent: bin_node_ptr_t;             { +8 }
    unused_12: array [12..99] of char;  { +12 }
    target_code: bin_code_ptr_t;        { +100 }
    unused_104: array [104..123] of char;    { +104 }
    p124: bin_rtn_ptr_t;                { +124 }
    unused_128: array [128..151] of char;    { +128 }
    range: code_range_ptr_t;            { +152 }
    start_pc: integer32;                { +156 }
    unused_160: array [160..187] of char;    { +160 }
    code: bin_code_ptr_t;               { +188 }
    data_sect: univ_ptr;                { +192 }
    unused_196: array [196..269] of char;    { +196 }
    pos: integer;                       { +270 }
    unused_272: array [272..283] of char;    { +272 }
    w284: integer;                      { +284 }
    unused_286: array [286..295] of char;    { +286 }
    name: bin_name_ptr_t;               { +296 }
    unused_300: array [300..377] of char;    { +300 }
    f378: packed record                 { +378 }
      b378: 0..255;
      b379_7: boolean;                  { +379 .7 }
      b379_6: boolean;                  { .6 }
      b379_5_0: 0..63;
      end;
  end;

  { An operand's symbol as resolve_ap_or_sf_relative_disp reads it:
    kind 110's owner at +40 when +26 bit 8, else +20 when +34 bit 8. }
  bin_sym_ptr_t = ^bin_sym_t;
  bin_sym_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    l4: integer32;                      { +4 }
    unused_8: array [8..19] of char;    { +8 }
    p20: univ_ptr;                      { +20 }
    unused_24: integer;                 { +24 }
    w26: integer;                       { +26 }
    unused_28: array [28..33] of char;  { +28 }
    w34: integer;                       { +34 }
    unused_36: integer32;               { +36 }
    p40: univ_ptr;                      { +40 }
  end;

  { A code range (gen_debug's): from the block heap. }
  code_range_t = record
    next: code_range_ptr_t;             { +0 }
    start: integer32;                   { +4 }
    end_pc: integer32;                  { +8 }
    range: gen_debug_$range_ptr_t;      { +12 }
    chain: univ_ptr;                    { +16: the routine's ranges,
                                          then the .lines offset }
    l20: integer32;                     { +20 }
  end;

  { An exception stub to put after the routine's code (from the stub
    heap). }
  exc_ptr_t = ^exc_t;
  exc_t = record
    next: exc_ptr_t;                    { +0 }
    rtn: bin_rtn_ptr_t;                 { +4 }
    loc: integer32;                     { +8 }
    opnd: opnd_t;                       { +12: the trap's operand 1 }
    pos: integer32;                     { +24 }
    from_list: boolean;                 { +28 }
  end;

  { A section (il_10c's chain): next (+4), size (+12), address (+16),
    routines (+20). }
  bin_sect_ptr_t = ^bin_sect_t;
  bin_sect_t = record
    l0: integer32;                      { +0 }
    next: bin_sect_ptr_t;               { +4 }
    name: univ_ptr;                     { +8 }
    size: integer32;                    { +12 }
    addr: integer32;                    { +16 }
    rtns: bin_rtn_ptr_t;                { +20 }
  end;

  { A source position list (a code cell's +16 when +0 bit 1). }
  pos_list_ptr_t = ^pos_list_t;
  pos_list_t = record
    next: pos_list_ptr_t;               { +0 }
    line: 0..65535;                     { +4 }
    line2: 0..65535;                    { +6 }
  end;

  { A code cell's +16 otherwise: two lines. }
  cell_pos_ptr_t = ^cell_pos_t;
  cell_pos_t = record
    case integer of
      1: (p: pos_list_ptr_t);
      2: (line: 0..65535;
          line2: 0..65535);
  end;

  { An exception operand's value as gen_debug_$exception_site takes it. }
  exc_value_ptr_t = ^exc_value_t;
  exc_value_t = record
    w: integer;                         { +0 }
    b: 0..255;                          { +2 }
  end;

  { map_statement_to_src_loc_and_offset's location: file and line. }
  src_loc_t = packed record
    b31: boolean;
    file_index: 0..2047;                { .30..20 }
    line: 0..1048575;                   { .19..0 }
  end;

  { A case table's code cell. }
  table_cell_ptr_t = ^table_cell_t;
  table_cell_t = record
    h: cell_hdr_t;                      { +0 }
    next: cell_ptr_t;                   { +4 }
    loc: integer32;                     { +8 }
    count: integer32;                   { +12 }
    l16: integer32;                     { +16 }
    entries: array [0..65535] of integer32;  { +20 }
  end;

  { A namelist descriptor literal's p0: words from +18, +16 the count
    of bytes. }
  nl_desc_ptr_t = ^nl_desc_t;
  nl_desc_t = record
    unused_0: array [0..15] of char;    { +0 }
    len: integer;                       { +16 }
    words: array [1..32767] of integer; { +18 }
  end;

  name_t = varying [1024] of char;

var
  stub_heap: mrh_$heap_t;               { +0x0 }
  block_heap: mrh_$heap_t;              { +0x18 }
  emit_108: record                      { +0x30: unix_objmod }
    e108: integer32;                    { the code's size }
    e10c: integer32;                    { the window's base offset }
    e110: integer32;                    { the location counter }
    e114: integer32;                    { the code's object offset }
    e118: univ_ptr;                     { the window }
  end;
  win_off: integer32;                   { +0x44 }
  last_end: integer32;                  { +0x48: after the last word }
  range_start: integer32;               { +0x4C }
  cur_frame: univ_ptr;                  { +0x50: the exception frame of
                                          the code since range_start }
  stmt_blocks: stmt_blocks_ptr_t;       { +0x54 }
  stmt_index: stmt_index_ptr_t;         { +0x58 }
  stmt_bits: stmt_bits_ptr_t;           { +0x5C }
  frame_limit: integer32;               { +0x60 }
  sect_off: integer32;                  { +0x64 }
  cur_node: bin_node_ptr_t;             { +0x68 }
  last_stmt: integer32;                 { +0x6C }
  stub_tail: exc_ptr_t;                 { +0x70 }
  stub_head: exc_ptr_t;                 { +0x74 }
  cur_rtn: bin_rtn_ptr_t;               { +0x78 }
  cur_block: bin_node_ptr_t;            { +0x7C }
  ranges: code_range_ptr_t;             { +0x80 }
  stub_form: boolean;                   { +0x84: -NEW_UNWIND: one-word
                                          stubs }
  emitting: boolean;                    { +0x86: the object file is open }
  listing: boolean;                     { +0x88: -EXP }
  debug: boolean;                       { +0x8A: -DB and emitting }
  exceptions: boolean;                  { +0x8C: il_13c and emitting }

define
  emit_108;

{ bin_$begin_compilation - the heaps entered, the lists emptied, the
  stubs' form from -NEW_UNWIND.

  0x222B3C, 0x6A bytes: mrh_$initialize of +24 (flags 1, size 24) and
  +0 (1, 30), each pair one longword; cargs +0x1E9B bits 7..6 (`moveq
  #64; and.b; lsr.w #6') compared with 1. }

procedure bin_$begin_compilation;
begin
  mrh_$initialize(block_heap, 1, 24, 'block_record code_ranges heap%');
  mrh_$initialize(stub_heap, 1, 30, 'exception stub heap%');
  ranges := nil;
  cur_rtn := nil;
  cur_frame := nil;
  stub_form := cargs_$options.unwind = 1;
end;

{ bin_$end_compilation - nothing.  0x222BD8, 2 bytes. }

procedure bin_$end_compilation;
begin
end;

{ bin_$check_window - the 512-byte window of the object file that holds
  the location (+0x38): while the location is past the window, or there
  is none, the old one is freed and the next mapped (putobj at the base
  plus the code's object offset); the offset into it set.

  0x222BDA, 0x66 bytes, internal. }

procedure bin_$check_window; internal;
begin
  while (emit_108.e10c + 512 <= emit_108.e110) or
        (emit_108.e118 = nil) do begin
    if emit_108.e118 <> nil then begin
      freeobj(emit_108.e118);
      emit_108.e118 := nil;
      emit_108.e10c := emit_108.e10c + 512;
    end;
    emit_108.e118 := putobj(emit_108.e10c + emit_108.e114, 512);
    win_off := emit_108.e110 - emit_108.e10c;
  end;
end;

{ bin_$put_byte_to_pure_text - a byte of code.  0x222C40, 0x2C bytes,
  internal. }

procedure bin_$put_byte_to_pure_text(
    b: integer32); options(val_param); internal;
var
  p: ^char;
begin
  bin_$check_window;
  p := univ_ptr(integer32(emit_108.e118) + win_off);
  p^ := chr(b & 255);
  win_off := win_off + 1;
  emit_108.e110 := emit_108.e110 + 1;
  sect_off := sect_off + 1;
end;

{ bin_$put_word_to_pure_text - a word; a bug check when the window's
  offset is odd (`btst #0,(71,A5)').  0x222C6C, 0x40 bytes, internal. }

procedure bin_$put_word_to_pure_text(
    w: integer32); options(val_param); internal;
var
  p: ^integer;
begin
  bin_$check_window;
  if odd(win_off) then
    bug_check('BIN_$PUT_WORD_TO_PURE_TEXT -- proc_g.offset_counter is not word aligned%$');
  p := univ_ptr(integer32(emit_108.e118) + win_off);
  p^ := w;
  win_off := win_off + 2;
  emit_108.e110 := emit_108.e110 + 2;
  sect_off := sect_off + 2;
end;

{ bin_$put_long_to_pure_text - a longword; a bug check unless the
  window's offset is a multiple of 4.  0x222CF6, 0x40 bytes, internal. }

procedure bin_$put_long_to_pure_text(
    l: integer32); options(val_param); internal;
var
  p: ^integer32;
begin
  bin_$check_window;
  if (win_off & 3) <> 0 then
    bug_check('BIN_$PUT_LONG_TO_PURE_TEXT -- proc_g.offset_counter is not longword aligned%$');
  p := univ_ptr(integer32(emit_108.e118) + win_off);
  p^ := l;
  win_off := win_off + 4;
  emit_108.e110 := emit_108.e110 + 4;
  sect_off := sect_off + 4;
end;

{ add_exception_table_entry - the code from start, len bytes, runs under
  frame: traced under the phase's switch 11, then
  gen_unwind_$add_exception_table_entry (frame by address, -1, start,
  len, frame).

  0x222D84, 0x46 bytes, internal: `btst #3,0x485D30'. }

procedure add_exception_table_entry(
    start: integer32;
    len: integer32;
    frame: univ_ptr); options(val_param); internal;
begin
  if at_backend_switches.sw11 then
    vfmt_$write('ADD_EXECEPTION_TABLE_ENTRY:  frame=%8lh   start_PC=%4lh   size=%4lh%.',
                frame, start, len);
  gen_unwind_$add_exception_table_entry(frame, -1, start, len, frame);
end;

{ bin_$put_cc_long_to_pure_text - a code cell's instruction word, with
  its exception range kept: when exceptions are recorded and the cell
  may raise one (+0 bit 5), its exception_information operand's frame
  starts a range or, differing from the current one, closes it
  (add_exception_table_entry) and starts another; a current frame that
  is not the routine's (its +12) is closed.  The end of the last word
  kept; the word written as bin_$put_long_to_pure_text does.

  0x222E10, 0x11A bytes, internal. }

procedure bin_$put_cc_long_to_pure_text(
    cell: cell_ptr_t); options(val_param); internal;
type
  frame_t = record
    unused_0: array [0..11] of char;    { +0 }
    owner: univ_ptr;                    { +12 }
  end;
var
  k: integer32;
  w: integer32;
  frame: ^frame_t;
  p: ^integer32;
begin
  if exceptions and cell^.h.b0_5 then begin
    k := 1;
    while cell^.opnds[k].h.kind <> operand$exception_information do
      k := k + 1;
    if cur_frame = nil then begin
      cur_frame := cell^.opnds[k].link;
      range_start := cell^.l8;
    end
    else if cur_frame <> univ_ptr(cell^.opnds[k].link) then begin
      add_exception_table_entry(range_start, last_end - range_start,
                                cur_frame);
      cur_frame := cell^.opnds[k].link;
      range_start := cell^.l8;
    end;
  end;
  if exceptions and (cur_frame <> nil) then begin
    frame := cur_frame;
    if univ_ptr(cur_rtn^.node) <> frame^.owner then begin
      add_exception_table_entry(range_start, last_end - range_start,
                                cur_frame);
      cur_frame := nil;
    end;
  end;
  last_end := cell^.l8 + 4;
  w := cell^.l12;
  bin_$check_window;
  if (win_off & 3) <> 0 then
    bug_check('BIN_$PUT_CC_LONG_TO_PURE_TEXT -- proc_g.offset_counter is not longword aligned%$');
  p := univ_ptr(integer32(emit_108.e118) + win_off);
  p^ := w;
  win_off := win_off + 4;
  emit_108.e110 := emit_108.e110 + 4;
  sect_off := sect_off + 4;
end;

{ bin_$advance_to_location - zero bytes up to the section offset loc; a
  bug check when the section is already past it.

  0x222F7A, 0x38 bytes, internal. }

procedure bin_$advance_to_location(
    loc: integer32); options(val_param); internal;
begin
  if loc <> sect_off then begin
    while loc > sect_off do
      bin_$put_byte_to_pure_text(0);
    if loc < sect_off then
      bug_check('BIN_$ADVANCE_TO_LOCATION -- section_offset exceeds location.%$');
  end;
end;

{ bin_$emit_literal_pool - a literal pool's entries (the cell's operand
  1's link, chained at +0): traced under the phase's switch 10; when
  the object file is open, each at its address by its literal's kind
  (a jump table of 21): the integers, booleans and chars by the entry's
  size, a single (converted from the double it is held as: FPP 0x0074
  0x00D4 0xFF3E) as a longword, doubles and complex values as two or
  four longwords, the strings' bytes, a namelist descriptor's words;
  kind 17 or above 20 a bug check; listed under -EXP.

  0x222FF0, 0x1F4 bytes, internal. }

procedure bin_$emit_literal_pool(
    cell: cell_ptr_t); options(val_param); internal;
var
  r: real;
  rv: record
    case integer of
      1: (r: real);
      2: (l: integer32);
  end;
  e: lpe_ptr_t;
  lit: lit_ptr_t;
  i: integer32;
  nd: nl_desc_ptr_t;
begin
  if listing then
    lst_$new_line;
  e := univ_ptr(cell^.opnds[1].link);
  while e <> nil do begin
    if at_backend_switches.sw10 then
      vfmt_$write('obj emit_literal:  object=%8lh   next=%8lh   size=%4lh   location=%8lh   value=%8lh%.',
                  e^.lit, e^.l0, e^.size, e^.addr, e^.lit^.value);
    if emitting then begin
      bin_$advance_to_location(e^.addr);
      lit := e^.lit;
      case lit^.kind of
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11:
          if e^.size = 1 then
            bin_$put_byte_to_pure_text(lit^.value)
          else if e^.size = 2 then
            bin_$put_word_to_pure_text(lit^.value)
          else
            bin_$put_long_to_pure_text(lit^.value);
        12: begin
          r := lit^.d;
          rv.r := r;
          bin_$put_long_to_pure_text(rv.l);
          end;
        13, 14: begin
          bin_$put_long_to_pure_text(lit^.value);
          bin_$put_long_to_pure_text(lit^.l12);
          end;
        15: begin
          bin_$put_long_to_pure_text(lit^.value);
          bin_$put_long_to_pure_text(lit^.l12);
          bin_$put_long_to_pure_text(lit^.l16);
          bin_$put_long_to_pure_text(lit^.l20);
          end;
        18, 19, 20:
          for i := 1 to lit^.len do
            bin_$put_byte_to_pure_text(ord(lit^.chars[i]));
        16: begin
          nd := lit^.p0;
          for i := 1 to (nd^.len + 1) div 2 do
            bin_$put_word_to_pure_text(nd^.words[i]);
          end;
        otherwise
          bug_check('BIN_$EMIT_LITERAL_POOL -- literal object kind %4wd%$',
                    lit^.kind);
      end;
    end;
    if listing then
      lst_$display_literal(e);
    e := univ_ptr(e^.l0);
  end;
end;

{ bin_$emit_table - a case table's entries at its location, bytes, words
  or longwords by its opcode (205, 206, 207); listed under -EXP.

  0x22326E, 0x7E bytes, internal. }

procedure bin_$emit_table(
    cell: cell_ptr_t); options(val_param); internal;
var
  i: integer32;
  tc: table_cell_ptr_t;
begin
  tc := univ_ptr(cell);
  if emitting then begin
    bin_$advance_to_location(tc^.loc);
    i := 0;
    while i < tc^.count do begin
      if tc^.h.opc = 205 then
        bin_$put_byte_to_pure_text(tc^.entries[i])
      else if tc^.h.opc = 206 then
        bin_$put_word_to_pure_text(tc^.entries[i])
      else
        bin_$put_long_to_pure_text(tc^.entries[i]);
      i := i + 1;
    end;
  end;
  if listing then
    lst_$display_table(cell);
end;

{ map_statement_to_src_loc_and_offset - a statement's file and line (in
  loc: the file 1 when get_include_file_index gives none), its block
  (the routine's statement tables) and how many statements of the same
  line came before it with their bit set (counting back while the
  earlier statements' lines are the same or 0), less one.

  0x2232EC, 0xE0 bytes, internal: the line map read through lst_13c
  (0x48C2E0) each time; the bit test `btst' of 7 less stmt mod 8 in the
  byte stmt div 8. }

procedure map_statement_to_src_loc_and_offset(
    stmt: integer32;
    out loc: src_loc_t;
    out count: integer32;
    out block: bin_node_ptr_t); options(val_param); internal;
var
  file_index: integer;
  line: integer;
  map: line_map_ptr_t;
  v: integer32;
begin
  map := lst_13c;
  get_include_file_index(map^[stmt], file_index, line);
  if file_index < 0 then
    file_index := 1;
  loc.file_index := file_index;
  loc.line := line;
  block := stmt_blocks^[stmt_index^[stmt]];
  count := 0;
  if line <> 0 then
    repeat
      if stmt_bits^[stmt] then
        count := count + 1;
      stmt := stmt - 1;
      if stmt = 0 then
        exit;
      map := lst_13c;
      v := map^[stmt];
    until (v <> line) and (v <> 0);
  if count > 0 then
    count := count - 1;
end;

{ new_code_range - a code range for block from pc (gen_debug_$range_open
  with the block's code's symbol), chained on +0x80.

  0x2233CC, 0x5E bytes, internal; A0. }

function new_code_range(
    block: bin_node_ptr_t;
    pc: integer32): code_range_ptr_t; options(val_param); internal;
var
  r: code_range_ptr_t;
begin
  r := mrh_$alloc_fixed(block_heap);
  r^.chain := ranges;
  ranges := r;
  r^.start := pc;
  r^.end_pc := pc;
  r^.range := gen_debug_$range_open(0, block^.code^.sym, pc);
  new_code_range := r;
end;

{ initialize_block - a block of kind 172, or the routine's own, gets its
  first code range at pc when it has none.

  0x22342A, 0x40 bytes, internal. }

procedure initialize_block(
    block: bin_node_ptr_t;
    pc: integer32); options(val_param); internal;
begin
  if (block^.kind = 172) or (block = cur_node) then
    if block^.range = nil then begin
      block^.start_pc := pc;
      block^.range := new_code_range(block, pc);
    end;
end;

{ set_end_pc - the code ranges of block and its parents up to the
  routine end at pc.

  0x22346A, 0x2A bytes, internal, no frame. }

procedure set_end_pc(
    block: bin_node_ptr_t;
    pc: integer32); options(val_param); internal;
begin
  while block <> nil do begin
    if block^.range <> nil then
      block^.range^.end_pc := pc;
    if block = cur_node then
      exit;
    block := block^.parent;
  end;
end;

{ set_current_block - the block whose statements follow from pc: the
  current one's ranges end there; block and its parents up to the
  routine get a range (a new one when their last does not end at pc);
  the innermost with a range made gen_debug's active buffer.

  0x223494, 0x9A bytes, internal. }

procedure set_current_block(
    block: bin_node_ptr_t;
    pc: integer32); options(val_param); internal;
var
  b: bin_node_ptr_t;
  r: code_range_ptr_t;
begin
  if block <> cur_block then begin
    set_end_pc(cur_block, pc);
    b := block;
    while b <> nil do begin
      if b^.range = nil then
        initialize_block(b, pc);
      if b^.range <> nil then begin
        r := b^.range;
        if pc <> r^.end_pc then begin
          r := new_code_range(b, pc);
          r^.next := b^.range;
          b^.range := r;
        end;
      end;
      if b = cur_node then
        exit;
      b := b^.parent;
    end;
    b := block;
    while b^.range = nil do
      b := b^.parent;
    gen_debug_$set_active_buffer(b^.range^.range, pc);
    cur_block := block;
  end;
end;

{ emit_a_pc_to_exception_correlation - a cell that may raise an
  exception: gen_debug_$exception_site of its location and its
  exception_information operand's value (its first word and third
  byte).

  0x22352E, 0x5E bytes, internal. }

procedure emit_a_pc_to_exception_correlation(
    cell: cell_ptr_t); options(val_param); internal;
var
  k: integer32;
  v: exc_value_ptr_t;
begin
  if cell^.h.b0_5 then begin
    k := 1;
    while cell^.opnds[k].h.kind <> operand$exception_information do
      k := k + 1;
    v := addr(cell^.opnds[k].value);
    gen_debug_$exception_site(cell^.l8, v^.w, v^.b);
  end;
end;

{ emit_a_pc_to_line_correlation - statement stmt at pc: unless 0 or the
  last one, its block made current and its line defined
  (gen_debug_$lines_def); the block's ranges end after size bytes.

  0x22358C, 0x8E bytes, internal. }

procedure emit_a_pc_to_line_correlation(
    stmt: integer32;
    pc: integer32;
    size: integer32); options(val_param); internal;
var
  loc: src_loc_t;
  count: integer32;
  block: bin_node_ptr_t;
  line: integer32;
begin
  if stmt <> 0 then
    if stmt <> last_stmt then begin
      last_stmt := stmt;
      map_statement_to_src_loc_and_offset(stmt, loc, count, block);
      if block <> cur_block then
        set_current_block(block, pc);
      line := loc.line;
      if line <> 0 then
        gen_debug_$lines_def(loc.file_index, line, count, pc);
    end;
  set_end_pc(cur_block, pc + size);
end;

{ emit_dot_lines_for_cc - a cell's statements to the .lines table: 8
  bytes when it or a cell it is grouped with (+0 bit 2, the next) is of
  the classes fp_double, immediate, fp_control, fp_single (mask
  0x21108), else 4; the statements of its position (the two lines, or
  the list +16 points to when +0 bit 1), the exception site after the
  first.

  0x22361A, 0x10E bytes, internal. }

procedure emit_dot_lines_for_cc(
    cell: cell_ptr_t); options(val_param); internal;
var
  size: integer32;
  c: cell_ptr_t;
  pos: cell_pos_ptr_t;
  p: pos_list_ptr_t;
begin
  c := cell;
  if instruction_attributes[c^.h.opc].class in
     [class$fp_double, class$immediate, class$fp_control,
      class$fp_single] then
    size := 8
  else
    size := 4;
  while c^.h.b0_2 do begin
    c := c^.next;
    if instruction_attributes[c^.h.opc].class in
       [class$fp_double, class$immediate, class$fp_control,
        class$fp_single] then
      size := 8;
  end;
  pos := addr(cell^.l16);
  if not cell^.h.b0_1 then begin
    emit_a_pc_to_line_correlation(pos^.line, cell^.l8, size);
    emit_a_pc_to_exception_correlation(cell);
    if pos^.line2 <> 0 then
      emit_a_pc_to_line_correlation(pos^.line2, cell^.l8, size);
  end
  else begin
    p := pos^.p;
    while p <> nil do begin
      emit_a_pc_to_line_correlation(p^.line, cell^.l8, size);
      if p = pos^.p then
        emit_a_pc_to_exception_correlation(cell);
      if p^.line2 <> 0 then
        emit_a_pc_to_line_correlation(p^.line2, cell^.l8, size);
      p := p^.next;
    end;
  end;
end;

{ bin_$unwind_bits - a routine's unwind facts: the return register
  (always 22), whether its stack frame is pushed (+226 bit 0), whether
  its stack frame register is above 23, and whether it uses an ECB (a
  pushed frame of at most 128 bytes, +48).

  0x223728, 0x5E bytes: the results by address. }

procedure bin_$unwind_bits(
    info: univ_ptr;
    out frame_reg: integer32;
    out pushed: boolean;
    out big_reg: boolean;
    out ecb: boolean);
var
  rtn: bin_rtn_ptr_t;
begin
  rtn := info;
  frame_reg := 22;
  pushed := rtn^.f226.pushed;
  big_reg := rtn^.stack_reg > 23;
  ecb := rtn^.f226.pushed and (rtn^.l48 <= 128);
end;

{ zero - n bytes from p cleared, a longword at a time.  0x223786, 0x16
  bytes, internal, no frame (zzzzz's and at_backend's are the same). }

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

{ add_unwind_rec - a routine's (or its stubs') scope for the unwind
  table: an open exception range closed first; printed under the
  phase's switch 9; the a88k scope (46 bytes, the first 32 cleared)
  filled from bin_$unwind_bits and the routine's words and masks;
  gen_unwind_$add_scope with the code's base and symbol.

  0x22379C, 0x212 bytes, internal.  The two registers at +222 are copied
  as one longword. }

procedure add_unwind_rec(
    rtn: bin_rtn_ptr_t;
    start: integer32;
    len: integer32); options(val_param); internal;
var
  scope: gen_unwind_$scope_t;
  frame_reg: integer32;
  unused_64: integer32;
  pushed: boolean;
  big_reg: boolean;
  ecb: boolean;
  rp_saved: boolean;
  n: integer32;
  node: bin_node_ptr_t;
begin
  if cur_frame <> nil then begin
    add_exception_table_entry(range_start, last_end - range_start,
                              cur_frame);
    cur_frame := nil;
  end;
  node := rtn^.node;
  bin_$unwind_bits(rtn, frame_reg, pushed, big_reg, ecb);
  if at_backend_switches.sw9 then begin
    vfmt_$write('%.');
    n := node^.name^.len;
    vfmt_$write('Routine name  %25A%.', node^.name^.chars, n);
    vfmt_$write('Start PC                       %8ZH%.', start);
    vfmt_$write('Size                                 %8ZH%.', len);
    vfmt_$write('Stack frame register                 %2WD%.', rtn^.stack_reg);
    n := ord(pushed) & 1;
    vfmt_$write('Is stack frame pushed?               %2D%.', n);
    vfmt_$write('PC offset when stack frame pushed  %4ZWH%.', rtn^.stack_disp);
    vfmt_$write('Return PC register                   %2D%.', frame_reg);
    rp_saved := rtn^.f226.rp_saved;
    vfmt_$write('Is Return PC saved?                  %2WD%.', rp_saved);
    vfmt_$write('register saved at [SF,4]             %2WD%.', rtn^.reg_1);
    vfmt_$write('register saved at [SF,12]            %2WD%.', rtn^.reg_2);
    vfmt_$write('Saved IP regs                  %8ZH%.', rtn^.ip_saved);
    vfmt_$write('Saved FP regs         %8ZH %8ZH%.', rtn^.fp_saved_hi,
                rtn^.fp_saved);
    vfmt_$write('SF offset of saved regs            %4ZWH%.', rtn^.save_reg_disp);
    vfmt_$write('PC offset when regs are saved      %4ZWH%.', rtn^.save_disp);
  end;
  zero(addr(scope), 32);
  scope.start := start;
  scope.len := len;
  scope.a_frame_pushed := pushed;
  scope.a_b43 := big_reg;
  scope.a_sf_offset := rtn^.save_reg_disp;
  scope.a_sf4_reg := rtn^.reg_1;
  scope.a_sf12_reg := rtn^.reg_2;
  scope.a_rp_reg := frame_reg;
  scope.a_rp_saved := rtn^.f226.rp_saved;
  scope.a_b44 := ecb;
  scope.a_regs_pc := rtn^.save_disp;
  scope.a_frame_pc := rtn^.stack_disp;
  scope.a_gregs := rtn^.ip_saved;
  scope.a_fregs1 := rtn^.fp_saved_hi;
  scope.a_fregs2 := rtn^.fp_saved;
  gen_unwind_$add_scope(scope, addr(node^.code^.base), node^.code^.sym);
end;

{ put_procedure_start - a routine's entry cell: with debugging tables,
  the statement count reset, and at the routine's first entry its block
  made current and its statement 0's line defined (when its bit is set
  and the line map has it), then gen_debug_$lines_entry; the routine's
  unwind scope.

  0x223BE0, 0xAC bytes, internal: the block is the cell's operand 1's
  link. }

procedure put_procedure_start(
    rtn: bin_rtn_ptr_t;
    cell: cell_ptr_t;
    first: boolean); options(val_param); internal;
var
  block: bin_node_ptr_t;
  block_0: bin_node_ptr_t;
  count: integer32;
  loc: src_loc_t;
  pc: integer32;
  map: line_map_ptr_t;
begin
  block := univ_ptr(cell^.opnds[1].link);
  pc := cell^.l8;
  if debug then begin
    last_stmt := -1;
    if first then begin
      set_current_block(block, pc);
      map := lst_13c;
      if stmt_bits^[0] and (map^[0] <> 0) then begin
        map_statement_to_src_loc_and_offset(0, loc, count, block_0);
        gen_debug_$lines_def(loc.file_index, loc.line, count, pc);
      end;
    end;
    gen_debug_$lines_entry;
  end;
  add_unwind_rec(rtn, pc, rtn^.size);
end;

{ close_previous_routine - the current routine's debugging ranges closed:
  its last line defined at the code's end (its position's line), each
  code range's exception table and range closed (their results kept at
  +20 and +16); the current routine, block, node and statement
  cleared.

  0x223C8C, 0xDC bytes, internal. }

procedure close_previous_routine; internal;
var
  rtn: bin_rtn_ptr_t;
  r: code_range_ptr_t;
  nxt: code_range_ptr_t;
  node: bin_node_ptr_t;
  size: integer32;
  file_index: integer;
  line: integer;
begin
  rtn := cur_rtn;
  if debug and (rtn <> nil) then begin
    r := ranges;
    if r <> nil then begin
      ranges := nil;
      node := rtn^.node;
      size := emit_108.e110 - node^.code^.start;
      get_include_file_index(node^.pos, file_index, line);
      if file_index < 0 then
        file_index := 1;
      gen_debug_$lines_def(file_index, line, 0, size);
      repeat
        nxt := r^.chain;
        r^.l20 := gen_debug_$exception_table_close(r^.range);
        r^.chain := univ_ptr(gen_debug_$range_close(r^.range, r^.end_pc));
        r := nxt;
      until r = nil;
    end;
  end;
  cur_rtn := nil;
  cur_block := nil;
  cur_node := nil;
  last_stmt := 0;
end;

{ set_current_routine - the routine whose cells follow: the previous one
  closed when it differs; its statement tables (the line map into
  lst_13c) and node taken.

  0x223D68, 0x3E bytes, internal. }

procedure set_current_routine(
    rtn: bin_rtn_ptr_t); options(val_param); internal;
begin
  if rtn <> cur_rtn then
    close_previous_routine;
  lst_13c := rtn^.line_map;
  stmt_bits := rtn^.stmt_bits;
  stmt_index := rtn^.stmt_index;
  stmt_blocks := rtn^.stmt_blocks;
  cur_rtn := rtn;
  cur_node := rtn^.node;
end;

{ resolve_ap_or_sf_relative_disp - an argument block or stack frame
  operand's displacement: the symbol's (sym_$displacement) plus the
  operand's value, a bug check beyond 16 bits; for a checked operand
  (+0 bit 7) whose access (1 shifted by the opcode's size, +19) passes
  the frame's limit, error 34 at the cell's line (cgerr) unless the
  routine does not push its frame and the symbol (kind 110 through +40
  when +26 bit 8, else +20 when +34 bit 8) belongs to it.

  0x223DA6, 0x100 bytes, internal; D0. }

function resolve_ap_or_sf_relative_disp(
    opnd: opnd_ptr_t;
    cell: cell_ptr_t;
    rtn: bin_rtn_ptr_t): integer32; options(val_param); internal;
var
  d: integer32;
  sym: bin_sym_ptr_t;
  owner: univ_ptr;
  pos: cell_pos_ptr_t;
  line: integer32;
  x: integer32;
  map: line_map_ptr_t;
  report: boolean;
begin
  d := sym_$displacement(opnd^.link) + opnd^.value;
  if (d > 32767) or (d < -32768) then
    bug_check('BIN: RESOLVE_AP_OR_SF_RELATIVE_DISP -- displacement exceeds 16 bits%$');
  if opnd^.h.num >= 128 then
    if lshft(1, instruction_attributes[cell^.h.opc].w18 & 7) + d >
       frame_limit then begin
      sym := univ_ptr(opnd^.link);
      report := true;
      if not rtn^.f226.pushed then begin
        if sym^.kind = 110 then begin
          if (sym^.w26 & 256) <> 0 then begin
            owner := sym^.p40;
            report := owner = univ_ptr(rtn^.node);
          end;
        end
        else if (sym^.w34 & 256) <> 0 then begin
          owner := sym^.p20;
          report := owner = univ_ptr(rtn^.node);
        end;
      end;
      if report then begin
        pos := addr(cell^.l16);
        if cell^.h.b0_1 then
          line := pos^.p^.line
        else
          line := pos^.line;
        sym := univ_ptr(opnd^.link);
        if sym^.kind = 110 then
          x := 0
        else
          x := sym^.l4;
        map := lst_13c;
        cgerr(34, map^[line], univ_ptr(x));
      end;
    end;
  resolve_ap_or_sf_relative_disp := d;
end;

{ get_exception_info - a stub record for a trap cell (from the stub
  heap): the routine, the cell's location, operand 1, position and +0
  bit 1.

  0x223EEC, 0x52 bytes, internal; A0. }

function get_exception_info(
    cell: cell_ptr_t;
    rtn: bin_rtn_ptr_t): exc_ptr_t; options(val_param); internal;
var
  e: exc_ptr_t;
begin
  e := mrh_$alloc_fixed(stub_heap);
  e^.rtn := rtn;
  e^.opnd := cell^.opnds[1];
  e^.pos := cell^.l16;
  e^.from_list := cell^.h.b0_1;
  e^.loc := cell^.l8;
  get_exception_info := e;
end;

{ resolve_exception_stub_disp - a trap's stub placed at the section's end
  (its size rounded up to 4, grown by 4 or 12 by the stubs' form) and
  queued; the word displacement to it.

  0x223F3E, 0x6A bytes, internal; D0 (`asr.l #2'). }

function resolve_exception_stub_disp(
    cell: cell_ptr_t;
    rtn: bin_rtn_ptr_t;
    sect: bin_sect_ptr_t): integer32; options(val_param); internal;
var
  e: exc_ptr_t;
  loc: integer32;
begin
  e := get_exception_info(cell, rtn);
  if stub_tail = nil then
    stub_head := e
  else
    stub_tail^.next := e;
  stub_tail := e;
  loc := (sect^.size + 3) & (-4);
  e^.loc := loc;
  if stub_form then
    sect^.size := loc + 4
  else
    sect^.size := loc + 12;
  resolve_exception_stub_disp := arshft(loc - cell^.l8, 2);
end;

{ add_unwind_for_exception_stub - the stubs' scope: the routine's PC
  offsets cleared first.  0x223FA8, 0x28 bytes, internal. }

procedure add_unwind_for_exception_stub(
    rtn: bin_rtn_ptr_t;
    start: integer32;
    len: integer32); options(val_param); internal;
begin
  rtn^.save_disp := 0;
  rtn^.stack_disp := 0;
  add_unwind_rec(rtn, start, len);
end;

{ put_exception - a trap's stub: in the old form a LOADL of register 4
  from a literal 0x00120004 in the pool (PC-relative, +8) and an SVC
  (asm's word less bits 9..8, plus 0x380; operand 2 the trap's operand
  1), the literal itself; in the -NEW_UNWIND form one SVC2 (plus 0x2C0
  and the trap's number).  The cells are built in the frame (two
  3080-byte cells, the pool entry and its literal), each written and
  given its .lines entries; listed under -EXP.

  0x223FD0, 0x270 bytes, internal: the first longwords built in a frame
  word (0x00690000 for LOADL, 0x20830000 SVC2, 0x20820000 SVC). }

procedure put_exception(
    e: exc_ptr_t); options(val_param); internal;
var
  h: record
    case integer of
      1: (l: integer32);
      2: (h: cell_hdr_t);
  end;
  pool: lpe_t;
  lit: lit_t;
  cell_1: cell_t;
  cell_2: cell_t;
begin
  if not stub_form then begin
    h.l := 16#00690000;
    cell_1.h := h.h;
    cell_1.next := nil;
    cell_1.l12 := instruction_assembly[105].w4 + 16#9E0008;
    cell_1.opnds[1].h.kind := operand$displacement_literal_pool;
    cell_1.opnds[1].link := univ_ptr(addr(pool));
    cell_1.opnds[1].value := 8;
    cell_1.opnds[2].h.kind := operand$ip_reg_like;
    cell_1.opnds[2].h.count := 0;
    cell_1.opnds[2].h.num := 30;
    cell_1.opnds[2].value := 0;
    cell_1.opnds[3].h.kind := operand$ip_reg;
    cell_1.opnds[3].h.num := 4;
    cell_1.opnds[3].h.count := 0;
    cell_1.opnds[3].value := 0;
    lit.kind := 3;
    lit.p0 := nil;
    pool.lit := addr(lit);
    pool.size := 4;
  end;
  cell_2.next := nil;
  cell_2.opnds[1].h.kind := operand$immediate;
  cell_2.opnds[1].value := 0;
  if emitting then begin
    bin_$advance_to_location(e^.loc);
    if not stub_form then begin
      cell_1.h.b0_1 := e^.from_list;
      cell_1.l16 := e^.pos;
      cell_1.l8 := e^.loc;
      bin_$put_cc_long_to_pure_text(addr(cell_1));
      if debug and (lst_13c <> nil) then
        emit_dot_lines_for_cc(addr(cell_1));
      e^.loc := e^.loc + 4;
    end;
    cell_2.h.b0_1 := e^.from_list;
    cell_2.l16 := e^.pos;
    cell_2.l8 := e^.loc;
    cell_2.l12 := instruction_assembly[130].w0 & (~16#300);
    if stub_form then begin
      cell_2.l12 := cell_2.l12 + (e^.opnd.value & 255) + 704;
      cell_2.opnds[1].value := 11;
      cell_2.opnds[2].h.kind := operand$immediate;
      cell_2.opnds[2].value := e^.opnd.value & 255;
      cell_2.opnds[2].link := nil;
      cell_2.opnds[3] := e^.opnd;
      h.l := 16#20830000;
    end
    else begin
      cell_2.l12 := cell_2.l12 + 896;
      cell_2.opnds[1].value := 14;
      cell_2.opnds[2] := e^.opnd;
      h.l := 16#20820000;
    end;
    cell_2.h := h.h;
    bin_$put_cc_long_to_pure_text(addr(cell_2));
    if debug and (lst_13c <> nil) then
      emit_dot_lines_for_cc(addr(cell_2));
    e^.loc := e^.loc + 4;
    if not stub_form then begin
      lit.value := 16#00120004;
      bin_$put_long_to_pure_text(lit.value);
    end;
  end;
  if listing then begin
    lst_$new_line;
    if not stub_form then
      lst_$display_code_cell(addr(cell_1));
    lst_$display_code_cell(addr(cell_2));
    if not stub_form then begin
      pool.addr := e^.loc;
      lst_$display_literal(addr(pool));
    end;
  end;
end;

{ put_exception_stubs - the section's queued stubs after its code, a
  routine's at a time: each run of one routine's stubs gets its unwind
  scope (4 or 12 bytes a stub) and then its stubs; the stub heap
  released.

  0x224240, 0xD4 bytes, internal. }

procedure put_exception_stubs; internal;
var
  start: integer32;
  e: exc_ptr_t;
  p: exc_ptr_t;
  size: integer32;
begin
  if stub_head <> nil then begin
    if listing then
      lst_$new_line;
    e := stub_head;
    set_current_routine(e^.rtn);
    start := e^.loc;
    size := 0;
    p := e;
    repeat
      if e^.rtn <> cur_rtn then begin
        add_unwind_for_exception_stub(cur_rtn, start, size);
        while p <> e do begin
          put_exception(p);
          p := p^.next;
        end;
        start := e^.loc;
        size := 0;
        p := e;
      end;
      set_current_routine(e^.rtn);
      if stub_form then
        size := size + 4
      else
        size := size + 12;
      if (e^.next = nil) and (size <> 0) then begin
        add_unwind_for_exception_stub(cur_rtn, start, size);
        while p <> nil do begin
          put_exception(p);
          p := p^.next;
        end;
      end;
      e := e^.next;
    until e = nil;
    mrh_$release_all(stub_heap);
  end;
end;

{ bin_$emit_compilation_pure_text - the compilation's code (unix_objmod
  calls it).

  0x224314, 0x7F6 bytes.  -EXP (cargs +0x27A bit 1) lists: lst's
  columns and the data sections (il_110) first.  The flags: emitting
  (iosub_$object_open), exceptions (il_13c), debugging tables (-DB,
  cargs +0x283/+0x284), the trace of the routines' names (debug switch
  'b', bit 8).  Two template cells: an FNOP (asm's word, for the half
  that follows a cell of the classes fp_double, immediate, fp_single
  which continues) and a grouped NOP (asm's word with bit 31 flipped).
  For each code section (il_10c): listed; its address the location;
  for each routine (+20, chained at +40): made current; the frame's
  limit (+172 for a pushed frame, else +176, but 1000000 or the parent
  routine's +172 for some nested ones, the node's +8 of kinds 105, 107,
  108, +379 bits 7 and 6); its data section listed when it changes;
  for each code cell (traced under switch 9), by the opcode's class:
  labels (an epilogue's line), entries (lst_$procedure_entry,
  put_procedure_start), classes 4, 18, 19, 26 skipped, tables (ltorg's
  literal pool or a case table), traps (put_exception at once); the
  others: a grouped muls/muld takes the next cell's word, the location
  advanced to, the NOP half of a continued floating cell first, the
  displacements patched (an argument block, stack frame or XSB operand
  2 of a cell with +0 bit 6; operand 1 of a cell with +0 bit 7: literal
  pool, routine (a word displacement of 18 bits signed), argument
  block, stack frame, XSB, exception stub) into the low 18 bits (the
  branch-like classes, mask 0x1104366) or 16 bits of the word, with the
  operand form's alignment checked (operand_forms_mask); the cell
  listed and written (unless no_hex); a class fp_control cell written
  again as opcode 1 with its word's high bits 0xE4; the FNOP half after
  a continued cell of another class; the .lines entries.  After the
  routines: the stubs, the last exception range, the routine closed,
  the section padded to 8 and its size kept.  The code's size (+0x30)
  the location at the end. }

procedure bin_$emit_compilation_pure_text;
label
  skip;
var
  unused_4: array [1..3076] of char;
  cell_nop: cell_t;
  cell_fnop: cell_t;
  name: name_t;
  rtn: bin_rtn_ptr_t;
  sect: bin_sect_ptr_t;
  unused_6440: integer32;
  k: integer32;
  count: integer32;
  h: record
    case integer of
      1: (l: integer32);
      2: (h: cell_hdr_t);
  end;
  data_sect: univ_ptr;
  unused_6464: integer32;
  unused_6468: integer32;
  block: bin_node_ptr_t;
  node: bin_node_ptr_t;
  unused_6480: integer32;
  line: integer;
  file_index: integer;
  first: boolean;
  verbose: boolean;
  n: integer32;
  n2: integer32;
  n3: integer32;
  cell: cell_ptr_t;
  cls: integer;
  opc: integer;
  d: integer32;
  mask: integer32;
  loc: src_loc_t;
  pool: lpe_ptr_t;
  target: bin_node_ptr_t;
  kp: bin_node_ptr_t;
  saved: integer;
begin
  listing := cargs_$options.exp;
  if listing then begin
    lst_$begin_compilation;
    sect := univ_ptr(il_110);
    while sect <> nil do begin
      lst_$define_data_section(sect);
      sect := sect^.next;
    end;
  end;
  emitting := iosub_$object_open in iosub_$state;
  exceptions := (il_13c <> 0) and emitting;
  debug := (cargs_$options.db >= 1) and emitting;
  verbose := (cargs_$debug_switches['b'] & 16#100) <> 0;
  h.l := 16#00C10000;
  cell_fnop.h := h.h;
  cell_fnop.l12 := instruction_assembly[193].w0;
  h.l := 16#04C00000;
  cell_nop.h := h.h;
  cell_nop.l12 := instruction_assembly[192].w0 - 16#80000000;
  last_stmt := -1;
  sect := univ_ptr(il_10c);
  while sect <> nil do begin
    if listing then
      lst_$program_section(sect);
    sect^.addr := emit_108.e110;
    sect_off := 0;
    stub_head := nil;
    stub_tail := nil;
    rtn := sect^.rtns;
    while rtn <> nil do begin
      set_current_routine(rtn);
      first := true;
      node := rtn^.node;
      if verbose then begin
        discard(sym_$fully_qualified_routine_name(addr(name), node, -1));
        n := name.length;
        vfmt_$write('BIN: emitting "%a"%.', name.body, n);
      end;
      if rtn^.f226.pushed then
        frame_limit := rtn^.l172
      else if not rtn^.f226.b227_5 then
        frame_limit := rtn^.l176
      else begin
        kp := node^.parent;
        if (kp^.kind <> 108) and (kp^.kind <> 107) and (kp^.kind <> 105) then
          frame_limit := rtn^.l176
        else if not node^.f378.b379_7 and not node^.f378.b379_6 then
          frame_limit := 1000000
        else
          frame_limit := kp^.p124^.l172;
      end;
      if listing then
        if node^.data_sect <> data_sect then begin
          data_sect := node^.data_sect;
          lst_$set_data_section(data_sect);
        end;
      cell := rtn^.cells;
      while cell <> nil do begin
        opc := cell^.h.opc;
        if at_backend_switches.sw9 then begin
          n := ord(instruction_assembly[opc].no_hex) & 1;
          n2 := ord(cell^.h.b0_2) & 1;
          n3 := ord((cell^.h.b2 & 64) <> 0) & 1;
          vfmt_$write('obj     LC: %4zlh  stmt=%3jwd  NOP=%1ld  continued=%1ld  5op=%1ld  %8zlh  %8M8ZA%.',
                      cell^.l8, cell^.l16, n3, n2, n, cell^.l12,
                      instruction_mnemonic[opc]);
        end;
        cls := instruction_attributes[opc].class;
        if cls = class$label then begin
          if opc = 198 then begin
            if debug then begin
              map_statement_to_src_loc_and_offset(0, loc, count, block);
              set_current_block(block, cell^.l8);
              gen_debug_$lines_return;
              last_stmt := -1;
              if cell^.l16 <> 0 then
                emit_dot_lines_for_cc(cell)
              else begin
                get_include_file_index(rtn^.node^.pos, file_index, line);
                if file_index < 0 then
                  file_index := 1;
                gen_debug_$lines_def(file_index, line, 0, cell^.l8);
              end;
            end;
          end
          else if listing then
            lst_$display_code_cell(cell);
        end
        else if cls = class$entry then begin
          if listing then
            lst_$procedure_entry(rtn, cell, cell^.opnds[1].link);
          put_procedure_start(rtn, cell, first);
          first := false;
        end
        else if cls in [class$entry, class$pmove, class$label,
                        class$join_bp] then
          goto skip
        else if cls = class$table then begin
          if opc = 204 then
            bin_$emit_literal_pool(cell)
          else
            bin_$emit_table(cell);
        end
        else if cls = class$trap then begin
          put_exception(get_exception_info(cell, rtn));
          goto skip;
        end
        else begin
          if cell^.h.b0_2 and ((opc = 181) or (opc = 184)) then
            cell^.l12 := cell^.next^.l12;
          if emitting then
            if not (cls in [class$fp_double, class$immediate,
                            class$fp_single]) or
               ((cell^.h.b2 & 64) <> 0) then
              bin_$advance_to_location(cell^.l8);
          if ((cell^.h.b2 & 64) <> 0) and
             (cls in [class$fp_double, class$immediate,
                      class$fp_single]) then begin
            if listing then begin
              cell_nop.h.b2 := (cell_nop.h.b2 & 16#F0) ! (cell^.h.b2 & 15);
              cell_nop.h.b0_1 := cell^.h.b0_1;
              cell_nop.l16 := cell^.l16;
              cell_nop.l8 := cell^.l8;
              lst_$display_code_cell(addr(cell_nop));
            end;
            if emitting then
              bin_$put_cc_long_to_pure_text(addr(cell_nop));
          end;
          k := 0;
          if cell^.h.b0_6 and
             (cell^.opnds[2].h.kind in [operand$displacement_arg_block,
                                        operand$displacement_stack_frame,
                                        operand$displacement_XSB_base]) then begin
            d := resolve_ap_or_sf_relative_disp(addr(cell^.opnds[2]), cell, rtn);
            cell^.opnds[2].value := d;
            k := 2;
          end
          else if cell^.h.b0_7 then begin
            k := 1;
            case cell^.opnds[1].h.kind of
              operand$displacement_literal_pool: begin
                if at_backend_switches.sw10 then
                  vfmt_$write('obj        literal_pool_entry reference = %8ZLX%.',
                              cell^.opnds[1].link);
                pool := univ_ptr(cell^.opnds[1].link);
                d := pool^.addr + cell^.opnds[1].value - cell^.l8;
                if (d > 32767) or (d < -32768) then
                  bug_check('BIN_$EMIT_COMPILATION_PURE_TEXT -- literal pool displacement exceeds 16 bits%$');
                end;
              operand$displacement_routine: begin
                target := univ_ptr(cell^.opnds[1].link);
                d := target^.target_code^.base - cell^.l8;
                if node^.data_sect <> target^.data_sect then
                  d := d + target^.w284;
                d := arshft(d, 2);
                if (d > 131071) or (d < -131072) then
                  bug_check('BIN_$EMIT_COMPILATION_PURE_TEXT -- illegal 20 bit displacement%$');
                end;
              operand$displacement_arg_block, operand$displacement_stack_frame,
              operand$displacement_XSB_base:
                d := resolve_ap_or_sf_relative_disp(addr(cell^.opnds[1]), cell, rtn);
              operand$exception_information:
                d := resolve_exception_stub_disp(cell, rtn, sect);
              otherwise
                k := 0;
            end;
            if k <> 0 then
              cell^.opnds[1].value := d;
          end;
          if k <> 0 then begin
            if cls in [class$branch, class$call, class$fp_branch, class$jump,
                       class$immediate, class$seq, class$trap, class$svc,
                       class$return] then
              d := d & 16#3FFFF
            else
              d := d & 16#FFFF;
            cell^.l12 := cell^.l12 + d;
            mask := ord(operand_forms_mask[instr_attr_view_ptr_t(
                        addr(instruction_attributes[opc]))^.opnds[k].form]);
            if (mask & d) <> 0 then begin
              n := mask & d;
              n2 := mask + 1;
              bug_check('BIN_$EMIT_COMPILATION_PURE_TEXT -- displacement is %ld MOD %ld for operand %ld of %a%$',
                        n, n2, k, instruction_mnemonic[opc], 12);
            end;
          end;
          if listing then
            lst_$display_code_cell(cell);
          if emitting then
            if not instruction_assembly[opc].no_hex then
              bin_$put_cc_long_to_pure_text(cell);
          if cls = class$fp_control then begin
            cell^.l12 := (cell^.l12 & 4095) ! 16#E40000;
            saved := cell^.h.opc;
            cell^.h.opc := 1;
            if listing then
              lst_$display_code_cell(cell);
            if emitting then
              bin_$put_cc_long_to_pure_text(cell);
            cell^.h.opc := saved;
          end
          else if ((cell^.h.b2 & 64) <> 0) and
                  not (cls in [class$fp_double, class$immediate,
                               class$fp_single]) then begin
            if listing then begin
              cell_fnop.h.b2 := (cell_fnop.h.b2 & 16#F0) ! (cell^.h.b2 & 15);
              cell_fnop.h.b0_1 := cell^.h.b0_1;
              cell_fnop.l16 := cell^.l16;
              cell_fnop.l8 := cell^.l8 + 4;
              lst_$display_code_cell(addr(cell_fnop));
            end;
            if emitting then
              bin_$put_cc_long_to_pure_text(addr(cell_fnop));
          end;
        end;
        if debug and (lst_13c <> nil) then
          if not (cls in [class$fp_double, class$immediate,
                          class$fp_single]) or
             ((cell^.h.b2 & 64) <> 0) then
            emit_dot_lines_for_cc(cell);
      skip:
        cell := cell^.next;
      end;
      rtn := rtn^.next;
    end;
    put_exception_stubs;
    if cur_frame <> nil then
      add_exception_table_entry(range_start, last_end - range_start,
                                cur_frame);
    close_previous_routine;
    bin_$advance_to_location((sect_off + 7) & (-8));
    sect^.size := sect_off;
    sect := sect^.next;
  end;
  emit_108.e108 := emit_108.e110;
end;
