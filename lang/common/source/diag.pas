{ diag - DIAG_, the compilers' diagnostic output.  Text formatted by
  VFMT_ control strings is gathered into a line of at most 200
  characters; DIAG_$NEW_LINE writes the line behind the prefix it began
  with.  Callers push onto the prefix (DIAG_$SET_PREFIX, DIAG_$INDENT,
  which return the length to come back to) and pop it
  (DIAG_$DROP_PREFIX, DIAG_$DROP_AND_YIELD_PREFIX); the prefix is taken
  for a line when the line's first text is written.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x068438  0x0686B8  about_to_write_to_line (internal)
    0x06845A  0x0686DA  diag_$write
    0x0684FA  0x06877A  diag_$writeln
    0x06855A  0x0687DA  diag_$new_line
    0x0685C2  0x068842  diag_$assure_fresh_line
    0x0685DE  0x06885E  diag_$tab_to_with_fill
    0x06863E  0x0688BE  diag_$tab_to
    0x06865E  0x0688DE  diag_$current_column
    0x068676  0x0688F6  diag_$set_prefix
    0x0686DC  0x06895C  diag_$drop_prefix
    0x0686F8  0x068978  diag_$drop_and_yield_prefix
    0x068754  0x0689D4  diag_$indent
    0x0687BE  0x068A3E  diag_$banner
    A5 0x14B080 (cc.m68k), 0x2CB080 (cc.a88k): the module's data, 0x274
    bytes to ecb's.

  Module data as the image uses it: +0 the line (a varying string: the
  length word, the characters from +2); +208 the prefix taken for the
  line; +416 the prefix; +622 a byte, true when nothing has been
  written to the line since it began.

  The global routines load A5; about_to_write_to_line, which does not,
  is internal (Pascal Rev 8.89 loads A5 in every global routine of a
  module with data; docs/rev889-patterns.md).
}
module diag;

%include 'lang/common/source/diag.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';

{ TODO(pascal) the 4 bytes at +624

  The image places the three strings at +0, +208 and +416 and the flag
  at +622: what a varying [200] of char takes (206 bytes, as dpc sizes
  it) placed on longword boundaries.  The next unit's data begin at
  +0x274 (628), 4 bytes after the flag's longword; no diag routine reads
  them.  A variable no routine uses, or padding, is not known. }

const
  diag_max_line = 200;                  { the line and prefix bound }

var
  line: diag_$vstring_t;                { +0: the line being built }
  line_prefix: diag_$vstring_t;         { +208: the prefix taken for it }
  prefix: diag_$vstring_t;              { +416: the prefix }
  line_is_fresh: boolean;               { +622: nothing written yet }

