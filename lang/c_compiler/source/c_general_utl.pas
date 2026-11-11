{ c_general_utl - the C preprocessor's general utilities: a
  non-negative mod, max and min, comparing, copying, stripping, sliding
  and searching lines held as a length and their characters, and the
  line number field of a listing line.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x052F08  0x053188  math_mod
    0x052F4A  0x0531CA  max
    0x052F6C  0x0531EC  min
    0x052F8E  0x05320E  str_eql
    0x052FDE  0x05325E  str_eql_insensitive
    0x05304A  0x0532CA  str_copy
    0x053080  0x053300  str_strip_leading
    0x0530D8  0x053358  str_slide
    0x05314C  0x0533CC  str_locate
    0x053240  0x0534C0  cgu_$make_line_no
    A5 0x142520 (cc.m68k), 0x2C2520 (cc.a88k): the module's data, 4
    bytes no routine reads.

  Every routine is global and loads A5; none is nested.
}
module c_general_utl;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';

{ math_mod - a mod b, plus b when that is negative.

  0x052F08, 0x42 bytes: b (10) to D2, a (8) sign-extended; M$OIS$WLW
  (0x052F2C, a longword by a word; the 6 bytes of arguments padded to
  8); `tst.w D0; bpl', `add.w D2,D0'.

