{ asm - the PRISM back end's assembler (cc.a88k only; at_backend's
  phase that encodes the instructions): for each routine, pass 1 lays
  the instructions out (each its location; the NOPs the pipeline wants
  in the delay slots and around the floating instructions, by a state
  machine over the instruction kinds; the literal pool's entries
  collected and the pool dumped where the 16-bit literal pool
  displacements would no longer reach, the block split for it), pass 2
  builds each instruction's 32-bit word (the opcode's template from
  instruction_assembly ORed with the operands' fields: the registers,
  the immediates, the branch displacements; docs/prism-isa.md) and
  stores it in the instruction's +24, which zzzzz copies into the code
  cell and bin writes out.  At the end of the compilation each code
  section's last literal pool and its case tables are placed.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x21DCC4  asm_$end_routine
    --------  0x21DCC6  first_bb_with_instructions (internal)
    --------  0x21DCDE  asm_$size_of_indirect_literal (internal)
    --------  0x21DD98  asm_$size_of_direct_literal (internal)
    --------  0x21DE60  add_literal_to_literal_pool (internal)
    --------  0x21DFE8  asm_$operand_in_literal_pool (internal)
    --------  0x21E04A  combine_literal_pools (internal)
    --------  0x21E418  emit_literal_pool (internal)
    --------  0x21E4E6  insert_literal_pool__instruction (internal)
    --------  0x21E624  append_literal_pool__code_cell (internal)
    --------  0x21E768  clear_literal_pool (internal)
    --------  0x21E800  bump_locations (internal)
    --------  0x21E938  new_instruction (internal)
    --------  0x21E9BC  dump_literal_pool (internal)
    --------  0x21EF0C  dump_pass_one_instruction (internal)
    --------  0x21F0A8  complete_entry_sequence (internal)
    --------  0x21F320  excise_instruction (internal)
    --------  0x21F362  asm_$build_dispatch_table (internal)
    --------  0x21F6D4  asm_$process_routine
    --------  0x221848  asm_$begin_compilation
    --------  0x22195C  asm_$end_compilation
    A5 0x4851D4: the module's data (0x65C bytes): the pools' heap (+0),
    the literal pool candidates (+0x18, 68 of 16 bytes: index -1 the
    routine's start, 0 the last block that does not fall through, 1..65
    by loop depth, 66 a split block), the entries' heap (+0x458), the
    pipeline's state table (+0x470, initialized: 8 states by 10
    instruction kinds), the routine's start (+0x650), the location
    counter (+0x654) and asm_658 (+0x658: lir, ra_utils).

  The two literal pools of a routine: pending (local, the entries of
  the code laid out since the last dump) and committed (the code
  section's, +80, those placed); with target_properties.p_be (+0xBE)
  set the routine's literals go in one pool before its second block
  instead, and a second pool (the section's +88) takes the literals of
  LOADL immediates.  The traces (at_backend_switches.sw9 for the
  passes, sw10 for the literals) name the variables: ltorg_cand,
  literal_scope_base, location_counter, pending_pool, committed_pool,
  this_bb, target.

  The gate: docs/dpc-gaps.md 22 (the traces' flags), 25 (parts of
  asm_$process_routine left out of the check) and 32 (the sections
  instr_assembly.init and operand_string*.init define); new readings
  of batch A's records (bb +134, +150; opnd +3 bits 7..5; rtn +44 ..
  +226) are through the local views below; docs/questions.md 177-180.

  Not known from the original: the module cells', locals' and
  parameters' names but those the traces give; the records' views
  (asm_rtn_t, asm_node_t, asm_sect_t, asm_sym_t ...) are named by
  offset where their use is not known; the state table's meaning
  beyond what pass 1 does with it. }
module asm;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_assembly.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_string_length.init';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { Instruction classes (instr_attr_t's class) as asm groups them. }
  branch_like_classes = [class$branch, class$call, class$fp_branch,
    class$jump, class$immediate, class$seq, class$trap, class$svc,
    class$return];                      { 0x1104366 }
  two_word_classes = [class$fp_double, class$immediate,
    class$fp_single];                   { 0x20108: an instruction that
                                          continues takes two words }
  fp_classes = [class$fp_double, class$immediate, class$fp_control,
    class$fp_single];                   { 0x21108 }
  marker_classes = [class$entry, class$pmove, class$label,
    class$join_bp];                     { 0x40C0010 }
  transfer_classes = [class$branch, class$fp_branch, class$jump,
    class$return];                      { 0x1000062 }
  unconditional_classes = [class$jump, class$trap,
    class$return];                      { 0x1004040 }
  no_code_classes = [class$label, class$table];    { 0x2080000 }
  load_store_classes = [class$load, class$store];  { 0x210000 }

