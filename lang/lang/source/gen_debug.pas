{ gen_debug - GEN_DEBUG_, the debugging tables' buffers.  Eight buffers
  (in three sections' masks): 3 the .lines section's packets, 4 the
  exception tables; each a chain of 500-byte pages from an MRH heap,
  written to the object file (PUTOBJ) when full or at the end.  A range
  (a routine's code) gets its own buffers for the .lines packets and
  the exception table (unless mode 3), copied into the module's at its
  close.  The .lines packets: a line and pc change in a nibble each, a
  byte each, a word each or a longword each (opcodes 16#82, 16#83,
  16#84); a file switch (16#81), statement switches (16#86, 16#87), a
  statement's end (16#8A), entries (16#88), returns (16#89), the
  range's end (16#8F).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0792D4  0x07ACB4  current_coff_offset_of_buf (internal)
    0x0792FE  0x07ACDE  current_sect_offset_of_buf (internal)
    0x079328  0x07AD08  gen_debug_$flush_one_block (internal)
    0x079384  0x07AD64  gen_debug_$flush_buffer (internal)
    0x0793F6  0x07ADD6  page_is_full (in gen_debug_$emit_bytes)
    0x07944C  0x07AE2C  gen_debug_$emit_bytes (internal)
    0x0794D8  0x07AEB8  gen_debug_$copy_buffer (internal)
    0x07952A  0x07AF0A  gen_debug_$read_file_index
    0x079550  0x07AF30  gen_debug_$set_file_index
    0x079570  0x07AF50  buffers_ala_mode (in gen_debug_$begin_compilation)
    0x079594  0x07AF74  init_buffers (in gen_debug_$begin_compilation)
    0x07961A  0x07AFFA  gen_debug_$begin_compilation
    0x0796C2  0x07B0A2  gen_debug_$begin_pass
    0x079714  0x07B0F4  gen_debug_$ready_output
    0x079756  0x07B136  sum_sect_buffers (internal)
    0x07979A  0x07B17A  even_buffer (in gen_debug_$end_pass)
    0x0797DC  0x07B1BC  gen_debug_$end_pass
    0x07981C  0x07B1FC  gen_debug_$end_compilation
    0x07986A  0x07B24A  emit_line_pc_packet (internal)
    0x07996C  0x07B34C  gen_debug_$range_open
    0x079B44  0x07B524  gen_debug_$range_close
    0x079C26  0x07B606  gen_debug_$set_active_buffer
    0x079C6A  0x07B64A  gen_debug_$exception_table_size
    0x079C82  0x07B662  gen_debug_$exception_table_close
    0x079D0A  0x07B6EA  gen_debug_$exception_site
    0x079D86  0x07B766  file_switch (in gen_debug_$lines_def)
    0x079DF0  0x07B7D0  statement_switch (in gen_debug_$lines_def)
    0x079E34  0x07B814  gen_debug_$lines_def
    0x079EEA  0x07B8CA  gen_debug_$lines_stmt_end
    0x079F2C  0x07B90C  gen_debug_$lines_entry
    0x079F76  0x07B956  gen_debug_$lines_return
    A5 0x169A7C (cc.m68k), 0x2E9AEC (cc.a88k): the module's data, 376
    bytes (do_report's A5 is the same address: it has no data).

  Module data as the image lays it out (.rwdi where marked):
    +0    the range template, 50 bytes (.rwdi: buffers 3 and 4's
          addresses, the file index -1, zeros)
    +56   the .lines heap (MRH), +104 the buffer heap
    +128  the buffer template, 20 bytes (.rwdi: zeros)
    +152  the eight buffers (20 bytes each)
    +312  the current range (.rwdi: nil), +316 the ranges open (0)
    +320  the sections' buffer masks (.rwdi: [0..2], [3, 4], [5..7])
    +328  the pc's shift, +332 the pass (.rwdi: -1), +336 the buffers
          in use, +338 the mode
    +340  the pad byte (.rwdi: 16#80), +342, +344, +346 the line and
          pc packets' opcodes (16#84, 16#83, 16#82), +348 the range's
          end (16#8F), +352 the exception table's end (8 bytes: 16#8D,
          0, -1, 0), +360 the file switch (16#81), +362 the statement
          switch (16#87, its kind), +364 the simple one (16#86), +366
          the statement's end (16#8A), +368 the entry (16#88, its
          count), +370 the return (16#89); each byte followed by a 0
    The range template is declared after the buffers here, whose
    addresses it holds (a Pascal initializer refers back only).

  The global routines load A5; the others (the gen_debug_$ buffer
  routines among them) are internal.  The routines nested in a global
  routine run on its frame (file_switch reads lines_def's parameters
  through the frame pointer it saved, `movea.l (A6),A2').

  Not known from the original: every name but the routines'; the
  record fields' names; what +50..+55, +76..+103, +124..+127 and +372
  hold (the heaps may be larger records).
}
module gen_debug;

%include '/sys/ins/base.ins.pas';
%include 'us/us/sys/ins/dst.ins.pas';
%include 'lang/lang/source/gen_debug.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';

const
  page_size = 500;
  lines_buffer = 3;
  exception_buffer = 4;

type
  page_p_t = ^page_t;
  page_t = record
    data: array [0..499] of char;       { +0 }
    offset: integer32;                  { +500: in its buffer }
    used: integer32;                    { +504 }
    next: page_p_t;                     { +508 }
  end;

  buffer_p_t = ^buffer_t;
  buffer_t = record
    cur: page_p_t;                      { +0 }
    first: page_p_t;                    { +4 }
    coff_offset: integer32;             { +8: in the object file }
    sect_offset: integer32;             { +12: in its section }
    count: integer32;                   { +16: the bytes emitted }
  end;

  { What a range's +8 points to (set outside gen_debug). }
  owner_p_t = ^owner_t;
  owner_t = record
    unused_0: integer32;                { +0 }
    unused_4: integer32;                { +4 }
    start: integer32;                   { +8 }
    length: integer32;                  { +12 }
    lines_offset: integer32;            { +16 }
  end;

  range_p_t = ^range_t;
  range_t = record
    lines: buffer_p_t;                  { +0 }
    exc: buffer_p_t;                    { +4 }
    owner: owner_p_t;                   { +8 }
    lines_sect: integer32;              { +12 }
    exc_sect: integer32;                { +16 }
    start_pc: integer32;                { +20 }
    file_index: integer32;              { +24 }
    last_line: integer32;               { +28 }
    last_pc: integer32;                 { +32 }
    last_stmt: integer32;               { +36 }
    stmt_kind: integer32;               { +40 }
    entries: integer32;                 { +44 }
    marked: boolean;                    { +48: an entry or a return
                                          since the last statement }
  end;

  bytes_t = array [1..500] of char;

  { A .lines packet, from the frame's odd byte (pad): a line and pc
    change, a file switch (a DST source location) or a statement's
    end. }
  lines_packet_t = packed record
    pad: char;
    case integer of
      1: (dl4: -8..7;
          dpc4: 0..15);
      2: (op: char;
          case integer of
            1: (b_dl: -128..127;
                b_dpc: 0..255);
            2: (w_dl: integer;
                w_dpc: 0..65535);
            3: (l_line: integer32;
                l_pc: integer32);
            4: (unused: boolean;
                file_index: 0..2047;
                line: 0..16#FFFFF);
            5: (offset: integer32));
  end;

  { An exception table entry. }
  exception_packet_t = packed record
    hi: 0..15;
    lo: 0..15;
    b: 0..255;
    w: integer;
    offset: integer32;
  end;

  two_bytes_t = array [1..2] of char;

var
  lines_heap: mrh_$heap_t;                              { +56 }
  buffer_heap: mrh_$heap_t;                             { +104 }
  buffer_template: buffer_t := [cur := nil, first := nil,
    coff_offset := 0, sect_offset := 0, count := 0];    { +128 }
  buffers: array [0..7] of buffer_t;                    { +152 }
  range_template: range_t := [lines := addr(buffers[3]),
    exc := addr(buffers[4]), owner := nil, lines_sect := 0,
    exc_sect := 0, start_pc := 0, file_index := -1, last_line := 0,
    last_pc := 0, last_stmt := 0, stmt_kind := 0, entries := 0,
    marked := false];                                   { +0 }
  cur_range: range_p_t := nil;                          { +312 }
  ranges_open: integer32 := 0;                          { +316 }
  sect_masks: array [0..2] of gen_debug_$mode_t := [
    [0, 1, 2], [3, 4], [5, 6, 7]];                      { +320 }
  pc_shift: integer32;                                  { +328 }
  pass: integer32 := -1;                                { +332 }
  active: gen_debug_$mode_t;                            { +336 }
  tables_mode: gen_debug_$mode_t;                       { +338 }
  pad_byte: char := chr(16#80);                         { +340 }
  long_op: char := chr(16#84);                          { +342 }
  word_op: char := chr(16#83);                          { +344 }
  byte_op: char := chr(16#82);                          { +346 }
  range_end: char := chr(16#8F);                        { +348 }
  exception_end: array [1..8] of char := [chr(16#8D), chr(0),
    chr(16#FF), chr(16#FF), chr(0), chr(0), chr(0), chr(0)];  { +352 }
  file_op: char := chr(16#81);                          { +360 }
  stmt_switch: two_bytes_t := [chr(16#87), chr(0)];     { +362 }
  stmt_simple: char := chr(16#86);                      { +364 }
  stmt_end_op: char := chr(16#8A);                      { +366 }
  entry_packet: two_bytes_t := [chr(16#88), chr(0)];    { +368 }
  return_op: char := chr(16#89);                        { +370 }

{ PUTOBJ, FREEOBJ - iosub.pas's (0x0B5FD0, 0x0B6094): size bytes of the
  object file at offset mapped, their address returned; the mapping
  dropped.  Declared here: gen_debug opens none of the prelude, whose
  globals_from_general.ins.pas declares putobj (docs/questions.md 19);
  iosub.ins.pas has freeobj. }
function putobj(
    offset: integer32;
    size: integer32): univ_ptr; options(val_param); extern;

{ BCOPY - the C library's (through the transfer vector): n bytes from
  src to dst. }
procedure bcopy(
    src: univ_ptr;
    dst: univ_ptr;
    n: integer32); options(val_param); extern;

{ current_coff_offset_of_buf, current_sect_offset_of_buf - where buffer
  i's next byte goes in the object file, in its section.  0x0792D4,
  0x0792FE, 0x2A bytes each: the buffer's 20 bytes (`lsl.w #2' twice
  and an add). }

function current_coff_offset_of_buf(
    i: integer): integer32; options(val_param); internal;
begin
  current_coff_offset_of_buf := buffers[i].coff_offset + buffers[i].count;
end;

function current_sect_offset_of_buf(
    i: integer): integer32; options(val_param); internal;
begin
  current_sect_offset_of_buf := buffers[i].sect_offset + buffers[i].count;
end;

{ gen_debug_$flush_one_block - the buffer's first page written at its
  place (PUTOBJ, BCOPY, FREEOBJ; the count, offset and addresses
  through locals).  0x079328, 0x5C bytes. }

procedure gen_debug_$flush_one_block(
    buf: buffer_p_t); options(val_param); internal;
var
  page: page_p_t;
  n, offset: integer32;
  dst: univ_ptr;
begin
  page := buf^.first;
  n := page^.used;
  offset := buf^.coff_offset + page^.offset;
  dst := putobj(offset, n);
  bcopy(page, dst, n);
  freeobj(dst);
end;

{ gen_debug_$flush_buffer - every page of the buffer written.
  0x079384, 0x72 bytes. }

procedure gen_debug_$flush_buffer(
    buf: buffer_p_t); options(val_param); internal;
var
  page: page_p_t;
  n, offset: integer32;
  dst: univ_ptr;
begin
  page := buf^.first;
  while page <> nil do begin
    n := page^.used;
    offset := buf^.coff_offset + page^.offset;
    dst := putobj(offset, n);
    bcopy(page, dst, n);
    freeobj(dst);
    page := page^.next;
  end;
end;

{ gen_debug_$emit_bytes - n bytes appended to the buffer (counted in
  every pass, stored from the first): as many as the current page
  takes, then the next page.

  0x07944C, 0x8C bytes: the page's count's low word as the index
  (`move.w (506,A0)'); the copy a `dbf' with the borrow from the high
  word (docs/rev889-patterns.md 17). }

procedure gen_debug_$emit_bytes(
    buf: buffer_p_t;
    in bytes: univ bytes_t;
    n: integer32); options(val_param); internal;
var
  page: page_p_t;
  room, k, j, src: integer32;

  { page_is_full - another page: a new one chained on when every page
    is kept (mode 15), else this one written and reused; its offset
    moved on by a page.  0x0793F6, 0x56 bytes. }

  procedure page_is_full(
      buf: buffer_p_t); options(val_param);
  var
    page: page_p_t;
    offset: integer32;
  begin
    page := buf^.cur;
    offset := page^.offset;
    if 15 in tables_mode then begin
      page^.next := mrh_$alloc_fixed(buffer_heap);
      page := page^.next;
      page^.next := nil;
      buf^.cur := page;
    end
    else
      gen_debug_$flush_one_block(buf);
    page^.offset := offset + page_size;
    page^.used := 0;
  end;

begin
  buf^.count := buf^.count + n;
  if (pass > 0) and (n > 0) then begin
    page := buf^.cur;
    src := 1;
    while n > 0 do begin
      room := page_size - page^.used;
      if room <= 0 then begin
        page_is_full(buf);
        room := page_size;
        page := buf^.cur;
      end;
      k := n;
      if k > room then
        k := room;
      for j := 1 to k do begin
        page^.data[page^.used] := bytes[src];
        page^.used := page^.used + 1;
        src := src + 1;
      end;
      n := n - k;
    end;
  end;
end;

{ gen_debug_$copy_buffer - a range's buffer appended to another (only
  counted when it has no bytes stored).  0x0794D8, 0x52 bytes. }

procedure gen_debug_$copy_buffer(
    src: buffer_p_t;
    dst: buffer_p_t); options(val_param); internal;
var
  page: page_p_t;
begin
  page := src^.first;
  if (page = nil) or (page^.used = 0) then
    dst^.count := dst^.count + src^.count
  else
    while page <> nil do begin
      gen_debug_$emit_bytes(dst, page^.data, page^.used);
      page := page^.next;
    end;
end;

{ gen_debug_$read_file_index - 0x07952A, 0x26 bytes. }

function gen_debug_$read_file_index: integer32;
begin
  if cur_range <> nil then
    gen_debug_$read_file_index := cur_range^.file_index
  else
    gen_debug_$read_file_index := 1;
end;

{ gen_debug_$set_file_index - 0x079550, 0x20 bytes. }

procedure gen_debug_$set_file_index(
    file_index: integer32);
begin
  cur_range^.file_index := file_index;
end;

{ gen_debug_$begin_compilation - 0x07961A, 0x74 bytes: the mode kept
  without 2 (`bclr #2'); the heaps of 512-byte blocks (MRH_$INITIALIZE
  with `pea 0x200': flags 0); the shift 1 for mode 7, else 2. }

procedure gen_debug_$begin_compilation(
    mode: gen_debug_$mode_t);

  { buffers_ala_mode - the buffers the mode's sections use (the masks
    of sections 0, 1, 2 for mode 0, 1, 2).  0x079570, 0x24 bytes: no
    frame (the mode at (4,SP)). }

  function buffers_ala_mode(
      mode: gen_debug_$mode_t): gen_debug_$mode_t; options(val_param);
  var
    used: gen_debug_$mode_t;
  begin
    used := [];
    if 0 in mode then
      used := sect_masks[0];
    if 1 in mode then
      used := used + sect_masks[1];
    if 2 in mode then
      used := used + sect_masks[2];
    buffers_ala_mode := used;
  end;

  { init_buffers - every buffer set from the template (7 down to 0), a
    first page for each in use.  0x079594, 0x86 bytes. }

  procedure init_buffers;
  var
    i: integer;
  begin
    for i := 7 downto 0 do begin
      buffers[i] := buffer_template;
      if i in active then begin
        buffers[i].first := mrh_$alloc_fixed(buffer_heap);
        buffers[i].cur := buffers[i].first;
        buffers[i].cur^.used := 0;
        buffers[i].cur^.offset := 0;
        buffers[i].cur^.next := nil;
      end;
    end;
  end;

begin
  tables_mode := mode;
  tables_mode := tables_mode - [2];
  mrh_$initialize(buffer_heap, 0, 512, 'gen_debug buffer heap%');
  mrh_$initialize(lines_heap, 0, 512, 'gen_debug .lines buffer heap%');
  pc_shift := 2;
  if 7 in tables_mode then
    pc_shift := 1;
  active := buffers_ala_mode(tables_mode);
  init_buffers;
end;

{ gen_debug_$begin_pass - the pass counted (from 0 when every page is
  kept); the buffers' counts cleared.  0x0796C2, 0x52 bytes. }

procedure gen_debug_$begin_pass;
var
  i: integer;
begin
  if 15 in tables_mode then
    pass := 0;
  pass := pass + 1;
  for i := 0 to 7 do
    buffers[i].count := 0;
end;

{ gen_debug_$ready_output - 0x079714, 0x42 bytes. }

procedure gen_debug_$ready_output(
    p1: integer32;
    exc_offset: integer32;
    p3: integer32);
begin
  buffers[exception_buffer].coff_offset := exc_offset;
  buffers[exception_buffer].sect_offset := 0;
  buffers[lines_buffer].coff_offset := current_coff_offset_of_buf(exception_buffer);
  buffers[lines_buffer].sect_offset := current_sect_offset_of_buf(exception_buffer);
end;

{ sum_sect_buffers - the bytes of a section's buffers (7 down to 0).
  0x079756, 0x44 bytes. }

function sum_sect_buffers(
    sect: integer32): integer32; options(val_param); internal;
var
  i: integer;
  total: integer32;
begin
  total := 0;
  for i := 7 downto 0 do
    if i in sect_masks[sect] then
      total := total + buffers[i].count;
  sum_sect_buffers := total;
end;

{ gen_debug_$end_pass - 0x0797DC, 0x40 bytes. }

procedure gen_debug_$end_pass(
    in p1: integer32;
    out size: integer32;
    in p3: integer32);

  { even_buffer - a pad byte after an odd count.  0x07979A, 0x42
    bytes: `lsr.b #1; bcc'; the byte's address the parameter's low
    byte (`pea (11,A6)'). }

  procedure even_buffer(
      i: integer;
      pad: integer); options(val_param);
  var
    c: char;
  begin
    if odd(buffers[i].count) then begin
      c := chr(pad);
      gen_debug_$emit_bytes(addr(buffers[i]), c, 1);
    end;
  end;

begin
  if 1 in tables_mode then
    even_buffer(lines_buffer, ord(pad_byte));
  size := sum_sect_buffers(1);
end;

{ gen_debug_$end_compilation - 0x07981C, 0x4E bytes: MRH_$RELEASE_ALL
  of the buffer heap. }

procedure gen_debug_$end_compilation;
var
  i: integer;
begin
  for i := 0 to 7 do
    if i in active then
      gen_debug_$flush_buffer(addr(buffers[i]));
  mrh_$release_all(buffer_heap);
end;

{ emit_line_pc_packet - the change from the range's last line and pc
  in the smallest packet that holds it (the pc's change shifted,
  unsigned).  0x07986A, 0x102 bytes: the packet in (-13,A6). }

procedure emit_line_pc_packet(
    line: integer32;
    pc: integer32); options(val_param); internal;
var
  pkt: lines_packet_t;
  dl, dpc: integer32;
  n: integer;
begin
  dl := line - cur_range^.last_line;
  dpc := rshft(pc - cur_range^.last_pc, pc_shift);
  if (dl >= -7) and (dl <= 7) and (dpc >= 0) and (dpc <= 15) then begin
    pkt.dl4 := dl;
    pkt.dpc4 := dpc;
    n := 1;
  end
  else if (dl >= -128) and (dl <= 127) and (dpc >= 0) and (dpc <= 255) then begin
    pkt.op := byte_op;
    pkt.b_dl := dl;
    pkt.b_dpc := dpc;
    n := 3;
  end
  else if (dl >= -32768) and (dl <= 32767) and (dpc >= 0) and (dpc <= 65535) then begin
    pkt.op := word_op;
    pkt.w_dl := dl;
    pkt.w_dpc := dpc;
    n := 5;
  end
  else begin
    pkt.op := long_op;
    pkt.l_line := line;
    pkt.l_pc := pc - cur_range^.start_pc;
    n := 9;
  end;
  gen_debug_$emit_bytes(cur_range^.lines, pkt.op, n);
end;

{ gen_debug_$range_open - 0x07996C, 0x1D8 bytes: 50 bytes from the
  .lines heap; with mode 0 or 1 (`moveq #3; and.w') the template copied
  (12 longwords and a word) and, unless mode 3, the range's two
  buffers made (each its descriptor and a page from the .lines heap,
  `mrh_$alloc_fixed'); the ranges counted; the result in A0 through a
  local. }

function gen_debug_$range_open(
    p1: integer32;
    p2: integer32;
    pc: integer32): gen_debug_$range_ptr_t;
var
  r: range_p_t;
begin
  if cur_range <> nil then
    gen_debug_$lines_stmt_end(pc - 1);
  cur_range := mrh_$alloc(lines_heap, 50);
  if tables_mode * [0, 1] <> [] then begin
    cur_range^ := range_template;
    if not (3 in tables_mode) then begin
      cur_range^.lines := mrh_$alloc(lines_heap, 20);
      cur_range^.lines^ := buffer_template;
      cur_range^.lines^.first := mrh_$alloc_fixed(lines_heap);
      cur_range^.lines^.cur := cur_range^.lines^.first;
      cur_range^.lines^.cur^.used := 0;
      cur_range^.lines^.cur^.offset := 0;
      cur_range^.lines^.cur^.next := nil;
      cur_range^.exc := mrh_$alloc(lines_heap, 20);
      cur_range^.exc^ := buffer_template;
      cur_range^.exc^.first := mrh_$alloc_fixed(lines_heap);
      cur_range^.exc^.cur := cur_range^.exc^.first;
      cur_range^.exc^.cur^.used := 0;
      cur_range^.exc^.cur^.offset := 0;
      cur_range^.exc^.cur^.next := nil;
    end;
    cur_range^.lines_sect := current_sect_offset_of_buf(lines_buffer);
    cur_range^.exc_sect := current_sect_offset_of_buf(exception_buffer);
    cur_range^.owner := nil;
    cur_range^.start_pc := pc;
    cur_range^.last_pc := pc;
  end;
  ranges_open := ranges_open + 1;
  r := cur_range;
  gen_debug_$range_open := r;
end;

{ gen_debug_$range_close - 0x079B44, 0xE2 bytes: the range's end packet
  and the last line at the final pc (mode 1); its .lines copied into
  the module's (unless mode 3); its owner's length and .lines offset
  (mode 0); the .lines heap released with the last range. }

function gen_debug_$range_close(
    range: gen_debug_$range_ptr_t;
    pc: integer32): integer32;
var
  last: integer32;
  result: integer32;
begin
  cur_range := range;
  if 1 in tables_mode then begin
    gen_debug_$emit_bytes(cur_range^.lines, range_end, 1);
    if pc <> 0 then
      last := pc
    else
      last := cur_range^.last_pc;
    emit_line_pc_packet(cur_range^.last_line, last);
  end;
  if not (3 in tables_mode) then begin
    cur_range^.lines_sect := current_sect_offset_of_buf(lines_buffer);
    gen_debug_$copy_buffer(cur_range^.lines, addr(buffers[lines_buffer]));
  end;
  if (0 in tables_mode) and (cur_range^.owner <> nil) then begin
    cur_range^.owner^.length := pc - cur_range^.owner^.start;
    cur_range^.owner^.lines_offset := cur_range^.lines_sect;
  end;
  result := cur_range^.lines_sect;
  ranges_open := ranges_open - 1;
  if ranges_open = 0 then
    mrh_$release_all(lines_heap);
  cur_range := nil;
  gen_debug_$range_close := result;
end;

{ gen_debug_$set_active_buffer - 0x079C26, 0x44 bytes. }

procedure gen_debug_$set_active_buffer(
    range: gen_debug_$range_ptr_t;
    pc: integer32);
begin
  if range <> cur_range then begin
    if cur_range <> nil then
      gen_debug_$lines_stmt_end(pc - 1);
    cur_range := range;
  end;
end;

{ gen_debug_$exception_table_size - 0x079C6A, 0x18 bytes. }

function gen_debug_$exception_table_size: integer32;
begin
  gen_debug_$exception_table_size := buffers[exception_buffer].count;
end;

{ gen_debug_$exception_table_close - 0x079C82, 0x88 bytes: the table's
  end (8 bytes) after a non-empty table; copied into the module's
  exception buffer unless mode 3. }

function gen_debug_$exception_table_close(
    range: gen_debug_$range_ptr_t): integer32;
begin
  cur_range := range;
  if cur_range^.exc^.count <> 0 then
    gen_debug_$emit_bytes(cur_range^.exc, exception_end, 8);
  if not (3 in tables_mode) then begin
    cur_range^.exc_sect := current_sect_offset_of_buf(exception_buffer);
    gen_debug_$copy_buffer(cur_range^.exc, addr(buffers[exception_buffer]));
  end;
  if cur_range^.exc^.count <> 0 then
    gen_debug_$exception_table_close := cur_range^.exc_sect
  else
    gen_debug_$exception_table_close := -1;
  cur_range := nil;
end;

{ gen_debug_$exception_site - 0x079D0A, 0x7C bytes: the entry's first
  byte 16#8D (two nibbles: `ori.b #-128', `ori.b #13'), b's low byte,
  w, the pc from the range's start. }

procedure gen_debug_$exception_site(
    pc: integer32;
    w: integer;
    b: integer);
var
  pkt: exception_packet_t;
begin
  if (b <> 0) or (w <> 0) then begin
    pkt.hi := 8;
    pkt.lo := 13;
    pkt.b := b & 16#FF;
    pkt.w := w;
    pkt.offset := pc - cur_range^.start_pc;
    gen_debug_$emit_bytes(cur_range^.exc, pkt, 8);
  end;
end;

{ gen_debug_$lines_def - (mode 1) a new file, line, statement or a
  statement after an entry or return: the statement switch, the line
  and pc packet, the range's state.  0x079E34, 0xB6 bytes. }

procedure gen_debug_$lines_def(
    file_index: integer32;
    line: integer32;
    stmt: integer32;
    pc: integer32);
var
  changed: boolean;

  { file_switch - the file and line as a DST source location
    (16#81 and 4 bytes: the file in bits 30..20, the line in 19..0).
    0x079D86, 0x6A bytes: lines_def's parameters through its frame
    (`movea.l (A6),A2'). }

  procedure file_switch;
  var
    pkt: lines_packet_t;
  begin
    pkt.op := file_op;
    pkt.unused := false;
    pkt.file_index := file_index;
    pkt.line := line;
    gen_debug_$emit_bytes(cur_range^.lines, pkt.op, 5);
    cur_range^.last_line := line;
  end;

  { statement_switch - a statement of another kind: 16#86 for kind 1,
    16#87 and the kind for the others; none for 0.  0x079DF0, 0x44
    bytes. }

  procedure statement_switch(
      kind: integer); options(val_param);
  begin
    if kind <> 0 then
      if kind = 1 then
        gen_debug_$emit_bytes(cur_range^.lines, stmt_simple, 1)
      else begin
        stmt_switch[2] := chr(kind);
        gen_debug_$emit_bytes(cur_range^.lines, stmt_switch, 2);
      end;
    cur_range^.stmt_kind := kind;
  end;

begin
  if 1 in tables_mode then begin
    changed := false;
    if gen_debug_$read_file_index <> file_index then begin
      file_switch;
      changed := true;
    end
    else if cur_range^.last_line <> line then
      changed := true;
    if changed then
      cur_range^.stmt_kind := -1
    else if (stmt <> cur_range^.last_stmt) or cur_range^.marked then
      changed := true;
    if changed then begin
      statement_switch(stmt);
      emit_line_pc_packet(line, pc);
      gen_debug_$set_file_index(file_index);
      cur_range^.last_line := line;
      cur_range^.last_stmt := stmt;
      cur_range^.last_pc := pc;
      cur_range^.marked := false;
    end;
  end;
end;

{ gen_debug_$lines_stmt_end - the statement's end (16#8A and the pc
  from the range's start) unless the pc lies before it.  0x079EEA,
  0x42 bytes: the packet in (-5,A6). }

procedure gen_debug_$lines_stmt_end(
    pc: integer32);
var
  pkt: lines_packet_t;
begin
  pkt.op := stmt_end_op;
  pkt.offset := pc - cur_range^.start_pc;
  if pkt.offset >= 0 then
    gen_debug_$emit_bytes(cur_range^.lines, pkt.op, 5);
end;

{ gen_debug_$lines_entry - (mode 1) 16#88 and the entries counted so
  far (the count's low byte, `move.b (47,A0)').  0x079F2C, 0x4A bytes. }

procedure gen_debug_$lines_entry;
begin
  if 1 in tables_mode then begin
    entry_packet[2] := chr(cur_range^.entries & 16#FF);
    gen_debug_$emit_bytes(cur_range^.lines, entry_packet, 2);
    cur_range^.entries := cur_range^.entries + 1;
    cur_range^.marked := true;
  end;
end;

{ gen_debug_$lines_return - (mode 1) 16#89.  0x079F76, 0x38 bytes. }

procedure gen_debug_$lines_return;
begin
  if 1 in tables_mode then begin
    gen_debug_$emit_bytes(cur_range^.lines, return_op, 1);
    cur_range^.marked := true;
  end;
end;