  Not known from the original:
  - the local's name (the image keeps it in D0). }

function math_mod(
    a: integer;
    b: integer): integer;
var
  m: integer;
begin
  m := a mod b;
  if m < 0 then
    m := m + b;
  math_mod := m;
end;

{ max - the greater of a and b.

  0x052F4A, 0x22 bytes: `cmp.w D1,D0; bgt' keeps a, else b. }

function max(
    a: integer;
    b: integer): integer;
begin
  if a > b then
    max := a
  else
    max := b;
end;

{ min - the lesser of a and b.

  0x052F6C, 0x22 bytes: `cmp.w D1,D0; blt' keeps a, else b. }

function min(
    a: integer;
    b: integer): integer;
begin
  if a < b then
    min := a
  else
    min := b;
end;

{ str_eql - s1 and s2 have the same length and characters.

  0x052F8E, 0x50 bytes: the result is held in D0, false (`clr.b')
  first; `cmp.w D1,D2; bne' (the lengths) to the end; a counted loop
  (`dbf') over 1..len1 comparing bytes, leaving on the first difference
  with D0 still false; after the loop `st D0'.

  Not known from the original:
  - the index's name; how the early return was written (return, or a
    goto to the end). }

function str_eql(
    len1: integer;
    in s1: univ pp_$line_t;
    len2: integer;
    in s2: univ pp_$line_t): boolean;
var
  i: integer;
begin
  str_eql := false;
  if len1 = len2 then begin
    for i := 1 to len1 do
      if s1[i] <> s2[i] then
        return;
    str_eql := true;
  end;
end;

{ str_eql_insensitive - as str_eql, each lower-case letter ('a'..'z',
  `cmpi.b #97; bcs', `cmpi.b #122; bhi') taken as its upper case
  (`subi.b #32') on both sides before comparing.

  0x052FDE, 0x6C bytes; no caller in either binary.

  Not known from the original:
  - the locals' names (the image keeps both characters in D3, D4). }

function str_eql_insensitive(
    len1: integer;
    in s1: univ pp_$line_t;
    len2: integer;
    in s2: univ pp_$line_t): boolean;
var
  i: integer;
  c1, c2: char;
begin
  str_eql_insensitive := false;
  if len1 = len2 then begin
    for i := 1 to len1 do begin
      c1 := s1[i];
      if (c1 >= 'a') and (c1 <= 'z') then
        c1 := chr(ord(c1) - 32);
      c2 := s2[i];
      if (c2 >= 'a') and (c2 <= 'z') then
        c2 := chr(ord(c2) - 32);
      if c1 <> c2 then
        return;
    end;
    str_eql_insensitive := true;
  end;
end;

{ str_copy - src[1..len] to dst[1..len].

  0x05304A, 0x36 bytes: a counted loop (`dbf') moving one byte a pass,
  `move.b (-1,A1,D1.w),(-1,A0,D1.w)'. }

procedure str_copy(
    len: integer;
    in src: univ pp_$line_t;
    out dst: univ pp_$line_t);
var
  i: integer;
begin
  for i := 1 to len do
    dst[i] := src[i];
end;

{ str_strip_leading - remove s's leading blanks and tabs.

  0x053080, 0x58 bytes: first (D2) := 0; a loop over 1..len testing
  `cmpi.b #32' and `cmpi.b #9' (both `seq', `or.b'; `bmi' to the next
  pass); at the first other character first := i and the loop is left
  (`bra' past the `tst.w D2'); when first <> 0, str_slide(len, s,
  first, 1).

  Not known from the original:
  - the locals' names; how the loop was left (exit). }

procedure str_strip_leading(
    in out len: integer;
    in out s: univ pp_$line_t);
var
  i: integer;
  first: integer;
begin
  first := 0;
  for i := 1 to len do
    if not ((s[i] = ' ') or (s[i] = chr(9))) then begin
      first := i;
      exit;
    end;
  if first <> 0 then
    str_slide(len, s, first, 1);
end;

{ str_slide - move s[from..len] to s[dest..] and adjust len.

  0x0530D8, 0x74 bytes: nothing when from = dest (`cmp.w D3,D2; beq').
  The addresses of s[from] and s[dest] are computed once (`lea
  (-1,A0,D2.w),A1', `lea (-1,A0,D3.w),A0'; docs/rev889-patterns.md 5).
  When dest > from (`cmp.w D2,D3; ble' to the other loop) the
  len - from + 1 characters are moved from the last down (a `dbf' loop
  with `subq.w #1' on the index), else from the first up; then len :=
  len + (dest - from) (`add.w D0,(A2)').

  Not known from the original:
  - the index's name. }

procedure str_slide(
    in out len: integer;
    in out s: univ pp_$line_t;
    from: integer;
    dest: integer);
var
  i: integer;
begin
  if from <> dest then begin
    if dest > from then
      for i := len - from + 1 downto 1 do
        s[dest - 1 + i] := s[from - 1 + i]
    else
      for i := 1 to len - from + 1 do
        s[dest - 1 + i] := s[from - 1 + i];
    len := len + (dest - from);
  end;
end;

{ str_locate - where pattern occurs in text, at start or after.

  0x05314C, 0xF4 bytes; no caller in either binary.  Two 512-byte
  locals: the pattern at (-1024,A6), the text at (-512,A6).  When
  insensitive (a byte at (8,A6), `bmi'), each is copied with its
  lower-case letters made upper case (pattern first), else both are
  copied with str_copy (0x0531D2, 0x0531E2).  Then pos := max(1,
  start) (0x0531F2) and a for loop over pos .. text_len -
  (pattern_len - 1) (its trip count kept at (-1036,A6), `subq.w #1;
  bcc'): an inner loop compares the pattern with the text at pos and
  on a difference goes on to the next pos; when it completes (or the
  pattern is empty, `tst.w D2; bmi') pos is the result (D0); after the
  last pos, 0 (`clr.w D0').

  Not known from the original:
  - the locals' names; how the inner loop's mismatch and the match
    were written (a goto to the loop's end, return). }

function str_locate(
    insensitive: boolean;
    start: integer;
    text_len: integer;
    in text: univ pp_$line_t;
    pattern_len: integer;
    in pattern: univ pp_$line_t): integer;
label
  next_pos;
var
  pat: array [1..512] of char;
  txt: array [1..512] of char;
  i, j: integer;
  c: char;
  pos: integer;
begin
  if insensitive then begin
    for i := 1 to pattern_len do begin
      c := pattern[i];
      if (c >= 'a') and (c <= 'z') then
        c := chr(ord(c) - 32);
      pat[i] := c;
    end;
    for i := 1 to text_len do begin
      c := text[i];
      if (c >= 'a') and (c <= 'z') then
        c := chr(ord(c) - 32);
      txt[i] := c;
    end;
  end
  else begin
    str_copy(pattern_len, pattern, pat);
    str_copy(text_len, text, txt);
  end;
  for pos := max(1, start) to text_len - (pattern_len - 1) do begin
    for j := 1 to pattern_len do
      if txt[pos + j - 1] <> pat[j] then
        goto next_pos;
    str_locate := pos;
    return;
  next_pos:
  end;
  str_locate := 0;
end;

{ cgu_$make_line_no - a listing line's number field.

  0x053240, 0x96 bytes: n := 8 when line > 9999 (`cmpi.w #9999; ble'),
  else 7; n := min(n, width) (0x05326C); buf[1] := ' ', buf[2] :=
  open; for i := n - 1 down to 3, buf[i] := the digit line mod 10
  (`divs.w #10; swap', `addi.w #48') and line := line div 10; buf[n] :=
  close; buf[n + 1 .. width] := ' '.

  Not known from the original:
  - the locals' names. }

procedure cgu_$make_line_no(
    line: integer;
    open: char;
    close: char;
    width: integer;
    out buf: univ pp_$line_t);
var
  n: integer;
  i: integer;
begin
  if line > 9999 then
    n := 8
  else
    n := 7;
  n := min(n, width);
  buf[1] := ' ';
  buf[2] := open;
  for i := n - 1 downto 3 do begin
    buf[i] := chr(line mod 10 + ord('0'));
    line := line div 10;
  end;
  buf[n] := close;
  for i := n + 1 to width do
    buf[i] := ' ';
end;
