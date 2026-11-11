{ std - STD_, the compilers' small standard helpers: range tests,
  rounding up, appending characters, strings and integers to a varying
  string, and dumping booleans and strings through DIAG_.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07327C  0x074C5C  std_$in_range_lower_to_upper
    0x0732AC  0x074C8C  std_$in_range_lower_to_upper_plus_1
    0x0732DC  0x074CBC  std_$in_range_lower_minus_1_to_upper
    0x07330C  0x074CEC  std_$in_range_lower_minus_1_to_upper_plus_1
    0x07333C  0x074D1C  std_$round_up_to_multiple_of
    0x07338A  0x074D6A  std_$diag_dump_boolean
    0x0733C4  0x074DA4  std_$diag_dump_any_string
    0x073424  0x074E04  std_$append_char
    0x073448  0x074E28  std_$append_string
    0x073484  0x074E64  std_$append_integer
    0x07350A  0x074EEA  std_$diag_dump_var_string
    A5 0x168D88 (cc.m68k), 0x2E8DF8 (cc.a88k): the module's data, 4 bytes
    before token's; no routine here reads it.

  Every routine is global and loads A5 (Pascal Rev 8.89 does so in every
  global routine of a module with data); none is nested.
}
module std;

%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/diag.ins.pas';

{ std_$in_range_lower_to_upper - lower <= value <= upper.

  0x07327C, 0x30 bytes: `movem.l D2-D4/A5'; upper, lower, value loaded to
  D2, D0, D1; `cmp.l D1,D0; sle D3' (lower <= value), `cmp.l D2,D1; sle
  D4' (value <= upper), `and.b D4,D3'; the result in D0.

  Not known from the original:
  - the parameter names; their roles follow from the comparisons and
    the routine's name. }

function std_$in_range_lower_to_upper(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean;
begin
  std_$in_range_lower_to_upper := (lower <= value) and (value <= upper);
end;

{ std_$in_range_lower_to_upper_plus_1 - lower <= value < upper.

  0x0732AC, 0x30 bytes: as std_$in_range_lower_to_upper, the second test
  `slt' (value < upper). }

function std_$in_range_lower_to_upper_plus_1(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean;
begin
  std_$in_range_lower_to_upper_plus_1 := (lower <= value) and (value < upper);
end;

{ std_$in_range_lower_minus_1_to_upper - lower < value <= upper.

  0x0732DC, 0x30 bytes: the first test `slt' (lower < value). }

function std_$in_range_lower_minus_1_to_upper(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean;
begin
  std_$in_range_lower_minus_1_to_upper := (lower < value) and (value <= upper);
end;

{ std_$in_range_lower_minus_1_to_upper_plus_1 - lower < value < upper.

  0x07330C, 0x30 bytes: both tests `slt'. }

function std_$in_range_lower_minus_1_to_upper_plus_1(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean;
begin
  std_$in_range_lower_minus_1_to_upper_plus_1 := (lower < value) and (value < upper);
end;

{ std_$round_up_to_multiple_of - value rounded up to a multiple of
  multiple; value itself when multiple is 0.

  0x07333C, 0x4E bytes: `tst.l D2' (multiple) `bne'; then D0 := value;
  else D3 := multiple - 1 + value, M$DIS$LLL (0x073368) by multiple,
  M$MIS$LLL (0x073374) by multiple; the result in D0. }

function std_$round_up_to_multiple_of(
    value: integer32;
    multiple: integer32): integer32;
begin
  if multiple = 0 then
    std_$round_up_to_multiple_of := value
  else
    std_$round_up_to_multiple_of :=
      ((value + multiple - 1) div multiple) * multiple;
end;

{ std_$diag_dump_boolean - `true' or `false' to the diagnostic output.

  0x07338A, 0x3A bytes: `move.b (8,A6),D0; bpl': the boolean by value;
  `pea' of the literal 'true%$' (0x0733B4) or 'false%$' (0x0733BC), then
  DIAG_$WRITE. }

procedure std_$diag_dump_boolean(
    b: boolean);
begin
  if b then
    diag_$write('true%$')
  else
    diag_$write('false%$');
end;

{ std_$diag_dump_any_string - len characters of s to the diagnostic
  output, in double quotes when quoted.

  0x0733C4, 0x60 bytes: quoted (a byte at (16,A6)) kept in D2, s's
  address in A2; DIAG_$WRITE('"%$') (0x07341C) when quoted, then
  DIAG_$WRITE('%a%$', s, len) with `pea (12,A6)': len is a value
  parameter passed on by address; then the quote again. }

procedure std_$diag_dump_any_string(
    in s: univ std_$string_t;
    len: integer32;
    quoted: boolean);
begin
  if quoted then
    diag_$write('"%$');
  diag_$write('%a%$', s, len);
  if quoted then
    diag_$write('"%$');
end;

{ std_$append_char - c to the end of s.

  0x073424, 0x24 bytes: `move.b (12,A6),D0' (c, by value); `addq.w
  #1,(A0)'; `move.w (A0),D1; move.b D0,(1,A0,D1.w)'. }

procedure std_$append_char(
    in out s: std_$string_t;
    c: char);
begin
  s.length := s.length + 1;
  s.body[s.length] := c;
end;

{ std_$append_string - src's characters to the end of dst.

  0x073448, 0x3C bytes: a `for' from 1 to src.length as a `dbf' loop
  (D0 the count less one, D1 the index); each pass `addq.w #1,(A1)' and
  the character copied to dst.body[dst.length]. }

procedure std_$append_string(
    in out dst: std_$string_t;
    in src: univ std_$string_t);
var
  i: integer;
begin
  for i := 1 to src.length do begin
    dst.length := dst.length + 1;
    dst.body[dst.length] := src.body[i];
  end;
end;

{ std_$append_integer - n in decimal to the end of s, a `-' first when
  negative.

  0x073484, 0x86 bytes: D1 := n; when negative, '-' (0x2D) appended
  and D1 negated.  start (D2) := s.length + 1, the address of s.body[start]
  hoisted into A2.  Each digit: s.length grows by one, the characters
  from start on move up one (a `for' downto start + 1, a `dbf' loop),
  s.body[start] := chr(v mod 10 + 48) (M$OIS$WLW 0x0734DE), v := v div 10
  (M$DIS$LLW 0x0734F4), until v = 0: the digits come out least
  significant first, each pushed in before the others.

  Not known from the original:
  - the locals' names. }

procedure std_$append_integer(
    in out s: std_$string_t;
    n: integer32);
var
  v: integer32;
  start: integer32;
  j: integer;
begin
  v := n;
  if v < 0 then begin
    s.length := s.length + 1;
    s.body[s.length] := '-';
    v := -v;
  end;
  start := s.length + 1;
  repeat
    s.length := s.length + 1;
    for j := s.length downto start + 1 do
      s.body[j] := s.body[j - 1];
    s.body[start] := chr(v mod 10 + ord('0'));
    v := v div 10;
  until v = 0;
end;

{ std_$diag_dump_var_string - s's characters to the diagnostic output,
  in double quotes when quoted.

  0x07350A, 0x32 bytes: STD_$DIAG_DUMP_ANY_STRING (`bsr', 0x07352C) with
  quoted (a byte in a word slot), s.length zero-extended to a longword
  and `pea (2,A2)': the characters. }

procedure std_$diag_dump_var_string(
    in s: std_$string_t;
    quoted: boolean);
begin
  std_$diag_dump_any_string(s.body, s.length, quoted);
end;