{ about_to_write_to_line - take the prefix for the line when it is the
  line's first text.

  0x068438, 0x22 bytes, internal (no A5 load, `bsr' from the writers):
    tst.b (0x26e,A5); bpl          if line_is_fresh then begin
    copy (0x1a0,A5) to (0xd0,A5)     line_prefix := prefix;  (by
                                     longwords, (length + 2) / 4 + 1)
    move.b #0,(0x26e,A5)             line_is_fresh := false;
                                   end; }

procedure about_to_write_to_line; internal;
begin
  if line_is_fresh then begin
    line_prefix := prefix;
    line_is_fresh := false;
  end;
end;

{ diag_$write - format the control string with its arguments onto the
  line.

  0x06845A, 0xA0 bytes.  The arguments a3..a10 are loaded at entry and
  pushed as they are, a1 and a2 by `pea'.  When the line has room
  (`cmpi.w #200,(A5); bcc' to the end): VFMT_$ENCODE (0x0684C8) of the
  control string into line.body[line.length + 1] (`pea (2,A5,D1.l)'),
  with the capacity 200 - line.length in a frame temporary at (-4,A6)
  and the length written at (-2,A6), then line.length := line.length +
  that length, at most 200 (`cmpi.l #200; ble'). }

procedure diag_$write(
    in control_string: univ diag_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ diag_$arg_t);
var
  text_length: integer;                 { (-2,A6) }
  new_length: integer32;
begin
  about_to_write_to_line;
  if line.length < diag_max_line then begin
    vfmt_$encode(control_string, line.body[line.length + 1],
                 diag_max_line - line.length, text_length,
                 a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
    new_length := line.length + text_length;
    if new_length > diag_max_line then
      new_length := diag_max_line;
    line.length := new_length;
  end;
end;

{ diag_$writeln - diag_$write, then end the line.

  0x0684FA, 0x60 bytes: the arguments passed on as diag_$write's are
  (`bsr' 0x068546), then `bsr' diag_$new_line (0x06854E). }

procedure diag_$writeln(
    in control_string: univ diag_$string_t;
    in a1, a2, a3, a4, a5, a6, a7, a8, a9, a10:
       univ diag_$arg_t);
begin
  diag_$write(control_string, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10);
  diag_$new_line;
end;

{ diag_$new_line - write the line behind its prefix and begin a new one.

  0x06855A, 0x68 bytes: about_to_write_to_line; when line_prefix.length
  <> 0, VFMT_$WRITE('%za%$', line_prefix.body, line_prefix.length)
  (0x06857C; the literal at 0x0685BA); the same for the line
  (0x068594); VFMT_$WRITE('%.') (0x0685A2; 0x0685C0); then
  line.length := 0 and line_is_fresh := true (`move.b #-1'). }

procedure diag_$new_line;
begin
  about_to_write_to_line;
  if line_prefix.length <> 0 then
    vfmt_$write('%za%$', line_prefix.body, line_prefix.length);
  if line.length <> 0 then
    vfmt_$write('%za%$', line.body, line.length);
  vfmt_$write('%.');
  line.length := 0;
  line_is_fresh := true;
end;

{ diag_$assure_fresh_line - end the line unless nothing has been written
  to it.

  0x0685C2, 0x1C bytes: `tst.b (0x26e,A5); bmi' past `bsr'
  diag_$new_line. }

procedure diag_$assure_fresh_line;
begin
  if not line_is_fresh then
    diag_$new_line;
end;

{ diag_$tab_to_with_fill - fill the line with fill up to column.

  0x0685DE, 0x60 bytes: fill (a byte) in D2, column in D3;
  about_to_write_to_line; count := column, at most 200 (`cmpi.l #200;
  bls': an unsigned test), less line.length, less 1, not below 0; a
  `for' over 1..count (a 32-bit `dbf' loop) stores fill at
  line.body[line.length + i]; then line.length := line.length + count.

  Not known from the original:
  - the unsigned bound test; it is written as a signed one here. }

procedure diag_$tab_to_with_fill(
    column: integer32;
    fill: char);
var
  count: integer32;
  i: integer32;
begin
  about_to_write_to_line;
  count := column;
  if count > diag_max_line then
    count := diag_max_line;
  count := count - line.length - 1;
  if count < 0 then
    count := 0;
  for i := 1 to count do
    line.body[line.length + i] := fill;
  line.length := line.length + count;
end;

{ diag_$tab_to - fill the line with blanks up to column.

  0x06863E, 0x20 bytes: diag_$tab_to_with_fill(column, ' ') (`move.w
  #0x2000,-(SP)': the blank in a word slot). }

procedure diag_$tab_to(
    column: integer32);
begin
  diag_$tab_to_with_fill(column, ' ');
end;

{ diag_$current_column - the line's length.

  0x06865E, 0x18 bytes: `clr.l D0; move.w (A5),D0'. }

function diag_$current_column: integer32;
begin
  diag_$current_column := line.length;
end;

{ diag_$set_prefix - append s to the prefix, at most to 200 characters.

  0x068676, 0x66 bytes: old_length := prefix.length (written through its
  address, then read back through it at each use); n := s.length, at
  most 200 - old_length (`bls': unsigned); a `for' over 1..n copies
  s.body[i] to prefix.body[old_length + i]; then prefix.length :=
  n + old_length. }

procedure diag_$set_prefix(
    in s: univ diag_$vstring_t;
    out old_length: integer);
var
  n: integer32;
  i: integer32;
begin
  old_length := prefix.length;
  n := s.length;
  if n > diag_max_line - old_length then
    n := diag_max_line - old_length;
  for i := 1 to n do
    prefix.body[old_length + i] := s.body[i];
  prefix.length := old_length + n;
end;

{ diag_$drop_prefix - cut the prefix back to old_length.

  0x0686DC, 0x1C bytes: `move.w (8,A6),D0; move.w D0,(0x1a0,A5)'. }

procedure diag_$drop_prefix(
    old_length: integer);
begin
  prefix.length := old_length;
end;

{ diag_$drop_and_yield_prefix - cut the prefix back to old_length,
  giving what is cut.

  0x0686F8, 0x5C bytes: old_length a word at (8,A6), yielded's address
  at (10,A6); yielded.length := prefix.length - old_length, not below 0;
  a `for' over 1..yielded.length copies prefix.body[old_length + i] to
  yielded.body[i]; then prefix.length := old_length. }

procedure diag_$drop_and_yield_prefix(
    old_length: integer;
    out yielded: univ diag_$vstring_t);
var
  n: integer32;
  i: integer32;
begin
  n := prefix.length - old_length;
  if n < 0 then
    n := 0;
  yielded.length := n;
  for i := 1 to yielded.length do
    yielded.body[i] := prefix.body[old_length + i];
  prefix.length := old_length;
end;

{ diag_$indent - append n blanks to the prefix, at most to 200
  characters.

  0x068754, 0x6A bytes: as diag_$set_prefix with a blank (`move.b
  #0x20') for each character. }

procedure diag_$indent(
    n: integer32;
    out old_length: integer);
var
  count: integer32;
  i: integer32;
begin
  old_length := prefix.length;
  count := n;
  if count > diag_max_line - old_length then
    count := diag_max_line - old_length;
  for i := 1 to count do
    prefix.body[old_length + i] := ' ';
  prefix.length := old_length + count;
end;

{ diag_$banner - title on a fresh line, a blank, then `=' to column 83,
  and end the line.

  0x0687BE, 0x46 bytes: diag_$assure_fresh_line; diag_$write(title);
  diag_$write(' %$') (0x068804); diag_$tab_to_with_fill(83, '=')
  (`move.w #0x3d00': `=' in a word slot; `pea 0x53'); diag_$new_line. }

procedure diag_$banner(
    in title: univ diag_$string_t);
begin
  diag_$assure_fresh_line;
  diag_$write(title);
  diag_$write(' %$');
  diag_$tab_to_with_fill(83, '=');
  diag_$new_line;
end;
