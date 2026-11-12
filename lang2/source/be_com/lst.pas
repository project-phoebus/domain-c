{ lst - the PRISM back end's assembler listing (cc.a88k only): the
  lines bin asks for as it emits a compilation (the sections, each
  routine's entry, each code cell, literal and case table), in one of
  two forms: Apollo's classic listing (mnemonic and operands, the
  registers an instruction uses in a column of their own) or, with the
  -PRASM option (cargs_$options.flags_286 element 16, the default), the
  PRISM assembler's algebraic form ("R3 = R1 + R2").  The line is built
  in the module's buffer and written to the listing stream with
  vfmt_$ws.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x24E620  add_char (internal)
    --------  0x24E63A  add_2_chars (internal)
    --------  0x24E676  add_2_digits (internal)
    --------  0x24E6CA  add_string (internal)
    --------  0x24E720  add_small_integer (internal)
    --------  0x24E776  add_integer (internal)
    --------  0x24E7D2  add_formatted_integer (internal)
    --------  0x24E908  add_offset (internal)
    --------  0x24E944  add_formatted_hex (internal)
    --------  0x24E992  add_hex (internal)
    --------  0x24E9FA  tab_to_column (internal)
    --------  0x24EA36  lst_$begin_compilation
    --------  0x24EAE4  lst_$end_compilation
    --------  0x24EAE6  lst_$new_line
    --------  0x24EB0A  lst_$define_data_section
    --------  0x24EB98  lst_$set_data_section
    --------  0x24EC88  lst_$program_section
    --------  0x24ED94  lst_$procedure_entry
    --------  0x24F370  lst_$add_register_name (internal)
    --------  0x24F4E0  lst_$display_operand (internal)
    --------  0x24F7F6  lst_$address_mode_a_operand (internal)
    --------  0x24F866  lst_$branch_destination (internal)
    --------  0x24F8FC  lst_$prtlit
    --------  0x24FE1C  lst_$prasm_operand_a (internal)
    --------  0x24FEAE  lst_$prasm_address_mode_suffix (internal)
    --------  0x24FFEC  lst_$prasm_address_mode (internal)
    --------  0x250158  lst_$prasm_add_bitfield
    --------  0x2501B2  lst_$prasm_add_condition_codes
    --------  0x2501F6  lst_$prasm_lhs
    --------  0x25023E  lst_$prasm_display_code_cell (internal)
    --------  0x250A0A  lst_$display_code_cell
    --------  0x251796  lst_$display_literal
    --------  0x251C92  lst_$display_table
    A5 0x48C1A4: the module's data (452 bytes): the squash suffixes
    (+0, initialized), the line (+0x10, a prtsub_$line_t), the scale
    letters (+0x114, initialized "1248"), the pending numbered label
    (+0x118), the eight columns (+0x11C..+0x138), lst_13c (+0x13C, the
    source lines' listing line numbers: at_backend, bin, dmp), lst_140
    (+0x140, the listing stream: sym), three flags (+0x142, +0x144,
    +0x146), the powers of ten (+0x148, initialized), the two
    routines' hexadecimal digits (+0x170, +0x180, initialized),
    register_letter (+0x190) and lsq_suffix (+0x1B8) from their .init
    files, a longword 2 no instruction reads (+0x1B0) and the table's
    location counter (+0x1C0).

  A code cell (backend.ins.pas's cell_t) carries its operands from +20,
  operand k at +8 + 12k: +3 bits 4..0 the kind, +0 a register's number,
  +2 bits 5..4 its scale, +4 the symbol (or the label's code cell), +8
  the immediate value.  The opcode's tables are the sections
  instruction_attributes (class +7, operand count +11 bits 2..0, the
  operands' forms at +4k) and instruction_assembly (instr_asm_t).

  Not known from the original: every local, parameter and module cell
  name; the record bin passes as lst_$procedure_entry's first parameter
  (pe_info_t) and the sections' records (lst_sect_t) are named by
  offset; the IL node kinds of the set the operands' symbols are tested
  against (not_symbol_kinds). }
module lst;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/cvfp.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_mnemonic.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_mnemonic_length.init';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/register_letter.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_suffix.init';

type
  { A section as lst_$define_data_section, lst_$set_data_section and
    lst_$program_section use it: name (+8) its IL node, its size the
    sum of +20 and +24. }
  lst_sect_ptr_t = ^lst_sect_t;
  lst_sect_t = record
    l0: integer32;                      { +0 }
    l4: integer32;                      { +4 }
    name: univ_ptr;                     { +8 }
    l12: integer32;                     { +12 }
    l16: integer32;                     { +16 }
    size: integer32;                    { +20 }
    size_2: integer32;                  { +24 }
  end;

  { What bin passes as lst_$procedure_entry's first parameter (and
    bin_$unwind_bits's): the routine's size (+44), the saved registers'
    masks (+160 the integer registers, bit k register k; +168 and +164
    the floating registers 0..31 and 32..63, two bits each: 1 the even
    single, 2 the odd one, 3 the double), the stack and save words
    (+208..+224) and +226 bit 6 (SAVE). }
  pe_info_ptr_t = ^pe_info_t;
  pe_info_t = record
    unused_0: array [0..43] of char;    { +0 }
    size: integer32;                    { +44 }
    unused_48: array [48..159] of char; { +48 }
    ip_saved: integer32;                { +160 }
    fp_saved_hi: integer32;             { +164 }
    fp_saved: integer32;                { +168 }
    unused_172: array [172..207] of char;    { +172 }
    stack: integer;                     { +208 }
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
      save: boolean;                    { .6 }
      b5_0: 0..63;
      end;
  end;

  { The routine's IL node as lst_$procedure_entry reads it: kind 167 a
    nested one whose +148 is the routine it is in; the frame's size
    +176 less +112; +294 (signed) and +376 bit 4 decide the EXPORT. }
  pe_node_ptr_t = ^pe_node_t;
  pe_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..111] of char;   { +4 }
    l112: integer32;                    { +112 }
    unused_116: array [116..147] of char;    { +116 }
    parent: pe_node_ptr_t;              { +148 }
    unused_152: array [152..175] of char;    { +152 }
    l176: integer32;                    { +176 }
    unused_180: array [180..293] of char;    { +180 }
    f294: packed record                 { +294 }
      level: -128..127;
      b295: 0..255;
      end;
    unused_296: array [296..375] of char;    { +296 }
    f376: packed record                 { +376 }
      b7, b6, b5: boolean;
      exported: boolean;                { .4 }
      b3_0: 0..15;
      end;
  end;

  { A code cell's source position (+16): with the cell's +0 bit 1 a
    pointer to a record whose +4 is the line, else the line and a word
    that, nonzero, marks the line with `*'. }
  pos_ptr_t = ^pos_t;
  pos_t = record
    l0: integer32;                      { +0 }
    line: integer;                      { +4 }
  end;
  cell_pos_ptr_t = ^cell_pos_t;
  cell_pos_t = record
    case integer of
      1: (p: pos_ptr_t);
      2: (line: 0..65535;
          marked: integer);
  end;

  { lst_13c: by source line, its line in the listing. }
  line_map_ptr_t = ^line_map_t;
  line_map_t = array [0..65535] of integer;

  { A case table's code cell: its entries from +20. }
  table_cell_ptr_t = ^table_cell_t;
  table_cell_t = record
    h: cell_head_t;                     { +0 }
    next: cell_ptr_t;                   { +4 }
    loc: integer32;                     { +8 }
    count: integer32;                   { +12 }
    l16: integer32;                     { +16 }
    entries: array [0..65535] of integer32;  { +20 }
  end;

  { A label reference's code cell (operand$label_reference's link):
    opcode 200 (label$) a numbered label, +12 its number, else +12 the
    label's symbol. }
  label_cell_ptr_t = ^label_cell_t;
  label_cell_t = record
    h: cell_head_t;                     { +0 }
    next: cell_ptr_t;                   { +4 }
    l8: integer32;                      { +8 }
    target: integer32;                  { +12 }
  end;

  { A literal pool operand's link (operand$displacement_literal_pool):
    the literal (+4) and its address (+20). }
  pool_ref_ptr_t = ^pool_ref_t;
  pool_ref_t = record
    l0: integer32;                      { +0 }
    lit: lit_ptr_t;                     { +4 }
    l8: integer32;                      { +8 }
    l12: integer32;                     { +12 }
    l16: integer32;                     { +16 }
    addr: integer32;                    { +20 }
  end;

  { An operand's symbol, an IL node (its kind at +2; kind 109's +4). }
  sym_node_ptr_t = ^sym_node_t;
  sym_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    l4: integer32;                      { +4 }
  end;

  { The front end's record il_184 points to: +377 bits 6..4, 3 for a
    language whose strings are written with `"' and counted with their
    terminator. }
  lang_node_ptr_t = ^lang_node_t;
  lang_node_t = record
    unused_0: array [0..375] of char;   { +0 }
    f377: packed record                 { +376 }
      b376: 0..255;
      b7: boolean;                      { +377 }
      language: 0..7;                   { .6..4 }
      b3_0: 0..15;
      end;
  end;

  chars16_t = packed array [1..16] of char;

  { What a namelist descriptor literal's p0 points to: the longword at
    +18 lst_$display_literal shows. }
  nl_desc_ptr_t = ^nl_desc_t;
  nl_desc_t = record
    unused_0: array [0..17] of char;    { +0 }
    l18: integer32;                     { +18 }
  end;

define
  lst_13c,                              { +0x13C }
  lst_140;                              { +0x140 }

var
  squash_suffix: array [0..3] of packed array [1..4] of char := [
    '.SN ', '.ST ', '.SF ', '.SA '];    { +0x0 }
  line: prtsub_$line_t;                 { +0x10 }
  scale_char: array [0..3] of char := [
    '1', '2', '4', '8'];                { +0x114 }
  pending_label: integer32;             { +0x118: a label$ cell's number,
                                          printed before the next line }
  col_code_comment: integer32;          { +0x11C }
  col_code_operand: integer32;          { +0x120 }
  col_code_opcode: integer32;           { +0x124 }
  col_code_label: integer32;            { +0x128 }
  col_comment: integer32;               { +0x12C }
  col_operand: integer32;               { +0x130 }
  col_opcode: integer32;                { +0x134 }
  col_label: integer32;                 { +0x138 }
  continued: boolean;                   { +0x142: the next cell continues
                                          this line's instruction (no
                                          location columns) }
  implied_disp: boolean;                { +0x144: a load's or store's
                                          displacement is implied (0, or
                                          the access size when it
                                          modifies its base) }
  negative_disp: boolean;               { +0x146: the displacement is
                                          negative (`--' for `++') }
  power_of_ten: array [1..9] of integer32 := [
    1, 10, 100, 1000, 10000, 100000, 1000000, 10000000,
    100000000];                         { +0x148 }
  formatted_hex_digits: array [0..15] of char := [
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];    { +0x170 }
  hex_digits: array [0..15] of char := [
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];    { +0x180 }
  unused_1b0: integer32 := 2;           { +0x1B0: not read }
  table_loc: integer32;                 { +0x1C0 }

{ add_char - c to the end of the line, unless it is full.

  0x24E620, 0x1A bytes, internal, no frame: c at (4,SP); `cmpi.w
  #256; bcc' on the length. }

procedure add_char(
    c: char); options(val_param); internal;
begin
  if line.length < 256 then begin
    line.length := line.length + 1;
    line.body[line.length] := c;
  end;
end;

{ add_2_chars - c1 and c2, as many as fit.

  0x24E63A, 0x3C bytes: the length taken into a longword (`clr.l;
  move.w; addq.l #1'), c1 stored, then c2 if the new length is below
  256; the length stored once. }

procedure add_2_chars(
    c1: char;
    c2: char); options(val_param); internal;
var
  len: integer32;
begin
  if line.length < 256 then begin
    len := line.length + 1;
    line.body[len] := c1;
    if len < 256 then begin
      len := len + 1;
      line.body[len] := c2;
    end;
    line.length := len;
  end;
end;

{ add_2_digits - n (0..99) as two digits.

  0x24E676, 0x54 bytes: n div 10 (M$DIS$LLW); add_2_chars of '0' plus
  it and '0' plus n less ten times it. }

procedure add_2_digits(
    n: integer32); options(val_param); internal;
var
  q: integer32;
begin
  q := n div 10;
  add_2_chars(chr(ord('0') + q), chr(ord('0') + n - q * 10));
end;

{ add_string - n characters of s, as many as fit.

  0x24E6CA, 0x56 bytes: nothing when the line is full; n cut to the
  room left (`256 - (n + length)', added when negative); then a loop
  that tests its count after the copy (`bgt' at the end), so a count
  of 0 copies one character. }

procedure add_string(
    in s: univ prtsub_$chars_t;
    n: integer32); options(val_param); internal;
var
  len: integer32;
  i: integer32;
  room: integer32;
begin
  len := line.length;
  if len < 256 then begin
    room := 256 - (n + len);
    if room < 0 then
      n := n + room;
    i := 0;
    repeat
      len := len + 1;
      i := i + 1;
      n := n - 1;
      line.body[len] := s[i];
    until n <= 0;
    line.length := len;
  end;
end;

{ add_small_integer - n (0..99) in decimal, one digit when below 10.

  0x24E720, 0x56 bytes: n div 10, its digit when nonzero; then the
  units (word arithmetic, `addi.w #48'). }

procedure add_small_integer(
    n: integer32); options(val_param); internal;
var
  q: integer32;
begin
  q := n div 10;
  if q <> 0 then
    add_char(chr(ord('0') + q));
  add_char(chr(ord('0') + n - q * 10));
end;

{ add_integer - n in decimal, `-' first when negative.

  0x24E776, 0x5C bytes: recursive on n div 10 when nonzero, then the
  last digit. }

procedure add_integer(
    n: integer32); options(val_param); internal;
var
  q: integer32;
begin
  if n < 0 then begin
    add_char('-');
    n := -n;
  end;
  q := n div 10;
  n := n - q * 10;
  if q <> 0 then
    add_integer(q);
  add_char(chr(ord('0') + n));
end;

{ add_formatted_integer - n in decimal, right-justified in width
  columns: blanks in front (zeros with zero_fill), at least one digit.

  0x24E7D2, 0x136 bytes: `-' and the negation; -2147483648 (still
  negative) as `2' and the rest less 2000000000; a value from 10^9 as
  its first digit (`1' or `2') before the nine others.  Each of the
  nine positions (the powers of ten, +0x148 indexed from the top) keeps
  its character in D2: masked to 0x30 (`0' once a digit was written,
  else ` '), `0' at the width's position when zero_fill or the last,
  the digit or-ed in by subtracting 8, 4, 2 and 1 times the power; the
  character is written when it is not a blank or the position is
  within the width and not zero-filled.  A `0' when nothing was
  written. }

procedure add_formatted_integer(
    n: integer32;
    width: integer32;
    zero_fill: boolean); options(val_param); internal;
var
  c: char;
  i: integer32;
  len: integer32;
  blank: boolean;
  p: integer32;
begin
  c := ' ';
  if n < 0 then begin
    add_char('-');
    n := -n;
    if n < 0 then begin
      add_char('2');
      n := n - 2000000000;
      c := '0';
    end;
  end;
  if n >= 1000000000 then begin
    n := n - 1000000000;
    if n < 1000000000 then
      add_char('1')
    else begin
      n := n - 1000000000;
      add_char('2');
    end;
    c := '0';
  end;
  len := line.length;
  blank := not zero_fill;
  for i := 9 downto 1 do begin
    c := chr(ord(c) & 16#30);
    p := power_of_ten[i];
    if i = width then
      if zero_fill or (i = 1) then
        c := '0';
    if n >= p then begin
      if n - p * 8 >= 0 then begin
        n := n - p * 8;
        c := chr(ord(c) ! 16#38);
      end;
      if n - p * 4 >= 0 then begin
        n := n - p * 4;
        c := chr(ord(c) ! 16#34);
      end;
      if n - p * 2 >= 0 then begin
        n := n - p * 2;
        c := chr(ord(c) ! 16#32);
      end;
      if n - p >= 0 then begin
        n := n - p;
        c := chr(ord(c) ! 16#31);
      end;
    end;
    if ((i <= width) and blank) or (c <> ' ') then
      if len < 256 then begin
        len := len + 1;
        line.body[len] := c;
      end;
  end;
  if line.length = len then
    if len < 256 then begin
      len := len + 1;
      line.body[len] := '0';
    end;
  line.length := len;
end;

{ add_offset - n as a signed offset: nothing for 0, else `+' or `-'
  and its magnitude.

  0x24E908, 0x3C bytes. }

procedure add_offset(
    n: integer32); options(val_param); internal;
begin
  if n <> 0 then
    if n > 0 then begin
      add_char('+');
      add_integer(n);
    end
    else begin
      add_char('-');
      add_integer(-n);
    end;
end;

{ add_formatted_hex - the last digits hexadecimal digits of n.

  0x24E944, 0x4E bytes: the shift from (digits - 1) * 4 down by 4
  while not negative (`bpl' at the end); the digits from the table at
  +0x170. }

procedure add_formatted_hex(
    n: integer32;
    digits: integer32); options(val_param); internal;
var
  len: integer32;
  shift: integer32;
begin
  len := line.length;
  shift := (digits - 1) * 4;
  repeat
    if len < 256 then begin
      len := len + 1;
      line.body[len] := formatted_hex_digits[rshft(n, shift) & 15];
    end;
    shift := shift - 4;
  until shift < 0;
  line.length := len;
end;

{ add_hex - n in hexadecimal without leading zeros, as h'... when above
  9.

  0x24E992, 0x68 bytes: "h'" stored without a check of the room
  (`move.b #104,(0x12,A5,D0.l)'); the nibbles from bit 28 down, or-ed
  into D2 to know when the first nonzero one came, the last always
  written; the digits from the table at +0x180. }

procedure add_hex(
    n: integer32); options(val_param); internal;
var
  started: integer32;
  shift: integer32;
  len: integer32;
  d: integer32;
  c: char;
begin
  started := 0;
  shift := 28;
  len := line.length;
  if n > 9 then begin
    line.body[len + 1] := 'h';
    line.body[len + 2] := '''';
    len := len + 2;
  end;
  repeat
    d := rshft(n, shift) & 15;
    c := hex_digits[d];
    started := started ! d;
    if (started <> 0) or (shift = 0) then
      if len < 256 then begin
        len := len + 1;
        line.body[len] := c;
      end;
    shift := shift - 4;
  until shift < 0;
  line.length := len;
end;

{ tab_to_column - blanks up to column col (the line's length becomes
  col), when it is shorter and col is below 256.

  0x24E9FA, 0x3C bytes: the length set first, the blanks stored from
  col down. }

procedure tab_to_column(
    col: integer32); options(val_param); internal;
var
  d: integer32;
begin
  d := col - line.length;
  if d > 0 then
    if col < 256 then begin
      line.length := col;
      repeat
        line.body[col] := ' ';
        col := col - 1;
        d := d - 1;
      until d <= 0;
    end;
end;

{ lst_$begin_compilation - the listing stream and the columns of the
  chosen form.

  0x24EA36, 0xAE bytes: +0x142 false, +0x118 0; lst_140 :=
  get_listing_stream_id; error_listing_0c set around
  advance_listing_to_line(32767) (the source listed to its end); the
  columns by -PRASM (`btst #3,0x4437F6'): classic 30, 45, 57, 78, 39,
  45, 57, 78, PRASM 26, 31, 45, 69, 26, 71, 82, 102 (+0x138 down to
  +0x11C). }

procedure lst_$begin_compilation;
begin
  continued := false;
  pending_label := 0;
  lst_140 := get_listing_stream_id;
  error_listing_0c := true;
  advance_listing_to_line(32767);
  error_listing_0c := false;
  if not (16 in cargs_$options.flags_286) then begin
    col_label := 30;
    col_opcode := 45;
    col_operand := 57;
    col_comment := 78;
    col_code_label := 39;
    col_code_opcode := 45;
    col_code_operand := 57;
    col_code_comment := 78;
  end
  else begin
    col_label := 26;
    col_opcode := 31;
    col_operand := 45;
    col_comment := 69;
    col_code_label := 26;
    col_code_opcode := 71;
    col_code_operand := 82;
    col_code_comment := 102;
  end;
end;

{ lst_$end_compilation - nothing.  0x24EAE4, 2 bytes (no A5). }

procedure lst_$end_compilation;
begin
end;

{ lst_$new_line - an empty line.  0x24EAE6, 0x22 bytes:
  vfmt_$ws(lst_140, '%.'). }

procedure lst_$new_line;
begin
  vfmt_$ws(lst_140, '%.');
end;

{ lst_$define_data_section - "name DFSECT".

  0x24EB0A, 0x84 bytes: the name (prtobj of +8) at the label column,
  the opcode column less one, a blank, "DFSECT"; vfmt_$ws(lst_140,
  '%a%.', line, length) (the length copied to a longword in the
  frame). }

procedure lst_$define_data_section(
    sect: univ_ptr);
var
  n: integer32;
  s: lst_sect_ptr_t;
begin
  s := sect;
  line.length := 0;
  tab_to_column(col_label);
  prtobj(line, s^.name);
  tab_to_column(col_opcode - 1);
  add_char(' ');
  add_string('DFSECT', 6);
  n := line.length;
  vfmt_$ws(lst_140, '%a%.', line.body, n);
end;

{ lst_$set_data_section - "SECT name ; size = h'... = n" after an empty
  line.

  0x24EB98, 0xD4 bytes: the comment at the comment column or one past
  the line; the size +20 plus +24 in hexadecimal and decimal;
  vfmt_$ws(lst_140, '%/%/%a%.', ...). }

procedure lst_$set_data_section(
    sect: univ_ptr);
var
  n: integer32;
  s: lst_sect_ptr_t;
  col: integer32;
begin
  s := sect;
  line.length := 0;
  tab_to_column(col_opcode);
  add_string('SECT', 4);
  tab_to_column(col_operand);
  prtobj(line, s^.name);
  col := line.length + 1;
  if col < col_comment then
    col := col_comment;
  tab_to_column(col);
  add_string('; size = ', 9);
  add_hex(s^.size + s^.size_2);
  add_string(' = ', 3);
  add_formatted_integer(s^.size + s^.size_2, 1, false);
  n := line.length;
  vfmt_$ws(lst_140, '%/%/%a%.', line.body, n);
end;

{ lst_$program_section - "name DFSECT readonly,instruction" and "SECT
  name".

  0x24EC88, 0xF8 bytes: as lst_$define_data_section with the operand,
  written with '%/%/%a%.'; then as lst_$set_data_section without the
  size, written with '%a%.'. }

procedure lst_$program_section(
    sect: univ_ptr);
var
  n: integer32;
  s: lst_sect_ptr_t;
begin
  s := sect;
  line.length := 0;
  tab_to_column(col_label);
  prtobj(line, s^.name);
  tab_to_column(col_opcode - 1);
  add_char(' ');
  add_string('DFSECT', 6);
  tab_to_column(col_operand);
  add_string('readonly,instruction', 20);
  n := line.length;
  vfmt_$ws(lst_140, '%/%/%a%.', line.body, n);
  line.length := 0;
  tab_to_column(col_opcode);
  add_string('SECT', 4);
  tab_to_column(col_operand);
  prtobj(line, s^.name);
  n := line.length;
  vfmt_$ws(lst_140, '%a%.', line.body, n);
end;

{ lst_$procedure_entry - a routine's entry lines.

  0x24ED94, 0x50A bytes: one empty line before a nested routine (kind
  167) and two before the others; bin_$unwind_bits(info, frame size,
  three flags), of which the bytes at -22 (stack) and -18 (ecb) are
  read.  -PRASM (`btst #3,0x4437F6'): "EXPORT name" when the node's
  +294 is not positive or its +376 bit 4 is set; "name PROCEDURE
  RETURN=(.n,SAVE)" (",NOSAVE" without +226 bit 6), the stack clause
  when the stack flag is set (", STACK=( .n", ", ECB" or ", *+h'xx",
  the two registers when not negative, " )"); the save clause when
  anything is saved (", " and, when registers are, " ..." ending the
  line; "SAVE=( *+h'xx, [.22,h'xx]", ",.n" for each integer register
  of +160 (bit 0 first, 32 of them), ",.FSn"/",.FSn+1"/",.FDn" for the
  pairs of bits of +168 then +164 (a jump table on the pair), ")");
  then "* routine size = h'xxxxx".  Classic: "ENTRY name".  Then the
  frame's size (+176 less +112 of the routine, the parent of a nested
  one) as a comment when positive; '%a%/%.'.  The name's failure to
  print is a bug check ("can't print block name"), except on the
  PROCEDURE line. }

procedure lst_$procedure_entry(
    info: univ_ptr;
    p2: univ_ptr;
    node: univ_ptr);
var
  frame_size: integer32;
  mask: integer32;
  n: integer32;
  pe: pe_info_ptr_t;
  rtn: pe_node_ptr_t;
  ecb: boolean;
  big_reg: boolean;
  stack: boolean;
  i: integer32;
  k: integer32;
begin
  pe := info;
  rtn := node;
  if rtn^.kind = 167 then
    vfmt_$ws(lst_140, '%/%$')
  else
    vfmt_$ws(lst_140, '%/%/%$');
  bin_$unwind_bits(pe, frame_size, stack, big_reg, ecb);
  if 16 in cargs_$options.flags_286 then begin
    line.length := 0;
    if (rtn^.f294.level <= 0) or rtn^.f376.exported then begin
      line.length := 0;
      tab_to_column(col_opcode);
      add_string('EXPORT', 6);
      tab_to_column(col_operand);
      if not sym_$append_symbol_print_name(addr(line), rtn) then
        bug_check('LST_$DISPLAY_ENTRY -- can''t print block name%$');
      n := line.length;
      vfmt_$ws(lst_140, '%a%/%.', line.body, n);
    end;
    line.length := 0;
    tab_to_column(col_label);
    discard(sym_$append_symbol_print_name(addr(line), rtn));
    tab_to_column(col_opcode - 1);
    add_string(' PROCEDURE ', 11);
    tab_to_column(col_operand);
    add_string('RETURN=(.', 9);
    add_formatted_integer(frame_size, 1, false);
    if pe^.f226.save then
      add_string(',SAVE', 5)
    else
      add_string(',NOSAVE', 7);
    add_char(')');
    if stack then begin
      add_string(', STACK=( .', 11);
      add_formatted_integer(pe^.stack, 1, false);
      if ecb then
        add_string(', ECB', 5)
      else begin
        add_string(', *+h''', 6);
        add_formatted_hex(pe^.stack_disp, 2);
      end;
      if pe^.reg_1 >= 0 then begin
        add_string(', .', 3);
        add_formatted_integer(pe^.reg_1, 1, false);
      end;
      if pe^.reg_2 >= 0 then begin
        add_string(', .', 3);
        add_formatted_integer(pe^.reg_2, 1, false);
      end;
      add_2_chars(' ', ')');
    end;
    if pe^.f226.save or (pe^.reg_2 >= 0) or (pe^.reg_1 >= 0) or
       (pe^.fp_saved <> 0) or (pe^.ip_saved <> 0) or
       (pe^.fp_saved_hi <> 0) then begin
      add_2_chars(',', ' ');
      if (pe^.fp_saved <> 0) or (pe^.ip_saved <> 0) or
         (pe^.fp_saved_hi <> 0) then begin
        add_string(' ...', 4);
        n := line.length;
        vfmt_$ws(lst_140, '%a%.', line.body, n);
        line.length := 0;
        tab_to_column(col_operand);
      end;
      add_string('SAVE=( *+h''', 11);
      add_formatted_hex(pe^.save_disp, 2);
      add_string(', [.22,h''', 9);
      add_formatted_hex(pe^.save_reg_disp, 2);
      add_char(']');
      mask := pe^.ip_saved;
      for i := 0 to 31 do begin
        if odd(mask) then begin
          add_2_chars(',', '.');
          add_formatted_integer(i, 1, false);
        end;
        mask := rshft(mask, 1);
      end;
      i := 0;
      mask := pe^.fp_saved;
      while i < 64 do begin
        case mask & 3 of
          1: begin
            add_string(',.FS', 4);
            add_formatted_integer(i, 1, false);
            end;
          2: begin
            add_string(',.FS', 4);
            add_formatted_integer(i + 1, 1, false);
            end;
          3: begin
            add_string(',.FD', 4);
            add_formatted_integer(i, 1, false);
            end;
          otherwise
        end;
        i := i + 2;
        if i = 32 then
          mask := pe^.fp_saved_hi
        else
          mask := rshft(mask, 2);
      end;
      add_char(')');
    end;
    n := line.length;
    vfmt_$ws(lst_140, '%a%.', line.body, n);
    line.length := 0;
    tab_to_column(col_label);
    add_string('* routine size = h''', 19);
    add_formatted_hex(pe^.size, 5);
  end
  else begin
    line.length := 0;
    tab_to_column(col_opcode);
    add_string('ENTRY', 5);
    tab_to_column(col_operand);
    if not sym_$append_symbol_print_name(addr(line), rtn) then
      bug_check('LST_$DISPLAY_ENTRY -- can''t print block name%$');
  end;
  if rtn^.kind = 167 then
    rtn := rtn^.parent;
  i := rtn^.l176 - rtn^.l112;
  if i > 0 then begin
    k := line.length + 1;
    if k < col_comment then
      k := col_comment;
    tab_to_column(k);
    add_string('; frame size = ', 15);
    add_hex(i);
    add_string(' = ', 3);
    add_formatted_integer(i, 1, false);
  end;
  n := line.length;
  vfmt_$ws(lst_140, '%a%/%.', line.body, n);
end;

{ lst_$add_register_name - operand k's register.

  0x24F370, 0x166 bytes, internal.  Classic: register_letter by the
  kind, the number (add_small_integer), and for an integer register
  (kinds 1 and 12) its scale as `*' and the letter of +0x114.
  -PRASM: a jump table on the kind less 1: the integer registers ".n"
  with the scale, the singles ".FSn" and ".H" when the opcode's half
  mask (instruction_assembly +9 bits 3..1) has bit k - 1, the doubles
  ".FDn"; other kinds nothing. }

procedure lst_$add_register_name(
    cell: cell_ptr_t;
    k: integer32); options(val_param); internal;
var
  scale: integer32;
begin
  if not (16 in cargs_$options.flags_286) then begin
    add_char(register_letter[cell^.opnds[k].h.kind]);
    add_small_integer(cell^.opnds[k].h.num);
    if (cell^.opnds[k].h.kind <> operand$ip_reg) and
       (cell^.opnds[k].h.kind <> operand$ip_reg_like) then
      return;
    scale := cell^.opnds[k].h.count;
  end
  else
    case cell^.opnds[k].h.kind of
      operand$ip_reg, operand$ip_reg_like: begin
        add_char('.');
        add_small_integer(cell^.opnds[k].h.num);
        scale := cell^.opnds[k].h.count;
        end;
      operand$fp_reg, operand$fp_reg_like: begin
        add_string('.FS', 3);
        add_small_integer(cell^.opnds[k].h.num);
        if (instruction_assembly[cell^.h.opc].half &
            lshft(1, k - 1)) <> 0 then
          add_2_chars('.', 'H');
        return;
        end;
      operand$fp_reg_pair, operand$fp_reg_pair_like: begin
        add_string('.FD', 3);
        add_small_integer(cell^.opnds[k].h.num);
        return;
        end;
      otherwise
        return;
    end;
  if scale <> 0 then begin
    add_char('*');
    add_char(scale_char[scale]);
  end;
end;

{ lst_$display_operand - operand k by its kind.

  0x24F4E0, 0x234 bytes, internal: a jump table on the kind less 1
  (28 entries, the rest a bug check "unable to display operand").  A
  register (kinds 1..3, 12..14): its symbol's name with the scale when
  the operand's link is a symbol other than lir_main_ac0's entry for
  its number (0x48BE6C); "PC" (".PC" in -PRASM) for register 30 of
  kind ip_reg_like; else the register's name.  label_reference: a
  numbered label (its cell's opcode 200) as "n$", else the label's
  symbol.  immediate: format 0 decimal (negated in -PRASM for an
  operand of form of$ip_compare_a_operand), 2 hexadecimal, else a bug
  check.  displacement_routine: the symbol.  displacement_arg_block and
  _stack_frame: the value.  displacement_literal_pool: "h'" and the
  value (target_properties.p_be) or the cell's location plus the value
  in five digits and "-*".  exception_information: the location plus
  four times the value. }

procedure lst_$display_operand(
    cell: cell_ptr_t;
    k: integer32;
    format: integer); options(val_param); internal;
var
  sym: univ_ptr;
  lab: label_cell_ptr_t;
  attr: instr_attr_view_ptr_t;
begin
  case cell^.opnds[k].h.kind of
    operand$ip_reg, operand$fp_reg, operand$fp_reg_pair,
    operand$ip_reg_like, operand$fp_reg_like,
    operand$fp_reg_pair_like: begin
      sym := cell^.opnds[k].link;
      if (sym <> nil) and (sym = lir_main_ac0[cell^.opnds[k].h.num]) then
        lst_$add_register_name(cell, k)
      else if sym_$append_symbol_print_name(addr(line), sym) then begin
        if cell^.opnds[k].h.count <> 0 then begin
          add_char('*');
          add_char(scale_char[cell^.opnds[k].h.count]);
        end;
      end
      else if (cell^.opnds[k].h.kind = operand$ip_reg_like) and
              (cell^.opnds[k].h.num = 30) then begin
        if 16 in cargs_$options.flags_286 then
          add_char('.');
        add_2_chars('P', 'C');
      end
      else
        lst_$add_register_name(cell, k);
      end;
    operand$label_reference: begin
      lab := univ_ptr(cell^.opnds[k].link);
      if lab^.h.opc = 200 then begin
        add_integer(lab^.target);
        add_char('$');
      end
      else if not sym_$append_symbol_print_name(addr(line), univ_ptr(lab^.target)) then
        bug_check('LST_$DISPLAY_OPERAND -- unable to display label operand%$');
      end;
    operand$immediate:
      if format = 0 then begin
        attr := addr(instruction_attributes[cell^.h.opc]);
        if (16 in cargs_$options.flags_286) and
           (attr^.opnds[k].form = ord(of$ip_compare_a_operand)) then
          add_integer(-cell^.opnds[k].value)
        else
          add_integer(cell^.opnds[k].value);
      end
      else if format = 2 then
        add_hex(cell^.opnds[k].value)
      else
        bug_check('LST_$DISPLAY_OPERAND -- unable to display immediate value%$');
    operand$displacement_routine:
      if not sym_$append_symbol_print_name(addr(line), cell^.opnds[k].link) then
        bug_check('LST_$DISPLAY_OPERAND -- unable to display routine name%$');
    operand$displacement_arg_block, operand$displacement_stack_frame:
      add_integer(cell^.opnds[k].value);
    operand$displacement_literal_pool: begin
      add_2_chars('h', '''');
      if target_properties.p_be then
        add_integer(cell^.opnds[k].value)
      else begin
        add_formatted_hex(cell^.l8 + cell^.opnds[k].value, 5);
        add_2_chars('-', '*');
      end;
      end;
    operand$exception_information:
      add_formatted_hex(cell^.opnds[k].value * 4 + cell^.l8, 5);
    otherwise
      bug_check('LST_$DISPLAY_OPERAND -- unable to display operand%$');
  end;
end;

{ lst_$address_mode_a_operand - a memory operand's displacement in the
  classic form: an immediate as its magnitude when it modifies the base
  (the sign is the `++'/`--'), else as it is; other kinds by
  lst_$display_operand.

  0x24F7F6, 0x70 bytes, internal. }

procedure lst_$address_mode_a_operand(
    cell: cell_ptr_t;
    k: integer32); options(val_param); internal;
begin
  if cell^.opnds[k].h.kind <> operand$immediate then
    lst_$display_operand(cell, k, 0)
  else if cell^.opnds[k].value > 0 then
    add_integer(cell^.opnds[k].value)
  else if cell_head_ptr_t(cell)^.modify <> 0 then
    add_integer(-cell^.opnds[k].value)
  else
    add_integer(cell^.opnds[k].value);
end;

{ lst_$branch_destination - a branch's target: "[register]" for an
  integer register, else the operand in the format of
  instruction_assembly's word for it (bits 2..1).

  0x24F866, 0x96 bytes, internal: k a word. }

procedure lst_$branch_destination(
    cell: cell_ptr_t;
    k: integer); options(val_param); internal;
begin
  if cell^.opnds[k].h.kind = operand$ip_reg then begin
    add_char('[');
    lst_$add_register_name(cell, k);
    add_char(']');
  end
  else
    lst_$display_operand(cell, k,
      rshft(instruction_assembly[cell^.h.opc].opnd[k] & 6, 1));
end;

{ lst_$prtlit - a literal to the end of s (dmp's line or this unit's).

  0x24F8FC, 0x490 bytes: a jump table on the kind (+4, 22 entries; the
  rest "????????"): the integers prtint(s, value, 10, false) and their
  type ("(short)", "(uns)", ...; plain integers none); the booleans
  ".TRUE."/".FALSE." and their size; a char quoted, `?' for one
  outside ' '..'~'; a single (held as a double) and a double by
  lib_$cv_dfp_out (14 characters, 7 or 16 digits); the complex kinds
  in parentheses (lib_$cv_sfp_out of +8 and +12, lib_$cv_dfp_out of +8
  and +16 with 23 characters, 14 written); a string quoted with `"'
  and its length less one when il_184's language (+377 bits 6..4) is
  3, else with `'''; a varying string; the fixed texts of the others. }

procedure lst_$prtlit(
    in out s: univ lst_line_t;
    lit: lit_ptr_t);
var
  buf: array [1..24] of char;
  c: integer32;
  quote: char;
  n: integer32;
  lang: lang_node_ptr_t;
  ls: ^prtsub_$line_t;
begin
  ls := addr(s);
  case lit^.kind of
    0:
      prtint(ls^, lit^.value, 10, false);
    4: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(uns)', 5);
      end;
    1: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(short)', 7);
      end;
    5: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(uns short)', 11);
      end;
    2: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(byte)', 6);
      end;
    6: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(uns byte)', 10);
      end;
    3: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(long)', 6);
      end;
    7: begin
      prtint(ls^, lit^.value, 10, false);
      prtcats(ls^, '(uns long)', 10);
      end;
    8: begin
      if lit^.value = 0 then
        prtcats(ls^, '.FALSE.', 7)
      else
        prtcats(ls^, '.TRUE.', 6);
      prtcats(ls^, '(word)', 6);
      end;
    9: begin
      if lit^.value = 0 then
        prtcats(ls^, '.FALSE.', 7)
      else
        prtcats(ls^, '.TRUE.', 6);
      prtcats(ls^, '(byte)', 6);
      end;
    10: begin
      if lit^.value = 0 then
        prtcats(ls^, '.FALSE.', 7)
      else
        prtcats(ls^, '.TRUE.', 6);
      prtcats(ls^, '(long)', 6);
      end;
    11: begin
      prtcatc(ls^, '''');
      c := lit^.value;
      if (c < 32) or (c > 126) then
        c := ord('?');
      prtcatc(ls^, chr(c));
      prtcatc(ls^, '''');
      end;
    12: begin
      lib_$cv_dfp_out(buf, lit^.d, 2, 14, 7, 4, 1, false);
      prtcats(ls^, buf, 14);
      end;
    13: begin
      lib_$cv_dfp_out(buf, lit^.d, 2, 23, 16, 4, 1, false);
      prtcats(ls^, buf, 23);
      end;
    14: begin
      prtcatc(ls^, '(');
      lib_$cv_sfp_out(buf, lit^.r, 2, 14, 7, 4, 1, false);
      prtcats(ls^, buf, 14);
      prtcatc(ls^, ',');
      lib_$cv_sfp_out(buf, lit^.r12, 2, 14, 7, 4, 1, false);
      prtcats(ls^, buf, 14);
      prtcatc(ls^, ')');
      end;
    15: begin
      prtcatc(ls^, '(');
      lib_$cv_dfp_out(buf, lit^.d, 2, 23, 16, 4, 1, false);
      prtcats(ls^, buf, 14);
      prtcatc(ls^, ',');
      lib_$cv_dfp_out(buf, lit^.d16, 2, 23, 16, 4, 1, false);
      prtcats(ls^, buf, 14);
      prtcatc(ls^, ')');
      end;
    19: begin
      lang := univ_ptr(il_184);
      if (lang <> nil) and (lang^.f377.language = 3) then begin
        quote := '"';
        n := lit^.len - 1;
      end
      else begin
        quote := '''';
        n := lit^.len;
      end;
      prtcatc(ls^, quote);
      prtcats(ls^, lit^.chars, n);
      prtcatc(ls^, quote);
      end;
    18: begin
      prtcats(ls^, 'varying( ''', 10);
      prtcats(ls^, lit^.chars14, lit^.w12);
      prtcats(ls^, ''' )', 3);
      end;
    20:
      prtcats(ls^, 'read-only data', 14);
    16:
      prtcats(ls^, 'namelist descriptor', 19);
    21:
      prtcats(ls^, 'def_const ', 10);
    otherwise
      prtcats(ls^, '??????? ', 8);
  end;
end;

{ lst_$prasm_operand_a - operand k in -PRASM form: a register's name;
  else, unless the displacement is implied, the value in hexadecimal,
  `#' first when hash: a negative value as its magnitude when the cell
  modifies its base, else with `-'.

  0x24FE1C, 0x92 bytes, internal: the register kinds as the mask
  0x2707E (`btst'). }

procedure lst_$prasm_operand_a(
    cell: cell_ptr_t;
    k: integer32;
    hash: boolean); options(val_param); internal;
begin
  if cell^.opnds[k].h.kind in
     [operand$ip_reg..operand$fp_reg_pair_physical,
      operand$ip_reg_like..operand$fp_reg_pair_like,
      operand$case_jump_base] then
    lst_$add_register_name(cell, k)
  else if not implied_disp then begin
    if hash then
      add_char('#');
    if cell^.opnds[k].value >= 0 then
      add_hex(cell^.opnds[k].value)
    else if cell_head_ptr_t(cell)^.modify <> 0 then
      add_hex(-cell^.opnds[k].value)
    else begin
      add_char('-');
      add_hex(-cell^.opnds[k].value);
    end;
  end;
end;

{ lst_$prasm_address_mode_suffix - a load's or store's size and
  qualifier: ".B", ".S", ".L", ".FS", ".FD", ".Q" (load_pair) by the
  opcode (a jump table on the opcode less 103; the others a bug check
  with the opcode), then ".LOCK", ".UNLOCK" or ".PHYS" by the qualifier
  (not for load_pair).

  0x24FEAE, 0x102 bytes, internal. }

procedure lst_$prasm_address_mode_suffix(
    cell: cell_ptr_t); options(val_param); internal;
var
  opc: integer;
  n: integer32;
begin
  add_char('.');
  opc := cell^.h.opc;
  case opc of
    103, 118: add_char('B');
    104, 119: add_char('S');
    105, 120: add_char('L');
    110: add_char('Q');
    106, 121: add_2_chars('F', 'S');
    109, 124: add_2_chars('F', 'D');
    otherwise begin
      n := opc;
      bug_check('LST_$PRASM_ADDRESS_MODE opcode = %8ZLH%.', n);
      end;
  end;
  if opc <> 110 then
    case cell_head_ptr_t(cell)^.lsq of
      2: add_string('.UNLOCK', 7);
      1: add_string('.LOCK', 5);
      3: add_string('.PHYS', 5);
      otherwise
    end;
end;

{ lst_$prasm_address_mode - "[base,displacement]" with `++'/`--' before
  (premodify) or after (postmodify) the base, the sign by the
  displacement's; the displacement left out when implied (load_pair's
  is the cell's +3, signed); then the suffix.

  0x24FFEC, 0x13C bytes, internal: by the opcode's class, the base is
  operand 1, 2 or 3 and the displacement operand 0, 1 or 2 (load_pair,
  load, store); another class is a bug check. }

procedure lst_$prasm_address_mode(
    cell: cell_ptr_t); options(val_param); internal;
var
  opc: integer;
  d: integer32;
  base: integer32;
  sign: char;
begin
  opc := cell^.h.opc;
  case instruction_attributes[opc].class of
    class$load_pair: begin
      base := 1;
      d := 0;
      end;
    class$load: begin
      base := 2;
      d := 1;
      end;
    class$store: begin
      base := 3;
      d := 2;
      end;
    otherwise
      bug_check('LST_$PRASM_ADDRESS_MODE: bad code_cell^.opcode%.');
  end;
  add_char('[');
  sign := '+';
  if (cell^.opnds[d].h.kind = operand$immediate) and
     (cell^.opnds[d].value < 0) then
    sign := '-';
  if cell_head_ptr_t(cell)^.modify = 2 then
    add_2_chars(sign, sign);
  lst_$add_register_name(cell, base);
  if cell_head_ptr_t(cell)^.modify = 1 then
    add_2_chars(sign, sign);
  if not implied_disp then begin
    add_char(',');
    if opc = 110 then
      add_hex(cell_head_ptr_t(cell)^.offset)
    else
      lst_$prasm_operand_a(cell, d, false);
  end;
  add_char(']');
  lst_$prasm_address_mode_suffix(cell);
end;

{ lst_$prasm_add_bitfield - "<offset,width>" of an insert or extract:
  operand k and the cell's +3 in hexadecimal.

  0x250158, 0x5A bytes. }

procedure lst_$prasm_add_bitfield(
    cell: cell_ptr_t;
    k: integer32); options(val_param);
begin
  add_char('<');
  lst_$prasm_operand_a(cell, k, false);
  add_char(',');
  add_hex(cell_head_ptr_t(cell)^.width);
  add_char('>');
end;

{ lst_$prasm_add_condition_codes - ".CC" for a cell that sets the
  integer condition codes (+0 bit 4), ".FCC" for the floating ones (bit
  3).

  0x2501B2, 0x3C bytes: the cell by address (`pea (8,A6)' at the
  calls). }

procedure lst_$prasm_add_condition_codes(
    in cell: cell_ptr_t);
begin
  if cell^.h.b0_4 then
    add_string('.CC', 3)
  else if cell^.h.b0_3 then
    add_string('.FCC', 4);
end;

{ lst_$prasm_lhs - the left side of an assignment: register k (none for
  0), the condition codes, "= " at column 45.

  0x2501F6, 0x48 bytes. }

procedure lst_$prasm_lhs(
    cell: cell_ptr_t;
    k: integer32); options(val_param);
begin
  if k > 0 then
    lst_$add_register_name(cell, k);
  lst_$prasm_add_condition_codes(cell);
  tab_to_column(45);
  add_2_chars('=', ' ');
end;

{ lst_$prasm_display_code_cell - a cell's instruction in -PRASM form, by
  instruction_assembly's prasm_format (+10): a jump table of 27 entries,
  each its layout of the registers, prasm_name (the operator, of
  prasm_len characters) and the other operands (below); 0 and 22
  nothing; another format a bug check.

  0x25023E, 0x762 bytes, internal: the instruction at column 31. }

procedure lst_$prasm_display_code_cell(
    cell: cell_ptr_t); options(val_param); internal;
var
  opc: integer;
begin
  opc := cell^.h.opc;
  tab_to_column(31);
  with instruction_assembly[opc] do
    case ord(text[10]) of
      1: begin
        lst_$add_register_name(cell, 2);
        tab_to_column(45 - prasm_len);
        add_string(text[11], prasm_len);
        add_2_chars('=', ' ');
        lst_$prasm_operand_a(cell, 1, true);
        end;
      2: begin
        lst_$add_register_name(cell, 3);
        lst_$prasm_add_condition_codes(cell);
        tab_to_column(45);
        add_2_chars('=', ' ');
        lst_$add_register_name(cell, 1);
        add_char(' ');
        add_string(text[11], prasm_len);
        add_char(' ');
        lst_$prasm_operand_a(cell, 2, true);
        end;
      3, 24: begin
        if (opc = 173) or (opc = 156) or (opc = 74) then
          lst_$prasm_add_condition_codes(cell)
        else begin
          lst_$add_register_name(cell, 3);
          lst_$prasm_add_condition_codes(cell);
          if (cell^.opnds[3].h.num = cell^.opnds[2].h.num) and
             (ord(text[10]) <> 24) and (prasm_len <= 2) then begin
            tab_to_column(45 - prasm_len);
            add_string(text[11], prasm_len);
            add_2_chars('=', ' ');
            lst_$prasm_operand_a(cell, 1, true);
            return;
          end;
        end;
        tab_to_column(45);
        add_2_chars('=', ' ');
        if ord(text[10]) = 24 then
          add_string('C + ', 4);
        lst_$add_register_name(cell, 2);
        add_char(' ');
        add_string(text[11], prasm_len);
        add_char(' ');
        lst_$prasm_operand_a(cell, 1, true);
        end;
      4: begin
        add_string(text[11], prasm_len);
        add_string(squash_suffix[cell_head_ptr_t(cell)^.modify], 3);
        tab_to_column(45);
        lst_$branch_destination(cell, 1);
        end;
      5: begin
        lst_$prasm_lhs(cell, 2);
        add_string(text[11], prasm_len);
        add_string(squash_suffix[cell_head_ptr_t(cell)^.modify], 3);
        add_char(' ');
        lst_$branch_destination(cell, 1);
        end;
      6: begin
        add_string('BNEVER.SA', 9);
        tab_to_column(45);
        add_string('[.31], ', 7);
        if opc = 127 then
          add_string('NO_TRAP, ', 9);
        add_string(text[11], prasm_len);
        end;
      7: begin
        lst_$prasm_lhs(cell, 2);
        add_string('EXTEND(', 7);
        lst_$add_register_name(cell, 1);
        add_char(',');
        add_string(text[11], prasm_len);
        add_char(')');
        end;
      8: begin
        lst_$prasm_lhs(cell, 3);
        lst_$add_register_name(cell, 1);
        lst_$prasm_add_bitfield(cell, 2);
        end;
      9: begin
        lst_$add_register_name(cell, 3);
        lst_$prasm_add_bitfield(cell, 2);
        lst_$prasm_add_condition_codes(cell);
        tab_to_column(45);
        add_2_chars('=', ' ');
        lst_$add_register_name(cell, 1);
        add_2_chars('<', '0');
        end;
      10: begin
        lst_$add_register_name(cell, 3);
        lst_$prasm_add_bitfield(cell, 2);
        lst_$prasm_add_condition_codes(cell);
        tab_to_column(45);
        add_2_chars('=', ' ');
        lst_$prasm_operand_a(cell, 1, true);
        end;
      11: begin
        lst_$prasm_lhs(cell, 3);
        add_string(text[11], prasm_len);
        add_char('(');
        lst_$add_register_name(cell, 1);
        lst_$prasm_add_bitfield(cell, 2);
        add_char(')');
        end;
      12, 21: begin
        lst_$prasm_lhs(cell, 2);
        add_string(text[11], prasm_len);
        if ord(text[10]) = 12 then
          add_char('(');
        lst_$add_register_name(cell, 1);
        if ord(text[10]) = 12 then
          add_char(')');
        end;
      13: begin
        lst_$prasm_lhs(cell, 3);
        lst_$prasm_address_mode(cell);
        end;
      14: begin
        lst_$prasm_lhs(cell, 2);
        lst_$prasm_operand_a(cell, 1, true);
        end;
      15: begin
        lst_$prasm_lhs(cell, 3);
        add_string(text[11], prasm_len);
        add_char('(');
        lst_$add_register_name(cell, 1);
        add_string('<0,', 3);
        add_small_integer(cell_head_ptr_t(cell)^.width);
        add_2_chars('>', ',');
        lst_$prasm_operand_a(cell, 2, false);
        add_char(')');
        end;
      16: begin
        lst_$prasm_lhs(cell, 0);
        add_string(text[11], prasm_len);
        add_char('(');
        lst_$add_register_name(cell, 1);
        add_char(')');
        end;
      17: begin
        add_char('(');
        lst_$add_register_name(cell, 2);
        add_char(',');
        lst_$add_register_name(cell, 3);
        add_char(')');
        if cell^.h.b0_4 then
          add_string('.CC', 3);
        tab_to_column(45);
        add_2_chars('=', ' ');
        lst_$prasm_address_mode(cell);
        end;
      18: begin
        lst_$prasm_lhs(cell, 3);
        add_2_chars('(', ' ');
        lst_$prasm_operand_a(cell, 1, true);
        add_string(') - ', 4);
        lst_$add_register_name(cell, 2);
        end;
      19: begin
        lst_$prasm_address_mode(cell);
        tab_to_column(45);
        add_2_chars('=', ' ');
        lst_$add_register_name(cell, 1);
        end;
      20: begin
        lst_$prasm_lhs(cell, 0);
        lst_$add_register_name(cell, 1);
        add_char('?');
        end;
      23: begin
        add_string(text[11], prasm_len);
        tab_to_column(45);
        add_char('#');
        add_small_integer(cell^.opnds[1].value);
        end;
      25: begin
        add_string('.31.CC', 6);
        tab_to_column(45);
        add_string('= EXTEND( ', 10);
        lst_$add_register_name(cell, 1);
        add_2_chars(',', ' ');
        add_string(text[11], prasm_len);
        add_2_chars(' ', ')');
        end;
      26:
        add_string(text[11], prasm_len);
      0, 22: ;
      otherwise
        bug_check('LST_$PRASM_DISPLAY_CODE_CELL: cc^.format%.');
    end;
end;

{ lst_$display_code_cell - a code cell's line.

  0x250A0A, 0xD28 bytes.  A label$ cell (opcode 200) prints nothing:
  its number waits in +0x118 for the next line, and the continuation
  flag is cleared.  Otherwise: the source line's listing line in five
  zero-filled digits (lst_13c's entry, 99999 without the map), `*' for
  a marked position; unless the cell continues the last one, the
  cycle column (+2 bits 3..0) and the location (+8) as "xxxxx: "; at
  column 17, a label (opcode 199) is its symbol and `:' at the code's
  label column; else the instruction word (+12) in eight digits unless
  the opcode's no_hex.  The continuation flag: +2 bit 6 for an opcode
  not of the classes fp_double, immediate, fp_single, or +0 bit 2.
  bnever (opcode 1) stops there.  The flags for a load's or store's
  displacement (operand 1 of the classes load and mfpr, 2 of store and
  mtpr): implied when an immediate 0 without a symbol, or plus or minus
  the access size (1 shifted by the attribute's +19 bits 2..0) when the
  cell modifies its base; negative.  Classic form: the registers'
  column at 27 (" .." first for a load_pair with an offset), operands
  1..3 as two digits each (".." for a non-register, ` ' or `,' before,
  "..," before an operand with a width), skipping an implied
  displacement.  Then the numbered label ("n$ " in -PRASM, "nnn$: "
  classic); -PRASM: lst_$prasm_display_code_cell, ", ..." when
  continued, `;' at 69.  The mnemonic at the code's opcode column: in
  -PRASM a cmp of an immediate as "ADD", a muls or muld followed by an
  opcode without an instruction word as that opcode's name with its
  letters' case swapped up to its `.', else instruction_assembly's
  name; classic instruction_mnemonic.  The suffixes (a load's or
  store's size and qualifier, a branch's squash, ".CC"), the operands
  at the code's operand column (",.31" before operand 2 of a -PRASM
  move; a memory operand in brackets with its displacement and `++' or
  `--'; a register a branch takes as "[r]"; load_pair's offset; `#'
  before an immediate of the forms of the set at 0x251734; the others
  by lst_$display_operand in the opcode's format), the -PRASM tails of
  cmp, tst and nop (",.31", ",.31,.31", ".31,.31,.31"), " R" for a
  classic continued line, and the comment: an immediate's or
  displacement's symbol ("; " and its name or prtobj, the offset from
  it) or a pool literal ("; = " and lst_$prtlit, the offset from it).
  A cell of class fp_control sets the continuation flag.  '%a%.'. }

procedure lst_$display_code_cell(
    cell: cell_ptr_t);
var
  buf: chars16_t;
  offset: integer32;
  sym: univ_ptr;
  lit: lit_ptr_t;
  nops: integer32;
  opc: integer;
  marker: char;
  attr: ^instr_attr_t;
  attrv: instr_attr_view_ptr_t;
  pos: cell_pos_ptr_t;
  line_no: integer32;
  map: line_map_ptr_t;
  dots: boolean;
  k: integer32;
  n: integer32;
  i: integer32;
  col: integer32;
  pool: pool_ref_ptr_t;
  memop: boolean;
  next_opc: integer;
  sn: sym_node_ptr_t;
begin
  opc := cell^.h.opc;
  if opc = 200 then begin
    continued := false;
    pending_label := cell^.l12;
    return;
  end;
  line.length := 0;
  attr := addr(instruction_attributes[opc]);
  attrv := addr(instruction_attributes[opc]);
  pos := addr(cell^.l16);
  if cell^.h.b0_1 then begin
    line_no := pos^.p^.line;
    marker := '*';
  end
  else if pos^.marked <> 0 then begin
    line_no := pos^.line;
    marker := '*';
  end
  else begin
    line_no := pos^.line;
    marker := ' ';
  end;
  if lst_13c <> nil then begin
    map := lst_13c;
    add_formatted_integer(map^[line_no], 5, true);
  end
  else
    add_formatted_integer(99999, 5, true);
  add_char(marker);
  if not continued then begin
    add_char(' ');
    if (cell^.h.b2 & 15) >= 10 then
      add_2_digits(cell^.h.b2 & 15)
    else
      add_2_chars(' ', chr((cell^.h.b2 & 15) + ord('0')));
    add_char(' ');
    add_formatted_hex(cell^.l8, 5);
    add_2_chars(':', ' ');
  end;
  tab_to_column(17);
  if opc = 199 then begin
    tab_to_column(col_code_label);
    discard(sym_$append_symbol_print_name(addr(line), univ_ptr(cell^.l12)));
    add_char(':');
  end
  else begin
    if not instruction_assembly[opc].no_hex then
      add_formatted_hex(cell^.l12, 8);
    add_char(' ');
    sym := nil;
    lit := nil;
    continued := (((cell^.h.b2 & 64) <> 0) and
                  not (attr^.class in [class$fp_double, class$immediate,
                                       class$fp_single])) or
                 cell^.h.b0_2;
    if opc <> 1 then begin
      nops := attr^.nresults;
      dots := (opc = 110) and (cell_head_ptr_t(cell)^.offset <> 0);
      implied_disp := false;
      negative_disp := false;
      if attr^.class in [class$load, class$mfpr] then
        k := 1
      else if attr^.class in [class$store, class$mtpr] then
        k := 2
      else
        k := 0;
      if k <> 0 then begin
        if cell^.opnds[k].h.kind = operand$immediate then
          if ((cell^.opnds[k].value = 0) and
              (cell^.opnds[k].link = nil)) or
             ((cell_head_ptr_t(cell)^.modify <> 0) and
              ((cell^.opnds[k].value = lshft(1, attr^.w18 & 7)) or
               (cell^.opnds[k].value = -lshft(1, attr^.w18 & 7)))) then
            implied_disp := true;
        if (cell^.opnds[k].h.kind = operand$immediate) and
           (cell^.opnds[k].value < 0) then
          negative_disp := true;
      end;
      { The registers' column of the classic form. }
      if not (16 in cargs_$options.flags_286) then begin
        tab_to_column(27);
        if dots then
          add_string(' ..', 3);
        for k := 1 to 3 do begin
          if implied_disp and
             (((k = 1) and (attr^.class in [class$load, class$mfpr])) or
              ((k = 2) and (attr^.class in [class$store, class$mtpr]))) then
            next;
          if k > nops then begin
            tab_to_column(line.length + 3);
            next;
          end;
          if ((k = 1) and not dots) or
             (implied_disp and (k = 2) and
              (attr^.class in [class$load, class$mfpr])) then
            add_char(' ')
          else
            add_char(',');
          if odd(attr^.b14_7_1) and ((attrv^.opnds[k].b2 & 16#C0) <> 0) then
          begin
            dots := true;
            add_string('..,', 3);
          end;
          if not (cell^.opnds[k].h.kind in
                  [operand$ip_reg..operand$fp_reg_pair_physical,
                   operand$ip_reg_like..operand$fp_reg_pair_like,
                   operand$case_jump_base]) then
            add_2_chars('.', '.')
          else
            add_2_digits(cell^.opnds[k].h.num);
        end;
      end;
      { The numbered label. }
      tab_to_column(col_code_label);
      if pending_label <> 0 then begin
        if 16 in cargs_$options.flags_286 then begin
          add_formatted_integer(pending_label, 1, false);
          add_string('$ ', 2);
        end
        else begin
          add_formatted_integer(pending_label, 3, false);
          add_string('$: ', 3);
        end;
        pending_label := 0;
      end;
      if 16 in cargs_$options.flags_286 then begin
        lst_$prasm_display_code_cell(cell);
        if continued then
          add_string(', ...', 5);
        tab_to_column(69);
        add_char(';');
      end;
      tab_to_column(col_code_opcode);
      if 16 in cargs_$options.flags_286 then begin
        if (opc = 74) and
           (cell^.opnds[1].h.kind = operand$immediate) then
          add_string('ADD', 3)
        else if ((opc = 184) or (opc = 181)) and
                instruction_assembly[cell^.next^.h.opc].no_hex then begin
          lib_$data_move(addr(instruction_assembly[cell^.next^.h.opc].text[19]),
                         addr(buf), 16);
          next_opc := cell^.next^.h.opc;
          n := instruction_assembly[next_opc].name_len - 1;
          if n >= 0 then
            for i := 1 to n + 1 do begin
              if buf[i] = '.' then
                exit;
              if buf[i] in ['A'..'Z', 'a'..'z'] then
                buf[i] := chr(xor(ord(buf[i]), 16#20));
            end;
          add_string(buf, instruction_assembly[cell^.next^.h.opc].name_len);
        end
        else
          add_string(instruction_assembly[opc].text[19],
                     instruction_assembly[opc].name_len);
      end
      else
        add_string(instruction_mnemonic[opc], instruction_mnemonic_length[opc]);
      if attr^.class in [class$load, class$store] then begin
        if 16 in cargs_$options.flags_286 then
          lst_$prasm_address_mode_suffix(cell)
        else if cell_head_ptr_t(cell)^.lsq <> 0 then
          add_string(lsq_suffix[lsq$t(cell_head_ptr_t(cell)^.lsq)], 2);
      end
      else if instruction_assembly[opc].squash then
        add_string(squash_suffix[cell_head_ptr_t(cell)^.modify], 3);
      if cell^.h.b0_4 or cell^.h.b0_3 then
        add_string('.CC', 3);
      if nops <> 0 then begin
        add_char(' ');
        tab_to_column(col_code_operand);
      end;
      k := 1;
      while k <= nops do begin
        if (k = 2) and (16 in cargs_$options.flags_286) and (opc = 75) then
          add_string(',.31', 4);
        case cell^.opnds[k].h.kind of
          operand$displacement_literal_pool: begin
            pool := univ_ptr(cell^.opnds[k].link);
            lit := pool^.lit;
            offset := cell^.opnds[k].value - pool^.addr;
            if not target_properties.p_be then
              offset := offset + cell^.l8;
            end;
          operand$immediate:
            if cell^.opnds[k].link <> nil then begin
              sn := univ_ptr(cell^.opnds[k].link);
              if not (sn^.kind in [45..58, 60, 61, 69, 156, 176, 198, 200]) then begin
                sym := sn;
                if sym_$has_displacement(sym) then
                  offset := cell^.opnds[k].value - sym_$displacement(sym)
                else
                  offset := 0;
              end;
            end;
          operand$displacement_arg_block, operand$displacement_stack_frame:
            if cell^.opnds[k].link <> nil then begin
              sn := univ_ptr(cell^.opnds[k].link);
              if not (sn^.kind in [45..58, 60, 61, 69, 156, 176, 198, 200]) then begin
                sym := sn;
                if sym = nil then
                  offset := 0
                else
                  offset := cell^.opnds[k].value - sym_$displacement(sym);
              end;
            end;
          otherwise
        end;
        if k > 1 then
          add_char(',');
        if odd(attr^.b14_7_1) and ((attrv^.opnds[k].b2 & 16#C0) <> 0) then begin
          add_char('#');
          add_small_integer(cell_head_ptr_t(cell)^.width);
          add_char(',');
        end;
        memop := ((attr^.class in [class$load, class$mfpr]) and (k = 1)) or
                 ((attr^.class in [class$store, class$mtpr]) and (k = 2));
        if (memop and not (16 in cargs_$options.flags_286)) or
           ((16 in cargs_$options.flags_286) and
            (((attr^.class in [class$load, class$mfpr]) and (k = 2)) or
             ((attr^.class in [class$store, class$mtpr]) and (k = 3)))) then begin
          if not (16 in cargs_$options.flags_286) then
            add_char('[');
          case cell_head_ptr_t(cell)^.modify of
            0:
              if not (16 in cargs_$options.flags_286) then begin
                if not implied_disp then begin
                  lst_$address_mode_a_operand(cell, k);
                  add_char(',');
                end;
                lst_$display_operand(cell, k + 1, 0);
              end
              else
                lst_$display_operand(cell, k, 0);
            1: begin
              if not (16 in cargs_$options.flags_286) then begin
                if not implied_disp then begin
                  lst_$display_operand(cell, k, 0);
                  add_char(',');
                end;
                lst_$display_operand(cell, k + 1, 0);
              end
              else
                lst_$display_operand(cell, k, 0);
              if negative_disp then
                add_2_chars('-', '-')
              else
                add_2_chars('+', '+');
              end;
            2:
              if not (16 in cargs_$options.flags_286) then begin
                if not implied_disp then begin
                  lst_$address_mode_a_operand(cell, k);
                  add_char(',');
                end;
                if negative_disp then
                  add_2_chars('-', '-')
                else
                  add_2_chars('+', '+');
                lst_$display_operand(cell, k + 1, 0);
              end
              else begin
                if negative_disp then
                  add_2_chars('-', '-')
                else
                  add_2_chars('+', '+');
                lst_$display_operand(cell, k, 0);
              end;
            otherwise
          end;
          if not (16 in cargs_$options.flags_286) then begin
            add_char(']');
            k := k + 1;
          end;
        end
        else if instruction_assembly[opc].squash and
                (cell^.opnds[k].h.kind = operand$ip_reg) and
                ((attrv^.opnds[k].form = ord(of$ip_reg_or_basic_block)) or
                 (attrv^.opnds[k].form = ord(of$ip_reg_or_long_pc_disp))) then begin
          add_char('[');
          lst_$display_operand(cell, k, 0);
          add_char(']');
        end
        else if (opc = 110) and (k = 1) then begin
          add_char('[');
          if not (16 in cargs_$options.flags_286) then begin
            if cell_head_ptr_t(cell)^.offset <> 0 then begin
              add_integer(cell_head_ptr_t(cell)^.offset);
              add_char(',');
            end;
            lst_$display_operand(cell, k, 0);
          end
          else begin
            lst_$display_operand(cell, k, 0);
            if cell_head_ptr_t(cell)^.offset <> 0 then begin
              add_char(',');
              add_integer(cell_head_ptr_t(cell)^.offset);
            end;
          end;
          add_char(']');
        end
        else begin
          if not (cell^.opnds[k].h.kind in
                  [operand$ip_reg..operand$fp_reg_pair_physical,
                   operand$ip_reg_like..operand$fp_reg_pair_like,
                   operand$case_jump_base]) and
             (attrv^.opnds[k].form in [3, 6..16, 20, 21, 23..31, 33..40, 42]) then
            add_char('#');
          lst_$display_operand(cell, k,
            rshft(instruction_assembly[opc].opnd[k] & 6, 1));
        end;
        k := k + 1;
      end;
      if 16 in cargs_$options.flags_286 then
        case opc of
          74: add_string(',.31', 4);
          73: add_string(',.31,.31', 8);
          192: begin
            tab_to_column(col_code_operand);
            add_string('.31,.31,.31', 11);
            end;
          otherwise
        end;
      if continued and not (16 in cargs_$options.flags_286) then
        add_2_chars(' ', 'R');
      if attr^.class = class$fp_control then
        continued := true;
      if sym <> nil then begin
        sn := sym;
        if (sn^.kind <> 109) or (sn^.l4 <> 0) then begin
          col := line.length + 1;
          if col < col_code_comment then
            col := col_code_comment;
          tab_to_column(col);
          add_2_chars(';', ' ');
          if sn^.kind in [45..58, 60, 61, 69, 156, 176, 198, 200] then
            add_2_chars('=', ' ');
          if not sym_$append_symbol_print_name(addr(line), sym) then
            prtobj(line, sym);
          add_offset(offset);
        end;
      end
      else if lit <> nil then begin
        col := line.length + 1;
        if col < col_code_comment then
          col := col_code_comment;
        tab_to_column(col);
        add_2_chars(';', ' ');
        add_2_chars('=', ' ');
        lst_$prtlit(line, lit);
        add_offset(offset);
      end;
    end;
  end;
  n := line.length;
  vfmt_$ws(lst_140, '%a%.', line.body, n);
end;

{ lst_$display_literal - a pool literal's line: "     xxxxx: " (its
  address, +20) and, by the literal's kind (a jump table of 21), its
  bytes and value: the integers, booleans and chars by the entry's
  size (+16: 1 "DC.B" or "DC.A" for a char, 2 "DC.W", else "DC.L"); a
  single (converted from the double it is held as) "DC.FS" with
  lib_$cv_sfp_out's text; a double "DC.FD" and its second word on the
  next line; complex and double complex likewise; a varying string's
  placeholder; a string "DA" with at most 40 characters, " ..." when
  longer; read-only data; a namelist descriptor.  Kind 17 or above 20
  is a bug check.

  0x251796, 0x326 bytes: the single's conversion is the FPP's 0x0074
  0x00D4 0xFF3E (docs/rev889-patterns.md 19) into a frame temporary,
  copied to another; the second and third arguments of each vfmt_$ws
  are by address. }

procedure lst_$display_literal(
    entry: lpe_ptr_t);
var
  buf2: array [1..24] of char;
  buf: array [1..24] of char;
  r2: real;
  n: integer32;
  quote: char;
  b: integer32;
  r: real;
  lit: lit_ptr_t;
  lang: lang_node_ptr_t;
  nd: nl_desc_ptr_t;
begin
  vfmt_$ws(lst_140, '%10x%5zlh: %$', entry^.addr);
  lit := entry^.lit;
  case lit^.kind of
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11:
      case entry^.size of
        1:
          if lit^.kind = 11 then begin
            b := ord(lit^.b11);
            vfmt_$ws(lst_140, '%2zlh%26xDC.A%8x**char**%.', b);
          end
          else begin
            b := ord(lit^.b11);
            vfmt_$ws(lst_140, '%2zlh%26xDC.B%8x%sld%.', b, lit^.value);
          end;
        2: begin
          b := lit^.w10;
          vfmt_$ws(lst_140, '%4zlh%24xDC.W%8x%sld%.', b, lit^.value);
          end;
        otherwise
          vfmt_$ws(lst_140, '%8zlh%20xDC.L%8x%sld%.', lit^.value, lit^.value);
      end;
    12: begin
      r := lit^.d;
      r2 := r;
      lib_$cv_sfp_out(buf, r2, 2, 14, 7, 4, 1, false);
      vfmt_$ws(lst_140, '%8ZLH%20XDC.FS%7X%M14A%.', r2, buf);
      end;
    13: begin
      lib_$cv_dfp_out(buf, lit^.d, 2, 23, 16, 4, 1, false);
      vfmt_$ws(lst_140, '%8ZLH%20XDC.FD%7X%M23A%.', lit^.d, buf);
      vfmt_$ws(lst_140, '%17X%8ZLH%.', lit^.l12);
      end;
    14: begin
      lib_$cv_sfp_out(buf, lit^.r, 2, 14, 7, 4, 1, false);
      lib_$cv_sfp_out(buf2, lit^.r12, 2, 14, 7, 4, 1, false);
      vfmt_$ws(lst_140, '%8zlh%20xDC.FS%7x%m14a,%m14a%.', lit^.r, buf, buf2);
      vfmt_$ws(lst_140, '%17x%8zlh%.', lit^.l12);
      end;
    15: begin
      lib_$cv_dfp_out(buf, lit^.d, 2, 23, 16, 4, 1, false);
      lib_$cv_dfp_out(buf2, lit^.d16, 2, 23, 16, 4, 1, false);
      vfmt_$ws(lst_140, '%8ZLH%20XDC.FD%7X%M23A,%M23A%.', lit^.d, buf, buf2);
      vfmt_$ws(lst_140, '%17X%8ZLH%/%/%17X%8ZLH%17X%8ZLH%.', lit^.l12,
               lit^.l16, lit^.l20);
      end;
    18:
      vfmt_$ws(lst_140, '%8zlh%20xDC.V%8x**varying**%.', 0);
    19: begin
      lang := univ_ptr(il_184);
      if (lang <> nil) and (lang^.f377.language = 3) then begin
        quote := '"';
        n := lit^.len - 1;
      end
      else begin
        quote := '''';
        n := lit^.len;
      end;
      if n > 40 then
        n := 40;
      vfmt_$ws(lst_140, '%8zlh%20xDA%10x%M1A%ZA%$', lit^.chars, quote,
               lit^.chars, n);
      if entry^.size > 40 then
        vfmt_$ws(lst_140, ' ...%.')
      else
        vfmt_$ws(lst_140, '%M1A%.', quote);
      end;
    20:
      vfmt_$ws(lst_140, '%8ZLH%20XDC.L%8X**read-only data**%.', lit^.l12);
    16: begin
      nd := lit^.p0;
      vfmt_$ws(lst_140, '%8ZLH%20XDC.L%8X**namelist descriptor**%.',
               nd^.l18);
      end;
    otherwise
      bug_check('LST_$DISPLAY_LITERAL -- literal object kind %4wd%.', lit^.kind);
  end;
end;

{ lst_$display_table - a case table's lines: an empty line, then each
  entry (from +20, +12 of them) as "DC.B", "DC.W" (opcodes 205, 206)
  or "DC.L" with the location counter (+0x1C0, from the cell's +8)
  advanced by the entry's size.

  0x251C92, 0xD0 bytes: the entry and its truncation passed by
  address from frame temporaries. }

procedure lst_$display_table(
    cell: cell_ptr_t);
var
  v: integer32;
  t: integer32;
  i: integer32;
  size: integer32;
  tc: table_cell_ptr_t;
begin
  tc := univ_ptr(cell);
  lst_$new_line;
  table_loc := tc^.loc;
  i := 0;
  while i < tc^.count do begin
    v := tc^.entries[i];
    if tc^.h.opc = 205 then begin
      t := v & 255;
      vfmt_$ws(lst_140, '%10x%5zlh: %2zlh%26xDC.B%8x%sld%.', table_loc, t, v);
      size := 1;
    end
    else if tc^.h.opc = 206 then begin
      t := v & 65535;
      vfmt_$ws(lst_140, '%10x%5zlh: %4zlh%24xDC.W%8x%sld%.', table_loc, t, v);
      size := 2;
    end
    else begin
      vfmt_$ws(lst_140, '%10x%5zlh: %8zlh%20xDC.L%8x%sld%.', table_loc, v, v);
      size := 4;
    end;
    table_loc := table_loc + size;
    i := i + 1;
  end;
end;
