{ prtsub - PRTSUB, building a printed line in a varying string of at
  most 256 characters.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x09829C  0x099C7C  prtcatc
    0x0982C6  0x099CA6  prtcats
    0x09832C  0x099D0C  prtcatb
    0x098378  0x099D58  prtint
    0x098456  0x099E36  prthex
    0x0984A8  0x099E88  prttab
    0x0984E2  0x099EC2  prtsub_$equal
    A5 0x19DB6C (cc.m68k): the module's data, 0x20 bytes (to strings'):
    +0 the hexadecimal digits (.rwdi: '0123456789ABCDEF'); +0x14 a byte
    .rwdi sets to 0.

  Every routine is global and loads A5.
}
module prtsub;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';

{ TODO(pascal) the byte at +0x14 of prtsub's data

  .rwdi initializes one byte at A5 + 0x14 (0x19DB80) to 0, and nothing
  else after the digits; no prtsub routine reads it, and no other unit
  references it absolutely.  Possibly a static of a routine compiled
  out, or a variable no routine uses. }

var
  hex_digits: array [0..15] of char := '0123456789ABCDEF';  { +0 }

{ prtcatc - c to the end of s, unless s is full.

  0x09829C, 0x2A bytes: `cmpi.w #256,(A0); bcc' past `addq.w #1,(A0)'
  and the store at s.body[s.length]. }

procedure prtcatc(
    in out s: prtsub_$line_t;
    c: char);
begin
  if s.length < prtsub_$max_line then begin
    s.length := s.length + 1;
    s.body[s.length] := c;
  end;
end;

{ prtcats - n characters of t to the end of s, as many as fit.

  0x0982C6, 0x66 bytes: the new length (D3) is 256 when n + s.length
  (a longword sum, `ble') exceeds it, else n + s.length; a `for' over i
  from s.length + 1 to it copies t[j], j (D1) counting from 1; then
  s.length := the new length.

  Not known from the original:
  - the locals' names. }

procedure prtcats(
    in out s: prtsub_$line_t;
    in t: univ prtsub_$chars_t;
    n: integer);
var
  new_length: integer;
  i, j: integer;
begin
  if n + s.length > prtsub_$max_line then
    new_length := prtsub_$max_line
  else
    new_length := n + s.length;
  j := 1;
  for i := s.length + 1 to new_length do begin
    s.body[i] := t[j];
    j := j + 1;
  end;
  s.length := new_length;
end;

{ prtcatb - `true' or `false' to the end of s.

  0x09832C, 0x40 bytes: `bpl' on the boolean; prtcats(s, 'false', 5)
  (0x09836C) or prtcats(s, 'true', 4) (0x098374), the call shared. }

procedure prtcatb(
    in out s: prtsub_$line_t;
    b: boolean);
begin
  if b then
    prtcats(s, 'true', 4)
  else
    prtcats(s, 'false', 5);
end;

{ prtint - n in decimal to the end of s.

  0x098378, 0xD4 bytes.  start (D3) := 10 - width.  A negative n puts a
  `-' (prtcatc, 0x0983A8) and is negated; one still negative (the most
  negative integer) takes the digits '2147483648' (the constant at
  0x09844C copied to the 10-character buffer at (-16,A6)) and i := 0; 0
  takes '0' in the last place and i := 9; else from i := 10 down the
  digits n mod 10 (M$OIU$WLW, 0x0983EA: unsigned) and n := n div 10
  (M$DIU$LLW, 0x098408) until n is 0.  Then i is raised to start when
  below it (`bge'), else with zero_fill zeros are put in front down to
  start; prtcats(s, buf[i + 1], 10 - i) (0x09843E).

  Not known from the original:
  - the locals' names; the unsigned division (written on a value known
    not to be negative). }

procedure prtint(
    in out s: prtsub_$line_t;
    n: integer32;
    width: integer;
    zero_fill: boolean);
var
  buf: array [1..10] of char;
  start: integer;
  i: integer;
  v: integer32;
begin
  start := 10 - width;
  v := n;
  if v < 0 then begin
    prtcatc(s, '-');
    if v < 0 then
      v := -v;
  end;
  if v < 0 then begin
    buf := '2147483648';
    i := 0;
  end
  else if v = 0 then begin
    buf[10] := '0';
    i := 9;
  end
  else begin
    i := 10;
    repeat
      buf[i] := chr(v mod 10 + ord('0'));
      i := i - 1;
      v := v div 10;
    until v = 0;
  end;
  if i < start then
    i := start
  else if zero_fill then
    while i > start do begin
      buf[i] := '0';
      i := i - 1;
    end;
  prtcats(s, buf[i + 1], 10 - i);
end;

{ prthex - the last width of n's eight hexadecimal digits to the end of
  s.

  0x098456, 0x52 bytes: a `for' k from 8 down to 1 (a `dbf' of 8)
  stores hex_digits[n & 15] (A5-relative) in buf[k] (8 characters at
  (-8,A6)) and shifts n right 4 (`lsr.l': logical); then
  prtcats(s, buf[9 - width], width) (`pea (-9,A6,D2.w)', 9 - (9 - width)).

  Not known from the original:
  - the locals' names. }

procedure prthex(
    in out s: prtsub_$line_t;
    n: integer32;
    width: integer);
var
  buf: array [1..8] of char;
  k: integer;
  start: integer;
begin
  for k := 8 downto 1 do begin
    buf[k] := hex_digits[n & 15];
    n := rshft(n, 4);
  end;
  start := 9 - width;
  prtcats(s, buf[start], 9 - start);
end;

{ prttab - blanks to the end of s until it is column - 1 long.

  0x0984A8, 0x3A bytes: target := column - 1, at most 256; while target >
  s.length (`bgt'), a blank is appended. }

procedure prttab(
    in out s: prtsub_$line_t;
    column: integer);
var
  target: integer;
begin
  target := column - 1;
  if target > prtsub_$max_line then
    target := prtsub_$max_line;
  while target > s.length do begin
    s.length := s.length + 1;
    s.body[s.length] := ' ';
  end;
end;

{ prtsub_$equal - whether a and b are the same characters.

  0x0984E2, 0x48 bytes: unequal lengths false; else a `for' over the
  length, false at the first unequal character; else true (`st D0'). }

function prtsub_$equal(
    in a: prtsub_$line_t;
    in b: prtsub_$line_t): boolean;
var
  i: integer;
begin
  if a.length <> b.length then begin
    prtsub_$equal := false;
    return;
  end;
  for i := 1 to a.length do
    if a.body[i] <> b.body[i] then begin
      prtsub_$equal := false;
      return;
    end;
  prtsub_$equal := true;
end;