type
  { A literal pool: lo (+0) the location of the first instruction that
    refers to it (lo_instruction_lc; -1 empty), hi (+4) the last's,
    size (+8) in bytes, location (+12) where it was placed; heads (+16)
    its entries by alignment (1, 2, 4, 8; sizes 0..1, 2, 3..4, more),
    tails (+48) where the next entry of each goes (the last entry, or
    the head itself; nil for 3, 5..7).  80 bytes, from the pools' heap
    (clear_literal_pool copies +0..+47 from a constant). }
  asm_pool_ptr_t = ^asm_pool_t;
  asm_pool_t = record
    lo: integer32;                      { +0 }
    hi: integer32;                      { +4 }
    size: integer32;                    { +8 }
    location: integer32;                { +12 }
    heads: array [1..8] of lpe_ptr_t;   { +16 }
    tails: array [1..8] of lpe_ptr_t;   { +48 }
  end;

  { A code section (il_10c's chain; a routine's IL node's +188): next
    (+4), size (+12), the case tables' cells (+76), the committed
    literal pool (+80), the last code cell (+84), the second pool (+88,
    target_properties.p_be). }
  asm_sect_ptr_t = ^asm_sect_t;
  asm_sect_t = record
    l0: integer32;                      { +0 }
    next: asm_sect_ptr_t;               { +4 }
    name: univ_ptr;                     { +8 }
    size: integer32;                    { +12 }
    unused_16: array [16..75] of char;  { +16 }
    tables: cell_ptr_t;                 { +76 }
    pool: asm_pool_ptr_t;               { +80 }
    last_cell: cell_ptr_t;              { +84 }
    pool2: asm_pool_ptr_t;              { +88 }
  end;

  { A symbol or code record whose +56 asm sets to a location: a
    routine's code (its node's +100: the routine's address), a label's
    symbol (kind 144; kind 117 points to it at +28), a literal's
    (kind 163: +8 the literal sym_$reformat_literal takes, +20 12). }
  asm_sym_ptr_t = ^asm_sym_t;
  asm_sym_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer32;                { +4 }
    l8: univ_ptr;                       { +8 }
    unused_12: array [12..19] of char;  { +12 }
    b20: char;                          { +20 }
    unused_21: char;                    { +21 }
    unused_22: array [22..27] of char;  { +22 }
    p28: asm_sym_ptr_t;                 { +28 }
    unused_32: array [32..55] of char;  { +32 }
    base: integer32;                    { +56 }
  end;

  { The routine's entry information (its node's +128): the frame
    register (+20), +26 bit 7. }
  asm_info_ptr_t = ^asm_info_t;
  asm_info_t = record
    unused_0: array [0..19] of char;    { +0 }
    reg: 0..65535;                      { +20 }
    unused_22: array [22..25] of char;  { +22 }
    f26: packed record                  { +26 }
      b7: boolean;
      b6_0: 0..127;
      end;
  end;

  { A routine's IL node as asm reads it: kind 167 a nested one (+148
    the routine it is in); its code (+100), entry information (+128),
    code section (+188), two words complete_entry_sequence sets (+282,
    +286) and the limit's offset (+280); +379 bits 7 and 6. }
  asm_node_ptr_t = ^asm_node_t;
  asm_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..99] of char;    { +4 }
    code: asm_sym_ptr_t;                { +100 }
    unused_104: array [104..127] of char;    { +104 }
    info: asm_info_ptr_t;               { +128 }
    unused_132: array [132..147] of char;    { +132 }
    parent: asm_node_ptr_t;             { +148 }
    unused_152: array [152..187] of char;    { +152 }
    sect: asm_sect_ptr_t;               { +188 }
    unused_192: array [192..279] of char;    { +192 }
    w280: integer;                      { +280 }
    w282: integer;                      { +282 }
    w284: integer;                      { +284 }
    w286: integer;                      { +286 }
    unused_288: array [288..377] of char;    { +288 }
    f378: packed record                 { +378 }
      b378: 0..255;
      b379_7: boolean;                  { +379 .7 }
      b379_6: boolean;                  { .6 }
      b379_5_0: 0..63;
      end;
  end;

  { What the routine's +116 points to: a byte (+2) a SYNCH carries. }
  asm_synch_ptr_t = ^asm_synch_t;
  asm_synch_t = packed record
    w0: 0..65535;                       { +0 }
    b2: 0..255;                         { +2 }
  end;

  { The routine (backend.ins.pas's rtn_t, batch A's) as asm reads it:
    its node (+0), code size (+44), frame size (+48), the blocks (+72,
    the last, chained back at +114; +76 in order), +116, the flags
    longword +148 (bits 0, 1), the argument block's size (+176), the
    words +210 (the limit's offset from the entry), +214, +216 and
    +226 bit 1 and bit 0 (the frame pushed). }
  asm_rtn_ptr_t = ^asm_rtn_t;
  asm_rtn_t = record
    node: asm_node_ptr_t;               { +0 }
    unused_4: array [4..43] of char;    { +4 }
    size: integer32;                    { +44 }
    frame_size: integer32;              { +48 }
    unused_52: array [52..115] of char; { +52 }
    p116: asm_synch_ptr_t;              { +116 }
    unused_120: array [120..147] of char;    { +120 }
    f148: set of 0..31;                 { +148 }
    unused_152: array [152..175] of char;    { +152 }
    arg_size: integer32;                { +176 }
    unused_180: array [180..209] of char;    { +180 }
    w210: integer;                      { +210 }
    w212: integer;                      { +212 }
    w214: integer;                      { +214 }
    w216: integer;                      { +216 }
    unused_218: array [218..225] of char;    { +218 }
    f226: packed record                 { +226 }
      b7_2: 0..63;
      b1: boolean;                      { .1 }
      pushed: boolean;                  { .0 }
      end;
  end;

  { A basic block (bb_t, batch A's) as asm reads it beyond bb_t: ip
    (+134) the instruction new_instruction appends after, after (+150)
    the entry's successor while complete_entry_sequence inserts. }
  asm_bb_ptr_t = ^asm_bb_t;
  asm_bb_t = record
    unused_0: array [0..133] of char;   { +0 }
    ip: instr_ptr_t;                    { +134 }
    unused_138: array [138..149] of char;    { +138 }
    after: instr_ptr_t;                 { +150 }
  end;

  { An operand's first longword with +3 bits 7..5 (a literal's size in
    bytes, asm_$size_of_direct_literal). }
  asm_ohdr_ptr_t = ^asm_ohdr_t;
  asm_ohdr_t = packed record
    num: 0..255;                        { +0 }
    rrp: 0..255;                        { +1 }
    b2: 0..255;                         { +2 }
    size: 0..7;                         { +3 .7..5 }
    kind: operand$t;                    { .4..0 }
  end;

  { A namelist descriptor literal's p0: +16 its size. }
  asm_nl_ptr_t = ^asm_nl_t;
  asm_nl_t = record
    unused_0: array [0..15] of char;    { +0 }
    size: 0..65535;                     { +16 }
  end;

  { A case table's code cell: its entries from +20 (the targets'
    instructions, then their displacements from the dispatch). }
  asm_table_ptr_t = ^asm_table_t;
  asm_table_t = record
    h: cell_head_t;                     { +0 }
    next: cell_ptr_t;                   { +4 }
    loc: integer32;                     { +8 }
    count: integer32;                   { +12 }
    l16: integer32;                     { +16 }
    entries: array [0..65535] of integer32;  { +20 }
  end;

  { lir +0x4090: by physical register, its live range. }
  asm_phys_ptr_t = ^asm_phys_t;
  asm_phys_t = array [0..255] of lr_ptr_t;

  { A literal pool candidate (ltorg_cand): the instruction after which
    the pool may go, its location, its block and the block after. }
  asm_cand_t = record
    inst: instr_ptr_t;                  { +0 }
    loc: integer32;                     { +4 }
    this_bb: bb_ptr_t;                  { +8 }
    target: bb_ptr_t;                   { +12 }
  end;

  { The pipeline's state table's entry: flags (bit 0 a NOP word
    before the pending instruction, or one inserted when none is
    pending; 1 a NOP word before the previous instruction (its +2 bit
    6); 2 a NOP instruction inserted after it; 3 a NOP word before this
    one; 4 this one pending; 5 it takes 8 bytes; 6 a NOP instruction
    after it; 7 none pending; 8 a bug check) and the next state. }
  asm_state_t = record
    flags: integer;                     { +0 }
    next: integer32;                    { +2 }
  end;

  { The instruction word as pass 2 builds it (bit 31 the most
    significant; dpc allocates a packed record's fields from the high
    bit): the views by field. }
  asm_word_t = packed record
    case integer of
      1: (b31: boolean;                 { continues into the next word }
          b30, b29, b28: boolean;
          b27: boolean;                 { an 8-bit displacement, or a
                                          high immediate }
          b26: boolean;                 { an immediate compare sets the
                                          condition codes }
          r21: 0..31;                   { 25..21 }
          r16: 0..31;                   { 20..16 }
          b15: boolean;                 { an immediate's sign }
          b14: boolean;                 { sets the condition codes }
          b13_9: 0..31;                 { a field's width less one }
          b8: boolean;                  { a 5-bit immediate for a
                                          register }
          b7: boolean;
          scale: 0..3;                  { 6..5 }
          r0: 0..31);                   { 4..0 }
      2: (c31_30: 0..3;
          f24: 0..63;                   { 29..24 }
          f18: 0..63;                   { 23..18 }
          f12: 0..63;                   { 17..12 }
          f6: 0..63;                    { 11..6 }
          f0: 0..63);                   { 5..0 }
      3: (d31_18: 0..16383;
          disp18: 0..262143);           { 17..0 }
      4: (e31_16: 0..65535;
          imm16: 0..65535);             { 15..0 }
      5: (g31_13: 0..524287;
          imm13: 0..8191);              { 12..0 }
      6: (h31_25: 0..127;
          b24: boolean;                 { sets the floating condition
                                          codes }
          h23_20: 0..15;
          squash: 0..3;                 { 19..18 }
          h17_11: 0..127;
          am: 0..3;                     { 10..9 }
          lsq: 0..3;                    { 8..7 }
          h6_0: 0..127);
      7: (m31_10: 0..4194303;
          imm4: 0..15;                  { 9..6 }
          m5_0: 0..63);
      8: (n31_11: 0..2097151;
          lpoff: 0..63;                 { 10..5 }
          n4_0: 0..31);
      9: (p31_7: 0..33554431;
          imm7: 0..127);                { 6..0 }
      10: (q31_8: 0..16777215;
           q7_1: 0..127;
           bit0: boolean);              { 0 }
      11: (all: integer32);
  end;

define
  asm_658;                              { +0x658 }

var
  pools_heap: mrh_$heap_t;              { +0x0 }
  unused_14: integer32;                 { +0x14 }
  ltorg_cand: array [-1..66] of asm_cand_t;    { +0x18 }
  entries_heap: mrh_$heap_t;            { +0x458 }
  unused_46c: integer32;                { +0x46C }
  state_table: array [0..7, 0..9] of asm_state_t := [
    [[16#20, 0], [16#10, 1], [16#10, 1], [16#28, 0], [16#10, 3],
     [16#10, 3], [16#20, 6], [16#50, 0], [16#50, 0], [16#60, 7]],
    [[16#21, 0], [0, 0], [16#11, 1], [16#29, 0], [0, 4],
     [16#11, 3], [16#21, 6], [16#40, 1], [16#51, 1], [16#61, 7]],
    [[16#100, 0], [0, 1], [0, 7], [16#100, 0], [16#100, 0],
     [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0]],
    [[16#100, 0], [0, 0], [16#10, 7], [16#100, 0], [16#100, 0],
     [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0]],
    [[16#100, 0], [0, 1], [0, 7], [16#100, 0], [16#100, 0],
     [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0]],
    [[16#21, 0], [0, 0], [16#11, 1], [16#29, 0], [0, 2],
     [1, 2], [16#21, 6], [16#40, 5], [16#51, 0], [16#61, 7]],
    [[16#100, 0], [0, 7], [0, 7], [16#100, 0], [16#100, 0],
     [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0], [16#100, 0]],
    [[16#24, 0], [16#80, 0], [16#14, 1], [16#2C, 0], [0, 6],
     [4, 2], [16#24, 6], [16#40, 5], [16#54, 0], [16#64, 7]]];
                                        { +0x470 }
  routine_start: integer32;             { +0x650 }
  location_counter: integer32;          { +0x654 }

{ ASM_$END_ROUTINE - nothing.  0x21DCC4, 0x2 bytes: `rts'. }

procedure asm_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ first_bb_with_instructions - bb or the first block after it that has
  instructions (nil if none).

  0x21DCC6, 0x18 bytes, internal, no frame: bb at (4,SP) in A0, the
  test at the bottom. }

function first_bb_with_instructions(
    bb: bb_ptr_t): bb_ptr_t; options(val_param); internal;
label
  1;
begin
  while bb <> nil do begin
    if bb^.first <> nil then
      goto 1;
    bb := bb^.next;
  end;
1:
  first_bb_with_instructions := bb;
end;

{ asm_$size_of_indirect_literal - the bytes a literal takes in the
  pool when a LOADL loads it: 4 for the integers, word and long
  booleans and singles (kinds 0, 3, 4, 7, 10, 12), 8 for doubles and
  complexes, 16 for double complexes, a namelist descriptor's own
  size, a string's length; any other kind is unimplemented.

  0x21DCDE, 0x7C bytes, internal: a jump table on the kind (`cmpi.w
  #21; bcc' to the unimplemented call). }

function asm_$size_of_indirect_literal(
    lit: lit_ptr_t): integer32; options(val_param); internal;
begin
  case lit^.kind of
    0, 3, 4, 7, 10, 12:
      asm_$size_of_indirect_literal := 4;
    13, 14:
      asm_$size_of_indirect_literal := 8;
    15:
      asm_$size_of_indirect_literal := 16;
    16:
      asm_$size_of_indirect_literal := asm_nl_ptr_t(lit^.p0)^.size;
    18, 19, 20:
      asm_$size_of_indirect_literal := lit^.len;
    otherwise
      unimplemented('ASM_$SIZE_OF_INDIRECT_LITERAL -- literal object kind %4wd%$',
                    lit^.kind);
  end;
end;

{ asm_$size_of_direct_literal - the bytes a literal pool operand's
  literal takes: for the integers, booleans and characters (kinds
  0..11) the operand's own size (+3 bits 7..5), else as
  asm_$size_of_indirect_literal.

  0x21DD98, 0x8E bytes, internal: `move.l #224,D0; and.b (3,A2),D0;
  lsr.l #5,D0'. }

function asm_$size_of_direct_literal(
    op: opnd_ptr_t): integer32; options(val_param); internal;
var
  lit: lit_ptr_t;
begin
  lit := univ_ptr(op^.link);
  case lit^.kind of
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11:
      asm_$size_of_direct_literal := asm_ohdr_ptr_t(op)^.size;
    12:
      asm_$size_of_direct_literal := 4;
    13, 14:
      asm_$size_of_direct_literal := 8;
    15:
      asm_$size_of_direct_literal := 16;
    16:
      asm_$size_of_direct_literal := asm_nl_ptr_t(lit^.p0)^.size;
    18, 19, 20:
      asm_$size_of_direct_literal := lit^.len;
    otherwise
      unimplemented('ASM_$SIZE_OF_DIRECT_LITERAL -- literal object kind %4wd%$',
                    lit^.kind);
  end;
end;

{ add_literal_to_literal_pool - the pool's entry for lit (of size
  bytes): an entry of the same alignment whose literal has the same
  object (p0) and size, unique false; else a new entry at the end of
  its list (the pool's lo set to the location counter when empty, hi
  to it, its size grown by the size rounded to the alignment).

  0x21DE60, 0xF8 bytes, internal: the alignment by a jump table on the
  size (0, 1 -> 1; 2 -> 2; 3, 4 -> 4; else 8), the list by `(12,A3,
  D4.l)' with D4 the alignment times 4; the trace prints the literal's
  kind as a longword (with its length) and the pool's lo. }

function add_literal_to_literal_pool(
    lit: lit_ptr_t;
    size: integer32;
    pool: asm_pool_ptr_t;
    var unique: boolean): lpe_ptr_t; options(val_param); internal;
label
  9;
var
  align: integer32;
  e: lpe_ptr_t;
  n: integer32;
begin
  unique := true;
  case size of
    0, 1:
      align := 1;
    2:
      align := 2;
    3, 4:
      align := 4;
    otherwise
      align := 8;
  end;
  e := pool^.heads[align];
  while e <> nil do begin
    if (e^.lit^.p0 = lit^.p0) and (size = e^.size) then begin
      unique := false;
      goto 9;
    end;
    e := e^.next;
  end;
  e := mrh_$alloc_fixed(entries_heap);
  e^.lit := lit;
  e^.size := size;
  if pool^.lo < 0 then
    pool^.lo := location_counter;
  pool^.hi := location_counter;
  pool^.size := pool^.size + ((size + align - 1) & (-align));
  pool^.tails[align]^.next := e;
  pool^.tails[align] := e;
9:
  if at_backend_switches.sw10 then begin
    n := ord(unique) & 1;
    vfmt_$write('add_literal_to_literal_pool():  literal = %8ZLH    kind = %6ld    size = %8ld      pool = %8ZLH     unique_entry = %2ld      pool_size = %8ld%.',
                lit, lit^.kind, size, pool^.lo, n, pool^.size);
  end;
  add_literal_to_literal_pool := e;
end;

{ asm_$operand_in_literal_pool - op's literal entered in pool; op on
  the entry's list of operands (its link the end of the list).

  0x21DFE8, 0x62 bytes, internal: unique read as the byte's sign. }

procedure asm_$operand_in_literal_pool(
    op: opnd_ptr_t;
    pool: asm_pool_ptr_t); options(val_param); internal;
var
  size: integer32;
  e: lpe_ptr_t;
  unique: boolean;
begin
  size := asm_$size_of_direct_literal(op);
  e := add_literal_to_literal_pool(univ_ptr(op^.link), size, pool, unique);
  if unique then
    e^.refs := op
  else
    e^.last_ref^.link := op;
  e^.last_ref := op;
  op^.link := nil;
end;

{ combine_literal_pools - src's entries moved to dst: an entry whose
  object dst has already is dropped (its operands pointed at dst's), the
  others appended to dst's lists (dst's size grown); every operand's
  link pointed at its entry.  dst's lo the lower, hi the higher.

  0x21E04A, 0x200 bytes, internal: the alignments 1..8 by `dbf' (D2
  7), the lists through two pointers advanced by 4; the empty pool's
  trace is printed for lo < 0. }

procedure combine_literal_pools(
    dst: asm_pool_ptr_t;
    src: asm_pool_ptr_t); options(val_param); internal;
label
  5;
var
  align: integer32;
  e, next_e, d: lpe_ptr_t;
  r, t: opnd_ptr_t;
begin
  if at_backend_switches.sw10 then begin
    vfmt_$write('%/combine_literal_pools():%.');
    if dst^.lo < 0 then
      vfmt_$write('    committed:  POOL IS EMPTY!%.')
    else
      vfmt_$write('    committed:  lo_inst = %8ZLH   hi_inst = %8ZLH  size = %8ZLH location = %8ZLH%.',
                  dst^.lo, dst^.hi, dst^.size, dst^.location);
    if src^.lo < 0 then
      vfmt_$write('    pending  :  POOL IS EMPTY!%.')
    else
      vfmt_$write('    pending  :  lo_inst = %8ZLH   hi_inst = %8ZLH  size = %8ZLH location = %8ZLH%.',
                  src^.lo, src^.hi, src^.size, src^.location);
  end;
  if dst^.lo < 0 then
    dst^.lo := src^.lo
  else if src^.lo >= 0 then
    if src^.lo < dst^.lo then
      dst^.lo := src^.lo;
  if dst^.hi < src^.hi then
    dst^.hi := src^.hi;
  for align := 1 to 8 do begin
    e := src^.heads[align];
    while e <> nil do begin
      next_e := e^.next;
      d := dst^.heads[align];
      while d <> nil do begin
        if e^.lit^.p0 = d^.lit^.p0 then begin
          if at_backend_switches.sw10 then
            vfmt_$write('    duplicate entry:  entry = %8ZLH    object = %8ZLH%.',
                        e, e^.lit);
          goto 5;
        end;
        d := d^.next;
      end;
      d := e;
      dst^.tails[align]^.next := e;
      dst^.tails[align] := e;
      dst^.size := dst^.size + ((align - 1 + e^.size) & (-align));
      if at_backend_switches.sw10 then
        vfmt_$write('    promote: entry = %8ZLH   object = %8ZLH   entry_size = %4ZLH  pool_size = %6ZLH%.',
                    e, e^.lit, e^.size, dst^.size);
      e^.next := nil;
5:
      r := e^.refs;
      while r <> nil do begin
        if at_backend_switches.sw10 then
          vfmt_$write('    rethread:  opr = %8ZLH   sentry = %8ZLH   dentry = %8ZLH%.',
                      r, e, d);
        t := r^.link;
        r^.link := univ_ptr(d);
        r := t;
      end;
      e := next_e;
    end;
  end;
end;

{ emit_literal_pool - the pool placed at loc (rounded to 8): its lists
  chained largest alignment first (8, 4, 2, 1), each entry's address
  given, aligned; head the first entry; the section's size and the
  result the end, rounded to 4.

  0x21E418, 0xCE bytes, internal: the walk is tested at the bottom. }

function emit_literal_pool(
    sect: asm_sect_ptr_t;
    pool: asm_pool_ptr_t;
    var loc: integer32;
    var head: univ lpe_ptr_t): integer32; options(val_param); internal;
var
  t, e: lpe_ptr_t;
begin
  loc := (loc + 7) & (-8);
  pool^.location := loc;
  t := pool^.tails[8];
  t^.next := pool^.heads[4];
  if pool^.heads[4] <> nil then
    t := pool^.tails[4];
  t^.next := pool^.heads[2];
  if pool^.heads[2] <> nil then
    t := pool^.tails[2];
  t^.next := pool^.heads[1];
  e := pool^.heads[8];
  repeat
    case e^.size of
      0, 1:
        ;
      2:
        loc := (loc + 1) & (-2);
      3, 4:
        loc := (loc + 3) & (-4);
      otherwise
        loc := (loc + 7) & (-8);
    end;
    e^.addr := loc;
    loc := loc + e^.size;
    e := e^.next;
  until e = nil;
  head := pool^.heads[8];
  loc := (loc + 3) & (-4);
  sect^.size := loc;
  emit_literal_pool := loc;
end;

{ insert_literal_pool__instruction - an LTORG instruction at loc
  (rounded to 8) after where (or, prefix, before it), where then the
  LTORG, and the pool placed there; the result the section's size (its
  end).  An empty pool: nothing, the section's size.

  0x21E4E6, 0xB8 bytes, internal: prefix a word; before where only
  where's predecessor's next is set (the new instruction's next is
  where). }

function insert_literal_pool__instruction(
    sect: asm_sect_ptr_t;
    pool: asm_pool_ptr_t;
    var where: instr_ptr_t;
    loc: integer32;
    prefix: integer): integer32; options(val_param); internal;
var
  i: instr_ptr_t;
  l: integer32;
begin
  if pool^.lo >= 0 then begin
    if at_backend_switches.sw10 then
      vfmt_$write('%/insert_literal_pool__instruction():  candidate = %8ZLH     location = %8ZLH     prefix_location(1 =>TRUE) = %2wd    pool = %8ZLH%.',
                  where, loc, prefix, pool);
    loc := (loc + 7) & (-8);
    i := lir_$new_instruction(ord(opc$ltorg));
    i^.l28 := loc;
    if prefix = 0 then begin
      i^.next := where^.next;
      where^.next := i;
    end
    else begin
      if where^.prev <> nil then
        where^.prev^.next := i;
      i^.next := where;
    end;
    where := i;
    l := loc;
    sect^.size := emit_literal_pool(sect, pool, l, i^.opnds[1].link);
  end;
  insert_literal_pool__instruction := sect^.size;
end;

{ append_literal_pool__code_cell - an LTORG code cell at loc (rounded
  to 8) after the section's last code cell and the pool placed there;
  the result the pool's end.  An empty pool: loc rounded.

  0x21E624, 0x98 bytes, internal: zzzzz_$new_code_cell's opcode by
  address (the constant 204 after the routine); the bug check's
  message begins with ASM_$ in braces. }

function append_literal_pool__code_cell(
    sect: asm_sect_ptr_t;
    pool: asm_pool_ptr_t;
    loc: integer32): integer32; options(val_param); internal;
var
  l: integer32;
  c, last: cell_ptr_t;
begin
  l := (loc + 7) & (-8);
  if pool^.lo >= 0 then begin
    if at_backend_switches.sw10 then
      vfmt_$write('%/append_literal_pool__code_cell():  location = %8ZLH    pool = %8ZLH%.',
                  loc, pool^);
    c := zzzzz_$new_code_cell(ord(opc$ltorg));
    c^.l8 := l;
    last := sect^.last_cell;
    if last = nil then
      bug_check('{ASM_$}APPEND_LITERAL_POOL__CODE_CELL --- Attempt to append ltorg code_cell to uncoded routine.%$');
    last^.next := c;
    sect^.last_cell := c;
    sect^.size := emit_literal_pool(sect, pool, l, c^.opnds[1].link);
  end;
  append_literal_pool__code_cell := l;
end;

{ clear_literal_pool - pool empty: lo and hi -1, size and location 0,
  no entries, each tail its head (none for the sizes 3, 5..7).

  0x21E768, 0x66 bytes, internal, no frame: +0..+47 copied from a
  constant after the routine (twelve `move.l (A0)+,(A1)+'), the tails
  stored one by one. }

procedure clear_literal_pool(
    pool: asm_pool_ptr_t); options(val_param); internal;
begin
  pool^.lo := -1;
  pool^.hi := -1;
  pool^.size := 0;
  pool^.location := 0;
  pool^.heads[1] := nil;
  pool^.heads[2] := nil;
  pool^.heads[3] := nil;
  pool^.heads[4] := nil;
  pool^.heads[5] := nil;
  pool^.heads[6] := nil;
  pool^.heads[7] := nil;
  pool^.heads[8] := nil;
  pool^.tails[1] := univ_ptr(addr(pool^.heads[1]));
  pool^.tails[2] := univ_ptr(addr(pool^.heads[2]));
  pool^.tails[3] := nil;
  pool^.tails[4] := univ_ptr(addr(pool^.heads[4]));
  pool^.tails[5] := nil;
  pool^.tails[6] := nil;
  pool^.tails[7] := nil;
  pool^.tails[8] := univ_ptr(addr(pool^.heads[8]));
end;

{ bump_locations - the instructions of the blocks from bb up to (not
  including) to_bb moved by incr; with at_start the routine's start
  too.

  0x21E800, 0xA8 bytes, internal: the trace reads to_bb's number even
  when it is nil (process_routine's calls). }

procedure bump_locations(
    bb: bb_ptr_t;
    incr: integer32;
    to_bb: bb_ptr_t;
    at_start: boolean); options(val_param); internal;
var
  i: instr_ptr_t;
  n: integer32;
begin
  if at_backend_switches.sw10 then
    vfmt_$write('%/bump_locations():  From (bb = %8ZLH #%wd)   To (bb = %8ZLH #%wd)   increment = %8ld%.',
                bb, bb^.num, to_bb, to_bb^.num, incr);
  while (bb <> nil) and (bb <> to_bb) do begin
    i := bb^.first;
    while i <> nil do begin
      i^.l28 := i^.l28 + incr;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
  if at_start then begin
    if at_backend_switches.sw10 then begin
      n := incr + routine_start;
      vfmt_$write('    routine start modified   %8ZLH  ------->  %8ZLH%.',
                  routine_start, n);
    end;
    routine_start := routine_start + incr;
  end;
end;

{ new_instruction - an instruction of opcode opc appended after bb's
  insertion point (+134), which it becomes; its operands 1..3 the
  integer registers r1..r3 where these are not negative.  Only the
  insertion point's next is set (complete_entry_sequence relinks).

  0x21E938, 0x84 bytes, internal: the kind and number as bytes (`andi.b
  #-32; or.b' of 1 into +47, +59, +71; `move.b' into +44, +56, +68). }

function new_instruction(
    opc: integer;
    bb: bb_ptr_t;
    r1: integer32;
    r2: integer32;
    r3: integer32): instr_ptr_t; options(val_param); internal;
var
  i: instr_ptr_t;
begin
  i := lir_$new_instruction(opc);
  asm_bb_ptr_t(bb)^.ip^.next := i;
  asm_bb_ptr_t(bb)^.ip := i;
  if r1 >= 0 then begin
    i^.opnds[1].h.kind := operand$ip_reg;
    i^.opnds[1].h.num := r1;
  end;
  if r2 >= 0 then begin
    i^.opnds[2].h.kind := operand$ip_reg;
    i^.opnds[2].h.num := r2;
  end;
  if r3 >= 0 then begin
    i^.opnds[3].h.kind := operand$ip_reg;
    i^.opnds[3].h.num := r3;
  end;
  new_instruction := i;
end;

{ dump_literal_pool - the pending pool dumped in the middle of the
  routine, by a strategy: the best candidate the first (0, then by
  loop depth) whose location the pool's last reference reaches; when
  the routine's start is a candidate and the pools fit before it there
  (strategy 3: the pending pool joins the committed one, placed at the
  start), else with a committed pool 12 (at the candidate, then the
  pending pool committed) or 5 (the pending pool committed, placed at
  the candidate).  At a candidate whose block falls through a JUMP
  around the pool is added.  The code after moves by the pool's size.

  0x21E9BC, 0x3BC bytes, internal: the strategy's bits tested one by
  one (0 combine first, 1 at the start, 2 at the candidate, 3 combine
  after); the search's index runs from -1 (`addq.l #1' first) to 66;
  the code after the strategies runs in every case, with the
  candidate's index as the search left it.  pool_begin is set only at
  the routine's start, candidate 0, or with the JUMP (else what the
  frame holds); the this_bb trace has one argument fewer than its
  format. }

procedure dump_literal_pool(
    committed: asm_pool_ptr_t;
    pending: asm_pool_ptr_t;
    start: integer32;
    bb: bb_ptr_t;
    sect: asm_sect_ptr_t); options(val_param); internal;
label
  1;
var
  total, i, n, pool_end, pool_begin: integer32;
  strategy: integer;
  lim: integer32;
  j: instr_ptr_t;
  p: instr_ptr_t;
  e: fg_edge_ptr_t;
  b: bb_ptr_t;
begin
  total := pending^.size + committed^.size;
  i := -1;
1:
  i := i + 1;
  if i < 66 then
    if (ltorg_cand[i].inst = nil)
       or (total + pending^.hi - target_properties.p_5c > ltorg_cand[i].loc) then
      goto 1;
  strategy := 0;
  if ltorg_cand[-1].inst <> nil then begin
    n := total + location_counter - start;
    lim := target_properties.p_5c - 32;
    if lim > n then begin
      pool_end := start - committed^.lo + total;
      if (pool_end < lim) or (committed^.lo < 0) then
        strategy := 3;
    end;
  end;
  if strategy = 0 then
    if committed^.lo >= 0 then
      strategy := 12
    else
      strategy := 5;
  if at_backend_switches.sw10 then begin
    vfmt_$write('%/dump_literal_pool():  dumping in middle of routine, strategy = %4wd  loop_depth = %4ld%.',
                strategy, i);
    vfmt_$write('    committed:  lo_inst = %8ZLH   hi_inst = %8ZLH  size = %8ZLH location = %8ZLH%.',
                committed^.lo, committed^.hi, committed^.size, committed^.location);
    vfmt_$write('    pending  :  lo_inst = %8ZLH   hi_inst = %8ZLH  size = %8ZLH location = %8ZLH%.',
                pending^.lo, pending^.hi, pending^.size, pending^.location);
  end;
  if (strategy & 1) <> 0 then begin
    combine_literal_pools(committed, pending);
    clear_literal_pool(pending);
  end;
  if (strategy & 2) <> 0 then begin
    pool_begin := start;
    pool_end := append_literal_pool__code_cell(sect, committed, start);
    clear_literal_pool(committed);
  end;
  if (strategy & 4) <> 0 then begin
    if i < 0 then
      pool_begin := start
    else if i = 0 then
      pool_begin := ltorg_cand[0].inst^.l28 + 4;
    if at_backend_switches.sw10 then begin
      vfmt_$write('    best recent:  i = %4LD   location = %8ZLH   pool_begin = %8ZLH%.',
                  i, ltorg_cand[i].loc, pool_begin);
      if i >= 0 then begin
        n := ord(ltorg_cand[i].this_bb^.f.sequential_flow_out) & 1;
        vfmt_$write('        this_bb = BB#%3ZWD %8ZLH  .seq_out = %2LD    target = BB#%3ZWD %8ZLH   target^.inst_head^.loc = %8ZLH%.',
                    ltorg_cand[i].this_bb^.num, ltorg_cand[i].this_bb, n,
                    ltorg_cand[i].target^.num, ltorg_cand[i].target);
        vfmt_$write('        ltorg_cand[i].inst:  %8ZLH  .loc=%6ZLH  %8M8ZA%.',
                    ltorg_cand[i].inst, ltorg_cand[i].inst^.l28,
                    instruction_mnemonic[ltorg_cand[i].inst^.opc]);
      end;
      vfmt_$write('        location_counter = %8ZLH   pool_end = %8ZLH   "loop_depth" = %4ld %.',
                  location_counter, pool_end, i);
    end;
    if i >= 0 then
      if ltorg_cand[i].this_bb^.f.sequential_flow_out then begin
        { The block falls through to its target: a JUMP around the
          pool. }
        j := lir_$new_instruction(ord(opc$jump));
        p := ltorg_cand[i].inst;
        if p^.h.b2_6 and (instruction_attributes[p^.opc].class in two_word_classes) then
          j^.l28 := p^.l28 + 8
        else
          j^.l28 := p^.l28 + 4;
        cell_head_ptr_t(j)^.modify := 0;
        e := lir_$add_flow_graph_edge(ltorg_cand[i].this_bb,
                                      first_bb_with_instructions(ltorg_cand[i].target));
        j^.opnds[1].ptr := e;
        e^.target^.f.needs_label := true;
        j^.opnds[1].h.kind := operand$flow_graph_edge;
        ltorg_cand[i].inst^.next := j;
        ltorg_cand[i].inst := j;
        ltorg_cand[i].this_bb^.f.sequential_flow_out := false;
        pool_begin := j^.l28 + 4;
      end;
    if i < 0 then
      pool_end := append_literal_pool__code_cell(sect, committed, start)
    else
      pool_end := insert_literal_pool__instruction(sect, committed, ltorg_cand[i].inst,
                                                   pool_begin, 0);
    clear_literal_pool(committed);
  end;
  b := first_bb_with_instructions(ltorg_cand[i].target);
  if i > 0 then
    b^.f.needs_label := true;
  pool_end := (pool_end - b^.first^.l28 + 7) & (-8);
  bump_locations(ltorg_cand[i].target, pool_end,
                 first_bb_with_instructions(bb^.next),
                 ltorg_cand[-1].inst <> nil);
  location_counter := location_counter + pool_end;
  ltorg_cand[-1].inst := nil;
  if (strategy & 8) <> 0 then begin
    combine_literal_pools(committed, pending);
    clear_literal_pool(pending);
  end;
end;

{ dump_pass_one_instruction - pass 1's trace of an instruction: mark
  (' ' as it is reached, '+' one grouped with the one before, 'x' one
  excised), its block's and its numbers, location and the state.

  0x21EF0C, 0xD6 bytes, internal: mark a char (the word pushed, the
  character its high byte); for nil the number is read from nil (+42).
  The flags are printed as 0 or 1 (`lsr.b #7'). }

procedure dump_pass_one_instruction(
    i: instr_ptr_t;
    bb: bb_ptr_t;
    mark: char;
    loc: integer32;
    state: integer32); options(val_param); internal;
var
  n1, n2, n3: integer32;
begin
  if i = nil then
    vfmt_$write('pass1  %M1ZA inst: %3ZWD:%3ZWD  %8ZLH %6ZLH  state=%1ld    NIL instruction%.',
                mark, bb^.num, i^.num, i, loc, state)
  else begin
    n1 := ord(instruction_assembly[i^.opc].no_hex) & 1;
    n2 := ord(i^.h.b2_7) & 1;
    n3 := ord(i^.h.grouped) & 1;
    vfmt_$write('pass1  %M1ZA inst: %3ZWD:%3ZWD  %8ZLH %6ZLH  state=%1ld  stmt=%3wd  continued=%1ld   companion=%1ld  5op=%1ld   %8M8ZA%.',
                mark, bb^.num, i^.num, i, loc, state, i^.l32, n3, n2, n1,
                instruction_mnemonic[i^.opc]);
  end;
end;

{ complete_entry_sequence - the code that pushes the frame, after the
  ENTRY instruction of bb (after its PMOVEs): when the routine has a
  frame and pushes it (the node's +379 bit 6 or 7, or rtn's +226 bit 1
  clear, or the entry information's +26 bit 7): a MOVE of the frame
  register (the information's +20) and R1, then a STORE.L of the
  register, R1 premodified by the frame's size (frames of at most 128
  bytes; rtn's +148 bit 1, 8 the words) or R0 loaded with the size / 8
  and a scaled premodified STORE.L (+148 bits 0 and 1, 12); else for a
  frame over 128 bytes with +226 bit 1 only the scaled STORE.L (4).
  rtn's +216 and the node's +282 the count (the words a push takes),
  rtn's +214 and the node's +286 8 when pushed.  The block's links
  repaired after.

  0x21F0A8, 0x23A bytes, internal: the instruction kinds by `andi.b
  #-32; or.b'; the frame size / 8 by `lsr.l #3; neg.l'; the last
  instruction found by the walk (its value from before the walk when
  the block is empty). }

procedure complete_entry_sequence(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param); internal;
var
  i, p, s: instr_ptr_t;
  node, n: asm_node_ptr_t;
  info: asm_info_ptr_t;
  r: asm_rtn_ptr_t;
  words: integer32;
begin
  r := univ_ptr(rtn);
  i := bb^.first;
  while instruction_attributes[i^.opc].class = class$pmove do
    i := i^.next;
  if i^.opc <> ord(opc$entry) then
    bug_check('ASM: COMPLETE_ENTRY_SEQUENCE -- missing ENTRY instruction%$');
  asm_bb_ptr_t(bb)^.ip := i;
  asm_bb_ptr_t(bb)^.after := i^.next;
  node := univ_ptr(i^.opnds[1].link);
  info := node^.info;
  n := node;
  if n^.kind = 167 then
    n := n^.parent;
  if (r^.frame_size <> 0)
     and (n^.f378.b379_6 or (not r^.f226.b1) or info^.f26.b7 or n^.f378.b379_7) then begin
    discard(new_instruction(ord(opc$move), bb, info^.reg, 1, -1));
    if r^.frame_size <= 128 then begin
      r^.f148 := r^.f148 + [1];
      words := 8;
      s := new_instruction(ord(opc$storel), bb, 1, 0, info^.reg);
      s^.opnds[2].h.kind := operand$immediate;
      s^.opnds[2].value := -r^.frame_size;
    end
    else begin
      r^.f148 := r^.f148 + [0, 1];
      words := 12;
      s := new_instruction(ord(opc$move), bb, -1, 0, -1);
      s^.opnds[1].h.kind := operand$immediate;
      s^.opnds[1].value := -rshft(r^.frame_size, 3);
      s := new_instruction(ord(opc$storel), bb, 1, 0, info^.reg);
      s^.opnds[2].h.count := 3;
    end;
    cell_head_ptr_t(s)^.modify := 2;
    r^.w214 := 8;
    node^.w286 := 8;
  end
  else if r^.f226.b1 and not info^.f26.b7 and (r^.frame_size > 128) then begin
    r^.f148 := r^.f148 + [0, 1];
    words := 4;
    s := new_instruction(ord(opc$storel), bb, 1, 0, info^.reg);
    s^.opnds[2].h.count := 3;
    cell_head_ptr_t(s)^.modify := 2;
  end
  else
    words := 0;
  r^.w216 := words;
  node^.w282 := words;
  asm_bb_ptr_t(bb)^.ip^.next := asm_bb_ptr_t(bb)^.after;
  i := bb^.first;
  while i <> nil do begin
    p := i;
    i := i^.next;
    if i <> nil then
      i^.prev := p;
  end;
  bb^.last := p;
end;

{ excise_instruction - i taken out of bb; the result its successor.

  0x21F320, 0x42 bytes, internal: the second test on the flags of the
  store before it. }

function excise_instruction(
    i: instr_ptr_t;
    bb: bb_ptr_t): instr_ptr_t; options(val_param); internal;
var
  n: instr_ptr_t;
begin
  n := i^.next;
  if n <> nil then
    n^.prev := i^.prev
  else
    bb^.last := i^.prev;
  if i^.prev <> nil then
    i^.prev^.next := i^.next
  else
    bb^.first := i^.next;
  excise_instruction := n;
end;

{ asm_$build_dispatch_table - a case dispatch's table (its operand 2's
  cell) turned from the targets' instructions into their displacements
  from the dispatch; when the dispatch is an ADD and the displacements
  fit 0..32767, the LOADL that loaded the entry (scaled x4, its result
  the ADD's operand 1) becomes a LOADBU (a TABLEB, displacements up to
  255) or LOADWU (TABLEW) with its index scaled x1 or x2 (or its
  immediate displacement divided), its word's template exchanged.

  0x21F362, 0x216 bytes, internal: the templates (instruction_assembly
  105 LOADL, 103 LOADBU, 104 LOADWU, +0 or +4) copied and their scale
  field set (`andi.b #-97; or.b' of the copies' low bytes); after the
  bug checks the word is still exchanged. }

procedure asm_$build_dispatch_table(
    i: instr_ptr_t); options(val_param); internal;
label
  1, 9;
var
  tbl: asm_table_ptr_t;
  lo, hi, d: integer32;
  k: integer32;
  l: instr_ptr_t;
  old, new: asm_word_t;
  kind: operand$t;
begin
  hi := 0;
  tbl := univ_ptr(i^.opnds[2].link);
  lo := hi;
  k := tbl^.count;
  while k > 0 do begin
    k := k - 1;
    d := instr_ptr_t(tbl^.entries[k])^.l28 - i^.l28;
    tbl^.entries[k] := d;
    if d < lo then
      lo := d;
    if d > hi then
      hi := d;
  end;
  if (i^.opc <> ord(opc$add)) or (lo < 0) or (hi > 32767) then
    goto 9;
  l := i^.prev;
  while l <> nil do begin
    if (l^.opc = ord(opc$loadl)) and (l^.opnds[3].h.num = i^.opnds[1].h.num)
       and (l^.opnds[1].h.count = 2) then
      goto 1;
    l := l^.prev;
  end;
  goto 9;
1:
  kind := l^.opnds[1].h.kind;
  if hi <= 255 then begin
    tbl^.h.opc := ord(opc$tableb);
    l^.opc := ord(opc$loadbu);
    if (kind = operand$ip_reg)
       or ((kind = operand$ip_reg_like) and (l^.opnds[1].h.num = 31)) then begin
      l^.opnds[1].h.count := 0;
      old.all := instruction_assembly[ord(opc$loadl)].w0;
      old.scale := 2;
      new.all := instruction_assembly[ord(opc$loadbu)].w0;
    end
    else if kind = operand$immediate then
      if (l^.opnds[1].value & 3) <> 0 then
        bug_check('ASM_$BUILD_DISPATCH_TABLE -- immediate displacement on LOADBU from CASE table is not 0 MOD 4%$')
      else begin
        l^.opnds[1].value := arshft(l^.opnds[1].value, 2);
        l^.l24 := (l^.l24 & 16#FFFF0000) ! (l^.opnds[1].value & 16#FFFF);
        old.all := instruction_assembly[ord(opc$loadl)].w4;
        new.all := instruction_assembly[ord(opc$loadbu)].w4;
      end
    else
      bug_check('ASM_$BUILD_DISPATCH_TABLE -- unexpected A operand doing LOADBU from CASE table%$');
  end
  else begin
    tbl^.h.opc := ord(opc$tablew);
    l^.opc := ord(opc$loadwu);
    if (kind = operand$ip_reg)
       or ((kind = operand$ip_reg_like) and (l^.opnds[1].h.num = 31)) then begin
      l^.opnds[1].h.count := 1;
      old.all := instruction_assembly[ord(opc$loadl)].w0;
      old.scale := 2;
      new.all := instruction_assembly[ord(opc$loadwu)].w0;
      new.scale := 1;
    end
    else if kind = operand$immediate then
      if odd(l^.opnds[1].value) then
        bug_check('ASM_$BUILD_DISPATCH_TABLE -- immediate displacement on LOADWU from CASE table is not 0 MOD 2%$')
      else begin
        l^.opnds[1].value := arshft(l^.opnds[1].value, 1);
        l^.l24 := (l^.l24 & 16#FFFF0000) ! (l^.opnds[1].value & 16#FFFF);
        old.all := instruction_assembly[ord(opc$loadl)].w4;
        new.all := instruction_assembly[ord(opc$loadwu)].w4;
      end
    else
      bug_check('ASM_$BUILD_DISPATCH_TABLE -- unexpected A operand doing LOADWU from CASE table%$');
  end;
  l^.l24 := l^.l24 - old.all + new.all;
9:
end;

{ ASM_$PROCESS_ROUTINE - the routine's instructions laid out and
  encoded (above).

  0x21F6D4, 0x19A2 bytes; frame 360 bytes.  The decisions:
  - First: the last block (from rtn's +72 back by +114) dropped when
    empty; each block's back links and last repaired; with
    target_properties.p_be clear the candidates cleared (`dbf' over
    0..66) and -1 set to the section's last cell, the location, the
    first block; the literal scope's base the committed pool's lo.
  - The last block with code (+17 bit 1 clear): a NOP after its last
    instruction (or the one before a two-word floating one) when that
    is branch-like (its delay slot).  The walk reads nil^ when no
    block has code.
  - Pass 1 by block (+17 bit 1 skips one); each instruction's shadow
    (a branch-like one squashing on bit 6 of its mode) noted for the
    next; LIMIT gives rtn's +210 and the node's +280 (the low words'
    difference from the ENTRY) and is excised; entries, PMOVEs, labels
    and join birthpoints take the location and no state; a transfer's
    target block needs a label, a JUMP's, TRAP's or RETURN's squash
    mode copies bit 6 to 7; a grouped IPCCNOP becomes a NOP (the
    floating classes, never met) or is excised; WIDENW and WIDENB are
    TSTW and TSTB.  A literal pool operand enters the pending pool;
    when its 16-bit displacement would no longer reach the pool (the
    scope from the literal scope's base, less 40), the block is split
    before the instruction (lir_$new_basic_block, the new block after
    it falling through; candidate 66) and the pool dumped there (an
    instruction first in its block: the block before is taken again).
    A LOADL of a literal (kind 163, +20 12) enters pool2.
  - The instruction's kind (0..9: 3 two-word floating, 1/2 others (2
    with +0 bit 5), 4/5 and 7/8 calls by the squash mode's high bit,
    6/9 calls followed in their group by a floating instruction or, in
    an atomic block (+17 bit 6), a load (+2 bit 7 set: companion)) and
    the state give the flags and the next state (state_table); the
    instruction and those grouped with it take their locations
    (grouped IPCCNOPs excised, a grouped load of an atomic block
    ungrouped).
  - The end of a block: the pools dumped when the scope reaches 15/16
    of the displacement's range (`asr #4' with the rounding of div); a
    block not ending in a shadow becomes candidate 0 (no fall through)
    or 1 + its loop depth (+16, the lower of the next block's, at most
    64).
  - The end: the committed pool placed at the routine's start, after
    the code, or both (p_be: the pending pool before the second
    block); the routine's size (+44) and the section's.
  - Pass 2 (the encoder): ENTRY and labels set their code's or
    symbol's +56; labels and tables (no_code_classes) are skipped; an
    IPCCNOP is a NOP, TSTS/TSTD MOVES/MOVED of operand 1 to 2, a
    conditional trap the conditional branch of its condition (opcode
    - 20, the double forms - 40) to its operand 3 or 5 (kind spare_3).
    The word: cleared unless the opcode is "5op"; the template
    instruction_assembly's +0; each of the operands the listing shows
    (+11 bits 2..0) by its field kind (+36's bits 7..3: the jump table
    0x2206BE); then the squash mode (57 >> 2 * mode), a field's width,
    a load's or store's mode and qualifier, load_pair's offset, a
    synch's byte, the condition codes' bits and bit 31; stored at +24
    ORed with the template.
  The flags are read as booleans (`tst.b'; `bmi'); locals the frame
  keeps (the pools at -80 and -160, pool_begin) are named by use. }

procedure asm_$process_routine(
    rtn: rtn_ptr_t);
label
  1, 2, 3, 5, 10, 13, 14, 15, 18, 20, 30;
var
  r: asm_rtn_ptr_t;
  node: asm_node_ptr_t;
  sect: asm_sect_ptr_t;
  committed: asm_pool_ptr_t;
  pending: asm_pool_t;
  pool2: asm_pool_t;
  bb, nb, tb: bb_ptr_t;
  i, prev, scan, pend, entry, n, first: instr_ptr_t;
  pend_bb: bb_ptr_t;
  scope_base, state, size, t, k, j, v, lim: integer32;
  cls, scls, kind, depth, field, form, mask: integer32;
  flags: integer;
  shadow, next_shadow, dump, unique: boolean;
  lit: lit_ptr_t;
  sym: asm_sym_ptr_t;
  op: opnd_ptr_t;
  lr: lr_ptr_t;
  reg: integer32;
  opc: integer;
  word, template: asm_word_t;
  n1, n2, n3: integer32;
  e: lpe_ptr_t;
  phys: asm_phys_ptr_t;
begin
  r := univ_ptr(rtn);
  if rtn^.bbs72^.first = nil then
    fg_utils_$drop_this_block(rtn, rtn^.bbs72);
  bb := rtn^.bbs;
  while bb <> nil do begin
    prev := nil;
    i := bb^.first;
    while i <> nil do begin
      prev := i;
      i := i^.next;
      if i <> nil then
        if i^.prev <> prev then
          i^.prev := prev;
    end;
    if bb^.last <> prev then
      bb^.last := prev;
    bb := bb^.next;
  end;
  entry := nil;
  node := r^.node;
  sect := node^.sect;
  location_counter := sect^.size;
  clear_literal_pool(addr(pending));
  clear_literal_pool(addr(pool2));
  committed := sect^.pool;
  if not target_properties.p_be then begin
    for k := 0 to 66 do begin
      ltorg_cand[k].inst := nil;
      ltorg_cand[k].loc := -1;
      ltorg_cand[k].this_bb := nil;
      ltorg_cand[k].target := nil;
    end;
    ltorg_cand[-1].inst := univ_ptr(sect^.last_cell);
    ltorg_cand[-1].loc := location_counter;
    ltorg_cand[-1].this_bb := nil;
    ltorg_cand[-1].target := rtn^.bbs;
    scope_base := -1;
    if committed^.lo >= 0 then
      scope_base := committed^.lo;
  end;
  routine_start := location_counter;
  pend := nil;
  state := 0;
  prev := nil;

  { The routine's last instruction in a delay slot gets a NOP. }
  bb := rtn^.bbs72;
  while bb <> nil do begin
    if not bb^.f.forwarded then
      if bb^.last <> nil then
        goto 5;
    bb := bb^.next114;
  end;
5:
  i := bb^.last;
  if i <> nil then begin
    if instruction_attributes[i^.opc].class in two_word_classes then
      i := i^.prev;
    if instruction_attributes[i^.opc].class in branch_like_classes then begin
      n := lir_$new_instruction(ord(opc$nop));
      n^.next := nil;
      n^.prev := bb^.last;
      bb^.last^.next := n;
      bb^.last := n;
    end;
  end;

  { Pass 1: the layout. }
  shadow := false;
  bb := rtn^.bbs;
  if bb = nil then
    goto 30;
10:
  if bb^.f.forwarded then
    goto 20;
  dump := false;
  if at_backend_switches.sw9 then begin
    n1 := ord(bb^.f.atomic) & 1;
    n2 := bb^.f.depth;
    n3 := ord(bb^.f.sequential_flow_out) & 1;
    vfmt_$write('pass1 BB: block=%lh  BB#%3ZWD, 1st_inst=%lh, last=%lh  sequential_flow_out=%ld  loop_depth=%ld  atomic=%1d%.',
                bb, bb^.num, bb^.first, bb^.last, n3, n2, n1);
  end;
  i := bb^.first;
  goto 18;
13:
  { An instruction. }
  cls := instruction_attributes[i^.opc].class;
  next_shadow := (cls in branch_like_classes) and cell_head_ptr_t(i)^.b3_6;
  if at_backend_switches.sw9 then
    dump_pass_one_instruction(i, bb, ' ', location_counter, state);
  if i^.opc = ord(opc$limit) then begin
    r^.w210 := location_counter - entry^.l28;
    node^.w280 := location_counter - entry^.l28;
    goto 15;
  end;
  if cls in marker_classes then begin
    if cls = class$label then begin
      if cell_head_ptr_t(i)^.b3_7 then
        bb^.f.needs_label := true;
    end
    else if i^.opc = ord(opc$entry) then begin
      entry := i;
      complete_entry_sequence(rtn, bb);
    end;
    prev := i;
    i^.l28 := location_counter;
    i := i^.next;
    goto 14;
  end;
  if cls in transfer_classes then begin
    if cls in unconditional_classes then
      cell_head_ptr_t(i)^.b3_7 := cell_head_ptr_t(i)^.b3_6;
    if i^.opnds[1].h.kind = operand$flow_graph_edge then
      fg_edge_ptr_t(i^.opnds[1].ptr)^.target^.f.needs_label := true;
  end
  else if (i^.opc = ord(opc$ipccnop)) and i^.h.grouped then begin
    if cls in two_word_classes then begin
      i^.opc := ord(opc$nop);
      i^.h.sets_cc := false;
    end
    else
      goto 15;
  end
  else if i^.opc = ord(opc$widenw) then
    i^.opc := ord(opc$tstw)
  else if i^.opc = ord(opc$widenb) then
    i^.opc := ord(opc$tstb);

  { Its literals. }
  if (i^.h.nopnds <> 0) and (i^.opnds[1].h.kind = operand$displacement_literal_pool) then begin
    size := asm_$size_of_direct_literal(addr(i^.opnds[1]));
    if not target_properties.p_be then begin
      if size > target_properties.p_5c then
        bug_check('ASM_$PROCESS_ROUTINE -- huge literal operand: BB#%3ZWD%.', bb^.num);
      if (scope_base >= 0) and not shadow then
        if location_counter - scope_base + size + pending.size + committed^.size
           > target_properties.p_5c - 40 then begin
          { The pool would be out of reach: split the block here. }
          if i = bb^.first then
            bb := bb^.next114
          else begin
            nb := lir_$new_basic_block;
            prev^.next := nil;
            i^.prev := nil;
            nb^.f.depth := bb^.f.depth;
            nb^.f.sequential_flow_out := bb^.f.sequential_flow_out;
            bb^.f.sequential_flow_out := true;
            nb^.first := i;
            nb^.last := bb^.last;
            bb^.last := scan;
            nb^.next := bb^.next;
            nb^.next114 := bb;
            bb^.next := nb;
            if i^.h.b2_6 or (instruction_attributes[i^.opc].class in fp_classes) then
              i^.l28 := (location_counter + 7) & (-8)
            else
              i^.l28 := location_counter;
            ltorg_cand[66].inst := prev;
            ltorg_cand[66].loc := i^.l28 + 4;
            ltorg_cand[66].this_bb := bb;
            ltorg_cand[66].target := nb;
            if at_backend_switches.sw10 then begin
              n1 := ord(nb^.f.sequential_flow_out) & 1;
              n2 := bb^.f.depth;
              vfmt_$write('      splitting BB:  (old BB#%3ZWD %8ZLH)  (new BB#%3ZWD %8ZLH)  loop depth=%4ld  sequential_flow_out=%2ld %.',
                          bb^.num, bb, nb^.num, nb, n2, n1);
              vfmt_$write('                     literal_scope_base = %8ZLH  pending.size = %5ZLH  committed.size = %5ZLH%.',
                          scope_base, pending.size, committed^.size);
            end;
          end;
          dump := true;
          goto 20;
        end;
      if scope_base < 0 then
        scope_base := location_counter;
    end;
    asm_$operand_in_literal_pool(addr(i^.opnds[1]), addr(pending));
  end
  else if (i^.opc = ord(opc$loadl)) and (i^.opnds[1].h.kind = operand$immediate)
          and (i^.opnds[1].link <> nil) then begin
    sym := univ_ptr(i^.opnds[1].link);
    if (sym^.kind = 163) and (ord(sym^.b20) = 12) then begin
      lit := sym_$reformat_literal(sym^.l8);
      size := asm_$size_of_indirect_literal(lit);
      discard(add_literal_to_literal_pool(lit, size, addr(pool2), unique));
    end;
  end;

  { Its kind for the pipeline. }
  cell_head_ptr_t(i)^.b2 := cell_head_ptr_t(i)^.b2 & 15;
  cls := instruction_attributes[i^.opc].class;
  if not (cls in fp_classes) then begin
    scan := i;
    while scan^.h.grouped do begin
      scan := scan^.next;
      cell_head_ptr_t(scan)^.b2 := cell_head_ptr_t(scan)^.b2 & 15;
      scls := instruction_attributes[scan^.opc].class;
      if (scls in fp_classes) or (bb^.f.atomic and (scls = class$load)) then begin
        i^.h.b2_7 := true;
        goto 1;
      end;
    end;
    if i^.opc = ord(opc$call) then
      if cell_head_ptr_t(i)^.b3_7 then
        if i^.h.quad_aligned then
          kind := 5
        else
          kind := 4
      else if i^.h.quad_aligned then
        kind := 8
      else
        kind := 7
    else if i^.h.quad_aligned then
      kind := 2
    else
      kind := 1;
    goto 2;
  end;
1:
  if cls in two_word_classes then
    kind := 3
  else if i^.opc <> ord(opc$call) then
    kind := 0
  else if cell_head_ptr_t(i)^.b3_7 then
    kind := 6
  else
    kind := 9;
2:
  flags := state_table[state, kind].flags;
  state := state_table[state, kind].next;
  if (flags & 16#100) <> 0 then
    bug_check('ASM_$PROCESS_ROUTINE -- FP operation scheduled in shadow of CALL.SA%$');
  if (flags & 1) <> 0 then
    if pend = nil then
      flags := flags ! 4
    else begin
      pend^.h.b2_6 := true;
      while pend <> i do begin
        pend := pend^.next;
        if pend = nil then begin
          pend_bb := pend_bb^.next;
          pend := pend_bb^.first;
        end;
        pend^.l28 := pend^.l28 + 4;
      end;
      location_counter := location_counter + 4;
      pend := nil;
    end;
  if (flags & 2) <> 0 then begin
    prev^.h.b2_6 := true;
    location_counter := location_counter + 4;
  end;
  if (flags & 4) <> 0 then begin
    n := lir_$new_instruction(ord(opc$nop));
    n^.next := prev^.next;
    n^.prev := prev;
    prev^.next := n;
    if i^.prev <> nil then
      i^.prev := n;
    n^.l28 := location_counter;
    location_counter := location_counter + 4;
  end;
  if (flags & 8) <> 0 then
    i^.h.b2_6 := true;
  if (flags & 16) <> 0 then begin
    pend := i;
    pend_bb := bb;
  end;

  { The instruction and those grouped with it. }
  repeat
    prev := i;
    i^.l28 := location_counter;
    i := i^.next;
    if i = nil then
      goto 3;
    if at_backend_switches.sw9 and prev^.h.grouped then
      dump_pass_one_instruction(i, bb, '+', location_counter, state);
    if prev^.h.grouped then
      if i^.opc = ord(opc$ipccnop) then begin
        if at_backend_switches.sw9 then
          dump_pass_one_instruction(i, bb, 'x', location_counter, state);
        prev^.h.grouped := i^.h.grouped;
        i := excise_instruction(i, bb);
        if i = nil then
          goto 3;
        if at_backend_switches.sw9 and prev^.h.grouped then
          dump_pass_one_instruction(i, bb, '+', location_counter, state);
      end
      else if bb^.f.atomic then
        if instruction_attributes[i^.opc].class = class$load then begin
          prev^.h.grouped := false;
          prev^.h.b2_7 := false;
          i^.l28 := location_counter + 4;
          i := i^.next;
          if i = nil then
            goto 3;
        end;
    cell_head_ptr_t(i)^.b2 := cell_head_ptr_t(i)^.b2 & 15;
  until not prev^.h.grouped;
3:
  if (flags & 16#20) <> 0 then
    location_counter := location_counter + 8
  else
    location_counter := location_counter + 4;
  if (flags & 16#40) <> 0 then begin
    n := lir_$new_instruction(ord(opc$nop));
    n^.l28 := location_counter;
    n^.next := i;
    prev^.next := n;
    prev := n;
    location_counter := location_counter + 4;
  end;
  if (flags & 16#80) <> 0 then
    pend := nil;
  goto 14;
15:
  { The instruction excised. }
  if at_backend_switches.sw9 then
    dump_pass_one_instruction(i, bb, 'x', location_counter, state);
  i := excise_instruction(i, bb);
  if i = nil then
    goto 20;
14:
  shadow := next_shadow;
18:
  if i <> nil then
    goto 13;
20:
  { The end of a block. }
  if not target_properties.p_be then begin
    t := pending.size + committed^.size;
    if scope_base >= 0 then
      if location_counter - scope_base + t > (target_properties.p_5c * 15) div 16 then
        dump := true;
    if dump then begin
      dump_literal_pool(committed, addr(pending), routine_start, bb, sect);
      scope_base := -1;
      if pending.lo >= 0 then
        scope_base := pending.lo;
      if committed^.lo >= 0 then
        if committed^.lo < pending.lo then
          scope_base := committed^.lo;
      dump := false;
    end;
    if not shadow then
      if not bb^.f.sequential_flow_out then begin
        ltorg_cand[0].inst := prev;
        ltorg_cand[0].loc := location_counter;
        ltorg_cand[0].this_bb := bb;
        ltorg_cand[0].target := bb^.next;
      end
      else begin
        depth := bb^.f.depth;
        if bb^.next <> nil then
          if bb^.next^.f.depth < depth then
            depth := bb^.next^.f.depth;
        if depth > 64 then
          depth := 64;
        ltorg_cand[depth + 1].inst := prev;
        ltorg_cand[depth + 1].loc := location_counter;
        ltorg_cand[depth + 1].this_bb := bb;
        ltorg_cand[depth + 1].target := bb^.next;
      end;
  end;
  bb := bb^.next;
  if bb <> nil then
    goto 10;
30:

  { The routine's last literal pool. }
  if not target_properties.p_be then begin
    if at_backend_switches.sw10 then begin
      vfmt_$write('%/end of routine:  location_counter = %8ZLH%.', location_counter);
      vfmt_$write('    committed_pool^.lo_instruction_lc = %8ZLH%.', committed^.lo);
      vfmt_$write('    committed_pool^.size              = %8ZLH%.', committed^.size);
      vfmt_$write('    pending_pool.lo_instruction_lc    = %8ZLH%.', pending.lo);
      vfmt_$write('    pending_pool^.size                = %8ZLH%.', pending.size);
      if scope_base < 0 then
        vfmt_$write('    literal_scope_base            = XXXXXXXX%.')
      else
        vfmt_$write('    literal_scope_base            = %8ZLH%.', scope_base);
    end;
    if (committed^.lo < 0)
       or (committed^.lo + target_properties.p_5c
           > committed^.size + location_counter + pending.size) then begin
      if pending.lo >= 0 then
        combine_literal_pools(committed, addr(pending));
    end
    else if committed^.lo + target_properties.p_5c
            > committed^.size + scope_base + pending.size then begin
      if pending.lo >= 0 then
        combine_literal_pools(committed, addr(pending));
      t := append_literal_pool__code_cell(sect, committed, routine_start);
      t := (t - ltorg_cand[-1].loc + 7) & (-8);
      bump_locations(ltorg_cand[-1].target, t, nil, ltorg_cand[-1].inst <> nil);
      location_counter := location_counter + t;
      clear_literal_pool(committed);
    end
    else begin
      if committed^.lo >= 0 then begin
        t := append_literal_pool__code_cell(sect, committed, ltorg_cand[-1].loc);
        t := (t - ltorg_cand[-1].loc + 7) & (-8);
        bump_locations(ltorg_cand[-1].target, t, nil, ltorg_cand[-1].inst <> nil);
        location_counter := location_counter + t;
        clear_literal_pool(committed);
      end;
      if pending.lo >= 0 then
        combine_literal_pools(committed, addr(pending));
    end;
  end
  else begin
    if pending.size > target_properties.p_5c then
      bug_check('ASM_$PROCESS_ROUTINE -- routine literal pool exceeds constant_lb reach of %LD K %$',
                target_properties.p_5c);
    if at_backend_switches.sw10 then begin
      vfmt_$write('%/end of routine:  location_counter = %8ZLH%.', location_counter);
      vfmt_$write('    short literal pool size = %8ld%.', pending.size);
    end;
    combine_literal_pools(committed, addr(pending));
    first := rtn^.bbs^.next^.first;
    t := insert_literal_pool__instruction(sect, addr(pending), first, routine_start, 1);
    t := (t - routine_start + 7) & (-8);
    bump_locations(rtn^.bbs^.next, t, nil, true);
    rtn^.bbs^.next^.first := first;
    location_counter := location_counter + t;
    clear_literal_pool(committed);
    if at_backend_switches.sw10 then
      vfmt_$write('    long literal pool size = %8ld%.', pool2.size);
    combine_literal_pools(sect^.pool2, addr(pool2));
  end;
  location_counter := (location_counter + 7) & (-8);
  r^.size := location_counter - routine_start;
  node^.sect^.size := location_counter;

  { Pass 2: the encoding. }
  phys := univ_ptr(addr(lir_4090));
  bb := rtn^.bbs;
  while bb <> nil do begin
    if at_backend_switches.sw9 then
      vfmt_$write('pass2 BB: block=%lh, BB#%3ZWD  1st_inst=%lh, last=%lh%.',
                  bb, bb^.num, bb^.first, bb^.last);
    i := bb^.first;
    while i <> nil do begin
      opc := i^.opc;
      if opc = ord(opc$entry) then
        asm_node_ptr_t(i^.opnds[1].link)^.code^.base := i^.l28
      else if opc = ord(opc$label) then begin
        sym := univ_ptr(i^.opnds[1].link);
        if sym <> nil then begin
          if sym^.kind = 117 then
            sym := sym^.p28;
          if sym <> nil then
            if sym^.kind = 144 then
              sym^.base := i^.l28;
        end;
      end;
      if not (instruction_attributes[opc].class in no_code_classes) then begin
        if opc = ord(opc$ipccnop) then begin
          opc := ord(opc$nop);
          i^.h.sets_cc := false;
          i^.opc := opc;
        end
        else if (opc = ord(opc$tsts)) or (opc = ord(opc$tstd)) then begin
          if opc = ord(opc$tsts) then
            opc := ord(opc$moves)
          else
            opc := ord(opc$moved);
          i^.opnds[2] := i^.opnds[1];
          i^.opc := opc;
        end
        else if instruction_attributes[opc].class = class$trap_cond then begin
          if (i^.opnds[1].h.kind = operand$fp_reg) or (i^.opnds[1].h.kind = operand$ip_reg) then begin
            j := 3;
            opc := opc - 20;
          end
          else if i^.opnds[1].h.kind = operand$fp_reg_pair then begin
            j := 5;
            opc := opc - 40;
          end
          else
            bug_check('ASM_$PROCESS_ROUTINE -- unexpected 1st operand kind in a TRAP instruction%$');
          i^.opc := opc;
          cell_head_ptr_t(i)^.b3_7 := true;
          i^.opnds[1] := i^.opnds[j];
          if i^.opnds[1].h.kind <> operand$spare_3 then
            i^.opnds[1].h.kind := operand$spare_3;
        end;

        if not instruction_assembly[opc].no_hex then
          word.all := 0;
        template.all := instruction_assembly[opc].w0;
        for k := 1 to instruction_attributes[opc].nresults do begin
          op := addr(i^.opnds[k]);
          if op^.h.kind in [operand$ip_reg .. operand$fp_reg_pair_physical,
                            operand$ip_reg_like .. operand$fp_reg_pair_like,
                            operand$case_jump_base] then begin
            if op^.h.kind = operand$case_jump_base then begin
              op^.h.kind := operand$ip_reg_like;
              asm_$build_dispatch_table(i);
            end;
            word.scale := op^.h.count;
            if op^.lts = nil then
              lr := phys^[op^.h.num]
            else
              lr := op^.lts^.lr;
            op^.link := univ_ptr(lr^.node20);
            op^.ptr := lr;
            reg := lr^.f2.reg;
            op^.h.num := reg;
          end;
          v := op^.value;
          field := rshft(instruction_assembly[opc].opnd[k] & 16#F8, 3);
          case field of
            0:
              word.r0 := reg & 31;
            1:
              word.r16 := reg & 31;
            2:
              word.r21 := reg & 31;
            3:
              word.r21 := rshft(reg, 1) & 31;
            4, 5:
              if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                operand$ip_reg_like, operand$case_jump_base] then
                word.r0 := reg & 31
              else begin
                { The immediate form. }
                template.all := instruction_assembly[opc].w4;
                form := instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[k].form;
                case form of
                  1, 2:
                    if op^.h.kind = operand$flow_graph_edge then begin
                      tb := fg_edge_ptr_t(v)^.target;
                      if tb^.f.forwarded then
                        bug_check('ASM_$PROCESS_ROUTINE -- target of branch is forwarded basic block%$');
                      word.disp18 := arshft(tb^.first^.l28 - i^.l28, 2) & 16#3FFFF;
                    end
                    else if ((form = 1) and (op^.h.kind <> operand$displacement_routine))
                            or ((form = 2) and (op^.h.kind <> operand$spare_3)) then
                      bug_check('ASM_$PROCESS_ROUTINE -- unexpected operand kind for long PC displacement%$');
                  3:
                    word.imm16 := (-v) & 16#FFFF;
                  5:
                    bug_check('ASM_$PROCESS_ROUTINE -- of$short_pc_disp not yet supported%$');
                  7, 9:
                    begin
                      word.imm7 := v & 127;
                      word.b15 := v < 0;
                    end;
                  8, 10, 11, 16, 20, 24, 25, 27, 28, 29, 30:
                    begin
                      op^.h.num := 0;
                      if (cell_head_ptr_t(i)^.modify <> 0) or (cell_head_ptr_t(i)^.lsq <> 0) then begin
                        { A load or store that modifies its base or has a
                          qualifier: an 8-bit displacement. }
                        if (op^.h.kind in [operand$displacement_arg_block .. operand$displacement_XSB_base])
                           or (v > 127) or (v < -128) then
                          bug_check('ASM_$PROCESS_ROUTINE -- illegal 8 bit displacement%$');
                        template.all := instruction_assembly[opc].w0;
                        word.b27 := true;
                        word.imm7 := v & 127;
                        word.b15 := v < 0;
                      end
                      else begin
                        if op^.h.kind = operand$immediate then
                          word.imm16 := v & 16#FFFF
                        else if op^.h.kind = operand$displacement_XSB_base then begin
                          v := v + lir_main_c40;
                          op^.value := v;
                          if v > 32767 then
                            bug_check('ASM_$PROCESS_ROUTINE -- %LD displacement to first XSB exceeds 16 bits%$',
                                      v);
                          op^.h.kind := operand$immediate;
                          word.imm16 := v & 16#FFFF;
                        end
                        else if op^.h.kind in [operand$displacement_arg_block .. operand$displacement_XSB_base] then begin
                          { Left for bin. }
                          if i^.opc <> ord(opc$add) then
                            if i^.opnds[k + 1].value = asm_658 then
                              op^.h.num := op^.h.num ! 128;
                          v := 0;
                        end
                        else
                          bug_check('ASM_$PROCESS_ROUTINE -- unexpect operand kind for displacement%$');
                        mask := ord(operand_forms_mask[form]);
                        if (mask & v) <> 0 then begin
                          n1 := mask & v;
                          n2 := mask + 1;
                          n3 := op^.h.num;
                          bug_check('ASM_$PROCESS_ROUTINE -- immediate is %ld MOD %ld for operand %ld of %a%$',
                                    n1, n2, n3, instruction_mnemonic[i^.opc], 12);
                        end;
                        if v <> 0 then
                          if i^.opc <> ord(opc$add) then
                            if i^.opnds[k + 1].value = asm_658 then begin
                              v := v + lshft(1, instruction_attributes[opc].w18 & 7);
                              if r^.f226.pushed then begin
                                if v > lir_main_c6c then
                                  bug_check('ASM_$PROCESS_ROUTINE -- SF relative access beyond register save area%$');
                              end
                              else if v > r^.arg_size then
                                bug_check('ASM_$PROCESS_ROUTINE -- SF relative access outside of supplied argument block%$');
                            end;
                      end;
                    end;
                  12, 14, 26:
                    begin
                      if form = 14 then
                        if (v & 16#FFFF0000) <> 0 then
                          if (v & 16#FFFF) <> 0 then begin
                            { AND and BIC exchanged for the complement. }
                            v := ~v;
                            op^.value := v;
                            if opc = ord(opc$and) then
                              opc := ord(opc$bic)
                            else
                              opc := ord(opc$and);
                            i^.opc := opc;
                            template.all := instruction_assembly[opc].w4;
                          end;
                      if (form = 26) and ((v & 16#FFFF) <> 0) and (((~v) & 16#FFFF0000) = 0) then begin
                        { A negative value of 16 bits: ADD's immediate form. }
                        template.all := instruction_assembly[ord(opc$add)].w4;
                        word.imm16 := v & 16#FFFF;
                      end
                      else if (v & 16#FFFF0000) = 0 then
                        word.imm16 := v
                      else if (v & 16#FFFF) = 0 then begin
                        { A high immediate. }
                        word.imm16 := rshft(v, 16);
                        word.b27 := true;
                      end
                      else
                        bug_check('ASM_$PROCESS_ROUTINE -- cannot encode immediate for i860 logical: x%8ZLH%$',
                                  v);
                    end;
                  otherwise
                    bug_check('ASM_$PROCESS_ROUTINE -- unexpected operand form: %a%$',
                              of_string[form], of_string_length[form]);
                end;
                { The forms done. }
              end;
            6:
              if op^.h.kind = operand$fp_reg then
                word.imm13 := (reg * 4) & 8191
              else
                word.imm13 := v & 8191;
            7:
              if op^.h.kind <> operand$immediate then
                word.r16 := reg & 31
              else begin
                word.r16 := v & 31;
                word.b8 := true;
              end;
            8:
              if op^.h.kind <> operand$immediate then
                word.r21 := reg & 31
              else begin
                word.r21 := v & 31;
                word.b8 := true;
              end;
            9:
              word.imm4 := v & 15;
            10:
              begin
                { A single in a double register: an odd one makes the
                  store STORESO, the load LOADSO. }
                if odd(reg) then
                  if opc = ord(opc$stores) then begin
                    opc := ord(opc$storeso);
                    template.all := instruction_assembly[ord(opc$storeso)].w0;
                  end
                  else begin
                    opc := ord(opc$loadso);
                    if template.all = instruction_assembly[ord(opc$loads)].w0 then
                      template.all := instruction_assembly[ord(opc$loadso)].w0
                    else
                      template.all := instruction_assembly[ord(opc$loadso)].w4;
                  end;
                word.r21 := rshft(reg, 1) & 31;
              end;
            11:
              word.f18 := reg & 63;
            12:
              word.f24 := reg & 63;
            13:
              begin
                word.f24 := reg & 62;
                word.bit0 := odd(reg);
              end;
            14:
              begin
                word.f6 := reg & 63;
                word.f0 := reg & 63;
              end;
            15:
              begin
                if (opc = ord(opc$divi)) and not odd(reg) then
                  bug_check('ASM_$PROCESS_ROUTINE -- even divisor in DIVI%$');
                word.f0 := reg & 63;
              end;
            16:
              word.f6 := reg & 63;
            17:
              word.f12 := reg & 63;
            otherwise
              bug_check('ASM_$PROCESS_ROUTINE -- opcode.operands[ i ].location = %lh%$', field);
          end;
        end;

        { The opcode's own fields. }
        if instruction_assembly[opc].squash then
          word.squash := rshft(57, 2 * cell_head_ptr_t(i)^.modify) & 3
        else if odd(instruction_attributes[opc].b14_7_1) then
          word.b13_9 := (i^.h.width - 1) & 31
        else if (instruction_attributes[opc].class in load_store_classes)
                and (instruction_assembly[opc].w4 <> template.all) then begin
          word.am := cell_head_ptr_t(i)^.modify;
          word.lsq := cell_head_ptr_t(i)^.lsq;
        end
        else if instruction_attributes[opc].class = class$load_pair then begin
          word.lpoff := cell_head_ptr_t(i)^.offset & 63;
          word.b14 := odd(rshft(cell_head_ptr_t(i)^.offset, 6));
          word.b15 := cell_head_ptr_t(i)^.offset < 0;
        end
        else if instruction_attributes[opc].class = class$synch then
          word.r16 := r^.p116^.b2 & 31;
        if i^.h.fp_ccs then
          word.b24 := true;
        if i^.h.sets_cc then
          if ((instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[1].form = 3)
              or (instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[1].form = 10))
             and (instruction_assembly[opc].w4 = template.all) then
            word.b26 := true
          else
            word.b14 := true;
        if i^.h.b2_7 then
          word.b31 := true
        else if i^.h.b2_6 then
          if not (instruction_attributes[i^.opc].class in two_word_classes) then
            word.b31 := true;
        i^.l24 := word.all ! template.all;
      end;
      if at_backend_switches.sw9 then begin
        n1 := ord(instruction_assembly[i^.opc].no_hex) & 1;
        n2 := ord(i^.h.grouped) & 1;
        n3 := ord(i^.h.b2_6) & 1;
        vfmt_$write('pass2   %3ZWD:%3ZWD  LC: %6zlh  stmt=%3jwd  NOP=%1ld  continued=%1ld  5op=%1ld  %8zlh  %8M8ZA%.',
                    bb^.num, i^.num, i^.l28, i^.l32, n3, n2, n1, i^.l24,
                    instruction_mnemonic[i^.opc]);
      end;
      i := i^.next;
    end;
    bb := bb^.next;
  end;
end;

{ ASM_$BEGIN_COMPILATION - the heaps; each code section's committed
  literal pool (and with target_properties.p_be the second).

  0x221848, 0xA8 bytes: mrh_$initialize's flags and size pushed as one
  longword (docs/rev889-patterns.md 105). }

procedure asm_$begin_compilation;
var
  s: asm_sect_ptr_t;
  p: asm_pool_ptr_t;
begin
  if at_backend_switches.sw10 then
    vfmt_$write('%/   ---- DUMP OF LITERALS AS THEY ARE PROCESSED ---- %/%.');
  mrh_$initialize(entries_heap, 1, 24, 'asm literal entries heap%');
  mrh_$initialize(pools_heap, 1, 80, 'asm literal pools heap%');
  s := univ_ptr(il_10c);
  while s <> nil do begin
    p := mrh_$alloc_fixed(pools_heap);
    clear_literal_pool(p);
    s^.pool := p;
    if target_properties.p_be then begin
      p := mrh_$alloc_fixed(pools_heap);
      clear_literal_pool(p);
      s^.pool2 := p;
    end;
    s := s^.next;
  end;
end;

{ ASM_$END_COMPILATION - each code section's last literal pool after
  its code (the committed pool, or with p_be the second), then its case
  tables (TABLEB, TABLEW, TABLEL: entries of 1, 2, 4 bytes, aligned),
  each after the last cell; the section's size.

  0x22195C, 0xC4 bytes: the tables' opcodes tested 205, 206, 207. }

procedure asm_$end_compilation;
var
  s: asm_sect_ptr_t;
  p: asm_pool_ptr_t;
  loc, n: integer32;
  c, last: cell_ptr_t;
begin
  s := univ_ptr(il_10c);
  while s <> nil do begin
    loc := (s^.size + 7) & (-8);
    if s^.last_cell <> nil then begin
      if not target_properties.p_be then
        p := s^.pool
      else
        p := s^.pool2;
      loc := append_literal_pool__code_cell(s, p, loc);
    end;
    last := s^.last_cell;
    c := s^.tables;
    while c <> nil do begin
      n := c^.l12;
      case c^.h.opc of
        205:
          ;
        206:
          begin
            loc := (loc + 1) & (-2);
            n := n * 2;
          end;
        207:
          begin
            loc := (loc + 3) & (-4);
            n := n * 4;
          end;
        otherwise
          bug_check('ASM_$END_COMPILATION -- unexpected entry on psect table list%$');
      end;
      c^.l8 := loc;
      last^.next := c;
      loc := loc + n;
      last := c;
      c := c^.next;
    end;
    s^.size := loc;
    s := s^.next;
  end;
end;
